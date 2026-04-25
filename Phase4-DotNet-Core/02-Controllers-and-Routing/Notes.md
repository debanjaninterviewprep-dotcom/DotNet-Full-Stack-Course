# Topic 2: Controllers & Routing

## 📘 What Are Controllers?

Controllers are **classes that handle incoming HTTP requests** and return responses. They are the heart of a Web API — they receive requests, process them (usually by calling services), and return appropriate HTTP responses.

### Controller Basics

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(new[] { "Product1", "Product2" });
    }
}
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `ControllerBase` | Base class for API controllers (no view support) |
| `Controller` | Base class for MVC controllers (includes view support) |
| `[ApiController]` | Enables API-specific behaviors (auto model validation, etc.) |
| `[Route]` | Defines the URL pattern |
| `[HttpGet]`, `[HttpPost]`, etc. | Maps HTTP methods to action methods |

> ⚠️ For Web APIs, always inherit from `ControllerBase`, not `Controller`. The `Controller` class adds view-related features you don't need.

---

## 📘 The [ApiController] Attribute

This attribute enables several **automatic behaviors**:

| Behavior | Description |
|----------|-------------|
| **Attribute Routing Required** | Must use `[Route]` (conventional routing disabled) |
| **Automatic 400 Responses** | Invalid model state auto-returns 400 Bad Request |
| **Binding Source Inference** | Complex types → `[FromBody]`, simple types → `[FromRoute]`/`[FromQuery]` |
| **Problem Details Responses** | Error responses use RFC 7807 Problem Details format |

### Without [ApiController] (Manual Validation)

```csharp
[HttpPost]
public IActionResult Create(Product product)
{
    if (!ModelState.IsValid)  // Must check manually
    {
        return BadRequest(ModelState);
    }
    // ... process
}
```

### With [ApiController] (Automatic Validation)

```csharp
[ApiController]
public class ProductsController : ControllerBase
{
    [HttpPost]
    public IActionResult Create(Product product)
    {
        // ModelState is automatically validated!
        // If invalid, framework returns 400 before this code runs
        // ... process
    }
}
```

---

## 📘 Routing Deep Dive

Routing determines **which controller action handles a given request** based on the URL and HTTP method.

### Route Templates

```csharp
[Route("api/[controller]")]   // [controller] = class name minus "Controller"
public class ProductsController : ControllerBase  // Route: api/products
{
    [HttpGet]                           // GET api/products
    [HttpGet("{id}")]                   // GET api/products/5
    [HttpGet("category/{category}")]    // GET api/products/category/electronics
    [HttpGet("{id}/reviews")]           // GET api/products/5/reviews
}
```

### Token Replacements

| Token | Replaced With | Example |
|-------|--------------|---------|
| `[controller]` | Controller class name (without "Controller" suffix) | `ProductsController` → `products` |
| `[action]` | Action method name | `GetAll` → `getall` |
| `[area]` | Area name | Used in MVC areas |

### Route Parameters

```csharp
// Required parameter
[HttpGet("{id}")]                          // GET api/products/5
public IActionResult GetById(int id) { }

// Optional parameter
[HttpGet("{id?}")]                         // GET api/products OR api/products/5
public IActionResult Get(int? id) { }

// Default value
[HttpGet("{page=1}")]                      // GET api/products → page=1
public IActionResult GetPaged(int page) { }

// Multiple parameters
[HttpGet("{category}/{id}")]               // GET api/products/electronics/5
public IActionResult Get(string category, int id) { }
```

### Route Constraints

Constraints validate route parameters **before** the action is called:

```csharp
// Integer only
[HttpGet("{id:int}")]                      // Matches: /5 | Rejects: /abc

// Minimum value
[HttpGet("{id:int:min(1)}")]               // Matches: /1, /5 | Rejects: /0, /-1

// String length
[HttpGet("{name:minlength(3)}")]           // Matches: /abc | Rejects: /ab

// Regex
[HttpGet("{code:regex(^[A-Z]{{3}}$)}")]    // Matches: /ABC | Rejects: /ab

// GUID
[HttpGet("{id:guid}")]                     // Matches: /a1b2c3d4-...

// Combined constraints
[HttpGet("{id:int:range(1,100)}")]         // Matches: /1 through /100
```

### Complete Constraint Reference

| Constraint | Example | Matches |
|-----------|---------|---------|
| `int` | `{id:int}` | 123, -1 |
| `long` | `{id:long}` | 123456789 |
| `decimal` | `{price:decimal}` | 49.99 |
| `double` | `{lat:double}` | 47.678 |
| `float` | `{lat:float}` | 47.678 |
| `bool` | `{active:bool}` | true, false |
| `guid` | `{id:guid}` | a1b2c3d4-e5f6-... |
| `datetime` | `{date:datetime}` | 2024-01-01 |
| `minlength(n)` | `{name:minlength(3)}` | "abc" (3+ chars) |
| `maxlength(n)` | `{name:maxlength(10)}` | Up to 10 chars |
| `length(n)` | `{code:length(3)}` | Exactly 3 chars |
| `length(m,n)` | `{code:length(3,5)}` | 3 to 5 chars |
| `min(n)` | `{age:min(18)}` | 18 or greater |
| `max(n)` | `{age:max(120)}` | 120 or less |
| `range(m,n)` | `{age:range(18,120)}` | 18 to 120 |
| `alpha` | `{name:alpha}` | Letters only |
| `regex(expr)` | `{code:regex(^[A-Z]+$)}` | Custom regex |
| `required` | `{name:required}` | Must have value |

---

## 📘 Parameter Binding Sources

ASP.NET Core automatically determines **where to get parameter values** from:

### Binding Source Attributes

| Attribute | Source | Example |
|-----------|--------|---------|
| `[FromRoute]` | URL path segments | `/api/products/5` → `id = 5` |
| `[FromQuery]` | Query string | `/api/products?page=2` → `page = 2` |
| `[FromBody]` | Request body (JSON) | `{ "name": "Laptop" }` |
| `[FromHeader]` | Request headers | `X-Request-Id: abc123` |
| `[FromForm]` | Form data | `name=Laptop&price=999` |
| `[FromServices]` | DI container | Injects a service |

### Examples

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    // Route parameter: /api/products/5
    [HttpGet("{id}")]
    public IActionResult GetById([FromRoute] int id) { }

    // Query string: /api/products?category=electronics&page=1&pageSize=10
    [HttpGet]
    public IActionResult Search(
        [FromQuery] string category,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10) { }

    // Request body: POST with JSON body
    [HttpPost]
    public IActionResult Create([FromBody] CreateProductDto product) { }

    // Header: Custom header value
    [HttpGet("with-header")]
    public IActionResult GetWithHeader(
        [FromHeader(Name = "X-Correlation-Id")] string correlationId) { }

    // Mixed sources
    [HttpPut("{id}")]
    public IActionResult Update(
        [FromRoute] int id,
        [FromBody] UpdateProductDto product,
        [FromHeader(Name = "If-Match")] string etag) { }

    // From DI container
    [HttpGet("stats")]
    public IActionResult GetStats([FromServices] IStatisticsService statsService)
    {
        return Ok(statsService.GetStats());
    }
}
```

### Automatic Binding Inference with [ApiController]

When `[ApiController]` is used, you don't need explicit attributes in most cases:

| Parameter Type | Inferred Source |
|---------------|----------------|
| Simple types (int, string) matching route parameter | `[FromRoute]` |
| Simple types not in route | `[FromQuery]` |
| Complex types (classes) | `[FromBody]` |
| `IFormFile` | `[FromForm]` |
| `CancellationToken` | Framework-provided |

---

## 📘 Action Return Types

### IActionResult (Flexible)

```csharp
[HttpGet("{id}")]
public IActionResult GetById(int id)
{
    var product = _repository.GetById(id);
    
    if (product == null)
        return NotFound();              // 404
    
    return Ok(product);                 // 200
}
```

### ActionResult<T> (Typed + Flexible)

```csharp
[HttpGet("{id}")]
public ActionResult<Product> GetById(int id)
{
    var product = _repository.GetById(id);
    
    if (product == null)
        return NotFound();              // 404
    
    return product;                     // 200 (implicit Ok)
}
```

### Common Return Helpers

| Helper Method | Status Code | Use When |
|--------------|------------|----------|
| `Ok(value)` | 200 | Successful GET, PUT, PATCH |
| `Created(uri, value)` | 201 | Successful POST |
| `CreatedAtAction(action, routeValues, value)` | 201 | POST with location header |
| `NoContent()` | 204 | Successful DELETE |
| `BadRequest(errors)` | 400 | Validation errors |
| `Unauthorized()` | 401 | Not authenticated |
| `Forbid()` | 403 | Not authorized |
| `NotFound()` | 404 | Resource doesn't exist |
| `Conflict()` | 409 | Duplicate resource |
| `StatusCode(code)` | Any | Custom status code |

### CreatedAtAction Example

```csharp
[HttpPost]
public ActionResult<Product> Create(CreateProductDto dto)
{
    var product = _service.Create(dto);
    
    // Returns 201 with Location header: /api/products/5
    return CreatedAtAction(
        nameof(GetById),           // Action name for the Location URL
        new { id = product.Id },   // Route values
        product                    // Response body
    );
}
```

---

## 📘 Attribute Routing Patterns

### Controller-Level Route

```csharp
[Route("api/[controller]")]      // Base route for all actions
public class OrdersController : ControllerBase
{
    [HttpGet]                     // GET api/orders
    [HttpGet("{id}")]             // GET api/orders/5
    [HttpPost]                    // POST api/orders
}
```

### Custom Route Names

```csharp
[HttpGet("{id}", Name = "GetProductById")]
public IActionResult GetById(int id) { }

[HttpPost]
public IActionResult Create(Product product)
{
    // Generate URL using the route name
    var url = Url.Link("GetProductById", new { id = product.Id });
    return Created(url, product);
}
```

### Route Prefixes and Combining Routes

```csharp
[Route("api/v1/[controller]")]           // Versioned route
public class ProductsController : ControllerBase
{
    [HttpGet]                             // GET api/v1/products
    [HttpGet("~/api/legacy/items")]       // GET api/legacy/items (~ overrides prefix)
}
```

### Area Routing

```csharp
[Area("Admin")]
[Route("api/[area]/[controller]")]
public class DashboardController : ControllerBase
{
    [HttpGet]                             // GET api/admin/dashboard
    public IActionResult GetStats() { }
}
```

---

## 📘 Query String Parameters & Filtering

```csharp
[HttpGet]
public IActionResult Search(
    [FromQuery] string? search,
    [FromQuery] string? category,
    [FromQuery] string? sortBy = "name",
    [FromQuery] string? sortOrder = "asc",
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 10)
{
    // URL: /api/products?search=laptop&category=electronics&sortBy=price&page=2
    
    var query = _repository.GetAll();
    
    if (!string.IsNullOrEmpty(search))
        query = query.Where(p => p.Name.Contains(search));
    
    if (!string.IsNullOrEmpty(category))
        query = query.Where(p => p.Category == category);
    
    query = sortOrder == "desc" 
        ? query.OrderByDescending(p => GetSortProperty(p, sortBy))
        : query.OrderBy(p => GetSortProperty(p, sortBy));
    
    var paged = query.Skip((page - 1) * pageSize).Take(pageSize);
    
    return Ok(new
    {
        Data = paged,
        Page = page,
        PageSize = pageSize,
        TotalCount = query.Count()
    });
}
```

---

## 📘 Returning Different Response Types

### Producing Specific Content Types

```csharp
[HttpGet("{id}")]
[Produces("application/json")]           // Only JSON
[ProducesResponseType(typeof(Product), StatusCodes.Status200OK)]
[ProducesResponseType(StatusCodes.Status404NotFound)]
public ActionResult<Product> GetById(int id)
{
    var product = _repository.GetById(id);
    if (product == null) return NotFound();
    return product;
}
```

### Content Negotiation

ASP.NET Core supports content negotiation — the client specifies what format it wants via the `Accept` header:

```
GET /api/products
Accept: application/json    → Returns JSON
Accept: application/xml     → Returns XML (if configured)
```

```csharp
// Enable XML output
builder.Services.AddControllers()
    .AddXmlSerializerFormatters();       // Adds XML support
```

---

## 📘 Async Controller Actions

**Always use async/await** for I/O operations (database, HTTP calls, file access):

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    // ✅ Async — doesn't block threads while waiting for DB
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetAll()
    {
        var products = await _productService.GetAllAsync();
        return Ok(products);
    }

    // ✅ Async with CancellationToken
    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetById(
        int id, 
        CancellationToken cancellationToken)
    {
        var product = await _productService.GetByIdAsync(id, cancellationToken);
        if (product == null) return NotFound();
        return product;
    }

    // ❌ Bad — blocks a thread while waiting for DB
    [HttpGet("bad")]
    public IActionResult GetAllBad()
    {
        var products = _productService.GetAllAsync().Result;  // DON'T DO THIS
        return Ok(products);
    }
}
```

### CancellationToken

Used to cancel long-running requests when the **client disconnects**:

```csharp
[HttpGet("report")]
public async Task<IActionResult> GenerateReport(CancellationToken cancellationToken)
{
    // If client disconnects, cancellationToken is triggered
    var data = await _service.GenerateExpensiveReportAsync(cancellationToken);
    return Ok(data);
}
```

---

## 📘 Controller Dependency Injection

```csharp
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly ILogger<OrdersController> _logger;
    private readonly IConfiguration _config;

    // Constructor injection — preferred method
    public OrdersController(
        IOrderService orderService,
        ILogger<OrdersController> logger,
        IConfiguration config)
    {
        _orderService = orderService;
        _logger = logger;
        _config = config;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        _logger.LogInformation("Getting all orders");
        var orders = await _orderService.GetAllAsync();
        return Ok(orders);
    }

    // Method-level injection with [FromServices]
    [HttpGet("stats")]
    public IActionResult GetStats([FromServices] IStatisticsService statsService)
    {
        return Ok(statsService.GetOrderStats());
    }
}
```

---

## 📘 Organizing Controllers — Best Practices

### One Controller Per Resource

```
Controllers/
├── ProductsController.cs       // /api/products
├── OrdersController.cs         // /api/orders
├── UsersController.cs          // /api/users
├── CategoriesController.cs     // /api/categories
└── AuthController.cs           // /api/auth
```

### Complete CRUD Controller Template

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _service;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(IProductService service, ILogger<ProductsController> logger)
    {
        _service = service;
        _logger = logger;
    }

    // GET api/products
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var products = await _service.GetAllAsync(page, pageSize);
        return Ok(products);
    }

    // GET api/products/5
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDto>> GetById(int id)
    {
        var product = await _service.GetByIdAsync(id);
        if (product == null)
        {
            _logger.LogWarning("Product {Id} not found", id);
            return NotFound();
        }
        return Ok(product);
    }

    // POST api/products
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ProductDto>> Create(CreateProductDto dto)
    {
        var product = await _service.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
    }

    // PUT api/products/5
    [HttpPut("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDto>> Update(int id, UpdateProductDto dto)
    {
        var product = await _service.UpdateAsync(id, dto);
        if (product == null) return NotFound();
        return Ok(product);
    }

    // DELETE api/products/5
    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _service.DeleteAsync(id);
        if (!deleted) return NotFound();
        return NoContent();
    }
}
```

---

## 📘 API Versioning

### URL-Based Versioning

```csharp
[Route("api/v1/products")]
public class ProductsV1Controller : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll() => Ok(new { version = "1.0", products = new[] { "basic" } });
}

[Route("api/v2/products")]
public class ProductsV2Controller : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll() => Ok(new { version = "2.0", products = new[] { "enhanced" } });
}
```

### Header-Based Versioning (using Asp.Versioning package)

```csharp
// Install: dotnet add package Asp.Versioning.Mvc
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
    options.ApiVersionReader = new HeaderApiVersionReader("X-Api-Version");
});
```

---

## 📘 Model Validation

### Data Annotations

```csharp
public class CreateProductDto
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be 2-100 characters")]
    public string Name { get; set; }

    [Required]
    [Range(0.01, 99999.99, ErrorMessage = "Price must be between $0.01 and $99,999.99")]
    public decimal Price { get; set; }

    [StringLength(50)]
    public string? Category { get; set; }

    [Url(ErrorMessage = "Must be a valid URL")]
    public string? ImageUrl { get; set; }

    [EmailAddress]
    public string? SupplierEmail { get; set; }
}
```

### Common Validation Attributes

| Attribute | Purpose |
|-----------|---------|
| `[Required]` | Field must have a value |
| `[StringLength(max)]` | Maximum string length |
| `[Range(min, max)]` | Numeric range |
| `[EmailAddress]` | Valid email format |
| `[Phone]` | Valid phone format |
| `[Url]` | Valid URL format |
| `[RegularExpression(pattern)]` | Custom regex validation |
| `[Compare("OtherProperty")]` | Must match another property |
| `[MinLength(n)]` / `[MaxLength(n)]` | Collection/string length |
| `[CreditCard]` | Valid credit card format |

> With `[ApiController]`, validation errors automatically return 400 Bad Request before your action code runs.

---

## 📘 Putting It All Together — TaskFlow API Controllers

```csharp
[ApiController]
[Route("api/[controller]")]
public class TasksController : ControllerBase
{
    private readonly ITaskService _taskService;
    private readonly ILogger<TasksController> _logger;

    public TasksController(ITaskService taskService, ILogger<TasksController> logger)
    {
        _taskService = taskService;
        _logger = logger;
    }

    /// <summary>
    /// Get all tasks with optional filtering
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PagedResult<TaskDto>>> GetAll(
        [FromQuery] string? status,
        [FromQuery] string? priority,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        _logger.LogInformation("Getting tasks: status={Status}, page={Page}", status, page);
        var result = await _taskService.GetAllAsync(status, priority, search, page, pageSize);
        return Ok(result);
    }

    /// <summary>
    /// Get a specific task by ID
    /// </summary>
    [HttpGet("{id:int}")]
    public async Task<ActionResult<TaskDto>> GetById(int id)
    {
        var task = await _taskService.GetByIdAsync(id);
        if (task == null)
            return NotFound(new { message = $"Task with ID {id} not found" });
        return Ok(task);
    }

    /// <summary>
    /// Create a new task
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<TaskDto>> Create(CreateTaskDto dto)
    {
        var task = await _taskService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = task.Id }, task);
    }

    /// <summary>
    /// Update task status
    /// </summary>
    [HttpPatch("{id:int}/status")]
    public async Task<ActionResult<TaskDto>> UpdateStatus(int id, UpdateTaskStatusDto dto)
    {
        var task = await _taskService.UpdateStatusAsync(id, dto);
        if (task == null) return NotFound();
        return Ok(task);
    }
}
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| Controllers | Classes inheriting `ControllerBase` that handle HTTP requests |
| `[ApiController]` | Enables auto-validation, binding inference, problem details |
| Route Templates | `[Route("api/[controller]")]` with `{id}` parameters |
| Route Constraints | `{id:int:min(1)}` validates parameters before action executes |
| Parameter Binding | `[FromRoute]`, `[FromQuery]`, `[FromBody]`, `[FromHeader]` |
| Action Results | `Ok()`, `NotFound()`, `CreatedAtAction()`, `BadRequest()` |
| Async Actions | Always use `async Task<ActionResult<T>>` for I/O operations |
| Model Validation | Data annotations + `[ApiController]` = automatic 400 responses |
| CancellationToken | Pass to async methods to handle client disconnects |

> **Next Topic**: Models, DTOs & AutoMapper — Separating your API contracts from your domain models.
