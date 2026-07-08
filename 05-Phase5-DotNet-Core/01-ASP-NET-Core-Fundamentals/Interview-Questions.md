# Topic 01: ASP.NET Core Fundamentals — Interview Questions

---

## Q1. What is ASP.NET Core and how does it differ from classic ASP.NET?
**Answer:**
ASP.NET Core is a **cross-platform, open-source, high-performance** web framework built on .NET. It is a complete rewrite of classic ASP.NET.

| | ASP.NET (Classic) | ASP.NET Core |
|---|---|---|
| **Platform** | Windows only | Cross-platform (Windows, Linux, macOS) |
| **Web server** | IIS required | Kestrel built-in, IIS optional |
| **Performance** | Moderate | Top-tier (consistently ranks in TechEmpower benchmarks) |
| **Dependency Injection** | Optional (third-party) | Built-in |
| **Hosting** | IIS only | Self-hosted, Docker, cloud-native |
| **Configuration** | web.config (XML) | JSON, environment variables, secrets |
| **Open source** | Partial | Fully open source on GitHub |
| **Minimal APIs** | ✗ | ✓ (since .NET 6) |

---

## Q2. What is the ASP.NET Core middleware pipeline?
**Answer:**
The middleware pipeline is a chain of components that process HTTP requests and responses. Each middleware can:
- Do work **before** the next middleware (pre-processing).
- Call `next()` to pass control to the next middleware.
- Do work **after** the next middleware returns (post-processing).
- Short-circuit the pipeline (not call `next()`).

```csharp
var app = builder.Build();

// Order matters — each middleware runs in declaration order
app.UseExceptionHandler("/error");    // 1st — catches errors from anything below
app.UseHttpsRedirection();            // 2nd
app.UseStaticFiles();                 // 3rd
app.UseRouting();                     // 4th
app.UseAuthentication();              // 5th — who are you?
app.UseAuthorization();               // 6th — what can you do?
app.MapControllers();                 // 7th — route to controller actions
```

Custom middleware:
```csharp
app.Use(async (context, next) => {
    // Before
    Console.WriteLine($"Request: {context.Request.Path}");
    await next(context);
    // After
    Console.WriteLine($"Response: {context.Response.StatusCode}");
});
```

---

## Q3. What is `WebApplication.CreateBuilder()` and what does it set up?
**Answer:**
`WebApplication.CreateBuilder()` (introduced in .NET 6) sets up the host with sensible defaults:

```csharp
var builder = WebApplication.CreateBuilder(args);
// Sets up:
// - Kestrel web server
// - Default configuration (appsettings.json, environment variables, command-line args)
// - Logging (Console, Debug, EventSource)
// - Dependency Injection container
// - IWebHostEnvironment

// Add services to DI
builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseSqlServer(builder.Configuration.GetConnectionString("Default")));
builder.Services.AddScoped<IUserService, UserService>();

// Build and configure pipeline
var app = builder.Build();
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();
app.Run();
```

---

## Q4. What is the configuration system in ASP.NET Core?
**Answer:**
ASP.NET Core uses a layered configuration system — each source can override the previous:

```json
// appsettings.json (base)
{
  "ConnectionStrings": { "Default": "Server=localhost..." },
  "Logging": { "LogLevel": { "Default": "Information" } },
  "AppSettings": { "PageSize": 20, "AllowedOrigins": ["http://localhost:4200"] }
}

// appsettings.Development.json — overrides for dev
{ "ConnectionStrings": { "Default": "Server=.;Database=MyAppDev..." } }
```

**Provider priority (last wins):**
1. `appsettings.json`
2. `appsettings.{Environment}.json`
3. User secrets (Development only)
4. Environment variables
5. Command-line arguments

```csharp
// Read configuration
string connStr = builder.Configuration.GetConnectionString("Default");
string pageSize = builder.Configuration["AppSettings:PageSize"];

// Strongly typed options (preferred)
builder.Services.Configure<AppSettings>(builder.Configuration.GetSection("AppSettings"));

// Inject in service
public class UserService(IOptions<AppSettings> opts) {
    int pageSize = opts.Value.PageSize;
}
```

---

## Q5. What is the built-in Dependency Injection container in ASP.NET Core?
**Answer:**
ASP.NET Core has a built-in IoC container. Services are registered with a **lifetime** that controls how instances are created and shared:

| Lifetime | Scope | Created | Disposed |
|---|---|---|---|
| `Singleton` | Entire app lifetime | Once on first request | App shutdown |
| `Scoped` | Per HTTP request | Each request | End of request |
| `Transient` | Per injection point | Every time | When containing scope disposes |

```csharp
// Registration
builder.Services.AddSingleton<ICache, MemoryCache>();          // one instance ever
builder.Services.AddScoped<IUserRepository, UserRepository>();  // one per request
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>(); // new each injection

// Constructor injection (preferred)
public class UserController(IUserService svc, ILogger<UserController> logger)
{
    // svc and logger injected automatically
}

// Inject into middleware
app.Use(async (context, next) => {
    var db = context.RequestServices.GetRequiredService<AppDbContext>();
    await next();
});
```

---

## Q6. What are environments in ASP.NET Core?
**Answer:**
Environments allow different behaviour in Development, Staging, and Production:

```csharp
// Set via environment variable: ASPNETCORE_ENVIRONMENT
// or launchSettings.json for local dev

var app = builder.Build();

if (app.Environment.IsDevelopment()) {
    app.UseDeveloperExceptionPage(); // detailed error page
    app.UseSwagger();
    app.UseSwaggerUI();
} else {
    app.UseExceptionHandler("/error"); // generic error page
    app.UseHsts();
}

// Check environment anywhere
public class UserService(IWebHostEnvironment env) {
    void DoWork() {
        if (env.IsProduction()) UseProductionSetting();
    }
}
```

---

## Q7. What is the Kestrel web server?
**Answer:**
Kestrel is ASP.NET Core's built-in, cross-platform, high-performance web server:

```csharp
// Kestrel configured by default; customize in Program.cs
builder.WebHost.ConfigureKestrel(options => {
    options.ListenAnyIP(5000);                         // HTTP
    options.ListenAnyIP(5001, lo => lo.UseHttps());    // HTTPS
    options.Limits.MaxRequestBodySize = 10 * 1024 * 1024; // 10MB
    options.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(2);
});
```

**Deployment models:**
- **Self-hosted (Kestrel directly)** — for Linux/Docker/cloud-native (recommended).
- **Reverse proxy + Kestrel** — Nginx/Apache → Kestrel (adds TLS termination, load balancing).
- **IIS in-process** — Kestrel replaced by IIS kernel-mode HTTP.sys (Windows only, best performance on IIS).

---

## Q8. What is logging in ASP.NET Core?
**Answer:**
ASP.NET Core has a built-in, provider-agnostic logging abstraction:

```csharp
// Built-in providers: Console, Debug, EventSource, EventLog, TraceSource
// Third-party: Serilog, NLog, log4net

// appsettings.json
{
  "Logging": {
    "LogLevel": { "Default": "Information", "Microsoft": "Warning" }
  }
}

// Usage in a service/controller
public class UserService(ILogger<UserService> logger) {
    public void CreateUser(User user) {
        logger.LogInformation("Creating user {UserId}", user.Id);
        try { _repo.Add(user); }
        catch (Exception ex) {
            logger.LogError(ex, "Failed to create user {UserId}", user.Id);
            throw;
        }
    }
}
```

**Serilog (popular structured logging):**
```csharp
builder.Host.UseSerilog((ctx, config) =>
    config.ReadFrom.Configuration(ctx.Configuration)
          .WriteTo.Console()
          .WriteTo.File("logs/app-.log", rollingInterval: RollingInterval.Day));
```

---

## Q9. What are Minimal APIs and when should you use them?
**Answer:**
Minimal APIs (introduced in .NET 6) let you define HTTP endpoints without controllers:

```csharp
var app = builder.Build();

// GET /users
app.MapGet("/users", async (IUserRepository repo) =>
    Results.Ok(await repo.GetAllAsync()));

// GET /users/{id}
app.MapGet("/users/{id:int}", async (int id, IUserRepository repo) => {
    var user = await repo.GetByIdAsync(id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});

// POST /users
app.MapPost("/users", async (CreateUserDto dto, IUserService svc) => {
    var user = await svc.CreateAsync(dto);
    return Results.CreatedAtRoute("GetUser", new { user.Id }, user);
});

// Grouped with RouteGroupBuilder
var users = app.MapGroup("/api/users").RequireAuthorization();
users.MapGet("/", GetAll);
users.MapGet("/{id}", GetById);
```

**Use Minimal APIs for:** Microservices, simple CRUD APIs, when you want less ceremony.
**Use Controllers for:** Complex APIs, large teams, when you need filters, model binders, convention-based routing.

---

## Q10. What is HTTPS redirection and HSTS?
**Answer:**
```csharp
// UseHttpsRedirection — redirects HTTP to HTTPS
app.UseHttpsRedirection(); // 307 Temporary Redirect (dev) or 301 Permanent (prod)

// UseHsts — sends Strict-Transport-Security header (production only)
// Tells browsers to ALWAYS use HTTPS for this domain for a specified duration
if (!app.Environment.IsDevelopment()) {
    app.UseHsts(); // adds: Strict-Transport-Security: max-age=31536000
}

// Configure HSTS options
builder.Services.AddHsts(options => {
    options.MaxAge = TimeSpan.FromDays(365);
    options.IncludeSubDomains = true;
    options.Preload = true; // submit to browser preload lists
});
```

---

## Q11. What is the `IHostedService` and `BackgroundService`?
**Answer:**
Background services run long-running tasks alongside the web server:

```csharp
// BackgroundService — base class for background tasks
public class QueueWorker : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var job = await _queue.DequeueAsync(stoppingToken);
            await ProcessJob(job);
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }
}

// Register in DI
builder.Services.AddHostedService<QueueWorker>();
builder.Services.AddHostedService<DatabaseCleanupService>();
```

Use cases: message queue consumers, scheduled tasks (use Quartz.NET or Hangfire for cron), cache warming, health monitoring.

---

## Q12. What are Health Checks in ASP.NET Core?
**Answer:**
Health checks expose an endpoint that monitoring systems use to check app status:

```csharp
builder.Services.AddHealthChecks()
    .AddSqlServer(connectionString, name: "database")
    .AddRedis(redisConnectionString, name: "redis")
    .AddCheck<CustomHealthCheck>("custom");

app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready",  new() { Predicate = check => check.Tags.Contains("ready") });
app.MapHealthChecks("/health/live",   new() { Predicate = _ => false }); // basic liveness

// Custom check
public class CustomHealthCheck : IHealthCheck {
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext ctx, CancellationToken ct) {
        return Task.FromResult(
            _isHealthy ? HealthCheckResult.Healthy("OK") : HealthCheckResult.Unhealthy("Degraded"));
    }
}
```

---

## Q13. What is the difference between `IOptions<T>`, `IOptionsSnapshot<T>`, and `IOptionsMonitor<T>`?
**Answer:**
| | `IOptions<T>` | `IOptionsSnapshot<T>` | `IOptionsMonitor<T>` |
|---|---|---|---|
| **Lifetime** | Singleton | Scoped (per-request) | Singleton |
| **Reloads config?** | ✗ No | ✓ Per request | ✓ On change (OnChange) |
| **Use in** | Singleton services | Scoped/Transient services | Singleton + live reload |

```csharp
// IOptions — simple, never changes
public class EmailService(IOptions<SmtpSettings> opts) { }

// IOptionsSnapshot — picks up config changes on next request
public class UserService(IOptionsSnapshot<FeatureFlags> flags) { }

// IOptionsMonitor — singleton that reacts to config file changes
public class ThemeService(IOptionsMonitor<ThemeSettings> monitor) {
    monitor.OnChange(settings => ApplyTheme(settings));
}
```

---

## Q14. What is the `appsettings.json` vs User Secrets vs Environment Variables?
**Answer:**
```json
// appsettings.json — committed to git (non-sensitive config)
{ "ApiUrl": "https://api.example.com", "PageSize": 20 }

// appsettings.Development.json — committed to git (dev-specific)
{ "Logging": { "LogLevel": { "Default": "Debug" } } }
```

```bash
# User Secrets — local dev only, stored in %APPDATA% (never committed)
dotnet user-secrets set "ConnectionStrings:Default" "Server=localhost;..."
dotnet user-secrets set "Jwt:Secret" "my-super-secret-key"
```

```bash
# Environment variables — deployed environments (Docker, Azure, etc.)
ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__Default=Server=prod-server;...  # __ replaces :
Jwt__Secret=production-jwt-secret
```

**Security rule:** Never commit secrets to source control. Use User Secrets locally and environment variables / Azure Key Vault in production.

---

## Q15. What is CORS and how do you configure it in ASP.NET Core?
**Answer:**
CORS (Cross-Origin Resource Sharing) is a browser security policy. The server must explicitly allow cross-origin requests:

```csharp
// Define a named policy
builder.Services.AddCors(options => {
    options.AddPolicy("AllowAngularApp", policy => {
        policy.WithOrigins("http://localhost:4200", "https://myapp.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // needed for cookies/auth headers
    });

    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()); // open (dev only)
});

// Apply in pipeline (BEFORE routing + authorization)
app.UseCors("AllowAngularApp");

// Per-endpoint with attributes
[EnableCors("AllowAngularApp")]
public class UserController : ControllerBase { }

// Minimal APIs
app.MapGet("/api/data", Handler).RequireCors("AllowAngularApp");
```
