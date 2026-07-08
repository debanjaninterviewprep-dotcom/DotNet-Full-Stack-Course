# Topic 03: Backend API Foundation — Interview Questions

---

## Q1. What makes a well-designed REST API?
**Answer:**
1. **Consistent naming** — plural nouns, lowercase, hyphens (`/api/user-profiles`, not `/api/UserProfiles`).
2. **Proper HTTP methods** — GET reads, POST creates, PUT full-update, PATCH partial-update, DELETE removes.
3. **Meaningful status codes** — 200/201/204/400/401/403/404/409/422/500.
4. **Problem Details errors** — RFC 7807 structured error responses.
5. **Versioning** — plan from day one (`/api/v1/`).
6. **Pagination** — never return unbounded collections.
7. **Filtering, sorting** — via query parameters.
8. **Documentation** — OpenAPI/Swagger always up to date.
9. **Security** — HTTPS always, JWT, rate limiting, input validation.
10. **Idempotency keys** — for non-idempotent operations (POST with `Idempotency-Key` header).

---

## Q2. What are the HTTP status codes and when to use each?
**Answer:**
```
2xx — Success
  200 OK           — successful GET, PUT, PATCH
  201 Created      — successful POST (include Location header)
  202 Accepted     — async operation started
  204 No Content   — successful DELETE or PUT with no body

3xx — Redirection
  301 Moved Permanently — resource permanently moved
  302 Found (Redirect)  — temporary redirect
  304 Not Modified      — cached response still valid (ETags)

4xx — Client Errors
  400 Bad Request       — malformed request, validation error
  401 Unauthorized      — missing or invalid authentication
  403 Forbidden         — authenticated but not authorized
  404 Not Found         — resource doesn't exist
  405 Method Not Allowed — HTTP method not supported
  409 Conflict          — duplicate key, concurrent update conflict
  410 Gone              — resource permanently deleted
  422 Unprocessable     — valid format but semantic validation failed
  429 Too Many Requests — rate limit exceeded

5xx — Server Errors
  500 Internal Server Error — unexpected server error
  502 Bad Gateway           — upstream service error
  503 Service Unavailable   — server overloaded or down
  504 Gateway Timeout       — upstream timeout
```

---

## Q3. What is idempotency in APIs and how do you implement it?
**Answer:**
An idempotent operation produces the same result regardless of how many times it's executed:

```
Idempotent:   GET, PUT, DELETE, HEAD, OPTIONS
Non-idempotent: POST (creates new resource each call)

Problem: User double-clicks "Pay" → 2 payment requests → 2 charges!

Solution: Idempotency keys
Client sends: POST /api/payments
             Idempotency-Key: uuid-unique-per-operation
             { "amount": 99.99 }

Server stores result keyed by Idempotency-Key
Second call with same key returns cached result — no double charge
```

```csharp
[HttpPost]
public async Task<IActionResult> CreatePayment(
    [FromBody] CreatePaymentDto dto,
    [FromHeader(Name = "Idempotency-Key")] string? idempotencyKey)
{
    if (idempotencyKey is not null) {
        var cached = await _cache.GetAsync<PaymentDto>(idempotencyKey);
        if (cached is not null) return Ok(cached); // return cached result
    }

    var payment = await _paymentService.CreateAsync(dto);

    if (idempotencyKey is not null)
        await _cache.SetAsync(idempotencyKey, payment, TimeSpan.FromHours(24));

    return CreatedAtAction(nameof(GetById), new { payment.Id }, payment);
}
```

---

## Q4. What is the difference between REST and gRPC?
**Answer:**
| | REST/HTTP | gRPC |
|---|---|---|
| **Protocol** | HTTP/1.1 or HTTP/2 | HTTP/2 only |
| **Data format** | JSON (text) | Protocol Buffers (binary) |
| **Performance** | Moderate | 5-10x faster (binary, multiplexing) |
| **Streaming** | Limited | First-class (server, client, bidirectional) |
| **Contract** | OpenAPI (optional) | `.proto` file (required) |
| **Browser support** | ✓ Native | ✗ Needs gRPC-Web proxy |
| **Human readable** | ✓ | ✗ |
| **Code generation** | Optional | Required |

```protobuf
// users.proto — contract definition
service UserService {
    rpc GetUser (GetUserRequest) returns (UserDto);
    rpc CreateUser (CreateUserRequest) returns (UserDto);
    rpc ListUsers (ListUsersRequest) returns (stream UserDto); // streaming
}
```

**Use gRPC for:** Microservice-to-microservice communication, streaming data, high-throughput internal APIs.
**Use REST for:** Public APIs, browser clients, when human readability matters.

---

## Q5. What is GraphQL and when would you use it over REST?
**Answer:**
GraphQL is a query language that lets clients request exactly the data they need:

```graphql
# Client requests only what it needs (no over-fetching)
query {
  user(id: 42) {
    name
    email
    orders(last: 5) {
      id
      total
      items { productName quantity }
    }
  }
}

# Compare: REST needs multiple calls
GET /api/users/42          → gets all user fields
GET /api/users/42/orders   → gets all order fields, all orders
```

**Use GraphQL when:**
- Frontend needs vary widely (mobile vs web).
- Many nested resources requiring multiple REST calls.
- Rapid prototyping where API shape evolves frequently.

**Stick with REST when:**
- Public API consumed by many clients.
- Caching is critical (REST caches easily via HTTP headers).
- Team is more familiar with REST.

---

## Q6. What is rate limiting and how do you implement it per user?
**Answer:**
```csharp
// .NET 7+ built-in rate limiting
builder.Services.AddRateLimiter(opts => {
    // Per-user rate limit (based on authenticated user ID)
    opts.AddPolicy("per-user", ctx => {
        var userId = ctx.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anonymous";
        return RateLimitPartition.GetFixedWindowLimiter(userId, _ => new() {
            Window = TimeSpan.FromMinutes(1),
            PermitLimit = 60  // 60 requests per minute per user
        });
    });

    // Stricter limit for sensitive endpoints
    opts.AddPolicy("auth-limit", ctx =>
        RateLimitPartition.GetFixedWindowLimiter(
            ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new() { Window = TimeSpan.FromMinutes(15), PermitLimit = 5 }));

    opts.OnRejected = async (ctx, ct) => {
        ctx.HttpContext.Response.StatusCode = 429;
        if (ctx.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
            ctx.HttpContext.Response.Headers.RetryAfter = retryAfter.TotalSeconds.ToString();
        await ctx.HttpContext.Response.WriteAsync("Rate limit exceeded. Try again later.", ct);
    };
});

// Apply
[EnableRateLimiting("auth-limit")]
[HttpPost("login")]
public async Task<IActionResult> Login(LoginDto dto) => Ok();
```

---

## Q7. What is API authentication vs authorization and which HTTP codes do they return?
**Answer:**
```csharp
// Authentication — who are you?
// Returns 401 Unauthorized when token is missing/invalid/expired

// Authorization — what can you do?
// Returns 403 Forbidden when authenticated but not permitted

// Common mistakes:
// ❌ Returning 401 for "not allowed" (forbidden) — wrong semantics
// ❌ Returning 403 for "not logged in" — gives attackers info

// Correct flow:
// 1. No token → 401 Unauthorized (you need to authenticate)
// 2. Invalid token → 401 Unauthorized
// 3. Valid token, insufficient role → 403 Forbidden
// 4. Valid token, resource not yours → 403 Forbidden (or 404 to hide existence)

// In ASP.NET Core:
[Authorize(Roles = "Admin")]  // 401 if not authenticated, 403 if not Admin
public IActionResult AdminOnly() => Ok();

// Return 404 instead of 403 to hide resource existence
[HttpGet("{id}")]
public async Task<IActionResult> GetOrder(int id) {
    var order = await _repo.GetByIdAsync(id);
    if (order is null || order.UserId != CurrentUserId)
        return NotFound(); // hide whether resource exists at all
    return Ok(order);
}
```

---

## Q8. What is request/response logging and how do you implement it?
**Answer:**
```csharp
// Middleware for logging all requests and responses
public class RequestResponseLoggingMiddleware(RequestDelegate next, ILogger<RequestResponseLoggingMiddleware> log)
{
    public async Task InvokeAsync(HttpContext ctx)
    {
        var requestId = ctx.TraceIdentifier;
        log.LogInformation("→ {Method} {Path} {QueryString} [{RequestId}]",
            ctx.Request.Method, ctx.Request.Path, ctx.Request.QueryString, requestId);

        var sw = Stopwatch.StartNew();
        await next(ctx);
        sw.Stop();

        log.LogInformation("← {StatusCode} {Path} {Duration}ms [{RequestId}]",
            ctx.Response.StatusCode, ctx.Request.Path, sw.ElapsedMilliseconds, requestId);
    }
}

// Or use built-in HTTP logging (ASP.NET Core 6+)
builder.Services.AddHttpLogging(logging => {
    logging.LoggingFields = HttpLoggingFields.All;
    logging.RequestHeaders.Add("X-Correlation-Id");
    logging.ResponseHeaders.Add("Content-Type");
    logging.MediaTypeOptions.AddText("application/json");
    logging.RequestBodyLogLimit = 4096;
    logging.ResponseBodyLogLimit = 4096;
});
app.UseHttpLogging();
```

---

## Q9. What is an ETag and how does it enable conditional requests?
**Answer:**
ETags enable efficient caching and concurrent update protection:

```csharp
// ETag — entity tag: hash/version of the resource
[HttpGet("{id}")]
public async Task<IActionResult> GetUser(int id)
{
    var user = await _svc.GetByIdAsync(id);
    var etag = new EntityTagHeaderValue($"\"{user.RowVersion}\"");

    // If client already has current version — return 304 Not Modified
    if (Request.Headers.IfNoneMatch == etag.ToString())
        return StatusCode(304);

    Response.Headers.ETag = etag.ToString();
    return Ok(user);
}

// Conditional PUT — prevent lost update problem
[HttpPut("{id}")]
public async Task<IActionResult> UpdateUser(int id, UpdateUserDto dto)
{
    var ifMatch = Request.Headers.IfMatch.FirstOrDefault();
    if (ifMatch is null) return BadRequest("If-Match header required");

    var user = await _svc.GetByIdAsync(id);
    if ($"\"{user.RowVersion}\"" != ifMatch)
        return StatusCode(412); // Precondition Failed — resource changed

    await _svc.UpdateAsync(id, dto);
    return NoContent();
}
```

---

## Q10. How do you document APIs with XML comments and Swagger?
**Answer:**
```csharp
/// <summary>Get user by ID</summary>
/// <param name="id">The user identifier</param>
/// <returns>The user with the specified ID</returns>
/// <response code="200">Returns the user</response>
/// <response code="404">User not found</response>
[HttpGet("{id:int}")]
[ProducesResponseType<UserDto>(200)]
[ProducesResponseType<ProblemDetails>(404)]
public async Task<ActionResult<UserDto>> GetById(int id) { }

/// <summary>Create a new user</summary>
/// <remarks>
/// Sample request:
///     POST /api/users
///     { "name": "Alice", "email": "alice@example.com" }
/// </remarks>
[HttpPost]
[ProducesResponseType<UserDto>(201)]
[ProducesResponseType<ValidationProblemDetails>(400)]
[ProducesResponseType<ProblemDetails>(409)]
public async Task<ActionResult<UserDto>> Create(CreateUserDto dto) { }

// Enable XML docs in .csproj
// <GenerateDocumentationFile>true</GenerateDocumentationFile>
// <NoWarn>$(NoWarn);1591</NoWarn>
```

---

## Q11. What is an API health endpoint and what should it expose?
**Answer:**
```json
// GET /health/ready — comprehensive check
{
  "status": "Healthy",
  "totalDuration": "00:00:00.0234567",
  "entries": {
    "database": { "status": "Healthy", "duration": "00:00:00.0123" },
    "redis":    { "status": "Healthy", "duration": "00:00:00.0045" },
    "external-api": { "status": "Degraded", "description": "High latency" }
  }
}

// GET /health/live — minimal: is the process alive?
{ "status": "Healthy" }
```

```csharp
builder.Services.AddHealthChecks()
    .AddSqlServer(connStr, name: "database",    tags: new[] { "ready" })
    .AddRedis(redisConnStr, name: "redis",      tags: new[] { "ready" })
    .AddUrlGroup(new Uri("https://api.stripe.com"), name: "stripe", tags: new[] { "ready" });

app.MapHealthChecks("/health/live",  new() { Predicate = _ => false }).AllowAnonymous();
app.MapHealthChecks("/health/ready", new() {
    Predicate = c => c.Tags.Contains("ready"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
}).RequireAuthorization("InternalOnly");
```

---

## Q12. What is CORS and how does it work?
**Answer:**
CORS (Cross-Origin Resource Sharing) is a browser security mechanism that restricts cross-origin HTTP requests:

```
Browser makes request: Angular app (http://localhost:4200) → API (http://localhost:5000)

1. Browser sends preflight OPTIONS request:
   OPTIONS /api/users HTTP/1.1
   Origin: http://localhost:4200
   Access-Control-Request-Method: POST
   Access-Control-Request-Headers: Authorization, Content-Type

2. Server responds (if CORS configured):
   Access-Control-Allow-Origin: http://localhost:4200
   Access-Control-Allow-Methods: GET, POST, PUT, DELETE
   Access-Control-Allow-Headers: Authorization, Content-Type
   Access-Control-Max-Age: 3600

3. Browser makes the actual request if preflight passed
```

```csharp
builder.Services.AddCors(opts => opts.AddPolicy("Angular", policy =>
    policy.WithOrigins("http://localhost:4200", "https://myapp.com")
          .AllowAnyMethod().AllowAnyHeader().AllowCredentials()));

app.UseCors("Angular"); // must be before UseAuthentication/UseAuthorization
```

---

## Q13. What is API pagination and what are the different approaches?
**Answer:**
```csharp
// Offset-based pagination (simple, but slow on large datasets)
GET /api/users?page=5&pageSize=20
// SKIP 80 TAKE 20 — gets worse as page increases

// Cursor-based pagination (fast, consistent)
GET /api/users?cursor=eyJpZCI6MTAwfQ&pageSize=20  // opaque cursor
// WHERE Id > 100 ORDER BY Id TAKE 20 — always O(log n)

// Keyset pagination (explicit key-based)
GET /api/users?afterId=100&pageSize=20
// WHERE Id > 100 ORDER BY Id TAKE 20

// Response envelope
{
  "data": [...],
  "pagination": {
    "page": 5, "pageSize": 20, "total": 1250,
    "totalPages": 63, "hasNext": true, "hasPrev": true,
    "nextCursor": "eyJpZCI6MTIwfQ"  // for cursor-based
  }
}
```

---

## Q14. What is the difference between synchronous validation and async validation?
**Answer:**
```csharp
// Synchronous validation — format, required, range (no I/O)
public class CreateUserValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserValidator()
    {
        RuleFor(x => x.Name).NotEmpty().Length(2, 50);
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).MinimumLength(8).Matches("[A-Z]");
    }
}

// Async validation — uniqueness, existence checks (requires DB query)
public class CreateUserValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserValidator(IUserRepository repo)
    {
        RuleFor(x => x.Email)
            .NotEmpty().EmailAddress()
            .MustAsync(async (email, ct) => !await repo.ExistsAsync(u => u.Email == email))
            .WithMessage("Email already registered");
    }
}

// Important: async validators only run when sync validators pass
// Use async validation sparingly — each adds a DB round-trip
```

---

## Q15. What is API testing and what tools are used?
**Answer:**
```
Tools:
- Postman / Insomnia — manual/automated API testing
- REST Client (VS Code extension) — .http files in source control
- xUnit + WebApplicationFactory — integration tests
- NBomber / k6 — load/performance testing
- Pact — consumer-driven contract testing

// .http file (checked into source control)
### Login
POST {{host}}/api/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "Admin123!"
}

### Get Users (use token from login)
GET {{host}}/api/users?page=1&pageSize=10
Authorization: Bearer {{token}}

# Integration test with WebApplicationFactory
var factory = new WebApplicationFactory<Program>()
    .WithWebHostBuilder(builder =>
        builder.ConfigureServices(svcs =>
            svcs.AddDbContext<AppDbContext>(opts => opts.UseInMemoryDatabase("Test"))));

var client = factory.CreateClient();
var response = await client.GetAsync("/api/users");
Assert.Equal(HttpStatusCode.OK, response.StatusCode);
```
