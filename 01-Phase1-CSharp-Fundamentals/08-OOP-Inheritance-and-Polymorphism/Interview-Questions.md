# Topic 08: OOP — Inheritance and Polymorphism — Interview Questions

---

## Q1. What is inheritance and what are its benefits?
**Answer:**
Inheritance allows a class (child/derived) to acquire the members of another class (parent/base), promoting code reuse and establishing an "is-a" relationship.

```csharp
class Animal
{
    public string Name { get; set; }
    public virtual void Speak() => Console.WriteLine("...");
}

class Dog : Animal
{
    public override void Speak() => Console.WriteLine("Woof!");
}
```

Benefits: code reuse, extensibility, polymorphic behavior. C# supports **single inheritance** for classes (a class can have only one direct base class), but a class can implement multiple interfaces.

---

## Q2. Does C# support multiple inheritance? How is it handled?
**Answer:**
C# does **not** support multiple class inheritance (to avoid the "diamond problem"). However, a class can implement **multiple interfaces**.

```csharp
interface IFlyable { void Fly(); }
interface ISwimmable { void Swim(); }

class Duck : Animal, IFlyable, ISwimmable
{
    public void Fly() => Console.WriteLine("Flying");
    public void Swim() => Console.WriteLine("Swimming");
}
```

Default interface implementations (C# 8+) allow interfaces to provide method bodies, providing a limited form of multiple inheritance of behaviour.

---

## Q3. What is the difference between `virtual`, `override`, `abstract`, and `sealed`?
**Answer:**
| Keyword | Meaning |
|---|---|
| `virtual` | Method in base class **can** be overridden by derived classes |
| `override` | Method in derived class **replaces** a virtual/abstract method |
| `abstract` | Method with **no body** — derived class **must** override it |
| `sealed` | Prevents a class from being inherited further, or prevents a specific override from being overridden again |

```csharp
abstract class Shape
{
    public abstract double Area();      // must override
    public virtual string Color => "Red"; // can override
}

class Circle : Shape
{
    public sealed override double Area() => Math.PI * R * R; // cannot override further
    public double R;
}
```

---

## Q4. What is the difference between method overriding and method hiding (`new`)?
**Answer:**
- **Override** — replaces the base method at runtime. The derived version is called through any reference, even a base-type variable.
- **Hiding (`new`)** — creates a new method that shadows the base. Which version is called depends on the **compile-time type** of the variable.

```csharp
class Base   { public virtual void Show() => Console.WriteLine("Base"); }
class Override : Base { public override void Show() => Console.WriteLine("Override"); }
class Hidden   : Base { public new void Show() => Console.WriteLine("Hidden"); }

Base b1 = new Override(); b1.Show(); // "Override" — runtime dispatch
Base b2 = new Hidden();   b2.Show(); // "Base"     — compile-time type (Base)
Hidden h = new Hidden();  h.Show();  // "Hidden"   — compile-time type (Hidden)
```

---

## Q5. What is the `base` keyword?
**Answer:**
`base` refers to the parent class. Common uses:
1. Call a base class constructor from a derived constructor.
2. Call an overridden base method from within the override.

```csharp
class Animal
{
    public Animal(string name) { Name = name; }
    public string Name { get; }
    public virtual void Describe() => Console.WriteLine($"Animal: {Name}");
}

class Dog : Animal
{
    public Dog(string name) : base(name) { }  // chain to base constructor

    public override void Describe()
    {
        base.Describe();                       // call base version
        Console.WriteLine("(is a Dog)");
    }
}
```

---

## Q6. What is a `sealed` class? When would you use it?
**Answer:**
A `sealed` class cannot be inherited. Sealing provides:
- **Security** — prevents unintended subclassing that could bypass security checks.
- **Performance** — JIT can devirtualize calls on sealed types, enabling inlining.

```csharp
sealed class MathHelper
{
    public static double Square(double x) => x * x;
}

// class AdvancedMath : MathHelper { } // ❌ Compile error
```

Common examples: `string`, `int`, all other primitive wrapper types are effectively sealed. Apply `sealed` to your own classes when extension would break invariants.

---

## Q7. What is polymorphism? Explain compile-time vs runtime polymorphism.
**Answer:**
Polymorphism means "many forms" — the same interface can have different implementations.

- **Compile-time (static) polymorphism** — resolved at compile time. Examples: method overloading, operator overloading.
- **Runtime (dynamic) polymorphism** — resolved at runtime via virtual dispatch. Example: method overriding through a base-class reference.

```csharp
// Compile-time
void Print(int x) { }
void Print(string x) { }

// Runtime
Animal[] animals = { new Dog(), new Cat() };
foreach (var a in animals)
    a.Speak(); // calls Dog.Speak or Cat.Speak depending on actual type
```

---

## Q8. What is an abstract class? When would you use it over an interface?
**Answer:**
An abstract class is a partial implementation — it can have abstract (no body) and concrete (with body) members. You cannot instantiate it directly.

```csharp
abstract class Repository<T>
{
    public abstract T GetById(int id);      // must override
    public void Save(T entity)              // shared implementation
    {
        Validate(entity);
        Persist(entity);
    }
    protected abstract void Persist(T entity);
}
```

**Use abstract class when:**
- You want to share code (fields, constructor logic, concrete methods) among related classes.
- There is a clear "is-a" hierarchy.

**Use interface when:**
- You want to define a capability contract across unrelated classes.
- You need multiple contracts on a single class.

---

## Q9. What is the Liskov Substitution Principle (LSP)?
**Answer:**
LSP states that objects of a derived class must be **substitutable for objects of the base class** without breaking the program's correctness. It's the "L" in SOLID.

A violation example:
```csharp
class Rectangle { public virtual int Width { get; set; } public virtual int Height { get; set; } }
class Square : Rectangle
{
    public override int Width  { set { base.Width = base.Height = value; } get => base.Width; }
    public override int Height { set { base.Width = base.Height = value; } get => base.Height; }
}

// This breaks LSP:
Rectangle r = new Square();
r.Width = 4;
r.Height = 5;
// Expected: Area = 20, but Square forces Width = Height = 5 → Area = 25
```

A `Square` is not substitutable for a `Rectangle` here. The fix is to not inherit `Square` from `Rectangle`.

---

## Q10. What is the `object` class and what methods does it provide?
**Answer:**
`System.Object` is the root of the C# type hierarchy — every type ultimately derives from it.

Key virtual methods you can override:
| Method | Purpose |
|---|---|
| `Equals(object)` | Value equality check |
| `GetHashCode()` | Hash code for use in dictionaries/sets |
| `ToString()` | Human-readable string representation |
| `GetType()` | Returns the runtime `Type` (cannot override) |
| `MemberwiseClone()` | Shallow copy (protected) |
| `Finalize()` | GC cleanup hook (override via `~`) |

**Rule:** If you override `Equals()`, always override `GetHashCode()` to maintain the contract: if `a.Equals(b)` then `a.GetHashCode() == b.GetHashCode()`.

---

## Q11. What is covariant return type (C# 9+)?
**Answer:**
C# 9 allows overriding methods to return a **more derived type** than declared in the base class:

```csharp
class Animal
{
    public virtual Animal Create() => new Animal();
}

class Dog : Animal
{
    public override Dog Create() => new Dog(); // covariant return — Dog is more derived than Animal
}

Dog d = new Dog();
Dog result = d.Create(); // no cast needed!
```

Before C# 9 you needed to cast: `(Dog)d.Create()`. Covariant returns are useful in factory/clone patterns.

---

## Q12. What is the Template Method design pattern?
**Answer:**
Template Method defines a **skeleton algorithm** in a base class with abstract steps that subclasses implement — a classic use of inheritance + polymorphism:

```csharp
abstract class DataExporter
{
    // Template method — defines the algorithm skeleton
    public void Export()
    {
        var data = FetchData();     // abstract
        var formatted = Format(data); // abstract
        Save(formatted);             // concrete (shared)
    }

    protected abstract IEnumerable<object> FetchData();
    protected abstract string Format(IEnumerable<object> data);

    protected void Save(string output)
        => File.WriteAllText("output.txt", output); // shared logic
}

class CsvExporter : DataExporter
{
    protected override IEnumerable<object> FetchData() => GetDbRows();
    protected override string Format(IEnumerable<object> data) => ToCsv(data);
}
```

---

## Q13. What are the SOLID principles? Give a C# example for each.
**Answer:**
**S — Single Responsibility:** A class should have only one reason to change.
```csharp
// Bad: one class that saves AND emails
// Good: OrderSaver and OrderEmailer as separate classes
```

**O — Open/Closed:** Open for extension, closed for modification.
```csharp
abstract class Discount { public abstract decimal Apply(decimal price); }
class TenPercentOff : Discount { public override decimal Apply(decimal p) => p * 0.9m; }
```

**L — Liskov Substitution:** Derived types must be substitutable for base types.
```csharp
// Square inheriting Rectangle violates LSP — see Q9 in this file
```

**I — Interface Segregation:** Clients should not be forced to depend on methods they don’t use.
```csharp
interface IReadable  { string Read(); }
interface IWriteable { void Write(string s); }
class ReadOnlyFile : IReadable { public string Read() => File.ReadAllText(_path); }
```

**D — Dependency Inversion:** Depend on abstractions, not concretions.
```csharp
class OrderService
{
    private readonly IOrderRepository _repo; // interface, not concrete class
    public OrderService(IOrderRepository repo) => _repo = repo;
}
```

---

## Q14. What is constructor chaining and why is it useful?
**Answer:**
Constructor chaining calls another constructor (`this(...)` for same class, `base(...)` for parent class) to avoid code duplication:

```csharp
class Server
{
    public string Host { get; }
    public int Port { get; }
    public bool UseSSL { get; }

    public Server() : this("localhost") { }
    public Server(string host) : this(host, 80) { }
    public Server(string host, int port) : this(host, port, false) { }

    public Server(string host, int port, bool ssl)
    {
        Host = host;
        Port = port;
        UseSSL = ssl;
    }
}
```

All constructors funnel to the most detailed one — validation logic lives in one place.

---

## Q15. What is the difference between `is` type pattern and `as` cast?
**Answer:**
```csharp
object obj = GetShape();

// Old style: as + null check (two operations)
var circle = obj as Circle;
if (circle != null)
    Console.WriteLine(circle.Radius);

// Modern: is pattern matching (one operation, more readable)
if (obj is Circle c)
    Console.WriteLine(c.Radius);

// Extended property pattern (C# 10+)
if (obj is Circle { Radius: > 10 } bigCircle)
    Console.WriteLine($"Big circle: {bigCircle.Radius}");

// switch expression with type patterns
string Describe(Shape s) => s switch
{
    Circle c   => $"Circle r={c.Radius}",
    Rectangle r => $"Rect {r.Width}x{r.Height}",
    _           => "Unknown"
};
```
