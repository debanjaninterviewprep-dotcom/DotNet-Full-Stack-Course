# Topic 6: Services Layer & Business Logic

## 📘 What is the Services Layer?

The Services Layer (also called the Business Logic Layer) sits **between controllers and repositories**. It contains the application's business rules, validation, and orchestration logic.

### Layered Architecture

```
Controller Layer    →  Handles HTTP, routing, response formatting
    ↓
Service Layer       →  Business logic, validation, orchestration
    ↓
Repository Layer    →  Data access, queries, persistence
    ↓
Database            →  SQL Server, PostgreSQL, etc.
```

### Why a Separate Services Layer?

| Benefit | Description |
|---------|------------|
| **Separation of Concerns** | Controllers don't contain business logic |
| **Reusability** | Same service used by controllers, background jobs, etc. |
| **Testability** | Business logic can be unit tested without HTTP |
| **Single Responsibility** | Each service handles one domain area |
| **Thin Controllers** | Controllers only handle HTTP concerns |

---

## 📘 Service Interface Pattern

### Interface

```csharp
public interface IProductService
{
    Task<IEnumerable<ProductDto>> GetAllAsync();
    Task<ProductDto?> GetByIdAsync(int id);
    Task<PagedResult<ProductDto>> GetPagedAsync(ProductQueryParams queryParams);
    Task<ProductDto> CreateAsync(CreateProductDto dto);
    Task<ProductDto?> UpdateAsync(int id, UpdateProductDto dto);
    Task<bool> DeleteAsync(int id);
    Task<IEnumerable<ProductDto>> SearchAsync(string searchTerm);
}
```

### Implementation

```csharp
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

    public async Task<ProductDto?> GetByIdAsync(int id)
    {
        var product = await _unitOfWork.Products.GetWithCategoryAsync(id);
        
        if (product == null)
        {
            _logger.LogWarning("Product {Id} not found", id);
            return null;
        }
        
        return _mapper.Map<ProductDto>(product);
    }

    public async Task<ProductDto> CreateAsync(CreateProductDto dto)
    {
        // Business validation
        var existingProduct = await _unitOfWork.Products
            .FindAsync(p => p.Name == dto.Name);
        
        if (existingProduct.Any())
            throw new BusinessException($"Product '{dto.Name}' already exists");
        
        var category = await _unitOfWork.Categories.GetByIdAsync(dto.CategoryId);
        if (category == null)
            throw new NotFoundException($"Category {dto.CategoryId} not found");
        
        // Map and save
        var product = _mapper.Map<Product>(dto);
        product.CreatedDate = DateTime.UtcNow;
        
        await _unitOfWork.Products.AddAsync(product);
        await _unitOfWork.SaveChangesAsync();
        
        _logger.LogInformation("Product {Id} created: {Name}", product.Id, product.Name);
        
        return _mapper.Map<ProductDto>(product);
    }

    public async Task<ProductDto?> UpdateAsync(int id, UpdateProductDto dto)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id);
        if (product == null) return null;
        
        // Check for duplicate name (excluding current product)
        var duplicate = await _unitOfWork.Products
            .FindAsync(p => p.Name == dto.Name && p.Id != id);
        if (duplicate.Any())
            throw new BusinessException($"Another product named '{dto.Name}' already exists");
        
        _mapper.Map(dto, product);
        product.UpdatedDate = DateTime.UtcNow;
        
        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync();
        
        return _mapper.Map<ProductDto>(product);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id);
        if (product == null) return false;
        
        // Soft delete
        product.IsActive = false;
        product.UpdatedDate = DateTime.UtcNow;
        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync();
        
        return true;
    }
}
```

---

## 📘 Business Validation vs Input Validation

| Type | Where | What | Example |
|------|-------|------|---------|
| **Input Validation** | DTO / Controller | Format, required, range | "Name is required", "Price > 0" |
| **Business Validation** | Service Layer | Business rules, uniqueness | "Product name already exists" |

```csharp
// Input validation (DTO level — handled by [ApiController])
public class CreateProductDto
{
    [Required] public string Name { get; set; }     // Format check
    [Range(0.01, 99999)] public decimal Price { get; set; }  // Range check
}

// Business validation (Service level)
public async Task<ProductDto> CreateAsync(CreateProductDto dto)
{
    // Business rules that require database access
    if (await _unitOfWork.Products.FindAsync(p => p.Name == dto.Name).Any())
        throw new BusinessException("Duplicate product name");
    
    if (dto.CategoryId > 0 && !await _unitOfWork.Categories.ExistsAsync(dto.CategoryId))
        throw new NotFoundException("Category not found");
}
```

---

## 📘 Custom Exception Classes

```csharp
public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message) { }
    public NotFoundException(string entityName, object key)
        : base($"{entityName} with ID '{key}' was not found.") { }
}

public class BusinessException : Exception
{
    public BusinessException(string message) : base(message) { }
}

public class ConflictException : Exception
{
    public ConflictException(string message) : base(message) { }
}

public class ForbiddenException : Exception
{
    public ForbiddenException(string message) : base(message) { }
}
```

---

## 📘 Complex Business Logic: Order Processing

```csharp
public class OrderService : IOrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly IEmailService _emailService;

    public async Task<OrderDto> CreateOrderAsync(CreateOrderDto dto)
    {
        // 1. Validate customer
        var customer = await _unitOfWork.Customers.GetByIdAsync(dto.CustomerId)
            ?? throw new NotFoundException("Customer", dto.CustomerId);
        
        // 2. Validate and gather products
        var orderItems = new List<OrderItem>();
        decimal totalAmount = 0;
        
        foreach (var itemDto in dto.Items)
        {
            var product = await _unitOfWork.Products.GetByIdAsync(itemDto.ProductId)
                ?? throw new NotFoundException("Product", itemDto.ProductId);
            
            // 3. Business rule: Check stock
            if (product.StockQuantity < itemDto.Quantity)
                throw new BusinessException(
                    $"Insufficient stock for '{product.Name}'. " +
                    $"Available: {product.StockQuantity}, Requested: {itemDto.Quantity}");
            
            // 4. Business rule: Minimum order amount per item
            if (itemDto.Quantity * product.Price < 1.00m)
                throw new BusinessException("Minimum order amount per item is $1.00");
            
            // 5. Deduct stock
            product.StockQuantity -= itemDto.Quantity;
            _unitOfWork.Products.Update(product);
            
            var orderItem = new OrderItem
            {
                ProductId = product.Id,
                Quantity = itemDto.Quantity,
                UnitPrice = product.Price,
                LineTotal = itemDto.Quantity * product.Price
            };
            orderItems.Add(orderItem);
            totalAmount += orderItem.LineTotal;
        }
        
        // 6. Business rule: Apply discount
        decimal discount = 0;
        if (totalAmount > 1000)
            discount = totalAmount * 0.1m;  // 10% discount over $1000
        else if (totalAmount > 500)
            discount = totalAmount * 0.05m; // 5% discount over $500
        
        // 7. Calculate tax
        decimal tax = (totalAmount - discount) * 0.08m;  // 8% tax
        
        // 8. Create order
        var order = new Order
        {
            CustomerId = customer.Id,
            Items = orderItems,
            SubTotal = totalAmount,
            Discount = discount,
            Tax = tax,
            TotalAmount = totalAmount - discount + tax,
            Status = "Pending",
            OrderDate = DateTime.UtcNow
        };
        
        await _unitOfWork.Orders.AddAsync(order);
        await _unitOfWork.SaveChangesAsync();
        
        // 9. Send confirmation email (fire-and-forget)
        _ = _emailService.SendOrderConfirmationAsync(customer.Email, order.Id);
        
        return _mapper.Map<OrderDto>(order);
    }
}
```

---

## 📘 Result Pattern (Alternative to Exceptions)

Instead of throwing exceptions for expected failures, return a `Result` object:

```csharp
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }
    public int StatusCode { get; }

    private Result(T value) { IsSuccess = true; Value = value; StatusCode = 200; }
    private Result(string error, int statusCode) { IsSuccess = false; Error = error; StatusCode = statusCode; }

    public static Result<T> Success(T value) => new(value);
    public static Result<T> NotFound(string error) => new(error, 404);
    public static Result<T> BadRequest(string error) => new(error, 400);
    public static Result<T> Conflict(string error) => new(error, 409);
}

// Service using Result pattern
public async Task<Result<ProductDto>> GetByIdAsync(int id)
{
    var product = await _unitOfWork.Products.GetByIdAsync(id);
    if (product == null)
        return Result<ProductDto>.NotFound($"Product {id} not found");
    
    return Result<ProductDto>.Success(_mapper.Map<ProductDto>(product));
}

// Controller using Result
[HttpGet("{id}")]
public async Task<IActionResult> GetById(int id)
{
    var result = await _productService.GetByIdAsync(id);
    
    if (!result.IsSuccess)
        return StatusCode(result.StatusCode, new { error = result.Error });
    
    return Ok(result.Value);
}
```

---

## 📘 Thin Controllers

Controllers should only handle HTTP concerns:

```csharp
// ✅ GOOD: Thin controller — delegates everything to service
[HttpPost]
public async Task<ActionResult<ProductDto>> Create(CreateProductDto dto)
{
    var product = await _productService.CreateAsync(dto);
    return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
}

// ❌ BAD: Fat controller — business logic in controller
[HttpPost]
public async Task<IActionResult> Create(CreateProductDto dto)
{
    // Don't do this in a controller!
    var existing = await _context.Products.FirstOrDefaultAsync(p => p.Name == dto.Name);
    if (existing != null) return Conflict("Already exists");
    
    var product = new Product { Name = dto.Name, Price = dto.Price };
    product.CreatedDate = DateTime.UtcNow;
    
    if (dto.Price > 1000) product.Category = "Premium";
    
    _context.Products.Add(product);
    await _context.SaveChangesAsync();
    
    return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
}
```

---

## 📘 Service Registration

```csharp
// Program.cs
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<IEmailService, SmtpEmailService>();

// Or use extension methods for clean registration
public static class ServiceRegistration
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<ICustomerService, CustomerService>();
        return services;
    }
}

// In Program.cs
builder.Services.AddApplicationServices();
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| Service Layer | Contains business logic between controllers and repositories |
| Thin Controllers | Controllers handle HTTP only, delegate to services |
| Input vs Business Validation | Input: format/required; Business: rules needing DB access |
| Custom Exceptions | NotFoundException, BusinessException, ConflictException |
| Result Pattern | Alternative to exceptions for expected failures |
| Order of Operations | Validate → Process → Persist → Notify |
| Service Registration | AddScoped in Program.cs or extension methods |

> **Next Topic**: Authentication & Authorization (JWT) — Securing your API.
