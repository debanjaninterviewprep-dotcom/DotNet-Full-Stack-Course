# Topic 8 — Real-Time with SignalR

> **Goal**: Push live updates from the API to connected clients (task moved, comment added, member joined) using SignalR — covering hubs, groups, authentication, scaling with the Redis backplane, and a typed React client.

---

## 1. Why SignalR over raw WebSockets

| Concern | Raw WebSocket | SignalR |
|---|---|---|
| Transport fallback | WebSocket only | WebSocket → ServerSentEvents → LongPolling |
| Reconnection | DIY | Built-in with backoff |
| Method invocation | Send raw frames, parse JSON yourself | RPC-style `hub.SendAsync("MethodName", payload)` |
| Groups / per-user fan-out | DIY | First-class |
| Scaling across nodes | DIY (pub/sub bus) | Redis / Azure SignalR backplane |
| Auth integration | DIY | `[Authorize]` on hubs/methods, JWT in query string |
| Typed clients | DIY | `Hub<T>` for strongly-typed server-to-client contracts |

For TaskFlow we need: live task drag-and-drop, presence, comments, notification badges. SignalR removes ~80% of the plumbing.

---

## 2. Architecture overview

```mermaid
flowchart LR
    A[Browser A] -- WS --> H1[ASP.NET Core /hubs/taskflow on Node 1]
    B[Browser B] -- WS --> H2[/hubs/taskflow on Node 2]
    H1 -- pub/sub --> R[(Redis Backplane)]
    H2 -- pub/sub --> R
    Cmd[Command Handler] -- IHubContext --> H1
```

- A single browser connects to whichever API replica its load balancer picks.
- A command handler running on Node 1 (e.g., `UpdateTaskStatusCommand`) needs to reach a client on Node 2 → Redis backplane forwards.
- Clients never talk directly; they only receive server-pushed events.

---

## 3. Installing & wiring SignalR

```bash
dotnet add package Microsoft.AspNetCore.SignalR.StackExchangeRedis
```

```csharp
// Program.cs
builder.Services
    .AddSignalR(o =>
    {
        o.EnableDetailedErrors = builder.Environment.IsDevelopment();
        o.MaximumReceiveMessageSize = 32 * 1024;            // 32 KB ceiling per message
        o.ClientTimeoutInterval = TimeSpan.FromSeconds(60);
        o.KeepAliveInterval = TimeSpan.FromSeconds(15);
    })
    .AddStackExchangeRedis(builder.Configuration.GetConnectionString("Redis")!, o =>
    {
        o.Configuration.ChannelPrefix = RedisChannel.Literal("taskflow");
    });

app.MapHub<TaskFlowHub>("/hubs/taskflow")
   .RequireAuthorization();
```

> `KeepAlive < ClientTimeout` is the rule — typically `KeepAlive = ClientTimeout / 4`. Otherwise your idle clients flap.

---

## 4. Strongly-typed hubs

Define a contract for everything the server pushes:

```csharp
public interface ITaskFlowClient
{
    Task TaskCreated(TaskDetailDto task);
    Task TaskUpdated(TaskDetailDto task);
    Task TaskDeleted(Guid taskId);
    Task CommentAdded(Guid taskId, CommentDto comment);
    Task PresenceChanged(Guid projectId, IReadOnlyList<UserPresence> members);
    Task Notify(NotificationDto notification);
}
```

Make the hub generic on that interface — now you can't typo a method name:

```csharp
[Authorize]
public sealed class TaskFlowHub : Hub<ITaskFlowClient>
{
    private readonly ICurrentUser _user;
    public TaskFlowHub(ICurrentUser user) => _user = user;

    public override async Task OnConnectedAsync()
    {
        // Auto-join personal channel for direct notifications.
        await Groups.AddToGroupAsync(Context.ConnectionId, $"user:{_user.UserId}");
        await base.OnConnectedAsync();
    }

    public Task JoinProject(Guid projectId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, $"project:{projectId}");

    public Task LeaveProject(Guid projectId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, $"project:{projectId}");
}
```

Server-to-client calls outside the hub use `IHubContext<TaskFlowHub, ITaskFlowClient>`:

```csharp
public sealed class TaskNotifier
{
    private readonly IHubContext<TaskFlowHub, ITaskFlowClient> _hub;
    public TaskNotifier(IHubContext<TaskFlowHub, ITaskFlowClient> hub) => _hub = hub;

    public Task TaskUpdated(Guid projectId, TaskDetailDto task) =>
        _hub.Clients.Group($"project:{projectId}").TaskUpdated(task);
}
```

Inject `TaskNotifier` into command handlers; commands stay decoupled from `IHubContext`.

---

## 5. Authentication — JWT in query string

WebSockets cannot send custom headers from browsers, so the bearer token rides on `?access_token=...` for the negotiate step:

```csharp
builder.Services.AddAuthentication()
    .AddJwtBearer(o =>
    {
        // existing JWT options from Topic 5...
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var path = ctx.HttpContext.Request.Path;
                var token = ctx.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(token) && path.StartsWithSegments("/hubs"))
                    ctx.Token = token;
                return Task.CompletedTask;
            }
        };
    });
```

The token is short-lived (15 min — Topic 5), so even if it leaks via referer or proxy logs, blast radius is small. Once connected, SignalR keeps the connection without re-auth until disconnect.

> **Refresh during a long-lived connection?** Two strategies: (1) re-negotiate periodically, or (2) use cookies+`AllowCredentials` so the auth cookie scheme handles it. TaskFlow chooses **(1) re-negotiate** since refresh tokens live in cookies but we use Bearer for hubs.

---

## 6. Authorization on hub methods

```csharp
[Authorize(Policy = "Member")]
public Task JoinProject(Guid projectId) { ... }

[Authorize(Roles = "Admin")]
public Task BroadcastSystemMessage(string text) { ... }
```

For **resource-based** authorization (only members of *this* project can join its group), check inside the hub method using the same `IAuthorizationService` from Topic 5:

```csharp
public async Task JoinProject(Guid projectId)
{
    var project = await _db.Projects.FindAsync(projectId)
                  ?? throw new HubException("Project not found");
    var auth = await _authz.AuthorizeAsync(Context.User!, project, "CanViewProject");
    if (!auth.Succeeded) throw new HubException("Forbidden");
    await Groups.AddToGroupAsync(Context.ConnectionId, $"project:{projectId}");
}
```

`HubException` is the *only* exception type whose message reaches the client by default — sanitize it.

---

## 7. Groups vs users vs everyone

| Target | Use | TaskFlow example |
|---|---|---|
| `Clients.All` | Global broadcast | Maintenance announcement |
| `Clients.Group("name")` | Topic-scoped | All members watching project X |
| `Clients.Groups(...)` | Multiple groups | Cross-project events |
| `Clients.User("userId")` | Per-user across all their devices | Direct notifications, mentions |
| `Clients.Users(...)` | Several users | Assignees of a task |
| `Clients.Caller` | Just the invoker | Echo / ack |
| `Clients.Others` | Everyone except caller | "Someone else is typing…" |
| `Clients.OthersInGroup("name")` | Group minus caller | Optimistic-update echoes |

To use `Clients.User(userId)`, the JWT subject claim must equal that userId. SignalR resolves it via the `IUserIdProvider` — default reads `Context.UserIdentifier` from `ClaimTypes.NameIdentifier`. Since Topic 5 stores user ids in `JwtRegisteredClaimNames.Sub`, register a custom provider:

```csharp
public sealed class SubUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext c) =>
        c.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
}
builder.Services.AddSingleton<IUserIdProvider, SubUserIdProvider>();
```

---

## 8. Connection lifecycle hooks

```csharp
public override async Task OnConnectedAsync()
{
    _logger.LogInformation("Connected {ConnId} as {User}", Context.ConnectionId, _user.UserId);
    await Groups.AddToGroupAsync(Context.ConnectionId, $"user:{_user.UserId}");
    await base.OnConnectedAsync();
}

public override async Task OnDisconnectedAsync(Exception? ex)
{
    if (ex is not null)
        _logger.LogWarning(ex, "Hub disconnect with error {ConnId}", Context.ConnectionId);
    // Group memberships are cleared automatically when the connection ends.
    await base.OnDisconnectedAsync(ex);
}
```

> Group memberships are **per connection**, not per user. A user opening 3 tabs has 3 connections; all 3 must `JoinProject` to receive events. The `user:{id}` group (joined automatically) gives you a single fan-out target across all their devices.

---

## 9. Backpressure & message size

| Limit | Default | TaskFlow |
|---|---|---|
| `MaximumReceiveMessageSize` | 32 KB | 32 KB (we never push large blobs through SignalR) |
| `StreamBufferCapacity` | 10 | 10 |
| `MaximumParallelInvocationsPerClient` | 1 | 1 (FIFO, prevents head-of-line skipping) |

Large payloads (file lists, activity backfill) ride on REST; SignalR carries small notifications and IDs. **The client refetches via TanStack Query when notified — the push is a cache-bust hint, not the source of truth.**

---

## 10. Pushing events from command handlers

```csharp
public sealed class UpdateTaskStatusHandler : IRequestHandler<UpdateTaskStatusCommand, TaskDetailDto>
{
    private readonly TaskFlowDbContext _db;
    private readonly TaskNotifier _notifier;

    public async Task<TaskDetailDto> Handle(UpdateTaskStatusCommand cmd, CancellationToken ct)
    {
        var task = await _db.Tasks.SingleAsync(t => t.Id == cmd.TaskId, ct);
        task.Status = cmd.Status;
        await _db.SaveChangesAsync(ct);

        var dto = TaskDetailDto.From(task);
        await _notifier.TaskUpdated(task.ProjectId, dto);   // fire-and-forget OK; await for ordering
        return dto;
    }
}
```

**Ordering guarantee:** SignalR delivers messages on a single connection in send order. Across multiple servers + Redis, ordering across *publishers* is not guaranteed — design events to be idempotent by id+timestamp.

---

## 11. The React client

```bash
npm i @microsoft/signalr
```

```ts
// src/api/realtime.ts
import { HubConnectionBuilder, HubConnection, LogLevel } from '@microsoft/signalr';
import { env } from '@config/env';
import { getAccessToken } from '@features/auth/token-store';

let connection: HubConnection | null = null;

export function getHub(): HubConnection {
  if (connection) return connection;
  connection = new HubConnectionBuilder()
    .withUrl(`${env.VITE_API_BASE_URL}/hubs/taskflow`, {
      accessTokenFactory: () => getAccessToken() ?? '',
    })
    .withAutomaticReconnect([0, 2000, 5000, 10_000, 30_000])
    .configureLogging(LogLevel.Warning)
    .build();
  return connection;
}
```

Wire it into TanStack Query:

```ts
// src/features/tasks/useRealtimeTasks.ts
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { getHub } from '@api/realtime';
import { taskKeys } from '@features/projects/keys';
import type { TaskDetailDto } from './types';

export function useRealtimeTasks(projectId: string) {
  const qc = useQueryClient();
  useEffect(() => {
    const hub = getHub();
    let cancelled = false;

    const start = async () => {
      if (hub.state === 'Disconnected') await hub.start();
      if (cancelled) return;
      await hub.invoke('JoinProject', projectId);

      hub.on('TaskUpdated', (task: TaskDetailDto) => {
        qc.setQueryData(taskKeys.detail(task.id), task);
        qc.invalidateQueries({ queryKey: taskKeys.lists() });
      });
      hub.on('TaskDeleted', (taskId: string) => {
        qc.removeQueries({ queryKey: taskKeys.detail(taskId) });
        qc.invalidateQueries({ queryKey: taskKeys.lists() });
      });
    };
    void start();

    return () => {
      cancelled = true;
      hub.off('TaskUpdated');
      hub.off('TaskDeleted');
      hub.invoke('LeaveProject', projectId).catch(() => {});
    };
  }, [projectId, qc]);
}
```

> The hub connection is a **singleton** for the app lifetime. Components subscribe/unsubscribe to events but don't tear down the socket.

---

## 12. Scaling — Redis backplane

Without a backplane, two API replicas don't share group state — a client connected to Node 1 misses events sent by Node 2. With Redis:

- Each `Clients.Group("project:X")` send is published on a Redis channel.
- Every API replica subscribes and forwards to its locally-connected clients in that group.
- Group membership stays per-replica (Redis only forwards messages, not membership).

Redis budget guidelines:
- 1 connection per API replica → cheap.
- Channel volume = total events/sec × replicas. For TaskFlow MVP this is dozens/sec.
- For >100k concurrent connections, prefer **Azure SignalR Service** (managed, removes the WebSocket termination from your app servers).

---

## 13. Sticky sessions — required when?

| Transport | Sticky required? |
|---|---|
| WebSocket only | No (single TCP connection — never re-balanced) |
| Long polling | **Yes** (multiple HTTP roundtrips that must hit the same node) |
| ServerSentEvents | Yes for the negotiate step + initial response |

If your load balancer can't guarantee stickiness (e.g., Azure Front Door without affinity), set `options.SkipNegotiation = true` on the client + `Transports.WebSockets` only — but then non-WebSocket-capable proxies will fail.

---

## 14. Testing real-time flows

- **Unit-test the notifier** by mocking `IHubContext<THub, IClient>` and asserting `Clients.Group(...).TaskUpdated(...)` was invoked.
- **Integration-test the hub** with `WebApplicationFactory<TProgram>` + `HubConnectionBuilder` pointing at `TestServer.CreateHandler()` (Topic 10).
- **Contract-test the client interface** by sharing the `ITaskFlowClient` method names between server and a TS const enum.

---

## 15. Common pitfalls

| Pitfall | Fix |
|---|---|
| 401 on hub negotiate | Wire `OnMessageReceived` for `?access_token=` query, or reuse cookie auth |
| `Clients.User(id)` no-op | Register a custom `IUserIdProvider` reading the right claim |
| Events not arriving on second tab | Each tab is its own connection — both must `JoinProject` |
| Cross-node delivery missing | Redis backplane not configured / connection string wrong |
| Reconnect loop on token expiry | Tear down + rebuild connection on auth refresh, or use cookies |
| Double-firing optimistic update echoes | Use `Clients.OthersInGroup` to skip the originator |
| Hub method blocked by long DB call | Methods are serialized per-connection; offload heavy work, return fast |
| Detailed exceptions leaking to clients | `EnableDetailedErrors = false` in production; throw `HubException` with safe text |

---

## 16. Security checklist

- ✅ `[Authorize]` on the hub class — no anonymous connections.
- ✅ Resource-based authorization inside `JoinProject` — never trust client-supplied IDs alone.
- ✅ `EnableDetailedErrors = false` in production.
- ✅ Validate every hub-method argument (FluentValidation pipeline reused).
- ✅ Rate-limit per-connection invokes (custom middleware or Redis-backed counter).
- ✅ Strip secrets from `OnConnectedAsync` logs; log connection id only.
- ✅ For Azure SignalR Service: rotate the access key, use AAD auth for the upstream connection.

---

## 17. 10 Q&A

1. **Why SignalR over raw WebSockets?** Transport fallback, automatic reconnect, RPC dispatch, group fan-out, and a Redis/Azure backplane — all out of the box.
2. **What does `Hub<T>` give you?** Strongly-typed server-to-client contracts so `Clients.Group("x").TaskUpdated(dto)` is checked at compile time.
3. **Why does the JWT need to ride in `?access_token=` for hubs?** Browsers can't add custom headers to the WebSocket handshake — query string is the documented workaround.
4. **What is the Redis backplane responsible for?** Forwarding `Clients.Group/User/All` calls between API replicas. It does **not** store group membership — that stays per node.
5. **When are sticky sessions required?** When the transport is long-polling or SSE (multiple HTTP requests must hit the same backend). Pure WebSocket connections don't need stickiness after negotiate.
6. **Why is `MaximumParallelInvocationsPerClient = 1` the default?** Preserves message ordering per connection. Increase only when you understand the FIFO trade-off.
7. **How do you target one user across all their tabs/devices?** Auto-join `user:{id}` in `OnConnectedAsync`, send to `Clients.Group("user:{id}")` — or use `Clients.User(id)` with a correct `IUserIdProvider`.
8. **How does the client recover from a dropped connection?** `withAutomaticReconnect()` exponential backoff. State within the hub (group memberships) is **lost** on reconnect — clients must rejoin in the `onreconnected` handler.
9. **Why does the client refetch via TanStack Query instead of trusting the pushed payload?** Defense in depth: pushes can be stale or out-of-order across nodes. The push triggers a cache invalidate; REST is the source of truth.
10. **When should we move to Azure SignalR Service?** When concurrent connections approach the per-replica limit (~5k–20k depending on size), or when WebSocket termination dominates the API CPU profile. The service offloads both.
