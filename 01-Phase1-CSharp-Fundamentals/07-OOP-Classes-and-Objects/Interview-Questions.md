# Topic 07: OOP — Classes and Objects — Interview Questions

---

## Q1. What are the four pillars of Object-Oriented Programming?
**Answer:**
1. **Encapsulation** — bundling data and methods together, hiding internal state via access modifiers.
2. **Inheritance** — a class (child) can derive from another (parent), reusing and extending its members.
3. **Polymorphism** — the same method call behaves differently depending on the actual runtime object.
4. **Abstraction** — exposing only the essential interface, hiding implementation details (abstract classes, interfaces).

---

## Q2. What is the difference between a class and a struct?
**Answer:**
| | `class` | `struct` |
|---|---|---|
| **Type** | Reference type (heap) | Value type (stack / inline) |
| **Default value** | `null` | Zero-initialized |
| **Inheritance** | Supports inheritance | Cannot inherit (can implement interfaces) |
| **Mutability** | Mutable by default | Should be immutable by convention |
| **Assignment** | Copies reference | Copies entire value |
| **Use case** | Complex objects, shared state | Small, data-centric types (Point, Color, DateTime) |

```csharp
struct Point { public int X, Y; }
class Person { public string Name; }

Point p1 = new Point { X = 1, Y = 2 };
Point p2 = p1;  // p2 is a copy — changing p2.X does not affect p1
```

---

## Q3. What are the different types of constructors in C#?
**Answer:**
1. **Default constructor** — no parameters. Compiler generates one if no constructor is defined.
2. **Parameterized constructor** — accepts arguments to initialize fields.
3. **Copy constructor** — takes an instance of the same class and copies its fields.
4. **Static constructor** — initializes static members. Called once before first use. No parameters, no access modifier.
5. **Private constructor** — prevents external instantiation (used in singletons or factory patterns).

```csharp
class Config
{
    public static readonly Config Instance;

    static Config()                          // Static constructor
    {
        Instance = new Config();
    }

    private Config() { }                     // Private constructor
}
```

---

## Q4. What is the difference between static and instance members?
**Answer:**
- **Instance members** — belong to a specific object. Each object has its own copy.
- **Static members** — belong to the class itself. Shared across all instances. Accessed via the class name.

```csharp
class Counter
{
    private static int _totalCount = 0;  // shared
    public int Id { get; }               // per instance

    public Counter()
    {
        _totalCount++;
        Id = _totalCount;
    }

    public static int GetTotal() => _totalCount;
}

var c1 = new Counter(); // Id=1
var c2 = new Counter(); // Id=2
Console.WriteLine(Counter.GetTotal()); // 2
```

---

## Q5. What is object initializer syntax?
**Answer:**
Object initializers allow you to set properties/fields at construction time without calling a parameterized constructor:

```csharp
var person = new Person
{
    Name = "Debanjan",
    Age = 25,
    Email = "d@example.com"
};
```

The compiler desugars this to calling the default constructor, then setting each property. If the class has a required parameterized constructor, you combine both:

```csharp
var p = new Person("Debanjan") { Age = 25 };
```

---

## Q6. What is the difference between a property and a field?
**Answer:**
- **Field** — a raw variable declared in a class. No access control over get/set logic.
- **Property** — a named pair of `get`/`set` accessors. Provides a controlled interface to underlying data.

```csharp
class Product
{
    private decimal _price;           // backing field

    public decimal Price              // property with validation
    {
        get => _price;
        set
        {
            if (value < 0) throw new ArgumentException("Price cannot be negative");
            _price = value;
        }
    }

    public string Name { get; set; }  // auto-implemented property
    public int Id { get; init; }      // init-only (C# 9+) — set only in constructor/initializer
}
```

**Best practice:** Expose public data via properties, never public fields. This preserves the ability to add validation/logic later without breaking callers.

---

## Q7. What is method overloading and how does the compiler resolve it?
**Answer:**
The compiler selects the best overload by matching the argument types to parameter types in this order:
1. Exact type match
2. Implicit conversions (widening)
3. Params array expansion
4. Optional parameters

```csharp
void Print(int x) { }
void Print(double x) { }
void Print(object x) { }

Print(5);       // → Print(int)
Print(5.0);     // → Print(double)
Print("hello"); // → Print(object)
```

If no unique best match exists, the compiler reports an **ambiguous call** error.

---

## Q8. What is the `this` keyword?
**Answer:**
`this` refers to the **current instance** of the class. Common uses:
1. Disambiguate field name from parameter name.
2. Pass the current object as an argument.
3. Chain constructors with `this(...)`.

```csharp
class Person
{
    private string name;

    public Person(string name)
    {
        this.name = name;         // this.name = field, name = parameter
    }

    public Person() : this("Unknown") { } // constructor chaining
}
```

---

## Q9. What is a finalizer (destructor) and when should you use it?
**Answer:**
A finalizer (`~ClassName()`) is called by the GC before an object is collected. It is used to release **unmanaged resources** (file handles, sockets, native memory).

```csharp
class ResourceHolder
{
    ~ResourceHolder()  // Finalizer
    {
        // Release unmanaged resources
    }
}
```

**Avoid finalizers when possible:**
- The GC promotes objects with finalizers to an older generation, delaying collection.
- Use `IDisposable` + `using` instead for deterministic cleanup.
- If you need both, implement the **Dispose pattern** (`IDisposable` + finalizer as safety net).

---

## Q10. What is a `record` type in C#?
**Answer:**
`record` (C# 9+) is a reference type optimized for **immutable data**. It auto-generates:
- Value-based `Equals()` and `GetHashCode()`
- `ToString()` that prints all properties
- Non-destructive mutation with `with` expression

```csharp
record Person(string Name, int Age);

var p1 = new Person("Debanjan", 25);
var p2 = p1 with { Age = 26 };      // creates a new record
Console.WriteLine(p1 == p2);        // false (value-based comparison)
Console.WriteLine(p1);              // Person { Name = Debanjan, Age = 25 }
```

`record struct` (C# 10+) is the value-type variant. Records are ideal for DTOs, command/query objects, and domain value objects.

---

## Q11. What is a `required` property and primary constructor (C# 11/12)?
**Answer:**
**`required` modifier (C# 11)** — forces callers to set the property via object initializer or constructor:

```csharp
class Product
{
    public required int Id { get; init; }       // must be set at construction
    public required string Name { get; init; }
    public decimal Price { get; init; }         // optional
}

// Compile error if Id or Name are omitted:
var p = new Product { Id = 1, Name = "Widget" }; // ✓
// var p = new Product { Name = "Widget" };       // ❌ Id is required
```

**Primary constructor (C# 12)** — constructor parameters are declared in the class header and are in scope throughout the class body:

```csharp
class OrderService(IOrderRepository repo, ILogger<OrderService> logger)
{
    public void Process(int id)
    {
        var order = repo.GetById(id); // repo is in scope everywhere
        logger.LogInformation($"Processing order {id}");
    }
}
```

---

## Q12. What are tuples in C# and how do they differ from classes?
**Answer:**
Tuples are lightweight, unnamed data containers. C# has two kinds:

**`ValueTuple` (C# 7+, struct)** — stack-allocated, named fields:
```csharp
// Method returning multiple values without a class
(string Name, int Age) GetPerson() => ("Debanjan", 25);

var person = GetPerson();
Console.WriteLine(person.Name); // "Debanjan"
Console.WriteLine(person.Age);  // 25

var (name, age) = GetPerson();  // deconstruction
```

**`Tuple<T1,T2,...>` (class, legacy)** — heap-allocated, accessed via `.Item1`, `.Item2`.

| | ValueTuple | Class/Record |
|---|---|---|
| Memory | Stack (value type) | Heap (reference type) |
| Named fields | Yes | Yes |
| Methods/behaviour | No | Yes |
| Use case | Temporary/local multi-return | Domain model |

---

## Q13. What are anonymous types?
**Answer:**
Anonymous types (C# 3+) are read-only, compiler-generated classes with properties inferred from the initializer. They are immutable and have `Equals`/`GetHashCode` based on property values:

```csharp
var person = new { Name = "Debanjan", Age = 25 };
Console.WriteLine(person.Name); // "Debanjan"
// person.Name = "Other"; // ❌ read-only

// Common use in LINQ projections
var summary = employees.Select(e => new { e.Name, e.Department, e.Salary });
```

Limitations: Cannot be returned from methods (use `Tuple`, `record`, or a named class instead). Cannot be used across assembly boundaries. Named type (`record`) is preferred in modern C#.

---

## Q14. What is the Singleton design pattern and how is it implemented in C#?
**Answer:**
Singleton ensures a class has **only one instance** for the lifetime of the application:

```csharp
// Thread-safe lazy singleton
public sealed class AppConfig
{
    private static readonly Lazy<AppConfig> _instance
        = new Lazy<AppConfig>(() => new AppConfig());

    public static AppConfig Instance => _instance.Value;

    private AppConfig() { Load(); } // private constructor

    public string ConnectionString { get; private set; } = "";
    private void Load() { /* load from config file */ }
}

// Usage
var config = AppConfig.Instance;
```

**Thread safety:** The `Lazy<T>` approach is thread-safe by default (`LazyThreadSafetyMode.ExecutionAndPublication`). Avoid the double-checked locking pattern in new code — `Lazy<T>` handles it correctly.

---

## Q15. What is object deconstruction and how is it implemented?
**Answer:**
Deconstruction allows you to "unpack" an object into individual variables by defining a `Deconstruct` method:

```csharp
class Point
{
    public int X { get; }
    public int Y { get; }
    public Point(int x, int y) { X = x; Y = y; }

    public void Deconstruct(out int x, out int y) { x = X; y = Y; }
}

var p = new Point(3, 5);
var (x, y) = p;                    // deconstruction
Console.WriteLine($"{x}, {y}");    // 3, 5

// Also works with records (auto-generated)
record Person(string Name, int Age);
var person = new Person("Debanjan", 25);
var (name, age) = person;

// Pattern matching with deconstruction
if (p is (3, var py)) Console.WriteLine($"x is 3, y is {py}");
```
