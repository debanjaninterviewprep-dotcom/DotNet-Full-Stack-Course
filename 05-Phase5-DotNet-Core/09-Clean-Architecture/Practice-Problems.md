# Topic 9: Clean Architecture & Project Structure — Practice Problems

---

## Problem 1: Domain Layer Simulator ★★★

### Objective
Build a rich domain model with entities, value objects, and domain rules — demonstrating that the domain layer has ZERO external dependencies.

### Requirements
1. Create entities:
   - `BaseEntity` with `Id`, `CreatedAt`, `UpdatedAt`, domain events list
   - `Product` with Name, Description, `Money` price, StockQuantity, IsActive
   - `Order` with CustomerId, `List<OrderItem>`, Status enum, `Money` total
   - `OrderItem` with ProductId, ProductName, Quantity, `Money` unitPrice
2. Create value objects (implement as records):
   - `Money(Amount, Currency)` with arithmetic operators (+, *, comparison)
   - `Email(Value)` with validation
   - `Address(Street, City, State, ZipCode, Country)` with validation
3. Domain rules (throw `DomainException` on violation):
   - Product price must be > 0
   - Cannot remove more stock than available
   - Order must have at least one item
   - Cannot add items to a completed/cancelled order
   - Total is automatically calculated from items
4. Demonstrate all domain logic and validation in console output

### Expected Output
```
=== Value Objects ===
Money: 99.99 USD + 50.01 USD = 150.00 USD
Money: 25.00 USD * 3 = 75.00 USD
Email: "john@example.com" ✓ valid
Email: "invalid" ✗ DomainException: Invalid email

=== Product Entity ===
Created: Laptop — 999.99 USD (Stock: 0)
Added 50 units → Stock: 50
Removed 3 units → Stock: 47
Tried removing 100 units → DomainException: Insufficient stock

=== Order Entity ===
Created Order for customer C001
Added: 2x Laptop (999.99 USD) = 1999.98 USD
Added: 1x Mouse (29.99 USD) = 29.99 USD
Order Total: 2029.97 USD
Status: Pending → Processing → Shipped → Delivered ✓
Tried adding item to delivered order → DomainException!
```

---

## Problem 2: Application Layer — Service + Result Pattern ★★★

### Objective
Build the application/service layer with DTOs, mapping, validation, and the Result pattern — no database, just in-memory repositories.

### Requirements
1. Domain layer: Reuse entities from Problem 1
2. Repository interfaces (in Domain):
   - `IRepository<T>` with GetById, GetAll, Add, Update, Delete
   - `IProductRepository` extending with `GetByName`, `GetActiveProducts`
3. Application layer:
   - `ProductDto`, `CreateProductDto`, `UpdateProductDto`
   - `IProductService` interface
   - `ProductService` implementation with full CRUD
   - `Result<T>` class with `Success`, `Failure`, `NotFound`, `Created`
   - Manual mapping (entity ↔ DTO)
4. Infrastructure layer (in-memory):
   - `InMemoryProductRepository` implementing `IProductRepository`
5. Wire up with manual DI and execute CRUD operations

### Expected Output
```
=== Product Service (Application Layer) ===

Create "Laptop" → Result: Created (201) — ID: abc-123
Create "Laptop" (duplicate) → Result: Failure (409) — Already exists

GetAll → Result: Success (200) — 1 product(s)
  • Laptop — 999.99 USD (Active, Stock: 0)

GetById(abc-123) → Result: Success (200) — Laptop
GetById(invalid) → Result: NotFound (404) — Not found

Update(abc-123, price=899.99) → Result: Success (200) — Updated
GetById(abc-123) → Laptop — 899.99 USD ✓

Delete(abc-123) → Result: Success (200) — Deleted
GetAll → Result: Success (200) — 0 product(s)
```

---

## Problem 3: CQRS Pattern Simulator ★★★★

### Objective
Implement the CQRS pattern with commands, queries, handlers, and a mediator — simulating MediatR behavior.

### Requirements
1. Create a `IMediator` interface with `Send<TResponse>(IRequest<TResponse>)` method
2. Create `IRequest<TResponse>` marker interface
3. Create `IRequestHandler<TRequest, TResponse>` interface
4. Implement a `Mediator` class that resolves handlers from a service registry
5. Commands:
   - `CreateProductCommand` → `CreateProductCommandHandler`
   - `UpdateProductCommand` → `UpdateProductCommandHandler`
   - `DeleteProductCommand` → `DeleteProductCommandHandler`
6. Queries:
   - `GetProductByIdQuery` → `GetProductByIdQueryHandler`
   - `GetAllProductsQuery` → `GetAllProductsQueryHandler`
7. Pipeline Behaviors:
   - `LoggingBehavior`: Logs before and after handling
   - `ValidationBehavior`: Validates command before handling
   - `PerformanceBehavior`: Measures and warns if slow
8. Wire up manually and execute commands/queries

### Expected Output
```
=== CQRS with Mediator ===

Sending: CreateProductCommand { Name="Laptop", Price=999.99 }
  [Logging] Handling CreateProductCommand...
  [Validation] Validating... ✓
  [Performance] Starting timer
  [Handler] Creating product...
  [Performance] Completed in 5ms ✓
  [Logging] Handled → Created (201)
Result: ProductDto { Id=abc-123, Name="Laptop" }

Sending: GetAllProductsQuery { Page=1, Size=10 }
  [Logging] Handling GetAllProductsQuery...
  [Handler] Querying products...
  [Logging] Handled → Success (200)
Result: [ProductDto { Name="Laptop" }]

Sending: CreateProductCommand { Name="", Price=-1 }
  [Logging] Handling CreateProductCommand...
  [Validation] ✗ Validation failed:
    - Name: Required
    - Price: Must be > 0
Result: Failure (400) — Validation Error
```

---

## Problem 4: Layered Architecture Dependency Enforcer ★★★★

### Objective
Build a system that analyzes a simulated project structure and enforces Clean Architecture dependency rules.

### Requirements
1. Model a project structure with layers:
   - Domain (no dependencies)
   - Application (depends on Domain only)
   - Infrastructure (depends on Domain + Application)
   - API (depends on Application + Infrastructure)
2. Each "project" has a name, layer, and list of references
3. Create a `DependencyAnalyzer` that:
   - Validates all project references follow the dependency rule
   - Detects circular dependencies
   - Detects forbidden references (e.g., Domain → Infrastructure)
   - Generates a dependency graph (ASCII art)
   - Suggests fixes for violations
4. Test with both valid and invalid architectures

### Expected Output
```
=== Valid Architecture ===
MyApp.Domain        → (no dependencies)        ✓
MyApp.Application   → Domain                   ✓
MyApp.Infrastructure → Domain, Application      ✓
MyApp.API           → Application, Infrastructure ✓

Dependency Graph:
  API
  ├── Application
  │   └── Domain
  └── Infrastructure
      ├── Domain
      └── Application
          └── Domain

All dependency rules satisfied! ✓

=== Invalid Architecture (Violations) ===
✗ VIOLATION: Domain → Infrastructure (Domain must have ZERO dependencies)
✗ VIOLATION: Application → Infrastructure (Application cannot depend on Infrastructure)
✗ CIRCULAR: Infrastructure → Application → Infrastructure

Suggestions:
  1. Remove Domain → Infrastructure reference. Use interfaces in Domain, implement in Infrastructure.
  2. Remove Application → Infrastructure. Define interfaces in Application, implement in Infrastructure.
  3. Break circular dependency by introducing an interface in Application layer.
```

---

## Problem 5: Full Clean Architecture Simulation ★★★★★

### Objective
Build a complete e-commerce order processing system following Clean Architecture with all layers, CQRS, domain events, and proper dependency injection — all in a console app.

### Requirements
1. **Domain Layer**:
   - Entities: `Product`, `Order`, `OrderItem`, `Customer`
   - Value objects: `Money`, `Email`, `Address`
   - Domain events: `OrderCreatedEvent`, `OrderStatusChangedEvent`, `LowStockEvent`
   - Interfaces: `IProductRepository`, `IOrderRepository`, `IUnitOfWork`
   - Enums: `OrderStatus` (Pending → Processing → Shipped → Delivered / Cancelled)
2. **Application Layer**:
   - Commands: `CreateOrderCommand`, `UpdateOrderStatusCommand`, `AddProductCommand`
   - Queries: `GetOrderByIdQuery`, `GetCustomerOrdersQuery`, `GetProductsQuery`
   - Event handlers: `SendConfirmationOnOrderCreated`, `CheckStockOnOrderCreated`
   - Services: `IEmailService`, `INotificationService`
   - DTOs and Result pattern
3. **Infrastructure Layer** (in-memory):
   - `InMemoryProductRepository`, `InMemoryOrderRepository`
   - `InMemoryUnitOfWork`
   - `ConsoleEmailService`, `ConsoleNotificationService`
4. **Presentation Layer** (console-based):
   - `ConsoleController` that accepts commands from user input
   - Route-like command parsing: `POST /products`, `GET /orders/1`
5. Simulate a complete workflow:
   - Add products
   - Create an order
   - Process order lifecycle (pending → shipped → delivered)
   - Handle domain events (email notifications, stock checks)
   - Handle errors (out of stock, invalid state transitions)

### Expected Output
```
========================================
  E-Commerce System — Clean Architecture
========================================

> POST /products {"name":"Laptop","price":999.99,"stock":10}
  [Application] CreateProductCommand received
  [Handler] Product created: ID=p1
  Response: 201 Created — { id: "p1", name: "Laptop" }

> POST /products {"name":"Mouse","price":29.99,"stock":50}
  Response: 201 Created — { id: "p2", name: "Mouse" }

> POST /orders {"customerId":"c1","items":[{"productId":"p1","qty":2},{"productId":"p2","qty":3}]}
  [Application] CreateOrderCommand received
  [Handler] Creating order...
  [Domain] Order.AddItem: 2x Laptop = 1999.98
  [Domain] Order.AddItem: 3x Mouse = 89.97
  [Domain] Order total: 2089.95
  [Domain] Event raised: OrderCreatedEvent
  [EventHandler] SendConfirmation → Email sent to customer c1
  [EventHandler] CheckStock → Laptop stock: 10→8, Mouse stock: 50→47
  [Infrastructure] UnitOfWork.SaveChanges() — 1 order, 2 stock updates
  Response: 201 Created — { orderId: "o1", total: 2089.95 }

> PATCH /orders/o1/status {"status":"Processing"}
  [Domain] Order status: Pending → Processing ✓
  [Domain] Event: OrderStatusChangedEvent
  Response: 200 OK

> PATCH /orders/o1/status {"status":"Delivered"}
  [Domain] ✗ Cannot transition from Processing to Delivered
  Response: 400 — Invalid state transition

> PATCH /orders/o1/status {"status":"Shipped"}
  [Domain] Order status: Processing → Shipped ✓
  Response: 200 OK

> GET /orders/o1
  Response: 200 — Order { Status: Shipped, Items: 2, Total: 2089.95 }
```

---

## 🎯 Difficulty Ratings

| Problem | Difficulty | Concepts |
|---------|-----------|----------|
| 1 | ★★★ | Rich domain model, value objects, domain rules |
| 2 | ★★★ | Service layer, Result pattern, DTOs, manual DI |
| 3 | ★★★★ | CQRS, mediator pattern, pipeline behaviors |
| 4 | ★★★★ | Dependency analysis, architecture validation |
| 5 | ★★★★★ | Full Clean Architecture, events, CQRS, all layers |
