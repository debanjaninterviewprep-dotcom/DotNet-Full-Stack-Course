# Topic 04: Control Flow — Interview Questions

---

## Q1. What are the loop constructs available in C# and when do you use each?
**Answer:**
| Loop | Use when |
|---|---|
| `for` | You know the number of iterations in advance |
| `while` | You loop until a condition becomes false (condition checked before body) |
| `do-while` | Body must execute **at least once** (condition checked after body) |
| `foreach` | Iterating over any `IEnumerable<T>` (array, list, etc.) |

```csharp
for (int i = 0; i < 5; i++) { }

while (queue.Count > 0) { queue.Dequeue(); }

do { input = Console.ReadLine(); } while (input == null);

foreach (var item in list) { Console.WriteLine(item); }
```

---

## Q2. What is the difference between `break`, `continue`, and `return` inside a loop?
**Answer:**
- `break` — exits the **innermost** loop or switch statement immediately.
- `continue` — skips the **rest of the current iteration** and moves to the next.
- `return` — exits the **entire method**, optionally returning a value.

```csharp
for (int i = 0; i < 10; i++)
{
    if (i == 3) continue;  // skip 3
    if (i == 7) break;     // stop at 7 — prints 0,1,2,4,5,6
    Console.WriteLine(i);
}
```

---

## Q3. What is the difference between a `switch` statement and a `switch` expression?
**Answer:**
- **`switch` statement** — imperative, uses `case`/`break`, allows multiple statements per branch.
- **`switch` expression** (C# 8+) — functional, returns a value, uses `=>` arms, more concise.

```csharp
// Switch statement
string label;
switch (day)
{
    case 1: label = "Monday"; break;
    case 2: label = "Tuesday"; break;
    default: label = "Other"; break;
}

// Switch expression
string label = day switch
{
    1 => "Monday",
    2 => "Tuesday",
    _ => "Other"
};
```

Switch expressions are preferred in modern C# when the result is a single value.

---

## Q4. What is pattern matching in C#?
**Answer:**
Pattern matching lets you test a value's shape, type, or properties and bind it to a variable in one step. C# supports:

```csharp
// Type pattern
if (obj is string s) Console.WriteLine(s.Length);

// Property pattern (C# 8+)
if (person is { Age: > 18, Name: "Debanjan" }) { }

// Positional pattern (with deconstruct)
if (point is (0, 0)) Console.WriteLine("Origin");

// Relational + logical patterns (C# 9+)
string grade = score switch
{
    >= 90 => "A",
    >= 80 => "B",
    >= 70 => "C",
    _ => "F"
};

// List pattern (C# 11+)
if (numbers is [1, 2, ..]) Console.WriteLine("Starts with 1, 2");
```

---

## Q5. What happens if you don't use `break` in a switch statement?
**Answer:**
In C#, **fall-through is not allowed** (unlike C/C++). Each `case` block with code **must end** with `break`, `return`, `throw`, or `goto case`. The compiler enforces this.

```csharp
switch (x)
{
    case 1:
    case 2:
        Console.WriteLine("1 or 2"); // ✓ Empty case fall-through is allowed
        break;
    case 3:
        Console.WriteLine("3");
        // ❌ Missing break — compile error
}
```

The only exception is **empty cases** — they can fall through to the next case.

---

## Q6. What is the `goto` statement and should you use it?
**Answer:**
`goto` transfers control unconditionally to a labeled statement. In C#, its use is rare but has two legitimate cases:
1. Jumping between `switch` cases with `goto case`.
2. Breaking out of deeply nested loops (though prefer a method with `return`).

```csharp
for (int i = 0; i < 3; i++)
    for (int j = 0; j < 3; j++)
        if (i == 1 && j == 1) goto Done;

Done:
Console.WriteLine("Exited nested loops");
```

**Best practice:** Avoid `goto` in most cases. Use methods and `return` for nested loop exits, or restructure the logic.

---

## Q7. What is a `foreach` loop's limitation compared to a `for` loop?
**Answer:**
- `foreach` **cannot modify the collection** while iterating (throws `InvalidOperationException`).
- `foreach` does **not provide the index** directly (use `.Select((item, i) => ...)` or a `for` loop).
- `foreach` calls `GetEnumerator()` and works on any `IEnumerable<T>`.
- `for` requires an indexed structure and lets you modify elements by index.

```csharp
// Cannot remove from list during foreach:
foreach (var item in list)
    list.Remove(item);  // ❌ InvalidOperationException

// Safe approach:
list.RemoveAll(item => item.IsExpired); // ✓
```

---

## Q8. What are the conditional preprocessor directives (`#if`, `#else`, `#endif`)?
**Answer:**
Preprocessor directives control which code is compiled based on defined symbols:

```csharp
#define DEBUG_MODE

#if DEBUG_MODE
    Console.WriteLine("Debug output");
#elif RELEASE
    // Production code
#else
    Console.WriteLine("Unknown build");
#endif
```

These are commonly used for platform-specific code, debug logging, or feature flags at compile time. In modern .NET, conditional attributes `[Conditional("DEBUG")]` are often preferred over `#if`.

---

## Q9. What is an infinite loop and when is it intentional?
**Answer:**
An infinite loop runs forever unless broken by `break`, `return`, `throw`, or an external interrupt.

```csharp
// Intentional — server message loop
while (true)
{
    var message = server.ReceiveMessage();
    if (message == null) break;
    ProcessMessage(message);
}

// Intentional — game loop
for (;;) // equivalent to while(true)
{
    Update();
    Render();
}
```

Common in service hosts, event loops, and REPL-style programs. Always ensure there is a clear exit condition.

---

## Q10. What is the difference between `if-else if` chain and `switch`? When do you prefer each?
**Answer:**
- **`if-else if`** — works with any boolean expression (ranges, complex conditions, null checks).
- **`switch`** — works best with discrete, constant values; compiler can optimize as jump tables.

```csharp
// if-else — better for ranges
if (score >= 90) grade = "A";
else if (score >= 80) grade = "B";

// switch expression — better for discrete values
string message = statusCode switch
{
    200 => "OK",
    404 => "Not Found",
    500 => "Server Error",
    _   => "Unknown"
};
```

**Rule of thumb:** Use `switch` when matching against a fixed set of known values; use `if-else` for complex conditions, ranges, or when the branches involve unrelated logic.

---

## Q11. What is `yield return` and how do iterators work?
**Answer:**
`yield return` turns a method into an **iterator** — a lazily evaluated sequence. The method returns `IEnumerable<T>` or `IEnumerator<T>` but produces values one at a time:

```csharp
IEnumerable<int> EvenNumbers(int max)
{
    for (int i = 0; i <= max; i += 2)
        yield return i;  // pauses here, resumes on next MoveNext()
}

foreach (int n in EvenNumbers(10))
    Console.Write(n + " "); // 0 2 4 6 8 10 — lazy, one at a time
```

`yield break` ends the iteration early. The compiler generates a state machine class behind the scenes. Values are only produced on demand — this makes iterators memory-efficient for large or infinite sequences.

---

## Q12. What is the difference between an iterator method and returning `IEnumerable<T>` directly?
**Answer:**
```csharp
// Returns immediately — all items computed upfront
IEnumerable<int> EagerSquares(int[] nums)
    => nums.Select(n => n * n).ToList(); // evaluated now

// Iterator — lazy, computed on demand
IEnumerable<int> LazySquares(int[] nums)
{
    foreach (var n in nums)
        yield return n * n;  // computed when iterated
}
```

**Key difference:** Iterator methods:
- Are **lazy** — no work done until iterated.
- Support **infinite sequences** (no memory issues).
- Cannot use `ref`/`out` parameters or `unsafe` code.
- Cannot contain `return` (only `yield return`/`yield break`).

---

## Q13. What are preprocessor directives and when are they used?
**Answer:**
Preprocessor directives control compilation and are processed before the compiler:

```csharp
#define FEATURE_X

#if DEBUG
    Console.WriteLine("Debug mode");
#elif RELEASE
    Console.WriteLine("Release mode");
#endif

#if FEATURE_X
    // code compiled only when FEATURE_X is defined
#endif

#region Helper Methods   // code folding in IDE
void Helper() { }
#endregion

#pragma warning disable CS0168  // suppress specific warning
#pragma warning restore CS0168

#nullable enable  // enable nullable reference types for this file
```

Common symbols: `DEBUG`, `RELEASE`, `TRACE`. Defined via `#define` in code or `<DefineConstants>` in `.csproj`.

---

## Q14. What is the difference between `for` loop and `foreach` loop internally?
**Answer:**
`foreach` is syntactic sugar for calling `GetEnumerator()` and using the resulting `IEnumerator<T>`:

```csharp
// foreach internally compiled to:
var enumerator = collection.GetEnumerator();
try
{
    while (enumerator.MoveNext())
    {
        var item = enumerator.Current;
        // loop body
    }
}
finally
{
    (enumerator as IDisposable)?.Dispose();
}
```

Any type that exposes a `GetEnumerator()` method returning something with `MoveNext()` and `Current` can be used in `foreach` — it doesn't have to implement `IEnumerable<T>` (duck typing).

---

## Q15. What is the `checked` and `unchecked` context in arithmetic control flow?
**Answer:**
```csharp
// Overflow silently wraps (default / unchecked)
int result = int.MaxValue + 1; // -2147483648

// checked — throws OverflowException
try
{
    int safe = checked(int.MaxValue + 1);
}
catch (OverflowException ex)
{
    Console.WriteLine(ex.Message);
}

// checked block
checked
{
    int a = int.MaxValue;
    int b = a + 1; // throws
}
```

Use `checked` in financial, cryptographic, or any arithmetic where silent overflow would be a silent data corruption bug.
