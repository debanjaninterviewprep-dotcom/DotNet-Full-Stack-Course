# Phase 4 Revision Test — Practice Problems

---

## Problem 1: Mini E-Commerce API Simulator ★★★★

### Objective
Build a console app that simulates a complete ASP.NET Core Web API for an e-commerce system, covering Topics 1-4 (fundamentals, controllers, DTOs, EF Core simulation).

### Requirements
1. Simulate a **DI Container** with `AddScoped`, `AddTransient`, `AddSingleton`
2. Simulate a **Controller Pipeline**: Route matching → Model binding → Action execution → Result
3. Implement `ProductsController` with full CRUD:
   - `GET /api/products` → List with pagination  
   - `GET /api/products/{id}` → Single product  
   - `POST /api/products` → Create with validation  
   - `PUT /api/products/{id}` → Update  
   - `DELETE /api/products/{id}` → Soft delete  
4. Use **DTOs** with manual mapping (entity ↔ dto)
5. Simulate **EF Core** with in-memory List<T> and change tracking
6. Validate requests (required fields, price > 0, etc.)
7. Return proper HTTP status codes and formatted JSON responses

### Expected Output
```
=== E-Commerce API Simulator ===

[DI] Registering services...
  ProductRepository → Scoped
  ProductService → Scoped
  ProductsController → Transient

POST /api/products
  Body: { "name": "Laptop", "price": 999.99, "category": "Electronics" }
  [Pipeline] Route matched: ProductsController.Create
  [Pipeline] Model binding: CreateProductDto ✓
  [Validation] Name: ✓, Price: ✓, Category: ✓
  [Service] Creating product...
  [Repository] Added to DbSet (State: Added)
  [SaveChanges] 1 entity persisted
  Response: 201 Created
  { "id": "abc-123", "name": "Laptop", "price": 999.99 }

GET /api/products?page=1&size=10
  [Pipeline] Route matched: ProductsController.GetAll
  [Service] Querying products...
  Response: 200 OK
  { "data": [...], "page": 1, "totalPages": 1, "totalCount": 1 }
```

---

## Problem 2: Repository + Unit of Work + Service Layer ★★★★

### Objective
Build a complete 3-layer system (Repository → Unit of Work → Service) covering Topics 5-6.

### Requirements
1. **Domain**: `Product`, `Order`, `OrderItem` entities
2. **Repositories**: 
   - `IRepository<T>` generic interface
   - `IProductRepository` with `GetByCategory`, `SearchByName`
   - `IOrderRepository` with `GetByCustomer`, `GetWithItems`
   - In-memory implementations
3. **Unit of Work**: 
   - `IUnitOfWork` with `Products`, `Orders`, `SaveChangesAsync()`
   - Transaction simulation (all-or-nothing on save)
4. **Service Layer**:
   - `ProductService`: CRUD + business rules
   - `OrderService`: Create order → validate stock → reduce stock → save (atomic)
   - Both return `Result<T>`
5. Test scenarios:
   - Successful order (2 products, stock is reduced)
   - Failed order (insufficient stock — nothing is persisted, rollback)
   - Concurrent modification detection

### Expected Output
```
=== Repository + UoW + Service Layer ===

--- Setup: Adding Products ---
Added: Laptop (Stock: 10) — ID: p1
Added: Mouse (Stock: 50) — ID: p2

--- Order: 2x Laptop + 5x Mouse ---
[OrderService] Validating stock...
  Laptop: Need 2, Have 10 ✓
  Mouse: Need 5, Have 50 ✓
[OrderService] Reducing stock...
  Laptop: 10 → 8
  Mouse: 50 → 45
[UnitOfWork] SaveChanges — 3 entities (1 order + 2 stock updates)
Result: Created — Order total: 2149.93

--- Order: 20x Laptop (Insufficient Stock) ---
[OrderService] Validating stock...
  Laptop: Need 20, Have 8 ✗
[UnitOfWork] Rollback — no changes persisted
Result: Failure (400) — Insufficient stock for Laptop (need 20, have 8)

--- Verify Rollback ---
Laptop stock: 8 (unchanged after failed order ✓)
```

---

## Problem 3: Authentication & Authorization System ★★★★

### Objective
Build a complete auth system covering Topic 7 — registration, login, JWT, roles, and protected endpoints.

### Requirements
1. **User system**: Register, Login, Role assignment
2. **Password**: Hash using simulated BCrypt (base64 + salt for demo)
3. **JWT Token**: Generate with claims (UserId, Email, Roles, Expiry)
4. **Token validation**: Verify signature, check expiry, extract claims
5. **Protected endpoints simulation**:
   - `GET /api/products` → Public (no auth needed)
   - `POST /api/products` → Requires `[Authorize]`
   - `DELETE /api/products/{id}` → Requires `[Authorize(Roles = "Admin")]`
   - `GET /api/admin/dashboard` → Requires `[Authorize(Policy = "AdminOnly")]`
6. **Refresh tokens**: Issue alongside access token, use to get new access token
7. Test all scenarios: valid token, expired token, wrong role, refresh flow

### Expected Output
```
=== Authentication & Authorization System ===

--- Register ---
POST /api/auth/register { email: "john@example.com", password: "Pass@123" }
  Password hashed: $2a$12$xyz...
  User created with role: User
  Response: 201 — User registered

--- Login ---
POST /api/auth/login { email: "john@example.com", password: "Pass@123" }
  Password verified ✓
  Access Token: eyJhbG... (expires: 30 min)
  Refresh Token: rt_abc123 (expires: 7 days)
  Response: 200 — Login successful

--- Access Protected Endpoint ---
GET /api/products → 200 OK (public)
POST /api/products [Token: valid, Role: User] → 200 OK (authenticated ✓)
DELETE /api/products/1 [Token: valid, Role: User] → 403 Forbidden (need Admin)
DELETE /api/products/1 [Token: valid, Role: Admin] → 200 OK ✓
GET /api/admin/dashboard [No Token] → 401 Unauthorized
POST /api/products [Token: expired] → 401 Token expired

--- Refresh Token Flow ---
POST /api/auth/refresh { refreshToken: "rt_abc123" }
  Refresh token valid ✓
  New Access Token: eyJhbG... (new 30 min)
  New Refresh Token: rt_def456
  Old refresh token revoked
```

---

## Problem 4: Middleware Pipeline + Error Handling ★★★★

### Objective
Build a complete middleware pipeline with filters and comprehensive error handling — Topics 8.

### Requirements
1. Build the middleware pipeline:
   - `ExceptionMiddleware` → `CorrelationMiddleware` → `LoggingMiddleware` → 
   - `SecurityHeadersMiddleware` → `RateLimitMiddleware` → `AuthMiddleware` →
   - `Controller`
2. Action filters: `ValidationFilter`, `AuditFilter`
3. Error handling with `ProblemDetails` (RFC 7807)
4. Support Development/Production error detail levels
5. Simulate all scenarios:
   - Normal request (full pipeline)
   - Validation failure (filter short-circuit)
   - Business exception (mapped to 400)
   - Not found (mapped to 404)
   - Unhandled exception (mapped to 500 with/without stack trace)
   - Rate limit exceeded (mapped to 429)

### Expected Output
```
=== Middleware Pipeline Simulator ===
Environment: Development

--- Scenario 1: Happy Path ---
→ [Exception] Pipeline wrapped
→ [Correlation] X-Correlation-Id: 7f3a9b2c
→ [Logging] → GET /api/products at 2026-04-25T10:00:00
→ [Security] Added: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
→ [RateLimit] Client-A: 1/100 (remaining: 99)
→ [Auth] Bearer token valid (user: admin)
→ [ValidationFilter] No body to validate
→ [AuditFilter] Before: admin → GET /api/products
→ [Handler] Returning 3 products
← [AuditFilter] After: 200 OK (12ms)
← [Logging] ← 200 OK (15ms)
Response: 200 | Headers: 5 | Body: [{...}]

--- Scenario 5: Unhandled Exception (Development) ---
→ [Handler] throws NullReferenceException
← [Exception] Caught NullReferenceException
Response: 500
{
  "type": "https://httpstatuses.com/500",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "Object reference not set to an instance of an object",
  "traceId": "7f3a9b2c",
  "stackTrace": "at ProductHandler.Handle()..."
}
```

---

## Problem 5: Full Clean Architecture E-Commerce System ★★★★★

### Objective
Build a complete Clean Architecture system covering ALL Phase 4 topics in one integrated application.

### Requirements
1. **Domain Layer**: Entities (Product, Category, Order, OrderItem, User), value objects (Money, Email), domain events, enums, exception hierarchy, repository interfaces
2. **Application Layer**: DTOs, mapping, validation, services with Result<T>, CQRS (commands/queries with mediator)
3. **Infrastructure Layer**: In-memory repositories, unit of work, console email service, cache service
4. **Presentation Layer**: Console-based controller with routing, middleware pipeline
5. **Cross-cutting**: 
   - JWT auth (simulated)
   - Middleware pipeline (exception, logging, auth, CORS)
   - Action filters (validation, audit)
   - Rate limiting
6. Full workflow:
   - Configure DI container
   - Register middleware pipeline
   - Process these commands:
     ```
     POST /api/auth/register
     POST /api/auth/login
     POST /api/categories (Admin only)
     POST /api/products (Admin only)
     GET /api/products (Public)
     POST /api/orders (Authenticated)
     GET /api/orders/me (Authenticated — own orders)
     PATCH /api/orders/{id}/status (Admin only)
     ```

### Expected Output
```
╔══════════════════════════════════════════════╗
║  E-Commerce API — Clean Architecture Demo   ║
╚══════════════════════════════════════════════╝

=== Application Bootstrap ===
[DI Container]
  Domain: 0 registrations (no dependencies!)
  Application: ProductService, OrderService, AuthService, Mediator
  Infrastructure: DbContext, ProductRepo, OrderRepo, UoW, EmailService
  Presentation: Middleware pipeline (6 components), Filters (2)

=== Middleware Pipeline Order ===
  1. ExceptionMiddleware
  2. CorrelationMiddleware
  3. RequestLoggingMiddleware
  4. RateLimitMiddleware (100 req/min)
  5. AuthenticationMiddleware (JWT)
  6. AuthorizationMiddleware (Roles + Policies)

=== Processing Requests ===

[1] POST /api/auth/register {"email":"admin@shop.com","password":"Admin@123","role":"Admin"}
    → Pipeline: Exception → Correlation(abc) → Logging → RateLimit(1/100) → [No Auth Required]
    → Handler: Register user, hash password, assign Admin role
    ← Response: 201 Created — User registered

[2] POST /api/auth/login {"email":"admin@shop.com","password":"Admin@123"}
    → Handler: Verify password, generate JWT + refresh token
    ← Response: 200 OK — { accessToken: "eyJ...", refreshToken: "rt_..." }

[3] POST /api/products {"name":"Laptop","price":999.99,"stock":10} [Token: admin]
    → Pipeline: ... → Auth(admin ✓) → Authz(Admin ✓)
    → Mediator: CreateProductCommand → ValidationBehavior(✓) → Handler
    → Domain: Product.Create("Laptop", 999.99) — validates price > 0
    → Infrastructure: Repository.Add → UoW.SaveChanges
    ← Response: 201 Created — { id: "p1", name: "Laptop" }

[4] POST /api/orders {"items":[{"productId":"p1","qty":2}]} [Token: admin]
    → Pipeline: ... → Auth(admin ✓)
    → Mediator: CreateOrderCommand → Handler
    → Domain: Order.Create → AddItem(2x Laptop = 1999.98) → CalcTotal
    → Domain Event: OrderCreatedEvent
      → EventHandler: SendConfirmation email
      → EventHandler: ReduceStock (Laptop: 10→8)
    → Infrastructure: UoW.SaveChanges (2 entities)
    ← Response: 201 Created — { orderId: "o1", total: "1999.98 USD" }

[5] GET /api/products [No Token — Public]
    → Pipeline: ... → Auth(anonymous, skip) → [Public endpoint]
    → Mediator: GetProductsQuery → Handler
    ← Response: 200 OK — [{ name: "Laptop", price: 999.99, stock: 8 }]

=== Final Statistics ===
Requests processed: 8
  Success: 7 (200/201)
  Auth failures: 1 (403)
Entities in DB: 3 (1 user, 1 product, 1 order)
Domain events fired: 2
Emails sent: 1
Pipeline execution time (avg): 18ms
```

---

## 🎯 Scoring Guide

| Section | Marks | Topics Covered |
|---------|-------|---------------|
| Problem 1 | 20 | Topics 1-4: Fundamentals, Controllers, DTOs, EF Core |
| Problem 2 | 20 | Topics 5-6: Repository, UoW, Service Layer |
| Problem 3 | 20 | Topic 7: Authentication, Authorization, JWT |
| Problem 4 | 20 | Topic 8: Middleware, Filters, Error Handling |
| Problem 5 | 20 | All Topics: Clean Architecture Integration |
| **Total** | **100** | |

### Grading
- **90-100**: Excellent — Ready for real-world .NET projects
- **70-89**: Good — Review weak areas and retry
- **50-69**: Fair — Re-study Notes for failed topics
- **Below 50**: Needs Work — Go through each topic again with practice problems
