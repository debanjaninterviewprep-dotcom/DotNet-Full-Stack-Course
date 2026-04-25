# Practice Problems: ASP.NET Core Fundamentals & Project Setup

---

## Problem 1: Configuration Explorer Console App ⭐ Easy

**Objective**: Build a console app that simulates ASP.NET Core's layered configuration system.

### Requirements:
1. Create a `ConfigurationBuilder` class that reads settings from multiple sources:
   - A dictionary representing `appsettings.json` (base config)
   - A dictionary representing `appsettings.Development.json` (environment overrides)
   - A dictionary representing environment variables (highest priority)
2. Implement the "last wins" priority rule — later sources override earlier ones
3. Support nested keys using colon notation (e.g., `"Logging:LogLevel:Default"`)
4. Implement a `GetValue(string key)` method that returns the resolved value
5. Print the final merged configuration

### Expected Output:
```
=== Configuration Explorer ===

Base Config (appsettings.json):
  Logging:LogLevel:Default = Information
  ConnectionStrings:DefaultConnection = Server=prod-server;Database=MyDb
  AppSettings:MaxRetries = 3
  AppSettings:ApiKey = default-key

Environment Override (appsettings.Development.json):
  Logging:LogLevel:Default = Debug
  ConnectionStrings:DefaultConnection = Server=localhost;Database=MyDb_Dev

Environment Variables:
  AppSettings:ApiKey = secret-dev-key-123

=== Resolved Configuration ===
  Logging:LogLevel:Default = Debug                    ← overridden by Development
  ConnectionStrings:DefaultConnection = Server=localhost;Database=MyDb_Dev  ← overridden
  AppSettings:MaxRetries = 3                          ← from base (no override)
  AppSettings:ApiKey = secret-dev-key-123             ← overridden by env var
```

### Hints:
- Use `Dictionary<string, string>` for each config source
- Merge dictionaries in order, with later values overwriting earlier ones
- Use LINQ's `.ToDictionary()` or manual loop for merging

---

## Problem 2: Dependency Injection Simulator ⭐⭐ Easy-Medium

**Objective**: Build a console app that simulates the ASP.NET Core DI container with all three service lifetimes.

### Requirements:
1. Create a `SimpleContainer` class that supports:
   - `RegisterTransient<TInterface, TImplementation>()` — new instance every time
   - `RegisterScoped<TInterface, TImplementation>()` — same instance within a scope
   - `RegisterSingleton<TInterface, TImplementation>()` — same instance always
2. Implement `Resolve<T>()` to get an instance
3. Implement `CreateScope()` that returns a scoped container
4. Create sample services:
   - `IGuidService` → `GuidService` (generates a GUID in constructor to track instances)
   - Register it as Transient, Scoped, and Singleton (using different interface names)
5. Demonstrate that:
   - Transient: different GUID each time
   - Scoped: same GUID within a scope, different across scopes
   - Singleton: same GUID always

### Expected Output:
```
=== Dependency Injection Simulator ===

--- Transient Lifetime ---
  Resolve #1: Guid = a1b2c3d4-...
  Resolve #2: Guid = e5f6g7h8-...    ← Different! New instance each time

--- Scoped Lifetime ---
  Scope 1:
    Resolve #1: Guid = x1y2z3w4-...
    Resolve #2: Guid = x1y2z3w4-...  ← Same! Same scope
  Scope 2:
    Resolve #1: Guid = m5n6o7p8-...  ← Different! New scope
    Resolve #2: Guid = m5n6o7p8-...  ← Same within scope 2

--- Singleton Lifetime ---
  Scope 1, Resolve #1: Guid = q1r2s3t4-...
  Scope 1, Resolve #2: Guid = q1r2s3t4-...  ← Same!
  Scope 2, Resolve #1: Guid = q1r2s3t4-...  ← Same! Always same instance
```

### Hints:
- Use `Dictionary<Type, (Type implementationType, ServiceLifetime lifetime)>` for registrations
- Use `Dictionary<Type, object>` for singleton cache
- Scope class should also have its own instance cache for scoped services
- Use `Activator.CreateInstance()` to create instances

---

## Problem 3: Middleware Pipeline Simulator ⭐⭐ Medium

**Objective**: Build a console app that simulates the ASP.NET Core middleware pipeline with request/response processing.

### Requirements:
1. Create a `HttpContext` class with `Request` (Method, Path, Headers) and `Response` (StatusCode, Body) properties
2. Create a `MiddlewarePipeline` class that:
   - Allows adding middleware via `Use(Func<HttpContext, Func<Task>, Task>)`
   - Builds and executes the pipeline in order
3. Implement these middleware components:
   - **LoggingMiddleware**: Logs request method/path, then logs response status after next()
   - **AuthenticationMiddleware**: Checks for "Authorization" header; if missing, short-circuits with 401
   - **TimingMiddleware**: Measures and logs request processing time
   - **ExceptionMiddleware**: Wraps next() in try/catch, returns 500 on exception
4. Create a terminal handler that processes the request and sets a response
5. Demonstrate both successful and failed (unauthorized) requests

### Expected Output:
```
=== Middleware Pipeline Simulator ===

--- Request 1: GET /api/users (Authenticated) ---
[Timing] Started...
[Logging] → Request: GET /api/users
[Auth] Authorization header found: Bearer token123
[Handler] Processing request... Response: 200 OK
[Logging] ← Response: 200
[Timing] Completed in 5ms

--- Request 2: GET /api/admin (No Auth) ---
[Timing] Started...
[Logging] → Request: GET /api/admin
[Auth] ✗ No Authorization header! Short-circuiting with 401.
[Logging] ← Response: 401
[Timing] Completed in 1ms
  ↳ Pipeline was short-circuited! Handler never reached.

--- Request 3: POST /api/error (Throws Exception) ---
[Timing] Started...
[Logging] → Request: POST /api/error
[Auth] Authorization header found: Bearer token123
[Exception] ✗ Caught exception: Simulated server error
[Logging] ← Response: 500
[Timing] Completed in 2ms
```

### Hints:
- Each middleware is a function that takes `context` and `next` (a delegate to the next middleware)
- Calling `await next()` passes control to the next middleware
- NOT calling `next()` short-circuits the pipeline
- Build the pipeline in reverse order — last registered middleware wraps the previous

---

## Problem 4: REST API Design & HTTP Status Code Trainer ⭐⭐ Medium-Hard

**Objective**: Build a console app that simulates a full CRUD REST API with proper HTTP status codes, teaching correct API conventions.

### Requirements:
1. Create an in-memory "database" using `List<T>` for a `Product` entity:
   - Id, Name, Price, Category, CreatedDate
2. Implement a `ProductApiSimulator` class with methods matching REST endpoints:
   - `GET /api/products` → `GetAll()` → 200 with list
   - `GET /api/products/{id}` → `GetById(int id)` → 200 or 404
   - `POST /api/products` → `Create(Product)` → 201 with Location header
   - `PUT /api/products/{id}` → `Update(int id, Product)` → 200 or 404
   - `PATCH /api/products/{id}` → `PartialUpdate(int id, Dictionary)` → 200 or 404
   - `DELETE /api/products/{id}` → `Delete(int id)` → 204 or 404
3. Each method should return an `ApiResponse` with StatusCode, Body, and Headers
4. Implement input validation:
   - Name required, Price > 0 → 400 if invalid
   - Duplicate name → 409 Conflict
5. Print formatted request/response pairs showing the HTTP conversation

### Expected Output:
```
=== REST API Simulator ===

▶ POST /api/products
  Body: { "Name": "Laptop", "Price": 999.99, "Category": "Electronics" }
◀ 201 Created
  Location: /api/products/1
  Body: { "Id": 1, "Name": "Laptop", "Price": 999.99, ... }

▶ GET /api/products
◀ 200 OK
  Body: [{ "Id": 1, "Name": "Laptop", ... }]

▶ GET /api/products/99
◀ 404 Not Found
  Body: { "Error": "Product with ID 99 not found" }

▶ POST /api/products
  Body: { "Name": "", "Price": -5 }
◀ 400 Bad Request
  Body: { "Errors": ["Name is required", "Price must be greater than 0"] }

▶ PUT /api/products/1
  Body: { "Name": "Gaming Laptop", "Price": 1499.99, "Category": "Electronics" }
◀ 200 OK

▶ PATCH /api/products/1
  Body: { "Price": 1299.99 }
◀ 200 OK

▶ DELETE /api/products/1
◀ 204 No Content

▶ DELETE /api/products/1
◀ 404 Not Found
```

### Hints:
- Use an enum or int for status codes
- Create a `ValidationResult` class with a list of errors
- PATCH only updates provided fields (use reflection or dictionary)
- Track auto-increment IDs

---

## Problem 5: Full Application Bootstrap Simulator ⭐⭐⭐ Hard

**Objective**: Build a console app that simulates the complete ASP.NET Core application startup process — builder, services, middleware, and request handling.

### Requirements:
1. **AppBuilder**: Simulates `WebApplication.CreateBuilder(args)`
   - `Services` property (a `ServiceCollection` from Problem 2)
   - `Configuration` property (from Problem 1)
   - `Build()` returns an `App`
2. **App**: Simulates `WebApplication`
   - `Use(middleware)` to add middleware (from Problem 3)
   - `MapGet(path, handler)`, `MapPost(path, handler)` for routing
   - `Run()` starts "listening" and processes simulated requests
3. **Router**: Matches incoming request paths to registered handlers
   - Support route parameters: `/api/users/{id}`
   - Return 404 if no route matches
4. **Combine all pieces**: Wire up DI, configuration, middleware, and routing
5. Process at least 5 simulated requests showing the full pipeline

### Expected Output:
```
=== ASP.NET Core Application Simulator ===

[Startup] Building application...
[Services] Registered: IProductService → ProductService (Scoped)
[Services] Registered: ILogger → ConsoleLogger (Singleton)
[Config] Loaded 4 configuration values
[Startup] Application built successfully!

[Pipeline] Middleware registered:
  1. ExceptionMiddleware
  2. TimingMiddleware
  3. LoggingMiddleware
  4. AuthenticationMiddleware

[Router] Routes registered:
  GET  /api/products
  GET  /api/products/{id}
  POST /api/products

[App] Application started. Processing requests...

━━━ Request 1 ━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ GET /api/products
  Headers: { Authorization: Bearer abc123 }
[Timing] Started
[Logging] → GET /api/products
[Auth] ✓ Authenticated
[Router] Matched route: GET /api/products
[Handler] ProductService.GetAll() called (Instance: #1)
◀ 200 OK — [{ id: 1, name: "Sample Product" }]
[Timing] 3ms

━━━ Request 2 ━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ GET /api/products/1
  Headers: { Authorization: Bearer abc123 }
[Router] Matched route: GET /api/products/{id}, id=1
[Handler] ProductService.GetById(1) called (Instance: #2 — new scoped instance!)
◀ 200 OK — { id: 1, name: "Sample Product" }

━━━ Request 3 ━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ GET /api/products/999
  Headers: { Authorization: Bearer abc123 }
[Router] Matched route: GET /api/products/{id}, id=999
◀ 404 Not Found — { error: "Product 999 not found" }

━━━ Request 4 ━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ POST /api/secret
  Headers: { }
[Auth] ✗ Unauthorized — short-circuiting
◀ 401 Unauthorized

━━━ Request 5 ━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ GET /api/unknown
  Headers: { Authorization: Bearer abc123 }
[Router] No matching route found
◀ 404 Not Found — { error: "Endpoint not found" }

[App] All requests processed. Application shutting down.
```

### Hints:
- This combines Problems 1-4 into one cohesive application
- For route matching, use regex or string splitting to extract `{id}` parameters
- Each simulated request should create a new DI scope (scoped services)
- Use a `List<SimulatedRequest>` to define the test requests upfront
- The middleware pipeline should be built once and reused for all requests
