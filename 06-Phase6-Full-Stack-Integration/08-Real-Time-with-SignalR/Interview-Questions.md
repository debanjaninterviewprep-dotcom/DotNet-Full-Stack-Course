# Topic 08: Real-Time with SignalR — Interview Questions

---

## Q1. What is SignalR and what problems does it solve?
**Answer:**
SignalR is a real-time communication library for ASP.NET Core that abstracts WebSockets, Server-Sent Events, and Long Polling to deliver messages from server to clients in real time:

```
Traditional HTTP: Client pulls data (polling)
  Client: "Any updates?" → Server: "No"
  Client: "Any updates?" → Server: "No"
  Client: "Any updates?" → Server: "Yes! Here's the data"

SignalR: Server pushes data
  Server: "Here's new data!" → Client instantly receives it
```

**Use cases:** Live chat, real-time dashboards, collaborative editing, notifications, live progress updates, game state, stock tickers.

---

## Q2. What is the difference between WebSockets, Server-Sent Events, and Long Polling?
**Answer:**
| | WebSocket | SSE | Long Polling |
|---|---|---|---|
| **Direction** | Bidirectional | Server → Client only | Bidirectional |
| **Protocol** | WS/WSS | HTTP | HTTP |
| **Connection** | Persistent, full-duplex | Persistent, one-way | Repeated HTTP requests |
| **Browser** | ✓ All modern | ✓ All (not IE) | ✓ All |
| **Firewall** | ❌ Sometimes blocked | ✓ Works everywhere | ✓ Works everywhere |
| **Latency** | Lowest | Low | High |

**SignalR transport negotiation** (automatic fallback):
1. Try WebSocket (preferred)
2. Fall back to SSE
3. Fall back to Long Polling

---

## Q3. What is a SignalR Hub and how do you implement one?
**Answer:**
A Hub is the central class for handling SignalR connections and message routing:

```csharp
// Hub implementation
public class NotificationHub : Hub
{
    private readonly IUserService _userSvc;

    public NotificationHub(IUserService userSvc) => _userSvc = userSvc;

    // Called when client connects
    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier; // from JWT
        var groups = await _userSvc.GetUserGroupsAsync(userId!);
        foreach (var group in groups)
            await Groups.AddToGroupAsync(Context.ConnectionId, group);

        await Clients.Caller.SendAsync("Connected", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    // Called when client disconnects
    public override Task OnDisconnectedAsync(Exception? exception)
    {
        return base.OnDisconnectedAsync(exception);
    }

    // Hub method — client can call this
    public async Task JoinGroup(string groupName)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        await Clients.Group(groupName).SendAsync("UserJoined", Context.UserIdentifier);
    }

    public async Task SendMessage(string groupName, string message)
    {
        await Clients.Group(groupName).SendAsync("ReceiveMessage", new {
            User = Context.UserIdentifier,
            Message = message,
            Timestamp = DateTime.UtcNow
        });
    }
}
```

---

## Q4. How do you configure SignalR in ASP.NET Core?
**Answer:**
```csharp
// Add SignalR services
builder.Services.AddSignalR(options => {
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
    options.MaximumReceiveMessageSize = 32 * 1024; // 32KB
    options.EnableDetailedErrors = app.Environment.IsDevelopment();
});

// Map hub endpoints
app.MapHub<NotificationHub>("/hubs/notifications");
app.MapHub<ChatHub>("/hubs/chat");

// With authentication
app.MapHub<NotificationHub>("/hubs/notifications")
   .RequireAuthorization(); // JWT auth works with SignalR

// Map specific JWT claim to ConnectionId (user identifier)
builder.Services.AddSignalR();
builder.Services.AddSingleton<IUserIdProvider, NameUserIdProvider>();

public class NameUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
        => connection.User.FindFirstValue(ClaimTypes.NameIdentifier);
}
```

---

## Q5. How do you target specific clients with SignalR?
**Answer:**
```csharp
// Send to specific connection
await Clients.Client(connectionId).SendAsync("Notify", message);

// Send to caller only
await Clients.Caller.SendAsync("Ack", "Message received");

// Send to all connected clients
await Clients.All.SendAsync("Broadcast", message);

// Send to all except caller
await Clients.Others.SendAsync("NewMessage", message);

// Send to a group
await Clients.Group("group-name").SendAsync("GroupMessage", message);

// Send to a specific user (all connections for that user)
await Clients.User(userId).SendAsync("PersonalNotification", message);

// Send to specific users
await Clients.Users(new[] { userId1, userId2 }).SendAsync("Notify", data);

// From outside a hub (inject IHubContext)
public class NotificationService(IHubContext<NotificationHub> hubContext)
{
    public async Task SendToUserAsync(string userId, string message)
        => await hubContext.Clients.User(userId).SendAsync("Notification", message);

    public async Task BroadcastAsync(object data)
        => await hubContext.Clients.All.SendAsync("Update", data);
}
```

---

## Q6. How do you connect to SignalR from Angular?
**Answer:**
```typescript
// Install: @microsoft/signalr
import * as signalR from '@microsoft/signalr';

@Injectable({ providedIn: 'root' })
export class SignalRService {
  private hubConnection!: signalR.HubConnection;
  private notifications = new Subject<NotificationDto>();

  readonly notifications$ = this.notifications.asObservable();

  async connect(token: string): Promise<void> {
    this.hubConnection = new signalR.HubConnectionBuilder()
      .withUrl(`${environment.signalrUrl}/hubs/notifications`, {
        accessTokenFactory: () => token // JWT authentication
      })
      .withAutomaticReconnect([0, 2000, 5000, 10000]) // retry delays
      .configureLogging(signalR.LogLevel.Information)
      .build();

    // Register message handlers
    this.hubConnection.on('Notification', (notification: NotificationDto) => {
      this.notifications.next(notification);
    });

    this.hubConnection.onreconnecting(() => console.log('Reconnecting...'));
    this.hubConnection.onreconnected(() => console.log('Reconnected!'));
    this.hubConnection.onclose(() => console.log('Connection closed'));

    await this.hubConnection.start();
    console.log('SignalR connected');
  }

  // Call hub method
  async joinGroup(groupName: string): Promise<void> {
    await this.hubConnection.invoke('JoinGroup', groupName);
  }

  async disconnect(): Promise<void> {
    await this.hubConnection?.stop();
  }
}
```

---

## Q7. How do you scale SignalR across multiple servers?
**Answer:**
By default, SignalR stores connection state in memory — only works with one server. For multiple servers/containers, use a **backplane**:

```csharp
// Redis backplane — synchronizes messages across server instances
builder.Services.AddSignalR().AddStackExchangeRedis(redisConnectionString, options => {
    options.Configuration.ChannelPrefix = RedisChannel.Literal("SignalR");
});

// Azure SignalR Service (fully managed — no backplane needed)
builder.Services.AddSignalR().AddAzureSignalR(builder.Configuration["Azure:SignalR:ConnectionString"]);
```

**Why it works:**
- All server instances connect to the Redis channel.
- When Server A sends a message, Redis distributes it to all other servers.
- Each server forwards the message to its local connections.

---

## Q8. What are SignalR groups and how are they used?
**Answer:**
Groups are named collections of connections for broadcasting to a subset of clients:

```csharp
// Common group patterns
// 1. Per-user group (multiple device support)
await Groups.AddToGroupAsync(connectionId, $"user-{userId}");

// 2. Room/channel group
await Groups.AddToGroupAsync(connectionId, $"order-{orderId}");

// 3. Role group
await Groups.AddToGroupAsync(connectionId, "admins");

// Business example: notify all users watching an order
public class OrderHub : Hub
{
    public async Task WatchOrder(int orderId)
        => await Groups.AddToGroupAsync(Context.ConnectionId, $"order-{orderId}");

    public async Task UnwatchOrder(int orderId)
        => await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"order-{orderId}");
}

// From background service: notify when order status changes
public async Task NotifyOrderUpdatedAsync(int orderId, OrderDto order)
    => await _hub.Clients.Group($"order-{orderId}").SendAsync("OrderUpdated", order);
```

---

## Q9. How do you handle SignalR authentication?
**Answer:**
```csharp
// JWT in SignalR — special handling because WebSocket doesn't support Authorization header
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context => {
                // Read token from query string (WebSocket can't use headers)
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                    context.Token = accessToken;
                return Task.CompletedTask;
            }
        };
    });
```

```typescript
// Angular: pass token in query string
new signalR.HubConnectionBuilder()
  .withUrl('/hubs/notifications', {
    accessTokenFactory: () => this.authService.getToken() ?? ''
  })
  .build();
// SignalR client automatically adds ?access_token=... to WebSocket URL
```

---

## Q10. What is the difference between `SendAsync`, `InvokeAsync`, and streaming in SignalR?
**Answer:**
```csharp
// SendAsync — fire and forget (server doesn't wait for client to process)
await Clients.All.SendAsync("Notification", data);

// InvokeAsync — call hub method from client and get return value
// Client side:
const result = await connection.invoke<UserDto>('GetCurrentUser');
// Server hub method:
public UserDto GetCurrentUser() => _userSvc.GetCurrentUser(Context.UserIdentifier!);

// Server streaming — server pushes multiple values over time
public async IAsyncEnumerable<StockPrice> StreamStockPrices(
    string symbol, [EnumeratorCancellation] CancellationToken ct)
{
    while (!ct.IsCancellationRequested)
    {
        yield return await _stockService.GetPriceAsync(symbol);
        await Task.Delay(1000, ct);
    }
}
// Client:
connection.stream<StockPrice>('StreamStockPrices', 'MSFT')
  .subscribe(price => console.log(price));

// Client streaming — client sends multiple values to server
```

---

## Q11. How do you display real-time notifications in Angular?
**Answer:**
```typescript
// Notification service with SignalR
@Injectable({ providedIn: 'root' })
export class NotificationService {
  private signalR  = inject(SignalRService);
  notifications   = signal<AppNotification[]>([]);
  unreadCount     = computed(() => this.notifications().filter(n => !n.read).length);

  constructor() {
    // Subscribe to real-time notifications
    this.signalR.on<AppNotification>('Notification').pipe(
      takeUntilDestroyed()
    ).subscribe(n => {
      this.notifications.update(list => [n, ...list].slice(0, 50)); // max 50
    });
  }

  markAllRead() {
    this.notifications.update(list => list.map(n => ({ ...n, read: true })));
  }
}

// Component
@Component({
  template: `
    <button [attr.data-count]="notifSvc.unreadCount()">
      🔔 Notifications
    </button>
    <div class="dropdown">
      @for (n of notifSvc.notifications(); track n.id) {
        <div [class.unread]="!n.read">{{ n.message }}</div>
      }
    </div>
  `
})
export class NotificationBellComponent {
  notifSvc = inject(NotificationService);
}
```

---

## Q12. What is Server-Sent Events (SSE) and how does it differ from SignalR?
**Answer:**
```csharp
// ASP.NET Core SSE endpoint — server push without SignalR
app.MapGet("/api/events/live", async (HttpResponse response, CancellationToken ct) =>
{
    response.Headers.ContentType  = "text/event-stream";
    response.Headers.CacheControl = "no-cache";

    while (!ct.IsCancellationRequested)
    {
        var data = await GetLatestDataAsync();
        await response.WriteAsync($"data: {JsonSerializer.Serialize(data)}\n\n", ct);
        await response.Body.FlushAsync(ct);
        await Task.Delay(5000, ct);
    }
});

// Client (Angular)
const eventSource = new EventSource('/api/events/live');
eventSource.onmessage = (event) => {
  this.data.set(JSON.parse(event.data));
};
eventSource.onerror = () => eventSource.close();
```

**SignalR vs SSE:**
- SignalR: bidirectional, client can call server methods, auto-reconnect, group support, authenticated.
- SSE: server-to-client only, simpler, works through HTTP, no special server configuration.

---

## Q13. How do you monitor and debug SignalR connections?
**Answer:**
```csharp
// Server-side logging
builder.Services.AddSignalR(opts => opts.EnableDetailedErrors = true);
builder.Logging.AddFilter("Microsoft.AspNetCore.SignalR", LogLevel.Debug);
builder.Logging.AddFilter("Microsoft.AspNetCore.Http.Connections", LogLevel.Debug);

// Track connection metrics
public class ConnectionTracker
{
    private readonly ConcurrentDictionary<string, UserConnection> _connections = new();

    public void Add(string connectionId, string userId)
        => _connections[connectionId] = new UserConnection(userId, DateTime.UtcNow);

    public void Remove(string connectionId) => _connections.TryRemove(connectionId, out _);

    public int TotalConnections => _connections.Count;
    public IEnumerable<string> GetConnectedUsers() => _connections.Values.Select(c => c.UserId).Distinct();
}
```

```typescript
// Client-side logging
new signalR.HubConnectionBuilder()
  .configureLogging(signalR.LogLevel.Debug) // verbose
  .withUrl('/hubs/notifications')
  .build();
```

---

## Q14. What is the reconnection strategy for SignalR?
**Answer:**
```typescript
// Angular: automatic reconnection with exponential backoff
const connection = new signalR.HubConnectionBuilder()
  .withUrl('/hubs/notifications', { accessTokenFactory: () => getToken() })
  .withAutomaticReconnect({
    nextRetryDelayInMilliseconds: retryContext => {
      if (retryContext.elapsedMilliseconds < 60000) {
        // First minute: try every 2s
        return 2000;
      } else if (retryContext.elapsedMilliseconds < 300000) {
        // Next 4 minutes: try every 10s
        return 10000;
      }
      // After 5 minutes: give up
      return null;
    }
  })
  .build();

// React to reconnection events
connection.onreconnecting(error => {
  notify.showWarning('Connection lost. Reconnecting...');
});

connection.onreconnected(connectionId => {
  notify.showSuccess('Reconnected!');
  // Refresh data that may have been missed
  reloadData();
});

connection.onclose(error => {
  notify.showError('Connection permanently closed. Please refresh.');
});
```

---

## Q15. What is the real-time dashboard pattern with SignalR?
**Answer:**
```csharp
// Background service pushes metrics every 5 seconds
public class DashboardMetricsService(IHubContext<DashboardHub> hub) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            var metrics = await CollectMetricsAsync();
            await hub.Clients.All.SendAsync("MetricsUpdate", metrics, ct);
            await Task.Delay(5000, ct);
        }
    }

    private async Task<DashboardMetrics> CollectMetricsAsync() => new DashboardMetrics {
        ActiveUsers = await _db.Sessions.CountAsync(s => s.LastSeen > DateTime.UtcNow.AddMinutes(-5)),
        OrdersToday = await _db.Orders.CountAsync(o => o.CreatedAt.Date == DateTime.Today),
        Revenue     = await _db.Orders.SumAsync(o => o.Total),
        Timestamp   = DateTime.UtcNow
    };
}

// Angular dashboard component
@Component({
  template: `
    <div class="metric">Active Users: {{ metrics()?.activeUsers }}</div>
    <div class="metric">Orders Today: {{ metrics()?.ordersToday }}</div>
    <div class="metric">Revenue: {{ metrics()?.revenue | currency }}</div>
    <div class="metric">Last Updated: {{ metrics()?.timestamp | date:'HH:mm:ss' }}</div>
  `
})
export class DashboardComponent implements OnInit {
  metrics = signal<DashboardMetrics | null>(null);

  ngOnInit() {
    this.signalR.on<DashboardMetrics>('MetricsUpdate').pipe(
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(m => this.metrics.set(m));
  }
}
```
