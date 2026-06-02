# Topic 8: Middleware, Filters & Error Handling — Practice Problems

---

## Problem 1: Middleware Pipeline Simulator ★★★

### Objective
Build a console app that simulates the ASP.NET Core middleware pipeline using the chain-of-responsibility pattern.

### Requirements
1. Create a `HttpContext` class with `Request` (method, path, headers) and `Response` (statusCode, body, headers)
2. Create a `RequestDelegate` delegate type: `Func<HttpContext, Task>`
3. Implement these middleware classes:
   - **LoggingMiddleware**: Logs request method/path before, status code after
   - **CorsMiddleware**: Checks "Origin" header, adds CORS response headers if origin is allowed
   - **AuthenticationMiddleware**: Checks for "Authorization" header, sets `context.Items["User"]`
   - **RateLimitMiddleware**: Tracks requests per "client" — blocks if > 5 per minute
   - **ExceptionMiddleware**: Wraps `next()` in try-catch, returns error JSON
4. Create an `ApplicationBuilder` class with `Use(middleware)` and `Build()` methods
5. Simulate various requests and show the pipeline output

### Expected Output
```
=== Request: GET /api/products ===
[Logging] → GET /api/products
[CORS] Origin 'http://localhost:4200' allowed ✓
[Auth] User authenticated: admin
[Action] Returning products list
[Logging] ← 200 (12ms)
Response: 200 — [{"id":1,"name":"Laptop"}]

=== Request: GET /api/products (No Auth) ===
[Logging] → GET /api/products
[CORS] Origin 'http://localhost:4200' allowed ✓
[Auth] ✗ Unauthorized — no token
[Logging] ← 401 (2ms)
Response: 401 — Unauthorized

=== Request: POST /api/orders (Exception) ===
[Logging] → POST /api/orders
[ExceptionHandler] Caught: OutOfStockException - Item not available
[Logging] ← 400 (5ms)
Response: 400 — {"error":"Item not available","type":"BusinessError"}
```

---

## Problem 2: Action Filter Chain ★★★

### Objective
Simulate ASP.NET Core action filters with before/after execution and short-circuiting.

### Requirements
1. Define `IActionFilter` interface with `OnActionExecuting(context)` and `OnActionExecuted(context)`
2. Define `IAsyncActionFilter` interface with `OnActionExecutionAsync(context, next)`
3. Implement filters:
   - **ValidationFilter**: Checks if model is valid, short-circuits with 400 if not
   - **AuditLogFilter**: Logs who did what and when
   - **PerformanceFilter**: Measures action execution time, warns if > 500ms
   - **CacheFilter**: Returns cached result if available, caches new results
4. Create a `FilterPipeline` that executes filters in order with proper short-circuiting
5. Demonstrate all filter scenarios including short-circuit

### Expected Output
```
=== Create Product (Valid) ===
[Validation] Model is valid ✓
[Cache] Cache miss for CreateProduct
[Audit] Before: admin creating product at 2026-04-25 10:00:00
[Performance] Starting timer...
  → Executing CreateProduct...
[Performance] Completed in 150ms ✓
[Audit] After: Product created successfully (ID: 42)
[Cache] Cached result for CreateProduct
Result: 201 Created — Product { Id=42, Name="Laptop" }

=== Create Product (Invalid) ===
[Validation] ✗ Validation failed:
  - Name: Required
  - Price: Must be > 0
Result: 400 Bad Request (short-circuited)
```

---

## Problem 3: Global Error Handler with Custom Exceptions ★★★★

### Objective
Build a comprehensive error handling system with custom exception types and RFC 7807 ProblemDetails responses.

### Requirements
1. Create exception hierarchy:
   - `AppException` (base) with `StatusCode` and `ErrorCode`
   - `NotFoundException : AppException`
   - `BusinessRuleException : AppException`
   - `ConflictException : AppException`
   - `ValidationException : AppException` with `Dictionary<string, string[]> Errors`
   - `RateLimitException : AppException` with `RetryAfter` timespan
2. Create a `ProblemDetails` class (RFC 7807):
   ```
   { type, title, status, detail, instance, traceId, errors?, retryAfter? }
   ```
3. Create `ExceptionHandler` that maps each exception type to proper ProblemDetails
4. Support "Development" vs "Production" modes (show/hide stack trace)
5. Simulate a service layer throwing various exceptions and show formatted responses

### Expected Output
```
=== NotFoundException (Production) ===
{
  "type": "https://httpstatuses.com/404",
  "title": "Not Found",
  "status": 404,
  "detail": "Product with ID 999 was not found",
  "instance": "/api/products/999",
  "traceId": "abc123"
}

=== ValidationException (Development) ===
{
  "type": "https://httpstatuses.com/400",
  "title": "Validation Error",
  "status": 400,
  "detail": "One or more validation errors occurred",
  "errors": {
    "Email": ["Invalid email format"],
    "Age": ["Must be >= 18", "Must be <= 120"]
  },
  "stackTrace": "at ProductService.Validate()..."
}
```

---

## Problem 4: Rate Limiter with Multiple Strategies ★★★★

### Objective
Implement different rate limiting strategies as middleware.

### Requirements
1. Implement rate limiting strategies:
   - **Fixed Window**: N requests per fixed time window
   - **Sliding Window**: N requests per sliding time window with segments
   - **Token Bucket**: Tokens refill at constant rate, each request takes 1 token
   - **Concurrent Limiter**: Max N simultaneous requests
2. Create a `RateLimitMiddleware` that:
   - Identifies clients by IP or API key
   - Applies configured strategy
   - Returns 429 with `Retry-After` header when limit exceeded
   - Tracks statistics per client
3. Simulate concurrent requests from multiple clients
4. Display rate limit statistics

### Expected Output
```
=== Fixed Window (5 req/min) ===
Client-A: Request 1 → 200 OK (remaining: 4)
Client-A: Request 2 → 200 OK (remaining: 3)
...
Client-A: Request 6 → 429 Too Many Requests (Retry-After: 45s)

=== Token Bucket (10 tokens, refill 2/sec) ===
Burst of 10 requests → All 200 OK (bucket empty)
Wait 3 seconds... (6 tokens refilled)
Request 11 → 200 OK (tokens: 5)
...

=== Statistics ===
Client-A: 15 total, 10 allowed, 5 rejected (33.3% rejection rate)
Client-B: 8 total, 8 allowed, 0 rejected (0% rejection rate)
```

---

## Problem 5: Enterprise Middleware Pipeline ★★★★★

### Objective
Build a complete enterprise-grade middleware pipeline with all common middleware components working together.

### Requirements
1. Implement the full middleware stack:
   - **ExceptionMiddleware**: Global exception handling with ProblemDetails
   - **CorrelationMiddleware**: Generate/forward X-Correlation-Id
   - **RequestLoggingMiddleware**: Structured logging with timings
   - **SecurityHeadersMiddleware**: Add security headers (X-Content-Type-Options, X-Frame-Options, etc.)
   - **CorsMiddleware**: Cross-origin with configurable policies
   - **RateLimitMiddleware**: Fixed window rate limiting
   - **AuthenticationMiddleware**: JWT-like token validation
   - **AuthorizationMiddleware**: Role-based access check
2. Implement `ActionFilter` support:
   - **ValidationFilter**: Model state validation
   - **AuditFilter**: Action audit logging
3. Create an `EndpointRouter` that maps paths to handler functions
4. Simulate these scenarios:
   - Happy path (authenticated, authorized, valid)
   - Unauthenticated request
   - Unauthorized (wrong role)
   - Validation failure
   - Business exception
   - Rate limit exceeded
   - CORS preflight request
5. Show complete request/response lifecycle for each

### Expected Output
```
========================================
Scenario 1: GET /api/products (admin, valid token)
========================================
→ [Exception] Wrapping pipeline
→ [Correlation] ID: abc-123
→ [Logging] → GET /api/products
→ [Security] Added 4 security headers
→ [CORS] Origin allowed ✓
→ [RateLimit] Client admin: 1/100 requests
→ [Auth] Token valid, user: admin
→ [Authz] Role 'Admin' has access to GET /api/products ✓
→ [Validation] No body to validate
→ [Audit] admin accessed GET /api/products at 2026-04-25T10:00:00
→ [Handler] Returning 3 products
← [Logging] ← 200 OK (15ms)
← [Correlation] X-Correlation-Id: abc-123

Response: 200
Headers: X-Correlation-Id: abc-123, X-Content-Type-Options: nosniff, ...
Body: [{"id":1,"name":"Laptop"},...]

========================================
Scenario 5: POST /api/orders (OutOfStockException)
========================================
→ [Exception] Wrapping pipeline
→ [Correlation] ID: ghi-789
→ [Handler] throws OutOfStockException
← [Exception] Caught: OutOfStockException
← [Logging] ← 400 (8ms)

Response: 400
Body: {"type":"business-error","title":"Out of Stock","detail":"Item X is out of stock"}
```

---

## 🎯 Difficulty Ratings

| Problem | Difficulty | Concepts |
|---------|-----------|----------|
| 1 | ★★★ | Middleware pipeline, chain of responsibility, async |
| 2 | ★★★ | Action filters, short-circuiting, before/after pattern |
| 3 | ★★★★ | Custom exceptions, ProblemDetails, environment-aware |
| 4 | ★★★★ | Rate limiting strategies, concurrent access, statistics |
| 5 | ★★★★★ | Full pipeline, filters, routing, enterprise patterns |
