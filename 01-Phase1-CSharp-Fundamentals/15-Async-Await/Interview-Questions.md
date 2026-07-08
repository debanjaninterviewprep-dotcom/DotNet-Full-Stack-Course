# Topic 15: Async/Await — Interview Questions

---

## Q1. What is async/await and why was it introduced?
**Answer:**
`async`/`await` is a language feature that makes asynchronous code look and behave like synchronous code, eliminating callback hell and making it easy to write non-blocking I/O.

Before async/await, you had to use callbacks, `BeginInvoke`/`EndInvoke`, or manual `Task` continuations. With async/await:

```csharp
// Non-blocking — thread is freed while waiting for I/O
public async Task<string> GetDataAsync(string url)
{
    using var client = new HttpClient();
    string result = await client.GetStringAsync(url); // thread released here
    return result.ToUpper();
}
```

When `await` suspends the method, the **calling thread is returned to the thread pool**. When the awaited operation completes, execution resumes (possibly on a different thread).

---

## Q2. What is the difference between `async void`, `async Task`, and `async Task<T>`?
**Answer:**
| Return type | Use case | Exceptions | Awaitable |
|---|---|---|---|
| `async void` | Event handlers only | Cannot be caught by caller | No |
| `async Task` | Async method with no return value | Propagated via task | Yes |
| `async Task<T>` | Async method returning a value | Propagated via task | Yes |

```csharp
// Event handler — only legitimate use of async void
private async void Button_Click(object sender, EventArgs e)
{
    await DoWorkAsync();
}

// Awaitable methods
public async Task SaveAsync() { await _db.SaveChangesAsync(); }
public async Task<User> GetUserAsync(int id) { return await _db.Users.FindAsync(id); }
```

**Never use `async void` outside of event handlers.** Exceptions thrown in `async void` crash the process.

---

## Q3. What is the difference between `Task` and `Thread`?
**Answer:**
| | `Thread` | `Task` |
|---|---|---|
| **Level** | OS-level thread | Logical unit of work (may use thread pool) |
| **Resource cost** | High (~1MB stack, kernel object) | Lightweight |
| **Return value** | No (use shared state) | Yes (`Task<T>`) |
| **Cancellation** | Manual abort (deprecated) | `CancellationToken` |
| **Composition** | Manual | `await`, `Task.WhenAll`, `Task.WhenAny` |
| **Use case** | Long-running, CPU-intensive | I/O-bound and CPU-bound work |

```csharp
// Thread — avoid for most new code
var thread = new Thread(() => DoWork());
thread.Start();

// Task — preferred
var task = Task.Run(() => DoWork());
await task;
```

---

## Q4. What is `Task.Run()` and when should you use it?
**Answer:**
`Task.Run()` queues work to the **thread pool**, making synchronous (CPU-bound) code awaitable.

```csharp
// CPU-bound work — run on thread pool
string result = await Task.Run(() => ComputeHeavyResult());

// I/O-bound — do NOT wrap in Task.Run (already async)
string data = await File.ReadAllTextAsync("file.txt"); // no Task.Run needed
```

**Rules:**
- Use `Task.Run()` for **CPU-bound** work in a UI or ASP.NET context to keep the calling thread free.
- Do **not** use `Task.Run()` in ASP.NET Core server code (it wastes thread pool threads).
- Do **not** wrap naturally async I/O methods in `Task.Run()`.

---

## Q5. What is `ConfigureAwait(false)` and when do you need it?
**Answer:**
By default, `await` tries to resume on the **original synchronization context** (e.g., the UI thread or ASP.NET request context). `ConfigureAwait(false)` says "I don't need the original context — resume on any available thread."

```csharp
// Library code — always use ConfigureAwait(false)
public async Task<string> FetchAsync(string url)
{
    var response = await httpClient.GetAsync(url).ConfigureAwait(false);
    return await response.Content.ReadAsStringAsync().ConfigureAwait(false);
}
```

**When to use:**
- In **library code** — avoids deadlocks and improves throughput.
- In **ASP.NET Core** — the sync context is null, so `ConfigureAwait(false)` has no effect but is still good practice.
- In **UI apps (WinForms/WPF)** — do NOT use `ConfigureAwait(false)` if you need to update UI after `await`.

---

## Q6. What is a deadlock in async code and how does it happen?
**Answer:**
A deadlock occurs when async code is blocked synchronously (`.Result` or `.Wait()`), and the awaited continuation needs the same thread that is blocked.

```csharp
// Deadlock in WinForms/WPF or legacy ASP.NET:
public void Button_Click(object sender, EventArgs e)
{
    var result = GetDataAsync().Result; // Blocks UI thread
    // GetDataAsync tries to resume on UI thread — but it's blocked → deadlock
}
```

**Fixes:**
1. Use `await` all the way up the call chain — never block.
2. Use `ConfigureAwait(false)` in library code.
3. Use `Task.Run(...).Result` only as a last resort for synchronous-only callers.

---

## Q7. What is `CancellationToken` and how do you use it?
**Answer:**
`CancellationToken` is the standard mechanism to cooperatively cancel async operations:

```csharp
public async Task ProcessAsync(CancellationToken ct = default)
{
    for (int i = 0; i < 100; i++)
    {
        ct.ThrowIfCancellationRequested(); // throws OperationCanceledException
        await DoStepAsync(i, ct);
    }
}

// Caller:
var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30)); // 30s timeout
try
{
    await ProcessAsync(cts.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("Operation was cancelled.");
}
```

Pass `CancellationToken` through the entire call chain. ASP.NET Core automatically provides tokens linked to the HTTP request lifecycle (`HttpContext.RequestAborted`).

---

## Q8. What is `Task.WhenAll()` and `Task.WhenAny()`?
**Answer:**
- `Task.WhenAll()` — awaits **all** tasks in parallel. Returns when all complete.
- `Task.WhenAny()` — returns when the **first** task completes.

```csharp
// Run three tasks in parallel — total time ≈ max(individual times)
var t1 = FetchUserAsync(1);
var t2 = FetchUserAsync(2);
var t3 = FetchUserAsync(3);
User[] users = await Task.WhenAll(t1, t2, t3);

// WhenAny — first result wins (e.g., timeout pattern)
var dataTask = FetchDataAsync();
var timeoutTask = Task.Delay(5000);
var winner = await Task.WhenAny(dataTask, timeoutTask);
if (winner == timeoutTask) throw new TimeoutException();
```

---

## Q9. What is `ValueTask<T>` and when is it preferred over `Task<T>`?
**Answer:**
`ValueTask<T>` is a **struct** (value type) wrapper for async results, designed to reduce allocations when the result is often available synchronously (e.g., cached data, high-frequency paths):

```csharp
public async ValueTask<int> GetCachedOrFetchAsync(int id)
{
    if (_cache.TryGetValue(id, out int val))
        return val;             // synchronous path — no Task allocation

    return await FetchFromDbAsync(id); // async path
}
```

**Use `Task<T>` by default.** Switch to `ValueTask<T>` only when profiling shows significant GC pressure from `Task` allocations in hot paths.

---

## Q10. What is the difference between parallelism and asynchrony?
**Answer:**
| | Asynchrony | Parallelism |
|---|---|---|
| **Purpose** | Avoid blocking a thread during I/O wait | Use multiple CPU cores simultaneously |
| **Thread count** | One or few threads; freed during wait | Multiple threads running at same time |
| **Use case** | I/O-bound work (HTTP, files, DB) | CPU-bound work (image processing, math) |
| **C# tools** | `async`/`await`, `Task` | `Task.WhenAll`, `Parallel.For`, PLINQ |

```csharp
// Asynchronous — one thread, not blocked during I/O
var data = await httpClient.GetStringAsync(url);

// Parallel — multiple threads doing CPU work simultaneously
Parallel.For(0, 1000000, i => ProcessItem(i));

// Async + parallel — best of both
await Task.WhenAll(items.Select(item => ProcessAsync(item)));

---

## Q11. What is `IAsyncEnumerable<T>` and async streams?
**Answer:**
`IAsyncEnumerable<T>` (C# 8+) is the async counterpart to `IEnumerable<T>`. It lets you produce and consume a sequence of items **asynchronously**, one at a time:

```csharp
// Producer — async iterator
async IAsyncEnumerable<int> StreamDataAsync()
{
    for (int i = 0; i < 10; i++)
    {
        await Task.Delay(100); // simulate async data fetch
        yield return i;        // yield works in async methods!
    }
}

// Consumer
await foreach (int item in StreamDataAsync())
{
    Console.WriteLine(item); // receives items as they arrive
}
```

Ideal for: database cursor streaming, paginated API calls, live feed data, file processing in chunks. Avoids loading all data into memory at once.

---

## Q12. What is `SynchronizationContext` and how does it affect async code?
**Answer:**
`SynchronizationContext` represents the thread or execution context where code should resume after `await`. Different hosting environments provide different contexts:

| Environment | Context | Behaviour |
|---|---|---|
| WPF/WinForms | `DispatcherSynchronizationContext` | Resumes on UI thread |
| ASP.NET (.NET Framework) | `AspNetSynchronizationContext` | Resumes on request thread |
| ASP.NET Core | None (`null`) | Resumes on thread pool |
| Console / test | None | Resumes on thread pool |

```csharp
// WPF — captures UI context
private async void Button_Click()
{
    var data = await FetchDataAsync();   // awaits on UI thread
    textBox.Text = data;                 // safe — resumes on UI thread
}

// Library code — opt out of context capture for performance
public async Task<string> LibraryMethod()
{
    return await httpClient.GetStringAsync(url).ConfigureAwait(false);
    // resumes on thread pool, not original context
}
```

---

## Q13. What is the difference between `Task.Delay()` and `Thread.Sleep()`?
**Answer:**
| | `Task.Delay()` | `Thread.Sleep()` |
|---|---|---|
| **Blocks thread?** | No — releases the thread | Yes — blocks the OS thread |
| **Works in async?** | Yes — `await Task.Delay(ms)` | Yes, but wastes a thread |
| **Cancellable?** | Yes — `CancellationToken` | No |
| **Precision** | OS timer (~15ms resolution) | Same |

```csharp
// Bad — blocks thread pool thread, hurts scalability
async Task BadWaitAsync() => Thread.Sleep(1000);

// Good — releases thread while waiting
async Task GoodWaitAsync() => await Task.Delay(1000);

// With cancellation
await Task.Delay(5000, cancellationToken); // throws OperationCanceledException if cancelled
```

---

## Q14. What is `SemaphoreSlim` and when is it used in async code?
**Answer:**
`SemaphoreSlim` is a lightweight semaphore that supports async waiting. It limits the number of concurrent accesses to a resource:

```csharp
private readonly SemaphoreSlim _semaphore = new SemaphoreSlim(3); // max 3 concurrent

async Task ProcessItemAsync(int id)
{
    await _semaphore.WaitAsync(); // async wait — won't block thread
    try
    {
        await DoWorkAsync(id);
    }
    finally
    {
        _semaphore.Release(); // always release
    }
}

// Throttle 100 tasks to 3 at a time
await Task.WhenAll(Enumerable.Range(0, 100).Select(ProcessItemAsync));
```

Use `SemaphoreSlim` instead of `lock` in async code — `lock` cannot be used with `await`.

---

## Q15. What is `Channel<T>` in .NET and when would you use it?
**Answer:**
`Channel<T>` (in `System.Threading.Channels`) is a high-performance, async-capable **producer-consumer pipe**:

```csharp
// Create a bounded channel (backpressure)
var channel = Channel.CreateBounded<int>(capacity: 100);

// Producer
Task.Run(async () =>
{
    for (int i = 0; i < 1000; i++)
    {
        await channel.Writer.WriteAsync(i); // async — waits if buffer full
    }
    channel.Writer.Complete(); // signal no more data
});

// Consumer
await foreach (int item in channel.Reader.ReadAllAsync())
{
    Console.WriteLine(item);
}
```

Channel types:
- `Channel.CreateBounded<T>(n)` — fixed-size buffer; writer blocks/drops when full.
- `Channel.CreateUnbounded<T>()` — unlimited buffer; writer never blocks.

Channels are the modern replacement for `BlockingCollection<T>` in async scenarios.
```
