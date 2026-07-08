# Topic 05: Methods and Parameters — Interview Questions

---

## Q1. What is the difference between `ref`, `out`, and `in` parameter modifiers?
**Answer:**
| Modifier | Must be initialized before call | Can be read before assigned | Purpose |
|---|---|---|---|
| `ref` | Yes | Yes | Pass by reference (read and write) |
| `out` | No | No (must assign before return) | Return multiple values from a method |
| `in` | Yes | Yes (read-only inside method) | Pass large value types by reference without copying |

```csharp
void Increment(ref int x) { x++; }

bool TryParse(string s, out int result)
{
    result = 0;
    return int.TryParse(s, out result);
}

void Print(in Matrix m) { /* m cannot be modified */ }

int n = 5;
Increment(ref n); // n = 6
```

---

## Q2. What is method overloading?
**Answer:**
Method overloading means defining multiple methods with the **same name** but **different parameter lists** (different number, type, or order of parameters). The return type alone cannot distinguish overloads.

```csharp
void Log(string message) { }
void Log(string message, int level) { }
void Log(Exception ex) { }
// void Log(string msg) { } // ❌ duplicate — same signature
```

The compiler resolves which overload to call at **compile time** (static/early binding). This is an example of **compile-time polymorphism**.

---

## Q3. What are optional (default) parameters?
**Answer:**
Parameters with default values are optional — callers can omit them and the default is used.

```csharp
void Connect(string host, int port = 80, bool ssl = false)
{
    // If called as Connect("localhost"), port=80, ssl=false
}

Connect("localhost");
Connect("localhost", 443, true);
```

Rules:
- Optional parameters must come **after** required parameters.
- The default value must be a compile-time constant.
- Prefer **overloading** over many optional parameters to keep API clarity.

---

## Q4. What is the `params` keyword?
**Answer:**
`params` allows a method to accept a **variable number of arguments** as an array. The caller can pass individual values, an array, or nothing.

```csharp
int Sum(params int[] numbers)
{
    int total = 0;
    foreach (var n in numbers) total += n;
    return total;
}

Sum(1, 2, 3);           // 6
Sum(new int[] { 4, 5 }); // 9
Sum();                   // 0
```

Rules: Only one `params` parameter per method, and it must be the **last parameter**.

---

## Q5. What is the difference between pass-by-value and pass-by-reference?
**Answer:**
- **Pass-by-value** — a copy of the value is passed. Changes inside the method do not affect the original.
- **Pass-by-reference** (`ref`/`out`) — the address of the variable is passed. Changes inside the method affect the original.

```csharp
void Double(int x) { x *= 2; }
void DoubleRef(ref int x) { x *= 2; }

int a = 5;
Double(a);       // a is still 5
DoubleRef(ref a); // a is now 10
```

**Note:** Reference types (classes) passed by value still allow mutation of the object's contents, but you cannot reassign the variable itself to point to a new object.

---

## Q6. What is an extension method?
**Answer:**
An extension method adds new functionality to an existing type **without modifying it** or subclassing it. It must be:
- In a **static class**
- A **static method**
- The first parameter has the `this` keyword

```csharp
public static class StringExtensions
{
    public static bool IsNullOrEmpty(this string s)
        => string.IsNullOrEmpty(s);

    public static string Truncate(this string s, int maxLength)
        => s.Length <= maxLength ? s : s.Substring(0, maxLength) + "...";
}

string name = "Debanjan";
Console.WriteLine(name.Truncate(4)); // "Deba..."
```

Extension methods are heavily used in LINQ (`Where`, `Select`, etc. are all extension methods on `IEnumerable<T>`).

---

## Q7. What is a recursive method? What is the risk?
**Answer:**
A recursive method calls itself to solve a smaller subproblem. Every recursion needs a **base case** to terminate.

```csharp
int Factorial(int n)
{
    if (n <= 1) return 1;       // base case
    return n * Factorial(n - 1); // recursive call
}
```

**Risks:**
- **Stack overflow** — each call consumes stack space. Deep recursion (e.g., n = 100,000) will crash.
- **Performance** — method call overhead can be significant compared to iteration.

Tail recursion optimization is NOT performed by the C# compiler. For deep recursion, prefer an iterative approach or use a `Stack<T>` on the heap.

---

## Q8. What is a local function?
**Answer:**
A local function is a method defined **inside** another method. It can access the enclosing method's variables (like a closure).

```csharp
int Calculate(int[] numbers)
{
    return numbers.Sum(n => Transform(n));

    int Transform(int x)  // local function — only visible inside Calculate
    {
        return x * x + 1;
    }
}
```

Differences from lambda: local functions support recursion, can have `ref`/`out` parameters, support `yield return`, and have less allocation overhead than lambdas.

---

## Q9. What is method hiding (`new` keyword) vs method overriding (`override`)?
**Answer:**
- **`override`** — replaces the base class virtual method at runtime (polymorphism). The derived version is called through any reference type.
- **`new`** — hides the base method. The version called depends on the compile-time type of the reference.

```csharp
class Animal { public virtual void Speak() => Console.WriteLine("..."); }
class Dog : Animal { public override void Speak() => Console.WriteLine("Woof"); }
class Cat : Animal { public new void Speak() => Console.WriteLine("Meow"); }

Animal a1 = new Dog(); a1.Speak(); // "Woof" — override (runtime type wins)
Animal a2 = new Cat(); a2.Speak(); // "..."  — new (compile-time type wins → Animal.Speak)
Cat c = new Cat();     c.Speak();  // "Meow" — Cat reference → Cat.Speak
```

---

## Q10. What are expression-bodied members?
**Answer:**
Expression-bodied members use the `=>` syntax for concise single-expression methods, properties, constructors, and more:

```csharp
// Method
public string GetFullName() => $"{FirstName} {LastName}";

// Read-only property
public int Age => DateTime.Now.Year - BirthYear;

// Property with getter and setter
public string Name
{
    get => _name;
    set => _name = value ?? throw new ArgumentNullException(nameof(value));
}

// Constructor (C# 7+)
public Person(string name) => Name = name;
```

These are purely syntactic sugar — no performance difference from block-bodied equivalents.

---

## Q11. What are named arguments and how do they improve readability?
**Answer:**
Named arguments let you pass values to a method by **parameter name** instead of position, improving clarity:

```csharp
void CreateUser(string name, int age, bool isAdmin = false, string role = "User")
{ }

// Positional — unclear what each value means
CreateUser("Debanjan", 25, true, "Admin");

// Named — self-documenting, order doesn't matter
CreateUser(name: "Debanjan", age: 25, isAdmin: true, role: "Admin");

// Mix named and positional — named must follow positional
CreateUser("Debanjan", 25, role: "Admin", isAdmin: true);
```

Named arguments are especially useful when calling methods with many optional parameters or boolean flags.

---

## Q12. What are the `CallerMemberName`, `CallerFilePath`, and `CallerLineNumber` attributes?
**Answer:**
These attributes automatically inject the caller's context into optional parameters at **compile time** — no runtime reflection needed:

```csharp
void Log(string message,
    [CallerMemberName] string memberName = "",
    [CallerFilePath]   string filePath   = "",
    [CallerLineNumber] int    lineNumber  = 0)
{
    Console.WriteLine($"[{memberName}:{lineNumber}] {message}");
}

void ProcessOrder()
{
    Log("Order started"); // prints: [ProcessOrder:42] Order started
}
```

Used heavily in `INotifyPropertyChanged` implementations and logging frameworks to avoid hard-coded member names.

---

## Q13. What is a static local function and how does it differ from a regular local function?
**Answer:**
A **static local function** (C# 8+) is declared `static` inside another method and **cannot capture** variables from the enclosing scope. This avoids accidental closures and has slightly better performance:

```csharp
int Compute(int x, int y)
{
    return Add(x, y);  // can call local function before its declaration

    static int Add(int a, int b) => a + b;  // cannot capture x or y
}

// Non-static local function — can capture enclosing variables
void Example()
{
    int multiplier = 3;
    int Triple(int n) => n * multiplier; // captures multiplier
}
```

Use `static` on local functions whenever they don't need outer variables — it's a compile-time guarantee of no hidden state capture.

---

## Q14. What is method resolution order and how are ambiguous overloads handled?
**Answer:**
When calling an overloaded method, the compiler chooses the **most specific applicable** overload:
1. Exact type match wins.
2. Implicit numeric widening (e.g., `int` → `long` → `double`).
3. Params array expansion.
4. Extension methods (last resort).

If two overloads are equally applicable, the compiler reports an **ambiguous call** error:

```csharp
void Print(long x) { }
void Print(double x) { }

Print(5);    // ❌ ambiguous — int can widen to long OR double
Print(5L);   // ✓ Print(long)
Print(5.0);  // ✓ Print(double)
```

Optional parameters do NOT participate in overload differentiation — two methods differing only in a default parameter are considered duplicates.

---

## Q15. What is the difference between `Func<T>` delegate and a method group?
**Answer:**
- **Method group** — a name that refers to one or more overloaded methods. Converted implicitly to a compatible delegate.
- **`Func<T>`** — a specific delegate type that holds a reference to a method.

```csharp
bool IsEven(int n) => n % 2 == 0;

// Method group — implicit delegate conversion
Func<int, bool> f1 = IsEven;           // method group
Predicate<int> p = IsEven;             // also method group

// Lambda (anonymous method)
Func<int, bool> f2 = n => n % 2 == 0;

var evens = numbers.Where(IsEven);     // method group passed to LINQ
var evens2 = numbers.Where(n => IsEven(n)); // lambda wrapping method group
```

Method groups are slightly preferred over lambdas that just wrap a single method call — they avoid creating an extra delegate allocation in some cases (C# 11+ improved this with method group caching).
