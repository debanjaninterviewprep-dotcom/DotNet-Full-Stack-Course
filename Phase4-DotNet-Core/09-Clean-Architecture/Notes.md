# Topic 9: Clean Architecture & Project Structure

## 📘 What is Clean Architecture?

Clean Architecture (Robert C. Martin / Uncle Bob) organizes code into **concentric layers** where dependencies point **inward** — outer layers depend on inner layers, never the reverse.

### The Dependency Rule

> **Source code dependencies must point inward, toward higher-level policies.**

```
┌─────────────────────────────────────────┐
│          Presentation / API             │  ← Controllers, Middleware, DTOs
│  ┌───────────────────────────────────┐  │
│  │        Infrastructure             │  │  ← EF Core, External APIs, Email
│  │  ┌─────────────────────────────┐  │  │
│  │  │       Application           │  │  │  ← Use Cases, Services, Interfaces
│  │  │  ┌───────────────────────┐  │  │  │
│  │  │  │       Domain          │  │  │  │  ← Entities, Value Objects, Enums
│  │  │  └───────────────────────┘  │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Why Clean Architecture?

| Benefit | How |
|---------|-----|
| **Testability** | Business logic has no infrastructure dependencies |
| **Flexibility** | Swap databases, frameworks without changing core |
| **Maintainability** | Clear boundaries, single responsibility |
| **Scalability** | Teams can work on layers independently |
| **Longevity** | Core domain survives technology changes |

---

## 📘 Layer-by-Layer Breakdown

### 1. Domain Layer (Innermost — Zero Dependencies)

The **heart** of the application. Contains business entities, value objects, domain events, and domain-level interfaces.

**Has NO references to any other project.**

```
MyApp.Domain/
├── Entities/
│   ├── BaseEntity.cs
│   ├── Product.cs
│   ├── Order.cs
│   ├── OrderItem.cs
│   └── User.cs
├── ValueObjects/
│   ├── Money.cs
│   ├── Address.cs
│   └── Email.cs
├── Enums/
│   ├── OrderStatus.cs
│   └── PaymentMethod.cs
├── Events/
│   ├── IDomainEvent.cs
│   ├── OrderCreatedEvent.cs
│   └── OrderStatusChangedEvent.cs
├── Exceptions/
│   ├── DomainException.cs
│   └── InsufficientStockException.cs
└── Interfaces/
    ├── IRepository.cs
    ├── IProductRepository.cs
    └── IUnitOfWork.cs
```

```csharp
// Domain/Entities/BaseEntity.cs
public abstract class BaseEntity
{
    public Guid Id { get; protected set; } = Guid.NewGuid();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();
    
    public void AddDomainEvent(IDomainEvent domainEvent) => _domainEvents.Add(domainEvent);
    public void ClearDomainEvents() => _domainEvents.Clear();
}

// Domain/Entities/Product.cs
public class Product : BaseEntity
{
    public string Name { get; private set; }
    public string Description { get; private set; }
    public Money Price { get; private set; }
    public int StockQuantity { get; private set; }
    public bool IsActive { get; private set; } = true;

    // Factory method — encapsulates creation logic
    public static Product Create(string name, string description, decimal price, string currency)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Product name is required");
        if (price <= 0)
            throw new DomainException("Price must be positive");
        
        return new Product
        {
            Name = name,
            Description = description,
            Price = new Money(price, currency)
        };
    }

    public void UpdatePrice(decimal newPrice, string currency)
    {
        if (newPrice <= 0)
            throw new DomainException("Price must be positive");
        Price = new Money(newPrice, currency);
        UpdatedAt = DateTime.UtcNow;
    }

    public void AddStock(int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");
        StockQuantity += quantity;
    }

    public void RemoveStock(int quantity)
    {
        if (quantity > StockQuantity)
            throw new InsufficientStockException(Name, StockQuantity, quantity);
        StockQuantity -= quantity;
    }

    public void Deactivate()
    {
        IsActive = false;
        UpdatedAt = DateTime.UtcNow;
    }
}

// Domain/ValueObjects/Money.cs
public record Money(decimal Amount, string Currency)
{
    public static Money operator +(Money a, Money b)
    {
        if (a.Currency != b.Currency)
            throw new DomainException("Cannot add different currencies");
        return new Money(a.Amount + b.Amount, a.Currency);
    }

    public static Money operator *(Money m, int quantity)
        => new Money(m.Amount * quantity, m.Currency);

    public override string ToString() => $"{Amount:F2} {Currency}";
}

// Domain/ValueObjects/Email.cs
public record Email
{
    public string Value { get; }

    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || !value.Contains('@'))
            throw new DomainException($"Invalid email: {value}");
        Value = value.ToLowerInvariant();
    }

    public override string ToString() => Value;
}

// Domain/Interfaces/IRepository.cs
public interface IRepository<T> where T : BaseEntity
{
    Task<T?> GetByIdAsync(Guid id);
    Task<IReadOnlyList<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    void Update(T entity);
    void Delete(T entity);
}

// Domain/Interfaces/IProductRepository.cs
public interface IProductRepository : IRepository<Product>
{
    Task<IReadOnlyList<Product>> GetActiveProductsAsync();
    Task<Product?> GetByNameAsync(string name);
    Task<IReadOnlyList<Product>> GetByPriceRangeAsync(decimal min, decimal max);
}

// Domain/Interfaces/IUnitOfWork.cs
public interface IUnitOfWork : IDisposable
{
    IProductRepository Products { get; }
    IOrderRepository Orders { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
```

---

### 2. Application Layer (Use Cases & Orchestration)

Contains **application logic** — use cases, service interfaces, DTOs, mapping, and validation. References **only Domain**.

```
MyApp.Application/
├── Common/
│   ├── Interfaces/
│   │   ├── IApplicationDbContext.cs
│   │   ├── IEmailService.cs
│   │   ├── IDateTimeProvider.cs
│   │   └── ICacheService.cs
│   ├── Behaviors/
│   │   ├── ValidationBehavior.cs
│   │   ├── LoggingBehavior.cs
│   │   └── PerformanceBehavior.cs
│   ├── Mappings/
│   │   └── MappingProfile.cs
│   └── Models/
│       ├── Result.cs
│       └── PaginatedList.cs
├── Products/
│   ├── DTOs/
│   │   ├── ProductDto.cs
│   │   ├── CreateProductDto.cs
│   │   └── UpdateProductDto.cs
│   ├── Commands/
│   │   ├── CreateProduct/
│   │   │   ├── CreateProductCommand.cs
│   │   │   ├── CreateProductCommandHandler.cs
│   │   │   └── CreateProductCommandValidator.cs
│   │   └── UpdateProduct/
│   │       ├── UpdateProductCommand.cs
│   │       └── UpdateProductCommandHandler.cs
│   ├── Queries/
│   │   ├── GetProducts/
│   │   │   ├── GetProductsQuery.cs
│   │   │   └── GetProductsQueryHandler.cs
│   │   └── GetProductById/
│   │       ├── GetProductByIdQuery.cs
│   │       └── GetProductByIdQueryHandler.cs
│   └── Interfaces/
│       └── IProductService.cs
└── DependencyInjection.cs
```

```csharp
// Application/Common/Models/Result.cs
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }
    public int StatusCode { get; }

    private Result(bool isSuccess, T? value, string? error, int statusCode)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
        StatusCode = statusCode;
    }

    public static Result<T> Success(T value) => new(true, value, null, 200);
    public static Result<T> Created(T value) => new(true, value, null, 201);
    public static Result<T> Failure(string error, int statusCode = 400) 
        => new(false, default, error, statusCode);
    public static Result<T> NotFound(string message) => new(false, default, message, 404);
}

// Application/Products/DTOs/ProductDto.cs
public record ProductDto(
    Guid Id,
    string Name,
    string Description,
    decimal Price,
    string Currency,
    int StockQuantity,
    bool IsActive,
    DateTime CreatedAt);

public record CreateProductDto(
    string Name,
    string Description,
    decimal Price,
    string Currency);

// Application/Products/Interfaces/IProductService.cs
public interface IProductService
{
    Task<Result<IReadOnlyList<ProductDto>>> GetAllProductsAsync();
    Task<Result<ProductDto>> GetProductByIdAsync(Guid id);
    Task<Result<ProductDto>> CreateProductAsync(CreateProductDto dto);
    Task<Result<ProductDto>> UpdateProductAsync(Guid id, UpdateProductDto dto);
    Task<Result<bool>> DeleteProductAsync(Guid id);
}

// Application/Products/Services/ProductService.cs
public class ProductService : IProductService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly ILogger<ProductService> _logger;

    public ProductService(IUnitOfWork unitOfWork, IMapper mapper, ILogger<ProductService> logger)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<Result<ProductDto>> CreateProductAsync(CreateProductDto dto)
    {
        var existingProduct = await _unitOfWork.Products.GetByNameAsync(dto.Name);
        if (existingProduct != null)
            return Result<ProductDto>.Failure($"Product '{dto.Name}' already exists", 409);

        var product = Product.Create(dto.Name, dto.Description, dto.Price, dto.Currency);
        
        await _unitOfWork.Products.AddAsync(product);
        await _unitOfWork.SaveChangesAsync();
        
        _logger.LogInformation("Product created: {ProductId} — {ProductName}", product.Id, product.Name);
        
        var productDto = _mapper.Map<ProductDto>(product);
        return Result<ProductDto>.Created(productDto);
    }

    public async Task<Result<ProductDto>> GetProductByIdAsync(Guid id)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id);
        if (product == null)
            return Result<ProductDto>.NotFound($"Product with ID {id} not found");
        
        return Result<ProductDto>.Success(_mapper.Map<ProductDto>(product));
    }
}
```

---

### CQRS with MediatR

CQRS = **Command Query Responsibility Segregation**.  
- **Commands**: Change state (Create, Update, Delete)  
- **Queries**: Read state (Get, List, Search)

```csharp
// Install: dotnet add package MediatR

// Application/Products/Commands/CreateProduct/CreateProductCommand.cs
public record CreateProductCommand(
    string Name,
    string Description,
    decimal Price,
    string Currency) : IRequest<Result<ProductDto>>;

// Application/Products/Commands/CreateProduct/CreateProductCommandHandler.cs
public class CreateProductCommandHandler 
    : IRequestHandler<CreateProductCommand, Result<ProductDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public CreateProductCommandHandler(IUnitOfWork unitOfWork, IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    public async Task<Result<ProductDto>> Handle(
        CreateProductCommand request, CancellationToken cancellationToken)
    {
        var product = Product.Create(request.Name, request.Description, 
            request.Price, request.Currency);
        
        await _unitOfWork.Products.AddAsync(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        
        return Result<ProductDto>.Created(_mapper.Map<ProductDto>(product));
    }
}

// Application/Products/Commands/CreateProduct/CreateProductCommandValidator.cs
public class CreateProductCommandValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductCommandValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Product name is required")
            .MaximumLength(200).WithMessage("Name cannot exceed 200 characters");
        
        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be greater than 0");
        
        RuleFor(x => x.Currency)
            .NotEmpty()
            .Must(c => new[] { "USD", "EUR", "INR" }.Contains(c))
            .WithMessage("Invalid currency");
    }
}

// Application/Products/Queries/GetProducts/GetProductsQuery.cs
public record GetProductsQuery(
    int PageNumber = 1,
    int PageSize = 10,
    string? SearchTerm = null) : IRequest<Result<PaginatedList<ProductDto>>>;

public class GetProductsQueryHandler 
    : IRequestHandler<GetProductsQuery, Result<PaginatedList<ProductDto>>>
{
    private readonly IApplicationDbContext _context;
    private readonly IMapper _mapper;

    public GetProductsQueryHandler(IApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<Result<PaginatedList<ProductDto>>> Handle(
        GetProductsQuery request, CancellationToken cancellationToken)
    {
        var query = _context.Products.AsNoTracking();
        
        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            query = query.Where(p => p.Name.Contains(request.SearchTerm));
        
        var totalCount = await query.CountAsync(cancellationToken);
        
        var products = await query
            .OrderBy(p => p.Name)
            .Skip((request.PageNumber - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToListAsync(cancellationToken);
        
        var dtos = _mapper.Map<List<ProductDto>>(products);
        var paginatedList = new PaginatedList<ProductDto>(
            dtos, totalCount, request.PageNumber, request.PageSize);
        
        return Result<PaginatedList<ProductDto>>.Success(paginatedList);
    }
}
```

### MediatR Pipeline Behaviors

```csharp
// Validation Behavior — auto-validates commands before handler
public class ValidationBehavior<TRequest, TResponse> 
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (!_validators.Any())
            return await next();

        var context = new ValidationContext<TRequest>(request);
        var failures = _validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Count > 0)
            throw new ValidationException(failures);

        return await next();
    }
}

// Logging Behavior — logs all requests
public class LoggingBehavior<TRequest, TResponse> 
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        _logger.LogInformation("Handling {RequestName}: {@Request}", requestName, request);
        
        var response = await next();
        
        _logger.LogInformation("Handled {RequestName} → {@Response}", requestName, response);
        return response;
    }
}
```

---

### 3. Infrastructure Layer (External Concerns)

Implements interfaces defined in Domain/Application. References **Domain** and **Application**.

```
MyApp.Infrastructure/
├── Data/
│   ├── ApplicationDbContext.cs
│   ├── Configurations/
│   │   ├── ProductConfiguration.cs
│   │   └── OrderConfiguration.cs
│   ├── Repositories/
│   │   ├── GenericRepository.cs
│   │   ├── ProductRepository.cs
│   │   └── OrderRepository.cs
│   ├── UnitOfWork.cs
│   └── Migrations/
├── Services/
│   ├── EmailService.cs
│   ├── CacheService.cs
│   └── DateTimeProvider.cs
├── Identity/
│   ├── TokenService.cs
│   └── AuthService.cs
└── DependencyInjection.cs
```

```csharp
// Infrastructure/Data/ApplicationDbContext.cs
public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
        : base(options) { }

    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Auto-set timestamps
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            if (entry.State == EntityState.Modified)
                entry.Entity.UpdatedAt = DateTime.UtcNow;
        }
        return await base.SaveChangesAsync(cancellationToken);
    }
}

// Infrastructure/Data/Repositories/GenericRepository.cs
public class GenericRepository<T> : IRepository<T> where T : BaseEntity
{
    protected readonly ApplicationDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public GenericRepository(ApplicationDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T?> GetByIdAsync(Guid id) => await _dbSet.FindAsync(id);
    
    public async Task<IReadOnlyList<T>> GetAllAsync() 
        => await _dbSet.AsNoTracking().ToListAsync();
    
    public async Task<T> AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
        return entity;
    }
    
    public void Update(T entity) => _dbSet.Update(entity);
    public void Delete(T entity) => _dbSet.Remove(entity);
}

// Infrastructure/DependencyInjection.cs
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                b => b.MigrationsAssembly(typeof(ApplicationDbContext).Assembly.FullName)));

        services.AddScoped<IApplicationDbContext>(provider => 
            provider.GetRequiredService<ApplicationDbContext>());
        
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped(typeof(IRepository<>), typeof(GenericRepository<>));
        services.AddScoped<IProductRepository, ProductRepository>();
        
        services.AddTransient<IEmailService, EmailService>();
        services.AddSingleton<IDateTimeProvider, DateTimeProvider>();
        services.AddSingleton<ICacheService, CacheService>();

        return services;
    }
}
```

---

### 4. Presentation Layer (API / Web)

The **outermost** layer. Contains controllers, middleware, API configuration. References **Application** (and **Infrastructure** only for DI registration in `Program.cs`).

```
MyApp.API/
├── Controllers/
│   ├── ProductsController.cs
│   └── OrdersController.cs
├── Middleware/
│   ├── ExceptionMiddleware.cs
│   └── RequestLoggingMiddleware.cs
├── Filters/
│   └── ValidationFilter.cs
├── Program.cs
├── appsettings.json
└── appsettings.Development.json
```

```csharp
// API/Controllers/ProductsController.cs
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IMediator _mediator;

    public ProductsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null)
    {
        var query = new GetProductsQuery(pageNumber, pageSize, search);
        var result = await _mediator.Send(query);
        return result.IsSuccess 
            ? Ok(result.Value) 
            : StatusCode(result.StatusCode, result.Error);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(CreateProductCommand command)
    {
        var result = await _mediator.Send(command);
        return result.IsSuccess
            ? CreatedAtAction(nameof(GetById), new { id = result.Value!.Id }, result.Value)
            : StatusCode(result.StatusCode, result.Error);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var result = await _mediator.Send(new GetProductByIdQuery(id));
        return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
    }
}

// API/Program.cs
var builder = WebApplication.CreateBuilder(args);

// Layer-specific DI registration
builder.Services.AddApplication();      // From Application layer
builder.Services.AddInfrastructure(builder.Configuration);  // From Infrastructure layer

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

---

## 📘 Complete Solution Structure

```
MyApp/
├── src/
│   ├── MyApp.Domain/                    ← Zero dependencies
│   │   ├── MyApp.Domain.csproj
│   │   ├── Entities/
│   │   ├── ValueObjects/
│   │   ├── Enums/
│   │   ├── Events/
│   │   ├── Exceptions/
│   │   └── Interfaces/
│   │
│   ├── MyApp.Application/              ← References: Domain
│   │   ├── MyApp.Application.csproj
│   │   ├── Common/
│   │   ├── Products/
│   │   ├── Orders/
│   │   └── DependencyInjection.cs
│   │
│   ├── MyApp.Infrastructure/           ← References: Domain, Application
│   │   ├── MyApp.Infrastructure.csproj
│   │   ├── Data/
│   │   ├── Services/
│   │   ├── Identity/
│   │   └── DependencyInjection.cs
│   │
│   └── MyApp.API/                      ← References: Application, Infrastructure
│       ├── MyApp.API.csproj
│       ├── Controllers/
│       ├── Middleware/
│       ├── Filters/
│       └── Program.cs
│
├── tests/
│   ├── MyApp.Domain.Tests/
│   ├── MyApp.Application.Tests/
│   ├── MyApp.Infrastructure.Tests/
│   └── MyApp.API.IntegrationTests/
│
├── MyApp.sln
└── README.md
```

### Project References (.csproj)

```xml
<!-- Domain.csproj — No project references -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
</Project>

<!-- Application.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyApp.Domain\MyApp.Domain.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="MediatR" Version="12.*" />
    <PackageReference Include="AutoMapper.Extensions.Microsoft.DependencyInjection" Version="12.*" />
    <PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="11.*" />
  </ItemGroup>
</Project>

<!-- Infrastructure.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyApp.Domain\MyApp.Domain.csproj" />
    <ProjectReference Include="..\MyApp.Application\MyApp.Application.csproj" />
  </ItemGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="9.*" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="9.*" />
  </ItemGroup>
</Project>

<!-- API.csproj -->
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\MyApp.Application\MyApp.Application.csproj" />
    <ProjectReference Include="..\MyApp.Infrastructure\MyApp.Infrastructure.csproj" />
  </ItemGroup>
</Project>
```

---

## 📘 Scaffolding a Clean Architecture Solution

### Using dotnet CLI

```bash
# Create solution
dotnet new sln -n MyApp

# Create projects
dotnet new classlib -n MyApp.Domain -o src/MyApp.Domain
dotnet new classlib -n MyApp.Application -o src/MyApp.Application
dotnet new classlib -n MyApp.Infrastructure -o src/MyApp.Infrastructure
dotnet new webapi -n MyApp.API -o src/MyApp.API

# Create test projects
dotnet new xunit -n MyApp.Domain.Tests -o tests/MyApp.Domain.Tests
dotnet new xunit -n MyApp.Application.Tests -o tests/MyApp.Application.Tests

# Add to solution
dotnet sln add src/MyApp.Domain/MyApp.Domain.csproj
dotnet sln add src/MyApp.Application/MyApp.Application.csproj
dotnet sln add src/MyApp.Infrastructure/MyApp.Infrastructure.csproj
dotnet sln add src/MyApp.API/MyApp.API.csproj
dotnet sln add tests/MyApp.Domain.Tests/MyApp.Domain.Tests.csproj
dotnet sln add tests/MyApp.Application.Tests/MyApp.Application.Tests.csproj

# Add project references (enforce dependency rule!)
dotnet add src/MyApp.Application reference src/MyApp.Domain
dotnet add src/MyApp.Infrastructure reference src/MyApp.Domain
dotnet add src/MyApp.Infrastructure reference src/MyApp.Application
dotnet add src/MyApp.API reference src/MyApp.Application
dotnet add src/MyApp.API reference src/MyApp.Infrastructure
```

---

## 📘 Common Patterns in Clean Architecture

### Specification Pattern

```csharp
// Domain/Specifications/ISpecification.cs
public interface ISpecification<T>
{
    Expression<Func<T, bool>> Criteria { get; }
    List<Expression<Func<T, object>>> Includes { get; }
    Expression<Func<T, object>>? OrderBy { get; }
    Expression<Func<T, object>>? OrderByDescending { get; }
    int? Take { get; }
    int? Skip { get; }
}

// Domain/Specifications/ActiveProductsSpec.cs
public class ActiveProductsByPriceSpec : BaseSpecification<Product>
{
    public ActiveProductsByPriceSpec(decimal minPrice, decimal maxPrice)
        : base(p => p.IsActive && p.Price.Amount >= minPrice && p.Price.Amount <= maxPrice)
    {
        AddOrderBy(p => p.Price.Amount);
    }
}
```

### Domain Events

```csharp
// Domain/Events/OrderCreatedEvent.cs
public record OrderCreatedEvent(Guid OrderId, Guid CustomerId, decimal Total) : IDomainEvent;

// Application/Products/EventHandlers/OrderCreatedEventHandler.cs
public class OrderCreatedEventHandler : INotificationHandler<OrderCreatedEvent>
{
    private readonly IEmailService _emailService;

    public OrderCreatedEventHandler(IEmailService emailService)
    {
        _emailService = emailService;
    }

    public async Task Handle(OrderCreatedEvent notification, CancellationToken cancellationToken)
    {
        await _emailService.SendOrderConfirmationAsync(
            notification.OrderId, notification.CustomerId);
    }
}
```

---

## 📝 Summary

| Layer | Responsibility | References |
|-------|---------------|------------|
| **Domain** | Entities, value objects, domain logic, interfaces | None |
| **Application** | Use cases, DTOs, services, CQRS handlers | Domain |
| **Infrastructure** | EF Core, external APIs, email, caching | Domain, Application |
| **Presentation** | Controllers, middleware, API config | Application, Infrastructure |

| Pattern | Purpose |
|---------|---------|
| **CQRS** | Separate read and write operations |
| **MediatR** | Decouple controllers from handlers |
| **Result Pattern** | Return success/failure without exceptions |
| **Specification** | Encapsulate query criteria |
| **Domain Events** | React to domain changes loosely |
| **Pipeline Behaviors** | Cross-cutting concerns (validation, logging) |

> **Key Rule**: Dependencies always point **inward**. Domain knows nothing about databases, APIs, or frameworks.
