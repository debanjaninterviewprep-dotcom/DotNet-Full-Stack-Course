# Topic 04: CRUD, DTOs, Validation & Pagination — Interview Questions

---

## Q1. What are the best practices for implementing CRUD APIs?
**Answer:**
```csharp
// Controller — thin, delegates to service
[ApiController, Route("api/[controller]")]
public class ProductsController(IProductService svc) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<ProductDto>> GetAll([FromQuery] ProductQueryParams p)
        => svc.GetPagedAsync(p);

    [HttpGet("{id:int}")]
    [ProducesResponseType<ProductDto>(200)]
    [ProducesResponseType(404)]
    public async Task<ActionResult<ProductDto>> GetById(int id)
    {
        var product = await svc.GetByIdAsync(id);
        return product is null ? NotFound() : Ok(product);
    }

    [HttpPost]
    [ProducesResponseType<ProductDto>(201)]
    [ProducesResponseType<ValidationProblemDetails>(400)]
    public async Task<ActionResult<ProductDto>> Create(CreateProductDto dto)
    {
        var product = await svc.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { product.Id }, product);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateProductDto dto)
    {
        await svc.UpdateAsync(id, dto);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        await svc.DeleteAsync(id);
        return NoContent();
    }
}
```

---

## Q2. How do you implement pagination, sorting, and filtering efficiently?
**Answer:**
```csharp
// Query parameters DTO
public class ProductQueryParams
{
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
    public string? Search { get; init; }
    public string? Category { get; init; }
    public decimal? MinPrice { get; init; }
    public decimal? MaxPrice { get; init; }
    public string SortBy { get; init; } = "id";
    public string SortOrder { get; init; } = "asc";
}

// Service applies all filters in one query
public async Task<PagedResult<ProductDto>> GetPagedAsync(ProductQueryParams p)
{
    var query = _db.Products.AsNoTracking();

    // Dynamic filtering
    if (p.Search is not null)    query = query.Where(x => x.Name.Contains(p.Search));
    if (p.Category is not null)  query = query.Where(x => x.Category == p.Category);
    if (p.MinPrice.HasValue)     query = query.Where(x => x.Price >= p.MinPrice.Value);
    if (p.MaxPrice.HasValue)     query = query.Where(x => x.Price <= p.MaxPrice.Value);

    // Dynamic sorting
    query = (p.SortBy, p.SortOrder) switch {
        ("name",  "asc")  => query.OrderBy(x => x.Name),
        ("name",  "desc") => query.OrderByDescending(x => x.Name),
        ("price", "asc")  => query.OrderBy(x => x.Price),
        ("price", "desc") => query.OrderByDescending(x => x.Price),
        _                 => query.OrderBy(x => x.Id)
    };

    int total = await query.CountAsync();
    var items = await query.Skip((p.Page - 1) * p.PageSize).Take(p.PageSize)
        .ProjectTo<ProductDto>(_mapper.ConfigurationProvider)
        .ToListAsync();

    return new PagedResult<ProductDto>(items, total, p.Page, p.PageSize);
}
```

---

## Q3. What is the difference between `PUT` and `PATCH` in practice?
**Answer:**
```csharp
// PUT DTO — ALL fields required (full replacement)
public class UpdateProductDto
{
    [Required] public string Name { get; init; } = "";
    [Required] public decimal Price { get; init; }
    [Required] public string Category { get; init; } = "";
    public string? Description { get; init; }
}

// PATCH DTO — optional fields (partial update)
public class PatchProductDto
{
    public string? Name { get; init; }
    public decimal? Price { get; init; }
    public string? Category { get; init; }
    public string? Description { get; init; }
}

// PATCH implementation — only update non-null fields
[HttpPatch("{id:int}")]
public async Task<IActionResult> Patch(int id, PatchProductDto dto)
{
    var product = await _repo.GetByIdAsync(id) ?? throw new NotFoundException("Product", id);

    if (dto.Name is not null)        product.Name = dto.Name;
    if (dto.Price.HasValue)          product.Price = dto.Price.Value;
    if (dto.Category is not null)    product.Category = dto.Category;
    if (dto.Description is not null) product.Description = dto.Description;

    await _uow.SaveChangesAsync();
    return NoContent();
}
```

---

## Q4. What is FluentValidation and how does it integrate with ASP.NET Core?
**Answer:**
```csharp
// Install: FluentValidation.AspNetCore
// Validator class
public class CreateProductValidator : AbstractValidator<CreateProductDto>
{
    public CreateProductValidator(ICategoryRepository categoryRepo)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .Length(3, 100).WithMessage("Name must be 3-100 characters");

        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be positive")
            .LessThanOrEqualTo(100_000).WithMessage("Price cannot exceed 100,000");

        RuleFor(x => x.CategoryId)
            .GreaterThan(0)
            .MustAsync(async (id, ct) => await categoryRepo.ExistsAsync(id))
            .WithMessage("Category does not exist");

        RuleFor(x => x.Description)
            .MaximumLength(2000).When(x => x.Description is not null);

        RuleSet("Edit", () => {
            RuleFor(x => x.Price).NotNull(); // extra rule for edit scenario
        });
    }
}

// Register
builder.Services.AddValidatorsFromAssemblyContaining<CreateProductValidator>();
builder.Services.AddFluentValidationAutoValidation(); // integrates with ModelState

// Custom response format on validation failure
builder.Services.Configure<ApiBehaviorOptions>(opts => {
    opts.InvalidModelStateResponseFactory = ctx =>
        new UnprocessableEntityObjectResult(new ValidationProblemDetails(ctx.ModelState));
});
```

---

## Q5. What is the difference between Data Annotations and FluentValidation?
**Answer:**
| | Data Annotations | FluentValidation |
|---|---|---|
| **Location** | On the DTO class | Separate validator class |
| **Async rules** | ✗ | ✓ (DB uniqueness checks) |
| **Dependency injection** | ✗ | ✓ |
| **Conditional rules** | Limited | ✓ `When()`, `Unless()` |
| **Complex rules** | Limited | ✓ Custom `Must()` |
| **Reusability** | Low | High (validators composable) |
| **Test-friendly** | Low | ✓ Validators can be unit tested |

**Best practice:** Use FluentValidation for all validation — use Data Annotations only for client-side hints (Swagger UI, JavaScript validation).

---

## Q6. How do you implement bulk operations in an API?
**Answer:**
```csharp
// Bulk create
[HttpPost("batch")]
public async Task<ActionResult<IEnumerable<ProductDto>>> CreateBatch(
    [FromBody] IEnumerable<CreateProductDto> dtos)
{
    if (!dtos.Any() || dtos.Count() > 100) // limit batch size
        return BadRequest("Batch must contain 1-100 items");

    var products = _mapper.Map<List<Product>>(dtos);
    await _db.Products.AddRangeAsync(products);
    await _db.SaveChangesAsync();
    return CreatedAtAction(null, _mapper.Map<List<ProductDto>>(products));
}

// Bulk delete
[HttpDelete("batch")]
public async Task<IActionResult> DeleteBatch([FromBody] int[] ids)
{
    await _db.Products.Where(p => ids.Contains(p.Id)).ExecuteDeleteAsync();
    return NoContent();
}

// Bulk update — ExecuteUpdateAsync (EF Core 7+)
[HttpPatch("batch/activate")]
public async Task<IActionResult> ActivateBatch([FromBody] int[] ids)
{
    int count = await _db.Products
        .Where(p => ids.Contains(p.Id))
        .ExecuteUpdateAsync(s => s.SetProperty(p => p.IsActive, true));
    return Ok(new { Updated = count });
}
```

---

## Q7. How do you handle validation errors uniformly across the API?
**Answer:**
```csharp
// Problem Details format for validation errors (default with [ApiController])
// Response: 400 Bad Request
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "Name": ["Name is required", "Name must be 3-100 characters"],
    "Price": ["Price must be positive"]
  }
}

// Customise the validation response
builder.Services.Configure<ApiBehaviorOptions>(opts => {
    opts.InvalidModelStateResponseFactory = ctx => {
        var errors = ctx.ModelState
            .Where(x => x.Value?.Errors.Any() == true)
            .ToDictionary(
                x => x.Key,
                x => x.Value!.Errors.Select(e => e.ErrorMessage).ToArray()
            );

        return new BadRequestObjectResult(new {
            Type    = "https://example.com/errors/validation",
            Title   = "Validation Failed",
            Status  = 400,
            Errors  = errors,
            TraceId = Activity.Current?.Id
        });
    };
});
```

---

## Q8. What is OData and when should you use it?
**Answer:**
OData (Open Data Protocol) enables dynamic querying of API endpoints using a standardized query syntax:

```
// OData query examples
GET /api/products?$filter=Price gt 100 and Category eq 'Electronics'
GET /api/products?$select=Name,Price
GET /api/products?$orderby=Price desc
GET /api/products?$top=10&$skip=20
GET /api/products?$expand=Category,Reviews
GET /api/products?$count=true
```

```csharp
// ASP.NET Core OData
builder.Services.AddControllers().AddOData(opts =>
    opts.Select().Filter().OrderBy().Expand().Count().SetMaxTop(100)
        .AddRouteComponents("odata", GetEdmModel()));

[HttpGet, EnableQuery]
public IQueryable<Product> Get() => _db.Products.AsQueryable();
```

**Use OData when:** Building internal tools, admin panels, report builders where ad-hoc querying is needed. Avoid for public APIs — it exposes too much of your data model.

---

## Q9. What is soft delete vs hard delete and which is preferred?
**Answer:**
```csharp
// Hard delete — physically removes the record
DELETE FROM Products WHERE Id = 42

// Soft delete — marks as deleted, preserves the record
UPDATE Products SET IsDeleted = true, DeletedAt = GETUTCDATE() WHERE Id = 42

// When to use soft delete:
// ✓ Audit requirements (when was it deleted, by whom)
// ✓ Recovery/undo functionality
// ✓ Foreign key relationships (related records reference this)
// ✓ Compliance (GDPR retention policies)

// When hard delete is OK:
// - Truly disposable data (logs, temp records)
// - Strict GDPR erasure requirements (user data deletion)
// - Storage is a concern (massive tables)

// Important: soft delete with unique constraints
// If Email has UNIQUE constraint and user is soft-deleted, same email can't re-register!
// Solution: partial unique index WHERE IsDeleted = 0
CREATE UNIQUE INDEX IX_Users_Email ON Users(Email) WHERE IsDeleted = 0;
```

---

## Q10. What is the difference between `200 OK` and `201 Created`?
**Answer:**
```csharp
// 200 OK — general success, operation completed
// Use for: GET, PUT with response body, authenticated operations
return Ok(user);
return Ok(new { message = "Updated successfully" });

// 201 Created — resource was created
// MUST include Location header pointing to new resource
// Body should contain the created resource
[HttpPost]
public async Task<ActionResult<UserDto>> Create(CreateUserDto dto)
{
    var user = await _svc.CreateAsync(dto);

    // 201 + Location: /api/users/42
    return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
    // or: return Created($"/api/users/{user.Id}", user);
}

// 204 No Content — success but no body to return
// Use for: DELETE, PUT/PATCH when not returning the updated resource
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id) {
    await _svc.DeleteAsync(id);
    return NoContent(); // 204
}
```

---

## Q11. How do you handle large response payloads?
**Answer:**
```csharp
// 1. Always paginate — never return unbounded collections
// 2. Use projections — return only needed fields

// 3. Response compression
builder.Services.AddResponseCompression(opts => {
    opts.EnableForHttps = true;
    opts.Providers.Add<BrotliCompressionProvider>();
    opts.Providers.Add<GzipCompressionProvider>();
});

// 4. Streaming for very large datasets
[HttpGet("export")]
public async IAsyncEnumerable<ProductDto> StreamAll([EnumeratorCancellation] CancellationToken ct)
{
    await foreach (var product in _db.Products.AsAsyncEnumerable().WithCancellation(ct))
        yield return _mapper.Map<ProductDto>(product);
}
// Content-Type: application/x-ndjson (newline-delimited JSON)

// 5. Sparse fieldsets (select only needed fields)
GET /api/products?fields=id,name,price
// Parse fields param and use Select() dynamically
```

---

## Q12. What is the difference between `FindAsync` and `FirstOrDefaultAsync` in EF Core?
**Answer:**
```csharp
// FindAsync — checks local change tracker first, then DB (by primary key only)
// Faster when entity already loaded in same request
var user = await _db.Users.FindAsync(id);

// FirstOrDefaultAsync — always queries the database (any predicate)
// Returns first matching or null
var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == id);
var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

// SingleOrDefaultAsync — throws if MORE THAN ONE matches (use for business uniqueness)
var user = await _db.Users.SingleOrDefaultAsync(u => u.Email == email);

// When to use each:
// FindAsync — get by PK, especially in the same DbContext scope
// FirstOrDefaultAsync — get by non-PK or when using Include/AsNoTracking
// SingleOrDefaultAsync — when exactly one result expected (email lookup, username)
```

---

## Q13. What is the N+1 problem in a CRUD API and how do you fix it?
**Answer:**
```csharp
// N+1: Loading orders, then accessing user for each
var orders = await _db.Orders.ToListAsync();  // 1 query
foreach (var order in orders)
    Console.Write(order.User.Name);  // N queries! (lazy loading)

// Fix 1: Eager loading with Include
var orders = await _db.Orders.Include(o => o.User).ToListAsync(); // 1 JOIN query

// Fix 2: Projection — only load needed data
var summaries = await _db.Orders
    .Select(o => new OrderSummaryDto {
        Id = o.Id,
        CustomerName = o.User.Name,  // SQL handles the join
        Total = o.Total
    }).ToListAsync(); // 1 query with projection

// Fix 3: Split query for large includes
var orders = await _db.Orders
    .Include(o => o.Items)
    .AsSplitQuery()  // 2 queries but avoids cartesian explosion
    .ToListAsync();
```

---

## Q14. How do you implement search functionality?
**Answer:**
```csharp
// Simple LIKE search
var results = await _db.Products
    .Where(p => p.Name.Contains(searchTerm) ||
                p.Description.Contains(searchTerm))
    .ToListAsync();

// SQL Server Full-Text Search (requires FTS index)
var results = await _db.Products
    .Where(p => EF.Functions.FreeText(p.Name, searchTerm) ||
                EF.Functions.FreeText(p.Description, searchTerm))
    .ToListAsync();

// Trigram/fuzzy search with LIKE wildcards
var normalized = searchTerm.Trim().ToLower();
var results = await _db.Products
    .Where(p => EF.Functions.Like(p.Name.ToLower(), $"%{normalized}%"))
    .ToListAsync();

// For complex search — consider Elasticsearch/Azure Search
// POST /api/products/search
// { "query": "laptop", "filters": { "category": "Electronics", "priceRange": [100, 2000] } }
```

---

## Q15. What is optimistic concurrency and how do you handle it in update endpoints?
**Answer:**
```csharp
// Client must send the ETag it received when fetching the resource
[HttpPut("{id}")]
public async Task<IActionResult> Update(
    int id,
    UpdateProductDto dto,
    [FromHeader(Name = "If-Match")] string? ifMatch)
{
    if (ifMatch is null)
        return BadRequest("If-Match header required to prevent lost updates");

    var product = await _repo.GetByIdAsync(id)
        ?? throw new NotFoundException("Product", id);

    // Check if resource changed since client last read it
    var currentETag = $"\"{Convert.ToBase64String(product.RowVersion)}\"";
    if (currentETag != ifMatch)
        return StatusCode(412, "Precondition Failed — resource was modified by another request");

    _mapper.Map(dto, product);
    await _db.SaveChangesAsync();  // EF Core also validates RowVersion
    return NoContent();
}
```
