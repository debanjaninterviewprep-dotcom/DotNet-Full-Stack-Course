# Topic 5: Repository Pattern & Unit of Work

## 📘 What is the Repository Pattern?

The Repository Pattern **abstracts the data access layer**, providing a clean separation between business logic and data persistence. It acts as an in-memory collection of domain objects.

### Why Use the Repository Pattern?

| Benefit | Description |
|---------|------------|
| **Abstraction** | Business logic doesn't know about EF Core, SQL, or any specific ORM |
| **Testability** | Easy to mock repositories in unit tests |
| **Single Responsibility** | Data access logic is centralized in one place |
| **Flexibility** | Can swap EF Core for Dapper, MongoDB, etc. without changing business logic |
| **Consistency** | All data access follows the same patterns |

### Without Repository (Controller Directly Uses DbContext)

```csharp
// ❌ Controller tightly coupled to EF Core
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var products = await _dbContext.Products
        .Where(p => p.IsActive)
        .Include(p => p.Category)
        .OrderBy(p => p.Name)
        .ToListAsync();
    return Ok(products);
}
```

### With Repository (Controller Uses Abstraction)

```csharp
// ✅ Controller only knows about the interface
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var products = await _productRepository.GetAllActiveAsync();
    return Ok(products);
}
```

---

## 📘 Generic Repository

A base repository that provides common CRUD operations for any entity.

### Interface

```csharp
public interface IGenericRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T> AddAsync(T entity);
    Task AddRangeAsync(IEnumerable<T> entities);
    void Update(T entity);
    void Remove(T entity);
    void RemoveRange(IEnumerable<T> entities);
    Task<bool> ExistsAsync(int id);
    Task<int> CountAsync();
    Task<int> CountAsync(Expression<Func<T, bool>> predicate);
}
```

### Implementation

```csharp
public class GenericRepository<T> : IGenericRepository<T> where T : class
{
    protected readonly AppDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public GenericRepository(AppDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(int id)
    {
        return await _dbSet.FindAsync(id);
    }

    public virtual async Task<IEnumerable<T>> GetAllAsync()
    {
        return await _dbSet.ToListAsync();
    }

    public virtual async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.Where(predicate).ToListAsync();
    }

    public virtual async Task<T> AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
        return entity;
    }

    public virtual async Task AddRangeAsync(IEnumerable<T> entities)
    {
        await _dbSet.AddRangeAsync(entities);
    }

    public virtual void Update(T entity)
    {
        _dbSet.Update(entity);
    }

    public virtual void Remove(T entity)
    {
        _dbSet.Remove(entity);
    }

    public virtual void RemoveRange(IEnumerable<T> entities)
    {
        _dbSet.RemoveRange(entities);
    }

    public virtual async Task<bool> ExistsAsync(int id)
    {
        return await _dbSet.FindAsync(id) != null;
    }

    public virtual async Task<int> CountAsync()
    {
        return await _dbSet.CountAsync();
    }

    public virtual async Task<int> CountAsync(Expression<Func<T, bool>> predicate)
    {
        return await _dbSet.CountAsync(predicate);
    }
}
```

---

## 📘 Specific Repositories

Extend the generic repository with entity-specific queries.

```csharp
// Interface
public interface IProductRepository : IGenericRepository<Product>
{
    Task<IEnumerable<Product>> GetByCategoryAsync(string category);
    Task<IEnumerable<Product>> GetActiveProductsAsync();
    Task<Product?> GetWithCategoryAsync(int id);
    Task<IEnumerable<Product>> SearchAsync(string searchTerm);
    Task<PagedResult<Product>> GetPagedAsync(int page, int pageSize, string? category = null);
}

// Implementation
public class ProductRepository : GenericRepository<Product>, IProductRepository
{
    public ProductRepository(AppDbContext context) : base(context) { }

    public async Task<IEnumerable<Product>> GetByCategoryAsync(string category)
    {
        return await _dbSet
            .Where(p => p.Category == category && p.IsActive)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    public async Task<IEnumerable<Product>> GetActiveProductsAsync()
    {
        return await _dbSet
            .Where(p => p.IsActive)
            .Include(p => p.CategoryNavigation)
            .ToListAsync();
    }

    public async Task<Product?> GetWithCategoryAsync(int id)
    {
        return await _dbSet
            .Include(p => p.CategoryNavigation)
            .FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<IEnumerable<Product>> SearchAsync(string searchTerm)
    {
        return await _dbSet
            .Where(p => p.Name.Contains(searchTerm) || 
                       p.Description!.Contains(searchTerm))
            .ToListAsync();
    }

    public async Task<PagedResult<Product>> GetPagedAsync(
        int page, int pageSize, string? category = null)
    {
        var query = _dbSet.Where(p => p.IsActive);
        
        if (!string.IsNullOrEmpty(category))
            query = query.Where(p => p.Category == category);
        
        var totalCount = await query.CountAsync();
        var items = await query
            .OrderBy(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
        
        return new PagedResult<Product>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }
}
```

---

## 📘 Unit of Work Pattern

The Unit of Work **coordinates multiple repositories** and ensures all changes are saved in a single transaction.

### Why Unit of Work?

```csharp
// ❌ Without Unit of Work — each repo has its own SaveChanges
await _orderRepository.SaveChangesAsync();      // What if this succeeds...
await _productRepository.SaveChangesAsync();    // ...but this fails? Data inconsistency!
```

```csharp
// ✅ With Unit of Work — single SaveChanges for all repos
_unitOfWork.Orders.Add(order);
_unitOfWork.Products.Update(product);
await _unitOfWork.SaveChangesAsync();  // All or nothing — atomic!
```

### Interface

```csharp
public interface IUnitOfWork : IDisposable
{
    IProductRepository Products { get; }
    ICategoryRepository Categories { get; }
    IOrderRepository Orders { get; }
    ICustomerRepository Customers { get; }
    
    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}
```

### Implementation

```csharp
public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;
    private IDbContextTransaction? _transaction;
    
    private IProductRepository? _products;
    private ICategoryRepository? _categories;
    private IOrderRepository? _orders;
    private ICustomerRepository? _customers;

    public UnitOfWork(AppDbContext context)
    {
        _context = context;
    }

    // Lazy initialization — repos created only when accessed
    public IProductRepository Products => 
        _products ??= new ProductRepository(_context);
    
    public ICategoryRepository Categories => 
        _categories ??= new CategoryRepository(_context);
    
    public IOrderRepository Orders => 
        _orders ??= new OrderRepository(_context);
    
    public ICustomerRepository Customers => 
        _customers ??= new CustomerRepository(_context);

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.CommitAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public async Task RollbackTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}
```

### Registration in Program.cs

```csharp
// Register repositories
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();

// Register Unit of Work
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
```

---

## 📘 Using Unit of Work in Services

```csharp
public class OrderService : IOrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public OrderService(IUnitOfWork unitOfWork, IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    public async Task<OrderDto> CreateOrderAsync(CreateOrderDto dto)
    {
        await _unitOfWork.BeginTransactionAsync();
        
        try
        {
            // Validate customer exists
            var customer = await _unitOfWork.Customers.GetByIdAsync(dto.CustomerId);
            if (customer == null)
                throw new NotFoundException("Customer not found");
            
            // Create order
            var order = _mapper.Map<Order>(dto);
            order.OrderDate = DateTime.UtcNow;
            
            // Process each item
            foreach (var itemDto in dto.Items)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(itemDto.ProductId);
                if (product == null)
                    throw new NotFoundException($"Product {itemDto.ProductId} not found");
                
                if (product.StockQuantity < itemDto.Quantity)
                    throw new BusinessException($"Insufficient stock for {product.Name}");
                
                // Deduct stock
                product.StockQuantity -= itemDto.Quantity;
                _unitOfWork.Products.Update(product);
                
                order.Items.Add(new OrderItem
                {
                    ProductId = product.Id,
                    Quantity = itemDto.Quantity,
                    UnitPrice = product.Price
                });
            }
            
            // Calculate total
            order.TotalAmount = order.Items.Sum(i => i.Quantity * i.UnitPrice);
            
            await _unitOfWork.Orders.AddAsync(order);
            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();
            
            return _mapper.Map<OrderDto>(order);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
}
```

---

## 📘 Specification Pattern (Advanced)

Move query logic into reusable specification objects:

```csharp
public abstract class Specification<T>
{
    public abstract Expression<Func<T, bool>> ToExpression();
    
    public bool IsSatisfiedBy(T entity)
    {
        return ToExpression().Compile()(entity);
    }
}

// Specific specifications
public class ActiveProductSpec : Specification<Product>
{
    public override Expression<Func<Product, bool>> ToExpression()
        => p => p.IsActive;
}

public class ProductByCategorySpec : Specification<Product>
{
    private readonly string _category;
    public ProductByCategorySpec(string category) => _category = category;
    
    public override Expression<Func<Product, bool>> ToExpression()
        => p => p.Category == _category;
}

public class PriceRangeSpec : Specification<Product>
{
    private readonly decimal _min, _max;
    public PriceRangeSpec(decimal min, decimal max) { _min = min; _max = max; }
    
    public override Expression<Func<Product, bool>> ToExpression()
        => p => p.Price >= _min && p.Price <= _max;
}

// Usage in repository
public async Task<IEnumerable<Product>> FindAsync(Specification<Product> spec)
{
    return await _dbSet.Where(spec.ToExpression()).ToListAsync();
}

// Usage in service
var products = await _unitOfWork.Products.FindAsync(
    new ActiveProductSpec()
        .And(new ProductByCategorySpec("Electronics"))
        .And(new PriceRangeSpec(100, 500)));
```

---

## 📘 Project Structure

```
MyApi/
├── Data/
│   ├── AppDbContext.cs
│   ├── Repositories/
│   │   ├── Interfaces/
│   │   │   ├── IGenericRepository.cs
│   │   │   ├── IProductRepository.cs
│   │   │   ├── IOrderRepository.cs
│   │   │   └── IUnitOfWork.cs
│   │   └── Implementations/
│   │       ├── GenericRepository.cs
│   │       ├── ProductRepository.cs
│   │       ├── OrderRepository.cs
│   │       └── UnitOfWork.cs
│   └── Specifications/
│       ├── Specification.cs
│       └── ProductSpecifications.cs
├── Services/
│   ├── Interfaces/
│   │   └── IOrderService.cs
│   └── Implementations/
│       └── OrderService.cs
└── Controllers/
    └── OrdersController.cs
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| Repository Pattern | Abstracts data access behind interfaces |
| Generic Repository | Base CRUD operations for any entity type |
| Specific Repository | Entity-specific queries extending generic |
| Unit of Work | Coordinates multiple repos, single SaveChanges = atomic |
| Lazy Initialization | Repos created on first access (??= operator) |
| Transaction Management | BeginTransaction → operations → Commit/Rollback |
| Specification Pattern | Reusable, composable query criteria objects |
| Registration | All repos + UoW registered as Scoped in DI |

> **Next Topic**: Services Layer & Business Logic — Where your application logic lives.
