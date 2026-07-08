# Topic 04: Entity Framework Core & SQL Server — Interview Questions

---

## Q1. What is Entity Framework Core?
**Answer:**
EF Core is Microsoft's **Object-Relational Mapper (ORM)** for .NET. It enables working with relational databases using .NET objects, eliminating most raw SQL:

```csharp
// Without ORM
using var cmd = new SqlCommand("SELECT Id, Name FROM Users WHERE Id = @id", conn);
cmd.Parameters.AddWithValue("@id", id);
var reader = cmd.ExecuteReader();
var user = new User { Id = (int)reader["Id"], Name = reader["Name"].ToString() };

// With EF Core
var user = await _db.Users.FindAsync(id); // same result — much simpler
```

EF Core supports multiple databases via providers: SQL Server, PostgreSQL, SQLite, MySQL, CosmosDB, and more.

---

## Q2. What is `DbContext` and what does it do?
**Answer:**
`DbContext` is the bridge between your domain model and the database:

```csharp
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // DbSet = table representation
    public DbSet<User>    Users    { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<Order>   Orders   { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Fluent API configuration
        modelBuilder.Entity<User>(entity => {
            entity.HasKey(u => u.Id);
            entity.Property(u => u.Email).IsRequired().HasMaxLength(100);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.HasMany(u => u.Orders).WithOne(o => o.User).HasForeignKey(o => o.UserId);
        });

        // Apply all IEntityTypeConfiguration<T> in this assembly
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}

// Register in DI
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));
```

---

## Q3. What is Code First vs Database First?
**Answer:**
| | Code First | Database First |
|---|---|---|
| **Start with** | C# entity classes | Existing database schema |
| **Database created** | Via migrations | Via scaffold |
| **Version control** | ✓ Migrations tracked in code | ✗ Manual SQL scripts |
| **Recommended** | ✓ New projects | Legacy databases |

```bash
# Code First workflow
dotnet ef migrations add InitialCreate     # generate migration from model changes
dotnet ef database update                  # apply pending migrations to DB

# Database First
dotnet ef dbcontext scaffold "Connection..." Microsoft.EntityFrameworkCore.SqlServer \
    --output-dir Models --context AppDbContext  # generate classes from existing DB
```

---

## Q4. What are EF Core migrations?
**Answer:**
Migrations track model changes and generate the SQL to evolve the database schema:

```bash
# Common migration commands
dotnet ef migrations add AddUserBirthdate      # create migration from model changes
dotnet ef migrations list                      # show all migrations
dotnet ef database update                      # apply all pending migrations
dotnet ef database update AddUserBirthdate     # apply up to specific migration
dotnet ef migrations remove                    # remove last migration (if not applied)
dotnet ef database update 0                    # revert ALL migrations
dotnet ef script                               # generate SQL script (for production)
```

```csharp
// Generated migration file
public partial class AddUserBirthdate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
        => migrationBuilder.AddColumn<DateTime>("Birthdate", "Users", nullable: true);

    protected override void Down(MigrationBuilder migrationBuilder)
        => migrationBuilder.DropColumn("Birthdate", "Users");
}

// Apply at startup (for auto-migration in development)
using var scope = app.Services.CreateScope();
var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
await db.Database.MigrateAsync();
```

---

## Q5. What is the difference between eager loading, lazy loading, and explicit loading?
**Answer:**
**Eager Loading** — loads related entities with the initial query (`Include`):
```csharp
// Generates single JOIN query
var orders = await _db.Orders
    .Include(o => o.User)                         // include User
    .Include(o => o.Items).ThenInclude(i => i.Product) // nested include
    .Where(o => o.Status == "Pending")
    .ToListAsync();
```

**Lazy Loading** — loads related entities on first access (requires proxy):
```csharp
// Setup: builder.Services.AddDbContext<AppDbContext>(opts => opts.UseLazyLoadingProxies());
// Navigation properties must be virtual:
public virtual ICollection<Order> Orders { get; set; }

var user = await _db.Users.FindAsync(1);
var count = user.Orders.Count; // triggers a DB query here (N+1 risk!)
```

**Explicit Loading** — load related entities on demand:
```csharp
var user = await _db.Users.FindAsync(1);
await _db.Entry(user).Collection(u => u.Orders).LoadAsync(); // explicit load
await _db.Entry(user).Reference(u => u.Address).LoadAsync();
```

**Avoid lazy loading in APIs** — it causes the N+1 problem.

---

## Q6. What is the N+1 query problem?
**Answer:**
The N+1 problem occurs when 1 query loads a list, then N more queries load related data for each item:

```csharp
// N+1 — BAD (lazy loading or explicit loading in a loop)
var orders = await _db.Orders.ToListAsync();            // 1 query
foreach (var order in orders)
    Console.WriteLine(order.User.Name);                 // N queries (one per order!)
// Total: 1 + N queries

// Fix 1: Eager loading (1 JOIN query)
var orders = await _db.Orders.Include(o => o.User).ToListAsync(); // 1 query with JOIN

// Fix 2: Select only needed data (projection)
var results = await _db.Orders
    .Select(o => new { o.Id, CustomerName = o.User.Name, o.Total })
    .ToListAsync(); // 1 query, no navigation needed
```

---

## Q7. How do you perform CRUD operations with EF Core?
**Answer:**
```csharp
// Create
var user = new User { Name = "Alice", Email = "alice@example.com" };
_db.Users.Add(user);
await _db.SaveChangesAsync(); // INSERT
Console.WriteLine(user.Id); // populated after save

// Read
var user = await _db.Users.FindAsync(id);          // by PK (from cache or DB)
var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
var users = await _db.Users.Where(u => u.IsActive).ToListAsync();

// Update
var user = await _db.Users.FindAsync(id);
user.Name = "Bob"; // change tracking detects this
await _db.SaveChangesAsync(); // UPDATE

// Update without loading (more efficient for single field updates)
await _db.Users.Where(u => u.Id == id)
    .ExecuteUpdateAsync(setters => setters.SetProperty(u => u.LastLogin, DateTime.UtcNow));

// Delete
var user = await _db.Users.FindAsync(id);
_db.Users.Remove(user);
await _db.SaveChangesAsync(); // DELETE

// Delete without loading
await _db.Users.Where(u => u.Id == id).ExecuteDeleteAsync();
```

---

## Q8. What is change tracking in EF Core?
**Answer:**
EF Core tracks changes to entities loaded from the database:

```csharp
// Entity states: Detached, Unchanged, Added, Modified, Deleted
var user = await _db.Users.FindAsync(1);  // Unchanged
user.Name = "New Name";                   // Modified (automatic)
_db.Users.Add(new User { ... });          // Added
_db.Users.Remove(user);                   // Deleted
await _db.SaveChangesAsync();             // generates UPDATE/INSERT/DELETE SQL

// Check state
var state = _db.Entry(user).State; // EntityState.Modified

// Disable tracking for read-only queries (performance)
var users = await _db.Users.AsNoTracking().ToListAsync(); // no change tracking overhead

// Detach entity
_db.Entry(user).State = EntityState.Detached;
```

---

## Q9. What is `AsNoTracking` and when should you use it?
**Answer:**
`AsNoTracking()` returns entities without attaching them to the change tracker — significant performance improvement for read-only operations:

```csharp
// With tracking (default) — 30-50% overhead from change tracking
var users = await _db.Users.ToListAsync();

// Without tracking — faster, less memory
var users = await _db.Users.AsNoTracking().ToListAsync();

// Default for all queries in a DbContext
_db.ChangeTracker.QueryTrackingBehavior = QueryTrackingBehavior.NoTracking;

// Use AsNoTracking when:
// - Read-only API endpoints (GET)
// - Reports and analytics
// - Projection queries (already not tracked)
// - You won't update/delete the returned entities

// Don't use when:
// - You will update/delete the entities
// - You need the entities to be tracked for relationship management
```

---

## Q10. How do you configure entity relationships with Fluent API?
**Answer:**
```csharp
protected override void OnModelCreating(ModelBuilder mb)
{
    // One-to-Many
    mb.Entity<Order>()
        .HasOne(o => o.User)
        .WithMany(u => u.Orders)
        .HasForeignKey(o => o.UserId)
        .OnDelete(DeleteBehavior.Restrict); // Cascade, SetNull, Restrict, NoAction

    // One-to-One
    mb.Entity<User>()
        .HasOne(u => u.Profile)
        .WithOne(p => p.User)
        .HasForeignKey<UserProfile>(p => p.UserId);

    // Many-to-Many (EF Core 5+)
    mb.Entity<Student>()
        .HasMany(s => s.Courses)
        .WithMany(c => c.Students)
        .UsingEntity<Enrollment>(                        // explicit join table
            e => e.HasOne(en => en.Course).WithMany(),
            e => e.HasOne(en => en.Student).WithMany(),
            e => e.ToTable("Enrollments").HasKey(en => new { en.StudentId, en.CourseId })
        );
}
```

---

## Q11. What are shadow properties in EF Core?
**Answer:**
Shadow properties exist in the EF Core model but NOT as properties in the entity class — stored in the change tracker:

```csharp
// Define shadow property
mb.Entity<User>().Property<DateTime>("LastModified");
mb.Entity<User>().Property<string>("CreatedByIp").HasMaxLength(50);

// Set in SaveChanges override (audit trail pattern)
public override async Task<int> SaveChangesAsync(CancellationToken ct = default)
{
    foreach (var entry in ChangeTracker.Entries<BaseEntity>())
    {
        switch (entry.State)
        {
            case EntityState.Added:
                entry.Property("CreatedAt").CurrentValue = DateTime.UtcNow;
                break;
            case EntityState.Modified:
                entry.Property("UpdatedAt").CurrentValue = DateTime.UtcNow;
                break;
        }
    }
    return await base.SaveChangesAsync(ct);
}

// Query using shadow property
var users = await _db.Users
    .Where(u => EF.Property<DateTime>(u, "LastModified") > DateTime.UtcNow.AddDays(-7))
    .ToListAsync();
```

---

## Q12. What are transactions in EF Core?
**Answer:**
```csharp
// Implicit transaction — SaveChanges wraps ALL changes in a transaction
await _db.SaveChangesAsync(); // all changes in one transaction

// Explicit transaction — span multiple SaveChanges calls
await using var transaction = await _db.Database.BeginTransactionAsync();
try {
    _db.Orders.Add(order);
    await _db.SaveChangesAsync(); // still inside transaction

    _db.Inventory.Remove(item);
    await _db.SaveChangesAsync(); // still inside transaction

    await transaction.CommitAsync(); // commit both
} catch {
    await transaction.RollbackAsync();
    throw;
}

// Cross-context transaction
await using var transaction = await dbContext1.Database.BeginTransactionAsync();
await dbContext2.Database.UseTransactionAsync(transaction.GetDbTransaction());
```

---

## Q13. How do you handle concurrency conflicts in EF Core?
**Answer:**
```csharp
// Add a concurrency token (rowversion/timestamp)
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public decimal Price { get; set; }

    [Timestamp]
    public byte[] RowVersion { get; set; } = []; // SQL Server rowversion column
}

// Fluent API
mb.Entity<Product>().Property(p => p.RowVersion).IsRowVersion();

// Handle concurrency exception
try {
    _db.Entry(product).State = EntityState.Modified;
    await _db.SaveChangesAsync();
} catch (DbUpdateConcurrencyException ex) {
    var entry = ex.Entries.Single();
    var dbValues = await entry.GetDatabaseValuesAsync(); // current DB values
    // Option 1: Client wins — keep local changes
    // Option 2: Database wins — refresh from DB
    entry.OriginalValues.SetValues(dbValues!);
    await _db.SaveChangesAsync(); // retry with updated token
}
```

---

## Q14. What is raw SQL in EF Core and when is it used?
**Answer:**
```csharp
// FromSqlRaw — execute raw SQL and map to entity
var users = await _db.Users
    .FromSqlRaw("SELECT * FROM Users WHERE CreatedAt > {0}", cutoff)
    .AsNoTracking()
    .ToListAsync();

// Combine with LINQ
var activeUsers = await _db.Users
    .FromSqlRaw("SELECT * FROM Users WHERE IsActive = 1")
    .Where(u => u.Name.StartsWith("A")) // adds WHERE after raw SQL
    .OrderBy(u => u.Name)
    .ToListAsync();

// ExecuteSqlRaw — for non-query statements
await _db.Database.ExecuteSqlRawAsync(
    "UPDATE Users SET LastLogin = {0} WHERE Id = {1}", DateTime.UtcNow, userId);

// Stored procedures
var result = await _db.Users
    .FromSqlRaw("EXEC sp_GetActiveUsers @p0", departmentId)
    .ToListAsync();

// When to use raw SQL:
// - Complex queries that EF Core can't generate efficiently
// - Stored procedures
// - Bulk operations
// - Database-specific features (full-text search, JSON queries)
```

---

## Q15. How do you seed data in EF Core?
**Answer:**
```csharp
// Approach 1: HasData in OnModelCreating (migration-tracked)
mb.Entity<Role>().HasData(
    new Role { Id = 1, Name = "Admin",  NormalizedName = "ADMIN" },
    new Role { Id = 2, Name = "User",   NormalizedName = "USER" },
    new Role { Id = 3, Name = "Editor", NormalizedName = "EDITOR" }
);

// Approach 2: Custom IEntityTypeConfiguration<T>
public class RoleConfiguration : IEntityTypeConfiguration<Role>
{
    public void Configure(EntityTypeBuilder<Role> builder)
    {
        builder.HasData(/* seed data */);
    }
}
mb.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());

// Approach 3: Programmatic seed at startup (for dynamic data)
public static async Task SeedAsync(AppDbContext db)
{
    if (!await db.Roles.AnyAsync())
    {
        db.Roles.AddRange(new Role { Name = "Admin" }, new Role { Name = "User" });
        await db.SaveChangesAsync();
    }
}

// Call at startup
using var scope = app.Services.CreateScope();
var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
await db.Database.MigrateAsync();
await SeedData.SeedAsync(db);
```
