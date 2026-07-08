# Topic 09: OOP — Abstraction and Interfaces — Interview Questions

---

## Q1. What is the difference between an abstract class and an interface?
**Answer:**
| | Abstract Class | Interface |
|---|---|---|
| **Instantiation** | Cannot be instantiated | Cannot be instantiated |
| **Method body** | Can have concrete methods | Can have default implementations (C# 8+) |
| **Fields** | Yes | No (constants only) |
| **Constructors** | Yes | No |
| **Access modifiers** | Any | Public by default |
| **Inheritance** | Single (one base class) | Multiple (a class can implement many) |
| **State** | Can store state | Cannot store instance state |
| **Keyword** | `abstract class` | `interface` |

Use abstract class for **shared base behaviour** among related types. Use interface for **capability contracts** across unrelated types.

---

## Q2. Can interfaces have default implementations?
**Answer:**
Yes, since **C# 8**. Default interface methods provide a method body that implementing classes can optionally override:

```csharp
interface ILogger
{
    void Log(string message);

    void LogWarning(string message)   // default implementation
        => Log($"[WARNING] {message}");

    void LogError(string message)
        => Log($"[ERROR] {message}");
}

class ConsoleLogger : ILogger
{
    public void Log(string message) => Console.WriteLine(message);
    // LogWarning and LogError are inherited from interface
}
```

**Important:** Default implementations are only accessible via the interface type, not through a concrete class variable unless explicitly cast.

---

## Q3. What is explicit interface implementation and why is it used?
**Answer:**
Explicit interface implementation hides the member from direct class access — it is only accessible through the interface type.

```csharp
interface IShape { double Area(); }
interface IPrintable { void Print(); }

class Circle : IShape, IPrintable
{
    double IShape.Area() => Math.PI * R * R;  // explicit
    void IPrintable.Print() => Console.WriteLine($"Circle r={R}");
    public double R;
}

Circle c = new Circle { R = 5 };
// c.Area();  // ❌ Not accessible directly
((IShape)c).Area(); // ✓ Must cast to interface

IShape shape = c;
shape.Area();       // ✓
```

Use explicit implementation to:
1. Resolve naming conflicts between multiple interfaces.
2. Hide "infrastructure" methods from the public API of the class.

---

## Q4. Can a class implement multiple interfaces? Can it inherit multiple abstract classes?
**Answer:**
- A class can implement **multiple interfaces** — there is no limit.
- A class can only inherit **one base class** (abstract or concrete).

```csharp
interface IFlyable { void Fly(); }
interface ISwimmable { void Swim(); }
interface IRunnable { void Run(); }

class Duck : Animal, IFlyable, ISwimmable, IRunnable
{
    public void Fly() { }
    public void Swim() { }
    public void Run() { }
}
```

This is how C# achieves flexibility without the complexity of multiple class inheritance.

---

## Q5. What is abstraction? How is it different from encapsulation?
**Answer:**
- **Abstraction** — hiding **what something does** at the implementation level, exposing only the interface (the "what", not the "how").
- **Encapsulation** — hiding **internal state and data**, exposing only a controlled API.

```csharp
// Abstraction — caller doesn't care how payment is processed
interface IPaymentGateway
{
    bool Charge(decimal amount);
}

// Encapsulation — internal balance hidden, accessed only via Deposit/Withdraw
class BankAccount
{
    private decimal _balance;  // hidden state
    public void Deposit(decimal amount) { _balance += amount; }
    public decimal GetBalance() => _balance;
}
```

Think of abstraction as the **design perspective** and encapsulation as the **implementation technique**.

---

## Q6. What is the Interface Segregation Principle (ISP)?
**Answer:**
ISP (the "I" in SOLID) states: **clients should not be forced to depend on interfaces they do not use**. Large, fat interfaces should be split into smaller, role-specific ones.

```csharp
// Bad — one fat interface
interface IWorker { void Work(); void Eat(); void Sleep(); }

// Good — segregated interfaces
interface IWorkable  { void Work(); }
interface IEatable   { void Eat(); }
interface ISleepable { void Sleep(); }

class HumanWorker : IWorkable, IEatable, ISleepable { }
class Robot : IWorkable { }  // Robots don't eat or sleep
```

---

## Q7. How do you check if an object implements an interface at runtime?
**Answer:**
Use `is` (with pattern matching) or `as`:

```csharp
object obj = new Circle();

if (obj is IShape shape)
    Console.WriteLine(shape.Area());

// Or
IShape s = obj as IShape;
if (s != null) s.Area();

// Checking type
bool implementsIShape = obj is IShape;
bool typeCheck = typeof(IShape).IsAssignableFrom(typeof(Circle));
```

---

## Q8. What is the `IComparable<T>` and `IComparer<T>` interface?
**Answer:**
- **`IComparable<T>`** — implemented by the type itself to define its natural ordering. Used by `Array.Sort`, `List.Sort`, etc.
- **`IComparer<T>`** — external comparer class, defines ordering without modifying the type. Useful when you need multiple sort orders.

```csharp
class Employee : IComparable<Employee>
{
    public int Salary { get; set; }
    public int CompareTo(Employee other) => Salary.CompareTo(other.Salary);
}

class SortByName : IComparer<Employee>
{
    public int Compare(Employee x, Employee y)
        => string.Compare(x.Name, y.Name);
}

employees.Sort();                        // uses IComparable
employees.Sort(new SortByName());        // uses IComparer
```

---

## Q9. What is the `IDisposable` interface and the Dispose pattern?
**Answer:**
`IDisposable` defines a single `Dispose()` method for releasing **unmanaged resources** deterministically (file handles, DB connections, streams).

```csharp
class DbConnection : IDisposable
{
    private bool _disposed = false;

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this); // tell GC no need to run finalizer
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed)
        {
            if (disposing)
                _managedResource?.Dispose(); // dispose managed resources
            // release unmanaged resources here
            _disposed = true;
        }
    }

    ~DbConnection() => Dispose(false); // safety net
}

using (var conn = new DbConnection()) // Dispose called automatically
{
    // use conn
}
```

---

## Q10. What are marker interfaces? Are they still relevant?
**Answer:**
A **marker interface** has no members — it simply "tags" a class to indicate a capability or contract.

Classic examples:
- `ISerializable` (older .NET)
- `ICloneable`

```csharp
interface IAuditable { }  // marker

class Order : IAuditable { }

// Check at runtime
if (entity is IAuditable)
    AuditLog.Record(entity);
```

In modern C#, **attributes** are often preferred over marker interfaces because they can carry metadata and don't pollute the class's type hierarchy:

```csharp
[Auditable]
class Order { }
```

Marker interfaces are still seen in legacy codebases and some framework APIs.

---

## Q11. What are static abstract interface members (C# 11)?
**Answer:**
C# 11 allows interfaces to declare `static abstract` members. Implementing types must provide their own static implementation. This enables **generic math** and operator overloading through generics:

```csharp
interface IAddable<T>
{
    static abstract T operator +(T left, T right);
    static abstract T Zero { get; }
}

struct MyInt : IAddable<MyInt>
{
    public int Value;
    public static MyInt operator +(MyInt a, MyInt b) => new() { Value = a.Value + b.Value };
    public static MyInt Zero => new() { Value = 0 };
}

// Generic sum that works for any IAddable
T Sum<T>(IEnumerable<T> items) where T : IAddable<T>
{
    T total = T.Zero;
    foreach (var item in items) total = total + item;
    return total;
}
```

This is used by .NET's `System.Numerics.INumber<T>` to write truly generic numeric algorithms.

---

## Q12. What is the Dependency Inversion Principle (DIP) and how do interfaces enable it?
**Answer:**
DIP states:
1. High-level modules should not depend on low-level modules — both should depend on abstractions.
2. Abstractions should not depend on details — details should depend on abstractions.

```csharp
// Bad — high-level depends on low-level concrete
class ReportGenerator
{
    private SqlDatabase _db = new SqlDatabase(); // tightly coupled
}

// Good — both depend on the abstraction IDatabase
interface IDatabase { IEnumerable<Row> Query(string sql); }

class ReportGenerator
{
    private readonly IDatabase _db;
    public ReportGenerator(IDatabase db) => _db = db; // injected
}

class SqlDatabase : IDatabase { public IEnumerable<Row> Query(string sql) { /* */ } }
class MockDatabase : IDatabase { public IEnumerable<Row> Query(string sql) => Enumerable.Empty<Row>(); }
```

Interfaces are the abstraction layer that breaks the tight coupling.

---

## Q13. What is interface versioning and how do default implementations solve it?
**Answer:**
Adding a new method to a published interface is a **breaking change** — all existing implementors must add the method or fail to compile.

**Before C# 8:** Impossible to add methods to a public interface without breaking all implementations.

**C# 8+ default implementations** solve this:
```csharp
public interface ILogger
{
    void Log(string message);

    // Added in v2 — existing implementors don't break
    void LogWarning(string msg) => Log($"[WARN] {msg}");
    void LogError(string msg) => Log($"[ERROR] {msg}");
}

// Old implementation — still compiles, gets default LogWarning/LogError for free
class OldLogger : ILogger
{
    public void Log(string message) => Console.WriteLine(message);
}
```

**Caveat:** The default method is only accessible via the **interface type**, not the concrete class reference.

---

## Q14. What is the difference between `IEquatable<T>` and `IComparable<T>`?
**Answer:**
- **`IEquatable<T>`** — defines **equality** (`Equals(T other)`). Avoids boxing when comparing value types. Used by `Contains`, `==` overloads, `HashSet<T>`.
- **`IComparable<T>`** — defines **ordering** (`CompareTo(T other)`, returns negative/zero/positive). Used by `Sort`, `Min`, `Max`, `SortedDictionary`.

```csharp
class Temperature : IEquatable<Temperature>, IComparable<Temperature>
{
    public double Celsius { get; }
    public Temperature(double c) => Celsius = c;

    public bool Equals(Temperature other) => Celsius == other?.Celsius;
    public int CompareTo(Temperature other) => Celsius.CompareTo(other.Celsius);

    public override bool Equals(object obj) => obj is Temperature t && Equals(t);
    public override int GetHashCode() => Celsius.GetHashCode();
    public static bool operator <(Temperature a, Temperature b) => a.CompareTo(b) < 0;
    public static bool operator >(Temperature a, Temperature b) => a.CompareTo(b) > 0;
}
```

---

## Q15. What are covariant and contravariant interfaces?
**Answer:**
- **Covariant (`out T`)** — the interface produces T. A more derived type can be assigned to the interface of the base type.
- **Contravariant (`in T`)** — the interface consumes T. A more general type can be assigned to the interface of the derived type.

```csharp
// IEnumerable<out T> is covariant — producer
IEnumerable<string> strings = new List<string>();
IEnumerable<object> objects = strings; // ✓ string IS-A object

// IComparer<in T> is contravariant — consumer
IComparer<object> objComparer = Comparer<object>.Default;
IComparer<string> strComparer = objComparer; // ✓ if you can compare objects, you can compare strings

// Your own covariant interface
interface IProducer<out T> { T Produce(); }
interface IConsumer<in T> { void Consume(T item); }
```

Variance only applies to **interfaces and delegates** — not to classes, structs, or generic methods. It only works with **reference types** (not value types).
