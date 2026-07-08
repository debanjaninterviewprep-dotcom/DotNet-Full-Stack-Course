# Topic 11: Logging, Observability, Caching & Performance — Interview Questions

---

## Q1. What is structured logging and why is it better than plain text?
**Answer:**
Structured logging stores log entries as structured data (key-value pairs) rather than plain strings — enabling powerful querying and analysis:

```csharp
// Plain text logging — hard to query
_logger.LogInformation($"User {userId} placed order {orderId} for ${amount}");
// Output: "User 42 placed order 891 for $99.99"
// Problem: To find all orders > $100, you must parse the string

// Structured logging — easy to query
_logger.LogInformation("User {UserId} placed order {OrderId} for {Amount:C}",
    userId, orderId, amount);
// Output: { "UserId": 42, "OrderId": 891, "Amount": 99.99, "Message": "..." }
// Query: Amount > 100 ← direct field query in any log aggregator

// Serilog (popular structured logging library)
builder.Host.UseSerilog((ctx, config) => {
    config
        .ReadFrom.Configuration(ctx.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithProperty("Application", "TaskFlow")
        .Enrich.WithProperty("Environment", ctx.HostingEnvironment.EnvironmentName)
        .WriteTo.Console(new JsonFormatter())
        .WriteTo.Seq("http://seq-server:5341") // centralized log storage
        .WriteTo.ApplicationInsights(telemetryClient, TelemetryConverter.Traces);
});
```

---

## Q2. What are log levels and when to use each?
**Answer:**
| Level | Use when | Example |
|---|---|---|
| `Trace` | Most detailed diagnostics (rarely used in prod) | Method entry/exit, SQL queries |
| `Debug` | Debugging information | Variable values, branch taken |
| `Information` | Significant events in normal flow | User logged in, order placed |
| `Warning` | Unexpected but recoverable situation | Retry attempted, deprecated API used |
| `Error` | Failure that doesn't stop the app | Request failed, operation failed |
| `Critical` | Critical failure requiring immediate attention | DB down, OOM, security breach |

```csharp
// appsettings.json — filter by level and category
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.EntityFrameworkCore.Database.Command": "Information" // log SQL
      }
    }
  }
}
```

---

## Q3. What is distributed tracing and OpenTelemetry?
**Answer:**
Distributed tracing tracks requests across multiple services with a correlation ID:

```
Request: Browser → Angular → ASP.NET Core API → SQL Server → External API
TraceId: abc123 (same across all services)
SpanId changes per service hop

Timeline:
00ms  API receives request (span: api-handler)
 5ms    Repository queries DB (span: ef-query)
15ms    HTTP call to Stripe (span: http-outgoing)
25ms  API returns response
```

```csharp
// OpenTelemetry in .NET
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing => {
        tracing
            .AddSource("MyApp")           // custom traces
            .AddAspNetCoreInstrumentation()  // HTTP requests
            .AddEntityFrameworkCoreInstrumentation() // EF queries
            .AddHttpClientInstrumentation()  // outgoing HTTP
            .AddSqlClientInstrumentation()   // raw SQL
            .AddOtlpExporter(opts => opts.Endpoint = new Uri("http://jaeger:4317")); // Jaeger
    })
    .WithMetrics(metrics => {
        metrics
            .AddAspNetCoreInstrumentation()
            .AddRuntimeInstrumentation()
            .AddPrometheusExporter(); // expose /metrics endpoint
    });

// Custom trace
private static readonly ActivitySource _activitySource = new("MyApp");

public async Task<Order> ProcessOrderAsync(int orderId)
{
    using var activity = _activitySource.StartActivity("ProcessOrder");
    activity?.SetTag("order.id", orderId);
    // ...
}
```

---

## Q4. What is in-memory caching and when should you use it?
**Answer:**
```csharp
// IMemoryCache — per-process, not shared across instances
builder.Services.AddMemoryCache();

public class ProductService(IMemoryCache cache, IProductRepository repo)
{
    public async Task<IEnumerable<Category>> GetCategoriesAsync()
    {
        return await cache.GetOrCreateAsync("categories", async entry => {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1);
            entry.SlidingExpiration = TimeSpan.FromMinutes(20); // reset timer on access
            entry.Priority = CacheItemPriority.High;
            return await repo.GetAllCategoriesAsync();
        });
    }

    public void InvalidateCategoriesCache()
        => cache.Remove("categories"); // call on create/update/delete
}

// IMemoryCache use cases:
// ✓ Reference data (categories, config, lookup tables)
// ✓ Computed results (aggregations, reports)
// ✗ User-specific data (each user has own cache)
// ✗ Data that must be consistent across servers
```

---

## Q5. What is distributed caching with Redis?
**Answer:**
```csharp
// Redis — shared cache across all server instances
builder.Services.AddStackExchangeRedisCache(opts => {
    opts.Configuration = builder.Configuration.GetConnectionString("Redis");
    opts.InstanceName  = "MyApp:";
});

// Use IDistributedCache
public class UserService(IDistributedCache cache, IUserRepository repo, IMapper mapper)
{
    public async Task<UserDto?> GetByIdAsync(int id)
    {
        var key = $"user:{id}";
        var cached = await cache.GetStringAsync(key);
        if (cached is not null)
            return JsonSerializer.Deserialize<UserDto>(cached);

        var user = await repo.GetByIdAsync(id);
        if (user is null) return null;

        var dto = mapper.Map<UserDto>(user);
        await cache.SetStringAsync(key, JsonSerializer.Serialize(dto), new() {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30)
        });
        return dto;
    }

    public async Task InvalidateAsync(int id)
        => await cache.RemoveAsync($"user:{id}");
}
```

---

## Q6. What is cache invalidation and what are the strategies?
**Answer:**
```csharp
// Cache invalidation strategies:

// 1. TTL (Time-to-Live) — expire after fixed duration (simplest, stale data window)
entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);

// 2. Write-through — update cache when writing to DB
public async Task UpdateUserAsync(int id, UpdateUserDto dto)
{
    await repo.UpdateAsync(id, dto); // DB update
    var updated = await repo.GetByIdAsync(id);
    await cache.SetStringAsync($"user:{id}", Serialize(updated)); // cache update
}

// 3. Cache-aside (lazy loading) — load into cache on first read, invalidate on write
// 4. Event-based invalidation — message broker notifies when data changes
// 5. Cache tags (advanced) — group related cache entries

// Redis tag-based invalidation
// Not built-in to IDistributedCache — use HybridCache (.NET 9) or custom tags
await cache.SetStringAsync("product:1", value, new() { Tags = new[] { "products" } });
await cache.RemoveByTagAsync("products"); // remove all products on any change
```

---

## Q7. What are Application Insights and what does it provide?
**Answer:**
Azure Application Insights is a full-stack APM (Application Performance Monitoring) service:

```csharp
// Install: Microsoft.ApplicationInsights.AspNetCore
builder.Services.AddApplicationInsightsTelemetry(
    builder.Configuration["ApplicationInsights:ConnectionString"]);

// Custom telemetry
public class OrderService(TelemetryClient telemetry)
{
    public async Task PlaceOrderAsync(CreateOrderDto dto)
    {
        var sw = Stopwatch.StartNew();
        try {
            var order = await ProcessAsync(dto);

            // Track event
            telemetry.TrackEvent("OrderPlaced", new Dictionary<string, string> {
                ["OrderId"]   = order.Id.ToString(),
                ["ProductId"] = dto.ProductId.ToString()
            }, new Dictionary<string, double> {
                ["OrderAmount"] = (double)order.Total
            });
        } catch (Exception ex) {
            telemetry.TrackException(ex);
            throw;
        } finally {
            // Track dependency
            telemetry.TrackDependency("OrderProcessing", "ProcessOrder", sw.Elapsed, true);
        }
    }
}
```

**Provides:** Request tracking, dependency tracking, exceptions, custom events, metrics, live metrics, alerting, distributed tracing, availability tests.

---

## Q8. What is the difference between monitoring and observability?
**Answer:**
```
Monitoring: Are known metrics within expected ranges?
  - CPU < 80%?
  - Response time < 200ms?
  - Error rate < 1%?
  Tells you THAT something is wrong.

Observability: Can you understand WHY something went wrong?
  Three pillars:
  1. Logs — what happened? (Serilog, Elasticsearch)
  2. Metrics — how is the system performing? (Prometheus, Grafana)
  3. Traces — where did the request go? (Jaeger, Zipkin, OpenTelemetry)
  Lets you debug unknown unknowns.

Good observability means you can ask novel questions about your system
without deploying new code.
```

---

## Q9. What is the EF Core performance optimization checklist?
**Answer:**
```csharp
// 1. AsNoTracking for read-only queries
await _db.Users.AsNoTracking().ToListAsync();

// 2. Project to DTO (avoid loading unused columns)
await _db.Users.Select(u => new UserDto { Id = u.Id, Name = u.Name }).ToListAsync();

// 3. Include only what you need
await _db.Orders.Include(o => o.Items).ToListAsync(); // not Include(o => o.User.Orders....)

// 4. Paginate — never return unbounded collections
await _db.Products.Skip(skip).Take(pageSize).ToListAsync();

// 5. Use indexes (check with .HasIndex in EF)
// 6. Use Split queries for cartesian explosion
await _db.Orders.Include(o => o.Items).AsSplitQuery().ToListAsync();

// 7. Use ExecuteUpdateAsync/ExecuteDeleteAsync for bulk operations
await _db.Users.Where(u => !u.IsActive).ExecuteDeleteAsync();

// 8. Log slow queries — set CommandTimeout, enable slow query log
builder.Logging.AddFilter("Microsoft.EntityFrameworkCore.Database.Command", LogLevel.Information);
// Look for high CommandExecuted Duration values

// 9. Use compiled queries for hot paths
private static readonly Func<AppDbContext, int, Task<User?>> GetUserById =
    EF.CompileAsyncQuery((AppDbContext db, int id) => db.Users.FirstOrDefault(u => u.Id == id));

var user = await GetUserById(_db, id); // 2-3x faster than regular query
```

---

## Q10. What are database query performance tools?
**Answer:**
```csharp
// 1. EF Core logging — log all SQL queries
builder.Services.AddDbContext<AppDbContext>(opts => opts
    .UseSqlServer(connStr)
    .LogTo(Console.WriteLine, new[] { DbLoggerCategory.Database.Command.Name }, LogLevel.Information)
    .EnableSensitiveDataLogging() // include parameter values (dev only!)
    .EnableDetailedErrors());

// 2. SQL Server Query Store (built into SQL Server)
// Captures and analyzes query plans, identifies regressions

// 3. MiniProfiler — shows query count and duration in browser
builder.Services.AddMiniProfiler(opts => {
    opts.RouteBasePath = "/profiler";
    opts.SqlFormatter = new StackExchange.Profiling.SqlFormatters.InlineFormatter();
}).AddEntityFramework();
app.UseMiniProfiler();

// 4. EF Core interceptors — log slow queries
public class SlowQueryInterceptor : DbCommandInterceptor
{
    public override async ValueTask<DbDataReader> ReaderExecutedAsync(...)
    {
        if (eventData.Duration.TotalMilliseconds > 500)
            _logger.LogWarning("Slow query ({Duration}ms): {SQL}",
                eventData.Duration.TotalMilliseconds, eventData.Command.CommandText);
        return result;
    }
}
```

---

## Q11. What is response caching vs output caching?
**Answer:**
```csharp
// Response Caching — sets HTTP cache headers for client/proxy caching
builder.Services.AddResponseCaching();
app.UseResponseCaching();

[ResponseCache(Duration = 60, Location = ResponseCacheLocation.Client)]
public IActionResult GetProductList() => Ok(products);
// Sets: Cache-Control: max-age=60
// Client doesn't make request if cached and fresh

// Output Caching (.NET 7+) — server-side cache of response body
builder.Services.AddOutputCache(opts => {
    opts.AddPolicy("Products", b => b.Expire(TimeSpan.FromMinutes(5)).Tag("products"));
});
app.UseOutputCache();

[OutputCache(PolicyName = "Products")]
public async Task<IActionResult> GetProducts() => Ok(await _svc.GetAllAsync());
// Server caches the response body — doesn't call handler again until expired/invalidated

// Invalidate on update
await _outputCache.EvictByTagAsync("products", ct);
```

---

## Q12. What is rate limiting and how does it protect performance?
**Answer:**
```csharp
// Rate limiting prevents abuse and protects server resources
builder.Services.AddRateLimiter(opts => {
    // Token bucket: allows bursts up to tokenLimit, replenishes at tokensPerPeriod
    opts.AddTokenBucketLimiter("api", opt => {
        opt.TokenLimit = 100;
        opt.ReplenishmentPeriod = TimeSpan.FromSeconds(10);
        opt.TokensPerPeriod = 20;
    });

    // Concurrency limiter: max 10 concurrent requests
    opts.AddConcurrencyLimiter("db-heavy", opt => {
        opt.PermitLimit = 10;
        opt.QueueProcessingOrder = QueueProcessingOrder.NewestFirst;
        opt.QueueLimit = 5;
    });
});

[EnableRateLimiting("db-heavy")]
[HttpGet("expensive-report")]
public async Task<IActionResult> GetReport() { }
```

---

## Q13. What are Prometheus metrics and how do you expose them?
**Answer:**
```csharp
// Install: prometheus-net.AspNetCore
builder.Services.AddOpenTelemetry().WithMetrics(m => m.AddPrometheusExporter());
app.MapPrometheusScrapingEndpoint("/metrics");

// Custom metrics
private static readonly Counter OrdersPlaced = Metrics
    .CreateCounter("orders_placed_total", "Total number of orders placed",
        new CounterConfiguration { LabelNames = new[] { "status" } });

private static readonly Histogram OrderProcessingTime = Metrics
    .CreateHistogram("order_processing_duration_seconds", "Order processing duration",
        new HistogramConfiguration { Buckets = Histogram.LinearBuckets(0.1, 0.1, 10) });

public async Task PlaceOrderAsync(CreateOrderDto dto)
{
    using var timer = OrderProcessingTime.NewTimer();
    try {
        await ProcessAsync(dto);
        OrdersPlaced.WithLabels("success").Inc();
    } catch {
        OrdersPlaced.WithLabels("failure").Inc();
        throw;
    }
}

// Prometheus scrapes /metrics, Grafana visualizes
```

---

## Q14. What is the health check pattern and how does it support observability?
**Answer:**
```csharp
// Kubernetes readiness and liveness probes
// Readiness: is the app ready to handle traffic?
// Liveness: is the app alive (restart if not)?

builder.Services.AddHealthChecks()
    .AddSqlServer(connStr, name: "db", tags: new[] { "ready" })
    .AddRedis(redisConnStr, name: "cache", tags: new[] { "ready" })
    .AddCheck("disk-space", () => {
        var drive = DriveInfo.GetDrives().First(d => d.Name == "/");
        return drive.AvailableFreeSpace > 1024 * 1024 * 100 // 100MB minimum
            ? HealthCheckResult.Healthy($"{drive.AvailableFreeSpace / 1024 / 1024}MB free")
            : HealthCheckResult.Degraded("Low disk space");
    }, tags: new[] { "ready" })
    .AddCheck("startup", () => _isStartupComplete
        ? HealthCheckResult.Healthy() : HealthCheckResult.Unhealthy("Still starting up"),
        tags: new[] { "live" });

// Kubernetes deployment.yaml
livenessProbe:
  httpGet: { path: /health/live, port: 8080 }
  initialDelaySeconds: 10, periodSeconds: 30, failureThreshold: 3
readinessProbe:
  httpGet: { path: /health/ready, port: 8080 }
  initialDelaySeconds: 5, periodSeconds: 10
```

---

## Q15. What are the top performance anti-patterns to avoid?
**Answer:**
```csharp
// 1. N+1 queries — EagerLoad with Include
// ❌ var orders = db.Orders.ToList(); foreach(var o in orders) Console.Write(o.User.Name);
// ✓  var orders = db.Orders.Include(o => o.User).ToListAsync();

// 2. Loading all data when paginating
// ❌ db.Products.ToList().Skip(page).Take(size) — loads ALL into memory first!
// ✓  db.Products.Skip(page).Take(size).ToList()

// 3. Synchronous I/O on thread pool
// ❌ public IActionResult Get() { Task.Run(async () => await db.ToListAsync()).Result; }
// ✓  public async Task<IActionResult> Get() { return Ok(await db.ToListAsync()); }

// 4. Missing cancellation token
// ❌ await db.Users.ToListAsync();
// ✓  await db.Users.ToListAsync(cancellationToken);

// 5. Not disposing DbContext (scoped lifetime handles this automatically)
// 6. Calling SaveChanges inside a loop (batch all changes first)
// 7. Using lazy loading in web APIs (use Include instead)
// 8. Not using AsNoTracking for read-only queries
// 9. Returning raw entities (infinite loops with circular references)
// 10. Not logging slow queries
```
