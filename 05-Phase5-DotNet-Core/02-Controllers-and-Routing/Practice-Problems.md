# Practice Problems: Controllers & Routing

---

## Problem 1: Route Matching Engine ⭐ Easy

**Objective**: Build a console app that simulates ASP.NET Core's route matching with support for route templates, parameters, and constraints.

### Requirements:
1. Create a `RouteTemplate` class that parses route patterns like `api/products/{id:int}`
2. Create a `Router` class that:
   - Registers routes with HTTP methods: `Register("GET", "api/products/{id:int}", handlerName)`
   - Matches incoming requests: `Match("GET", "api/products/5")` → returns handler + extracted parameters
3. Support these constraint types: `int`, `guid`, `minlength(n)`, `alpha`
4. Handle route conflicts (same pattern, same method)
5. Test with at least 10 different request URLs

### Expected Output:
```
=== Route Matching Engine ===

Registered Routes:
  GET    api/products
  GET    api/products/{id:int}
  GET    api/products/{id:int}/reviews
  POST   api/products
  GET    api/users/{username:alpha:minlength(3)}
  GET    api/orders/{id:guid}

--- Matching Requests ---
GET  api/products         → ✓ Matched: GetAllProducts | Params: {}
GET  api/products/42      → ✓ Matched: GetProductById | Params: { id: 42 }
GET  api/products/abc     → ✗ No Match (constraint failed: 'abc' is not int)
GET  api/products/42/reviews → ✓ Matched: GetProductReviews | Params: { id: 42 }
POST api/products         → ✓ Matched: CreateProduct | Params: {}
GET  api/users/john       → ✓ Matched: GetUser | Params: { username: "john" }
GET  api/users/ab         → ✗ No Match (constraint failed: minlength(3))
GET  api/unknown          → ✗ No Match (404)
```

### Hints:
- Split route templates by `/` and compare segment by segment
- Use regex to parse `{paramName:constraint}` syntax
- Store routes in a list of `(HttpMethod, RouteTemplate, HandlerName)` tuples

---

## Problem 2: Parameter Binding Simulator ⭐⭐ Easy-Medium

**Objective**: Build a console app that simulates how ASP.NET Core binds parameters from different sources (route, query, body, header).

### Requirements:
1. Create an `HttpRequest` class with: Method, Path, QueryString (Dictionary), Headers (Dictionary), Body (string/JSON)
2. Create a `ParameterBinder` that resolves parameter values based on binding source:
   - `[FromRoute]` — extracts from URL path
   - `[FromQuery]` — extracts from query string
   - `[FromBody]` — deserializes from JSON body
   - `[FromHeader]` — extracts from headers
3. Create simulated action method definitions with parameter attributes
4. For each request, show which parameters were bound from which source
5. Show automatic binding inference (complex types → body, simple in route → route, else query)

### Expected Output:
```
=== Parameter Binding Simulator ===

--- Action: PUT /api/products/{id} ---
Parameters:
  [FromRoute] int id
  [FromBody]  UpdateProductDto product
  [FromHeader] string If-Match

Request: PUT /api/products/5
  Query: (none)
  Headers: { If-Match: "etag-123", Content-Type: "application/json" }
  Body: { "name": "Updated Laptop", "price": 1299.99 }

Binding Results:
  ✓ id = 5                          (from route segment 3)
  ✓ product = { Name: "Updated Laptop", Price: 1299.99 }  (from body JSON)
  ✓ If-Match = "etag-123"           (from header)

--- Action: GET /api/products ---
Parameters:
  [FromQuery] string? search        (auto-inferred: simple type, not in route)
  [FromQuery] int page = 1
  [FromQuery] int pageSize = 10

Request: GET /api/products?search=laptop&page=2
Binding Results:
  ✓ search = "laptop"               (from query)
  ✓ page = 2                        (from query)
  ✓ pageSize = 10                   (default value, not in query)
```

### Hints:
- Use `System.Text.Json` to deserialize body JSON
- Parse query strings by splitting on `&` and `=`
- Create an attribute simulation using enums: `BindingSource.Route`, `.Query`, `.Body`, `.Header`

---

## Problem 3: Full CRUD Controller Simulator ⭐⭐ Medium

**Objective**: Build a console app that simulates a complete CRUD API controller with proper status codes, validation, and response formatting.

### Requirements:
1. Create a `TaskItem` model: Id, Title (required, 3-100 chars), Description, Priority (Low/Medium/High), Status (Todo/InProgress/Done), CreatedDate
2. Implement all CRUD operations with validation:
   - `GET /api/tasks` — list all with filtering by status and priority, pagination
   - `GET /api/tasks/{id}` — get by ID → 200 or 404
   - `POST /api/tasks` — create → 201 with Location or 400
   - `PUT /api/tasks/{id}` — full update → 200 or 404 or 400
   - `PATCH /api/tasks/{id}/status` — update status only → 200 or 404
   - `DELETE /api/tasks/{id}` — delete → 204 or 404
3. Implement model validation with proper error messages
4. Return `ProblemDetails`-formatted error responses (RFC 7807)
5. Show pagination metadata in responses

### Expected Output:
```
=== CRUD Controller Simulator ===

▶ POST /api/tasks
  Body: { "title": "Learn ASP.NET Core", "priority": "High" }
◀ 201 Created
  Location: /api/tasks/1
  Body: { "id": 1, "title": "Learn ASP.NET Core", "priority": "High", "status": "Todo", "createdDate": "2026-04-25T10:00:00" }

▶ POST /api/tasks
  Body: { "title": "ab" }
◀ 400 Bad Request
  Body: {
    "type": "https://tools.ietf.org/html/rfc7807",
    "title": "Validation Error",
    "status": 400,
    "errors": {
      "Title": ["Title must be between 3 and 100 characters"],
      "Priority": ["Priority is required"]
    }
  }

▶ GET /api/tasks?status=Todo&page=1&pageSize=2
◀ 200 OK
  Body: {
    "data": [...],
    "page": 1,
    "pageSize": 2,
    "totalCount": 5,
    "totalPages": 3
  }

▶ PATCH /api/tasks/1/status
  Body: { "status": "InProgress" }
◀ 200 OK

▶ DELETE /api/tasks/1
◀ 204 No Content

▶ DELETE /api/tasks/1
◀ 404 Not Found
  Body: { "type": "...", "title": "Not Found", "status": 404, "detail": "Task with ID 1 not found" }
```

---

## Problem 4: API Versioning & Content Negotiation Engine ⭐⭐ Medium-Hard

**Objective**: Build a console app that demonstrates API versioning strategies and content negotiation (JSON vs XML output).

### Requirements:
1. Implement three versioning strategies:
   - **URL versioning**: `/api/v1/products` vs `/api/v2/products`
   - **Query string versioning**: `/api/products?api-version=1.0`
   - **Header versioning**: `X-Api-Version: 2.0`
2. Create V1 and V2 product responses:
   - V1: `{ id, name, price }`
   - V2: `{ id, name, price, category, rating, reviews_count }`
3. Implement content negotiation:
   - `Accept: application/json` → JSON output
   - `Accept: application/xml` → XML output
   - `Accept: text/plain` → Simple text output
   - No Accept header → default JSON
4. Show how each versioning strategy resolves the version from the request

### Expected Output:
```
=== API Versioning & Content Negotiation ===

--- URL Versioning ---
GET /api/v1/products/1
  Resolved Version: 1.0
  Response (JSON): { "id": 1, "name": "Laptop", "price": 999.99 }

GET /api/v2/products/1
  Resolved Version: 2.0
  Response (JSON): { "id": 1, "name": "Laptop", "price": 999.99, "category": "Electronics", "rating": 4.5, "reviewsCount": 128 }

--- Header Versioning ---
GET /api/products/1
  Header: X-Api-Version: 1.0
  Response (JSON): { "id": 1, "name": "Laptop", "price": 999.99 }

--- Content Negotiation ---
GET /api/v2/products/1
  Accept: application/xml
  Response:
    <Product>
      <Id>1</Id>
      <Name>Laptop</Name>
      <Price>999.99</Price>
      <Category>Electronics</Category>
    </Product>

GET /api/v2/products/1
  Accept: text/plain
  Response: Product: Laptop | Price: $999.99 | Category: Electronics
```

---

## Problem 5: Complete Request Processing Pipeline ⭐⭐⭐ Hard

**Objective**: Build a console app that simulates the complete ASP.NET Core request processing pipeline from HTTP request to controller action to response.

### Requirements:
1. **Request Parsing**: Parse raw HTTP request strings into structured `HttpRequest` objects
2. **Router**: Match requests to controller actions (support route parameters + constraints)
3. **Model Binding**: Bind parameters from route, query, body, and headers
4. **Model Validation**: Validate bound models using attribute rules
5. **Action Execution**: Execute the matched action with bound parameters
6. **Result Processing**: Convert action results to HTTP response strings
7. **Full Pipeline**: Wire everything together and process 8+ requests

### Raw Request Input Format:
```
POST /api/products HTTP/1.1
Content-Type: application/json
Authorization: Bearer token123

{ "name": "Laptop", "price": 999.99, "category": "Electronics" }
```

### Expected Output:
```
=== Complete Request Processing Pipeline ===

━━━ Request 1 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Raw:
  POST /api/products HTTP/1.1
  Content-Type: application/json
  Authorization: Bearer token123
  
  { "name": "Laptop", "price": 999.99, "category": "Electronics" }

[Parse] Method=POST, Path=/api/products, Headers=2, Body=yes
[Route] Matched: ProductsController.Create
[Bind]  product ← Body: { name: "Laptop", price: 999.99, category: "Electronics" }
[Validate] ✓ Model is valid
[Execute] ProductsController.Create(product)
[Result] 201 Created

HTTP/1.1 201 Created
Location: /api/products/1
Content-Type: application/json

{ "id": 1, "name": "Laptop", "price": 999.99, "category": "Electronics" }

━━━ Request 2 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Raw:
  GET /api/products?category=Electronics&page=1 HTTP/1.1

[Parse] Method=GET, Path=/api/products, Query={category:Electronics, page:1}
[Route] Matched: ProductsController.GetAll
[Bind]  category ← Query: "Electronics"
[Bind]  page ← Query: 1
[Bind]  pageSize ← Default: 10
[Execute] ProductsController.GetAll("Electronics", 1, 10)
[Result] 200 OK

HTTP/1.1 200 OK
Content-Type: application/json

{ "data": [...], "page": 1, "totalCount": 1 }

━━━ Request 3 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Raw:
  POST /api/products HTTP/1.1
  Content-Type: application/json
  
  { "name": "", "price": -5 }

[Parse] Method=POST, Path=/api/products
[Route] Matched: ProductsController.Create
[Bind]  product ← Body
[Validate] ✗ Validation failed:
  - Name: "Name is required"
  - Price: "Price must be greater than 0"
[Result] 400 Bad Request (short-circuit, action NOT executed)

HTTP/1.1 400 Bad Request
Content-Type: application/json

{ "type": "validation", "title": "Validation Error", "errors": { "Name": [...], "Price": [...] } }
```

### Hints:
- Parse raw HTTP by splitting on `\n` (first line = request line, then headers, blank line, then body)
- Create a `ControllerActionDescriptor` that stores route, method, parameters, and validation rules
- The pipeline should be: Parse → Route → Bind → Validate → Execute → Format Response
- If validation fails, skip execution (simulating [ApiController] automatic 400)
- Use string formatting to produce readable HTTP responses
