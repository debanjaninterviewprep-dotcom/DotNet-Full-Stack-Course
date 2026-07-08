# Topic 03: Models, DTOs, and AutoMapper — Interview Questions

---

## Q1. What is a DTO and why is it important?
**Answer:**
A DTO (Data Transfer Object) is a plain class used to transfer data between layers or across API boundaries — separate from domain/entity models:

```csharp
// Entity — maps to database, has navigation properties, EF Core concerns
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string PasswordHash { get; set; } = ""; // NEVER expose this!
    public DateTime CreatedAt { get; set; }
    public ICollection<Order> Orders { get; set; } = []; // navigation property
}

// Response DTO — what the API returns (safe subset)
public class UserDto
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Email { get; init; } = "";
    public DateTime CreatedAt { get; init; }
    // No PasswordHash, no Orders (unless specifically needed)
}

// Request DTO — what the API accepts for creation
public class CreateUserDto
{
    [Required, MinLength(2), MaxLength(50)]
    public string Name { get; init; } = "";

    [Required, EmailAddress]
    public string Email { get; init; } = "";

    [Required, MinLength(8)]
    public string Password { get; init; } = ""; // plain text — service will hash it
}
```

---

## Q2. Why separate DTOs from domain entities?
**Answer:**
1. **Security** — prevent over-posting and accidental exposure of sensitive fields (`PasswordHash`, internal flags).
2. **API stability** — change entity structure without breaking API contracts.
3. **Shape differences** — flattened DTOs, computed fields, different naming.
4. **Validation** — apply input-specific validation rules to request DTOs.
5. **Performance** — return only what the client needs (smaller payload).
6. **Versioning** — `UserDtoV1` / `UserDtoV2` without touching the domain model.

---

## Q3. What is AutoMapper and how is it configured?
**Answer:**
AutoMapper is a convention-based object-to-object mapping library that eliminates repetitive mapping code:

```csharp
// Install: AutoMapper
// Define mapping profile
public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserDto>();                    // automatic for same-named properties
        CreateMap<CreateUserDto, User>()               // from DTO to entity
            .ForMember(dest => dest.CreatedAt,
                       opt  => opt.MapFrom(_ => DateTime.UtcNow))
            .ForMember(dest => dest.PasswordHash,
                       opt  => opt.Ignore());          // skip — set manually in service

        CreateMap<Order, OrderDto>()
            .ForMember(dest => dest.CustomerName,
                       opt  => opt.MapFrom(src => src.User.Name)); // flattening
    }
}

// Register in DI
builder.Services.AddAutoMapper(typeof(MappingProfile));

// Use in service/controller
public class UserService(IMapper mapper, IUserRepository repo)
{
    public async Task<UserDto> GetByIdAsync(int id) {
        var user = await repo.GetByIdAsync(id);
        return mapper.Map<UserDto>(user); // entity → DTO
    }

    public async Task<UserDto> CreateAsync(CreateUserDto dto) {
        var user = mapper.Map<User>(dto); // DTO → entity
        user.PasswordHash = _hasher.Hash(dto.Password);
        await repo.AddAsync(user);
        return mapper.Map<UserDto>(user);
    }
}
```

---

## Q4. What are AutoMapper mapping configurations and options?
**Answer:**
```csharp
CreateMap<Source, Destination>()
    // Custom member mapping
    .ForMember(dest => dest.FullName,
               opt  => opt.MapFrom(src => $"{src.FirstName} {src.LastName}"))

    // Ignore a member
    .ForMember(dest => dest.PasswordHash, opt => opt.Ignore())

    // Conditional mapping
    .ForMember(dest => dest.Email,
               opt  => opt.MapFrom(src => src.IsEmailVerified ? src.Email : null))

    // Pre/Post map actions
    .AfterMap((src, dest) => dest.CreatedAt = DateTime.UtcNow)

    // Null substitution
    .ForMember(dest => dest.Description, opt => opt.NullSubstitute("No description"))

    // Use a value resolver
    .ForMember(dest => dest.Slug, opt => opt.MapFrom<SlugResolver>())

    // Flatten nested object
    .ForMember(dest => dest.CityName, opt => opt.MapFrom(src => src.Address.City));
```

---

## Q5. What is `ReverseMap` and when do you use it?
**Answer:**
`ReverseMap` creates a bidirectional mapping (both directions with one call):

```csharp
CreateMap<UserDto, User>().ReverseMap();
// Equivalent to:
// CreateMap<UserDto, User>();
// CreateMap<User, UserDto>();

// But only for simple cases — complex mappings may need separate ReverseMap configuration
CreateMap<User, UserDto>()
    .ForMember(dest => dest.FullName, opt => opt.MapFrom(src => $"{src.First} {src.Last}"))
    .ReverseMap()
    .ForMember(dest => dest.First, opt => opt.MapFrom(src => src.FullName.Split(' ')[0]))
    .ForMember(dest => dest.Last,  opt => opt.MapFrom(src => src.FullName.Split(' ')[1]));
```

---

## Q6. What is `ProjectTo` and why is it more efficient than `Map`?
**Answer:**
`ProjectTo` translates the mapping to an IQueryable expression — pushed down to the database as a SQL projection:

```csharp
// Without ProjectTo — loads entire User entity (all columns), then maps in memory
var users = await _db.Users.ToListAsync();          // SELECT * FROM Users
return mapper.Map<List<UserDto>>(users);

// With ProjectTo — only selects needed columns in SQL
var users = await _db.Users
    .ProjectTo<UserDto>(mapper.ConfigurationProvider) // SELECT Id, Name, Email FROM Users
    .ToListAsync();

// Benefits:
// 1. No over-fetching — only selected columns loaded
// 2. Filters applied in DB — WHERE, ORDER BY work on projected type
// 3. Works with Include-free eager loading

// With filter
var activeUsers = await _db.Users
    .Where(u => u.IsActive)           // WHERE applied in SQL
    .ProjectTo<UserDto>(cfg)
    .OrderBy(u => u.Name)             // ORDER BY in SQL
    .Skip(page * size).Take(size)     // LIMIT/OFFSET in SQL
    .ToListAsync();
```

---

## Q7. What is a value resolver in AutoMapper?
**Answer:**
A value resolver encapsulates complex mapping logic in a reusable class:

```csharp
// Define resolver
public class SlugResolver : IValueResolver<Article, ArticleDto, string>
{
    public string Resolve(Article source, ArticleDto destination, string destMember, ResolutionContext context)
        => source.Title.ToLower().Replace(' ', '-').Trim();
}

// Register in profile
CreateMap<Article, ArticleDto>()
    .ForMember(dest => dest.Slug, opt => opt.MapFrom<SlugResolver>());

// Or inline resolver
CreateMap<Product, ProductDto>()
    .ForMember(dest => dest.PriceDisplay,
               opt  => opt.MapFrom((src, dest, _, ctx) =>
                   ctx.Mapper.Map<CurrencyDto>(src.Price)));
```

---

## Q8. What is a type converter in AutoMapper?
**Answer:**
Type converters convert one type to another across all mappings:

```csharp
// Converter class
public class DateTimeToStringConverter : ITypeConverter<DateTime, string>
{
    public string Convert(DateTime source, string destination, ResolutionContext context)
        => source.ToString("yyyy-MM-dd HH:mm:ss UTC");
}

// Register globally
CreateMap<DateTime, string>().ConvertUsing<DateTimeToStringConverter>();
// Now ALL DateTime → string mappings use this converter

// Or inline for a specific type pair
CreateMap<Money, decimal>().ConvertUsing(m => m.Amount);
```

---

## Q9. How do you handle collection mapping in AutoMapper?
**Answer:**
AutoMapper automatically handles collection types:

```csharp
// Single → single
mapper.Map<UserDto>(user);

// List → List (automatic)
mapper.Map<List<UserDto>>(users);

// Array → Array
mapper.Map<UserDto[]>(users);

// With custom list mapping
public class UserWithOrdersDto
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public List<OrderSummaryDto> RecentOrders { get; set; } = [];
}

CreateMap<User, UserWithOrdersDto>()
    .ForMember(dest => dest.RecentOrders,
               opt  => opt.MapFrom(src => src.Orders.OrderByDescending(o => o.Date).Take(5)));
```

---

## Q10. How do you validate DTOs in ASP.NET Core?
**Answer:**
Use Data Annotations or FluentValidation:

```csharp
// Data Annotations on DTO
public class CreateUserDto
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(50, MinimumLength = 2)]
    public string Name { get; init; } = "";

    [Required, EmailAddress]
    public string Email { get; init; } = "";

    [Required, MinLength(8)]
    [RegularExpression(@"^(?=.*[A-Z])(?=.*\d).+$",
        ErrorMessage = "Password must contain uppercase and digit")]
    public string Password { get; init; } = "";

    [Range(0, 120)]
    public int? Age { get; init; }
}

// FluentValidation (more powerful)
public class CreateUserValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserValidator(IUserRepository repo)
    {
        RuleFor(x => x.Name).NotEmpty().Length(2, 50);
        RuleFor(x => x.Email).NotEmpty().EmailAddress()
            .MustAsync(async (email, ct) => !await repo.ExistsAsync(email))
            .WithMessage("Email already in use");
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8)
            .Matches("[A-Z]").WithMessage("Must contain uppercase")
            .Matches("[0-9]").WithMessage("Must contain digit");
    }
}

// Register FluentValidation
builder.Services.AddValidatorsFromAssemblyContaining<CreateUserValidator>();
builder.Services.AddFluentValidationAutoValidation(); // integrates with ModelState
```

---

## Q11. What is the difference between input and output models?
**Answer:**
```csharp
// Input models (request DTOs) — what API accepts
public class CreateProductDto    { /* fields + validation attributes */ }
public class UpdateProductDto    { /* fields + validation — different from Create */ }
public class ProductSearchParams { /* query parameters */ }

// Output models (response DTOs) — what API returns
public class ProductDto           { /* safe subset of entity, computed fields */ }
public class ProductSummaryDto    { /* lighter version for lists */ }
public class ProductDetailDto     { /* full detail with related data */ }

// Never expose the same type in both directions:
// ❌ Return the entity directly
[HttpGet("{id}")]
public Product GetById(int id) => _repo.Get(id); // exposes DB structure, may cause infinite loops

// ✓ Return a DTO
[HttpGet("{id}")]
public ProductDto GetById(int id) => mapper.Map<ProductDto>(_repo.Get(id));
```

---

## Q12. What is over-posting and how does AutoMapper help prevent it?
**Answer:**
Over-posting (mass assignment attack) occurs when a client sends extra fields that get bound and persisted:

```csharp
// ❌ Vulnerable — client could POST { "Name": "Alice", "IsAdmin": true }
[HttpPost]
public IActionResult Create([FromBody] User user) {
    _db.Users.Add(user); // isAdmin from user gets saved!
    _db.SaveChanges();
    return Ok();
}

// ✓ Safe with DTO — only Name/Email accepted
[HttpPost]
public IActionResult Create([FromBody] CreateUserDto dto) {
    var user = mapper.Map<User>(dto); // only maps Name and Email from DTO
    _db.Users.Add(user);
    _db.SaveChanges();
    return Ok();
}
```

---

## Q13. What is the `[BindNever]` and `[BindRequired]` attribute?
**Answer:**
```csharp
// [BindNever] — exclude property from model binding (cannot be over-posted)
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = "";

    [BindNever]
    public string PasswordHash { get; set; } = ""; // never bound from request

    [BindNever]
    public DateTime CreatedAt { get; set; }
}

// [BindRequired] — model binding must succeed for this property (binding error if absent)
public class SearchParams
{
    [BindRequired]
    public string Query { get; set; } = ""; // 400 if not provided in query string
}
```

---

## Q14. How do you handle nested mappings in AutoMapper?
**Answer:**
```csharp
// Nested objects
public class OrderDto
{
    public int Id { get; init; }
    public UserSummaryDto Customer { get; init; } = new();
    public List<OrderItemDto> Items { get; init; } = [];
    public decimal Total => Items.Sum(i => i.Subtotal);
}

// AutoMapper automatically maps nested types if profiles exist
CreateMap<User, UserSummaryDto>();     // register nested mapping
CreateMap<OrderItem, OrderItemDto>();  // register nested mapping
CreateMap<Order, OrderDto>();          // AutoMapper resolves nested mappings automatically

// With custom nested configuration
CreateMap<Order, OrderDto>()
    .ForMember(dest => dest.Customer,
               opt  => opt.MapFrom(src => src.User)) // maps User → UserSummaryDto
    .ForMember(dest => dest.Items,
               opt  => opt.MapFrom(src => src.OrderItems)); // maps OrderItems → OrderItemDto list
```

---

## Q15. What is the `IMappingAction` in AutoMapper?
**Answer:**
`IMappingAction` runs code after mapping is complete, useful for side effects like logging or audit:

```csharp
public class AuditMappingAction : IMappingAction<CreateUserDto, User>
{
    private readonly IAuditService _audit;

    public AuditMappingAction(IAuditService audit) => _audit = audit;

    public void Process(CreateUserDto source, User destination, ResolutionContext context)
    {
        destination.CreatedBy = context.Items["CurrentUserId"]?.ToString();
        _audit.Log($"User created from DTO: {source.Email}");
    }
}

// Register in profile
CreateMap<CreateUserDto, User>()
    .AfterMap<AuditMappingAction>();

// Pass context items
mapper.Map<User>(dto, opts => opts.Items["CurrentUserId"] = currentUserId);
```
