# Topic 17: Generics — Practice Problems

## Problem 1: Generic Utility Methods (Easy)
**Concept**: Generic methods, type parameters, constraints

Create a static `GenericUtils` class with these methods:

1. `Swap<T>(ref T a, ref T b)` — swap two values of any type
2. `FindMax<T>(T[] items) where T : IComparable<T>` — find maximum in an array
3. `FindMin<T>(T[] items) where T : IComparable<T>` — find minimum
4. `Contains<T>(T[] items, T target) where T : IEquatable<T>` — check if item exists
5. `CountOccurrences<T>(T[] items, T target) where T : IEquatable<T>` — count matches
6. `Reverse<T>(T[] items)` — reverse array in-place
7. `PrintAll<T>(IEnumerable<T> items, string separator = ", ")` — print items

Test each method with at least 2 different types (int + string, etc.)

**Expected Output:**
```
=== Generic Utilities ===

--- Swap ---
Before: x=10, y=20 → After: x=20, y=10
Before: a="Hello", b="World" → After: a="World", b="Hello"

--- FindMax / FindMin ---
[5, 2, 8, 1, 9, 3] → Max: 9, Min: 1
["Banana", "Apple", "Cherry"] → Max: Cherry, Min: Apple

--- Contains ---
[10, 20, 30, 40] contains 30? True
["C#", "Java", "Python"] contains "Go"? False

--- CountOccurrences ---
[1, 2, 3, 2, 4, 2, 5] count of 2: 3

--- Reverse ---
[1, 2, 3, 4, 5] → [5, 4, 3, 2, 1]
```

---

## Problem 2: Generic Collection — SmartList\<T\> (Easy-Medium)
**Concept**: Generic class, IEnumerable\<T\>, indexer, constraints

Build a `SmartList<T>` that wraps `List<T>` with extra features:

**Properties & Methods:**
- `Count`, `IsEmpty` properties
- `Add(T item)`, `Remove(T item)`, `Clear()`
- `this[int index]` — indexer with bounds checking
- `First`, `Last` — properties for first/last elements (throw if empty)
- `Sorted()` — return new sorted `SmartList<T>` (requires `T : IComparable<T>`)
- `Where(Predicate<T> condition)` — return filtered `SmartList<T>`
- `ForEach(Action<T> action)` — apply action to each element
- `Map<TResult>(Func<T, TResult> transform)` — transform to new `SmartList<TResult>`
- `Reduce<TResult>(TResult seed, Func<TResult, T, TResult> accumulator)`
- Implement `IEnumerable<T>` so it works with `foreach`
- Override `ToString()` — display as `[item1, item2, item3]`

**Expected Output:**
```
=== SmartList<T> ===

var numbers = new SmartList<int> { 5, 2, 8, 1, 9, 3 };
Count: 6 | First: 5 | Last: 3
Sorted: [1, 2, 3, 5, 8, 9]
Evens: [2, 8]
Doubled: [10, 4, 16, 2, 18, 6]
Sum (Reduce): 28

var names = new SmartList<string> { "Charlie", "Alice", "Bob" };
Sorted: [Alice, Bob, Charlie]
Uppercase: [CHARLIE, ALICE, BOB]
Contains 'A': [Alice]

foreach works: Charlie, Alice, Bob
```

---

## Problem 3: Generic Repository Pattern (Medium)
**Concept**: Generic interface, generic class, constraints, CRUD pattern

Build a complete repository system:

**Interfaces:**
```csharp
interface IEntity { int Id { get; set; } }
interface IRepository<T> where T : IEntity
{
    T? GetById(int id);
    List<T> GetAll();
    List<T> Find(Func<T, bool> predicate);
    void Add(T entity);
    void Update(T entity);
    bool Delete(int id);
    int Count { get; }
}
```

**InMemoryRepository\<T\>** — generic implementation that works for ANY entity:
- Stores entities in `Dictionary<int, T>`
- Auto-increments ID on Add (if ID is 0)
- All CRUD operations with proper error handling
- `Find` method accepts a predicate for flexible queries

**Entity Classes (all implement IEntity):**
- `Employee` { Id, Name, Department, Salary }
- `Product` { Id, Name, Category, Price, Stock }
- `Order` { Id, CustomerId, ProductId, Quantity, OrderDate }

**Demo Program:**
1. Create `InMemoryRepository<Employee>`, `InMemoryRepository<Product>`, `InMemoryRepository<Order>`
2. Add sample data to each
3. Perform queries: find employees by department, products under a price, orders by customer
4. Update and delete operations
5. Show that ONE repository class handles ALL three entity types

**Expected Output:**
```
=== Generic Repository ===

--- Employee Repository ---
Added: Debanjan (Engineering, $85,000)
Added: Alice (Marketing, $72,000)
Added: Bob (Engineering, $95,000)

Find by department "Engineering":
  #1 Debanjan — $85,000
  #3 Bob — $95,000

--- Product Repository (same class!) ---
Added: Laptop ($999.99, 50 in stock)
Added: Mouse ($29.99, 200 in stock)

Find products under $100:
  #2 Mouse — $29.99

--- Order Repository (same class!) ---
Find orders by customer #1:
  Order #1: Product #1, Qty: 2 (2026-04-01)
  Order #3: Product #2, Qty: 5 (2026-04-03)

Total entities: Employees: 3, Products: 2, Orders: 3
```

---

## Problem 4: Generic Pipeline & Middleware (Medium-Hard)  
**Concept**: Generic delegates, Func chaining, generic constraints, builder pattern

Build a generic data processing pipeline (extending Topic 14's concept with full generics):

**Pipeline\<T\> Class:**
```csharp
class Pipeline<T>
{
    // Chain of Func<T, T> steps
    Pipeline<T> AddStep(Func<T, T> step);
    Pipeline<T> AddStep(Func<T, T> step, string name); // Named steps for logging
    Pipeline<T> AddConditionalStep(Predicate<T> condition, Func<T, T> step, string name);
    Pipeline<T> AddValidator(Predicate<T> validator, string errorMessage);
    T Execute(T input);
    PipelineResult<T> ExecuteWithLog(T input); // Returns result + execution log
}
```

**PipelineResult\<T\>:**
```csharp
class PipelineResult<T>
{
    T Result;
    bool IsSuccess;
    List<string> Log;         // Step-by-step log
    List<string> Errors;      // Validation errors
    TimeSpan TotalTime;
}
```

**Build These Pipelines:**

1. **String Processing Pipeline\<string\>**:
   - Trim → Lowercase → Remove punctuation → Collapse whitespace → URL-encode spaces
   
2. **Number Pipeline\<double\>**:
   - Validate (> 0) → Square root → Round to 2 decimals → Validate (< 1000)

3. **Order Processing Pipeline\<Order\>** (generic class with entity):
   - Validate (quantity > 0) → Apply discount → Calculate tax → Calculate total → Validate (total < $10,000)

4. **Composable Pipelines**: Combine Pipeline A + Pipeline B into Pipeline C

5. **Generic Middleware\<T\>**: Create `Middleware<T>` where each middleware wraps the next:
   ```csharp
   var middleware = new MiddlewareBuilder<Request>()
       .Use(LoggingMiddleware)
       .Use(AuthenticationMiddleware)
       .Use(ValidationMiddleware)
       .Build();
   ```

**Expected Output:**
```
=== Generic Pipeline ===

--- String Pipeline ---
Input: "  Hello, World!!!   "
  [Trim] → "Hello, World!!!"
  [Lowercase] → "hello, world!!!"
  [RemovePunctuation] → "hello world"
  [CollapseSpaces] → "hello world"
  [UrlEncode] → "hello%20world"
Result: "hello%20world"
Steps: 5 | Time: 0.2ms | ✓ Success

--- Order Pipeline ---
Input: Order { Product: "Laptop", Qty: 2, UnitPrice: $999.99 }
  [Validate] ✓ Quantity valid
  [Discount] 10% off → $899.99/unit
  [Tax] 8.5% → $152.999/unit
  [Total] $2,105.98
  [Validate] ✓ Under $10,000 limit
Result: Order { Total: $2,105.98 }

--- Failed Pipeline ---
Input: Order { Qty: -1 }
  [Validate] ✗ FAILED: Quantity must be positive
Result: FAILED with 1 error(s)
```

---

## Problem 5: TaskFlow Generic Service Layer (Hard)
**Concept**: All generics concepts — generic repository, services, constraints, delegates, events

Build a complete generic service layer for TaskFlow:

**Generic Base Classes:**
```csharp
interface IEntity { int Id { get; set; } DateTime CreatedAt { get; set; } }
interface IAuditable { DateTime? ModifiedAt { get; set; } string? ModifiedBy { get; set; } }

class GenericService<T> where T : class, IEntity, new()
{
    // CRUD with validation, events, and logging
    event EventHandler<EntityEventArgs<T>> EntityCreated;
    event EventHandler<EntityEventArgs<T>> EntityUpdated;
    event EventHandler<EntityEventArgs<T>> EntityDeleted;
    
    void Add(T entity, Func<T, bool>? validator = null);
    void Update(T entity, Func<T, bool>? validator = null);
    // ...
}
```

**Entity Classes:**
- `Project : IEntity, IAuditable` { Id, Name, Description, Status, Budget, CreatedAt, ... }
- `TaskItem : IEntity, IAuditable` { Id, Title, ProjectId, AssigneeId, Priority, Status, ... }
- `User : IEntity` { Id, Name, Email, Role, CreatedAt }

**Generic Features to Implement:**

1. **GenericRepository\<T\>** — in-memory CRUD (from Problem 3)
2. **GenericService\<T\>** — business logic layer:
   - Wraps repository with validation
   - Fires events on create/update/delete
   - Accepts `Func<T, bool>` validators (custom per entity)
   - Tracks audit info for IAuditable entities
3. **GenericQueryBuilder\<T\>** — chainable query builder:
   ```csharp
   var results = queryBuilder
       .Where(t => t.Status == "Active")
       .OrderBy(t => t.CreatedAt)
       .Take(10)
       .Execute();
   ```
4. **GenericEventBus\<T\>** — generic pub/sub for events
5. **GenericValidator\<T\>** — composable validation rules:
   ```csharp
   var validator = new GenericValidator<TaskItem>()
       .AddRule(t => !string.IsNullOrEmpty(t.Title), "Title is required")
       .AddRule(t => t.Priority >= 1 && t.Priority <= 3, "Priority must be 1-3")
       .AddRule(t => t.ProjectId > 0, "Must belong to a project");
   ```

**Demonstrate:**
1. Create services for Project, TaskItem, and User — all using the SAME generic classes
2. Add validation rules specific to each entity
3. Subscribe to events (audit logging, notifications)
4. Perform CRUD operations, queries, and show the power of generics

**Expected Output:**
```
=== TaskFlow Generic Service Layer ===

--- Setup ---
✓ ProjectService<Project> created with 2 validation rules
✓ TaskService<TaskItem> created with 4 validation rules
✓ UserService<User> created with 3 validation rules
✓ Event subscribers registered

--- Operations ---
[Create] Project "TaskFlow API" → ✓ Valid → 🔔 EntityCreated fired
  📝 Audit: Created Project #1 at 2026-04-04 10:30:00

[Create] Task "Build endpoints" (Project #1) → ✓ Valid → 🔔 EntityCreated fired
[Create] Task "" (Project #1) → ✗ Validation failed: "Title is required"

[Query] Active tasks in Project #1:
  Using GenericQueryBuilder<TaskItem>:
    .Where(Status == "Active")
    .Where(ProjectId == 1)
    .OrderBy(Priority DESC)
  Results: 3 tasks found

--- Statistics (all via generics) ---
  GenericService<Project>: 3 entities, 1 event subscriber
  GenericService<TaskItem>: 8 entities, 2 event subscribers
  GenericService<User>: 4 entities, 1 event subscriber
```

---

### Submission
- Create a new console project: `dotnet new console -n GenericsPractice`
- Solve all 5 problems in `Program.cs`
- Use proper generic constraints for type safety
- Avoid using `object` — use generics everywhere
- Tell me "check" when you're ready for review!
