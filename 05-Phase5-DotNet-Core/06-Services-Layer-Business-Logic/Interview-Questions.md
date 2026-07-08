# Topic 06: Services Layer & Business Logic — Interview Questions

---

## Q1. What is the service layer and what is its responsibility?
**Answer:**
The service layer sits between the API (controllers) and the data layer (repositories), orchestrating business operations:

```
Controller → Service → Repository → Database
```

Responsibilities:
- **Business rules and logic** — validate, calculate, enforce invariants.
- **Transaction orchestration** — coordinate multiple repositories within one transaction.
- **Mapping** — transform domain objects to DTOs.
- **External service calls** — email, SMS, payment gateways.
- **Authorization logic** — fine-grained business-level access checks.

```csharp
public class OrderService(IOrderRepository orderRepo, IProductRepository productRepo,
    IEmailSender emailSender, IUnitOfWork uow, IMapper mapper)
{
    public async Task<OrderDto> PlaceOrderAsync(CreateOrderDto dto, int userId)
    {
        // 1. Validate business rule
        var product = await productRepo.GetByIdAsync(dto.ProductId)
            ?? throw new NotFoundException("Product not found");

        if (product.Stock < dto.Quantity)
            throw new BusinessException("Insufficient stock");

        // 2. Execute business operation
        var order = new Order { UserId = userId, ProductId = dto.ProductId, Quantity = dto.Quantity };
        product.Stock -= dto.Quantity; // domain rule: deduct stock

        // 3. Persist atomically
        await orderRepo.AddAsync(order);
        productRepo.Update(product);
        await uow.SaveChangesAsync();

        // 4. Side effects
        await emailSender.SendOrderConfirmationAsync(userId, order.Id);

        return mapper.Map<OrderDto>(order);
    }
}
```

---

## Q2. What is the Single Responsibility Principle in the context of services?
**Answer:**
A service class should have **one reason to change** — one primary responsibility:

```csharp
// ❌ Too many responsibilities
public class UserService
{
    public async Task RegisterAsync(RegisterDto dto) { /* ... */ }
    public async Task LoginAsync(LoginDto dto) { /* ... */ }
    public async Task SendPasswordResetEmailAsync(string email) { /* ... */ }
    public async Task GenerateReportAsync() { /* ... */ } // ❌ report generation here?
    public async Task ExportToCsvAsync() { /* ... */ }    // ❌ and export?
}

// ✓ Separated by responsibility
public class UserAuthService       { /* registration, login, tokens */ }
public class UserPasswordService   { /* password reset, change */ }
public class UserReportService     { /* reports, exports */ }
```

---

## Q3. What is the Result pattern and why is it better than exceptions for business errors?
**Answer:**
Exceptions are expensive (stack trace allocation) and inappropriate for expected business failures:

```csharp
// Result type
public class Result<T>
{
    public T? Value { get; private init; }
    public bool IsSuccess { get; private init; }
    public string? Error { get; private init; }
    public string? ErrorCode { get; private init; }

    public static Result<T> Ok(T value) => new() { Value = value, IsSuccess = true };
    public static Result<T> Fail(string error, string? code = null)
        => new() { IsSuccess = false, Error = error, ErrorCode = code };
}

// Service using Result
public async Task<Result<OrderDto>> PlaceOrderAsync(CreateOrderDto dto)
{
    var product = await _productRepo.GetByIdAsync(dto.ProductId);
    if (product is null) return Result<OrderDto>.Fail("Product not found", "PRODUCT_NOT_FOUND");
    if (product.Stock < dto.Quantity) return Result<OrderDto>.Fail("Insufficient stock", "OUT_OF_STOCK");

    var order = await CreateOrderAsync(dto, product);
    return Result<OrderDto>.Ok(mapper.Map<OrderDto>(order));
}

// Controller handles Result
var result = await _svc.PlaceOrderAsync(dto);
return result.IsSuccess
    ? Ok(result.Value)
    : result.ErrorCode switch {
        "PRODUCT_NOT_FOUND" => NotFound(result.Error),
        "OUT_OF_STOCK"      => Conflict(result.Error),
        _                   => BadRequest(result.Error)
    };
```

---

## Q4. What is validation in the service layer vs controller layer?
**Answer:**
- **Controller/DTO validation** — structural validity (format, required, length). Fast, cheap. Uses `[Required]`, FluentValidation.
- **Service validation** — business rule validity (uniqueness, consistency, domain constraints). May require DB queries.

```csharp
// DTO validation — happens before service is called (400 Bad Request)
public class CreateUserDto
{
    [Required, EmailAddress] public string Email { get; init; } = "";
    [Required, MinLength(8)] public string Password { get; init; } = "";
}

// Service validation — business rules
public async Task<UserDto> CreateAsync(CreateUserDto dto)
{
    // Business rule: email must be unique in our system
    if (await _repo.ExistsAsync(u => u.Email == dto.Email))
        throw new ConflictException("Email already registered");

    // Business rule: cannot register with company domain
    if (dto.Email.EndsWith("@competitor.com"))
        throw new BusinessException("Email domain not allowed");

    // ...create user
}
```

---

## Q5. What are domain exceptions and how do you structure them?
**Answer:**
Custom exceptions communicate business-level failures clearly:

```csharp
// Base business exception
public class AppException : Exception
{
    public string ErrorCode { get; }
    public int HttpStatusCode { get; }

    protected AppException(string message, string code, int status)
        : base(message) { ErrorCode = code; HttpStatusCode = status; }
}

// Specific exceptions
public class NotFoundException : AppException
{
    public NotFoundException(string entity, object key)
        : base($"{entity} with id '{key}' was not found.", "NOT_FOUND", 404) { }
}

public class ConflictException : AppException
{
    public ConflictException(string message)
        : base(message, "CONFLICT", 409) { }
}

public class BusinessException : AppException
{
    public BusinessException(string message)
        : base(message, "BUSINESS_RULE", 422) { }
}

public class ForbiddenException : AppException
{
    public ForbiddenException(string message = "Access denied")
        : base(message, "FORBIDDEN", 403) { }
}
```

---

## Q6. What is the difference between application services and domain services?
**Answer:**
| | Application Service | Domain Service |
|---|---|---|
| **Layer** | Application | Domain |
| **Concerns** | Orchestration, use cases | Domain logic that spans entities |
| **Dependencies** | Repositories, external services | Domain entities/value objects only |
| **Transaction** | Manages transactions | Unaware of persistence |

```csharp
// Domain service — pure domain logic, no infrastructure
public class PricingDomainService
{
    public decimal CalculateDiscount(Order order, Customer customer)
    {
        if (customer.Tier == CustomerTier.Premium && order.Total > 1000)
            return order.Total * 0.15m;
        return 0;
    }
}

// Application service — orchestrates use case
public class OrderApplicationService(
    IOrderRepository orderRepo,
    PricingDomainService pricingService,
    IEmailSender emailSender)
{
    public async Task<OrderDto> CheckoutAsync(CheckoutDto dto)
    {
        var customer = await _customerRepo.GetByIdAsync(dto.CustomerId);
        var order = BuildOrder(dto, customer);

        // Use domain service for business calculation
        order.Discount = pricingService.CalculateDiscount(order, customer);

        await orderRepo.AddAsync(order);
        await _uow.SaveChangesAsync();
        await emailSender.SendReceiptAsync(customer.Email, order);
        return mapper.Map<OrderDto>(order);
    }
}
```

---

## Q7. How do you handle cross-cutting concerns in services?
**Answer:**
```csharp
// Using decorators — wrap service with logging/caching/timing
public class LoggingUserService : IUserService
{
    private readonly IUserService _inner;
    private readonly ILogger<LoggingUserService> _logger;

    public LoggingUserService(IUserService inner, ILogger<LoggingUserService> logger)
        { _inner = inner; _logger = logger; }

    public async Task<UserDto> CreateAsync(CreateUserDto dto) {
        _logger.LogInformation("Creating user {Email}", dto.Email);
        var sw = Stopwatch.StartNew();
        var result = await _inner.CreateAsync(dto);
        _logger.LogInformation("User created in {ms}ms", sw.ElapsedMilliseconds);
        return result;
    }
}

// Scrutor decorator registration
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.Decorate<IUserService, LoggingUserService>();
builder.Services.Decorate<IUserService, CachingUserService>();

// Using MediatR pipeline behaviors (Clean Architecture approach)
public class LoggingBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
{
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct) {
        _logger.LogInformation("Handling {RequestType}", typeof(TRequest).Name);
        var response = await next();
        _logger.LogInformation("Handled {RequestType}", typeof(TRequest).Name);
        return response;
    }
}
```

---

## Q8. What is the difference between `AddScoped`, `AddSingleton`, and `AddTransient` for services?
**Answer:**
```csharp
// Singleton — one instance for the app lifetime
// Use for: stateless services, expensive-to-create services, caches
builder.Services.AddSingleton<ICache, DistributedCache>();
builder.Services.AddSingleton<IEmailTemplateRenderer, RazorEmailRenderer>();

// Scoped — one instance per HTTP request (shared within request)
// Use for: services that hold request state (DbContext, user context)
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<AppDbContext>();

// Transient — new instance each injection
// Use for: lightweight stateless utilities
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();
builder.Services.AddTransient<IPasswordHasher, BcryptPasswordHasher>();

// ⚠️ Captive dependency trap
// Singleton cannot depend on Scoped or Transient (DI throws at runtime)
// Solution: use IServiceScopeFactory to create a scope inside singleton
public class BackgroundWorker(IServiceScopeFactory factory)
{
    public async Task DoWork() {
        using var scope = factory.CreateScope();
        var svc = scope.ServiceProvider.GetRequiredService<IUserService>();
        await svc.ProcessAsync();
    }
}
```

---

## Q9. What is service interface segregation?
**Answer:**
Split large service interfaces into smaller, role-specific ones:

```csharp
// ❌ Fat service interface — all callers depend on all methods
public interface IUserService {
    Task<UserDto> GetByIdAsync(int id);
    Task<UserDto> CreateAsync(CreateUserDto dto);
    Task UpdateAsync(int id, UpdateUserDto dto);
    Task DeleteAsync(int id);
    Task<string> GenerateJwtAsync(int id);     // auth concern mixed in
    Task SendWelcomeEmailAsync(int id);        // email concern mixed in
    Task<byte[]> ExportToCsvAsync();           // export concern mixed in
}

// ✓ Segregated — callers depend only on what they use
public interface IUserQueryService    { Task<UserDto?> GetByIdAsync(int id); Task<PagedResult<UserDto>> GetPagedAsync(...); }
public interface IUserCommandService  { Task<UserDto> CreateAsync(CreateUserDto dto); Task UpdateAsync(...); Task DeleteAsync(int id); }
public interface IUserAuthService     { Task<string> GenerateJwtAsync(int id); Task<bool> ValidateCredentialsAsync(...); }
```

---

## Q10. What is the Mediator pattern and how does MediatR implement it?
**Answer:**
The Mediator pattern decouples senders and handlers — components communicate through a central hub:

```csharp
// Install: MediatR
// Define request + handler
public record GetUserQuery(int Id) : IRequest<UserDto?>;

public class GetUserQueryHandler : IRequestHandler<GetUserQuery, UserDto?>
{
    private readonly IUserRepository _repo;
    private readonly IMapper _mapper;

    public GetUserQueryHandler(IUserRepository repo, IMapper mapper)
        { _repo = repo; _mapper = mapper; }

    public async Task<UserDto?> Handle(GetUserQuery request, CancellationToken ct)
    {
        var user = await _repo.GetByIdAsync(request.Id);
        return user is null ? null : _mapper.Map<UserDto>(user);
    }
}

// Register
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

// Controller — sends request, doesn't know about handler
[HttpGet("{id}")]
public async Task<ActionResult<UserDto>> GetById(int id, IMediator mediator)
{
    var user = await mediator.Send(new GetUserQuery(id));
    return user is null ? NotFound() : Ok(user);
}
```
