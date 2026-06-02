# Practice Problems: Entity Framework Core & SQL Server

---

## Problem 1: In-Memory ORM Simulator ⭐ Easy

**Objective**: Build a console app that simulates EF Core's basic operations using in-memory collections with change tracking.

### Requirements:
1. Create a `SimpleDbContext` with `DbSet<T>` simulated as `List<T>` with change tracking
2. Implement entity states: Added, Unchanged, Modified, Deleted
3. Implement `Add()`, `Find()`, `Update()`, `Remove()`, `SaveChanges()`
4. `SaveChanges()` processes all tracked changes and prints the SQL it would generate
5. Demonstrate CRUD operations on `Product` and `Category` entities

### Expected Output:
```
=== In-Memory ORM Simulator ===

--- Add Products ---
context.Products.Add(Laptop)  → State: Added
context.Products.Add(Mouse)   → State: Added
context.SaveChanges()
  Generated SQL: INSERT INTO Products (Name, Price) VALUES ('Laptop', 999.99)
  Generated SQL: INSERT INTO Products (Name, Price) VALUES ('Mouse', 29.99)
  2 rows affected.

--- Find & Modify ---
var product = context.Products.Find(1)  → State: Unchanged
product.Price = 1099.99                  → State: Modified
context.SaveChanges()
  Generated SQL: UPDATE Products SET Price = 1099.99 WHERE Id = 1
  1 row affected.

--- Delete ---
context.Products.Remove(product)  → State: Deleted
context.SaveChanges()
  Generated SQL: DELETE FROM Products WHERE Id = 1
  1 row affected.
```

---

## Problem 2: LINQ-to-SQL Translator ⭐⭐ Easy-Medium

**Objective**: Build a console app that takes LINQ method chain operations and translates them into SQL query strings.

### Requirements:
1. Create an in-memory `Product` table with 20+ items
2. Implement a `QueryBuilder<T>` that chains these operations:
   - `Where(predicate)` → `WHERE` clause
   - `OrderBy(property)` / `OrderByDescending(property)` → `ORDER BY`
   - `Select(columns)` → `SELECT` specific columns
   - `Skip(n)` / `Take(n)` → `OFFSET/FETCH` (pagination)
   - `Include(navigation)` → `JOIN`
   - `GroupBy(property)` → `GROUP BY`
3. Print both the generated SQL and the query results
4. Execute at least 8 different queries

### Expected Output:
```
=== LINQ-to-SQL Translator ===

Query: Products.Where(p => p.Price > 100).OrderBy(p => p.Name)
SQL:   SELECT * FROM Products WHERE Price > 100 ORDER BY Name ASC
Results: [3 items] Keyboard($149.99), Laptop($999.99), Monitor($349.99)

Query: Products.Where(p => p.Category == "Electronics").Skip(0).Take(5)
SQL:   SELECT * FROM Products WHERE Category = 'Electronics' ORDER BY Id OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
Results: [5 items] ...

Query: Products.GroupBy(p => p.Category).Select(g => new { Category, Count, AvgPrice })
SQL:   SELECT Category, COUNT(*) AS Count, AVG(Price) AS AvgPrice FROM Products GROUP BY Category
Results: Electronics(8, $425.50), Clothing(6, $49.99), Books(4, $24.99)
```

---

## Problem 3: Migration System Simulator ⭐⭐ Medium

**Objective**: Build a console app that simulates EF Core's database migration system.

### Requirements:
1. Create a `MigrationManager` that tracks schema versions
2. Each migration has `Up()` and `Down()` methods
3. Implement these migrations in sequence:
   - `001_CreateProductsTable`: Creates Products table with columns
   - `002_AddCategoryColumn`: Adds Category column to Products
   - `003_CreateOrdersTable`: Creates Orders and OrderItems tables with foreign keys
   - `004_AddIndexes`: Adds indexes on frequently queried columns
   - `005_SeedData`: Inserts initial data
4. Support applying, reverting, and listing migrations
5. Show the SQL DDL each migration would generate

### Expected Output:
```
=== Migration System Simulator ===

Available Migrations:
  [x] 001_CreateProductsTable (applied)
  [x] 002_AddCategoryColumn (applied)
  [ ] 003_CreateOrdersTable (pending)
  [ ] 004_AddIndexes (pending)
  [ ] 005_SeedData (pending)

--- Applying: 003_CreateOrdersTable ---
Up():
  CREATE TABLE Orders (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    TotalAmount DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(Id)
  );
  CREATE TABLE OrderItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Products(Id)
  );
Migration applied successfully.

--- Reverting: 003_CreateOrdersTable ---
Down():
  DROP TABLE OrderItems;
  DROP TABLE Orders;
Migration reverted successfully.
```

---

## Problem 4: Relationship & Query Engine ⭐⭐ Medium-Hard

**Objective**: Build a console app that demonstrates all EF Core relationship types and complex queries with eager/lazy loading simulation.

### Requirements:
1. Create an in-memory database with these related entities:
   - `Customer` (1-to-many → Orders, 1-to-1 → Profile)
   - `Order` (many-to-1 → Customer, 1-to-many → OrderItems)
   - `OrderItem` (many-to-1 → Order, many-to-1 → Product)
   - `Product` (many-to-many → Tags, 1-to-many → Reviews)
2. Implement loading strategies:
   - Eager Loading: `Include(x => x.Orders).ThenInclude(o => o.Items)`
   - Lazy Loading: Load on first property access (with N+1 detection)
   - Explicit Loading: `LoadCollection()`, `LoadReference()`
3. Demonstrate the N+1 query problem and how to fix it
4. Execute complex queries: joins, grouping, subqueries

### Expected Output:
```
=== Relationship & Query Engine ===

--- Eager Loading ---
Query: Customers.Include(c => c.Orders).ThenInclude(o => o.Items)
SQL Queries Executed: 1
  SELECT c.*, o.*, i.* FROM Customers c
  LEFT JOIN Orders o ON c.Id = o.CustomerId
  LEFT JOIN OrderItems i ON o.Id = i.OrderId
Result: Customer "John" has 3 orders with 7 total items

--- N+1 Problem (Lazy Loading) ---
Query: foreach customer → access customer.Orders
SQL Queries Executed: 6  ⚠️ N+1 PROBLEM!
  SELECT * FROM Customers                    (1 query)
  SELECT * FROM Orders WHERE CustomerId = 1  (N queries...)
  SELECT * FROM Orders WHERE CustomerId = 2
  SELECT * FROM Orders WHERE CustomerId = 3
  SELECT * FROM Orders WHERE CustomerId = 4
  SELECT * FROM Orders WHERE CustomerId = 5

--- Fixed with Include ---
SQL Queries Executed: 1  ✓ 
  SELECT c.*, o.* FROM Customers c LEFT JOIN Orders o ON c.Id = o.CustomerId

--- Complex Query: Top customers by order value ---
SQL: SELECT c.Name, COUNT(o.Id) AS OrderCount, SUM(o.TotalAmount) AS TotalSpent
     FROM Customers c JOIN Orders o ON c.Id = o.CustomerId
     GROUP BY c.Name ORDER BY TotalSpent DESC

Results:
  1. John Doe — 5 orders, $4,523.99
  2. Jane Smith — 3 orders, $2,150.00
```

---

## Problem 5: Complete Database Layer Simulator ⭐⭐⭐ Hard

**Objective**: Build a console app that simulates a complete EF Core database layer with DbContext, entities, relationships, migrations, change tracking, queries, and transactions.

### Requirements:
1. **Schema**: Products, Categories, Customers, Orders, OrderItems with all relationships
2. **Migrations**: Create tables, add constraints, seed data (apply sequentially)
3. **Change Tracking**: Track entity states, detect modified properties, generate minimal UPDATE SQL
4. **Queries**: Implement 10+ queries including joins, group by, pagination, projection
5. **Transactions**: Simulate order creation that updates stock (commit on success, rollback on failure)
6. **Global Query Filters**: Soft delete filter that auto-excludes IsActive=false
7. **Process a full workflow**: Seed → Query → Create order → Update stock → Query again

### Expected Output:
```
=== Complete Database Layer Simulator ===

[Migrations] Applying 5 migrations...
  ✓ 001_CreateSchema: 5 tables created
  ✓ 002_AddIndexes: 4 indexes added
  ✓ 003_SeedCategories: 5 categories inserted
  ✓ 004_SeedProducts: 20 products inserted
  ✓ 005_SeedCustomers: 10 customers inserted

[Query] Active products by category:
  Electronics: 8 products, avg $425.50
  Clothing: 6 products, avg $49.99
  Books: 4 products, avg $24.99

[Transaction] Creating order for Customer #1...
  BEGIN TRANSACTION
  INSERT INTO Orders (...) → Order #1
  INSERT INTO OrderItems (...) → 3 items
  UPDATE Products SET StockQuantity = StockQuantity - 2 WHERE Id = 1
  UPDATE Products SET StockQuantity = StockQuantity - 1 WHERE Id = 5
  UPDATE Products SET StockQuantity = StockQuantity - 3 WHERE Id = 8
  COMMIT ✓

[Transaction] Creating order with insufficient stock...
  BEGIN TRANSACTION
  INSERT INTO Orders (...)
  UPDATE Products SET StockQuantity = ... → ✗ Stock insufficient for Product #3!
  ROLLBACK ✗ — Order not created

[Change Tracking] Modifying Product #1:
  State: Unchanged → Modified
  Changed Properties: Price (999.99 → 1099.99), UpdatedDate (null → 2026-04-25)
  SQL: UPDATE Products SET Price = 1099.99, UpdatedDate = '2026-04-25' WHERE Id = 1
  (Only modified columns in UPDATE — not all columns!)

[Global Filter] Soft-deleting Product #2...
  UPDATE Products SET IsActive = 0 WHERE Id = 2
  Query all products: 19 results (Product #2 hidden by filter)
  Query with IgnoreQueryFilters: 20 results (all products)
```

### Hints:
- Use `Dictionary<int, T>` per table for storage
- Track original and current values for change tracking
- Change tracking should compare property-by-property for minimal UPDATEs
- Transactions should use a "pending changes" buffer that's committed or discarded
