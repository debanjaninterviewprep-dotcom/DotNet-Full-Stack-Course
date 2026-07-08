# Topic 09: Clean Architecture — Interview Questions

---

## Q1. What is Clean Architecture?
**Answer:**
Clean Architecture (Robert C. Martin, "Uncle Bob") organizes code into concentric layers where **inner layers know nothing about outer layers**:

```
  ┌───────────────────────────────────────┐
  │         Infrastructure                │  ← DB, EF Core, Email, HTTP clients
  │  ┌─────────────────────────────────┐  │
  │  │         Application             │  │  ← Use cases, services, DTOs, interfaces
  │  │  ┌───────────────────────────┐  │  │
  │  │  │        Domain             │  │  │  ← Entities, value objects, domain services
  │  │  └───────────────────────────┘  │  │
  │  └─────────────────────────────────┘  │
  └───────────────────────────────────────┘
           ↑ Presentation (API, UI)
```

**The Dependency Rule:** Source code dependencies can only point **inward**. Nothing in an inner layer can know anything about outer layers.

---

## Q2. What are the layers in Clean Architecture and their responsibilities?
**Answer:**
```
Domain Layer (innermost):
  - Entities (User, Order, Product)
  - Value Objects (Money, Address, Email)
  - Domain Services (PricingService, DiscountCalculator)
  - Domain Events
  - Repository Interfaces (IUserRepository — interface only, no implementation)
  - Domain Exceptions
  - No dependencies on any other layer

Application Layer:
  - Use Cases / Application Services (PlaceOrderUseCase)
  - Commands and Queries (CQRS)
  - DTOs / Request / Response models
  - Application Interfaces (IEmailSender, ICurrentUserService)
  - Mapping (AutoMapper profiles)
  - Validation (FluentValidation)
  - Depends on: Domain only

Infrastructure Layer:
  - EF Core DbContext implementations
  - Repository implementations (UserRepository : IUserRepository)
  - External service clients (SendGridEmailSender, StripePaymentGateway)
  - Configuration
  - Depends on: Domain, Application (implements interfaces)

Presentation Layer (outermost):
  - ASP.NET Core Controllers / Minimal API endpoints
  - Middleware, Filters
  - Depends on: Application (sends commands/queries)
```

---

## Q3. What is CQRS and why is it used?
**Answer:**
CQRS (Command Query Responsibility Segregation) separates read operations (queries) from write operations (commands):

```csharp
// Command — changes state, returns minimal data
public record CreateUserCommand(string Name, string Email, string Password) : IRequest<int>;

public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, int>
{
    public async Task<int> Handle(CreateUserCommand cmd, CancellationToken ct)
    {
        var user = new User { Name = cmd.Name, Email = cmd.Email };
        user.SetPassword(cmd.Password); // domain method hashes
        await _repo.AddAsync(user, ct);
        await _uow.SaveChangesAsync(ct);
        await _eventBus.PublishAsync(new UserCreatedEvent(user.Id), ct);
        return user.Id;
    }
}

// Query — reads state, doesn't change it
public record GetUserByIdQuery(int Id) : IRequest<UserDto?>;

public class GetUserByIdQueryHandler : IRequestHandler<GetUserByIdQuery, UserDto?>
{
    public async Task<UserDto?> Handle(GetUserByIdQuery query, CancellationToken ct)
        => await _db.Users
            .Where(u => u.Id == query.Id)
            .ProjectTo<UserDto>(_mapper.ConfigurationProvider)
            .FirstOrDefaultAsync(ct);
}
```

Benefits: separate read/write models, optimized read stack (bypass domain, direct DB projection), easier scaling.

---

## Q4. What is MediatR and how does it implement the Mediator pattern?
**Answer:**
MediatR is a .NET library implementing the Mediator pattern — decouples senders (controllers) from handlers:

```csharp
// Setup
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(CreateUserCommand).Assembly));

// Controller sends request — knows nothing about handler
[HttpPost]
public async Task<IActionResult> Create(CreateUserRequest req, IMediator mediator)
{
    var userId = await mediator.Send(new CreateUserCommand(req.Name, req.Email, req.Password));
    return CreatedAtAction(nameof(GetById), new { id = userId }, null);
}

// Pipeline behaviors — cross-cutting concerns (logging, validation, caching)
public class ValidationBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public async Task<TResponse> Handle(TRequest req, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        var context = new ValidationContext<TRequest>(req);
        var failures = _validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Any()) throw new ValidationException(failures);
        return await next();
    }
}

builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
```

---

## Q5. What are Domain Entities and Value Objects?
**Answer:**
**Entity** — has a unique identity that persists over time. Equality by ID.
**Value Object** — no identity; equality by value. Immutable.

```csharp
// Entity
public class Order
{
    public int Id { get; private set; }          // identity
    public Money Total { get; private set; }     // value object
    public Address ShippingAddress { get; private set; }
    private List<OrderItem> _items = [];
    public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();

    public void AddItem(Product product, int quantity)
    {
        // Domain logic inside entity
        if (Status != OrderStatus.Draft) throw new InvalidOperationException("Order not in draft");
        _items.Add(new OrderItem(product, quantity));
        Total = Money.Sum(_items.Select(i => i.Subtotal));
    }
}

// Value Object — immutable, equality by value
public record Money(decimal Amount, string Currency)
{
    public static Money Zero(string currency) => new(0, currency);
    public Money Add(Money other)
    {
        if (Currency != other.Currency) throw new InvalidOperationException("Currency mismatch");
        return new Money(Amount + other.Amount, Currency);
    }
    public static Money Sum(IEnumerable<Money> amounts)
        => amounts.Aggregate(Zero("USD"), (acc, m) => acc.Add(m));
}

public record Address(string Street, string City, string Country, string PostalCode);
public record Email(string Value)
{
    public Email(string value) : this(value)
    {
        if (!value.Contains('@')) throw new ArgumentException("Invalid email");
    }
}
```

---

## Q6. What are Domain Events?
**Answer:**
Domain events signal that something significant happened in the domain — decouple side effects from domain logic:

```csharp
// Domain event
public record OrderPlacedEvent(int OrderId, int UserId, decimal Total) : IDomainEvent;

// Entity raises event
public class Order
{
    private List<IDomainEvent> _events = [];
    public IReadOnlyCollection<IDomainEvent> Events => _events.AsReadOnly();

    public void Place()
    {
        Status = OrderStatus.Placed;
        _events.Add(new OrderPlacedEvent(Id, UserId, Total.Amount));
    }
}

// Dispatch events after SaveChanges
public override async Task<int> SaveChangesAsync(CancellationToken ct = default)
{
    var result = await base.SaveChangesAsync(ct);
    var events = ChangeTracker.Entries<Entity>()
        .SelectMany(e => e.Entity.Events).ToList();
    foreach (var evt in events)
        await _mediator.Publish(evt, ct); // publish after successful save
    return result;
}

// Event handler (in Application layer)
public class OrderPlacedEventHandler(IEmailSender emailSender)
    : INotificationHandler<OrderPlacedEvent>
{
    public async Task Handle(OrderPlacedEvent evt, CancellationToken ct)
        => await emailSender.SendOrderConfirmationAsync(evt.UserId, evt.OrderId);
}
```

---

## Q7. What is the Clean Architecture project structure?
**Answer:**
```
MyApp.sln
├── MyApp.Domain/           ← no dependencies
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Events/
│   ├── Exceptions/
│   └── Interfaces/         ← IRepository interfaces
│
├── MyApp.Application/      ← depends on Domain only
│   ├── Features/
│   │   └── Users/
│   │       ├── Commands/
│   │       │   ├── CreateUser/
│   │       │   │   ├── CreateUserCommand.cs
│   │       │   │   ├── CreateUserCommandHandler.cs
│   │       │   │   └── CreateUserCommandValidator.cs
│   │       └── Queries/
│   │           └── GetUserById/
│   │               ├── GetUserByIdQuery.cs
│   │               └── GetUserByIdQueryHandler.cs
│   ├── Common/
│   │   ├── Interfaces/     ← IEmailSender, ICurrentUserService
│   │   └── Behaviors/      ← MediatR pipeline behaviors
│   └── Mappings/
│
├── MyApp.Infrastructure/   ← depends on Domain + Application
│   ├── Persistence/
│   │   ├── AppDbContext.cs
│   │   ├── Migrations/
│   │   └── Repositories/
│   ├── Services/
│   │   ├── EmailSender.cs
│   │   └── JwtTokenService.cs
│   └── DependencyInjection.cs
│
└── MyApp.WebApi/           ← depends on Application
    ├── Controllers/
    ├── Middleware/
    ├── Program.cs
    └── appsettings.json
```

---

## Q8. How do you apply SOLID principles in Clean Architecture?
**Answer:**
```csharp
// S — Single Responsibility: each class has one reason to change
public class CreateUserCommandHandler { /* only handles user creation */ }
public class UserEmailService { /* only sends user emails */ }

// O — Open/Closed: open for extension, closed for modification
// Add new payment methods by implementing IPaymentGateway, not modifying existing code
public interface IPaymentGateway { Task<PaymentResult> ChargeAsync(decimal amount); }
public class StripeGateway : IPaymentGateway { }
public class PayPalGateway : IPaymentGateway { }

// L — Liskov Substitution: subtypes substitutable for base types
// All IPaymentGateway implementations must honor the contract

// I — Interface Segregation: clients only depend on what they use
public interface IUserReader { Task<UserDto?> GetByIdAsync(int id); }
public interface IUserWriter { Task<int> CreateAsync(CreateUserDto dto); Task UpdateAsync(...); }
// AdminController uses IUserReader + IUserWriter; PublicController uses only IUserReader

// D — Dependency Inversion: depend on abstractions
// Application depends on IUserRepository (abstraction), not UserRepository (concrete)
// Infrastructure provides the implementation, registered via DI
```

---

## Q9. What is the difference between Clean Architecture, Onion Architecture, and Hexagonal Architecture?
**Answer:**
These are all variations of the same core idea — depend inward, isolate domain from infrastructure:

| Architecture | Creator | Key metaphor | Core concept |
|---|---|---|---|
| **Hexagonal (Ports & Adapters)** | Alistair Cockburn | Hexagon with ports | Primary/secondary adapters |
| **Onion Architecture** | Jeffrey Palermo | Onion layers | Domain model at core |
| **Clean Architecture** | Robert C. Martin | Concentric circles | Dependency rule |

All three share:
- Domain logic at the center.
- Infrastructure at the outside.
- Inward-only dependencies.
- Interfaces separate layers.

The terminology differs but the principles are the same.

---

## Q10. What is the difference between Anemic Domain Model and Rich Domain Model?
**Answer:**
```csharp
// Anemic Domain Model — entities are just data bags, logic in services
public class Order { public int Id; public decimal Total; public string Status; }

public class OrderService {
    public void PlaceOrder(Order order) {
        order.Status = "Placed"; // logic outside entity
        order.Total = CalculateTotal(order); // scattered logic
    }
}

// Rich Domain Model — entities encapsulate their own logic
public class Order
{
    public int Id { get; private set; }
    private OrderStatus _status = OrderStatus.Draft;
    private Money _total = Money.Zero("USD");

    public void Place()
    {
        if (_status != OrderStatus.Draft) throw new InvalidOperationException("Already placed");
        _status = OrderStatus.Placed;
        AddEvent(new OrderPlacedEvent(Id));
    }

    public void AddItem(Product product, int qty)
    {
        // enforces invariants, updates total
    }
}
```

Rich Domain Model puts domain logic inside entities, making entities the heart of the system. Anemic models are often simpler but violate OOP principles.

---

## Q11. What are aggregate roots in Domain-Driven Design?
**Answer:**
An aggregate is a cluster of domain objects treated as a single unit. The **aggregate root** is the only entry point:

```csharp
// Order is the aggregate root — only entry point to the aggregate
public class Order  // aggregate root
{
    private List<OrderItem> _items = []; // part of the Order aggregate

    // All changes go through the root
    public void AddItem(Product product, int quantity) { _items.Add(...); }
    public void RemoveItem(int itemId) { _items.RemoveAll(i => i.Id == itemId); }
    public void Cancel() { /* validate and cancel */ }
}

public class OrderItem  // part of Order aggregate — never accessed directly
{
    internal OrderItem(Product product, int quantity) { /* ... */ }
    public Product Product { get; private set; }
    public int Quantity { get; private set; }
}

// Rules:
// 1. External objects hold references only to the aggregate root
// 2. Changes to aggregate members go through the root
// 3. Each aggregate has its own repository (OrderRepository, not OrderItemRepository)
// 4. Transactions don't cross aggregate boundaries
```

---

## Q12. What is the Outbox Pattern?
**Answer:**
The Outbox Pattern ensures reliable event delivery — saves events to a database table in the same transaction as the domain change:

```csharp
// Problem: if you save the order AND publish an event, they can fail independently:
await _db.SaveChangesAsync(); // ← saved
await _eventBus.PublishAsync(event); // ← crashes here — event lost!

// Outbox solution: store events in DB in the same transaction
public class OutboxMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string EventType { get; set; } = "";
    public string Payload { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

// In SaveChanges — persist events to outbox table
var events = ChangeTracker.Entries<IAggregateRoot>()
    .SelectMany(e => e.Entity.Events)
    .Select(evt => new OutboxMessage {
        EventType = evt.GetType().Name,
        Payload = JsonSerializer.Serialize(evt, evt.GetType())
    });
_db.OutboxMessages.AddRange(events);
await base.SaveChangesAsync(ct); // both domain changes + events in one tx

// Background worker polls outbox and publishes events
// Guarantees at-least-once delivery
```

---

## Q13. What is the difference between Application Services and Use Case classes?
**Answer:**
```csharp
// Traditional Application Service — contains multiple use cases
public class UserApplicationService
{
    public Task<UserDto> CreateUser(CreateUserDto dto) { }
    public Task<UserDto> GetUser(int id) { }
    public Task UpdateUser(int id, UpdateUserDto dto) { }
    public Task DeleteUser(int id) { }
}

// Use Case / CQRS Handler — one class per use case (Single Responsibility)
public class CreateUserCommand : IRequest<int> { }
public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, int> { }

public class GetUserByIdQuery : IRequest<UserDto?> { }
public class GetUserByIdQueryHandler : IRequestHandler<GetUserByIdQuery, UserDto?> { }

public class DeleteUserCommand : IRequest { }
public class DeleteUserCommandHandler : IRequestHandler<DeleteUserCommand> { }
```

CQRS use case classes are more granular but easier to test, extend, and evolve independently.

---

## Q14. What are the benefits and drawbacks of Clean Architecture?
**Answer:**
**Benefits:**
- Domain logic is framework-agnostic — can swap ASP.NET Core, EF Core, or the database.
- Highly testable — domain and application layers have no infrastructure dependencies.
- Clear separation of concerns — easy to locate where to add new features.
- Follows SOLID principles naturally.

**Drawbacks:**
- **More files and folders** — simple CRUD operations require 4+ files (command, handler, validator, DTO).
- **Over-engineering for small apps** — a simple CRUD API doesn't need 4 projects.
- **Learning curve** — steeper for teams unfamiliar with DDD concepts.
- **Mapping overhead** — multiple mapping layers (domain → DTO → response).

**When to use:** Medium to large applications, teams working in parallel, apps expected to evolve significantly over time.

---

## Q15. What are the `Vertical Slice Architecture` and how does it differ from Clean Architecture?
**Answer:**
Vertical Slice Architecture organizes code by **feature** (vertical slice through all layers) rather than by layer:

```
Clean Architecture:
Controllers/ → Services/ → Repositories/ → Domain/
(horizontal layers)

Vertical Slice:
Features/
├── Users/
│   ├── Create/     ← CreateUserCommand, Handler, Validator, Response — all in one folder
│   ├── GetById/    ← GetUserQuery, Handler, Response
│   └── Delete/     ← DeleteUserCommand, Handler
├── Orders/
│   ├── Place/
│   └── Cancel/
```

```csharp
// Vertical Slice — all code for "Create User" in one place
namespace MyApp.Features.Users.Create
{
    public record Request(string Name, string Email) : IRequest<Response>;
    public record Response(int Id, string Name);
    public class Validator : AbstractValidator<Request> { /* rules here */ }
    public class Handler(AppDbContext db, IMapper mapper) : IRequestHandler<Request, Response>
    {
        public async Task<Response> Handle(Request req, CancellationToken ct)
        {
            var user = new User { Name = req.Name, Email = req.Email };
            db.Users.Add(user);
            await db.SaveChangesAsync(ct);
            return new Response(user.Id, user.Name);
        }
    }
}
```

**Vertical Slice vs Clean Architecture:** Vertical Slice reduces indirection and is easier to add features. Clean Architecture enforces stricter separation but requires more files. Both are valid — choose based on team preference and complexity.
