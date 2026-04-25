# Topic 4: Entity Framework Core & SQL Server

## 📘 What is Entity Framework Core (EF Core)?

Entity Framework Core is an **Object-Relational Mapper (ORM)** that lets you work with databases using C# objects instead of raw SQL.

### How an ORM Works

```
C# Code:  _context.Products.Where(p => p.Price > 100).ToList()
    ↓ (EF Core translates)
SQL:      SELECT * FROM Products WHERE Price > 100
    ↓ (Database executes)
Result:   Rows from Products table
    ↓ (EF Core materializes)
C#:       List<Product> with populated properties
```

### EF Core vs Other ORMs

| Feature | EF Core | Dapper | ADO.NET |
|---------|---------|--------|---------|
| Type | Full ORM | Micro ORM | Low-level |
| LINQ support | ✅ Full | ❌ None | ❌ None |
| Change tracking | ✅ Yes | ❌ No | ❌ No |
| Migrations | ✅ Yes | ❌ No | ❌ No |
| Performance | Good | Excellent | Best |
| Learning curve | Medium | Low | High |
| SQL Control | Medium | Full | Full |
| Best for | Enterprise apps | Performance-critical | Full control |

---

## 📘 Setting Up EF Core with SQL Server

### Install NuGet Packages

```bash
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add package Microsoft.EntityFrameworkCore.Design
```

### The DbContext — Your Database Gateway

```csharp
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // Each DbSet<T> represents a database table
    public DbSet<Product> Products { get; set; }
    public DbSet<Category> Categories { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<Customer> Customers { get; set; }

    // Configure the model (table structure, relationships, constraints)
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Apply all configurations from this assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
```

### Register in Program.cs

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(10),
                errorNumbersToAdd: null);
        }));
```

### Connection String in appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=TaskFlowDb;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

---

## 📘 Entity Configuration: Two Approaches

### Approach 1: Data Annotations (Simple)

```csharp
[Table("Products")]
public class Product
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    [Required]
    public decimal Price { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string Category { get; set; } = string.Empty;
    
    public int StockQuantity { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Foreign Key
    [ForeignKey("CategoryNavigation")]
    public int CategoryId { get; set; }
    
    // Navigation Property
    public Category CategoryNavigation { get; set; } = null!;
}
```

### Approach 2: Fluent API (Recommended for Complex Config)

```csharp
public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        // Table name
        builder.ToTable("Products");
        
        // Primary key
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).ValueGeneratedOnAdd();
        
        // Properties
        builder.Property(p => p.Name)
            .IsRequired()
            .HasMaxLength(100);
        
        builder.Property(p => p.Description)
            .HasMaxLength(500);
        
        builder.Property(p => p.Price)
            .IsRequired()
            .HasColumnType("decimal(18,2)");
        
        builder.Property(p => p.Category)
            .IsRequired()
            .HasMaxLength(50);
        
        builder.Property(p => p.IsActive)
            .HasDefaultValue(true);
        
        builder.Property(p => p.CreatedDate)
            .HasDefaultValueSql("GETUTCDATE()");
        
        // Indexes
        builder.HasIndex(p => p.Name);
        builder.HasIndex(p => p.Category);
        builder.HasIndex(p => new { p.Category, p.Price });  // Composite index
        
        // Unique constraint
        builder.HasIndex(p => p.Name).IsUnique();
    }
}
```

---

## 📘 Relationships

### One-to-Many

```csharp
// Entity classes
public class Category
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public ICollection<Product> Products { get; set; } = new List<Product>();
}

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int CategoryId { get; set; }                      // Foreign Key
    public Category Category { get; set; } = null!;          // Navigation Property
}

// Fluent API
builder.HasOne(p => p.Category)
    .WithMany(c => c.Products)
    .HasForeignKey(p => p.CategoryId)
    .OnDelete(DeleteBehavior.Restrict);  // Prevent cascade delete
```

### Many-to-Many

```csharp
public class Student
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public ICollection<Course> Courses { get; set; } = new List<Course>();
}

public class Course
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public ICollection<Student> Students { get; set; } = new List<Student>();
}

// EF Core 5+ creates the join table automatically
// Or configure explicitly:
builder.HasMany(s => s.Courses)
    .WithMany(c => c.Students)
    .UsingEntity(j => j.ToTable("StudentCourses"));
```

### One-to-One

```csharp
public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public UserProfile? Profile { get; set; }
}

public class UserProfile
{
    public int Id { get; set; }
    public string Bio { get; set; } = string.Empty;
    public int UserId { get; set; }
    public User User { get; set; } = null!;
}

builder.HasOne(u => u.Profile)
    .WithOne(p => p.User)
    .HasForeignKey<UserProfile>(p => p.UserId);
```

---

## 📘 Migrations

Migrations track database schema changes in code.

### Common Commands

```bash
# Create a migration
dotnet ef migrations add InitialCreate

# Apply migrations to database
dotnet ef database update

# Remove last migration (if not applied)
dotnet ef migrations remove

# Generate SQL script (for production)
dotnet ef migrations script

# Revert to a specific migration
dotnet ef database update MigrationName

# List all migrations
dotnet ef migrations list
```

### What a Migration Looks Like

```csharp
public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Products",
            columns: table => new
            {
                Id = table.Column<int>(nullable: false)
                    .Annotation("SqlServer:Identity", "1, 1"),
                Name = table.Column<string>(maxLength: 100, nullable: false),
                Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                IsActive = table.Column<bool>(nullable: false, defaultValue: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Products", x => x.Id);
            });
        
        migrationBuilder.CreateIndex(
            name: "IX_Products_Name",
            table: "Products",
            column: "Name",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Products");
    }
}
```

### Seeding Data

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Category>().HasData(
        new Category { Id = 1, Name = "Electronics" },
        new Category { Id = 2, Name = "Clothing" },
        new Category { Id = 3, Name = "Books" }
    );
    
    modelBuilder.Entity<Product>().HasData(
        new Product { Id = 1, Name = "Laptop", Price = 999.99m, CategoryId = 1 },
        new Product { Id = 2, Name = "T-Shirt", Price = 29.99m, CategoryId = 2 }
    );
}
```

---

## 📘 CRUD Operations with EF Core

### Create (Insert)

```csharp
// Single entity
var product = new Product { Name = "Laptop", Price = 999.99m, CategoryId = 1 };
_context.Products.Add(product);
await _context.SaveChangesAsync();
// product.Id is now set by the database

// Multiple entities
var products = new List<Product> { /* ... */ };
_context.Products.AddRange(products);
await _context.SaveChangesAsync();
```

### Read (Query)

```csharp
// Get all
var allProducts = await _context.Products.ToListAsync();

// Get by ID
var product = await _context.Products.FindAsync(id);

// Get with filter
var electronics = await _context.Products
    .Where(p => p.Category == "Electronics")
    .OrderBy(p => p.Price)
    .ToListAsync();

// Get with include (eager loading)
var productWithCategory = await _context.Products
    .Include(p => p.Category)
    .FirstOrDefaultAsync(p => p.Id == id);

// Get with projection
var productDtos = await _context.Products
    .Select(p => new ProductDto
    {
        Id = p.Id,
        Name = p.Name,
        Price = p.Price,
        CategoryName = p.Category.Name
    })
    .ToListAsync();
```

### Update

```csharp
// Method 1: Track and modify
var product = await _context.Products.FindAsync(id);
if (product != null)
{
    product.Name = "Updated Laptop";
    product.Price = 1099.99m;
    await _context.SaveChangesAsync();  // EF tracks changes automatically
}

// Method 2: Attach and set state
var product = new Product { Id = id, Name = "Updated", Price = 1099.99m };
_context.Products.Update(product);  // Marks ALL properties as modified
await _context.SaveChangesAsync();

// Method 3: ExecuteUpdate (EF Core 7+) — no tracking, direct SQL
await _context.Products
    .Where(p => p.Category == "Electronics")
    .ExecuteUpdateAsync(setters => setters
        .SetProperty(p => p.Price, p => p.Price * 1.1m));  // 10% price increase
```

### Delete

```csharp
// Method 1: Find and remove
var product = await _context.Products.FindAsync(id);
if (product != null)
{
    _context.Products.Remove(product);
    await _context.SaveChangesAsync();
}

// Method 2: ExecuteDelete (EF Core 7+)
await _context.Products
    .Where(p => !p.IsActive)
    .ExecuteDeleteAsync();
```

---

## 📘 Querying — LINQ to Entities

### Filtering

```csharp
var results = await _context.Products
    .Where(p => p.Price > 100 && p.IsActive)
    .Where(p => p.Category == "Electronics" || p.Category == "Computers")
    .Where(p => p.Name.Contains("laptop"))           // LIKE '%laptop%'
    .Where(p => EF.Functions.Like(p.Name, "%lap%"))   // Explicit LIKE
    .ToListAsync();
```

### Sorting

```csharp
var sorted = await _context.Products
    .OrderBy(p => p.Category)
    .ThenByDescending(p => p.Price)
    .ToListAsync();
```

### Pagination

```csharp
var page = 2;
var pageSize = 10;

var pagedProducts = await _context.Products
    .OrderBy(p => p.Id)
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();

var totalCount = await _context.Products.CountAsync();
```

### Aggregations

```csharp
var count = await _context.Products.CountAsync();
var avgPrice = await _context.Products.AverageAsync(p => p.Price);
var maxPrice = await _context.Products.MaxAsync(p => p.Price);
var totalValue = await _context.Products.SumAsync(p => p.Price * p.StockQuantity);
var any = await _context.Products.AnyAsync(p => p.StockQuantity == 0);
```

### Grouping

```csharp
var categoryStats = await _context.Products
    .GroupBy(p => p.Category)
    .Select(g => new
    {
        Category = g.Key,
        Count = g.Count(),
        AveragePrice = g.Average(p => p.Price),
        TotalStock = g.Sum(p => p.StockQuantity)
    })
    .OrderByDescending(x => x.Count)
    .ToListAsync();
```

---

## 📘 Loading Related Data

### Eager Loading (Include)

```csharp
// Load product with its category
var product = await _context.Products
    .Include(p => p.Category)
    .FirstOrDefaultAsync(p => p.Id == id);

// Multi-level includes
var order = await _context.Orders
    .Include(o => o.Customer)
    .Include(o => o.Items)
        .ThenInclude(i => i.Product)
            .ThenInclude(p => p.Category)
    .FirstOrDefaultAsync(o => o.Id == id);
```

### Explicit Loading

```csharp
var product = await _context.Products.FindAsync(id);

// Load related data on demand
await _context.Entry(product)
    .Collection(p => p.Reviews)
    .LoadAsync();

await _context.Entry(product)
    .Reference(p => p.Category)
    .LoadAsync();
```

### Lazy Loading

```csharp
// Install: dotnet add package Microsoft.EntityFrameworkCore.Proxies
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseLazyLoadingProxies()
           .UseSqlServer(connectionString));

// Properties must be virtual
public class Product
{
    public virtual Category Category { get; set; }  // Loaded on first access
    public virtual ICollection<Review> Reviews { get; set; }
}
```

> ⚠️ **Warning**: Lazy loading can cause the N+1 query problem — avoid in loops!

### Split Queries

```csharp
// Instead of one huge JOIN query, split into multiple queries
var orders = await _context.Orders
    .Include(o => o.Items)
    .Include(o => o.Customer)
    .AsSplitQuery()              // Generates separate SQL queries
    .ToListAsync();
```

---

## 📘 Change Tracking

EF Core tracks changes to entities automatically:

```csharp
var product = await _context.Products.FindAsync(1);
// EntityState: Unchanged

product.Price = 1099.99m;
// EntityState: Modified (EF detected the change)

await _context.SaveChangesAsync();
// Generates: UPDATE Products SET Price = 1099.99 WHERE Id = 1

// Check entity state
var entry = _context.Entry(product);
Console.WriteLine(entry.State);  // Unchanged (after SaveChanges)
```

### Entity States

| State | Meaning |
|-------|---------|
| `Detached` | Not tracked by the context |
| `Unchanged` | Loaded from DB, no changes |
| `Added` | New, will be INSERTed |
| `Modified` | Changed, will be UPDATEd |
| `Deleted` | Marked for deletion |

### No-Tracking Queries (Performance)

```csharp
// For read-only queries, skip change tracking
var products = await _context.Products
    .AsNoTracking()
    .Where(p => p.IsActive)
    .ToListAsync();

// Set globally for a context instance
_context.ChangeTracker.QueryTrackingBehavior = QueryTrackingBehavior.NoTracking;
```

---

## 📘 Raw SQL & Stored Procedures

```csharp
// Raw SQL query
var products = await _context.Products
    .FromSqlRaw("SELECT * FROM Products WHERE Price > {0}", 100)
    .ToListAsync();

// Interpolated (parameterized automatically — safe from SQL injection)
var category = "Electronics";
var products = await _context.Products
    .FromSqlInterpolated($"SELECT * FROM Products WHERE Category = {category}")
    .ToListAsync();

// Execute non-query
await _context.Database.ExecuteSqlRawAsync(
    "UPDATE Products SET Price = Price * 1.1 WHERE Category = {0}", "Electronics");

// Stored procedure
var products = await _context.Products
    .FromSqlRaw("EXEC GetProductsByCategory @Category = {0}", "Electronics")
    .ToListAsync();
```

> ⚠️ Always use parameterized queries (`{0}` or interpolation) — never concatenate strings!

---

## 📘 Transactions

```csharp
// Implicit transaction (SaveChanges wraps all changes in a transaction)
_context.Products.Add(product1);
_context.Products.Add(product2);
await _context.SaveChangesAsync();  // Both succeed or both fail

// Explicit transaction
using var transaction = await _context.Database.BeginTransactionAsync();
try
{
    var order = new Order { /* ... */ };
    _context.Orders.Add(order);
    await _context.SaveChangesAsync();
    
    // Update stock
    foreach (var item in order.Items)
    {
        var product = await _context.Products.FindAsync(item.ProductId);
        product!.StockQuantity -= item.Quantity;
    }
    await _context.SaveChangesAsync();
    
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

---

## 📘 Global Query Filters

Automatically apply filters to all queries (e.g., soft delete):

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // All Product queries automatically exclude inactive products
    modelBuilder.Entity<Product>()
        .HasQueryFilter(p => p.IsActive);
    
    // Multi-tenant filter
    modelBuilder.Entity<Product>()
        .HasQueryFilter(p => p.TenantId == _currentTenantId);
}

// Query automatically applies filter
var products = await _context.Products.ToListAsync();
// SQL: SELECT * FROM Products WHERE IsActive = 1

// Override filter when needed
var allProducts = await _context.Products
    .IgnoreQueryFilters()
    .ToListAsync();
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| EF Core | ORM that maps C# classes to database tables |
| DbContext | Gateway to database — contains DbSets and configuration |
| Data Annotations | Simple config using attributes on entity properties |
| Fluent API | Complex config using IEntityTypeConfiguration — preferred |
| Migrations | Version-controlled database schema changes |
| CRUD | Add/Find/Update/Remove + SaveChangesAsync |
| LINQ | Write C# queries, EF translates to SQL |
| Include | Eager loading of related data (joins) |
| AsNoTracking | Better performance for read-only queries |
| Change Tracking | EF detects property changes and generates UPDATE SQL |
| Global Filters | Auto-applied WHERE clauses (soft delete, multi-tenant) |

> **Next Topic**: Repository Pattern & Unit of Work — Abstracting data access.
