# Topic 13: LINQ — Interview Questions

---

## Q1. What is LINQ and what are its main benefits?
**Answer:**
LINQ (Language Integrated Query) is a set of features in C# that lets you query collections, databases, XML, and other data sources using a unified, compile-time-checked syntax.

Benefits:
- **Type safety** — queries are checked at compile time.
- **Readability** — SQL-like syntax close to the problem domain.
- **Consistency** — the same query model works over any `IEnumerable<T>` or `IQueryable<T>`.
- **Composability** — queries are built as expression chains.

There are two equivalent syntaxes:
```csharp
// Query syntax
var result = from n in numbers where n > 5 orderby n select n * 2;

// Method (fluent) syntax — more commonly used
var result = numbers.Where(n => n > 5).OrderBy(n => n).Select(n => n * 2);
```

---

## Q2. What is deferred execution in LINQ?
**Answer:**
Most LINQ operators do **not execute** when the query is defined — they execute when the result is **iterated** (e.g., in a `foreach`, or when calling `ToList()`, `ToArray()`, `Count()`, `First()`).

```csharp
var query = numbers.Where(n => n > 5); // defines query — NO execution yet

numbers.Add(10);   // modifying source AFTER query definition

foreach (var n in query) // executes NOW — includes 10
    Console.WriteLine(n);
```

This is why calling `.ToList()` is important when you need a snapshot of the data, or when the source might change.

**Immediate execution operators:** `ToList`, `ToArray`, `ToDictionary`, `Count`, `Sum`, `Max`, `Min`, `Average`, `First`, `Single`, `Any`, `All`, `ElementAt`.

---

## Q3. What is the difference between `IEnumerable<T>` and `IQueryable<T>`?
**Answer:**
| | `IEnumerable<T>` | `IQueryable<T>` |
|---|---|---|
| **Execution** | In-memory (LINQ to Objects) | Translated to query language (SQL, etc.) |
| **Expression trees** | No — delegates | Yes — builds expression trees |
| **Use case** | In-memory collections | Databases (EF Core), remote data sources |
| **Where** | Filter runs in application | Filter runs in the database |

```csharp
// IEnumerable — loads ALL rows, then filters in memory
var result = dbContext.Users.AsEnumerable().Where(u => u.Age > 18);

// IQueryable — translates to WHERE clause in SQL
var result = dbContext.Users.Where(u => u.Age > 18); // SELECT ... WHERE Age > 18
```

**Rule:** Always use `IQueryable<T>` when querying a database. Use `IEnumerable<T>` for in-memory collections.

---

## Q4. What is the difference between `First()`, `FirstOrDefault()`, `Single()`, and `SingleOrDefault()`?
**Answer:**
| Method | If no match | If multiple matches |
|---|---|---|
| `First()` | `InvalidOperationException` | Returns first |
| `FirstOrDefault()` | Returns `default(T)` (null/0) | Returns first |
| `Single()` | `InvalidOperationException` | `InvalidOperationException` |
| `SingleOrDefault()` | Returns `default(T)` | `InvalidOperationException` |

```csharp
var user = users.First(u => u.Id == 1);           // assumes at least one exists
var user = users.FirstOrDefault(u => u.Id == 99); // returns null if not found

var admin = users.Single(u => u.Role == "Admin");  // assumes exactly one admin
```

Use `Single` when the domain rule guarantees exactly one match (primary key lookup). Use `First` when you want the first of potentially many.

---

## Q5. What is the difference between `Select()` and `SelectMany()`?
**Answer:**
- `Select()` — projects each element to a new value (1-to-1 mapping).
- `SelectMany()` — projects each element to a **sequence**, then **flattens** all sequences into one (1-to-many flattening).

```csharp
// Select — each order maps to its ID
var ids = orders.Select(o => o.Id);  // IEnumerable<int>

// SelectMany — each order has many items; flatten all items
var allItems = orders.SelectMany(o => o.Items); // IEnumerable<OrderItem>

// Equivalent loop:
// foreach order → foreach item in order.Items → yield item
```

---

## Q6. What does `GroupBy()` return and how do you use it?
**Answer:**
`GroupBy()` returns `IEnumerable<IGrouping<TKey, TElement>>`. Each `IGrouping` has a `Key` and is itself an `IEnumerable<TElement>`.

```csharp
var grouped = employees.GroupBy(e => e.Department);

foreach (var group in grouped)
{
    Console.WriteLine($"Dept: {group.Key}");
    foreach (var emp in group)
        Console.WriteLine($"  {emp.Name}");
}

// With projection
var summary = employees
    .GroupBy(e => e.Department)
    .Select(g => new
    {
        Department = g.Key,
        Count = g.Count(),
        AvgSalary = g.Average(e => e.Salary)
    });
```

---

## Q7. What is the difference between `Any()`, `All()`, and `Contains()`?
**Answer:**
- `Any()` — returns `true` if **at least one** element satisfies the predicate (or if the sequence is non-empty).
- `All()` — returns `true` if **all** elements satisfy the predicate.
- `Contains()` — checks if the sequence contains a specific value (uses `Equals`).

```csharp
var nums = new[] { 1, 2, 3, 4, 5 };

nums.Any()             // true — not empty
nums.Any(n => n > 4)   // true — 5 exists
nums.All(n => n > 0)   // true — all positive
nums.All(n => n > 3)   // false — 1, 2, 3 fail
nums.Contains(3)       // true
```

`Any()` short-circuits on the first match. `All()` short-circuits on the first failure.

---

## Q8. How do `Join()` and `GroupJoin()` work in LINQ?
**Answer:**
- `Join()` — equivalent to SQL INNER JOIN. Returns matching pairs.
- `GroupJoin()` — equivalent to SQL LEFT OUTER JOIN. Groups right-side elements under each left-side element.

```csharp
// Inner join
var result = orders.Join(
    customers,
    o => o.CustomerId,
    c => c.Id,
    (o, c) => new { o.Id, c.Name }
);

// Left outer join via GroupJoin + SelectMany
var leftJoin = customers.GroupJoin(
    orders,
    c => c.Id,
    o => o.CustomerId,
    (c, orderGroup) => new { Customer = c, Orders = orderGroup }
);
```

---

## Q9. What is the difference between `OrderBy()` and `ThenBy()`?
**Answer:**
- `OrderBy()` / `OrderByDescending()` — sorts by a primary key.
- `ThenBy()` / `ThenByDescending()` — sorts by a secondary key (applied to already-sorted result).

```csharp
var sorted = employees
    .OrderBy(e => e.Department)
    .ThenBy(e => e.LastName)
    .ThenByDescending(e => e.Salary);
```

Do not chain multiple `OrderBy()` calls — each one resets the sort from scratch. Always use `ThenBy()` for secondary sorts.

---

## Q10. What is the difference between `Where()` + `Select()` and using a single `Select()` with a condition?
**Answer:**
`Where` filters; `Select` projects (transforms). Use `Where` before `Select` to avoid transforming elements that will be discarded:

```csharp
// Correct order — filter first, then project
var names = people.Where(p => p.IsActive).Select(p => p.Name);

// Less efficient — projects everything, then filters (not valid, Filter on result type)
// var names = people.Select(p => p.Name).Where(name => ...);

// Never do: filter inside select (works but breaks readability and optimization)
var names = people.Select(p => p.IsActive ? p.Name : null).Where(n => n != null);
```

When using `IQueryable<T>` (EF Core), the order is translated to SQL — `Where` first is still preferred for clarity but the query optimizer may reorder anyway.

---

## Q11. What is the `Aggregate()` method?
**Answer:**
`Aggregate` applies a function cumulatively over a sequence, effectively implementing a custom fold/reduce:

```csharp
int[] numbers = { 1, 2, 3, 4, 5 };

// Sum manually: ((((1+2)+3)+4)+5) = 15
int sum = numbers.Aggregate((acc, next) => acc + next); // 15

// With seed: start at 10
int result = numbers.Aggregate(10, (acc, next) => acc + next); // 25

// With result selector
string sentence = new[] {"Hello", "World", "!"}.
    Aggregate("", (acc, s) => acc + " " + s).Trim();
// "Hello World !"

// Running factorial: 5! = 120
int factorial = Enumerable.Range(1, 5).Aggregate(1, (acc, n) => acc * n);
```

---

## Q12. What is `Zip()` and when do you use it?
**Answer:**
`Zip` merges two (or three in .NET 6+) sequences element-by-element, stopping at the shortest:

```csharp
var names  = new[] { "Alice", "Bob", "Charlie" };
var scores = new[] { 90, 85, 92 };

// Pair elements from two sequences
var pairs = names.Zip(scores, (name, score) => $"{name}: {score}");
// ["Alice: 90", "Bob: 85", "Charlie: 92"]

// Tuple shorthand (C# 8+)
var tuples = names.Zip(scores); // IEnumerable<(string, int)>

// Three sequences (.NET 6+)
var ids = new[] { 1, 2, 3 };
var result = names.Zip(scores, ids); // IEnumerable<(string, int, int)>
```

---

## Q13. What is the difference between `ToDictionary()` and `ToLookup()`?
**Answer:**
- **`ToDictionary()`** — one-to-one mapping. Throws if duplicate keys exist.
- **`ToLookup()`** — one-to-many mapping. Each key maps to a group of values. Never throws on duplicates. Immutable after creation.

```csharp
var employees = GetEmployees();

// ToDictionary — fails if two employees share an ID
var byId = employees.ToDictionary(e => e.Id); // must be unique keys

// ToLookup — multiple employees per department
var byDept = employees.ToLookup(e => e.Department);
foreach (var emp in byDept["Engineering"])
    Console.WriteLine(emp.Name);

// Key not found returns an empty group (no exception)
var missing = byDept["Nonexistent"]; // empty, not null
```

`ToLookup` is essentially an immutable `Dictionary<K, IEnumerable<V>>`.

---

## Q14. What is PLINQ (Parallel LINQ)?
**Answer:**
PLINQ automatically parallelizes LINQ queries across multiple CPU cores using the thread pool:

```csharp
// Sequential LINQ
var result = data.Where(IsValid).Select(Transform).ToList();

// Parallel LINQ — add .AsParallel()
var result = data.AsParallel()
                  .Where(IsValid)
                  .Select(Transform)
                  .ToList();

// Preserve order (at cost of some parallelism)
var ordered = data.AsParallel()
                  .AsOrdered()
                  .Select(Transform)
                  .ToList();

// Limit degree of parallelism
var limited = data.AsParallel()
                  .WithDegreeOfParallelism(4)
                  .Select(Transform)
                  .ToList();
```

Use PLINQ only for **CPU-bound** work that takes meaningful time per element. The overhead of partitioning and thread synchronization makes it counter-productive for fast operations or small collections.

---

## Q15. What are the new LINQ methods introduced in .NET 6+?
**Answer:**
**.NET 6 additions:**
```csharp
// DistinctBy — distinct by a key
people.DistinctBy(p => p.LastName);

// MinBy / MaxBy — element with min/max key
var youngest = people.MinBy(p => p.Age);
var oldest   = people.MaxBy(p => p.Age);

// Chunk — split into batches
var batches = numbers.Chunk(100); // IEnumerable<int[]> of length 100

// UnionBy, IntersectBy, ExceptBy
people1.UnionBy(people2, p => p.Id); // union without duplicates by Id
```

**.NET 9 additions:**
```csharp
// CountBy — count elements by key
var departmentCounts = employees.CountBy(e => e.Department);
// IEnumerable<KeyValuePair<string, int>>

// AggregateBy — aggregate by key
var totalSalaryByDept = employees.AggregateBy(
    e => e.Department,
    0m,
    (acc, e) => acc + e.Salary);
```
