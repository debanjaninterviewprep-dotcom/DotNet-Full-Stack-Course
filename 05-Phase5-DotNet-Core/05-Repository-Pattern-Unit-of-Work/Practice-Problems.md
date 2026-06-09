# Practice Problems: Repository Pattern & Unit of Work

---

## Problem 1: Generic Repository Implementation ⭐ Easy

**Objective**: Build a console app that implements the Generic Repository pattern with an in-memory data store.

### Requirements:
1. Create `IGenericRepository<T>` with: GetById, GetAll, Find(predicate), Add, Update, Remove, Count
2. Create `InMemoryRepository<T>` using `List<T>` as storage
3. Create entities: `Product` and `Category` with IDs
4. Demonstrate all CRUD operations with both entity types using the same generic repo
5. Show how the same interface works for different entity types

### Expected Output:
```
=== Generic Repository Pattern ===

--- ProductRepository (IGenericRepository<Product>) ---
Add: Product { Id: 1, Name: "Laptop", Price: 999.99 } → Added
Add: Product { Id: 2, Name: "Mouse", Price: 29.99 }   → Added
GetAll: 2 products
Find(p => p.Price > 100): [Laptop]
GetById(1): Laptop ($999.99)
Update: Laptop price → $1099.99
Remove: Mouse removed
Count: 1

--- CategoryRepository (IGenericRepository<Category>) ---
(same interface, different entity!)
Add: Category { Id: 1, Name: "Electronics" } → Added
GetAll: 1 category
```

---

## Problem 2: Specific Repository with Complex Queries ⭐⭐ Easy-Medium

**Objective**: Build a console app with specific repositories that extend the generic repo with entity-specific queries including search, filtering, and pagination.

### Requirements:
1. Extend `IGenericRepository<Product>` as `IProductRepository` with:
   - `GetByCategoryAsync`, `SearchAsync`, `GetActiveAsync`, `GetPagedAsync`
2. Implement pagination returning `PagedResult<T>` (Items, Page, PageSize, TotalCount, TotalPages)
3. Populate 30+ products across multiple categories
4. Demonstrate all specific queries with filtering and sorting
5. Show pagination across 3 pages

### Expected Output:
```
=== Specific Repository with Queries ===

--- Search: "lap" ---
Results: [Laptop, Laptop Stand, Laptop Bag] (3 items)

--- Filter: Category = "Electronics", Active only ---
Results: 12 active electronics products

--- Paginated: Page 1, Size 5, Category = "Electronics" ---
Page 1 of 3 (12 total)
  [1] Laptop — $999.99
  [2] Monitor — $349.99
  [3] Keyboard — $79.99
  [4] Mouse — $29.99
  [5] Webcam — $89.99
HasPrevious: false, HasNext: true
```

---

## Problem 3: Unit of Work with Transaction Management ⭐⭐ Medium

**Objective**: Build a console app implementing the Unit of Work pattern that coordinates multiple repositories with transaction support.

### Requirements:
1. Create `IUnitOfWork` with: Products, Categories, Orders properties and SaveChanges, BeginTransaction, Commit, Rollback
2. Implement order creation that:
   - Creates an order record
   - Creates order items
   - Decrements product stock
   - All within a single transaction
3. Demonstrate successful commit (all operations succeed)
4. Demonstrate rollback (insufficient stock → rollback entire order)
5. Show that SaveChanges commits ALL repo changes atomically

### Expected Output:
```
=== Unit of Work Pattern ===

--- Successful Order Creation ---
[Transaction] BEGIN
  _unitOfWork.Orders.Add(Order #1)
  _unitOfWork.Products.Update(Laptop: stock 10 → 8)
  _unitOfWork.Products.Update(Mouse: stock 50 → 49)
  _unitOfWork.SaveChanges() → 3 operations committed
[Transaction] COMMIT ✓

Product stock after: Laptop=8, Mouse=49

--- Failed Order (Insufficient Stock) ---
[Transaction] BEGIN
  _unitOfWork.Orders.Add(Order #2)
  _unitOfWork.Products.Update(Laptop: stock 8 → -2) ← ✗ Negative!
  ✗ BusinessException: Insufficient stock for Laptop (need 10, have 8)
[Transaction] ROLLBACK ✗

Product stock after: Laptop=8 (unchanged!), Mouse=49 (unchanged!)
Order #2: NOT created
```

---

## Problem 4: Specification Pattern ⭐⭐ Medium-Hard

**Objective**: Build a console app that implements the Specification Pattern for composable, reusable query criteria.

### Requirements:
1. Create abstract `Specification<T>` with `ToExpression()` returning `Expression<Func<T, bool>>`
2. Implement AND, OR, NOT composition operators
3. Create product specifications: ActiveProductSpec, CategorySpec, PriceRangeSpec, InStockSpec, SearchSpec
4. Demonstrate composing complex queries from simple specs
5. Apply specs in the repository's `FindAsync(spec)` method

### Expected Output:
```
=== Specification Pattern ===

--- Simple Specifications ---
ActiveProductSpec: 18 products match
CategorySpec("Electronics"): 8 products match
PriceRangeSpec(50, 500): 12 products match

--- Composed Specifications ---
Active AND Electronics: 7 products
Active AND Electronics AND PriceRange(50, 500): 4 products
  [1] Keyboard — $79.99 (Electronics, Active)
  [2] Webcam — $89.99 (Electronics, Active)
  [3] Monitor — $349.99 (Electronics, Active)
  [4] Headphones — $149.99 (Electronics, Active)

Active AND (Electronics OR Books): 11 products
NOT(Active): 2 products (inactive ones)
InStock AND Active AND Search("wireless"): 2 products
```

---

## Problem 5: Complete Data Access Layer ⭐⭐⭐ Hard

**Objective**: Build a console app that implements a complete data access layer with Generic Repository, Specific Repositories, Unit of Work, Specifications, and handles a multi-step business workflow.

### Requirements:
1. **Entities**: Product, Category, Customer, Order, OrderItem (with relationships)
2. **Generic Repository**: Full CRUD with async support
3. **Specific Repos**: ProductRepository (search, filter, paged), OrderRepository (by customer, by date range, with items)
4. **Unit of Work**: Coordinates all repos with transaction support
5. **Specifications**: At least 5 composable specs
6. **Business Workflow**: Process 5 operations:
   - Create a customer
   - Browse products with specs (active + category + price range)
   - Create an order (with validation, stock deduction, in transaction)
   - Get order history for customer (with included items)
   - Generate sales report (grouped by category)

### Expected Output:
```
=== Complete Data Access Layer ===

[Setup] Seeded: 5 categories, 30 products, 5 customers

━━━ Step 1: Create Customer ━━━
_unitOfWork.Customers.Add("Alice Johnson")
_unitOfWork.SaveChanges()
→ Customer #6 created

━━━ Step 2: Browse Products ━━━
Spec: Active AND Electronics AND PriceRange(50, 200)
_unitOfWork.Products.FindBySpec(spec)
→ 4 products found:
  [3] Wireless Mouse — $49.99 (stock: 100)
  [5] Mechanical Keyboard — $129.99 (stock: 45)
  [8] USB-C Hub — $59.99 (stock: 80)
  [12] Webcam HD — $89.99 (stock: 30)

━━━ Step 3: Create Order (Transaction) ━━━
[Transaction] BEGIN
  Create Order #1 for Customer #6
  Add item: Wireless Mouse × 2 = $99.98
  Add item: Webcam HD × 1 = $89.99
  Update stock: Wireless Mouse 100→98, Webcam HD 30→29
  Calculate total: $189.97
  _unitOfWork.SaveChanges() → 4 operations
[Transaction] COMMIT ✓

━━━ Step 4: Order History ━━━
_unitOfWork.Orders.GetByCustomerWithItemsAsync(6)
→ Customer: Alice Johnson
  Order #1 (2026-04-25): $189.97
    - Wireless Mouse × 2 = $99.98
    - Webcam HD × 1 = $89.99

━━━ Step 5: Sales Report ━━━
_unitOfWork.Orders.GetSalesReportAsync()
→ Sales by Category:
  Electronics: 15 orders, $8,234.50 total
  Clothing: 8 orders, $1,245.00 total
  Books: 12 orders, $567.80 total
  Total Revenue: $10,047.30
```
