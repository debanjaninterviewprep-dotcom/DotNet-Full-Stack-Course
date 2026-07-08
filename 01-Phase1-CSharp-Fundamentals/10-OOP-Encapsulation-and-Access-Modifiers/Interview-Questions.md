# Topic 10: OOP — Encapsulation and Access Modifiers — Interview Questions

---

## Q1. What are the access modifiers in C# and what do they control?
**Answer:**
| Modifier | Accessible from |
|---|---|
| `public` | Anywhere |
| `private` | Only within the same class or struct |
| `protected` | Same class + derived classes |
| `internal` | Same assembly (project) |
| `protected internal` | Same assembly **OR** derived classes (union) |
| `private protected` | Same assembly **AND** derived classes (intersection) |
| `file` (C# 11+) | Only the same source file |

The default is `private` for class members and `internal` for top-level types.

---

## Q2. What is encapsulation and why is it important?
**Answer:**
Encapsulation is the practice of **hiding internal state** and requiring all interaction to go through a well-defined public API. It protects data integrity and decouples implementation from usage.

```csharp
class Temperature
{
    private double _celsius;

    public double Celsius
    {
        get => _celsius;
        set
        {
            if (value < -273.15) throw new ArgumentOutOfRangeException("Below absolute zero");
            _celsius = value;
        }
    }

    public double Fahrenheit => _celsius * 9 / 5 + 32; // derived, read-only
}
```

Benefits: validation, change management (you can change implementation without breaking callers), testability, and maintainability.

---

## Q3. What is the difference between `private` and `protected`?
**Answer:**
- `private` — accessible only within the **same class**. Derived classes cannot access it.
- `protected` — accessible within the same class **and all derived classes**.

```csharp
class Base
{
    private int _secret = 1;    // only Base can access
    protected int _shared = 2;  // Base and all derived classes can access
}

class Derived : Base
{
    void Test()
    {
        // Console.WriteLine(_secret); // ❌ Compile error
        Console.WriteLine(_shared);    // ✓
    }
}
```

---

## Q4. What is the difference between `internal` and `public`?
**Answer:**
- `public` — accessible from any assembly (project).
- `internal` — accessible only within the **same assembly**. This is the default for classes.

Use `internal` to hide implementation classes that should not be part of a library's public API. This supports the **principle of least privilege** — expose only what consumers need.

```csharp
// MyLibrary.csproj
public class UserService { }       // visible to any consuming project
internal class UserRepository { }  // hidden — only used internally in the library
```

You can grant a specific assembly access to `internal` types using `[assembly: InternalsVisibleTo("MyLibrary.Tests")]`.

---

## Q5. What is the difference between `const` and `readonly`?
**Answer:**
| | `const` | `readonly` |
|---|---|---|
| **Evaluation** | Compile time — value inlined | Runtime (or field init) |
| **Type** | Primitive types + `string` | Any type |
| **Storage** | No storage (inlined) | Stored as a field |
| **Instance or static** | Always static | Can be either |
| **Set in constructor** | No | Yes |

```csharp
class Config
{
    public const int MaxRetries = 3;              // inlined everywhere at compile time
    public readonly DateTime StartTime;           // set once in constructor
    public static readonly string AppName = "App"; // set once at startup

    public Config() { StartTime = DateTime.Now; }
}
```

**Pitfall:** `const` values are baked into the calling assembly at compile time. If you change a `const` in a library and don't recompile callers, they still use the old value. `readonly` avoids this.

---

## Q6. What are auto-implemented properties and when are backing fields needed?
**Answer:**
Auto-implemented properties let the compiler generate the backing field automatically:

```csharp
public string Name { get; set; }         // auto-implemented
public int Id { get; init; }             // init-only (C# 9+)
public DateTime CreatedAt { get; } = DateTime.Now; // with initializer
```

You need an explicit backing field when:
- You need **validation** in the setter.
- You need to **raise an event** (`INotifyPropertyChanged`).
- The getter computes a value from the field.

```csharp
private string _name;
public string Name
{
    get => _name;
    set
    {
        if (string.IsNullOrWhiteSpace(value)) throw new ArgumentException("Name required");
        _name = value;
        OnPropertyChanged(nameof(Name)); // MVVM binding notification
    }
}
```

---

## Q7. What are the `get`, `set`, and `init` accessors?
**Answer:**
- `get` — returns the property value. Can be made private/protected/internal.
- `set` — assigns the property value.
- `init` (C# 9+) — like `set`, but only callable during object construction or object initializers. Makes the property **immutable after construction**.

```csharp
class Product
{
    public int Id { get; init; }         // set only once
    public string Name { get; set; }     // mutable
    public decimal Price { get; private set; } // read-only externally

    public void ApplyDiscount(decimal pct) => Price *= (1 - pct);
}

var p = new Product { Id = 1, Name = "Widget", Price = 9.99m };
// p.Id = 2; // ❌ Cannot re-assign init-only
```

---

## Q8. What is the principle of "program to an interface, not an implementation"?
**Answer:**
Depend on abstractions (interfaces/abstract classes) rather than concrete types. This enables:
- **Flexibility** — swap implementations without changing callers.
- **Testability** — inject mock implementations in unit tests.
- **Loose coupling** — reducing dependency between components.

```csharp
// Bad — tightly coupled
class OrderService
{
    private SqlOrderRepository _repo = new SqlOrderRepository();
}

// Good — loosely coupled
class OrderService
{
    private readonly IOrderRepository _repo;
    public OrderService(IOrderRepository repo) { _repo = repo; }
}
```

---

## Q9. What is the difference between shallow copy and deep copy?
**Answer:**
- **Shallow copy** — copies the object's fields. For reference-type fields, only the reference is copied (both original and copy point to the same nested objects).
- **Deep copy** — recursively copies all nested objects so the two copies are fully independent.

```csharp
class Address { public string City; }
class Person  { public string Name; public Address Address; }

var original = new Person { Name = "Debanjan", Address = new Address { City = "Delhi" } };

// Shallow copy via MemberwiseClone
var shallow = (Person)original.MemberwiseClone();
shallow.Name = "Other";       // original.Name unchanged ✓
shallow.Address.City = "Mumbai"; // original.Address.City ALSO changes ❌

// Deep copy — manual or via serialization
var deep = new Person { Name = original.Name, Address = new Address { City = original.Address.City } };
```

---

## Q10. What is the Open/Closed Principle and how does encapsulation support it?
**Answer:**
The Open/Closed Principle (OCP, "O" in SOLID) states: classes should be **open for extension but closed for modification**. You should be able to add behaviour without changing existing code.

Encapsulation supports OCP because private internals cannot be reached externally — callers depend on the public contract. When you want new behaviour, you extend (subclass or compose) rather than modify:

```csharp
abstract class Discount
{
    public abstract decimal Apply(decimal price);
}

class PercentageDiscount : Discount
{
    public override decimal Apply(decimal price) => price * 0.9m; // new without touching base
}

class SeasonalDiscount : Discount
{
    public override decimal Apply(decimal price) => price - 50;   // another extension
}
```

The `Discount` hierarchy is open to extension (new discount types) but closed to modification (existing classes unchanged).

---

## Q11. What is `INotifyPropertyChanged` and why is it used?
**Answer:**
`INotifyPropertyChanged` is an interface that raises a `PropertyChanged` event whenever a property value changes. It is the foundation of **data binding** in WPF, MAUI, and Blazor:

```csharp
class UserViewModel : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    private string _name = "";
    public string Name
    {
        get => _name;
        set
        {
            if (_name != value)
            {
                _name = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Name)));
            }
        }
    }
}
```

UI controls subscribe to `PropertyChanged` and automatically refresh when the property changes. Modern toolkits use source generators (e.g., `[ObservableProperty]` in CommunityToolkit.Mvvm) to eliminate the boilerplate.

---

## Q12. What are `init`-only setters and how do they relate to encapsulation?
**Answer:**
`init` (C# 9+) creates properties that can be set **only during construction** (via constructor or object initializer), then become immutable:

```csharp
class Order
{
    public int Id { get; init; }         // set once, immutable after
    public DateTime CreatedAt { get; } = DateTime.UtcNow; // no setter at all
    public string Status { get; set; }   // mutable
}

var order = new Order { Id = 42, Status = "Pending" }; // ✓ init OK
// order.Id = 99; // ❌ compile error — init-only after construction
order.Status = "Shipped"; // ✓ regular setter
```

`init` is perfect for immutable DTOs and value objects where the identity must be fixed after creation.

---

## Q13. What is the difference between `private set` and `init`?
**Answer:**
| | `private set` | `init` |
|---|---|---|
| **Who can set** | Only code within the class | Constructor + object initializer |
| **When** | Any time | Only during object initialization |
| **External immutability** | Yes | Yes |
| **Internal mutability** | Yes (any method) | No (after construction, even internally) |

```csharp
class Product
{
    public int Id { get; private set; }   // class can change Id internally
    public string Name { get; init; }     // nobody can change Name after construction

    public void UpdateId(int newId) => Id = newId; // ✓ private set allows this
    // public void UpdateName(string n) => Name = n; // ❌ init does not allow this
}
```

---

## Q14. What are the access levels for property accessors?
**Answer:**
Property getters and setters can have **different, more restrictive** access levels than the property itself:

```csharp
class Account
{
    public decimal Balance { get; private set; }     // read publicly, set privately
    public string Name    { get; protected set; }    // set by derived classes
    public int    Version { get; internal set; }     // set within assembly
    public string Id      { get; init; }             // set only during construction

    public void Deposit(decimal amount)
    {
        if (amount <= 0) throw new ArgumentException("Amount must be positive");
        Balance += amount;  // private setter used internally
    }
}
```

The accessor's access modifier must be **more restrictive** than the property's (you cannot make the setter `public` if the property is `internal`).

---

## Q15. What is the Law of Demeter and how does encapsulation support it?
**Answer:**
The Law of Demeter ("Don't talk to strangers") states: a method should only call methods on its **direct dependencies**, not on objects obtained from those dependencies.

```csharp
// Violates Law of Demeter — "train wreck"
decimal tax = order.Customer.Address.Region.TaxRate;

// Better — encapsulate the navigation in the domain
decimal tax = order.GetApplicableTaxRate();

// In Order class:
public decimal GetApplicableTaxRate()
    => _customer.GetRegionTaxRate(); // delegates internally
```

Violating the Law of Demeter creates tight coupling between classes. If `Address` or `Region` changes its structure, every caller that chains through them must change too. Encapsulating that navigation inside the owning class contains the change.
