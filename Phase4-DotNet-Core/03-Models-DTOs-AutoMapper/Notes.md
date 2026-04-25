# Topic 3: Models, DTOs & AutoMapper

## 📘 What Are Models?

In ASP.NET Core, **models** represent the data structures used throughout your application. There are different types of models serving different purposes.

### Types of Models

| Model Type | Purpose | Example |
|-----------|---------|---------|
| **Domain Model / Entity** | Represents database table | `Product` with all DB columns |
| **DTO (Data Transfer Object)** | Shapes data for API requests/responses | `ProductDto` with selected fields |
| **View Model** | Shapes data for UI (MVC/Razor) | `ProductViewModel` with display formatting |
| **Request Model** | Incoming API request body | `CreateProductRequest` |
| **Response Model** | Outgoing API response body | `ProductResponse` |

---

## 📘 Why DTOs? Why Not Expose Entities Directly?

### The Problem: Exposing Entities

```csharp
// ❌ BAD: Exposing entity directly
[HttpGet("{id}")]
public ActionResult<User> GetById(int id)
{
    var user = _dbContext.Users.Find(id);
    return Ok(user);  // Exposes PasswordHash, internal IDs, navigation props!
}
```

### What Goes Wrong:

| Problem | Description |
|---------|------------|
| **Security** | Sensitive fields exposed (passwords, internal IDs, audit fields) |
| **Over-posting** | Client can set fields you don't want (IsAdmin, CreatedDate) |
| **Tight coupling** | API contract tied to database schema — DB changes break the API |
| **Circular references** | Navigation properties cause infinite JSON serialization loops |
| **Performance** | Returns more data than the client needs |
| **Versioning** | Can't have v1 and v2 of an endpoint with different shapes |

### The Solution: DTOs

```csharp
// ✅ GOOD: Using DTOs
[HttpGet("{id}")]
public ActionResult<UserDto> GetById(int id)
{
    var user = _dbContext.Users.Find(id);
    var dto = new UserDto
    {
        Id = user.Id,
        Name = user.Name,
        Email = user.Email
        // No PasswordHash, no internal fields!
    };
    return Ok(dto);
}
```

---

## 📘 Entity Models (Domain Models)

Entities represent your **database tables**. They are your core data structures.

```csharp
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public int StockQuantity { get; set; }
    public bool IsActive { get; set; } = true;
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedDate { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    
    // Navigation properties (relationships)
    public int CategoryId { get; set; }
    public Category CategoryNavigation { get; set; } = null!;
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<Review> Reviews { get; set; } = new List<Review>();
}

public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;  // NEVER expose this!
    public string Salt { get; set; } = string.Empty;           // NEVER expose this!
    public string Role { get; set; } = "User";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedDate { get; set; }
    public DateTime? LastLoginDate { get; set; }
    
    // Navigation
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}
```

---

## 📘 DTO Patterns

### Pattern 1: Separate DTOs for Each Operation

```csharp
// For reading (GET responses)
public class ProductDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public string FormattedPrice => $"${Price:F2}";
}

// For creating (POST request body)
public class CreateProductDto
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    [Required]
    [Range(0.01, 99999.99)]
    public decimal Price { get; set; }
    
    [Required]
    public string Category { get; set; } = string.Empty;
    
    [Range(0, int.MaxValue)]
    public int StockQuantity { get; set; }
}

// For updating (PUT request body)
public class UpdateProductDto
{
    [Required]
    [StringLength(100, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    [Required]
    [Range(0.01, 99999.99)]
    public decimal Price { get; set; }
    
    [Required]
    public string Category { get; set; } = string.Empty;
    
    [Range(0, int.MaxValue)]
    public int StockQuantity { get; set; }
    
    public bool IsActive { get; set; }
}

// For listing (simplified, less data)
public class ProductListDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
}
```

### Pattern 2: Nested DTOs

```csharp
public class OrderDto
{
    public int Id { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    
    // Nested DTO (not the full User entity!)
    public OrderCustomerDto Customer { get; set; } = null!;
    
    // Collection of nested DTOs
    public List<OrderItemDto> Items { get; set; } = new();
}

public class OrderCustomerDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public class OrderItemDto
{
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}
```

---

## 📘 Manual Mapping (Without AutoMapper)

### Simple Mapping

```csharp
// Entity → DTO
public static ProductDto ToDto(Product product)
{
    return new ProductDto
    {
        Id = product.Id,
        Name = product.Name,
        Description = product.Description,
        Price = product.Price,
        Category = product.CategoryNavigation?.Name ?? product.Category,
        IsActive = product.IsActive
    };
}

// DTO → Entity
public static Product ToEntity(CreateProductDto dto)
{
    return new Product
    {
        Name = dto.Name,
        Description = dto.Description,
        Price = dto.Price,
        Category = dto.Category,
        StockQuantity = dto.StockQuantity,
        CreatedDate = DateTime.UtcNow
    };
}

// Update entity from DTO
public static void UpdateEntity(Product product, UpdateProductDto dto)
{
    product.Name = dto.Name;
    product.Description = dto.Description;
    product.Price = dto.Price;
    product.Category = dto.Category;
    product.StockQuantity = dto.StockQuantity;
    product.IsActive = dto.IsActive;
    product.UpdatedDate = DateTime.UtcNow;
}
```

### Extension Method Pattern

```csharp
public static class ProductMappingExtensions
{
    public static ProductDto ToDto(this Product product)
    {
        return new ProductDto
        {
            Id = product.Id,
            Name = product.Name,
            Price = product.Price,
            Category = product.Category
        };
    }
    
    public static List<ProductDto> ToDtoList(this IEnumerable<Product> products)
    {
        return products.Select(p => p.ToDto()).ToList();
    }
    
    public static Product ToEntity(this CreateProductDto dto)
    {
        return new Product
        {
            Name = dto.Name,
            Price = dto.Price,
            Category = dto.Category
        };
    }
}

// Usage
var dto = product.ToDto();
var dtos = products.ToDtoList();
var entity = createDto.ToEntity();
```

### Problems with Manual Mapping

| Problem | Impact |
|---------|--------|
| **Tedious** | Writing mapping code for every property is repetitive |
| **Error-prone** | Easy to forget a property when adding new fields |
| **Maintenance** | Adding a property requires updating mapping code everywhere |
| **Boilerplate** | Lots of code that doesn't add business value |

---

## 📘 AutoMapper: Automatic Object Mapping

AutoMapper **automatically maps properties** between objects based on naming conventions.

### Installation

```bash
dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection
```

### Setup in Program.cs

```csharp
var builder = WebApplication.CreateBuilder(args);

// Register AutoMapper — scans assembly for Profile classes
builder.Services.AddAutoMapper(typeof(Program).Assembly);
// OR specify profile types
builder.Services.AddAutoMapper(typeof(ProductProfile));
```

### Creating Mapping Profiles

```csharp
using AutoMapper;

public class ProductProfile : Profile
{
    public ProductProfile()
    {
        // Simple mapping (property names match)
        CreateMap<Product, ProductDto>();
        
        // Reverse mapping (DTO → Entity)
        CreateMap<CreateProductDto, Product>();
        
        // Mapping with custom member configuration
        CreateMap<Product, ProductDetailDto>()
            .ForMember(dest => dest.CategoryName, 
                       opt => opt.MapFrom(src => src.CategoryNavigation.Name))
            .ForMember(dest => dest.ReviewCount, 
                       opt => opt.MapFrom(src => src.Reviews.Count))
            .ForMember(dest => dest.AverageRating, 
                       opt => opt.MapFrom(src => src.Reviews.Average(r => r.Rating)));
        
        // Ignore certain properties
        CreateMap<UpdateProductDto, Product>()
            .ForMember(dest => dest.Id, opt => opt.Ignore())
            .ForMember(dest => dest.CreatedDate, opt => opt.Ignore())
            .ForMember(dest => dest.CreatedBy, opt => opt.Ignore());
    }
}
```

### Using AutoMapper in Controllers

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductRepository _repository;
    private readonly IMapper _mapper;

    public ProductsController(IProductRepository repository, IMapper mapper)
    {
        _repository = repository;
        _mapper = mapper;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAll()
    {
        var products = await _repository.GetAllAsync();
        var dtos = _mapper.Map<IEnumerable<ProductDto>>(products);
        return Ok(dtos);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDetailDto>> GetById(int id)
    {
        var product = await _repository.GetByIdAsync(id);
        if (product == null) return NotFound();
        
        var dto = _mapper.Map<ProductDetailDto>(product);
        return Ok(dto);
    }

    [HttpPost]
    public async Task<ActionResult<ProductDto>> Create(CreateProductDto createDto)
    {
        var product = _mapper.Map<Product>(createDto);
        await _repository.AddAsync(product);
        
        var dto = _mapper.Map<ProductDto>(product);
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, dto);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ProductDto>> Update(int id, UpdateProductDto updateDto)
    {
        var product = await _repository.GetByIdAsync(id);
        if (product == null) return NotFound();
        
        // Map updateDto properties onto existing product entity
        _mapper.Map(updateDto, product);
        await _repository.UpdateAsync(product);
        
        var dto = _mapper.Map<ProductDto>(product);
        return Ok(dto);
    }
}
```

---

## 📘 AutoMapper Advanced Features

### Flattening (Automatic)

AutoMapper automatically flattens nested properties:

```csharp
public class Order
{
    public Customer Customer { get; set; }  // Navigation prop
}

public class Customer
{
    public string Name { get; set; }
}

public class OrderDto
{
    public string CustomerName { get; set; }  // Flattened! Order.Customer.Name → CustomerName
}

// AutoMapper matches "CustomerName" to "Customer.Name" automatically!
CreateMap<Order, OrderDto>();
```

### Conditional Mapping

```csharp
CreateMap<Product, ProductDto>()
    .ForMember(dest => dest.DiscountedPrice, opt => opt.Condition(src => src.IsOnSale))
    .ForMember(dest => dest.DiscountedPrice, 
               opt => opt.MapFrom(src => src.Price * 0.9m));
```

### Value Resolvers (Complex Logic)

```csharp
public class FullNameResolver : IValueResolver<User, UserDto, string>
{
    public string Resolve(User source, UserDto destination, string destMember, ResolutionContext context)
    {
        return $"{source.FirstName} {source.LastName}".Trim();
    }
}

// In profile
CreateMap<User, UserDto>()
    .ForMember(dest => dest.FullName, opt => opt.MapFrom<FullNameResolver>());
```

### Type Converters (Entire Type Mapping)

```csharp
public class DateTimeToStringConverter : ITypeConverter<DateTime, string>
{
    public string Convert(DateTime source, string destination, ResolutionContext context)
    {
        return source.ToString("yyyy-MM-dd HH:mm:ss");
    }
}

// In profile
CreateMap<DateTime, string>().ConvertUsing<DateTimeToStringConverter>();
```

### Null Substitution

```csharp
CreateMap<Product, ProductDto>()
    .ForMember(dest => dest.Description, 
               opt => opt.NullSubstitute("No description available"));
```

### Collection Mapping

```csharp
// AutoMapper handles collections automatically
CreateMap<Product, ProductDto>();  // That's it!

// This works:
var products = await _repository.GetAllAsync();
var dtos = _mapper.Map<List<ProductDto>>(products);

// And this:
var dtos = _mapper.Map<IEnumerable<ProductDto>>(products);
```

### Mapping Inheritance

```csharp
public class Vehicle { }
public class Car : Vehicle { }
public class Truck : Vehicle { }

public class VehicleDto { }
public class CarDto : VehicleDto { }
public class TruckDto : VehicleDto { }

// In profile
CreateMap<Vehicle, VehicleDto>()
    .Include<Car, CarDto>()
    .Include<Truck, TruckDto>();

CreateMap<Car, CarDto>();
CreateMap<Truck, TruckDto>();
```

---

## 📘 Projection with AutoMapper (LINQ + EF Core)

Instead of loading full entities then mapping, **project directly in the query**:

```csharp
// ❌ Inefficient: Loads ALL columns, then maps in memory
var products = await _dbContext.Products.ToListAsync();
var dtos = _mapper.Map<List<ProductDto>>(products);

// ✅ Efficient: Only selects needed columns in SQL query
var dtos = await _dbContext.Products
    .ProjectTo<ProductDto>(_mapper.ConfigurationProvider)
    .ToListAsync();
```

`ProjectTo<T>()` generates a SQL `SELECT` with only the columns needed for the DTO, reducing data transfer.

---

## 📘 Validation with Data Annotations

### Common Validation Attributes

```csharp
public class CreateProductDto
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name: 2-100 chars")]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(500, ErrorMessage = "Description max 500 chars")]
    public string? Description { get; set; }
    
    [Required]
    [Range(0.01, 99999.99, ErrorMessage = "Price: $0.01 - $99,999.99")]
    public decimal Price { get; set; }
    
    [Required]
    [RegularExpression(@"^(Electronics|Clothing|Food|Books)$",
        ErrorMessage = "Invalid category")]
    public string Category { get; set; } = string.Empty;
    
    [Range(0, int.MaxValue, ErrorMessage = "Stock cannot be negative")]
    public int StockQuantity { get; set; }
    
    [Url(ErrorMessage = "Invalid URL")]
    public string? ImageUrl { get; set; }
}
```

### Custom Validation Attributes

```csharp
public class FutureDateAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext context)
    {
        if (value is DateTime date && date <= DateTime.UtcNow)
        {
            return new ValidationResult("Date must be in the future");
        }
        return ValidationResult.Success;
    }
}

// Usage
public class CreateEventDto
{
    [Required]
    public string Title { get; set; } = string.Empty;
    
    [FutureDate(ErrorMessage = "Event date must be in the future")]
    public DateTime EventDate { get; set; }
}
```

### IValidatableObject (Cross-Property Validation)

```csharp
public class DateRangeDto : IValidatableObject
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (EndDate <= StartDate)
        {
            yield return new ValidationResult(
                "EndDate must be after StartDate",
                new[] { nameof(EndDate) });
        }
    }
}
```

---

## 📘 FluentValidation (Alternative to Data Annotations)

A more powerful, testable validation library:

```bash
dotnet add package FluentValidation.AspNetCore
```

```csharp
public class CreateProductValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .MinimumLength(2).WithMessage("Name must be at least 2 characters")
            .MaximumLength(100).WithMessage("Name cannot exceed 100 characters");
        
        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be positive")
            .LessThanOrEqualTo(99999.99m);
        
        RuleFor(x => x.Category)
            .NotEmpty()
            .Must(BeAValidCategory).WithMessage("Invalid category");
        
        RuleFor(x => x.ImageUrl)
            .Must(BeAValidUrl).When(x => !string.IsNullOrEmpty(x.ImageUrl))
            .WithMessage("Invalid URL format");
    }
    
    private bool BeAValidCategory(string category)
    {
        var validCategories = new[] { "Electronics", "Clothing", "Food", "Books" };
        return validCategories.Contains(category);
    }
    
    private bool BeAValidUrl(string? url)
    {
        return Uri.TryCreate(url, UriKind.Absolute, out _);
    }
}

// Register in Program.cs
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<CreateProductValidator>();
```

---

## 📘 Response Wrapper Pattern

Standardize all API responses:

```csharp
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public List<string>? Errors { get; set; }
    public int StatusCode { get; set; }
    
    public static ApiResponse<T> Ok(T data, string? message = null)
    {
        return new ApiResponse<T>
        {
            Success = true,
            Data = data,
            Message = message,
            StatusCode = 200
        };
    }
    
    public static ApiResponse<T> Created(T data)
    {
        return new ApiResponse<T>
        {
            Success = true,
            Data = data,
            StatusCode = 201
        };
    }
    
    public static ApiResponse<T> Fail(string message, int statusCode = 400)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Message = message,
            StatusCode = statusCode
        };
    }
    
    public static ApiResponse<T> Fail(List<string> errors, int statusCode = 400)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Errors = errors,
            StatusCode = statusCode
        };
    }
}

// Paginated response
public class PagedResponse<T>
{
    public List<T> Data { get; set; } = new();
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasPrevious => Page > 1;
    public bool HasNext => Page < TotalPages;
}
```

---

## 📘 Project Organization

```
MyApi/
├── Models/
│   ├── Entities/
│   │   ├── Product.cs
│   │   ├── Order.cs
│   │   └── User.cs
│   ├── DTOs/
│   │   ├── Products/
│   │   │   ├── ProductDto.cs
│   │   │   ├── CreateProductDto.cs
│   │   │   ├── UpdateProductDto.cs
│   │   │   └── ProductListDto.cs
│   │   ├── Orders/
│   │   │   ├── OrderDto.cs
│   │   │   └── CreateOrderDto.cs
│   │   └── Common/
│   │       ├── ApiResponse.cs
│   │       └── PagedResponse.cs
│   └── Validators/
│       ├── CreateProductValidator.cs
│       └── UpdateProductValidator.cs
├── Mappings/
│   ├── ProductProfile.cs
│   ├── OrderProfile.cs
│   └── UserProfile.cs
└── Controllers/
    ├── ProductsController.cs
    └── OrdersController.cs
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| Entities | Database models with all columns and navigation properties |
| DTOs | Shaped data objects for API contracts — never expose entities |
| Separate DTOs | CreateDto, UpdateDto, ResponseDto for each entity |
| Manual Mapping | Extension methods work but are tedious and error-prone |
| AutoMapper | Convention-based mapping with Profiles — reduces boilerplate |
| ProjectTo | LINQ + AutoMapper for efficient SQL queries |
| Validation | Data Annotations (simple) or FluentValidation (complex) |
| Response Wrapper | `ApiResponse<T>` standardizes all API responses |
| Flattening | AutoMapper auto-maps `Customer.Name` → `CustomerName` |

> **Next Topic**: Entity Framework Core & SQL Server — Connecting your API to a real database.
