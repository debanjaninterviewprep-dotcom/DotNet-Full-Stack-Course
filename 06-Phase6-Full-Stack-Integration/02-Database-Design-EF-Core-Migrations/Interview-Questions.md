# Topic 02: Database Design & EF Core Migrations — Interview Questions

---

## Q1. What are the database normalization forms?
**Answer:**
Normalization eliminates redundancy and ensures data integrity:

**1NF (First Normal Form):** Each cell contains a single atomic value; no repeating groups.
```
❌ Orders(Id, ProductIds) — multiple values in ProductIds
✓  OrderItems(OrderId, ProductId, Quantity) — atomic values
```

**2NF (Second Normal Form):** 1NF + no partial dependencies (non-key attributes depend on the FULL primary key).
```
❌ OrderItems(OrderId, ProductId, ProductName) — ProductName depends only on ProductId
✓  OrderItems(OrderId, ProductId, Quantity) + Products(ProductId, ProductName)
```

**3NF (Third Normal Form):** 2NF + no transitive dependencies (non-key depends on another non-key).
```
❌ Employees(Id, DepartmentId, DepartmentName) — DepartmentName depends on DepartmentId, not Id
✓  Employees(Id, DepartmentId) + Departments(DepartmentId, DepartmentName)
```

**BCNF / 4NF:** More advanced forms for eliminating remaining anomalies — rarely applied beyond 3NF in practice.

---

## Q2. What are indexes and when should you create them?
**Answer:**
An index is a B-tree data structure that speeds up lookups at the cost of write performance and storage:

```sql
-- Clustered index (1 per table) — table data stored in this order
-- Default: primary key
CREATE CLUSTERED INDEX IX_Users_Id ON Users(Id);

-- Non-clustered index — separate structure with pointer to row
CREATE INDEX IX_Users_Email ON Users(Email);         -- lookup by email
CREATE INDEX IX_Orders_UserId ON Orders(UserId);     -- foreign key lookup
CREATE INDEX IX_Orders_Status_CreatedAt ON Orders(Status, CreatedAt); -- composite

-- Unique index — enforces uniqueness
CREATE UNIQUE INDEX IX_Users_Email ON Users(Email);

-- Filtered index — index only a subset of rows
CREATE INDEX IX_Orders_Pending ON Orders(CreatedAt) WHERE Status = 'Pending';
```

**EF Core:**
```csharp
mb.Entity<User>().HasIndex(u => u.Email).IsUnique();
mb.Entity<Order>().HasIndex(o => new { o.UserId, o.Status }); // composite
mb.Entity<Order>().HasIndex(o => o.Status).HasFilter("[Status] = 'Pending'"); // filtered
```

**When to create:** Columns in WHERE, JOIN ON, ORDER BY, GROUP BY clauses that are used frequently. Monitor slow queries — add indexes based on actual query plans.

---

## Q3. What is the difference between `HasOne`, `HasMany`, and `HasForeignKey` in EF Core?
**Answer:**
```csharp
// One-to-Many: User has many Orders
mb.Entity<User>()
    .HasMany(u => u.Orders)
    .WithOne(o => o.User)
    .HasForeignKey(o => o.UserId)
    .OnDelete(DeleteBehavior.Cascade);

// One-to-One: User has one UserProfile
mb.Entity<User>()
    .HasOne(u => u.Profile)
    .WithOne(p => p.User)
    .HasForeignKey<UserProfile>(p => p.UserId);

// Many-to-Many (EF Core 5+ without join entity)
mb.Entity<Student>()
    .HasMany(s => s.Courses)
    .WithMany(c => c.Students);

// Many-to-Many with explicit join entity
mb.Entity<Enrollment>(e => {
    e.HasKey(en => new { en.StudentId, en.CourseId }); // composite key
    e.HasOne(en => en.Student).WithMany(s => s.Enrollments).HasForeignKey(en => en.StudentId);
    e.HasOne(en => en.Course).WithMany(c => c.Enrollments).HasForeignKey(en => en.CourseId);
    e.Property(en => en.Grade);  // extra column on join table
});
```

---

## Q4. What is soft delete and how do you implement it in EF Core?
**Answer:**
Soft delete marks records as deleted without physically removing them — preserves audit trail and allows recovery:

```csharp
// Base entity with soft delete
public abstract class BaseEntity
{
    public int Id { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
    public string? DeletedBy { get; set; }
}

// Global query filter — automatically excludes deleted records
mb.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
mb.Entity<Order>().HasQueryFilter(o => !o.IsDeleted);

// Override Delete to soft delete
public override int SaveChanges()
{
    foreach (var entry in ChangeTracker.Entries<BaseEntity>().Where(e => e.State == EntityState.Deleted))
    {
        entry.State = EntityState.Modified;  // don't actually delete
        entry.Entity.IsDeleted = true;
        entry.Entity.DeletedAt = DateTime.UtcNow;
    }
    return base.SaveChanges();
}

// Include soft-deleted records when needed
var allUsers = await _db.Users.IgnoreQueryFilters().ToListAsync();
var deletedUsers = await _db.Users.IgnoreQueryFilters().Where(u => u.IsDeleted).ToListAsync();
```

---

## Q5. What are audit fields and how do you implement them automatically?
**Answer:**
```csharp
// Auditable entity base
public abstract class AuditableEntity
{
    public int Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; } = "";
    public DateTime? UpdatedAt { get; set; }
    public string? UpdatedBy { get; set; }
}

// DbContext auto-sets audit fields
public class AppDbContext(DbContextOptions opts, ICurrentUserService currentUser) : DbContext(opts)
{
    public override Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var user = currentUser.UserId ?? "system";

        foreach (var entry in ChangeTracker.Entries<AuditableEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = now;
                    entry.Entity.CreatedBy = user;
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = now;
                    entry.Entity.UpdatedBy = user;
                    break;
            }
        }
        return base.SaveChangesAsync(ct);
    }
}
```

---

## Q6. What are table-per-hierarchy (TPH) and table-per-type (TPT) inheritance strategies?
**Answer:**
```csharp
// TPH — all types in one table with discriminator column (EF Core default)
public abstract class Payment { public int Id; public decimal Amount; }
public class CreditCardPayment : Payment { public string CardNumber; }
public class BankTransferPayment : Payment { public string IBAN; }

// One table: Payments(Id, Amount, Discriminator, CardNumber?, IBAN?)
mb.Entity<Payment>().HasDiscriminator<string>("PaymentType")
    .HasValue<CreditCardPayment>("CreditCard")
    .HasValue<BankTransferPayment>("BankTransfer");

// TPT — each type has its own table
mb.Entity<Payment>().ToTable("Payments");
mb.Entity<CreditCardPayment>().ToTable("CreditCardPayments");  // Payments JOIN CreditCardPayments

// TPC (Table Per Concrete class, EF Core 7+) — each concrete class has full table
mb.Entity<CreditCardPayment>().ToTable("CreditCardPayments");  // all columns here
mb.Entity<BankTransferPayment>().ToTable("BankTransferPayments");

// TPH: faster reads (no joins), but many nullable columns
// TPT: cleaner schema, slower reads (requires joins)
// TPC: best read performance, no joins, but harder to query all payments
```

---

## Q7. What are database migrations in production?
**Answer:**
Applying migrations in production requires care to avoid downtime:

```bash
# Generate SQL script (for production — review before applying)
dotnet ef script 0 --output migration.sql

# Generate incremental script (from last applied to latest)
dotnet ef script LastAppliedMigration --output incremental.sql
```

**Safe migration practices:**
1. **Additive first:** Add new nullable columns/tables before removing old ones.
2. **Multi-step breaking changes:** Expand → Migrate data → Contract (3-phase deploy).
3. **Backward compatible:** New code must work with old schema until old schema is removed.
4. **Test on production copy:** Never apply untested migrations to production.
5. **Rollback plan:** Have a rollback script ready.

```csharp
// Apply at startup (for development/staging — not recommended for production)
using var scope = app.Services.CreateScope();
var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
if (db.Database.GetPendingMigrations().Any())
    await db.Database.MigrateAsync();
```

---

## Q8. How do you design a database for multi-tenancy?
**Answer:**
Three main approaches:

```
1. Shared database, shared schema (column discriminator):
   Each table has TenantId column
   SELECT * FROM Users WHERE TenantId = @tenantId
   Pro: Simple, cost-effective. Con: Poor isolation, risk of data leak

2. Shared database, separate schema:
   SELECT * FROM tenant_123.Users
   Pro: Good isolation. Con: Schema management complexity

3. Separate database per tenant:
   Connection string per tenant
   Pro: Best isolation, easy backup/restore. Con: Many databases to manage
```

**EF Core approach (shared schema):**
```csharp
// Global query filter per entity
mb.Entity<User>().HasQueryFilter(u => u.TenantId == _currentTenant.Id);

// Override SaveChanges to auto-set TenantId
entry.Entity.TenantId = _currentTenant.Id;
```

---

## Q9. What are database views and computed columns?
**Answer:**
```csharp
// Database view — query stored as virtual table
// Migration:
migrationBuilder.Sql(@"
    CREATE VIEW vw_OrderSummary AS
    SELECT o.Id, u.Name AS CustomerName, o.Total, COUNT(oi.Id) AS ItemCount
    FROM Orders o
    JOIN Users u ON o.UserId = u.Id
    LEFT JOIN OrderItems oi ON o.Id = oi.OrderId
    GROUP BY o.Id, u.Name, o.Total");

// Map view to entity in EF Core
mb.Entity<OrderSummaryView>().HasNoKey().ToView("vw_OrderSummary");
var summaries = await _db.Set<OrderSummaryView>().ToListAsync();

// Computed column — value calculated from other columns
migrationBuilder.AddColumn<string>("FullName", "Users",
    computedColumnSql: "[FirstName] + ' ' + [LastName]",
    stored: true); // stored = persisted to disk (faster reads, slower writes)

mb.Entity<User>().Property(u => u.FullName).HasComputedColumnSql("[FirstName] + ' ' + [LastName]");
```

---

## Q10. What is connection pooling and why does it matter?
**Answer:**
Connection pooling reuses existing database connections instead of creating new ones (expensive):

```csharp
// Default: SqlClient manages connection pool automatically
// Max pool size: 100 connections by default
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        connectionString,
        sqlOptions => {
            sqlOptions.EnableRetryOnFailure(maxRetryCount: 5);
            sqlOptions.CommandTimeout(30);
        }
    ));

// Connection string pool settings
// "Server=.;Database=App;Pooling=true;Min Pool Size=5;Max Pool Size=100;Connection Timeout=30"

// Monitor pool exhaustion:
// If connection pool is exhausted → timeouts
// Symptoms: "Timeout expired. The timeout period elapsed prior to obtaining a connection"
// Fix: reduce connection hold time, use AsNoTracking, dispose DbContext promptly
```

---

## Q11. What is a database transaction and what are isolation levels?
**Answer:**
```sql
-- ACID properties: Atomicity, Consistency, Isolation, Durability

-- Isolation levels (least → most strict)
READ UNCOMMITTED  -- dirty reads possible (sees uncommitted changes)
READ COMMITTED    -- no dirty reads (SQL Server default)
REPEATABLE READ   -- no non-repeatable reads
SERIALIZABLE      -- fully isolated (no phantom reads)
SNAPSHOT          -- reads consistent snapshot (no locks — SQL Server feature)
```

```csharp
// EF Core transaction
await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
try {
    // multiple operations...
    await _db.SaveChangesAsync();
    await tx.CommitAsync();
} catch {
    await tx.RollbackAsync();
    throw;
}
```

---

## Q12. What is the difference between optimistic and pessimistic concurrency?
**Answer:**
```
Optimistic concurrency:
  - No locks acquired during read
  - At save time: check if data changed since read
  - If changed: throw ConcurrencyException (client must retry)
  - Best for: low-contention scenarios (most web apps)
  - EF Core: [Timestamp] / [ConcurrencyCheck] attributes

Pessimistic concurrency:
  - Lock the row when reading (SELECT ... WITH (UPDLOCK))
  - Other transactions must wait
  - At save: no conflict possible (row was locked)
  - Best for: high-contention, critical operations (bank transfers)
```

```csharp
// Optimistic in EF Core
[Timestamp] public byte[] RowVersion { get; set; } = [];

try { await _db.SaveChangesAsync(); }
catch (DbUpdateConcurrencyException ex) {
    var entry = ex.Entries.Single();
    var db = await entry.GetDatabaseValuesAsync(); // current DB state
    entry.OriginalValues.SetValues(db!); // refresh — user must retry
    throw new ConflictException("Data was modified by another user");
}
```

---

## Q13. What are database constraints and how are they defined in EF Core?
**Answer:**
```csharp
mb.Entity<User>(e => {
    // NOT NULL
    e.Property(u => u.Email).IsRequired();

    // UNIQUE constraint
    e.HasIndex(u => u.Email).IsUnique();

    // CHECK constraint
    e.HasCheckConstraint("CK_User_Age", "[Age] >= 0 AND [Age] <= 120");
    e.HasCheckConstraint("CK_User_Email", "[Email] LIKE '%@%.%'");

    // DEFAULT value
    e.Property(u => u.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
    e.Property(u => u.IsActive).HasDefaultValue(true);

    // MAX LENGTH
    e.Property(u => u.Name).HasMaxLength(100);

    // FOREIGN KEY with cascade behavior
    e.HasMany(u => u.Orders).WithOne(o => o.User)
     .HasForeignKey(o => o.UserId).OnDelete(DeleteBehavior.Restrict);
});
```

---

## Q14. How do you handle large text and binary data in databases?
**Answer:**
```csharp
// Large text — NVARCHAR(MAX) in SQL Server
mb.Entity<Article>().Property(a => a.Content).HasColumnType("nvarchar(max)");

// Binary data — consider storing in blob storage, save URL in DB
public class Document {
    public int Id { get; set; }
    public string FileName { get; set; } = "";
    public string BlobUrl { get; set; } = "";     // URL to Azure Blob Storage
    public long FileSizeBytes { get; set; }
    public string ContentType { get; set; } = "";
}

// If must store in DB — VARBINARY(MAX)
mb.Entity<Document>().Property(d => d.Content).HasColumnType("varbinary(max)");

// For small binary data (< 8KB) — consider using:
mb.Entity<User>().Property(u => u.AvatarThumbnail).HasColumnType("varbinary(1024)");
```

---

## Q15. What is database sharding and when is it needed?
**Answer:**
Sharding horizontally partitions data across multiple database instances — each shard holds a subset of rows:

```
Without sharding (1 database):
  Users table: 1 billion rows → slow queries, storage limits

With sharding (horizontal partitioning):
  Shard 1 (userId % 3 == 0): Users 0, 3, 6, 9...
  Shard 2 (userId % 3 == 1): Users 1, 4, 7, 10...
  Shard 3 (userId % 3 == 2): Users 2, 5, 8, 11...
```

**Sharding strategies:**
- **Range-based:** User 1-1M on Shard 1, 1M-2M on Shard 2.
- **Hash-based:** `userId % shardCount` — even distribution.
- **Directory-based:** Lookup table maps key → shard.

**Before sharding, try:**
- Read replicas for read scaling.
- Caching (Redis).
- Query optimization.
- Table partitioning (within a single database).

Sharding adds significant complexity — a last resort for massive scale.
