# Topic 13: LINQ (Language Integrated Query)

## What is LINQ?

LINQ lets you **query and transform data** using C# syntax — no matter where the data comes from (arrays, lists, databases, XML, JSON). It brings SQL-like power directly into your code.

```csharp
// Without LINQ — manual filtering
List<int> numbers = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
List<int> evens = new List<int>();
foreach (int n in numbers)
{
    if (n % 2 == 0)
        evens.Add(n);
}

// With LINQ — one expressive line
List<int> evens = numbers.Where(n => n % 2 == 0).ToList();
```

---

## Two LINQ Syntaxes

### Method Syntax (Fluent) — More Common

```csharp
var result = numbers
    .Where(n => n > 5)
    .OrderBy(n => n)
    .Select(n => n * 2);
```

### Query Syntax (SQL-like)

```csharp
var result = from n in numbers
             where n > 5
             orderby n
             select n * 2;
```

Both produce the same result. **Method syntax is preferred** in most C# projects because it's more flexible and chains better.

---

## Setting Up Sample Data

We'll use this data throughout the notes:

```csharp
public class Employee
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Department { get; set; } = "";
    public decimal Salary { get; set; }
    public int Age { get; set; }
    public DateTime JoinDate { get; set; }
}

List<Employee> employees = new List<Employee>
{
    new Employee { Id = 1, Name = "Debanjan", Department = "Engineering", Salary = 85000, Age = 25, JoinDate = new DateTime(2024, 3, 15) },
    new Employee { Id = 2, Name = "Alice", Department = "Engineering", Salary = 92000, Age = 30, JoinDate = new DateTime(2022, 7, 1) },
    new Employee { Id = 3, Name = "Bob", Department = "Marketing", Salary = 65000, Age = 28, JoinDate = new DateTime(2023, 1, 10) },
    new Employee { Id = 4, Name = "Charlie", Department = "Engineering", Salary = 105000, Age = 35, JoinDate = new DateTime(2020, 5, 20) },
    new Employee { Id = 5, Name = "Diana", Department = "HR", Salary = 72000, Age = 27, JoinDate = new DateTime(2023, 9, 5) },
    new Employee { Id = 6, Name = "Eve", Department = "Marketing", Salary = 68000, Age = 26, JoinDate = new DateTime(2024, 1, 15) },
    new Employee { Id = 7, Name = "Frank", Department = "HR", Salary = 78000, Age = 32, JoinDate = new DateTime(2021, 11, 1) },
    new Employee { Id = 8, Name = "Grace", Department = "Engineering", Salary = 98000, Age = 29, JoinDate = new DateTime(2022, 3, 10) },
};
```

---

## Filtering — Where

```csharp
// Single condition
var engineers = employees.Where(e => e.Department == "Engineering");
// Debanjan, Alice, Charlie, Grace

// Multiple conditions
var seniorEngineers = employees.Where(e => e.Department == "Engineering" && e.Salary > 90000);
// Alice, Charlie, Grace

// With index (overload)
var firstThreeOver70k = employees
    .Where((e, index) => e.Salary > 70000 && index < 5);
```

---

## Projection — Select

Transform each element into a new shape.

```csharp
// Select single property
var names = employees.Select(e => e.Name);
// ["Debanjan", "Alice", "Bob", ...]

// Select anonymous type
var nameAndSalary = employees.Select(e => new { e.Name, e.Salary });
// [{ Name = "Debanjan", Salary = 85000 }, ...]

// Select with transformation
var summaries = employees.Select(e => new
{
    e.Name,
    Department = e.Department.ToUpper(),
    AnnualSalary = e.Salary,
    MonthlySalary = Math.Round(e.Salary / 12, 2)
});

foreach (var s in summaries)
    Console.WriteLine($"{s.Name}: {s.MonthlySalary:C}/month ({s.Department})");

// Select with index
var indexed = employees.Select((e, i) => $"{i + 1}. {e.Name}");
// ["1. Debanjan", "2. Alice", ...]
```

---

## Sorting — OrderBy, ThenBy

```csharp
// Ascending
var byName = employees.OrderBy(e => e.Name);

// Descending
var bySalaryDesc = employees.OrderByDescending(e => e.Salary);

// Multiple sort criteria
var sorted = employees
    .OrderBy(e => e.Department)          // First by department
    .ThenByDescending(e => e.Salary);    // Then by salary (highest first)

foreach (var e in sorted)
    Console.WriteLine($"{e.Department,-15} {e.Name,-12} {e.Salary:C}");
```

---

## Aggregation Methods

```csharp
// Count
int total = employees.Count();                           // 8
int engineers = employees.Count(e => e.Department == "Engineering"); // 4

// Sum
decimal totalSalary = employees.Sum(e => e.Salary);       // 663,000

// Average
double avgSalary = (double)employees.Average(e => e.Salary);  // 82,875

// Min / Max
decimal lowest = employees.Min(e => e.Salary);             // 65,000
decimal highest = employees.Max(e => e.Salary);            // 105,000

// MinBy / MaxBy (C# 10+) — returns the ELEMENT, not the value
Employee topEarner = employees.MaxBy(e => e.Salary)!;
Console.WriteLine($"Top earner: {topEarner.Name} ({topEarner.Salary:C})");
// Top earner: Charlie ($105,000.00)

Employee youngest = employees.MinBy(e => e.Age)!;
Console.WriteLine($"Youngest: {youngest.Name} (Age {youngest.Age})");
```

---

## Element Access

```csharp
// First / Last
Employee first = employees.First();                         // Debanjan
Employee firstEngineer = employees.First(e => e.Department == "Engineering"); // Debanjan

// FirstOrDefault — returns null (or default) if not found (SAFE)
Employee? ceo = employees.FirstOrDefault(e => e.Department == "CEO");  // null

// Single — expects EXACTLY one match (throws if 0 or 2+)
Employee charlie = employees.Single(e => e.Name == "Charlie");

// SingleOrDefault — expects 0 or 1 match
Employee? unknown = employees.SingleOrDefault(e => e.Name == "Unknown"); // null

// ElementAt
Employee third = employees.ElementAt(2);  // Bob (0-indexed)

// Last
Employee lastHired = employees.OrderBy(e => e.JoinDate).Last();
```

### When to Use Which?

| Method | 0 matches | 1 match | 2+ matches |
|---|---|---|---|
| `First` | ❌ Throws | ✅ Returns it | ✅ Returns first |
| `FirstOrDefault` | Returns default | ✅ Returns it | ✅ Returns first |
| `Single` | ❌ Throws | ✅ Returns it | ❌ Throws |
| `SingleOrDefault` | Returns default | ✅ Returns it | ❌ Throws |

**Rule**: Use `FirstOrDefault` for general queries. Use `Single` when you **expect exactly one** result (like finding by unique ID).

---

## Quantifiers — Any, All, Contains

```csharp
// Any — does ANY element match?
bool hasHighEarner = employees.Any(e => e.Salary > 100000);  // true
bool hasAnyEmployees = employees.Any();                        // true (non-empty)

// All — do ALL elements match?
bool allOver50k = employees.All(e => e.Salary > 50000);       // true
bool allEngineers = employees.All(e => e.Department == "Engineering"); // false

// Contains (for simple types)
List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };
bool has3 = numbers.Contains(3);  // true
```

---

## Partitioning — Take, Skip

```csharp
// Take first N
var top3 = employees.OrderByDescending(e => e.Salary).Take(3);
// Charlie (105k), Grace (98k), Alice (92k)

// Skip first N
var afterFirst2 = employees.Skip(2);
// Bob, Charlie, Diana, Eve, Frank, Grace

// Pagination
int page = 2;
int pageSize = 3;
var pageResults = employees.Skip((page - 1) * pageSize).Take(pageSize);
// Skip 3, Take 3 → Charlie, Diana, Eve

// TakeLast / SkipLast
var last2 = employees.TakeLast(2);   // Frank, Grace
var allButLast = employees.SkipLast(1); // Everyone except Grace

// TakeWhile / SkipWhile — take/skip while condition is true
var numbers = new List<int> { 1, 2, 3, 8, 2, 1 };
var taken = numbers.TakeWhile(n => n < 5);  // [1, 2, 3] — stops at 8
var skipped = numbers.SkipWhile(n => n < 5); // [8, 2, 1] — skips until 8
```

---

## Grouping — GroupBy

```csharp
// Group by department
var byDept = employees.GroupBy(e => e.Department);

foreach (var group in byDept)
{
    Console.WriteLine($"\n{group.Key} ({group.Count()} employees):");
    foreach (var emp in group)
        Console.WriteLine($"  {emp.Name} — {emp.Salary:C}");
}
// Engineering (4 employees):
//   Debanjan — $85,000.00
//   Alice — $92,000.00
//   Charlie — $105,000.00
//   Grace — $98,000.00
// Marketing (2 employees):
//   Bob — $65,000.00
//   Eve — $68,000.00
// HR (2 employees):
//   Diana — $72,000.00
//   Frank — $78,000.00

// Group with aggregation
var deptSummary = employees
    .GroupBy(e => e.Department)
    .Select(g => new
    {
        Department = g.Key,
        Count = g.Count(),
        AvgSalary = g.Average(e => e.Salary),
        MaxSalary = g.Max(e => e.Salary),
        TotalSalary = g.Sum(e => e.Salary)
    })
    .OrderByDescending(d => d.AvgSalary);

foreach (var d in deptSummary)
    Console.WriteLine($"{d.Department}: {d.Count} people, Avg: {d.AvgSalary:C}");
```

---

## Set Operations

```csharp
List<int> a = new List<int> { 1, 2, 3, 4, 5 };
List<int> b = new List<int> { 3, 4, 5, 6, 7 };

var union = a.Union(b);         // [1, 2, 3, 4, 5, 6, 7]
var intersect = a.Intersect(b); // [3, 4, 5]
var except = a.Except(b);       // [1, 2]  (in a but not b)
var distinct = new[] { 1, 1, 2, 2, 3 }.Distinct(); // [1, 2, 3]

// DistinctBy (C# 10+)
var uniqueDepts = employees.DistinctBy(e => e.Department);
// One employee per department
```

---

## Joining — Join & GroupJoin

```csharp
// Sample related data
var departments = new[]
{
    new { Name = "Engineering", Floor = 3 },
    new { Name = "Marketing", Floor = 2 },
    new { Name = "HR", Floor = 1 },
    new { Name = "Finance", Floor = 4 }  // No employees
};

// Inner Join — only matching records
var joined = employees.Join(
    departments,
    emp => emp.Department,     // outer key
    dept => dept.Name,         // inner key
    (emp, dept) => new { emp.Name, emp.Department, dept.Floor }
);

foreach (var j in joined)
    Console.WriteLine($"{j.Name} works in {j.Department} on Floor {j.Floor}");

// Group Join — like LEFT JOIN with grouped results
var groupJoined = departments.GroupJoin(
    employees,
    dept => dept.Name,
    emp => emp.Department,
    (dept, emps) => new
    {
        Department = dept.Name,
        Floor = dept.Floor,
        Employees = emps.ToList()
    }
);

foreach (var g in groupJoined)
{
    Console.WriteLine($"\n{g.Department} (Floor {g.Floor}):");
    if (g.Employees.Any())
        foreach (var e in g.Employees)
            Console.WriteLine($"  {e.Name}");
    else
        Console.WriteLine("  (No employees)");
}
// Finance (Floor 4):
//   (No employees)
```

---

## Flattening — SelectMany

When each element contains a collection, `SelectMany` flattens them into one sequence.

```csharp
var teams = new[]
{
    new { Team = "Backend", Members = new[] { "Debanjan", "Alice" } },
    new { Team = "Frontend", Members = new[] { "Bob", "Eve" } },
    new { Team = "DevOps", Members = new[] { "Charlie" } }
};

// Select → List of arrays
var nested = teams.Select(t => t.Members);
// [["Debanjan","Alice"], ["Bob","Eve"], ["Charlie"]]

// SelectMany → Flat list
var allMembers = teams.SelectMany(t => t.Members);
// ["Debanjan", "Alice", "Bob", "Eve", "Charlie"]

// SelectMany with projection
var memberDetails = teams.SelectMany(
    t => t.Members,
    (team, member) => new { team.Team, Member = member }
);
// [{ Team="Backend", Member="Debanjan" }, { Team="Backend", Member="Alice" }, ...]
```

---

## Chaining — Building Complex Queries

The real power of LINQ is **chaining** operations:

```csharp
// Find the department with the highest average salary
// and list its members sorted by salary
var topDept = employees
    .GroupBy(e => e.Department)
    .Select(g => new
    {
        Department = g.Key,
        AvgSalary = g.Average(e => e.Salary),
        Members = g.OrderByDescending(e => e.Salary).ToList()
    })
    .OrderByDescending(d => d.AvgSalary)
    .First();

Console.WriteLine($"Top Department: {topDept.Department} (Avg: {topDept.AvgSalary:C})");
foreach (var m in topDept.Members)
    Console.WriteLine($"  {m.Name}: {m.Salary:C}");
```

---

## Deferred vs Immediate Execution

### Deferred Execution (Lazy)

LINQ queries are NOT executed when defined — they execute when you **iterate** over the results.

```csharp
List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };

// Query is DEFINED here, not executed
var query = numbers.Where(n => n > 3);

numbers.Add(6); // Modify the source

// Query executes NOW — includes 6!
foreach (var n in query)
    Console.Write($"{n} "); // 4 5 6
```

### Immediate Execution (Eager)

Methods that return a **concrete result** execute immediately:

```csharp
// These execute IMMEDIATELY:
int count = numbers.Count();         // single value
List<int> list = numbers.Where(n => n > 3).ToList();  // ToList()
int[] arr = numbers.Where(n => n > 3).ToArray();      // ToArray()
Dictionary<int, int> dict = numbers.ToDictionary(n => n, n => n * 2);
int first = numbers.First();         // single element
bool any = numbers.Any(n => n > 10); // boolean
```

**Rule**: If you need to use results multiple times or want a "snapshot", call `.ToList()` or `.ToArray()`.

---

## LINQ with Strings

```csharp
string sentence = "Hello World from LINQ in CSharp";

// Count vowels
int vowels = sentence.Count(c => "aeiouAEIOU".Contains(c)); // 9

// Get unique characters (lowercase)
var uniqueChars = sentence.ToLower()
    .Where(c => char.IsLetter(c))
    .Distinct()
    .OrderBy(c => c);
// [a, c, d, e, f, h, i, l, m, n, o, q, r, s, w]

// Longest word
string longest = sentence.Split(' ')
    .OrderByDescending(w => w.Length)
    .First(); // "CSharp"
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| `Where` | Filter elements by condition |
| `Select` | Transform/project each element |
| `OrderBy` / `ThenBy` | Sort with multiple criteria |
| `GroupBy` | Group elements by a key |
| `Join` / `GroupJoin` | Combine two collections by key |
| `SelectMany` | Flatten nested collections |
| `First` / `Single` | Get one element (with safety variants) |
| `Any` / `All` | Check conditions across collection |
| `Sum` / `Average` / `Min` / `Max` | Aggregate calculations |
| `Take` / `Skip` | Pagination and partitioning |
| Deferred execution | Queries run when iterated, not when defined |
| `.ToList()` / `.ToArray()` | Force immediate execution |

---

*Next Topic: Delegates, Events & Lambda Expressions →*
