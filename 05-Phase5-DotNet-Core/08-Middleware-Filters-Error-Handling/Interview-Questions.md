# Topic 08: Middleware, Filters & Error Handling — Interview Questions

---

## Q1. What is middleware and how does it differ from filters?
**Answer:**
| | Middleware | Filters |
|---|---|---|
| **Level** | HTTP pipeline | MVC/API action pipeline |
| **Scope** | All requests | Controller/action requests only |
| **Knowledge** | HTTP context only | Action, result, controller context |
| **Order** | Defined in Program.cs | Filter pipeline order |
| **Use for** | HTTPS, CORS, logging, auth | Validation, logging per-action, result transformation |

```csharp
// Middleware — wraps entire pipeline
app.Use(async (context, next) => {
    // before all actions
    await next(context);
    // after all actions
});

// Filter — wraps action execution
public class AuditFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext ctx) { /* before action */ }
    public void OnActionExecuted(ActionExecutedContext ctx)   { /* after action */ }
}
```

---

## Q2. How do you write a custom middleware?
**Answer:**
```csharp
// Convention-based middleware (no interface required)
public class RequestTimingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestTimingMiddleware> _logger;

    public RequestTimingMiddleware(RequestDelegate next, ILogger<RequestTimingMiddleware> logger)
        { _next = next; _logger = logger; }

    public async Task InvokeAsync(HttpContext context)
    {
        var sw = Stopwatch.StartNew();
        await _next(context);           // call next middleware
        sw.Stop();
        _logger.LogInformation("{Method} {Path} completed in {Ms}ms",
            context.Request.Method, context.Request.Path, sw.ElapsedMilliseconds);
    }
}

// Extension method for clean registration
public static class MiddlewareExtensions
{
    public static IApplicationBuilder UseRequestTiming(this IApplicationBuilder app)
        => app.UseMiddleware<RequestTimingMiddleware>();
}

// Usage
app.UseRequestTiming();

// Inline middleware with app.Use
app.Use(async (context, next) => {
    context.Response.Headers.Add("X-Frame-Options", "DENY");
    context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
    await next(context);
});
```

---

## Q3. What are the types of filters in ASP.NET Core?
**Answer:**
| Filter Type | Interface | Runs |
|---|---|---|
| Authorization | `IAuthorizationFilter` | Before everything |
| Resource | `IResourceFilter` | After auth, before model binding |
| Action | `IActionFilter` | Before/after action method |
| Exception | `IExceptionFilter` | When unhandled exception occurs |
| Result | `IResultFilter` | Before/after action result executed |

```csharp
// Filter pipeline order:
// Authorization → Resource (before) → [Model Binding] → Action (before) → [Action] → Action (after) → Exception* → Result (before) → [Result] → Result (after) → Resource (after)

// Action filter
public class ValidateModelFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext ctx)
    {
        if (!ctx.ModelState.IsValid)
            ctx.Result = new BadRequestObjectResult(ctx.ModelState);
    }
    public void OnActionExecuted(ActionExecutedContext ctx) { }
}

// Exception filter
public class GlobalExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext ctx)
    {
        ctx.Result = new ObjectResult(new ProblemDetails {
            Status = 500, Title = "Server Error", Detail = ctx.Exception.Message
        }) { StatusCode = 500 };
        ctx.ExceptionHandled = true;
    }
}
```

---

## Q4. What is exception handling middleware and how does it work?
**Answer:**
```csharp
// Built-in exception handler
if (app.Environment.IsDevelopment())
    app.UseDeveloperExceptionPage(); // detailed stack trace
else
    app.UseExceptionHandler("/error"); // generic error page

// Custom global exception middleware
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext ctx)
    {
        try { await next(ctx); }
        catch (Exception ex) { await HandleExceptionAsync(ctx, ex); }
    }

    private async Task HandleExceptionAsync(HttpContext ctx, Exception ex)
    {
        logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);

        var (status, title) = ex switch {
            NotFoundException    => (404, "Not Found"),
            ConflictException    => (409, "Conflict"),
            BusinessException    => (422, "Business Rule Violation"),
            ForbiddenException   => (403, "Forbidden"),
            _                    => (500, "Internal Server Error")
        };

        ctx.Response.StatusCode = status;
        ctx.Response.ContentType = "application/problem+json";

        var problem = new ProblemDetails {
            Status = status, Title = title,
            Detail = app.Environment.IsDevelopment() ? ex.Message : "An error occurred",
            Extensions = { ["traceId"] = Activity.Current?.Id }
        };
        await ctx.Response.WriteAsJsonAsync(problem);
    }
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
```

---

## Q5. What is the `UseExceptionHandler` vs a custom exception middleware?
**Answer:**
```csharp
// UseExceptionHandler — built-in, re-executes on a different path
app.UseExceptionHandler(opt => opt.Run(async ctx => {
    var exceptionFeature = ctx.Features.Get<IExceptionHandlerPathFeature>();
    var problem = new ProblemDetails { Status = 500, Detail = exceptionFeature?.Error.Message };
    await ctx.Response.WriteAsJsonAsync(problem);
}));

// OR route to an error controller
app.UseExceptionHandler("/api/error");
[ApiExplorerSettings(IgnoreApi = true)]
[Route("api/error")]
public class ErrorController : ControllerBase {
    [HttpGet, HttpPost]
    public IActionResult Error() {
        var exFeature = HttpContext.Features.Get<IExceptionHandlerPathFeature>();
        return Problem(detail: exFeature?.Error.Message);
    }
}

// Custom middleware — more control, can access services, inspect exception type
// UseExceptionHandler — simpler, built-in, handles edge cases well (response already started)
```

---

## Q6. What are attribute filters and how do they differ from service filters?
**Answer:**
```csharp
// Attribute filter — constructor injection limited (no DI)
public class CacheAttribute : Attribute, IActionFilter
{
    private readonly int _durationSeconds;
    public CacheAttribute(int seconds) => _durationSeconds = seconds;

    public void OnActionExecuting(ActionExecutingContext ctx) { }
    public void OnActionExecuted(ActionExecutedContext ctx) {
        ctx.HttpContext.Response.Headers.CacheControl = $"public, max-age={_durationSeconds}";
    }
}
[HttpGet, Cache(300)] // applied as attribute
public IActionResult GetData() => Ok();

// ServiceFilter — full DI support
public class AuditFilter(IAuditService audit) : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext ctx) => audit.Log(ctx.ActionDescriptor.DisplayName!);
    public void OnActionExecuted(ActionExecutedContext ctx) { }
}
builder.Services.AddScoped<AuditFilter>(); // register in DI
[ServiceFilter(typeof(AuditFilter))]       // use on controller/action
public class UserController : ControllerBase { }
```

---

## Q7. What is a result filter and when is it useful?
**Answer:**
Result filters run before and after action results are executed — useful for transforming or wrapping responses:

```csharp
// Add API envelope to all responses
public class ApiResponseFilter : IResultFilter
{
    public void OnResultExecuting(ResultExecutingContext ctx)
    {
        if (ctx.Result is ObjectResult obj && obj.Value is not ProblemDetails)
        {
            obj.Value = new ApiResponse<object> {
                Success = true,
                Data    = obj.Value,
                TraceId = Activity.Current?.Id
            };
        }
    }
    public void OnResultExecuted(ResultExecutedContext ctx) { }
}

// Add globally
builder.Services.AddControllers(opt => opt.Filters.Add<ApiResponseFilter>());
```

---

## Q8. What is rate limiting in ASP.NET Core?
**Answer:**
Rate limiting (built-in since .NET 7) restricts how many requests a client can make in a time window:

```csharp
// Install: System.Threading.RateLimiting (built-in .NET 7+)
builder.Services.AddRateLimiter(opts => {
    // Fixed window: 10 requests per minute per IP
    opts.AddFixedWindowLimiter("fixed", opt => {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 10;
        opt.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 5;
    });

    // Token bucket: 100 tokens, replenish 20 per 30s
    opts.AddTokenBucketLimiter("api", opt => {
        opt.TokenLimit = 100;
        opt.ReplenishmentPeriod = TimeSpan.FromSeconds(30);
        opt.TokensPerPeriod = 20;
    });

    opts.OnRejected = async (ctx, ct) => {
        ctx.HttpContext.Response.StatusCode = 429; // Too Many Requests
        await ctx.HttpContext.Response.WriteAsync("Rate limit exceeded. Try again later.", ct);
    };
});

app.UseRateLimiter();
[EnableRateLimiting("fixed")]
public class AuthController : ControllerBase { }
```

---

## Q9. What is response caching middleware?
**Answer:**
```csharp
// Add response caching services
builder.Services.AddResponseCaching();

// Add to pipeline
app.UseResponseCaching();

// On actions
[HttpGet]
[ResponseCache(Duration = 60, Location = ResponseCacheLocation.Client)]
public IActionResult GetData() => Ok(data);

// Cache profile (reusable configuration)
builder.Services.AddControllers(opt => {
    opt.CacheProfiles.Add("Standard", new CacheProfile { Duration = 60 });
    opt.CacheProfiles.Add("Never", new CacheProfile { NoStore = true });
});
[ResponseCache(CacheProfileName = "Standard")]
public IActionResult GetProducts() => Ok();

// For dynamic content: Vary by header/query
[ResponseCache(Duration = 60, VaryByHeader = "Accept-Language")]
public IActionResult GetLocalized() => Ok();
```

---

## Q10. What is output caching (ASP.NET Core 7+)?
**Answer:**
Output caching caches entire responses on the server, more powerful than response caching:

```csharp
builder.Services.AddOutputCache(options => {
    options.AddBasePolicy(builder => builder.Expire(TimeSpan.FromSeconds(10)));
    options.AddPolicy("Products", builder => builder
        .Expire(TimeSpan.FromMinutes(5))
        .Tag("products")
        .SetVaryByQuery("category", "page"));
});

app.UseOutputCache();

[HttpGet]
[OutputCache(PolicyName = "Products")]
public async Task<IActionResult> GetProducts([FromQuery] string category)
    => Ok(await _svc.GetProductsAsync(category));

// Invalidate cache by tag (after update)
[HttpPost]
public async Task<IActionResult> CreateProduct(CreateProductDto dto,
    [FromServices] IOutputCacheStore cache)
{
    await _svc.CreateAsync(dto);
    await cache.EvictByTagAsync("products", default); // clear products cache
    return Created();
}
```

---

## Q11. What are health check middleware and conventions?
**Answer:**
```csharp
// Middleware order: health checks should be early (before auth) for infra checks
app.MapHealthChecks("/health/live", new() {
    Predicate = _ => false // liveness: just "is process alive?"
}).AllowAnonymous();

app.MapHealthChecks("/health/ready", new() {
    Predicate = check => check.Tags.Contains("ready"), // readiness: DB, cache connected?
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse // JSON report
}).RequireAuthorization("InternalOnly");
```

---

## Q12. What is the middleware pipeline short-circuiting?
**Answer:**
When a middleware doesn't call `next()`, it short-circuits the pipeline — subsequent middleware and the action don't run:

```csharp
// Short-circuit example: return early for certain paths
app.Use(async (context, next) => {
    if (context.Request.Path == "/favicon.ico") {
        context.Response.StatusCode = 204; // No Content
        return; // ❌ doesn't call next — pipeline stops here
    }
    await next(context);
});

// Rate limiter short-circuits when limit exceeded
// Authentication middleware short-circuits on invalid token
// Authorization middleware short-circuits on forbidden access

// Terminal middleware with app.Run (always short-circuits)
app.Run(async ctx => {
    await ctx.Response.WriteAsync("This is a terminal middleware — nothing after this runs");
});
```

---

## Q13. What is the `IMiddleware` interface?
**Answer:**
`IMiddleware` provides DI-friendly middleware (compared to the convention-based approach):

```csharp
// IMiddleware — supports full DI, registered as scoped/transient
public class TenantMiddleware : IMiddleware
{
    private readonly ITenantService _tenantSvc; // injected via DI

    public TenantMiddleware(ITenantService tenantSvc) => _tenantSvc = tenantSvc;

    public async Task InvokeAsync(HttpContext ctx, RequestDelegate next)
    {
        var tenantId = ctx.Request.Headers["X-Tenant-Id"].FirstOrDefault();
        if (tenantId is not null) _tenantSvc.SetTenant(tenantId);
        await next(ctx);
    }
}

// Register both the middleware AND the service
builder.Services.AddScoped<TenantMiddleware>(); // must register!
app.UseMiddleware<TenantMiddleware>();

// Difference from convention-based:
// Convention: middleware instantiated once (singleton-like), dependencies in Invoke params
// IMiddleware: new instance per request (scoped), natural DI in constructor
```

---

## Q14. What is `app.UseWhen` and `app.MapWhen`?
**Answer:**
Conditionally apply middleware based on the request:

```csharp
// UseWhen — conditionally add middleware, then rejoin main pipeline
app.UseWhen(
    ctx => ctx.Request.Path.StartsWithSegments("/api"),
    apiApp => {
        apiApp.UseAuthentication();
        apiApp.UseAuthorization();
    }
);

// MapWhen — branch pipeline (doesn't rejoin)
app.MapWhen(
    ctx => ctx.Request.Path.StartsWithSegments("/webhooks"),
    webhookApp => {
        webhookApp.UseMiddleware<WebhookSignatureVerifier>();
        webhookApp.Run(async ctx => {
            var payload = await ctx.Request.ReadFromJsonAsync<WebhookEvent>();
            // process webhook
        });
    }
);
```

---

## Q15. What are response compression and static file middleware?
**Answer:**
```csharp
// Response compression — compress response bodies (Gzip, Brotli)
builder.Services.AddResponseCompression(opts => {
    opts.EnableForHttps = true;
    opts.Providers.Add<BrotliCompressionProvider>();
    opts.Providers.Add<GzipCompressionProvider>();
    opts.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[] { "application/json" });
});
app.UseResponseCompression();

// Static files — serve files from wwwroot/
app.UseStaticFiles(); // default: wwwroot/

// Custom static file directory
app.UseStaticFiles(new StaticFileOptions {
    FileProvider = new PhysicalFileProvider(Path.Combine(env.ContentRootPath, "uploads")),
    RequestPath  = "/uploads"
});

// Default files (serve index.html for /)
app.UseDefaultFiles(); // must be before UseStaticFiles
app.UseStaticFiles();

// Directory browsing (dev only)
app.UseDirectoryBrowser(new DirectoryBrowserOptions {
    FileProvider = new PhysicalFileProvider(Path.Combine(env.WebRootPath, "images")),
    RequestPath  = "/images"
});
```
