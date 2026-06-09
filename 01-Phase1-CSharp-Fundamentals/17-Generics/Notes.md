# Topic 17: Generics

## What Are Generics?

Generics let you write **one piece of code** that works with **any data type**, while still being type-safe. Instead of writing separate methods for `int`, `string`, `Employee`, etc., you write it once with a **type parameter** `<T>`.

```csharp
// ❌ Without generics — duplicate code for each type
void PrintInt(int value) => Console.WriteLine(value);
void PrintString(string value) => Console.WriteLine(value);
void PrintDouble(double value) => Console.WriteLine(value);

// ✅ With generics — one method for ALL types
void Print<T>(T value) => Console.WriteLine(value);

Print(42);          // T is int
Print("Hello");     // T is string
Print(3.14);        // T is double
Print(true);        // T is bool
```

---

## Why Not Just Use object?

```csharp
// Using object — works but has problems
void PrintObject(object value) => Console.WriteLine(value);
PrintObject(42);      // Boxing: int → object (heap allocation)
PrintObject("Hello"); // Works but no type safety

// What if you expect an int but get a string?
object result = GetValue(); // Returns object
int number = (int)result;   // 💥 InvalidCastException if it's actually a string!

// Generics solve this:
T GetValue<T>() { /* ... */ }
int number = GetValue<int>(); // Compile-time type safety, no casting, no boxing
```

| Feature | object | Generics |
|---|---|---|
| Type safety | ❌ Runtime errors | ✅ Compile-time errors |
| Boxing/unboxing | ❌ Yes (for value types) | ✅ No |
| Performance | ❌ Slower | ✅ Faster |
| IntelliSense | ❌ No suggestions | ✅ Full IDE support |

---

## Generic Methods

### Basic Generic Method

```csharp
// T is a placeholder — replaced by actual type when called
T GetMax<T>(T a, T b) where T : IComparable<T>
{
    return a.CompareTo(b) > 0 ? a : b;
}

Console.WriteLine(GetMax(10, 20));         // 20
Console.WriteLine(GetMax("Apple", "Mango")); // Mango
Console.WriteLine(GetMax(3.14, 2.71));     // 3.14
```

### Multiple Type Parameters

```csharp
// Two different type parameters
void PrintPair<TKey, TValue>(TKey key, TValue value)
{
    Console.WriteLine($"Key: {key}, Value: {value}");
}

PrintPair("Name", "Debanjan");  // TKey=string, TValue=string
PrintPair("Age", 25);           // TKey=string, TValue=int
PrintPair(1, true);             // TKey=int, TValue=bool

// Returning a tuple
(TKey Key, TValue Value) MakePair<TKey, TValue>(TKey key, TValue value)
{
    return (key, value);
}

var pair = MakePair("Score", 95);
Console.WriteLine($"{pair.Key}: {pair.Value}"); // Score: 95
```

### Generic Method with Arrays

```csharp
void Swap<T>(ref T a, ref T b)
{
    T temp = a;
    a = b;
    b = temp;
}

int x = 10, y = 20;
Swap(ref x, ref y);
Console.WriteLine($"x={x}, y={y}"); // x=20, y=10

string s1 = "Hello", s2 = "World";
Swap(ref s1, ref s2);
Console.WriteLine($"{s1}, {s2}"); // World, Hello

// Find an element
int FindIndex<T>(T[] array, T target) where T : IEquatable<T>
{
    for (int i = 0; i < array.Length; i++)
    {
        if (array[i].Equals(target))
            return i;
    }
    return -1;
}

int[] nums = { 10, 20, 30, 40 };
Console.WriteLine(FindIndex(nums, 30)); // 2
```

---

## Generic Classes

### Basic Generic Class

```csharp
public class Box<T>
{
    public T Value { get; set; }

    public Box(T value)
    {
        Value = value;
    }

    public override string ToString() => $"Box<{typeof(T).Name}>: {Value}";
}

Box<int> intBox = new Box<int>(42);
Box<string> strBox = new Box<string>("Hello");
Box<List<int>> listBox = new Box<List<int>>(new List<int> { 1, 2, 3 });

Console.WriteLine(intBox);    // Box<Int32>: 42
Console.WriteLine(strBox);    // Box<String>: Hello
```

### Generic Stack Implementation

```csharp
public class SimpleStack<T>
{
    private T[] _items;
    private int _count;

    public SimpleStack(int capacity = 16)
    {
        _items = new T[capacity];
        _count = 0;
    }

    public int Count => _count;
    public bool IsEmpty => _count == 0;

    public void Push(T item)
    {
        if (_count == _items.Length)
            Array.Resize(ref _items, _items.Length * 2);
        
        _items[_count++] = item;
    }

    public T Pop()
    {
        if (IsEmpty)
            throw new InvalidOperationException("Stack is empty.");
        
        T item = _items[--_count];
        _items[_count] = default!; // Clear reference for GC
        return item;
    }

    public T Peek()
    {
        if (IsEmpty)
            throw new InvalidOperationException("Stack is empty.");
        
        return _items[_count - 1];
    }
}

// Usage
var intStack = new SimpleStack<int>();
intStack.Push(10);
intStack.Push(20);
Console.WriteLine(intStack.Pop()); // 20

var stringStack = new SimpleStack<string>();
stringStack.Push("First");
stringStack.Push("Second");
Console.WriteLine(stringStack.Peek()); // Second
```

### Multiple Type Parameters in Classes

```csharp
public class KeyValueStore<TKey, TValue>
{
    private Dictionary<TKey, TValue> _store = new();

    public void Set(TKey key, TValue value) => _store[key] = value;
    
    public TValue? Get(TKey key)
    {
        _store.TryGetValue(key, out TValue? value);
        return value;
    }

    public bool ContainsKey(TKey key) => _store.ContainsKey(key);
    
    public int Count => _store.Count;
}

var settings = new KeyValueStore<string, object>();
settings.Set("Theme", "Dark");
settings.Set("FontSize", 14);
settings.Set("ShowLineNumbers", true);

Console.WriteLine(settings.Get("Theme")); // Dark
```

---

## Generic Interfaces

```csharp
// Define a generic interface
public interface IRepository<T>
{
    T GetById(int id);
    List<T> GetAll();
    void Add(T item);
    void Update(T item);
    void Delete(int id);
}

// Implement for a specific type
public class Employee
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public decimal Salary { get; set; }
}

public class EmployeeRepository : IRepository<Employee>
{
    private List<Employee> _employees = new();

    public Employee GetById(int id) => 
        _employees.FirstOrDefault(e => e.Id == id)
        ?? throw new KeyNotFoundException($"Employee {id} not found.");

    public List<Employee> GetAll() => new List<Employee>(_employees);

    public void Add(Employee item) => _employees.Add(item);

    public void Update(Employee item)
    {
        int index = _employees.FindIndex(e => e.Id == item.Id);
        if (index >= 0) _employees[index] = item;
    }

    public void Delete(int id) => _employees.RemoveAll(e => e.Id == id);
}

// Now you can create repositories for ANY type
public class ProductRepository : IRepository<Product> { /* ... */ }
public class OrderRepository : IRepository<Order> { /* ... */ }
```

---

## Generic Constraints (where keyword)

Constraints **restrict** what types can be used as `T`. This lets you safely call methods on `T`.

### Available Constraints

```csharp
// where T : struct          — T must be a value type (int, double, bool, struct)
// where T : class           — T must be a reference type (string, class, interface)
// where T : new()           — T must have a parameterless constructor
// where T : BaseClass       — T must inherit from BaseClass
// where T : IInterface      — T must implement IInterface
// where T : notnull         — T cannot be nullable
// where T : unmanaged       — T must be unmanaged type (no reference types inside)
```

### Constraint Examples

```csharp
// T must implement IComparable
T FindMin<T>(T[] items) where T : IComparable<T>
{
    T min = items[0];
    foreach (T item in items)
    {
        if (item.CompareTo(min) < 0)
            min = item;
    }
    return min;
}

// T must be a class with parameterless constructor
T CreateDefault<T>() where T : class, new()
{
    return new T(); // Only works because of 'new()' constraint
}

// T must inherit from a base class
void ProcessAnimal<T>(T animal) where T : Animal
{
    animal.Speak();   // Safe — all Animals have Speak()
    animal.Eat();     // Safe — all Animals have Eat()
}

// Multiple constraints
void Save<T>(T entity) where T : class, IEntity, new()
{
    // T is a reference type, implements IEntity, and has parameterless constructor
}

// Multiple type parameters with different constraints
void Map<TSource, TDest>(TSource source, TDest destination)
    where TSource : class
    where TDest : class, new()
{
    // ...
}
```

### Practical: Generic Validator

```csharp
public interface IValidatable
{
    bool IsValid();
    string GetValidationError();
}

public class Validator<T> where T : IValidatable
{
    public bool Validate(T item, out string error)
    {
        if (item.IsValid())
        {
            error = "";
            return true;
        }
        error = item.GetValidationError();
        return false;
    }

    public List<T> FilterValid(List<T> items)
    {
        return items.Where(item => item.IsValid()).ToList();
    }
}

public class Email : IValidatable
{
    public string Address { get; set; } = "";
    
    public bool IsValid() => Address.Contains("@") && Address.Contains(".");
    public string GetValidationError() => $"'{Address}' is not a valid email.";
}

var validator = new Validator<Email>();
var email = new Email { Address = "debanjan@example.com" };
if (validator.Validate(email, out string error))
    Console.WriteLine("✓ Valid!");
else
    Console.WriteLine($"✗ {error}");
```

---

## Generic Delegates (Revisited)

You already know `Func<T>`, `Action<T>`, and `Predicate<T>` — these are generic delegates!

```csharp
// Custom generic delegate
delegate TResult Transformer<TInput, TResult>(TInput input);

Transformer<string, int> getLength = s => s.Length;
Transformer<int, string> toHex = n => n.ToString("X");

Console.WriteLine(getLength("Hello")); // 5
Console.WriteLine(toHex(255));         // FF

// Generic method that accepts generic delegates
List<TResult> Map<TSource, TResult>(List<TSource> source, Func<TSource, TResult> transform)
{
    List<TResult> result = new List<TResult>();
    foreach (TSource item in source)
        result.Add(transform(item));
    return result;
}

List<int> numbers = new List<int> { 1, 2, 3, 4, 5 };
List<string> strings = Map(numbers, n => $"Number: {n}");
List<int> doubled = Map(numbers, n => n * 2);
```

---

## Covariance and Contravariance (out / in)

### Covariance (out) — "output" position

```csharp
// IEnumerable<out T> is covariant
IEnumerable<string> strings = new List<string> { "Hello" };
IEnumerable<object> objects = strings; // ✅ Works! string → object (upcast)

// Your own covariant interface
interface IProducer<out T>
{
    T Produce(); // T only in OUTPUT position
}

class AnimalProducer : IProducer<Animal>
{
    public Animal Produce() => new Dog();
}

IProducer<Animal> producer = new DogProducer(); // ✅ Dog → Animal
```

### Contravariance (in) — "input" position

```csharp
// Action<in T> is contravariant
Action<object> printObject = obj => Console.WriteLine(obj);
Action<string> printString = printObject; // ✅ Works! object → string (downcast)

// Your own contravariant interface
interface IConsumer<in T>
{
    void Consume(T item); // T only in INPUT position
}
```

### Simple Rule

- `out T` → T can be more specific (child types OK) — used for return types
- `in T` → T can be more general (parent types OK) — used for parameter types

---

## Generic Collections You Already Know

Every collection you learned in Topic 12 is generic!

```csharp
List<T>                        // Dynamic array of T
Dictionary<TKey, TValue>       // Key-value pairs
HashSet<T>                     // Unique elements
Queue<T>                       // FIFO
Stack<T>                       // LIFO
LinkedList<T>                  // Doubly-linked list
SortedDictionary<TKey, TValue> // Sorted by key
SortedSet<T>                   // Sorted unique set
```

---

## Static Members in Generic Classes

Each closed generic type (`Box<int>`, `Box<string>`) has its **own** static members.

```csharp
public class Counter<T>
{
    private static int _count = 0;
    
    public Counter() { _count++; }
    
    public static int Count => _count;
}

new Counter<int>();
new Counter<int>();
new Counter<string>();

Console.WriteLine(Counter<int>.Count);    // 2
Console.WriteLine(Counter<string>.Count); // 1 (separate counter!)
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| `<T>` | Type parameter placeholder — replaced at compile time |
| Generic methods | One method works with any type: `Print<T>(T value)` |
| Generic classes | One class works with any type: `Box<T>` |
| Generic interfaces | Contracts for any type: `IRepository<T>` |
| Constraints (`where`) | Restrict what types T can be |
| `where T : class` | Must be reference type |
| `where T : struct` | Must be value type |
| `where T : new()` | Must have parameterless constructor |
| `where T : IInterface` | Must implement interface |
| Covariance (`out T`) | Allow subtype substitution in outputs |
| Contravariance (`in T`) | Allow supertype substitution in inputs |
| No boxing | Value types stay on stack — better performance |

---

*Next Topic: Phase 1 Revision Test →*
