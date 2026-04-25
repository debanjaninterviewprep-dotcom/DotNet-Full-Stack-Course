# Topic 10: Phase 4 — Revision Test

## 📘 Revision Summary: .NET Core Web API & Architecture

This revision test covers **all 9 topics** from Phase 4. Use this to consolidate your understanding before moving on.

---

### Topic 1: ASP.NET Core Fundamentals
- **Program.cs**: Minimal hosting model, `WebApplication.CreateBuilder(args)`
- **Dependency Injection**: AddTransient, AddScoped, AddSingleton — lifetime matters
- **Configuration**: `appsettings.json`, environment-specific, `IOptions<T>`, secrets
- **Environments**: Development, Staging, Production — `ASPNETCORE_ENVIRONMENT`
- **Kestrel**: Default cross-platform web server, configurable endpoints
- **Middleware pipeline**: Request → Middleware chain → Controller → Middleware chain → Response

### Topic 2: Controllers & Routing
- **[ApiController]**: Enables automatic model validation, binding source inference
- **Attribute routing**: `[Route("api/[controller]")]`, `[HttpGet("{id:int}")]`
- **Route constraints**: `{id:int}`, `{name:alpha}`, `{slug:regex(...)}`
- **Parameter binding**: `[FromBody]`, `[FromQuery]`, `[FromRoute]`, `[FromHeader]`
- **Return types**: `IActionResult`, `ActionResult<T>`, `Ok()`, `NotFound()`, `CreatedAtAction()`
- **Async actions**: Always use `async Task<IActionResult>`

### Topic 3: Models, DTOs & AutoMapper
- **Entity vs DTO**: Entities = database shape, DTOs = API shape
- **AutoMapper**: `CreateMap<Source, Dest>()`, `Profile`, `ProjectTo<T>()`
- **FluentValidation**: `RuleFor(x => x.Name).NotEmpty().MaximumLength(200)`
- **Response wrapper**: `ApiResponse<T>` with `Success`, `Error`, `Pagination`

### Topic 4: Entity Framework Core & SQL Server
- **DbContext**: Database session, `DbSet<T>` properties, connection string
- **Fluent API**: `OnModelCreating`, `HasOne/HasMany`, `Property().IsRequired()`
- **Relationships**: 1-to-many, many-to-many, 1-to-1 with navigation properties
- **Migrations**: `Add-Migration`, `Update-Database`, `Script-Migration`
- **LINQ queries**: `Where`, `Include`, `ThenInclude`, `Select`, `GroupBy`
- **Loading**: Eager (`Include`), Explicit (`Load`), Lazy (proxies)
- **Change tracking**: `EntityState.Added/Modified/Deleted`, `AsNoTracking()`

### Topic 5: Repository Pattern & Unit of Work
- **Generic Repository**: `IRepository<T>` with CRUD, `GenericRepository<T>`
- **Specific Repositories**: Extend generic with domain-specific queries
- **Unit of Work**: Coordinates multiple repositories in one transaction
- **Specification Pattern**: Encapsulate query logic in reusable specs

### Topic 6: Services Layer & Business Logic
- **Service layer**: Orchestrates domain logic between controllers and repositories
- **Thin controllers**: Controllers only delegate to services
- **Business validation** vs **Input validation**: Different layers, different concerns
- **Custom exceptions**: `NotFoundException`, `BusinessException` hierarchy
- **Result pattern**: `Result<T>.Success(value)`, `Result<T>.Failure(error)`

### Topic 7: Authentication & Authorization (JWT)
- **JWT structure**: Header.Payload.Signature (Base64URL encoded)
- **Token generation**: `JwtSecurityTokenHandler`, claims, signing credentials
- **[Authorize]**: Requires authentication on controller/action
- **Roles**: `[Authorize(Roles = "Admin")]`, claim-based
- **Policies**: `[Authorize(Policy = "CanEditProducts")]`, requirement handlers
- **Refresh tokens**: Stored securely, used to get new access tokens
- **Password hashing**: `BCrypt.HashPassword()`, never store plaintext

### Topic 8: Middleware, Filters & Error Handling
- **Middleware**: Pipeline components with `InvokeAsync(HttpContext, next)`
- **Global exception middleware**: First in pipeline, catches all exceptions
- **Action filters**: `IAsyncActionFilter`, before/after controller actions
- **Exception filters**: `IExceptionFilter`, handle action-level exceptions
- **Validation filter**: Auto-reject invalid model state
- **Rate limiting**: Fixed window, sliding window, token bucket
- **CORS**: `AddCors()`, `UseCors("PolicyName")`
- **Pipeline order**: Exception → Logging → CORS → Auth → Authz → Controllers

### Topic 9: Clean Architecture
- **Layers**: Domain → Application → Infrastructure → Presentation
- **Dependency rule**: Dependencies point inward only
- **Domain**: Entities, value objects, domain events, repository interfaces
- **Application**: Use cases, DTOs, services, CQRS commands/queries
- **Infrastructure**: EF Core, external APIs, repository implementations
- **Presentation**: Controllers, middleware, Program.cs
- **CQRS**: Separate commands (write) and queries (read)
- **MediatR**: Decouples handlers, pipeline behaviors for cross-cutting concerns

---

## 📝 Key Concepts Quick Reference

### Startup / Configuration
```
WebApplication.CreateBuilder(args)
  → builder.Services (DI container)
  → builder.Configuration (settings)
  → builder.Build() → app
  → app.Use*() (middleware pipeline)
  → app.Map*() (endpoints)
  → app.Run()
```

### Request Lifecycle
```
HTTP Request → Kestrel → Middleware Pipeline →
  Routing → Auth → Action Filters → Model Binding →
  Controller Action → Service → Repository → DB
  → Response travels back through pipeline
```

### DI Lifetimes
| Lifetime | Created | Disposed | Use For |
|----------|---------|----------|---------|
| Transient | Every request for service | End of scope | Lightweight, stateless |
| Scoped | Once per HTTP request | End of request | DbContext, services |
| Singleton | Once for app lifetime | App shutdown | Cache, configuration |

### HTTP Status Codes
| Code | Meaning | When |
|------|---------|------|
| 200 | OK | Successful GET/PUT |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation failure |
| 401 | Unauthorized | No/invalid token |
| 403 | Forbidden | Valid token, no permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource |
| 500 | Internal Server Error | Unhandled exception |

---

## 🎯 Revision Test Format

The test below has **5 sections** covering all Phase 4 topics. Answer in code + explanation.

### Section A: Conceptual (Write short answers)

1. What is the difference between `AddScoped` and `AddTransient` for a `DbContext`? Why should `DbContext` be Scoped?
2. Explain the difference between **attribute routing** and **conventional routing**. Which is preferred for APIs?
3. Why should you never expose Entity Framework entities directly in API responses?
4. What is the **N+1 query problem** and how does `Include()` solve it?
5. Explain the **Dependency Rule** in Clean Architecture. Give an example of a violation.
6. What is the difference between **Authentication** and **Authorization**?
7. Why should global exception middleware be the **first** middleware registered?
8. What are MediatR **Pipeline Behaviors** and why are they useful?
9. Compare the **Repository Pattern** with using `DbContext` directly in services.
10. What is a **Value Object** and how does it differ from an **Entity**?

### Section B: Code Analysis (Find bugs/improvements)

```csharp
// Bug 1: What's wrong with this controller?
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public ProductsController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    [HttpGet]
    public IActionResult GetAll()
    {
        var products = _context.Products.ToList();
        return Ok(products);
    }
    
    [HttpPost]
    public IActionResult Create(Product product)
    {
        _context.Products.Add(product);
        _context.SaveChanges();
        return Ok(product);
    }
}
```

```csharp
// Bug 2: What's the security issue?
[HttpPost("login")]
public IActionResult Login(LoginDto dto)
{
    var user = _context.Users.FirstOrDefault(u => 
        u.Email == dto.Email && u.Password == dto.Password);
    
    if (user == null)
        return Unauthorized("Invalid email or password");
    
    var token = GenerateJwt(user);
    return Ok(new { token, user.Password });
}
```

```csharp
// Bug 3: What Clean Architecture violation exists?
// In Application/Services/OrderService.cs
public class OrderService
{
    private readonly ApplicationDbContext _context;  // EF Core DbContext
    private readonly SmtpClient _smtpClient;        // Direct SMTP
    
    public async Task CreateOrder(Order order)
    {
        _context.Orders.Add(order);
        await _context.SaveChangesAsync();
        
        await _smtpClient.SendMailAsync(new MailMessage(...));
    }
}
```

### Section C: Implementation (Write code)

1. **Write a custom middleware** that adds a response time header (`X-Response-Time`) to every response.

2. **Write a service method** that creates an order with proper validation:
   - Validate customer exists
   - Validate all products exist and have sufficient stock
   - Calculate total
   - Reduce stock
   - Return `Result<OrderDto>`

3. **Write a JWT token generation method** that creates a token with: UserId, Email, Roles, 30-minute expiry.

4. **Write a generic repository** method `GetPagedAsync` that returns paginated results with total count.

5. **Write a validation filter** that returns a structured error response for invalid model state.

### Section D: Architecture Design

Design a **Library Management System** using Clean Architecture:

1. Draw the project structure (folders and files)
2. Define the domain entities: `Book`, `Member`, `Loan`
3. Define the repository interfaces
4. Write the `BorrowBookCommand` and its handler
5. List all the services needed and their lifetimes

### Section E: Debugging Scenarios

1. Your API returns 500 for all requests. The error log shows: `"Unable to resolve service for type 'IProductService' while attempting to activate 'ProductsController'"`. What's wrong and how do you fix it?

2. Your JWT authentication works in Postman but Angular gets 401 on every request. The token is in `localStorage`. What could be wrong? (List 3 possible causes)

3. Your EF Core query `_context.Orders.Include(o => o.Items).ToListAsync()` returns orders but `Items` is always empty even though data exists in DB. What could be wrong?

4. You added `[Authorize]` to a controller but ALL requests (even unauthenticated) go through. What did you forget in `Program.cs`?

5. After adding a new migration, `Update-Database` fails with: `"The entity type 'OrderItem' requires a primary key to be defined"`. How do you fix this?
