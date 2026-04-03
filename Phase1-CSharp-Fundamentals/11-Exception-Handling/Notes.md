# Topic 11: Exception Handling

## What is an Exception?

An exception is an **unexpected event** that occurs during program execution and disrupts the normal flow. Instead of crashing silently, C# gives you a structured way to **detect**, **handle**, and **recover** from errors.

```csharp
// Without exception handling — app crashes
int result = 10 / 0; // 💥 System.DivideByZeroException
```

---

## Why Exception Handling Matters

| Without Handling | With Handling |
|---|---|
| App crashes unexpectedly | App recovers gracefully |
| User sees cryptic errors | User sees friendly messages |
| No logging, hard to debug | Errors are logged and traceable |
| Data can be left inconsistent | Cleanup code always runs |

---

## The try-catch-finally Structure

### Basic Syntax

```csharp
try
{
    // Code that might throw an exception
    int result = 10 / 0;
}
catch (Exception ex)
{
    // Handle the exception
    Console.WriteLine($"Error: {ex.Message}");
}
finally
{
    // Always runs — whether exception occurred or not
    Console.WriteLine("Cleanup complete.");
}
```

### How It Works

1. Code inside `try` executes normally
2. If an exception occurs, execution **jumps** to the matching `catch` block
3. `finally` block **always runs** — even if no exception occurred, even if `return` is called

---

## Catching Specific Exceptions

Always catch **specific exceptions first**, then more general ones last.

```csharp
try
{
    Console.Write("Enter a number: ");
    string input = Console.ReadLine()!;
    int number = int.Parse(input);
    int result = 100 / number;
    Console.WriteLine($"Result: {result}");
}
catch (FormatException ex)
{
    Console.WriteLine($"Invalid format: {ex.Message}");
}
catch (DivideByZeroException ex)
{
    Console.WriteLine($"Cannot divide by zero: {ex.Message}");
}
catch (OverflowException ex)
{
    Console.WriteLine($"Number too large or too small: {ex.Message}");
}
catch (Exception ex)
{
    // General catch — catches anything not caught above
    Console.WriteLine($"Unexpected error: {ex.Message}");
}
```

### Why Order Matters

```
Exception (base class)
├── SystemException
│   ├── FormatException
│   ├── DivideByZeroException
│   ├── NullReferenceException
│   ├── IndexOutOfRangeException
│   ├── InvalidOperationException
│   ├── ArgumentException
│   │   ├── ArgumentNullException
│   │   └── ArgumentOutOfRangeException
│   ├── OverflowException
│   ├── StackOverflowException
│   ├── OutOfMemoryException
│   └── IOException
│       ├── FileNotFoundException
│       └── DirectoryNotFoundException
└── ApplicationException (legacy — don't use)
```

If you put `catch (Exception ex)` first, it catches **everything** and the specific catches below it become unreachable.

---

## The finally Block

`finally` is used for **cleanup** — closing files, releasing resources, resetting state.

```csharp
StreamReader? reader = null;
try
{
    reader = new StreamReader("data.txt");
    string content = reader.ReadToEnd();
    Console.WriteLine(content);
}
catch (FileNotFoundException)
{
    Console.WriteLine("File not found!");
}
finally
{
    // Always close the reader, even if an exception occurred
    reader?.Close();
    Console.WriteLine("Reader closed.");
}
```

### When finally Runs

| Scenario | finally runs? |
|---|---|
| No exception | ✅ Yes |
| Exception caught | ✅ Yes |
| Exception NOT caught | ✅ Yes (before app crashes) |
| `return` inside try/catch | ✅ Yes |
| `Environment.Exit()` called | ❌ No |
| `StackOverflowException` | ❌ No (process killed) |

---

## Throwing Exceptions

### throw Statement

Use `throw` to signal that something has gone wrong.

```csharp
void SetAge(int age)
{
    if (age < 0)
        throw new ArgumentOutOfRangeException(nameof(age), "Age cannot be negative.");
    
    if (age > 150)
        throw new ArgumentOutOfRangeException(nameof(age), "Age seems unrealistic.");
    
    Console.WriteLine($"Age set to {age}");
}

try
{
    SetAge(-5);
}
catch (ArgumentOutOfRangeException ex)
{
    Console.WriteLine(ex.Message);
}
```

### throw vs throw ex

```csharp
// ✅ CORRECT — preserves the original stack trace
catch (Exception ex)
{
    // Log the error
    Console.WriteLine($"Logging: {ex.Message}");
    throw; // Re-throws with original stack trace
}

// ❌ WRONG — resets the stack trace (loses where the error originated)
catch (Exception ex)
{
    Console.WriteLine($"Logging: {ex.Message}");
    throw ex; // Stack trace starts HERE, not at the original error
}
```

**Rule**: Always use `throw;` (without the variable) when re-throwing. Use `throw ex;` only if you intentionally want to reset the stack trace (rare).

---

## Creating Custom Exceptions

When built-in exceptions don't describe your error well enough, create your own.

### Basic Custom Exception

```csharp
public class InsufficientFundsException : Exception
{
    public decimal AttemptedAmount { get; }
    public decimal CurrentBalance { get; }

    public InsufficientFundsException(decimal attempted, decimal balance)
        : base($"Cannot withdraw {attempted:C}. Current balance: {balance:C}")
    {
        AttemptedAmount = attempted;
        CurrentBalance = balance;
    }

    // Optional: constructor with inner exception for chaining
    public InsufficientFundsException(decimal attempted, decimal balance, Exception innerException)
        : base($"Cannot withdraw {attempted:C}. Current balance: {balance:C}", innerException)
    {
        AttemptedAmount = attempted;
        CurrentBalance = balance;
    }
}
```

### Using the Custom Exception

```csharp
public class BankAccount
{
    public string Owner { get; }
    public decimal Balance { get; private set; }

    public BankAccount(string owner, decimal initialBalance)
    {
        Owner = owner;
        Balance = initialBalance;
    }

    public void Withdraw(decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentOutOfRangeException(nameof(amount), "Withdrawal amount must be positive.");

        if (amount > Balance)
            throw new InsufficientFundsException(amount, Balance);

        Balance -= amount;
        Console.WriteLine($"Withdrew {amount:C}. New balance: {Balance:C}");
    }
}

// Usage
var account = new BankAccount("Debanjan", 1000m);

try
{
    account.Withdraw(1500m);
}
catch (InsufficientFundsException ex)
{
    Console.WriteLine(ex.Message);
    Console.WriteLine($"You tried: {ex.AttemptedAmount:C}, You have: {ex.CurrentBalance:C}");
}
```

### Custom Exception Best Practices

1. **End the name with "Exception"**: `InsufficientFundsException`, not `InsufficientFunds`
2. **Inherit from `Exception`** (not `ApplicationException` — it's outdated)
3. **Include relevant data** as properties
4. **Provide multiple constructors**: default, message, message + inner exception

---

## Exception Filters (when keyword)

C# 6+ lets you add conditions to catch blocks.

```csharp
try
{
    MakeHttpRequest();
}
catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
{
    Console.WriteLine("Resource not found (404).");
}
catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.Unauthorized)
{
    Console.WriteLine("Authentication required (401).");
}
catch (HttpRequestException ex)
{
    Console.WriteLine($"HTTP error: {ex.StatusCode} — {ex.Message}");
}
```

### Why Use Filters Instead of if Inside catch?

```csharp
// ✅ With filter — exception is NOT caught if condition is false
// (other catch blocks can still handle it)
catch (Exception ex) when (ex.Message.Contains("timeout"))
{
    // Handle timeout specifically
}

// ❌ With if inside catch — exception IS caught, then you have to re-throw
catch (Exception ex)
{
    if (ex.Message.Contains("timeout"))
    {
        // Handle timeout
    }
    else
    {
        throw; // Re-throw — but stack unwinding already happened
    }
}
```

Exception filters don't unwind the stack, making them better for debugging.

---

## The using Statement & IDisposable

For objects that hold external resources (files, database connections, network streams), use `using` to guarantee cleanup.

### Classic using Statement

```csharp
using (StreamReader reader = new StreamReader("data.txt"))
{
    string content = reader.ReadToEnd();
    Console.WriteLine(content);
} // reader.Dispose() is called automatically here — even if an exception occurs
```

### Modern using Declaration (C# 8+)

```csharp
void ReadFile()
{
    using StreamReader reader = new StreamReader("data.txt");
    string content = reader.ReadToEnd();
    Console.WriteLine(content);
} // reader.Dispose() called when the method exits
```

### How using Works Under the Hood

The `using` statement is syntactic sugar for try-finally:

```csharp
// This:
using (var reader = new StreamReader("data.txt"))
{
    // use reader
}

// Is equivalent to:
StreamReader reader = new StreamReader("data.txt");
try
{
    // use reader
}
finally
{
    reader?.Dispose();
}
```

### Implementing IDisposable

```csharp
public class DatabaseConnection : IDisposable
{
    private bool _disposed = false;

    public DatabaseConnection(string connectionString)
    {
        Console.WriteLine($"Connected to: {connectionString}");
    }

    public void ExecuteQuery(string query)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(DatabaseConnection));
        
        Console.WriteLine($"Executing: {query}");
    }

    public void Dispose()
    {
        if (!_disposed)
        {
            Console.WriteLine("Connection closed.");
            _disposed = true;
        }
    }
}

// Usage
using var db = new DatabaseConnection("Server=localhost;Database=TaskFlow");
db.ExecuteQuery("SELECT * FROM Tasks");
// Dispose() is called automatically
```

---

## Common Exception Types Reference

| Exception | When It Occurs |
|---|---|
| `NullReferenceException` | Accessing a member on a null object |
| `IndexOutOfRangeException` | Array/list index beyond bounds |
| `ArgumentNullException` | Passing null to a method that doesn't accept it |
| `ArgumentOutOfRangeException` | Argument value outside valid range |
| `ArgumentException` | General invalid argument |
| `InvalidOperationException` | Operation not valid for current state |
| `FormatException` | String not in expected format (e.g., parsing) |
| `DivideByZeroException` | Dividing integer by zero |
| `FileNotFoundException` | File doesn't exist at specified path |
| `IOException` | General I/O error |
| `InvalidCastException` | Invalid type cast |
| `NotImplementedException` | Method not yet implemented (placeholder) |
| `NotSupportedException` | Operation not supported by the type |
| `TimeoutException` | Operation exceeded time limit |
| `StackOverflowException` | Call stack exhausted (infinite recursion) |
| `OutOfMemoryException` | Not enough memory to continue |

---

## Exception Handling Best Practices

### ✅ DO

```csharp
// 1. Catch specific exceptions
catch (FileNotFoundException ex) { /* handle */ }

// 2. Use throw; to re-throw (preserves stack trace)
catch (Exception ex) { Log(ex); throw; }

// 3. Use using/IDisposable for resource cleanup
using var connection = new SqlConnection(connString);

// 4. Validate inputs BEFORE they cause exceptions (Guard Clauses)
if (string.IsNullOrWhiteSpace(name))
    throw new ArgumentException("Name cannot be empty.", nameof(name));

// 5. Include meaningful messages
throw new InvalidOperationException("Cannot process order — cart is empty.");

// 6. Use exception filters for conditional catching
catch (SqlException ex) when (ex.Number == 2627) { /* duplicate key */ }
```

### ❌ DON'T

```csharp
// 1. Don't catch Exception for everything (swallowing errors)
catch (Exception) { } // Silent failure — bugs hide here

// 2. Don't use exceptions for flow control
try { int.Parse(input); } catch { } // Use int.TryParse instead!

// 3. Don't catch and do nothing
catch (Exception ex) { /* TODO: handle later */ }

// 4. Don't throw ex (resets stack trace)
catch (Exception ex) { throw ex; }

// 5. Don't catch exceptions you can't handle
catch (OutOfMemoryException) { /* What can you really do here? */ }
```

### TryParse Pattern — Avoid Exceptions for Expected Failures

```csharp
// ❌ Expensive — throws exception for invalid input
try
{
    int number = int.Parse(input);
}
catch (FormatException)
{
    Console.WriteLine("Invalid number");
}

// ✅ Better — no exception thrown
if (int.TryParse(input, out int number))
{
    Console.WriteLine($"Parsed: {number}");
}
else
{
    Console.WriteLine("Invalid number");
}
```

---

## Global Exception Handling (Preview)

In real applications, you add a **top-level catch** to handle anything unexpected:

```csharp
try
{
    // Your entire application logic
    RunApplication();
}
catch (Exception ex)
{
    Console.WriteLine("A fatal error occurred:");
    Console.WriteLine(ex.ToString()); // Full stack trace
    // In production: log to file, send to error tracking service
}
```

In ASP.NET Core (Phase 4), you'll use **middleware** for global exception handling — we'll cover that in detail there.

---

## Key Takeaways

| Concept | Summary |
|---|---|
| `try-catch-finally` | Structured way to handle exceptions |
| Specific catches first | Catch `FileNotFoundException` before `Exception` |
| `throw;` not `throw ex;` | Preserve the original stack trace |
| Custom exceptions | Create when built-in types don't fit your domain |
| `when` filters | Add conditions to catch blocks without unwinding stack |
| `using` / `IDisposable` | Automatic resource cleanup |
| Guard clauses | Validate inputs early to prevent exceptions |
| TryParse pattern | Avoid exceptions for expected failures |

---

*Next Topic: Collections (List, Dictionary, HashSet, etc.) →*
