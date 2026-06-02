# Practice Problems: Models, DTOs & AutoMapper

---

## Problem 1: Entity-to-DTO Mapper ⭐ Easy

**Objective**: Build a console app that demonstrates entity-to-DTO mapping using manual extension methods for a multi-entity system.

### Requirements:
1. Create entity classes: `Employee` (Id, FirstName, LastName, Email, Salary, DepartmentId, HireDate, PasswordHash) and `Department` (Id, Name, Budget)
2. Create DTOs: `EmployeeDto` (Id, FullName, Email, DepartmentName), `EmployeeDetailDto` (all safe fields), `CreateEmployeeDto` (with validation attributes)
3. Write manual mapping extension methods for all conversions
4. Demonstrate mapping a list of employees with their departments
5. Show that sensitive fields (PasswordHash, Salary) are NOT in the basic DTO

### Expected Output:
```
=== Entity-to-DTO Mapping ===

Entities (what's in the database):
  Employee { Id: 1, FirstName: "John", LastName: "Doe", Email: "john@co.com", Salary: 85000, PasswordHash: "$2a$10$xyz...", DepartmentId: 1 }

Basic DTO (what the API returns):
  EmployeeDto { Id: 1, FullName: "John Doe", Email: "john@co.com", DepartmentName: "Engineering" }
  ✗ Salary: HIDDEN
  ✗ PasswordHash: HIDDEN

Detail DTO:
  EmployeeDetailDto { Id: 1, FullName: "John Doe", Email: "john@co.com", DepartmentName: "Engineering", HireDate: "2023-01-15", YearsEmployed: 3 }

List mapping (5 employees → 5 DTOs):
  [1] John Doe - Engineering
  [2] Jane Smith - Marketing
  ...
```

---

## Problem 2: AutoMapper Simulator ⭐⭐ Easy-Medium

**Objective**: Build a console app that simulates AutoMapper's core functionality using reflection — convention-based property name matching.

### Requirements:
1. Create a `SimpleMapper` class that:
   - `CreateMap<TSource, TDestination>()` registers a mapping
   - `Map<TDestination>(source)` maps an object using matching property names
   - Automatically matches properties with the same name and compatible types
2. Support these AutoMapper features:
   - **Name matching**: `Name` → `Name` (exact match)
   - **Flattening**: `Customer.Name` → `CustomerName`
   - **Type conversion**: `int` → `string`, `DateTime` → `string`
3. Log which properties were mapped and which were skipped
4. Test with at least 3 different mapping scenarios

### Expected Output:
```
=== AutoMapper Simulator ===

--- Map: Product → ProductDto ---
  ✓ Id (int → int): 1
  ✓ Name (string → string): "Laptop"
  ✓ Price (decimal → decimal): 999.99
  ✗ PasswordHash: No matching property in destination (skipped)
  ✗ InternalNotes: No matching property in destination (skipped)
Result: ProductDto { Id: 1, Name: "Laptop", Price: 999.99 }

--- Map: Order → OrderDto (with Flattening) ---
  ✓ Id (int → int): 1
  ✓ Customer.Name → CustomerName (flattened): "John Doe"
  ✓ Customer.Email → CustomerEmail (flattened): "john@co.com"
  ✓ TotalAmount (decimal → decimal): 150.00
Result: OrderDto { Id: 1, CustomerName: "John Doe", CustomerEmail: "john@co.com", TotalAmount: 150.00 }
```

### Hints:
- Use `typeof(T).GetProperties()` for reflection
- For flattening, check if destination property name is a concatenation of source navigation property + its property name

---

## Problem 3: Validation Framework ⭐⭐ Medium

**Objective**: Build a console app that implements a validation system similar to Data Annotations + FluentValidation.

### Requirements:
1. Implement an attribute-based validator supporting:
   - `[Required]`, `[StringLength(min, max)]`, `[Range(min, max)]`, `[EmailAddress]`, `[RegularExpression]`
2. Implement a `FluentValidator<T>` class with:
   - `RuleFor(x => x.Property).NotEmpty().MinLength(n).MaxLength(n)`
   - `RuleFor(x => x.Price).GreaterThan(0)`
   - `.WithMessage("custom error")`
   - `.When(condition)` for conditional rules
3. Create `CreateProductDto` and `CreateUserDto` with validation rules
4. Test with valid and invalid inputs, showing all error messages
5. Return errors in ProblemDetails format

### Expected Output:
```
=== Validation Framework ===

--- Attribute-Based Validation ---
Input: { Name: "", Price: -5, Email: "not-an-email" }
Validation Result: FAILED
Errors:
  Name: "Name is required"
  Name: "Name must be at least 2 characters"
  Price: "Price must be between 0.01 and 99999.99"
  Email: "Invalid email address"

--- Fluent Validation ---
Input: { Name: "A", Price: 0, Category: "InvalidCat" }
Validation Result: FAILED
Errors:
  Name: "Name must be at least 2 characters"
  Price: "Price must be greater than 0"
  Category: "Category must be one of: Electronics, Clothing, Food, Books"

--- ProblemDetails Output ---
{
  "type": "https://tools.ietf.org/html/rfc7807",
  "title": "One or more validation errors occurred",
  "status": 400,
  "errors": {
    "Name": ["Name must be at least 2 characters"],
    "Price": ["Price must be greater than 0"],
    "Category": ["Category must be one of: Electronics, Clothing, Food, Books"]
  }
}
```

---

## Problem 4: Response Wrapper & Pagination System ⭐⭐ Medium-Hard

**Objective**: Build a console app that implements a complete API response wrapper pattern with pagination, sorting, and filtering.

### Requirements:
1. Create `ApiResponse<T>` with: Success, Data, Message, Errors, StatusCode
2. Create `PagedResponse<T>` with: Data, Page, PageSize, TotalCount, TotalPages, HasPrevious, HasNext
3. Create an in-memory product database (50+ items)
4. Implement query operations:
   - Filter by category, price range, search text
   - Sort by any property (ascending/descending)
   - Paginate with configurable page size
5. Wrap all results in appropriate response types
6. Demonstrate success, error, and paginated responses

### Expected Output:
```
=== Response Wrapper & Pagination ===

--- Success Response ---
ApiResponse {
  Success: true,
  StatusCode: 200,
  Data: { Id: 1, Name: "Laptop", Price: 999.99 },
  Message: null,
  Errors: null
}

--- Error Response ---
ApiResponse {
  Success: false,
  StatusCode: 404,
  Data: null,
  Message: "Product with ID 999 not found",
  Errors: null
}

--- Paginated Response ---
Query: category=Electronics, sortBy=price desc, page=2, pageSize=5
PagedResponse {
  Data: [5 products...],
  Page: 2,
  PageSize: 5,
  TotalCount: 23,
  TotalPages: 5,
  HasPrevious: true,
  HasNext: true
}
Products:
  [6] Wireless Mouse - $29.99
  [7] USB Hub - $34.99
  ...
```

---

## Problem 5: Complete DTO Pipeline with Mapping, Validation & Transformation ⭐⭐⭐ Hard

**Objective**: Build a console app that implements the complete data flow pipeline: Input DTO → Validate → Map to Entity → Process → Map to Response DTO.

### Requirements:
1. **Entities**: `Order` (Id, CustomerId, Items, Status, TotalAmount, CreatedDate), `OrderItem` (ProductId, ProductName, Quantity, UnitPrice, LineTotal), `Customer` (Id, Name, Email)
2. **DTOs**: `CreateOrderDto`, `OrderDto`, `OrderListDto`, `OrderDetailDto` (with nested items and customer info)
3. **Mapper**: Implement property-name-based mapper with flattening and collection support
4. **Validator**: Validate CreateOrderDto (customer exists, items not empty, quantities > 0, products exist)
5. **Pipeline**: `CreateOrderDto → Validate → Map to Order → Calculate totals → Save → Map to OrderDto → Wrap in ApiResponse`
6. Process 5+ order creation requests showing the full pipeline, including:
   - Successful creation
   - Validation failures
   - Business rule failures (insufficient stock)
   - Getting order details with nested data

### Expected Output:
```
=== Complete DTO Pipeline ===

━━━ Create Order #1 ━━━
Input: CreateOrderDto { CustomerId: 1, Items: [{ ProductId: 1, Qty: 2 }, { ProductId: 3, Qty: 1 }] }
[Validate] ✓ Valid
[Map] CreateOrderDto → Order entity
[Process] Calculated totals:
  Item 1: Laptop × 2 = $1,999.98
  Item 2: Mouse × 1 = $29.99
  SubTotal: $2,029.97, Tax: $162.40, Total: $2,192.37
[Save] Order #1 saved
[Map] Order → OrderDto
[Wrap] ApiResponse<OrderDto> { Success: true, StatusCode: 201, Data: { Id: 1, ... } }

━━━ Create Order #2 (Invalid) ━━━
Input: CreateOrderDto { CustomerId: 999, Items: [] }
[Validate] ✗ Failed:
  - Customer with ID 999 not found
  - Order must have at least one item
[Wrap] ApiResponse { Success: false, StatusCode: 400, Errors: [...] }
(Pipeline short-circuited — no mapping or processing)

━━━ Get Order Detail ━━━
[Fetch] Order #1 from database
[Map] Order → OrderDetailDto with flattening:
  OrderDetailDto {
    Id: 1,
    CustomerName: "John Doe",    ← flattened from Customer.Name
    CustomerEmail: "john@co.com", ← flattened from Customer.Email
    Status: "Pending",
    TotalAmount: $2,192.37,
    Items: [
      { ProductName: "Laptop", Quantity: 2, UnitPrice: $999.99, LineTotal: $1,999.98 },
      { ProductName: "Mouse", Quantity: 1, UnitPrice: $29.99, LineTotal: $29.99 }
    ]
  }
```

### Hints:
- Create an in-memory "database" using `Dictionary<int, T>` for each entity
- The pipeline should be a series of steps that can short-circuit on failure
- Use `Result<T>` pattern to chain success/failure through the pipeline
- Calculate line totals, subtotals, and tax in the processing step
