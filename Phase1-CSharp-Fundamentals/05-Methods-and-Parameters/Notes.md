# Phase 1 | Topic 5: Methods & Parameters

---

## 1. What is a Method?

A method is a **reusable block of code** that performs a specific task. Instead of writing the same code over and over, you write it once in a method and **call** it whenever needed.

Think of it like a **recipe** — write it once, cook it anytime.

```csharp
// WITHOUT methods — repeating code ❌
Console.WriteLine("==========");
Console.WriteLine("  Hello!  ");
Console.WriteLine("==========");
// ... 50 lines later, need the same box again ...
Console.WriteLine("==========");
Console.WriteLine("  Hello!  ");
Console.WriteLine("==========");

// WITH methods — write once, use forever ✅
void PrintBox(string message)
{
    Console.WriteLine("==========");
    Console.WriteLine($"  {message}  ");
    Console.WriteLine("==========");
}

PrintBox("Hello!");     // Call it anywhere
PrintBox("Goodbye!");   // Reuse with different data
```

---

## 2. Method Syntax

```csharp
accessModifier returnType MethodName(parameterType parameterName)
{
    // method body
    return value;    // if returnType is not void
}
```

### Breaking it down:

```csharp
public static int Add(int a, int b)
{
    return a + b;
}

// public    → who can access it (we'll cover access modifiers in OOP)
// static    → can call without creating an object (more on this in OOP)
// int       → return type (this method gives back an integer)
// Add       → method name (PascalCase convention)
// (int a, int b) → parameters (inputs the method needs)
// return    → sends a value back to the caller
```

### void Methods (No Return Value):

```csharp
static void Greet(string name)
{
    Console.WriteLine($"Hello, {name}!");
    // No return statement needed (void = returns nothing)
}

// Call it:
Greet("Debanjan");   // Output: Hello, Debanjan!
```

### Methods with Return Values:

```csharp
static int Multiply(int a, int b)
{
    return a * b;
}

// Call it and use the returned value:
int result = Multiply(5, 3);     // result = 15
Console.WriteLine(result);

// Or use directly:
Console.WriteLine(Multiply(7, 8));   // 56
```

### ⚠️ Top-Level Statements Note:

In modern C# with top-level statements, you define methods **after** your main code (which is different from classic C#):

```csharp
// Main code (top-level)
string greeting = GetGreeting("Debanjan");
Console.WriteLine(greeting);

// Method definitions go BELOW the main code
static string GetGreeting(string name)
{
    return $"Hello, {name}! Welcome to TaskFlow.";
}
```

---

## 3. Parameters In Detail

### 3.1 Value Parameters (Default — Pass by Value)

A **copy** of the value is passed. Changing the parameter inside the method does NOT affect the original:

```csharp
static void DoubleIt(int number)
{
    number = number * 2;
    Console.WriteLine($"Inside method: {number}");   // 20
}

int x = 10;
DoubleIt(x);
Console.WriteLine($"Outside method: {x}");           // 10 (unchanged!)
```

```
Before call:     x = 10
Method gets:     number = 10 (COPY of x)
Inside method:   number = 20
After call:      x = 10 (original unchanged)
```

### 3.2 ref Parameter (Pass by Reference)

The **actual variable** is passed, not a copy. Changes inside the method **DO affect** the original:

```csharp
static void DoubleIt(ref int number)
{
    number = number * 2;
    Console.WriteLine($"Inside method: {number}");   // 20
}

int x = 10;
DoubleIt(ref x);          // Must use 'ref' keyword when calling too
Console.WriteLine($"Outside method: {x}");           // 20 (changed!)
```

```
Before call:     x = 10
Method gets:     reference to x (same memory location)
Inside method:   number = 20 → x is also 20
After call:      x = 20 (changed!)
```

### 3.3 out Parameter (Must Assign Inside Method)

Like `ref`, but the variable **doesn't need to be initialized** before calling. The method **MUST** assign a value:

```csharp
static void Divide(int a, int b, out int quotient, out int remainder)
{
    quotient = a / b;
    remainder = a % b;
}

// Don't need to initialize before calling:
Divide(17, 5, out int q, out int r);
Console.WriteLine($"17 / 5 = {q} remainder {r}");   // 17 / 5 = 3 remainder 2
```

### You've already used `out` — remember `TryParse`?

```csharp
if (int.TryParse("42", out int result))
{
    Console.WriteLine(result);   // 42
}
// TryParse uses 'out' to give you the converted value
```

### 3.4 in Parameter (Read-Only Reference)

Passes by reference but the method **cannot modify** it. Used for performance with large structs:

```csharp
static double CalculateDistance(in Point a, in Point b)
{
    // a.X = 100;  // ❌ ERROR — cannot modify 'in' parameter
    return Math.Sqrt(Math.Pow(b.X - a.X, 2) + Math.Pow(b.Y - a.Y, 2));
}
```

### Parameter Passing Summary:

```
┌──────────┬──────────────────┬────────────────┬─────────────────┐
│ Keyword  │ Pass Style       │ Must Init?     │ Can Modify?     │
├──────────┼──────────────────┼────────────────┼─────────────────┤
│ (none)   │ By value (copy)  │ Yes            │ Only the copy   │
│ ref      │ By reference     │ Yes            │ Yes (original)  │
│ out      │ By reference     │ No             │ Must assign     │
│ in       │ By reference     │ Yes            │ No (read-only)  │
└──────────┴──────────────────┴────────────────┴─────────────────┘
```

---

## 4. Optional Parameters & Default Values

Parameters can have **default values** — if the caller doesn't provide one, the default is used:

```csharp
static void CreateTask(string title, string priority = "Medium", bool isCompleted = false)
{
    Console.WriteLine($"Task: {title}");
    Console.WriteLine($"Priority: {priority}");
    Console.WriteLine($"Completed: {isCompleted}");
}

// All valid calls:
CreateTask("Fix bug");                          // Uses defaults: Medium, false
CreateTask("Fix bug", "High");                  // Uses default: false
CreateTask("Fix bug", "Critical", true);        // No defaults used
```

### Rules for Optional Parameters:
```csharp
// ✅ Optional parameters must come AFTER required ones
static void Example(int required, string optional = "default") { }

// ❌ This won't compile
// static void Bad(string optional = "default", int required) { }
```

---

## 5. Named Parameters

You can specify parameters **by name** instead of position:

```csharp
static void RegisterUser(string name, int age, string city, bool isPremium = false)
{
    Console.WriteLine($"{name}, {age}, {city}, Premium: {isPremium}");
}

// Positional (normal):
RegisterUser("Debanjan", 25, "Kolkata");

// Named (order doesn't matter!):
RegisterUser(age: 25, city: "Kolkata", name: "Debanjan");

// Mix — positional first, then named:
RegisterUser("Debanjan", 25, isPremium: true, city: "Kolkata");

// Skip optional parameters in the middle:
RegisterUser("Debanjan", 25, "Kolkata", isPremium: true);
```

Named parameters are super useful when a method has many optional parameters and you only want to set specific ones.

---

## 6. params Keyword (Variable Number of Arguments)

Accept **any number** of arguments of the same type:

```csharp
static int Sum(params int[] numbers)
{
    int total = 0;
    foreach (int num in numbers)
    {
        total += num;
    }
    return total;
}

// Call with any number of arguments:
Console.WriteLine(Sum(1, 2, 3));            // 6
Console.WriteLine(Sum(10, 20, 30, 40));     // 100
Console.WriteLine(Sum(5));                   // 5
Console.WriteLine(Sum());                    // 0

// Or pass an array:
int[] scores = { 85, 90, 78 };
Console.WriteLine(Sum(scores));              // 253
```

### Rules for `params`:
```csharp
// params must be the LAST parameter
static void Log(string message, params string[] tags)
{
    Console.Write($"[{string.Join(", ", tags)}] {message}");
}

Log("Task created", "info", "task", "create");
// Output: [info, task, create] Task created
```

---

## 7. Method Overloading

Multiple methods with the **same name** but **different parameters**:

```csharp
static int Add(int a, int b)
{
    return a + b;
}

static double Add(double a, double b)
{
    return a + b;
}

static int Add(int a, int b, int c)
{
    return a + b + c;
}

// C# picks the right version based on the arguments:
Console.WriteLine(Add(5, 3));           // Calls int version → 8
Console.WriteLine(Add(5.5, 3.2));       // Calls double version → 8.7
Console.WriteLine(Add(1, 2, 3));        // Calls 3-parameter version → 6
```

### What Makes Overloads Different:
```csharp
// ✅ Different parameter TYPES
int Process(int x) { ... }
int Process(string x) { ... }

// ✅ Different NUMBER of parameters
int Process(int x) { ... }
int Process(int x, int y) { ... }

// ❌ Different RETURN TYPE alone is NOT enough
int Process(int x) { ... }
// double Process(int x) { ... }   // ❌ Compile error — same name, same params
```

---

## 8. Expression-Bodied Methods (Shorthand)

For simple one-line methods, use the `=>` arrow:

```csharp
// Traditional:
static int Square(int x)
{
    return x * x;
}

// Expression-bodied (shorter):
static int Square(int x) => x * x;

// Works with void too:
static void PrintLine() => Console.WriteLine("─────────────────");

// More examples:
static double CircleArea(double radius) => Math.PI * radius * radius;
static bool IsAdult(int age) => age >= 18;
static string GetGreeting(string name) => $"Hello, {name}!";
```

---

## 9. Local Functions (Methods Inside Methods)

C# allows defining methods **inside other methods**:

```csharp
static void ProcessTask(string taskName)
{
    // Local function — only accessible inside ProcessTask
    string FormatTitle(string title)
    {
        return title.Trim().ToUpper();
    }
    
    bool IsValid(string title)
    {
        return !string.IsNullOrWhiteSpace(title) && title.Length >= 3;
    }
    
    if (IsValid(taskName))
    {
        string formatted = FormatTitle(taskName);
        Console.WriteLine($"Processing: {formatted}");
    }
    else
    {
        Console.WriteLine("Invalid task name!");
    }
}
```

### When to Use Local Functions:
- Helper logic used **only inside one method**
- Keeps the helper **close to where it's used**
- Cannot be called from outside the parent method

---

## 10. Recursion (A Method Calling Itself)

A method can **call itself** to solve problems that have a **self-similar structure**:

```csharp
// Factorial: 5! = 5 × 4 × 3 × 2 × 1 = 120
static int Factorial(int n)
{
    if (n <= 1)           // Base case — MUST have one to stop recursion!
        return 1;
    
    return n * Factorial(n - 1);   // Recursive case — calls itself
}

Console.WriteLine(Factorial(5));   // 120
```

### Tracing the Recursion:

```
Factorial(5)
  = 5 * Factorial(4)
  = 5 * 4 * Factorial(3)
  = 5 * 4 * 3 * Factorial(2)
  = 5 * 4 * 3 * 2 * Factorial(1)
  = 5 * 4 * 3 * 2 * 1
  = 120
```

### Another Example — Fibonacci:

```csharp
static int Fibonacci(int n)
{
    if (n <= 0) return 0;
    if (n == 1) return 1;
    
    return Fibonacci(n - 1) + Fibonacci(n - 2);
}

// 0, 1, 1, 2, 3, 5, 8, 13, 21, 34...
for (int i = 0; i < 10; i++)
{
    Console.Write($"{Fibonacci(i)} ");
}
```

### ⚠️ Recursion Danger:

```csharp
// MISSING base case = Stack Overflow!
static void InfiniteRecursion()
{
    InfiniteRecursion();   // ❌ Calls itself forever → StackOverflowException
}

// Rule: Every recursive method MUST have:
// 1. A BASE CASE that stops the recursion
// 2. A RECURSIVE CASE that moves toward the base case
```

---

## 11. Tuples (Returning Multiple Values)

Methods can return **multiple values** using tuples:

```csharp
// Return multiple values
static (int min, int max, double avg) GetStatistics(int[] numbers)
{
    int min = numbers.Min();
    int max = numbers.Max();
    double avg = numbers.Average();
    
    return (min, max, avg);
}

int[] scores = { 85, 92, 78, 95, 88 };
var stats = GetStatistics(scores);

Console.WriteLine($"Min: {stats.min}");    // 78
Console.WriteLine($"Max: {stats.max}");    // 95
Console.WriteLine($"Avg: {stats.avg}");    // 87.6

// Or deconstruct:
var (minimum, maximum, average) = GetStatistics(scores);
Console.WriteLine($"Min: {minimum}, Max: {maximum}, Avg: {average}");
```

---

## 12. Putting It All Together — Practical Example

### TaskFlow Task Helper Methods:

```csharp
// ======= MAIN PROGRAM =======
Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║    TASKFLOW - METHOD DEMO              ║");
Console.WriteLine("╚═══════════════════════════════════════╝");

// Using our methods:
string task1 = CreateTaskTitle("  fix the login bug  ");
string task2 = CreateTaskTitle("  update dashboard  ");

Console.WriteLine(task1);   // FIX-THE-LOGIN-BUG
Console.WriteLine(task2);   // UPDATE-DASHBOARD

// Priority calculation with overloading
int priority1 = CalculatePriority(true, true);           // Urgent + Important
int priority2 = CalculatePriority(false, true, 14);      // Not urgent, important, 14 days
Console.WriteLine($"Task 1 Priority: {priority1}");      // 100
Console.WriteLine($"Task 2 Priority: {priority2}");      // 40

// Statistics
int[] taskScores = { 85, 92, 78, 95, 88, 73, 99 };
var (min, max, avg) = GetStats(taskScores);
Console.WriteLine($"Scores — Min: {min}, Max: {max}, Avg: {avg:F1}");

// Logging with params
LogAction("Task created", "Debanjan", "info", "task");


// ======= METHOD DEFINITIONS =======

static string CreateTaskTitle(string rawTitle)
{
    return rawTitle.Trim().ToUpper().Replace(" ", "-");
}

static int CalculatePriority(bool isUrgent, bool isImportant, int daysLeft = 0)
{
    int score = 0;
    score += isUrgent ? 50 : 0;
    score += isImportant ? 30 : 0;
    score += daysLeft <= 3 ? 20 : daysLeft <= 7 ? 10 : 0;
    return score;
}

static (int min, int max, double avg) GetStats(params int[] numbers)
{
    int min = numbers[0], max = numbers[0];
    int sum = 0;
    
    foreach (int n in numbers)
    {
        if (n < min) min = n;
        if (n > max) max = n;
        sum += n;
    }
    
    return (min, max, (double)sum / numbers.Length);
}

static void LogAction(string message, string user, params string[] tags)
{
    string tagStr = tags.Length > 0 ? $"[{string.Join(", ", tags)}]" : "";
    Console.WriteLine($"{DateTime.Now:HH:mm:ss} {tagStr} {user}: {message}");
}
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Method** | Reusable block of code with a name |
| **void** | Method returns nothing |
| **return** | Sends a value back to the caller |
| **Value parameter** | Default — passes a copy, original unchanged |
| **ref** | Pass by reference — method can modify original |
| **out** | Must assign inside method — used by TryParse |
| **in** | Read-only reference — can't modify |
| **Optional params** | Default values: `string s = "default"` |
| **Named params** | Call by name: `Method(age: 25, name: "X")` |
| **params** | Variable arguments: `params int[] nums` |
| **Overloading** | Same name, different parameters |
| **Expression-bodied** | `static int Square(int x) => x * x;` |
| **Local functions** | Methods inside methods — private helpers |
| **Recursion** | Method calls itself — needs a base case! |
| **Tuples** | Return multiple values: `(int, string)` |

---

## Real-World Use Cases

1. **API Controllers** — Each endpoint is a method: `GetTaskById(int id)`, `CreateTask(TaskDto task)`, `DeleteTask(int id)`.
2. **Validation** — Reusable validation methods: `IsValidEmail(string email)`, `IsStrongPassword(string pwd)`.
3. **Business Logic** — `CalculateDiscount(decimal price, string membershipLevel)`, `IsTaskOverdue(DateTime dueDate)`.
4. **Utility/Helper Methods** — `FormatCurrency(decimal amount)`, `GenerateSlug(string title)`, `GetTimeAgo(DateTime date)`.
5. **Recursion in Real Code** — Traversing folder structures, parsing nested JSON, navigating tree-like menus.
6. **TaskFlow Project** — Service methods like `GetAllTasks()`, `UpdateTaskStatus(int id, string status)`, `CalculateCompletionPercentage()`.

---
