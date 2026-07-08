# Topic 14: Delegates, Events, and Lambdas — Interview Questions

---

## Q1. What is a delegate in C#?
**Answer:**
A delegate is a **type-safe function pointer** — a reference type that holds a reference to a method with a specific signature.

```csharp
delegate int MathOperation(int a, int b);

int Add(int a, int b) => a + b;
int Multiply(int a, int b) => a * b;

MathOperation op = Add;
Console.WriteLine(op(3, 4)); // 7

op = Multiply;
Console.WriteLine(op(3, 4)); // 12
```

Delegates enable: callbacks, event handling, passing methods as arguments, and functional programming patterns (LINQ, etc.).

---

## Q2. What are `Action`, `Func`, and `Predicate`?
**Answer:**
These are built-in generic delegate types that eliminate the need to declare custom delegates for common signatures:

| Type | Signature | Returns |
|---|---|---|
| `Action` | `Action<T1, T2, ...>` | `void` (up to 16 params) |
| `Func` | `Func<T1, T2, ..., TResult>` | `TResult` (last type param) |
| `Predicate<T>` | `Predicate<T>` | `bool` — equivalent to `Func<T, bool>` |

```csharp
Action<string> log = msg => Console.WriteLine(msg);
log("Hello"); // void

Func<int, int, int> add = (a, b) => a + b;
int result = add(3, 4); // 7

Predicate<int> isEven = n => n % 2 == 0;
bool check = isEven(4); // true
```

---

## Q3. What is a multicast delegate?
**Answer:**
A delegate can hold references to **multiple methods**. When invoked, it calls all methods in the invocation list in order.

```csharp
Action<string> notify = null;
notify += SendEmail;
notify += SendSMS;
notify += LogToFile;

notify("Order shipped!"); // calls all three methods

notify -= SendSMS; // remove from invocation list
```

If any method in the chain throws an exception, subsequent methods are NOT called. If the delegate has a non-void return type, only the last method's return value is accessible.

---

## Q4. What is the difference between a delegate and an event?
**Answer:**
An `event` is a **restricted delegate** — it prevents external code from replacing (`=`) or invoking the delegate directly. Only `+=` and `-=` are allowed from outside the class.

```csharp
class Button
{
    private Action _onClick;          // delegate — external code can set = null or invoke
    public event Action OnClicked;    // event — external code can only += or -=

    public void Click()
    {
        OnClicked?.Invoke(); // only the owning class can invoke
    }
}

Button btn = new Button();
btn.OnClicked += () => Console.WriteLine("Clicked!");
// btn.OnClicked = null;       // ❌ not allowed externally
// btn.OnClicked();            // ❌ not allowed externally
btn.Click();                   // ✓ fires through the class
```

---

## Q5. What is a lambda expression?
**Answer:**
A lambda is an **anonymous method** (inline function) using the `=>` syntax. It can be used anywhere a delegate or expression tree is expected.

```csharp
// Statement lambda (block body)
Func<int, int> square = x => { return x * x; };

// Expression lambda (single expression — preferred)
Func<int, int> square = x => x * x;

// Multiple parameters
Func<int, int, int> add = (a, b) => a + b;

// No parameters
Action greet = () => Console.WriteLine("Hello");

// Used inline with LINQ
var evens = numbers.Where(n => n % 2 == 0);
```

---

## Q6. What is a closure and what are its pitfalls?
**Answer:**
A **closure** is a lambda that captures variables from its enclosing scope. The lambda holds a reference to the variable, not a copy of its value at capture time.

```csharp
var funcs = new List<Func<int>>();
for (int i = 0; i < 3; i++)
{
    int captured = i;                      // create a separate variable per iteration
    funcs.Add(() => captured);             // ✓ captures the per-loop variable
}
// Without the 'captured' variable: all lambdas capture the same 'i', which is 3 after the loop
```

**Common pitfall:**
```csharp
for (int i = 0; i < 3; i++)
    funcs.Add(() => i);     // all lambdas capture same 'i'
// funcs[0]() = 3, funcs[1]() = 3, funcs[2]() = 3 (all return 3)
```

---

## Q7. What is an anonymous method and how does it differ from a lambda?
**Answer:**
Anonymous methods (introduced in C# 2) use the `delegate` keyword. Lambdas (C# 3+) are the modern, concise replacement.

```csharp
// Anonymous method
Func<int, int> square = delegate(int x) { return x * x; };

// Equivalent lambda
Func<int, int> square = x => x * x;
```

Differences:
- Lambdas can be converted to **expression trees** (`Expression<Func<T>>`); anonymous methods cannot.
- Lambdas can omit parameter types (inferred); anonymous methods cannot.
- `delegate` without parameters can capture block-scoped variables (same as lambda).

---

## Q8. What is `EventHandler` and the standard event pattern?
**Answer:**
The standard .NET event pattern uses `EventHandler<TEventArgs>` and a derived `EventArgs` class:

```csharp
class OrderEventArgs : EventArgs
{
    public int OrderId { get; init; }
}

class OrderProcessor
{
    public event EventHandler<OrderEventArgs>? OrderCompleted;

    protected virtual void OnOrderCompleted(OrderEventArgs e)
        => OrderCompleted?.Invoke(this, e);

    public void Process(int orderId)
    {
        // ...processing...
        OnOrderCompleted(new OrderEventArgs { OrderId = orderId });
    }
}

// Subscriber
processor.OrderCompleted += (sender, e)
    => Console.WriteLine($"Order {e.OrderId} completed by {sender}");
```

Using `?.Invoke` is thread-safer than a null check + separate invocation in multi-threaded code.

---

## Q9. What is an expression tree (`Expression<Func<T>>`)?
**Answer:**
An expression tree is a runtime representation of a lambda as a **data structure** (AST) that can be inspected, modified, or compiled. It enables LINQ-to-SQL to translate C# lambdas into SQL.

```csharp
// Delegate — compiled code, not inspectable
Func<int, bool> del = x => x > 5;

// Expression tree — data structure, can be inspected
Expression<Func<int, bool>> expr = x => x > 5;
// expr.Body, expr.Parameters, etc. are accessible
// EF Core uses these to build SQL: WHERE x > 5

// Compile to a delegate when needed
Func<int, bool> compiled = expr.Compile();
compiled(10); // true
```

---

## Q10. What are `Func<T>` vs `Lazy<T>`? When do you use each?
**Answer:**
- `Func<T>` — a delegate that computes a value every time it is called.
- `Lazy<T>` — wraps a factory function and computes the value only **once** on first access, then caches it.

```csharp
Func<string> getConfig = () => File.ReadAllText("config.json");
string c1 = getConfig(); // reads file
string c2 = getConfig(); // reads file again

Lazy<string> lazyConfig = new Lazy<string>(() => File.ReadAllText("config.json"));
string c1 = lazyConfig.Value; // reads file once
string c2 = lazyConfig.Value; // returns cached result

// Thread-safe by default (LazyThreadSafetyMode.ExecutionAndPublication)
```

`Lazy<T>` is ideal for expensive initializations (heavy objects, DB connections, file reads) where the value may not always be needed.

---

## Q11. What is a weak event pattern and why is it needed?
**Answer:**
In normal event subscriptions, the event source holds a **strong reference** to the handler. If the handler is part of a subscriber that should be garbage collected, the event source prevents it from being collected — a **memory leak**.

```csharp
// Memory leak — DataService holds reference to ViewModel forever
class ViewModel
{
    public ViewModel(DataService svc)
    {
        svc.DataChanged += OnDataChanged; // strong reference
    }
    void OnDataChanged(object? sender, EventArgs e) { }
    // Even when ViewModel goes out of scope, DataService keeps it alive!
}
```

**Weak event pattern** uses `WeakReference` to allow the subscriber to be GC'd:
```csharp
// Using WeakEventManager (WPF) or manual WeakReference approach
WeakEventManager<DataService, EventArgs>.AddHandler(
    service, nameof(service.DataChanged), OnDataChanged);
```

In modern code, `IDisposable` with event unsubscription in `Dispose()` is the simplest solution.

---

## Q12. What is the difference between synchronous and asynchronous delegate invocation?
**Answer:**
```csharp
Action work = () => Console.WriteLine("Work done");

// Synchronous — blocks calling thread until complete
work.Invoke();  // or just: work();

// Asynchronous — run on thread pool (legacy approach)
work.BeginInvoke(callback: null, object: null); // .NET Framework only — not available in .NET Core+

// Modern async equivalent
await Task.Run(work);
```

In .NET Core / .NET 5+, `BeginInvoke` and `EndInvoke` on delegates are **not supported** and throw `PlatformNotSupportedException`. Use `Task.Run()` instead.

---

## Q13. What is `Delegate.Combine` and `Delegate.Remove`?
**Answer:**
These are the underlying static methods that `+=` and `-=` delegate operators compile to:

```csharp
Action a = () => Console.Write("A ");
Action b = () => Console.Write("B ");

// += compiles to:
Action combined = (Action)Delegate.Combine(a, b);
combined(); // "A B "

// -= compiles to:
Action single = (Action)Delegate.Remove(combined, b);
single(); // "A "

// Remove a delegate not in the list — returns original, no error
Action unchanged = (Action)Delegate.Remove(a, b); // unchanged == a
```

Delegates are **immutable** — `Combine` and `Remove` always return a **new delegate** object. The original delegates are unchanged.

---

## Q14. What are anonymous types and how do they relate to delegates/LINQ?
**Answer:**
Anonymous types are compiler-generated immutable classes with properties inferred from the initializer. They are primarily used in **LINQ projections**:

```csharp
// Classic anonymous type usage in LINQ
var summaries = employees
    .Where(e => e.IsActive)
    .Select(e => new { e.Name, e.Department, YearsService = e.YearsAt(DateTime.Today) });

foreach (var s in summaries)
    Console.WriteLine($"{s.Name} in {s.Department}: {s.YearsService} years");
```

The compiler generates a class named something like `<>f__AnonymousType0` with value-based `Equals` and `GetHashCode`. Two anonymous type instances with the same property names and types in the same assembly share the same generated class.

**Modern alternative:** Use `record` or `(Type Name, ...)` named tuples for anonymous-type-like scenarios when the type needs to cross method boundaries.

---

## Q15. What is the observer design pattern and how does it relate to events in C#?
**Answer:**
The Observer pattern defines a one-to-many dependency: when one object changes state, all its dependents are notified automatically. **C# events are the built-in implementation of the observer pattern**.

```csharp
// Subject (publisher)
class StockMarket
{
    public event EventHandler<StockEventArgs>? PriceChanged;

    public void UpdatePrice(string ticker, decimal newPrice)
    {
        // ... update logic
        PriceChanged?.Invoke(this, new StockEventArgs(ticker, newPrice));
    }
}

// Observers (subscribers)
class StockDashboard
{
    public void Subscribe(StockMarket market)
        => market.PriceChanged += OnPriceChanged;

    public void Unsubscribe(StockMarket market)
        => market.PriceChanged -= OnPriceChanged;

    private void OnPriceChanged(object? sender, StockEventArgs e)
        => Console.WriteLine($"{e.Ticker}: {e.Price:C}");
}
```

For more complex scenarios, `IObservable<T>` / `IObserver<T>` (Reactive Extensions, Rx.NET) provide a richer implementation of the observer pattern.
