# Topic 17: Generics — Interview Questions

---

## Q1. What are generics and why are they used?
**Answer:**
Generics allow you to write **type-parameterized** classes, methods, interfaces, and delegates. They provide:
- **Type safety** — type errors caught at compile time.
- **Performance** — avoids boxing/unboxing (no `object` cast overhead).
- **Code reuse** — one implementation works for any type.

```csharp
// Without generics — loses type safety, causes boxing for value types
ArrayList list = new ArrayList();
list.Add(1);
int n = (int)list[0]; // explicit cast needed; wrong cast = runtime exception

// With generics — type-safe, no boxing
List<int> list = new List<int>();
list.Add(1);
int n = list[0]; // no cast needed; compiler enforces type
```

---

## Q2. What are type constraints on generic parameters?
**Answer:**
Constraints restrict what types can be used for a type parameter:

| Constraint | Meaning |
|---|---|
| `where T : class` | T must be a reference type |
| `where T : struct` | T must be a value type (non-nullable) |
| `where T : new()` | T must have a public parameterless constructor |
| `where T : SomeClass` | T must be (or derive from) `SomeClass` |
| `where T : ISomeInterface` | T must implement `ISomeInterface` |
| `where T : U` | T must be the same as or derive from U |
| `where T : notnull` | T cannot be a nullable type (C# 8+) |
| `where T : unmanaged` | T must be an unmanaged value type |

```csharp
class Repository<T> where T : class, new()
{
    public T Create() => new T();  // new() constraint allows this
}

T Max<T>(T a, T b) where T : IComparable<T>
    => a.CompareTo(b) >= 0 ? a : b;
```

---

## Q3. What is the difference between a generic class and a generic method?
**Answer:**
- **Generic class** — the type parameter applies to the entire class. Specified when instantiating.
- **Generic method** — the type parameter is local to the method. Inferred or specified at call site.

```csharp
// Generic class
class Box<T>
{
    public T Value { get; set; }
}

var intBox = new Box<int> { Value = 42 };
var strBox = new Box<string> { Value = "Hello" };

// Generic method (type inferred from argument)
T Identity<T>(T value) => value;

int n = Identity(42);          // T inferred as int
string s = Identity("hello");  // T inferred as string
string s2 = Identity<string>("explicit"); // explicit type arg
```

---

## Q4. What is covariance and contravariance in generics?
**Answer:**
- **Covariance** (`out T`) — allows a generic type to be treated as a **more general** type. Think: "produce/return T". Used with `IEnumerable<out T>`, `IReadOnlyList<out T>`.
- **Contravariance** (`in T`) — allows a generic type to be treated as a **more specific** type. Think: "consume/accept T". Used with `Action<in T>`, `IComparer<in T>`.

```csharp
// Covariance
IEnumerable<string> strings = new List<string>();
IEnumerable<object> objects = strings;  // ✓ covariant — string is object

// Contravariance
Action<object> actObject = obj => Console.WriteLine(obj);
Action<string> actString = actObject;  // ✓ contravariant — can accept string as object

// Invariant — regular generic classes are invariant
List<string> ls = new List<string>();
// List<object> lo = ls; // ❌ compile error — List<T> is invariant
```

---

## Q5. What is a generic interface? Give a real-world example.
**Answer:**
A generic interface defines a contract parameterized by one or more types.

```csharp
interface IRepository<T> where T : class
{
    T GetById(int id);
    IEnumerable<T> GetAll();
    void Add(T entity);
    void Delete(int id);
}

class UserRepository : IRepository<User>
{
    public User GetById(int id) => _db.Users.Find(id);
    public IEnumerable<User> GetAll() => _db.Users.ToList();
    public void Add(User user) => _db.Users.Add(user);
    public void Delete(int id) => _db.Users.Remove(_db.Users.Find(id));
}
```

Benefits: the `IRepository<T>` contract can be used with any entity type without duplicating the interface definition. It also enables easy mocking in unit tests.

---

## Q6. What is the difference between `T` and `object` in a generic method?
**Answer:**
| | `T` (generic) | `object` |
|---|---|---|
| **Type safety** | Preserved — caller's type maintained | Lost — cast required on retrieval |
| **Boxing** | No — value types stay as value types | Yes — value types boxed to object |
| **IntelliSense** | Full — IDE knows the actual type | None |
| **Performance** | Better (no allocation for value types) | Worse |

```csharp
// With object — boxing + cast required
object o = 42;             // boxes int → heap allocation
int n = (int)o;            // explicit unboxing cast

// With T — no boxing, type preserved
T Echo<T>(T val) => val;
int n = Echo(42);          // no boxing, no cast
```

---

## Q7. How does the CLR handle generics vs Java's type erasure?
**Answer:**
.NET generics are **reified** — the actual type information is preserved at runtime:
- A separate native code version is JIT-compiled for each distinct value type (`List<int>`, `List<double>` generate different code).
- Reference types share one JIT-compiled version (since all references are the same size).

Java uses **type erasure** — generic type information is removed at compile time, and everything becomes `Object` at runtime. This is why Java has `List<Integer>` (boxed) instead of `List<int>`.

**Benefits of .NET's approach:** Better performance for value types (no boxing), full type info available via reflection at runtime.

---

## Q8. What is a generic delegate and how is it used?
**Answer:**
Generic delegates allow you to define reusable delegate types. The built-in `Action<T>`, `Func<T, TResult>`, and `Predicate<T>` are generic delegates.

```csharp
// Custom generic delegate
delegate TResult Transformer<T, TResult>(T input);

Transformer<string, int> lengthOf = s => s.Length;
int len = lengthOf("Hello"); // 5

// Equivalent with Func
Func<string, int> lengthOf = s => s.Length;
```

Generic delegates combine with lambdas and LINQ to enable powerful functional patterns.

---

## Q9. What is the `default(T)` keyword in generics?
**Answer:**
`default(T)` returns the default value for a type parameter:
- For reference types: `null`
- For value types: zero-equivalent (`0`, `false`, etc.)

```csharp
T CreateDefault<T>() => default(T);  // or just default

int n = CreateDefault<int>();        // 0
string s = CreateDefault<string>();  // null
bool b = CreateDefault<bool>();      // false

// Short form (C# 7.1+)
T val = default;  // type inferred from context
```

---

## Q10. What are the SOLID principles and how do generics support them?
**Answer:**
Generics directly support three SOLID principles:

1. **Single Responsibility** — a generic `Repository<T>` handles CRUD for any entity without code duplication.
2. **Open/Closed** — generic classes can be extended for new types without modifying the existing code.
3. **Dependency Inversion** — `IRepository<T>` is an abstraction; `UserRepository` is a concrete implementation injected via DI.

```csharp
// One interface, many implementations
interface ICache<T> where T : class
{
    T Get(string key);
    void Set(string key, T value);
}

class MemoryCache<T> : ICache<T> where T : class { }
class RedisCache<T>  : ICache<T> where T : class { }

// Inject via DI — callers depend on abstraction
class ProductService
{
    public ProductService(ICache<Product> cache) { }
}

---

## Q11. What are open and closed generic types?
**Answer:**
- **Open generic type** — has unbound type parameters. Cannot be instantiated. Used in reflection and type registration.
- **Closed generic type** — all type parameters are specified. Can be instantiated.

```csharp
// Open generic types (cannot instantiate)
Type open = typeof(List<>);                // List`1
Type openDict = typeof(Dictionary<,>);    // Dictionary`2

// Closed generic types (can instantiate)
Type closed = typeof(List<int>);           // List`1[System.Int32]
var list = new List<int>();                // instance

// Create closed from open at runtime (reflection)
Type constructed = open.MakeGenericType(typeof(string)); // List<string>
var instance = Activator.CreateInstance(constructed);   // new List<string>()
```

In dependency injection frameworks, you can register open generic types: `services.AddSingleton(typeof(IRepository<>), typeof(Repository<>));`

---

## Q12. What is generic type inference and where does it apply?
**Answer:**
The C# compiler infers type arguments from the method's **argument types**, so you don't need to specify them explicitly:

```csharp
T Max<T>(T a, T b) where T : IComparable<T>
    => a.CompareTo(b) >= 0 ? a : b;

// Explicit
int r1 = Max<int>(3, 7);        // 7
string r2 = Max<string>("a", "b"); // "b"

// Inferred (preferred)
int r3 = Max(3, 7);             // T inferred as int
string r4 = Max("a", "b");      // T inferred as string
```

Inference **does not work** when:
- The type argument is only used in the return type (not parameters).
- There is ambiguity between overloads.
- Calling with `null` (use `Max<string>(null, "a")` explicitly).

---

## Q13. What is the difference between `T?` and `Nullable<T>` in generics?
**Answer:**
With nullable reference types enabled (`<Nullable>enable</Nullable>`):

- `T?` where `T : class` — nullable reference type (compile-time annotation only, no runtime change).
- `T?` where `T : struct` — compiles to `Nullable<T>` (runtime wrapper with `.HasValue` / `.Value`).
- In an **unconstrained generic** `T?`, the compiler cannot determine which case applies:

```csharp
void Process<T>(T? value)  // ambiguous — struct or class?
{ }

// Solution: add constraint
void ProcessClass<T>(T? value)  where T : class  { } // reference nullable
void ProcessStruct<T>(T? value) where T : struct  { } // Nullable<T>

// Or use the MaybeNull attribute
void Process<T>([MaybeNull] T value) { }
```

---

## Q14. What is generic type caching with static fields?
**Answer:**
A **static field in a generic class** gets a **separate copy** for each closed type — this is a powerful caching pattern:

```csharp
class TypeCache<T>
{
    public static readonly string TypeName = typeof(T).Name;
    public static int InstanceCount = 0;
}

// Each T gets its own static field
Console.WriteLine(TypeCache<int>.TypeName);    // "Int32"
Console.WriteLine(TypeCache<string>.TypeName); // "String"
TypeCache<int>.InstanceCount++;  // only affects int version

// Practical use: per-type serializer caching
class JsonHelper<T>
{
    private static readonly JsonSerializerOptions _options = new() { WriteIndented = true };
    public static string Serialize(T obj) => JsonSerializer.Serialize(obj, _options);
}
```

---

## Q15. What is the difference between generic constraints and runtime `is` checks?
**Answer:**
Generic constraints enforce type requirements **at compile time**. Runtime `is` checks work **at runtime** but sacrifice type safety:

```csharp
// Compile-time constraint — type safe, IntelliSense works
void Sort<T>(List<T> list) where T : IComparable<T>
    => list.Sort(); // compiler knows T has CompareTo

// Runtime check — less safe, no IntelliSense on the typed result
void TrySort<T>(List<T> list)
{
    if (list is List<IComparable> comparables)
        comparables.Sort(); // works but loses T information
}

// Pattern matching with generics
void Process<T>(T value)
{
    if (value is string s) Console.WriteLine(s.ToUpper()); // OK
    if (value is int n)    Console.WriteLine(n * 2);       // OK
}
```

Prefer compile-time constraints. Use runtime checks only when you genuinely need to handle multiple unrelated types in the same generic method, or when consuming objects from reflection/dynamic sources.
```
