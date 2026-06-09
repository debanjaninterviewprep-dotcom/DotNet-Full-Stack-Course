# Topic 8 — Practice Problems

> Project: `PracticeProblemsSolutions/` — ASP.NET Core webapi with SignalR hub. Run `dotnet run` and connect with a SignalR client (browser, `wscat`, or the Topic 7 React app).

---

## P1 — Hub, JWT auth via query string, and `[Authorize]`

**Goal:** Stand up `/hubs/taskflow` requiring authentication, accepting JWT from `?access_token=` for WebSocket negotiate.

**Tasks**
1. Add `Microsoft.AspNetCore.SignalR.StackExchangeRedis`.
2. Configure `AddSignalR` with detailed errors in dev only, 32 KB receive max, KeepAlive 15 s, ClientTimeout 60 s.
3. Wire JWT bearer (reuse Topic 5 settings) with `OnMessageReceived` reading `?access_token=` when path starts with `/hubs`.
4. `MapHub<TaskFlowHub>("/hubs/taskflow").RequireAuthorization()`.
5. Define `ITaskFlowClient` (TaskCreated/Updated/Deleted, CommentAdded, Notify) and make `TaskFlowHub : Hub<ITaskFlowClient>`.

**Acceptance**
- Negotiate without a token → 401.
- Negotiate with a valid bearer → connection accepted; `OnConnectedAsync` log shows the user id.
- Detailed errors are absent in `Production`.

---

## P2 — Strongly-typed `IUserIdProvider` from `sub` claim

**Goal:** Make `Clients.User(userId)` work for tokens issued by Topic 5 (which puts userId in `JwtRegisteredClaimNames.Sub`).

**Tasks**
1. Implement `SubUserIdProvider : IUserIdProvider`.
2. Register as singleton.
3. In `OnConnectedAsync`, also add the connection to `Groups.AddToGroupAsync($"user:{userId}")` for parity.
4. Build an admin-only hub method `Ping(string userId)` that calls `Clients.User(userId).Notify(...)` and `Clients.Group($"user:{userId}").Notify(...)` — verify both reach the target on multiple tabs.

**Acceptance**
- A user opening 3 tabs receives both notifications on all 3.
- A user opening 0 tabs (offline) silently no-ops, no exception.
- Ping endpoint is rejected (`Forbidden`) for non-admin callers.

---

## P3 — Project group join with resource-based authorization

**Goal:** `JoinProject(Guid projectId)` must verify the caller is a member of that project.

**Tasks**
1. Reuse the `CanViewProject` requirement + handler from Topic 5.
2. In the hub method: load the project, call `IAuthorizationService.AuthorizeAsync`, throw `HubException("Forbidden")` if not allowed.
3. On success, `Groups.AddToGroupAsync(Context.ConnectionId, $"project:{projectId}")`.
4. Implement `LeaveProject(Guid projectId)` and call it from `OnDisconnectedAsync` cleanup is automatic — verify by attaching a logger.
5. Sanitize the `HubException` message — never include EF or SQL details.

**Acceptance**
- Non-member → `HubException` reaches the client with the message `Forbidden`.
- Member → group membership confirmed by sending an event from a separate REST endpoint and observing receipt.
- Disconnect cleans up automatically (no zombie groups in logs).

---

## P4 — `TaskNotifier` + push from a command handler

**Goal:** A reusable notifier that command handlers inject — keeps `IHubContext` out of business logic.

**Tasks**
1. Create `TaskNotifier(IHubContext<TaskFlowHub, ITaskFlowClient>)` with methods: `TaskCreated`, `TaskUpdated`, `TaskDeleted`, `CommentAdded` — each pushes to `Clients.Group($"project:{projectId}")`.
2. Inject into a stub `UpdateTaskStatusCommandHandler`. After saving, await `_notifier.TaskUpdated(...)`.
3. Add a unit test: mock `IHubContext`, invoke handler, assert `.Group("project:X").TaskUpdated(dto)` was called once.
4. Use `Clients.OthersInGroup` for a "typing…" demo method to avoid echoing to the originator.

**Acceptance**
- Two browser sessions on the same project: A patches a task → B sees the update within 200 ms; A's UI updates from its own optimistic mutation, not the echo.
- Unit test passes deterministically.

---

## P5 — Redis backplane + smoke test

**Goal:** Run two API instances on different ports and verify cross-node delivery via Redis.

**Tasks**
1. `AddSignalR().AddStackExchangeRedis(connStr, o => o.Configuration.ChannelPrefix = RedisChannel.Literal("taskflow"))`.
2. `docker run -p 6379:6379 redis:7` (documented in README).
3. Launch the API twice on ports 7108 and 7208 (`launchSettings.json` profiles).
4. Connect client A to 7108, client B to 7208, both `JoinProject(p1)`.
5. POST to `/api/v1/tasks/{id}` on 7108 → both clients receive `TaskUpdated`.

**Acceptance**
- Without Redis configured, only client A receives the event (single-node baseline).
- With Redis configured, both clients receive it.
- Redis disconnect raises a logged warning but does not crash the API.

---

## P6 — React client + reconnect handling

**Goal:** Add a SignalR client to the Topic 7 React app, integrate with TanStack Query, and re-join groups after reconnect.

**Tasks**
1. Install `@microsoft/signalr`.
2. Create a singleton `getHub()` with `withAutomaticReconnect([0, 2000, 5000, 10_000, 30_000])` and `accessTokenFactory: () => getAccessToken()`.
3. In `useRealtimeTasks(projectId)`: start hub if disconnected, `JoinProject`, register `TaskUpdated`/`TaskDeleted` handlers that write to TanStack Query cache.
4. On `hub.onreconnected`, re-call `JoinProject(currentProjectId)` so the group membership is restored.
5. On logout, `hub.stop()` and null out the singleton.

**Acceptance**
- Killing the API for 5 s and bringing it back: client reconnects without user action and continues receiving events.
- Switching projects (`/projects/p1` → `/projects/p2`): old project group is left, new one joined; events for `p1` no longer arrive.
- After logout, no further events arrive even if the API pushes.
