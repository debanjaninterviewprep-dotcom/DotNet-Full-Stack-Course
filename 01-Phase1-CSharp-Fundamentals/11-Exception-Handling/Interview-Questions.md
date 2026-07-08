# Topic 11: Exception Handling — Interview Questions

---

## Q1. What is the difference between an exception and an error in C#?
**Answer:**
- **Exception** — an abnormal condition that occurs at runtime and can (in principle) be caught and recovered from. All .NET exceptions derive from `System.Exception`.
- **Error** — in C#/.NET terminology there is no separate "Error" base class (unlike Java). What would be called errors in Java (e.g., `OutOfMemoryException`, `StackOverflowException`) are also exceptions in .NET, but most cannot be meaningfully caught/recovered from.

Use exceptions for **recoverable** conditions. Do not use exceptions for normal control flow — it is expensive and reduces readability.

---

## Q2. Explain the `try-catch-finally` block.
**Answer:**
```csharp
try
{
    // Code that might throw
    int result = Divide(10, 0);
}
catch (DivideByZeroException ex)
{
    // Handle specific exception
    Console.WriteLine($"Math error: {ex.Message}");
}
catch (Exception ex)
{
    // Handle any other exception — place more specific catches first
    Console.WriteLine($"Unexpected: {ex.Message}");
}
finally
{
    // Always executes — whether an exception was thrown or not
    // Ideal for cleanup (close files, connections, etc.)
    Console.WriteLine("Cleanup complete.");
}
```

- `catch` blocks are evaluated **top to bottom** — most specific first.
- `finally` runs even if `return` is called in `try` or `catch`.
- A `try` block can exist without `catch` (only `finally`), useful for cleanup-only patterns.

---

## Q3. What is the difference between `throw` and `throw ex`?
**Answer:**
- `throw` — **rethrows the current exception**, preserving the original stack trace.
- `throw ex` — **throws a new exception** from the current location, resetting the stack trace and losing the original origin information.

```csharp
catch (Exception ex)
{
    Log(ex);
    throw;        // ✓ preserves original stack trace
    // throw ex;  // ❌ loses original stack trace — avoid
}
```

Always use `throw;` (without variable) when re-throwing. Only use `throw ex;` if you intentionally want to wrap or replace the exception.

---

## Q4. What is exception chaining (inner exception)?
**Answer:**
When catching one exception and throwing a new one, pass the original as the `innerException` to preserve the full error context.

```csharp
try
{
    LoadConfig("config.json");
}
catch (IOException ex)
{
    throw new ApplicationException("Failed to start application.", ex); // chain
}

// Accessing the chain:
try { } catch (Exception ex)
{
    Exception current = ex;
    while (current != null)
    {
        Console.WriteLine(current.Message);
        current = current.InnerException;
    }
}
```

---

## Q5. How do you create a custom exception?
**Answer:**
Derive from `Exception` (or a more specific exception) and provide the standard constructors:

```csharp
class InsufficientFundsException : Exception
{
    public decimal Amount { get; }
    public decimal Balance { get; }

    public InsufficientFundsException(decimal amount, decimal balance)
        : base($"Cannot withdraw {amount:C}. Balance is {balance:C}.")
    {
        Amount = amount;
        Balance = balance;
    }

    // Always provide these constructors for proper serialization support
    public InsufficientFundsException() { }
    public InsufficientFundsException(string message) : base(message) { }
    public InsufficientFundsException(string message, Exception inner) : base(message, inner) { }
}
```

Name custom exceptions with the `Exception` suffix. Throw them to communicate domain-specific failures.

---

## Q6. What is exception filtering (`when` clause)?
**Answer:**
Exception filters (`catch (Ex ex) when (condition)`) let you conditionally handle an exception without catching and rethrowing, which preserves the original stack trace:

```csharp
try
{
    ProcessOrder(order);
}
catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
{
    Console.WriteLine("Order endpoint not found.");
}
catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.Unauthorized)
{
    Console.WriteLine("Authentication required.");
}
catch (HttpRequestException ex)
{
    Console.WriteLine("General HTTP error.");
}
```

If the `when` condition is `false`, the exception is **not caught** by that clause and continues up the call stack — unlike catching and rethrowing.

---

## Q7. What is `IDisposable`, and how does the `using` statement work?
**Answer:**
`IDisposable` defines `Dispose()` for deterministic cleanup of unmanaged or expensive resources. The `using` statement guarantees `Dispose()` is called even if an exception occurs.

```csharp
// Traditional using
using (var conn = new SqlConnection(connStr))
{
    conn.Open();
    // use conn
} // conn.Dispose() called automatically

// Using declaration (C# 8+) — disposes at end of enclosing scope
using var reader = new StreamReader("file.txt");
string content = reader.ReadToEnd();
// reader.Dispose() called here
```

Internally, `using` compiles to a `try-finally` block where `Dispose()` is called in the `finally`.

---

## Q8. What is `ObjectDisposedException` and when is it thrown?
**Answer:**
`ObjectDisposedException` is thrown when you attempt to use an object that has already been disposed. A well-implemented `IDisposable` type guards against this:

```csharp
public void Read()
{
    if (_disposed)
        throw new ObjectDisposedException(nameof(MyReader), "Cannot read after disposal.");
    // ...
}
```

Always check `_disposed` at the start of every public method in a disposable class. Once disposed, the object should not be used further.

---

## Q9. When should you catch `Exception` (the base class)?
**Answer:**
Catch the **most specific exception type** possible. Only catch `Exception` (base class) at:
1. **Top-level handlers** (global error handlers in ASP.NET, desktop apps, or worker services) to log and prevent crashes.
2. **When you will rethrow** — e.g., for logging before rethrowing.

```csharp
// Bad — swallows all exceptions, hides bugs
catch (Exception) { } // ❌

// Acceptable — log and rethrow
catch (Exception ex)
{
    _logger.LogError(ex, "Unhandled exception");
    throw; // ✓ rethrow preserving stack
}
```

Never catch `OutOfMemoryException`, `StackOverflowException`, or `ExecutionEngineException` — the process is in an undefined state and cannot recover.

---

## Q10. What is the difference between `ArgumentNullException`, `ArgumentException`, and `InvalidOperationException`?
**Answer:**
| Exception | Use when |
|---|---|
| `ArgumentNullException` | A required argument is `null` |
| `ArgumentOutOfRangeException` | An argument is outside the valid range |
| `ArgumentException` | An argument is invalid for another reason |
| `InvalidOperationException` | The operation is invalid for the **current state** of the object |
| `NotSupportedException` | The operation is not supported at all |
| `NotImplementedException` | Placeholder for code not yet written |

```csharp
public void SetName(string name)
{
    if (name == null) throw new ArgumentNullException(nameof(name));
    if (name.Length > 100) throw new ArgumentOutOfRangeException(nameof(name), "Too long");
}

public void Process()
{
    if (!_isInitialized)
        throw new InvalidOperationException("Call Initialize() first.");
}

---

## Q11. What is `AggregateException` and when does it occur?
**Answer:**
`AggregateException` wraps multiple exceptions that occurred simultaneously, most commonly from parallel/async operations:

```csharp
// When Task.WhenAll fails
try
{
    await Task.WhenAll(
        Task.FromException(new IOException("Disk error")),
        Task.FromException(new HttpRequestException("Network error"))
    );
}
catch (AggregateException ae)
{
    foreach (var ex in ae.InnerExceptions)
        Console.WriteLine(ex.Message);
}

// Flatten nested AggregateExceptions
ae.Flatten().Handle(ex =>
{
    if (ex is IOException) { LogIoError(ex); return true; }  // handled
    return false; // re-throw others
});
```

In modern `async`/`await` with a single `await`, the **first inner exception** is automatically unwrapped — you can catch `IOException` directly.

---

## Q12. What is `ExceptionDispatchInfo` and when is it used?
**Answer:**
`ExceptionDispatchInfo` (in `System.Runtime.ExceptionServices`) captures an exception's stack trace and lets you **rethrow it later** on a different thread while preserving the original stack trace:

```csharp
ExceptionDispatchInfo captured = null;
try
{
    // ... some operation
    throw new InvalidOperationException("Oops");
}
catch (Exception ex)
{
    captured = ExceptionDispatchInfo.Capture(ex); // capture with stack trace
}

// Later, possibly on another thread:
captured?.Throw(); // rethrows preserving original stack trace
```

This is used internally by the `async`/`await` machinery to marshal exceptions from background threads back to the caller's context. Prefer `throw;` for simple rethrowing within the same context.

---

## Q13. What is the .NET exception hierarchy?
**Answer:**
```
System.Object
  └─ System.Exception
       ├─ System.SystemException
       │    ├─ NullReferenceException
       │    ├─ IndexOutOfRangeException
       │    ├─ InvalidCastException
       │    ├─ OverflowException
       │    ├─ DivideByZeroException
       │    ├─ StackOverflowException     (cannot catch in .NET 2+)
       │    ├─ OutOfMemoryException       (can catch but process unstable)
       │    ├─ IOException
       │    ├─ ArgumentException
       │    │    ├─ ArgumentNullException
       │    │    └─ ArgumentOutOfRangeException
       │    └─ InvalidOperationException
       └─ System.ApplicationException  (deprecated — don't inherit from this)
       └─ YourCustomException          (derive directly from Exception)
```

Best practice: derive custom exceptions directly from `Exception`, not `ApplicationException` (the recommended split between system/app exceptions was abandoned in .NET).

---

## Q14. What happens if an exception is thrown inside a `finally` block?
**Answer:**
If an exception is thrown in a `finally` block, it **replaces** the original exception — the original is lost:

```csharp
try
{
    throw new InvalidOperationException("Original");
}
finally
{
    throw new IOException("From finally"); // ⚠️ replaces original!
    // Caller sees IOException, never sees InvalidOperationException
}
```

**Best practice:** Never throw exceptions in `finally` blocks. Only do cleanup (close streams, release locks). If cleanup might fail, catch and log the error silently:

```csharp
finally
{
    try { resource?.Dispose(); }
    catch (Exception ex) { logger.LogError(ex, "Cleanup failed"); } // swallow safely
}
```

---

## Q15. What is the difference between `StackOverflowException` and `OutOfMemoryException`? Can you catch them?
**Answer:**
| | `StackOverflowException` | `OutOfMemoryException` |
|---|---|---|
| **Cause** | Stack exhausted (infinite recursion or too-deep nesting) | Heap memory exhausted |
| **Catchable?** | No — CLR terminates the process | Yes — but process state is unreliable |
| **Recovery** | Impossible | Sometimes possible (release large objects) |

```csharp
// StackOverflow — cannot catch
void Infinite() => Infinite(); // crash

// OutOfMemory — can catch but dangerous
try
{
    var huge = new byte[long.MaxValue]; // force OOM
}
catch (OutOfMemoryException)
{
    // GC.Collect() here may help slightly; but state is suspect
    Console.WriteLine("Out of memory!");
    throw; // rethrow — don't try to continue normally
}
```

For `StackOverflowException`, the only remedy is to fix the code (add a base case, reduce recursion depth, or use an iterative algorithm). For `OutOfMemoryException`, use streaming/chunking to process data in smaller pieces.
```
