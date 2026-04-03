# Topic 14: Delegates, Events & Lambda Expressions

## What is a Delegate?

A delegate is a **type-safe function pointer** — a variable that holds a reference to a method. It lets you pass methods as arguments, store them in variables, and call them later.

```csharp
// Define a delegate type
delegate int MathOperation(int a, int b);

// Methods that match the delegate signature
int Add(int a, int b) => a + b;
int Multiply(int a, int b) => a * b;

// Use the delegate
MathOperation operation = Add;
Console.WriteLine(operation(5, 3)); // 8

operation = Multiply;
Console.WriteLine(operation(5, 3)); // 15
```

**Think of it like**: A TV remote (delegate) that can be programmed to control any TV (method) — as long as the buttons match (same signature).

---

## Declaring and Using Delegates

### Step-by-Step

```csharp
// Step 1: Declare the delegate type
delegate void Greeting(string name);

// Step 2: Create methods with matching signature
void SayHello(string name) => Console.WriteLine($"Hello, {name}!");
void SayGoodbye(string name) => Console.WriteLine($"Goodbye, {name}!");

// Step 3: Assign and invoke
Greeting greet = SayHello;
greet("Debanjan");     // Hello, Debanjan!

greet = SayGoodbye;
greet("Debanjan");     // Goodbye, Debanjan!
```

### Delegates as Method Parameters

This is where delegates become truly powerful — **passing behavior as a parameter**.

```csharp
delegate bool FilterCondition(int number);

void PrintFiltered(int[] numbers, FilterCondition filter)
{
    foreach (int n in numbers)
    {
        if (filter(n))
            Console.Write($"{n} ");
    }
    Console.WriteLine();
}

bool IsEven(int n) => n % 2 == 0;
bool IsPositive(int n) => n > 0;
bool IsGreaterThan5(int n) => n > 5;

int[] nums = { -3, 1, 4, 7, 2, 8, -1, 6, 10 };

PrintFiltered(nums, IsEven);         // 4 2 8 6 10
PrintFiltered(nums, IsPositive);     // 1 4 7 2 8 6 10
PrintFiltered(nums, IsGreaterThan5); // 7 8 6 10
```

---

## Multicast Delegates

A delegate can hold **multiple method references** and call them all.

```csharp
delegate void Notify(string message);

void SendEmail(string msg) => Console.WriteLine($"📧 Email: {msg}");
void SendSMS(string msg) => Console.WriteLine($"📱 SMS: {msg}");
void LogToFile(string msg) => Console.WriteLine($"📝 Log: {msg}");

// Combine delegates with +=
Notify notifier = SendEmail;
notifier += SendSMS;
notifier += LogToFile;

notifier("Server is down!");
// 📧 Email: Server is down!
// 📱 SMS: Server is down!
// 📝 Log: Server is down!

// Remove a delegate with -=
notifier -= SendSMS;
notifier("Server recovered.");
// 📧 Email: Server recovered.
// 📝 Log: Server recovered.
```

---

## Built-in Delegate Types: Func, Action, Predicate

C# provides **generic delegate types** so you don't need to declare your own most of the time.

### Action\<T\> — Returns void

```csharp
// Action = delegate that returns void
Action greet = () => Console.WriteLine("Hello!");
Action<string> greetPerson = name => Console.WriteLine($"Hello, {name}!");
Action<string, int> greetWithAge = (name, age) => Console.WriteLine($"{name} is {age}");

greet();                    // Hello!
greetPerson("Debanjan");   // Hello, Debanjan!
greetWithAge("Alice", 30); // Alice is 30
```

### Func\<T, TResult\> — Returns a value

```csharp
// Func = delegate that returns a value (last type parameter is return type)
Func<int, int, int> add = (a, b) => a + b;
Func<string, int> getLength = s => s.Length;
Func<double> getPI = () => Math.PI;
Func<int, bool> isEven = n => n % 2 == 0;

Console.WriteLine(add(5, 3));           // 8
Console.WriteLine(getLength("Hello"));  // 5
Console.WriteLine(getPI());             // 3.14159...
Console.WriteLine(isEven(4));           // True
```

### Predicate\<T\> — Returns bool (special case of Func)

```csharp
// Predicate<T> = Func<T, bool>
Predicate<int> isPositive = n => n > 0;
Predicate<string> isLong = s => s.Length > 10;

Console.WriteLine(isPositive(5));          // True
Console.WriteLine(isLong("Hello World!")); // True

// Predicates work great with List methods
List<int> numbers = new List<int> { -5, 3, -1, 8, -2, 7 };
List<int> positives = numbers.FindAll(isPositive); // [3, 8, 7]
bool anyNegative = numbers.Exists(n => n < 0);    // True
```

### When to Use Which?

| Delegate | Returns | Use Case |
|---|---|---|
| `Action<T>` | void | Performing an action (logging, printing, notifying) |
| `Func<T, TResult>` | value | Transforming, calculating, mapping |
| `Predicate<T>` | bool | Filtering, testing conditions |

---

## Lambda Expressions

Lambdas are **anonymous (unnamed) methods** written inline — the most common way to use delegates.

### Syntax Evolution

```csharp
// Full delegate (old style)
Func<int, int> square1 = delegate(int x) { return x * x; };

// Lambda with types
Func<int, int> square2 = (int x) => { return x * x; };

// Lambda without types (compiler infers)
Func<int, int> square3 = (x) => { return x * x; };

// Remove parentheses (single parameter)
Func<int, int> square4 = x => { return x * x; };

// Expression body (single expression — no braces, no return)
Func<int, int> square5 = x => x * x;  // ✅ Cleanest
```

### Lambda Examples

```csharp
// No parameters
Action sayHello = () => Console.WriteLine("Hello!");

// One parameter
Func<int, bool> isEven = n => n % 2 == 0;

// Multiple parameters
Func<int, int, int> add = (a, b) => a + b;

// Multi-line body (needs braces and return)
Func<int, string> classify = n =>
{
    if (n > 0) return "Positive";
    if (n < 0) return "Negative";
    return "Zero";
};

// With LINQ (most common usage)
var adults = people.Where(p => p.Age >= 18)
                   .OrderBy(p => p.Name)
                   .Select(p => new { p.Name, p.Age });
```

---

## Closures (Variable Capture)

Lambdas can **capture variables** from their surrounding scope.

```csharp
int threshold = 5;
Func<int, bool> isAboveThreshold = n => n > threshold;

Console.WriteLine(isAboveThreshold(3)); // False
Console.WriteLine(isAboveThreshold(7)); // True

// Changing the captured variable affects the lambda!
threshold = 10;
Console.WriteLine(isAboveThreshold(7)); // False (now checking > 10)
```

### Closure Gotcha with Loops

```csharp
// ❌ Common bug — all lambdas capture the SAME variable i
var actions = new List<Action>();
for (int i = 0; i < 5; i++)
{
    actions.Add(() => Console.Write($"{i} "));
}
actions.ForEach(a => a()); // Prints: 5 5 5 5 5 (all 5!)

// ✅ Fix — capture a copy
var fixedActions = new List<Action>();
for (int i = 0; i < 5; i++)
{
    int captured = i; // New variable for each iteration
    fixedActions.Add(() => Console.Write($"{captured} "));
}
fixedActions.ForEach(a => a()); // Prints: 0 1 2 3 4
```

---

## Events — The Observer Pattern

Events allow an object to **notify** other objects when something happens. It's based on delegates but adds **encapsulation** — only the class that defines the event can raise it.

### Defining and Raising Events

```csharp
public class TemperatureSensor
{
    // Step 1: Define a delegate for the event signature
    public delegate void TemperatureChangedHandler(double oldTemp, double newTemp);

    // Step 2: Declare the event using the delegate
    public event TemperatureChangedHandler? TemperatureChanged;

    private double _temperature;

    public double Temperature
    {
        get => _temperature;
        set
        {
            double old = _temperature;
            _temperature = value;
            
            // Step 3: Raise the event (notify subscribers)
            if (old != value)
                TemperatureChanged?.Invoke(old, value);
        }
    }
}

// Step 4: Subscribe to the event
var sensor = new TemperatureSensor();

// Subscribe handler methods
sensor.TemperatureChanged += (oldT, newT) =>
    Console.WriteLine($"🌡 Temperature changed: {oldT}°C → {newT}°C");

sensor.TemperatureChanged += (oldT, newT) =>
{
    if (newT > 100)
        Console.WriteLine("🔥 WARNING: Temperature critical!");
};

// Step 5: Trigger by changing value
sensor.Temperature = 25;   // 🌡 Temperature changed: 0°C → 25°C
sensor.Temperature = 105;  // 🌡 Temperature changed: 25°C → 105°C
                           // 🔥 WARNING: Temperature critical!
```

---

## Standard Event Pattern (EventHandler)

C# has a standard convention for events using `EventHandler` and `EventArgs`.

### Custom EventArgs

```csharp
public class OrderEventArgs : EventArgs
{
    public int OrderId { get; }
    public string CustomerName { get; }
    public decimal Amount { get; }

    public OrderEventArgs(int orderId, string customerName, decimal amount)
    {
        OrderId = orderId;
        CustomerName = customerName;
        Amount = amount;
    }
}
```

### Publisher (raises events)

```csharp
public class OrderService
{
    // Standard pattern: EventHandler<TEventArgs>
    public event EventHandler<OrderEventArgs>? OrderPlaced;
    public event EventHandler<OrderEventArgs>? OrderShipped;

    private int _nextId = 1;

    public void PlaceOrder(string customer, decimal amount)
    {
        int orderId = _nextId++;
        Console.WriteLine($"Order #{orderId} placed by {customer}.");

        // Raise event — standard pattern
        OnOrderPlaced(new OrderEventArgs(orderId, customer, amount));
    }

    public void ShipOrder(int orderId, string customer, decimal amount)
    {
        Console.WriteLine($"Order #{orderId} shipped.");
        OnOrderShipped(new OrderEventArgs(orderId, customer, amount));
    }

    // Protected virtual method — allows derived classes to override
    protected virtual void OnOrderPlaced(OrderEventArgs e)
    {
        OrderPlaced?.Invoke(this, e);
    }

    protected virtual void OnOrderShipped(OrderEventArgs e)
    {
        OrderShipped?.Invoke(this, e);
    }
}
```

### Subscribers (listen for events)

```csharp
public class EmailNotifier
{
    public void OnOrderPlaced(object? sender, OrderEventArgs e)
    {
        Console.WriteLine($"  📧 Email sent to {e.CustomerName}: Order #{e.OrderId} confirmed (${e.Amount})");
    }

    public void OnOrderShipped(object? sender, OrderEventArgs e)
    {
        Console.WriteLine($"  📧 Email sent to {e.CustomerName}: Order #{e.OrderId} shipped!");
    }
}

public class InventoryManager
{
    public void OnOrderPlaced(object? sender, OrderEventArgs e)
    {
        Console.WriteLine($"  📦 Inventory updated for Order #{e.OrderId}");
    }
}

public class AnalyticsService
{
    public void OnOrderPlaced(object? sender, OrderEventArgs e)
    {
        Console.WriteLine($"  📊 Analytics: New order worth ${e.Amount}");
    }
}
```

### Wiring It Up

```csharp
var orderService = new OrderService();
var emailNotifier = new EmailNotifier();
var inventory = new InventoryManager();
var analytics = new AnalyticsService();

// Subscribe
orderService.OrderPlaced += emailNotifier.OnOrderPlaced;
orderService.OrderPlaced += inventory.OnOrderPlaced;
orderService.OrderPlaced += analytics.OnOrderPlaced;
orderService.OrderShipped += emailNotifier.OnOrderShipped;

// Trigger
orderService.PlaceOrder("Debanjan", 299.99m);
// Order #1 placed by Debanjan.
//   📧 Email sent to Debanjan: Order #1 confirmed ($299.99)
//   📦 Inventory updated for Order #1
//   📊 Analytics: New order worth $299.99

orderService.ShipOrder(1, "Debanjan", 299.99m);
// Order #1 shipped.
//   📧 Email sent to Debanjan: Order #1 shipped!

// Unsubscribe
orderService.OrderPlaced -= analytics.OnOrderPlaced;
```

---

## Event vs Delegate — What's the Difference?

```csharp
public class Demo
{
    public Action? MyDelegate;           // Public delegate — ANYONE can invoke
    public event Action? MyEvent;        // Event — only Demo class can invoke

    public void RaiseEvent()
    {
        MyEvent?.Invoke(); // ✅ OK — inside the class
    }
}

var demo = new Demo();
demo.MyDelegate?.Invoke(); // ✅ Anyone can invoke the delegate
// demo.MyEvent?.Invoke();  // ❌ Compile error — only the class can raise its event
demo.MyEvent += () => Console.WriteLine("Subscribed!"); // ✅ Can subscribe
```

| Feature | Delegate | Event |
|---|---|---|
| External invoke | ✅ Anyone can call | ❌ Only owner class |
| Subscribe/Unsubscribe | ✅ Yes | ✅ Yes |
| Direct assignment `=` | ✅ Can overwrite | ❌ Only `+=` / `-=` |
| Encapsulation | ❌ No protection | ✅ Controlled access |

**Rule**: Use **events** when you want the publisher-subscriber pattern. Use **delegates** when you need to pass methods as parameters.

---

## Higher-Order Functions

Functions that **take functions as parameters** or **return functions**.

### Taking a Function

```csharp
List<T> Filter<T>(List<T> source, Func<T, bool> predicate)
{
    List<T> result = new List<T>();
    foreach (T item in source)
    {
        if (predicate(item))
            result.Add(item);
    }
    return result;
}

void ApplyToAll<T>(List<T> source, Action<T> action)
{
    foreach (T item in source)
        action(item);
}

List<int> numbers = new List<int> { 1, 2, 3, 4, 5, 6, 7, 8 };
var evens = Filter(numbers, n => n % 2 == 0);      // [2, 4, 6, 8]
ApplyToAll(evens, n => Console.Write($"{n} "));     // 2 4 6 8
```

### Returning a Function

```csharp
Func<int, int> CreateMultiplier(int factor)
{
    return x => x * factor; // Closure — captures 'factor'
}

var double_ = CreateMultiplier(2);
var triple = CreateMultiplier(3);

Console.WriteLine(double_(5));  // 10
Console.WriteLine(triple(5));   // 15

// Chaining function factories
Func<string, string> CreateFormatter(string prefix, string suffix)
{
    return text => $"{prefix}{text}{suffix}";
}

var htmlBold = CreateFormatter("<b>", "</b>");
var parenthesize = CreateFormatter("(", ")");

Console.WriteLine(htmlBold("Hello"));      // <b>Hello</b>
Console.WriteLine(parenthesize("note"));   // (note)
```

---

## Practical Example: Callback Pattern

```csharp
void DownloadFile(string url, Action<string> onSuccess, Action<string> onError)
{
    try
    {
        // Simulate download
        if (url.StartsWith("https://"))
        {
            Console.WriteLine($"Downloading {url}...");
            string content = $"Content from {url}"; // Simulated
            onSuccess(content);
        }
        else
        {
            throw new Exception("URL must start with https://");
        }
    }
    catch (Exception ex)
    {
        onError(ex.Message);
    }
}

// Usage with lambdas
DownloadFile(
    "https://example.com/data.json",
    content => Console.WriteLine($"✅ Downloaded: {content}"),
    error => Console.WriteLine($"❌ Failed: {error}")
);

DownloadFile(
    "http://insecure.com/data",
    content => Console.WriteLine($"✅ Downloaded: {content}"),
    error => Console.WriteLine($"❌ Failed: {error}")
);
// ❌ Failed: URL must start with https://
```

---

## Practical Example: Strategy Pattern with Delegates

```csharp
class PriceCalculator
{
    private readonly Func<decimal, decimal> _discountStrategy;

    public PriceCalculator(Func<decimal, decimal> discountStrategy)
    {
        _discountStrategy = discountStrategy;
    }

    public decimal CalculatePrice(decimal originalPrice)
    {
        return _discountStrategy(originalPrice);
    }
}

// Different strategies
Func<decimal, decimal> noDiscount = price => price;
Func<decimal, decimal> percentOff = price => price * 0.8m;   // 20% off
Func<decimal, decimal> flatOff = price => price - 50;         // $50 off
Func<decimal, decimal> memberDiscount = price => price * 0.85m; // 15% off

var regularCalc = new PriceCalculator(noDiscount);
var saleCalc = new PriceCalculator(percentOff);
var memberCalc = new PriceCalculator(memberDiscount);

decimal price = 200m;
Console.WriteLine($"Regular: {regularCalc.CalculatePrice(price):C}"); // $200.00
Console.WriteLine($"Sale: {saleCalc.CalculatePrice(price):C}");       // $160.00
Console.WriteLine($"Member: {memberCalc.CalculatePrice(price):C}");   // $170.00
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| **Delegate** | Type-safe reference to a method |
| **Multicast** | One delegate can call multiple methods (`+=` / `-=`) |
| **Action\<T\>** | Delegate that returns `void` |
| **Func\<T, TResult\>** | Delegate that returns a value |
| **Predicate\<T\>** | Delegate that returns `bool` |
| **Lambda** | Inline anonymous method: `x => x * 2` |
| **Closure** | Lambda capturing variables from outer scope |
| **Event** | Encapsulated delegate — only owner can raise |
| **EventHandler\<T\>** | Standard event pattern with `EventArgs` |
| **Higher-order functions** | Functions that take or return other functions |

---

*Next Topic: Async/Await & Task-Based Programming →*
