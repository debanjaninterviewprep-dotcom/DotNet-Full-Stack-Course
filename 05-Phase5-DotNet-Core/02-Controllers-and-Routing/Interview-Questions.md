# Topic 02: Controllers and Routing — Interview Questions

---

## Q1. What is a controller in ASP.NET Core Web API?
**Answer:**
A controller is a class that handles HTTP requests and returns HTTP responses. It derives from `ControllerBase` (for APIs) or `Controller` (for MVC with views):

```csharp
[ApiController]           // enables automatic model validation, binding inference
[Route("api/[controller]")] // route template: api/users
public class UsersController : ControllerBase
{
    private readonly IUserService _svc;

    public UsersController(IUserService svc) => _svc = svc;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetAll()
        => Ok(await _svc.GetAllAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id) {
        var user = await _svc.GetByIdAsync(id);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<UserDto>> Create(CreateUserDto dto) {
        var user = await _svc.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { user.Id }, user);
    }
}
```

---

## Q2. What does the `[ApiController]` attribute do?
**Answer:**
`[ApiController]` enables several convenience behaviours:

1. **Automatic model validation** — returns 400 Bad Request with validation errors automatically (no need for `if (!ModelState.IsValid)` check).
2. **Binding source inference** — `[FromBody]` inferred for complex types, `[FromRoute]` for route params.
3. **Problem Details responses** — automatic ProblemDetails format for 400/500 responses.
4. **Multipart/form-data inference** — `IFormFile` automatically bound from form data.

```csharp
// Without [ApiController]
public IActionResult Create([FromBody] CreateDto dto) {
    if (!ModelState.IsValid) return BadRequest(ModelState); // must do manually
}

// With [ApiController] — automatic
public IActionResult Create(CreateDto dto) {
    // ModelState.IsValid is checked automatically; returns 400 if invalid
    // dto is automatically bound from body
}
```

---

## Q3. What are the common `IActionResult` return types?
**Answer:**
```csharp
// Success
Ok(data)              // 200 OK with body
Created(uri, data)    // 201 Created
CreatedAtAction(nameof(GetById), new { id }, data) // 201 with Location header
NoContent()           // 204 No Content (PUT/DELETE success)
Accepted()            // 202 Accepted (async processing)

// Client errors
BadRequest(modelState)    // 400 Bad Request
BadRequest("Invalid input") // 400 with message
NotFound()                // 404 Not Found
NotFound("User not found") // 404 with message
Conflict()                // 409 Conflict
UnprocessableEntity()     // 422 Validation failure
Unauthorized()            // 401
Forbid()                  // 403

// Redirects
Redirect("https://other.com")   // 302
RedirectToAction("Index")       // redirect within app

// Other
StatusCode(503)          // custom status code
Problem("Error occurred") // RFC 7807 Problem Details
File(bytes, "application/pdf") // file download
```

---

## Q4. What is attribute routing and how does it work?
**Answer:**
Attribute routing places route templates directly on controllers and actions:

```csharp
// Route tokens: [controller], [action], [area]
[Route("api/v{version:apiVersion}/[controller]")]
public class ProductsController : ControllerBase
{
    [HttpGet]                          // GET /api/v1/products
    [HttpGet("list")]                  // GET /api/v1/products/list (additional route)
    public IActionResult GetAll() => Ok();

    [HttpGet("{id:int}")]              // GET /api/v1/products/42
    [HttpGet("{id:int}/details")]      // GET /api/v1/products/42/details
    public IActionResult GetById(int id) => Ok();

    [HttpGet("by-slug/{slug}")]        // GET /api/v1/products/by-slug/iphone-15
    public IActionResult GetBySlug(string slug) => Ok();

    [HttpPost]                         // POST /api/v1/products
    [HttpPut("{id:int}")]              // PUT /api/v1/products/42
    [HttpPatch("{id:int}")]            // PATCH /api/v1/products/42
    [HttpDelete("{id:int}")]           // DELETE /api/v1/products/42
}
```

---

## Q5. What are route constraints and how are they used?
**Answer:**
Route constraints validate and filter route values:

```csharp
// Type constraints
[HttpGet("{id:int}")]           // int only — e.g., /users/42
[HttpGet("{id:guid}")]          // GUID format
[HttpGet("{id:long}")]          // long
[HttpGet("{name:alpha}")]       // letters only

// Value constraints
[HttpGet("{age:int:min(1):max(120)}")]  // 1-120
[HttpGet("{id:int:range(1,1000)}")]     // range
[HttpGet("{code:length(5)}")]           // exact length
[HttpGet("{code:minlength(3):maxlength(10)}")]

// Optional and defaults
[HttpGet("{id:int?}")]          // optional
[HttpGet("{page:int=1}")]       // default value

// Regex constraint
[HttpGet("{slug:regex(^[a-z0-9-]+$)}")]
```

---

## Q6. What is model binding in ASP.NET Core?
**Answer:**
Model binding automatically maps HTTP request data to action parameters:

```csharp
// [FromRoute] — from route template
[HttpGet("{id}")]
public IActionResult Get([FromRoute] int id) => Ok();

// [FromQuery] — from query string: /users?page=2&size=10
public IActionResult List([FromQuery] int page, [FromQuery] int size) => Ok();

// [FromBody] — from request body (JSON/XML)
[HttpPost]
public IActionResult Create([FromBody] CreateUserDto dto) => Ok();

// [FromHeader] — from HTTP headers
public IActionResult Action([FromHeader(Name = "X-Correlation-Id")] string correlationId) => Ok();

// [FromForm] — from form data
public IActionResult Upload([FromForm] IFormFile file, [FromForm] string description) => Ok();

// [FromServices] — inject from DI (rarely needed; prefer constructor)
public IActionResult Work([FromServices] IEmailSender sender) => Ok();

// Complex query model
public IActionResult Search([FromQuery] UserSearchParams @params) => Ok();
// Binds all public properties of UserSearchParams from query string
```

---

## Q7. What is the difference between `CreatedAtAction` and `CreatedAtRoute`?
**Answer:**
Both return HTTP 201 with a `Location` header pointing to the created resource:

```csharp
// CreatedAtAction — reference by action method name (within same controller)
return CreatedAtAction(
    actionName: nameof(GetById),
    routeValues: new { id = user.Id },
    value: user
);
// Location: https://api.example.com/api/users/42

// CreatedAtRoute — reference by named route
// Named route setup:
[HttpGet("{id}", Name = "GetUser")]
public IActionResult GetById(int id) => Ok();

// Usage:
return CreatedAtRoute("GetUser", new { id = user.Id }, user);
```

---

## Q8. How do you implement API versioning?
**Answer:**
```csharp
// Install: Microsoft.AspNetCore.Mvc.Versioning
builder.Services.AddApiVersioning(opt => {
    opt.DefaultApiVersion = new ApiVersion(1, 0);
    opt.AssumeDefaultVersionWhenUnspecified = true;
    opt.ReportApiVersions = true; // Adds api-supported-versions header
    opt.ApiVersionReader = ApiVersionReader.Combine(
        new QueryStringApiVersionReader("v"),      // ?v=2
        new HeaderApiVersionReader("X-Version"),   // header
        new UrlSegmentApiVersionReader()            // /api/v2/users
    );
});

// URL segment versioning
[Route("api/v{version:apiVersion}/users")]
[ApiVersion("1.0")]
[ApiVersion("2.0")]
public class UsersController : ControllerBase
{
    [HttpGet, MapToApiVersion("1.0")]
    public IActionResult GetV1() => Ok("v1 response");

    [HttpGet, MapToApiVersion("2.0")]
    public IActionResult GetV2() => Ok("v2 response");
}
```

---

## Q9. What is content negotiation in ASP.NET Core?
**Answer:**
Content negotiation allows the client to specify the desired response format via the `Accept` header:

```csharp
// Enable XML support alongside JSON
builder.Services.AddControllers()
    .AddXmlSerializerFormatters();  // adds XML input/output formatters

// Client sends: Accept: application/xml → returns XML
// Client sends: Accept: application/json → returns JSON (default)

// Force a specific format on an action
[Produces("application/json")]
public IActionResult GetJson() => Ok(data);

// Disable content negotiation (always return JSON)
builder.Services.AddControllers(opt => {
    opt.RespectBrowserAcceptHeader = false; // ignore browser's */html preference
    opt.ReturnHttpNotAcceptable = true;     // return 406 if format not supported
});
```

---

## Q10. What are action filters and how are they different from middleware?
**Answer:**
| | Middleware | Action Filters |
|---|---|---|
| **Scope** | Entire pipeline | Controller/Action only |
| **Knowledge of** | HTTP context | MVC context (controller, action, params) |
| **Access to** | Request/Response | ActionContext, ActionArguments, Result |
| **Order** | Pipeline order | Filter pipeline order |

```csharp
// Action filter
public class ValidateModelAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
            context.Result = new BadRequestObjectResult(context.ModelState);
    }
}

// Apply globally
builder.Services.AddControllers(opt =>
    opt.Filters.Add<ValidateModelAttribute>());

// Apply to controller
[ValidateModel]
public class UsersController : ControllerBase { }

// Apply to action
[HttpPost, ValidateModel]
public IActionResult Create(CreateDto dto) { }
```

---

## Q11. What are the HTTP verbs and their intended semantics?
**Answer:**
| Method | Idempotent | Safe | Typical use |
|---|---|---|---|
| `GET` | ✓ | ✓ | Read resource(s) |
| `POST` | ✗ | ✗ | Create resource / submit data |
| `PUT` | ✓ | ✗ | Full update / replace resource |
| `PATCH` | ✗ | ✗ | Partial update |
| `DELETE` | ✓ | ✗ | Delete resource |
| `HEAD` | ✓ | ✓ | GET without body (check existence) |
| `OPTIONS` | ✓ | ✓ | Get supported methods (CORS preflight) |

- **Safe** — doesn't change server state.
- **Idempotent** — calling it multiple times has the same result as calling it once.

---

## Q12. What is the difference between `PUT` and `PATCH`?
**Answer:**
```csharp
// PUT — full replacement (send the entire resource)
[HttpPut("{id}")]
public async Task<IActionResult> Update(int id, UpdateUserDto dto) {
    // dto must contain ALL fields; missing fields are set to defaults
    await _svc.ReplaceAsync(id, dto);
    return NoContent();
}

// PATCH — partial update (send only changed fields)
[HttpPatch("{id}")]
public async Task<IActionResult> PartialUpdate(int id, JsonPatchDocument<UserDto> patchDoc) {
    var user = await _repo.GetByIdAsync(id);
    if (user is null) return NotFound();
    patchDoc.ApplyTo(user, ModelState); // applies only specified operations
    if (!ModelState.IsValid) return BadRequest(ModelState);
    await _repo.UpdateAsync(user);
    return NoContent();
}

// PATCH body using RFC 6902 JSON Patch:
// [{ "op": "replace", "path": "/name", "value": "Alice" }]
```

---

## Q13. What are Problem Details and how do they improve API error responses?
**Answer:**
Problem Details (RFC 7807) is a standard format for API error responses:

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "traceId": "00-abc123-def456-00",
  "errors": {
    "Name": ["The Name field is required."],
    "Email": ["Invalid email format."]
  }
}
```

```csharp
// Enable Problem Details (default with [ApiController], configure globally)
builder.Services.AddProblemDetails();

// Custom problem details for exceptions
app.UseExceptionHandler(opt => {
    opt.Run(async ctx => {
        ctx.Response.ContentType = "application/problem+json";
        var problem = new ProblemDetails {
            Status = 500, Title = "An error occurred",
            Detail = ctx.Features.Get<IExceptionHandlerFeature>()?.Error.Message
        };
        await ctx.Response.WriteAsJsonAsync(problem);
    });
});

// Return Problem from action
return Problem(detail: "User not found", statusCode: 404, title: "Not Found");
```

---

## Q14. How do you return paginated results?
**Answer:**
```csharp
// Pagination response envelope
public class PagedResult<T>
{
    public IEnumerable<T> Data { get; init; } = [];
    public int TotalCount { get; init; }
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
    public bool HasNextPage => Page < TotalPages;
    public bool HasPrevPage => Page > 1;
}

// Controller
[HttpGet]
public async Task<ActionResult<PagedResult<UserDto>>> GetAll(
    [FromQuery] int page = 1,
    [FromQuery] int pageSize = 20,
    [FromQuery] string? search = null,
    [FromQuery] string sortBy = "id")
{
    var result = await _svc.GetPagedAsync(page, pageSize, search, sortBy);
    return Ok(result);
}

// Service
var query = _db.Users.AsQueryable();
if (search is not null) query = query.Where(u => u.Name.Contains(search));
int total = await query.CountAsync();
var data = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
return new PagedResult<User> { Data = data, TotalCount = total, Page = page, PageSize = pageSize };
```

---

## Q15. What is `ActionResult<T>` vs `IActionResult`?
**Answer:**
```csharp
// IActionResult — untyped; flexible but no return type info in OpenAPI/Swagger
[HttpGet("{id}")]
public async Task<IActionResult> GetById(int id) {
    var user = await _svc.GetByIdAsync(id);
    return user is null ? NotFound() : Ok(user); // Ok(user) returns UserDto implicitly
}

// ActionResult<T> — typed; enables Swagger to know the success response type
[HttpGet("{id}")]
public async Task<ActionResult<UserDto>> GetById(int id) {
    var user = await _svc.GetByIdAsync(id);
    return user is null ? NotFound() : user; // implicit conversion from T to ActionResult<T>
}

// T directly — simplest when never returning non-200
[HttpGet]
public async Task<IEnumerable<UserDto>> GetAll()
    => await _svc.GetAllAsync();
```

`ActionResult<T>` is preferred for API controllers — it provides better Swagger documentation and type safety.
