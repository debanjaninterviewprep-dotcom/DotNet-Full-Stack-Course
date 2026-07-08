# Topic 05: Repository Pattern & Unit of Work — Interview Questions

---

## Q1. What is the Repository pattern?
**Answer:**
The Repository pattern abstracts the data access layer, providing a collection-like interface to the domain layer. The domain doesn't know if data comes from SQL Server, MongoDB, or a cache:

```csharp
// Interface (abstraction)
public interface IUserRepository
{
    Task<User?> GetByIdAsync(int id);
    Task<IEnumerable<User>> GetAllAsync();
    Task<IEnumerable<User>> FindAsync(Expression<Func<User, bool>> predicate);
    Task AddAsync(User user);
    void Update(User user);
    void Delete(User user);
}

// Implementation (EF Core)
public class UserRepository : IUserRepository
{
    private readonly AppDbContext _db;
    public UserRepository(AppDbContext db) => _db = db;

    public async Task<User?> GetByIdAsync(int id) => await _db.Users.FindAsync(id);
    public async Task<IEnumerable<User>> GetAllAsync() => await _db.Users.AsNoTracking().ToListAsync();
    public async Task<IEnumerable<User>> FindAsync(Expression<Func<User, bool>> pred)
        => await _db.Users.Where(pred).AsNoTracking().ToListAsync();
    public async Task AddAsync(User user) => await _db.Users.AddAsync(user);
    public void Update(User user) => _db.Users.Update(user);
    public void Delete(User user) => _db.Users.Remove(user);
}
```

---

## Q2. What is a generic repository?
**Answer:**
A generic repository provides common CRUD operations for all entities:

```csharp
// Generic interface
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T> AddAsync(T entity);
    void Update(T entity);
    void Delete(T entity);
    Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate);
    Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null);
}

// Generic implementation
public class Repository<T> : IRepository<T> where T : class
{
    protected readonly AppDbContext _db;
    protected readonly DbSet<T> _set;

    public Repository(AppDbContext db) { _db = db; _set = db.Set<T>(); }

    public async Task<T?> GetByIdAsync(int id) => await _set.FindAsync(id);
    public async Task<IEnumerable<T>> GetAllAsync() => await _set.AsNoTracking().ToListAsync();
    public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> pred)
        => await _set.Where(pred).AsNoTracking().ToListAsync();
    public async Task<T> AddAsync(T entity) { await _set.AddAsync(entity); return entity; }
    public void Update(T entity) => _set.Update(entity);
    public void Delete(T entity) => _set.Remove(entity);
    public async Task<bool> ExistsAsync(Expression<Func<T, bool>> pred)
        => await _set.AnyAsync(pred);
    public async Task<int> CountAsync(Expression<Func<T, bool>>? pred = null)
        => pred is null ? await _set.CountAsync() : await _set.CountAsync(pred);
}

// Extend for domain-specific queries
public class UserRepository : Repository<User>, IUserRepository
{
    public UserRepository(AppDbContext db) : base(db) { }

    public async Task<User?> GetByEmailAsync(string email)
        => await _set.FirstOrDefaultAsync(u => u.Email == email);

    public async Task<IEnumerable<User>> GetActiveUsersAsync()
        => await _set.Where(u => u.IsActive).AsNoTracking().ToListAsync();
}
```

---

## Q3. What is the Unit of Work pattern?
**Answer:**
Unit of Work groups multiple repository operations into a single transaction — either all succeed or all fail:

```csharp
// Unit of Work interface
public interface IUnitOfWork : IDisposable
{
    IUserRepository    Users    { get; }
    IOrderRepository   Orders   { get; }
    IProductRepository Products { get; }
    Task<int> SaveChangesAsync(CancellationToken ct = default);
}

// Implementation wrapping DbContext
public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _db;

    public UnitOfWork(AppDbContext db)
    {
        _db = db;
        Users    = new UserRepository(db);
        Orders   = new OrderRepository(db);
        Products = new ProductRepository(db);
    }

    public IUserRepository    Users    { get; }
    public IOrderRepository   Orders   { get; }
    public IProductRepository Products { get; }

    public Task<int> SaveChangesAsync(CancellationToken ct = default)
        => _db.SaveChangesAsync(ct); // single call — atomic commit

    public void Dispose() => _db.Dispose();
}

// Service uses UoW
public class OrderService(IUnitOfWork uow)
{
    public async Task PlaceOrderAsync(CreateOrderDto dto)
    {
        var user = await uow.Users.GetByIdAsync(dto.UserId);
        var product = await uow.Products.GetByIdAsync(dto.ProductId);

        var order = new Order { User = user!, Product = product! };
        await uow.Orders.AddAsync(order);
        product!.Stock -= dto.Quantity;
        uow.Products.Update(product);

        await uow.SaveChangesAsync(); // both changes committed atomically
    }
}
```

---

## Q4. Why is the Repository pattern debated with EF Core?
**Answer:**
Arguments **against** adding a Repository on top of EF Core:
- `DbContext` + `DbSet<T>` **already IS** a Unit of Work + Repository.
- `IQueryable<T>` gives powerful composable queries that repositories often limit.
- Abstraction leaks — you still need to handle `AsNoTracking`, `Include`, pagination in repository interfaces.
- Extra layer with no benefit if you only ever use one database.

Arguments **for** it:
- **Testability** — mock `IUserRepository` in unit tests without needing a real DB.
- **Encapsulation** — complex domain-specific queries live in one place.
- **Replaceability** — can swap EF Core for Dapper or another ORM.
- **Code organization** — separates data access from business logic.

**Pragmatic approach:** Use repositories in projects where testability and clear separation matter. Inject `DbContext` directly in small projects.

---

## Q5. How do you implement a specification pattern with repositories?
**Answer:**
The Specification pattern encapsulates query criteria as objects:

```csharp
// Specification base
public abstract class Specification<T>
{
    public abstract Expression<Func<T, bool>> Criteria { get; }
    public List<Expression<Func<T, object>>> Includes { get; } = [];
    public Expression<Func<T, object>>? OrderBy { get; protected set; }
    public int? Take { get; protected set; }
    public int? Skip { get; protected set; }
}

// Concrete specification
public class ActiveUsersSpec : Specification<User>
{
    public ActiveUsersSpec(string? search, int page, int size)
    {
        Criteria = u => u.IsActive && (search == null || u.Name.Contains(search));
        Includes.Add(u => u.Orders);
        OrderBy = u => u.Name;
        Skip = (page - 1) * size;
        Take = size;
    }
    public override Expression<Func<User, bool>> Criteria { get; }
}

// Repository applies specification
public async Task<IEnumerable<T>> FindAsync(Specification<T> spec)
{
    var query = _set.Where(spec.Criteria);
    foreach (var include in spec.Includes) query = query.Include(include);
    if (spec.OrderBy != null) query = query.OrderBy(spec.OrderBy);
    if (spec.Skip.HasValue) query = query.Skip(spec.Skip.Value);
    if (spec.Take.HasValue) query = query.Take(spec.Take.Value);
    return await query.AsNoTracking().ToListAsync();
}

// Usage
var users = await _repo.FindAsync(new ActiveUsersSpec("alice", page: 1, size: 20));
```

---

## Q6. How do you unit test a service that uses a repository?
**Answer:**
```csharp
// Using Moq
[Test]
public async Task CreateOrder_ShouldDeductStock()
{
    // Arrange
    var mockUoW = new Mock<IUnitOfWork>();
    var product = new Product { Id = 1, Name = "Widget", Stock = 10, Price = 9.99m };

    mockUoW.Setup(u => u.Products.GetByIdAsync(1)).ReturnsAsync(product);
    mockUoW.Setup(u => u.Orders.AddAsync(It.IsAny<Order>())).Returns(Task.CompletedTask);
    mockUoW.Setup(u => u.SaveChangesAsync(default)).ReturnsAsync(1);

    var service = new OrderService(mockUoW.Object);

    // Act
    await service.PlaceOrderAsync(new CreateOrderDto { ProductId = 1, Quantity = 3, UserId = 1 });

    // Assert
    Assert.That(product.Stock, Is.EqualTo(7)); // stock deducted
    mockUoW.Verify(u => u.SaveChangesAsync(default), Times.Once);
}

// Using InMemory database (integration-style unit test)
[Test]
public async Task GetByEmail_ShouldReturnUser()
{
    var opts = new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase("TestDb")
        .Options;
    await using var db = new AppDbContext(opts);
    db.Users.Add(new User { Id = 1, Email = "test@test.com", Name = "Test" });
    await db.SaveChangesAsync();

    var repo = new UserRepository(db);
    var user = await repo.GetByEmailAsync("test@test.com");
    Assert.That(user!.Name, Is.EqualTo("Test"));
}
```

---

## Q7. What is the difference between `IRepository` and using `DbContext` directly?
**Answer:**
```csharp
// Direct DbContext in service — tight coupling to EF Core
public class OrderService(AppDbContext db)
{
    public async Task<Order?> GetOrder(int id)
        => await db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id);
}

// With repository — abstracted, testable
public class OrderService(IOrderRepository repo)
{
    public async Task<Order?> GetOrder(int id) => await repo.GetWithItemsAsync(id);
}
```

Direct DbContext: simpler, less code, allows full IQueryable power.
Repository: enables unit testing without a database, centralizes query logic.

---

## Q8. How do you register repositories in the DI container?
**Answer:**
```csharp
// Option 1: Manual registration
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Option 2: Convention-based with Scrutor (auto-register by convention)
builder.Services.Scan(scan => scan
    .FromAssemblyOf<UserRepository>()
    .AddClasses(classes => classes.AssignableTo(typeof(IRepository<>)))
    .AsImplementedInterfaces()
    .WithScopedLifetime());

// Register generic repository + specific repositories
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IUserRepository, UserRepository>(); // override for specific
```

---

## Q9. What is the `IQueryable` vs `IEnumerable` issue with repositories?
**Answer:**
Returning `IQueryable<T>` from a repository leaks the data access abstraction:

```csharp
// ❌ Leaky — caller must know about EF Core to use IQueryable properly
public interface IUserRepository {
    IQueryable<User> GetAll(); // caller can call .Include(), .Where() — knows it's EF
}

// ✓ Encapsulated — repository owns the query logic
public interface IUserRepository {
    Task<IEnumerable<UserDto>> GetActiveUsersAsync(int page, int size, string? search);
    // Repository builds the complete query internally
}
```

**Trade-off:** `IQueryable<T>` is more flexible but breaks the abstraction. `IEnumerable<T>` is safer but you need specific methods per use case.

**Pragmatic middle ground:** Return `IReadOnlyList<T>` or `IEnumerable<T>` from repositories; build the full query (with filters, pagination, projections) inside the repository.

---

## Q10. What are some best practices for the Repository pattern?
**Answer:**
1. **One repository per aggregate root** — not per table (Order repo handles Order + OrderItems).
2. **Methods should be meaningful** — `GetActiveUsersWithOrders()` not `Find(u => u.IsActive, include: u => u.Orders)`.
3. **Keep repositories thin** — complex business logic belongs in the Service layer.
4. **Use async everywhere** — all data access should be `async/await`.
5. **Return concrete results** — `Task<User?>` not `IQueryable<User>`.
6. **Include only what's needed** — document what each method loads (lazy loading off).

```csharp
// Good repository interface
public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(int id);
    Task<Order?> GetWithItemsAndUserAsync(int id);    // explicit loading
    Task<PagedResult<Order>> GetPagedAsync(int page, int size, OrderStatus? status);
    Task<IReadOnlyList<Order>> GetByUserIdAsync(int userId);
    Task AddAsync(Order order);
    void Update(Order order);
}
```
