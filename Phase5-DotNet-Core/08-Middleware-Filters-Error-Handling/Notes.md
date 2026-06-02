# Topic 8: Middleware, Filters & Error Handling

## 📘 Middleware Deep Dive

Middleware components form a **pipeline** that processes every HTTP request and response.

### Pipeline Visualization

```
Request  →  Exception  →  CORS  →  Auth  →  Routing  →  Controller
Response ←  Exception  ←  CORS  ←  Auth  ←  Routing  ←  Controller
```

### Types of Middleware

| Type | Implementation | Use Case |
|------|---------------|----------|
| **Inline** | `app.Use(...)` | Quick, one-off logic |
| **Class-based** | Implement `IMiddleware` or convention | Reusable, testable |
| **Terminal** | `app.Run(...)` | Ends the pipeline |
| **Map/Branch** | `app.Map(path, ...)` | Branch pipeline by path |

---

## 📘 Custom Middleware — Class-Based

### Convention-Based (Most Common)

```csharp
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = Guid.NewGuid().ToString("N")[..8];
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        
        _logger.LogInformation("[{RequestId}] → {Method} {Path}",
            requestId, context.Request.Method, context.Request.Path);
        
        await _next(context);  // Call next middleware
        
        stopwatch.Stop();
        _logger.LogInformation("[{RequestId}] ← {StatusCode} ({Elapsed}ms)",
            requestId, context.Response.StatusCode, stopwatch.ElapsedMilliseconds);
    }
}

// Register
app.UseMiddleware<RequestLoggingMiddleware>();

// Or via extension method
public static class MiddlewareExtensions
{
    public static IApplicationBuilder UseRequestLogging(this IApplicationBuilder builder)
        => builder.UseMiddleware<RequestLoggingMiddleware>();
}

app.UseRequestLogging();
```

### Interface-Based (Supports DI for Scoped Services)

```csharp
public class CorrelationIdMiddleware : IMiddleware
{
    private readonly ILogger<CorrelationIdMiddleware> _logger;

    public CorrelationIdMiddleware(ILogger<CorrelationIdMiddleware> logger)
    {
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, RequestDelegate next)
    {
        var correlationId = context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Guid.NewGuid().ToString();
        
        context.Items["CorrelationId"] = correlationId;
        context.Response.Headers["X-Correlation-Id"] = correlationId;
        
        using (_logger.BeginScope(new Dictionary<string, object> { ["CorrelationId"] = correlationId }))
        {
            await next(context);
        }
    }
}

// Must register as service (IMiddleware requires this)
builder.Services.AddTransient<CorrelationIdMiddleware>();
app.UseMiddleware<CorrelationIdMiddleware>();
```

---

## 📘 Global Exception Handling Middleware

The most critical middleware — catches all unhandled exceptions and returns proper error responses.

```csharp
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger,
        IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);

        var (statusCode, message) = exception switch
        {
            NotFoundException => (StatusCodes.Status404NotFound, exception.Message),
            BusinessException => (StatusCodes.Status400BadRequest, exception.Message),
            ConflictException => (StatusCodes.Status409Conflict, exception.Message),
            ForbiddenException => (StatusCodes.Status403Forbidden, exception.Message),
            UnauthorizedAccessException => (StatusCodes.Status401Unauthorized, "Unauthorized"),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred")
        };

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";

        var problemDetails = new
        {
            type = $"https://httpstatuses.com/{statusCode}",
            title = GetTitle(statusCode),
            status = statusCode,
            detail = _env.IsDevelopment() ? exception.Message : message,
            instance = context.Request.Path.ToString(),
            traceId = context.TraceIdentifier,
            stackTrace = _env.IsDevelopment() ? exception.StackTrace : null
        };

        await context.Response.WriteAsJsonAsync(problemDetails);
    }

    private static string GetTitle(int statusCode) => statusCode switch
    {
        400 => "Bad Request",
        401 => "Unauthorized",
        403 => "Forbidden",
        404 => "Not Found",
        409 => "Conflict",
        500 => "Internal Server Error",
        _ => "Error"
    };
}

// Register FIRST in pipeline (catches everything below it)
app.UseMiddleware<GlobalExceptionMiddleware>();
```

---

## 📘 Action Filters

Filters run **around controller actions** — before and/or after action execution.

### Filter Types & Execution Order

```
Request → Authorization Filters → Resource Filters → Model Binding →
  Action Filters (Before) → ACTION → Action Filters (After) →
  Exception Filters → Result Filters → Response
```

| Filter Type | Interface | When |
|------------|-----------|------|
| **Authorization** | `IAuthorizationFilter` | Before everything |
| **Resource** | `IResourceFilter` | Before/after model binding |
| **Action** | `IActionFilter` | Before/after action execution |
| **Exception** | `IExceptionFilter` | When action throws exception |
| **Result** | `IResultFilter` | Before/after result execution |

### Custom Action Filter

```csharp
public class LogActionFilter : IAsyncActionFilter
{
    private readonly ILogger<LogActionFilter> _logger;

    public LogActionFilter(ILogger<LogActionFilter> logger)
    {
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        // BEFORE action
        var controllerName = context.RouteData.Values["controller"];
        var actionName = context.RouteData.Values["action"];
        _logger.LogInformation("Executing {Controller}.{Action}", controllerName, actionName);
        
        var result = await next();  // Execute the action
        
        // AFTER action
        if (result.Exception != null)
        {
            _logger.LogError(result.Exception, "Action {Action} threw exception", actionName);
        }
        else
        {
            _logger.LogInformation("Executed {Controller}.{Action} → {StatusCode}",
                controllerName, actionName,
                (result.Result as ObjectResult)?.StatusCode ?? 200);
        }
    }
}
```

### Validation Filter (Auto-Validate Models)

```csharp
public class ValidationFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        if (!context.ModelState.IsValid)
        {
            var errors = context.ModelState
                .Where(x => x.Value?.Errors.Count > 0)
                .ToDictionary(
                    x => x.Key,
                    x => x.Value!.Errors.Select(e => e.ErrorMessage).ToArray());
            
            context.Result = new BadRequestObjectResult(new
            {
                type = "https://tools.ietf.org/html/rfc7807",
                title = "Validation Error",
                status = 400,
                errors = errors
            });
            return;  // Short-circuit — don't call the action
        }
        
        await next();
    }
}

// Register globally
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationFilter>();
});
```

### Applying Filters

```csharp
// Global (applies to ALL actions)
builder.Services.AddControllers(options =>
{
    options.Filters.Add<LogActionFilter>();
    options.Filters.Add<ValidationFilter>();
});

// Controller-level
[ServiceFilter(typeof(LogActionFilter))]
public class ProductsController : ControllerBase { }

// Action-level
[ServiceFilter(typeof(AuditLogFilter))]
[HttpPost]
public async Task<IActionResult> Create(CreateProductDto dto) { }

// Attribute-based (no DI)
[TypeFilter(typeof(CustomFilter), Arguments = new object[] { "param1" })]
public async Task<IActionResult> Action() { }
```

---

## 📘 Exception Filters

Handle exceptions thrown by controller actions:

```csharp
public class ApiExceptionFilter : IExceptionFilter
{
    private readonly ILogger<ApiExceptionFilter> _logger;
    private readonly IHostEnvironment _env;

    public ApiExceptionFilter(ILogger<ApiExceptionFilter> logger, IHostEnvironment env)
    {
        _logger = logger;
        _env = env;
    }

    public void OnException(ExceptionContext context)
    {
        _logger.LogError(context.Exception, "Exception in {Action}",
            context.ActionDescriptor.DisplayName);

        var response = context.Exception switch
        {
            NotFoundException ex => new ProblemDetails
            {
                Status = 404,
                Title = "Not Found",
                Detail = ex.Message
            },
            BusinessException ex => new ProblemDetails
            {
                Status = 400,
                Title = "Business Rule Violation",
                Detail = ex.Message
            },
            _ => new ProblemDetails
            {
                Status = 500,
                Title = "Internal Server Error",
                Detail = _env.IsDevelopment() ? context.Exception.Message : "An error occurred"
            }
        };

        context.Result = new ObjectResult(response) { StatusCode = response.Status };
        context.ExceptionHandled = true;
    }
}
```

---

## 📘 Rate Limiting Middleware

```csharp
// .NET 7+: Built-in rate limiting
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("fixed", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 100;
        opt.QueueLimit = 0;
    });
    
    options.AddSlidingWindowLimiter("sliding", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.SegmentsPerWindow = 6;
        opt.PermitLimit = 100;
    });
    
    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = 429;
        await context.HttpContext.Response.WriteAsync("Too many requests");
    };
});

app.UseRateLimiter();

// Apply to endpoint
[EnableRateLimiting("fixed")]
[HttpGet]
public IActionResult GetAll() { }
```

---

## 📘 CORS (Cross-Origin Resource Sharing)

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngularApp", policy =>
    {
        policy.WithOrigins("http://localhost:4200", "https://myapp.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
    
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

app.UseCors("AllowAngularApp");

// Or per endpoint
[EnableCors("AllowAll")]
[HttpGet]
public IActionResult PublicData() { }
```

---

## 📘 Complete Middleware Pipeline

```csharp
var app = builder.Build();

// 1. Global exception handling (outermost — catches everything)
app.UseMiddleware<GlobalExceptionMiddleware>();

// 2. Request logging
app.UseMiddleware<RequestLoggingMiddleware>();

// 3. Correlation ID
app.UseMiddleware<CorrelationIdMiddleware>();

// 4. HTTPS redirection
app.UseHttpsRedirection();

// 5. CORS
app.UseCors("AllowAngularApp");

// 6. Rate limiting
app.UseRateLimiter();

// 7. Authentication
app.UseAuthentication();

// 8. Authorization
app.UseAuthorization();

// 9. Custom response headers
app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    await next();
});

// 10. Map controllers
app.MapControllers();

app.Run();
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| Middleware | Pipeline components for request/response processing |
| Custom Middleware | Class with `InvokeAsync(HttpContext, next)` |
| Exception Middleware | First in pipeline, catches all unhandled exceptions |
| Action Filters | Run around controller actions (before/after) |
| Exception Filters | Handle exceptions thrown by actions |
| Validation Filter | Auto-return 400 for invalid model state |
| Rate Limiting | Built-in fixed/sliding window limiters (.NET 7+) |
| CORS | Configure allowed origins for cross-domain requests |
| Pipeline Order | Exception → Logging → CORS → Auth → Authorization → Controllers |
| ProblemDetails | RFC 7807 standard error response format |

> **Next Topic**: Clean Architecture — Organizing all these pieces into a scalable project structure.
