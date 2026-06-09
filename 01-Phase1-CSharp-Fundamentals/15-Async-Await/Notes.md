# Topic 15: Async/Await & Task-Based Programming

## Why Async?

In a **synchronous** program, each operation blocks the thread until it completes. If you download a file, your entire app freezes until the download finishes.

**Async** programming lets your app do other work while waiting for slow operations (network calls, file reads, database queries).

```csharp
// ❌ Synchronous — UI freezes for 3 seconds
void LoadData()
{
    Thread.Sleep(3000); // Simulates slow operation
    Console.WriteLine("Data loaded.");
}

// ✅ Asynchronous — app stays responsive
async Task LoadDataAsync()
{
    await Task.Delay(3000); // Non-blocking wait
    Console.WriteLine("Data loaded.");
}
```

---

## Synchronous vs Asynchronous — Visual

```
SYNCHRONOUS (one at a time):
Thread: [Download File---3s---][Process Data--1s--][Save to DB--2s--]
Total: 6 seconds

ASYNCHRONOUS (overlapping waits):
Thread: [Start Download][Start Process][Start Save]
         ↓               ↓              ↓
         [Await...3s]    [Await...1s]   [Await...2s]
Total: ~3 seconds (longest operation)
```

---

## The Task Type

`Task` represents an **asynchronous operation**. It's a promise that work will be completed in the future.

### Task (no return value)

```csharp
// Returns Task — async method with no result
async Task DoWorkAsync()
{
    Console.WriteLine("Working...");
    await Task.Delay(1000);
    Console.WriteLine("Done!");
}
```

### Task\<T\> (returns a value)

```csharp
// Returns Task<int> — async method that produces an int
async Task<int> CalculateAsync(int x, int y)
{
    await Task.Delay(500); // Simulate processing
    return x + y;
}

int result = await CalculateAsync(5, 3);
Console.WriteLine(result); // 8
```

### ValueTask\<T\> (optimization)

```csharp
// Use ValueTask when the result is often available synchronously (cached results)
async ValueTask<int> GetCachedValueAsync(int key)
{
    if (_cache.TryGetValue(key, out int value))
        return value; // No allocation — returns synchronously
    
    value = await FetchFromDatabaseAsync(key);
    _cache[key] = value;
    return value;
}
```

---

## async and await Keywords

### The Rules

1. `async` goes on the method signature
2. `await` goes before any async call inside that method
3. An `async` method must return `Task`, `Task<T>`, `ValueTask<T>`, or `void` (events only)
4. The method name should end with `Async` by convention

```csharp
// Rule 1: async keyword                Rule 4: Async suffix
async Task<string> FetchDataAsync()
{
    using HttpClient client = new HttpClient();
    
    // Rule 2: await the async operation
    string data = await client.GetStringAsync("https://api.example.com/data");
    
    return data; // Rule 3: returns Task<string>, but you return string
}
```

### What await Actually Does

```csharp
async Task ExampleAsync()
{
    Console.WriteLine("Before await");      // Runs on original thread
    
    await Task.Delay(1000);                 // Thread is RELEASED here
    // ← Thread goes back to do other work while waiting
    
    Console.WriteLine("After await");       // Runs after delay completes
    // (possibly on a different thread in console apps)
}
```

`await` does NOT block the thread. It **releases** the thread and **resumes** the method when the awaited task completes.

---

## Creating and Running Tasks

### Task.Run — Offload CPU Work

```csharp
// Run CPU-intensive work on a background thread
Task<int> task = Task.Run(() =>
{
    int sum = 0;
    for (int i = 0; i < 1_000_000; i++)
        sum += i;
    return sum;
});

int result = await task;
Console.WriteLine($"Sum: {result}");
```

### Task.Delay — Non-Blocking Wait

```csharp
// ✅ Non-blocking — releases the thread
await Task.Delay(2000);

// ❌ Blocking — freezes the thread
Thread.Sleep(2000); // DON'T use in async code
```

### Task.FromResult — Immediate Completion

```csharp
// When you need to return a Task but already have the result
Task<int> GetCachedAge() => Task.FromResult(25);

// Useful in interfaces that require async, but your impl is sync
```

---

## Running Multiple Tasks

### Task.WhenAll — Run All in Parallel

```csharp
async Task<string> FetchUserAsync()
{
    await Task.Delay(2000);
    return "User: Debanjan";
}

async Task<string> FetchOrdersAsync()
{
    await Task.Delay(1500);
    return "Orders: 5";
}

async Task<string> FetchNotificationsAsync()
{
    await Task.Delay(1000);
    return "Notifications: 3";
}

// ❌ Sequential — 4.5 seconds total
string user = await FetchUserAsync();             // 2s
string orders = await FetchOrdersAsync();         // 1.5s
string notifs = await FetchNotificationsAsync();  // 1s

// ✅ Parallel — ~2 seconds total (time of longest task)
Task<string> userTask = FetchUserAsync();
Task<string> ordersTask = FetchOrdersAsync();
Task<string> notifsTask = FetchNotificationsAsync();

string[] results = await Task.WhenAll(userTask, ordersTask, notifsTask);

Console.WriteLine(results[0]); // User: Debanjan
Console.WriteLine(results[1]); // Orders: 5
Console.WriteLine(results[2]); // Notifications: 3

// Or access individual results
string userResult = userTask.Result; // Safe after WhenAll completes
```

### Task.WhenAny — First to Complete Wins

```csharp
// Useful for timeouts or racing multiple sources
async Task<string> FetchWithTimeoutAsync()
{
    Task<string> dataTask = FetchDataFromApiAsync();
    Task timeoutTask = Task.Delay(5000); // 5 second timeout

    Task completedTask = await Task.WhenAny(dataTask, timeoutTask);

    if (completedTask == dataTask)
    {
        return await dataTask;
    }
    else
    {
        throw new TimeoutException("API call timed out after 5 seconds.");
    }
}
```

---

## Exception Handling in Async Code

### try-catch Works Naturally with await

```csharp
async Task<string> FetchDataAsync()
{
    try
    {
        using HttpClient client = new HttpClient();
        string data = await client.GetStringAsync("https://api.example.com/data");
        return data;
    }
    catch (HttpRequestException ex)
    {
        Console.WriteLine($"Network error: {ex.Message}");
        return "Fallback data";
    }
    catch (TaskCanceledException)
    {
        Console.WriteLine("Request timed out.");
        return "Timeout fallback";
    }
}
```

### Handling Exceptions from WhenAll

```csharp
Task task1 = Task.Run(() => throw new InvalidOperationException("Error 1"));
Task task2 = Task.Run(() => throw new ArgumentException("Error 2"));

try
{
    await Task.WhenAll(task1, task2);
}
catch (Exception ex)
{
    // Only catches the FIRST exception
    Console.WriteLine(ex.Message);
    
    // To see ALL exceptions:
    if (task1.IsFaulted)
        Console.WriteLine($"Task 1: {task1.Exception?.InnerException?.Message}");
    if (task2.IsFaulted)
        Console.WriteLine($"Task 2: {task2.Exception?.InnerException?.Message}");
}
```

### AggregateException

```csharp
Task allTasks = Task.WhenAll(task1, task2, task3);

try
{
    await allTasks;
}
catch
{
    // Access ALL exceptions via the task's Exception property
    AggregateException? allExceptions = allTasks.Exception;
    if (allExceptions != null)
    {
        foreach (var ex in allExceptions.InnerExceptions)
            Console.WriteLine($"Error: {ex.Message}");
    }
}
```

---

## Cancellation with CancellationToken

Allow users or the system to cancel long-running operations.

### Basic Cancellation

```csharp
async Task LongRunningOperationAsync(CancellationToken cancellationToken)
{
    for (int i = 0; i < 100; i++)
    {
        // Check if cancellation was requested
        cancellationToken.ThrowIfCancellationRequested();
        
        Console.WriteLine($"Processing step {i + 1}/100...");
        await Task.Delay(200, cancellationToken); // Delay also accepts token
    }
    Console.WriteLine("Operation complete!");
}

// Usage
using CancellationTokenSource cts = new CancellationTokenSource();

// Cancel after 3 seconds
cts.CancelAfter(TimeSpan.FromSeconds(3));

try
{
    await LongRunningOperationAsync(cts.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("Operation was cancelled.");
}
```

### Manual Cancellation

```csharp
using CancellationTokenSource cts = new CancellationTokenSource();

// Start long-running work
Task work = LongRunningOperationAsync(cts.Token);

// Simulate user pressing cancel
Console.WriteLine("Press any key to cancel...");
Console.ReadKey();
cts.Cancel(); // Signal cancellation

try
{
    await work;
}
catch (OperationCanceledException)
{
    Console.WriteLine("Cancelled by user.");
}
```

### Linked Cancellation Tokens

```csharp
// Combine multiple cancellation sources
using var userCts = new CancellationTokenSource();      // User can cancel
using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(30)); // Auto-cancel after 30s

using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(
    userCts.Token, timeoutCts.Token);

// Cancelled if EITHER user cancels OR timeout hits
await DoWorkAsync(linkedCts.Token);
```

---

## Progress Reporting

Report progress back to the caller using `IProgress<T>`.

```csharp
async Task DownloadFilesAsync(IProgress<int> progress, CancellationToken token)
{
    for (int i = 0; i < 10; i++)
    {
        token.ThrowIfCancellationRequested();
        
        await Task.Delay(500, token); // Simulate download
        
        int percentComplete = (i + 1) * 10;
        progress.Report(percentComplete);
    }
}

// Usage
Progress<int> progress = new Progress<int>(percent =>
{
    Console.Write($"\rDownloading: {percent}% [{"".PadLeft(percent / 5, '█').PadRight(20)}]");
});

using var cts = new CancellationTokenSource();
await DownloadFilesAsync(progress, cts.Token);
Console.WriteLine("\nDownload complete!");

// Output (updates in place):
// Downloading: 70% [██████████████      ]
```

---

## Async Patterns Comparison

### Pattern 1: Sequential Async

```csharp
// Each awaits before starting next — use when order matters
string user = await GetUserAsync(userId);
List<Order> orders = await GetOrdersAsync(user.Id);
decimal total = await CalculateTotalAsync(orders);
```

### Pattern 2: Concurrent Async

```csharp
// Start all, await all — use when independent
Task<string> userTask = GetUserAsync(userId);
Task<List<string>> notifsTask = GetNotificationsAsync(userId);
Task<int> messageCountTask = GetUnreadCountAsync(userId);

await Task.WhenAll(userTask, notifsTask, messageCountTask);

var user = userTask.Result;
var notifs = notifsTask.Result;
var count = messageCountTask.Result;
```

### Pattern 3: Fire-and-Forget (be careful)

```csharp
// ⚠ Exceptions are silently lost! Use only for truly optional work
_ = SendAnalyticsAsync(eventData); // Discard the task

// Safer version — at least log errors
_ = Task.Run(async () =>
{
    try { await SendAnalyticsAsync(eventData); }
    catch (Exception ex) { Console.WriteLine($"Analytics error: {ex.Message}"); }
});
```

---

## Common Async Pitfalls

### ❌ async void — Avoid!

```csharp
// ❌ NEVER use async void (except for event handlers)
async void BadMethod()
{
    await Task.Delay(1000);
    throw new Exception("Unobservable!"); // Crashes the app — can't be caught!
}

// ✅ Use async Task
async Task GoodMethod()
{
    await Task.Delay(1000);
    throw new Exception("Catchable!"); // Can be caught with try-catch
}

// ✅ Exception: event handlers require void
async void Button_Click(object sender, EventArgs e)
{
    try
    {
        await LoadDataAsync();
    }
    catch (Exception ex)
    {
        ShowError(ex.Message); // Handle exception inside the handler
    }
}
```

### ❌ .Result and .Wait() — Deadlock Risk

```csharp
// ❌ Can cause deadlocks in UI/ASP.NET apps
string data = FetchDataAsync().Result;  // BLOCKED!
FetchDataAsync().Wait();                // BLOCKED!

// ✅ Always use await
string data = await FetchDataAsync();
```

### ❌ Missing await

```csharp
// ❌ Task starts but nobody waits for it — errors are lost
async Task ProcessAsync()
{
    SaveToDatabase();  // This returns Task but isn't awaited!
    // Compiler warning CS4014
}

// ✅ Await it
async Task ProcessAsync()
{
    await SaveToDatabase();
}
```

---

## Real-World Async Patterns

### Retry Logic

```csharp
async Task<string> FetchWithRetryAsync(string url, int maxRetries = 3)
{
    using HttpClient client = new HttpClient();
    
    for (int attempt = 1; attempt <= maxRetries; attempt++)
    {
        try
        {
            return await client.GetStringAsync(url);
        }
        catch (HttpRequestException) when (attempt < maxRetries)
        {
            int delay = attempt * 1000; // Exponential-ish backoff
            Console.WriteLine($"Attempt {attempt} failed. Retrying in {delay}ms...");
            await Task.Delay(delay);
        }
    }
    throw new Exception($"Failed after {maxRetries} attempts.");
}
```

### Semaphore — Limit Concurrency

```csharp
// Process 100 items, but max 5 at a time
SemaphoreSlim semaphore = new SemaphoreSlim(5);
List<string> urls = GetUrls(); // 100 URLs

var tasks = urls.Select(async url =>
{
    await semaphore.WaitAsync(); // Wait for a slot
    try
    {
        return await DownloadAsync(url);
    }
    finally
    {
        semaphore.Release(); // Free the slot
    }
});

string[] results = await Task.WhenAll(tasks);
```

### Async Enumerable (C# 8+)

```csharp
// Produce items asynchronously one at a time
async IAsyncEnumerable<int> GenerateNumbersAsync()
{
    for (int i = 1; i <= 10; i++)
    {
        await Task.Delay(500); // Simulate async work
        yield return i;
    }
}

// Consume with await foreach
await foreach (int number in GenerateNumbersAsync())
{
    Console.Write($"{number} "); // Prints numbers one by one every 500ms
}
// 1 2 3 4 5 6 7 8 9 10
```

---

## Async in Console Apps (Top-Level Statements)

```csharp
// In modern C# with top-level statements, you can use await directly
Console.WriteLine("Starting...");
await Task.Delay(1000);
Console.WriteLine("Done!");

// Or call async methods
string result = await FetchGreetingAsync();
Console.WriteLine(result);

async Task<string> FetchGreetingAsync()
{
    await Task.Delay(500);
    return "Hello from async!";
}
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| `async` / `await` | Write non-blocking code that looks synchronous |
| `Task` / `Task<T>` | Represents an ongoing/future async operation |
| `Task.WhenAll` | Run multiple tasks in parallel, wait for all |
| `Task.WhenAny` | Wait for the first task to complete |
| `Task.Run` | Offload CPU-heavy work to a background thread |
| `CancellationToken` | Allow cooperative cancellation of async work |
| `IProgress<T>` | Report progress from async operations |
| `async void` | AVOID — only for event handlers |
| `.Result` / `.Wait()` | AVOID — deadlock risk; always `await` |
| `SemaphoreSlim` | Limit how many async tasks run concurrently |
| `IAsyncEnumerable` | Produce async streams of data |

---

*Next Topic: File I/O & Serialization →*
