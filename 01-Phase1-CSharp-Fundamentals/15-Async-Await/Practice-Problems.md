# Topic 15: Async/Await & Task-Based Programming — Practice Problems

## Problem 1: Async Timer & Countdown (Easy)
**Concept**: async/await basics, Task.Delay, sequential vs concurrent

Build an async console app with:

1. **Countdown Timer**: Takes seconds as input, counts down asynchronously (prints every second)
2. **Parallel Stopwatch**: Start 3 async timers simultaneously:
   - Timer A: 3 seconds
   - Timer B: 5 seconds  
   - Timer C: 2 seconds
   Use `Task.WhenAll` — total time should be ~5 seconds, not 10
3. **Race Condition Demo**: Start 3 tasks with random delays (1-5 seconds). Use `Task.WhenAny` to report which finished first

**Expected Output:**
```
=== Async Timer ===

--- Countdown (5 seconds) ---
5... 4... 3... 2... 1... 🎉 Time's up!

--- Parallel Timers ---
[00:00] Starting all timers...
[00:02] ✓ Timer C finished (2s)
[00:03] ✓ Timer A finished (3s)
[00:05] ✓ Timer B finished (5s)
Total elapsed: ~5 seconds (parallel execution)

--- Race ---
[00:00] Starting race: Task-A (3s), Task-B (1s), Task-C (4s)
[00:01] 🏆 Task-B finished first!
[00:03] Task-A finished.
[00:04] Task-C finished.
```

---

## Problem 2: Async Data Fetcher with Retry (Easy-Medium)
**Concept**: Exception handling in async, retry pattern, Task.Delay

Simulate fetching data from multiple APIs (use `Task.Delay` + random success/failure):

1. Create `FetchDataAsync(string apiName, int delayMs, double failChance)`:
   - Simulates API call with delay
   - Throws `HttpRequestException` based on `failChance` (0.0 to 1.0)
   - Returns a string like "Data from {apiName}"

2. Create `FetchWithRetryAsync(string apiName, int maxRetries = 3)`:
   - Calls `FetchDataAsync`, retries on failure with exponential backoff
   - 1st retry: wait 1s, 2nd: 2s, 3rd: 4s
   - Returns result or throws after all retries exhausted

3. Fetch from 4 "APIs" concurrently with retry:
   - UserAPI (500ms, 20% fail)
   - OrderAPI (800ms, 40% fail)
   - ProductAPI (300ms, 10% fail)
   - ReviewAPI (1000ms, 50% fail)

4. Display results as they complete, and a summary at the end

**Expected Output:**
```
=== Async Data Fetcher ===

Fetching from 4 APIs concurrently...

[00:00.3] ✓ ProductAPI → "Data from ProductAPI" (1st attempt)
[00:00.5] ✓ UserAPI → "Data from UserAPI" (1st attempt)
[00:00.8] ✗ OrderAPI failed (attempt 1/3). Retrying in 1s...
[00:01.0] ✗ ReviewAPI failed (attempt 1/3). Retrying in 1s...
[00:01.8] ✓ OrderAPI → "Data from OrderAPI" (2nd attempt)
[00:02.0] ✗ ReviewAPI failed (attempt 2/3). Retrying in 2s...
[00:04.0] ✓ ReviewAPI → "Data from ReviewAPI" (3rd attempt)

=== Summary ===
  ProductAPI:  ✓ Success (1 attempt,  0.3s)
  UserAPI:     ✓ Success (1 attempt,  0.5s)
  OrderAPI:    ✓ Success (2 attempts, 1.8s)
  ReviewAPI:   ✓ Success (3 attempts, 4.0s)
  Total time: ~4.0s
```

---

## Problem 3: Async File Downloader with Progress & Cancellation (Medium)
**Concept**: CancellationToken, IProgress\<T\>, SemaphoreSlim, Task.WhenAll

Build an async file download simulator:

**Features:**
1. `DownloadFileAsync(string fileName, int sizeKB, IProgress<DownloadProgress>, CancellationToken)`:
   - Simulates downloading in chunks (10KB per chunk, 100ms per chunk)
   - Reports progress after each chunk (fileName, bytesDownloaded, totalBytes, percent)
   - Respects cancellation token

2. Create a `DownloadProgress` class with: FileName, BytesDownloaded, TotalBytes, PercentComplete

3. **Download Queue**: Accept 6 file downloads, but only run 3 at a time (use `SemaphoreSlim`)

4. **Progress Display**: Show a progress bar for each active download

5. **Cancellation**: Auto-cancel all downloads after 5 seconds (some won't finish)

6. **Summary**: Show completed, cancelled, and failed downloads

**Expected Output:**
```
=== Async File Downloader ===

Downloading 6 files (max 3 concurrent)...

[Active Downloads]
  report.pdf    [████████████████░░░░] 80%  (80/100 KB)
  image.png     [██████████░░░░░░░░░░] 50%  (25/50 KB)
  video.mp4     [██░░░░░░░░░░░░░░░░░░] 10%  (50/500 KB)

[Queued] data.csv, readme.md, archive.zip

✓ image.png     — Downloaded (50 KB in 0.5s)
✓ report.pdf    — Downloaded (100 KB in 1.0s)
  → Starting: data.csv, readme.md

⚠ CANCELLATION after 5 seconds!
✗ video.mp4     — Cancelled at 60% (300/500 KB)
✗ archive.zip   — Cancelled (never started)

=== Download Summary ===
  Completed: 4 files (270 KB)
  Cancelled: 2 files
  Total time: 5.0s
```

---

## Problem 4: Async Producer-Consumer Pipeline (Medium-Hard)
**Concept**: IAsyncEnumerable, Channels/Queue, concurrent processing

Build a data processing pipeline with three stages:

**Stage 1 — Producer**: Generates "raw data" items asynchronously
- Generates 20 items with random delay (50-200ms each)
- Each item: `{ Id, RawValue (random string), Timestamp }`

**Stage 2 — Processor** (3 concurrent workers): Transforms data
- Takes raw items, performs "heavy computation" (200-500ms delay)
- Transforms: uppercase, add hash, calculate length
- Outputs: `{ Id, ProcessedValue, ProcessingTimeMs }`

**Stage 3 — Consumer**: Collects and reports results
- Receives processed items as they arrive
- Displays real-time progress
- At the end, shows statistics

**Implementation:** Use `IAsyncEnumerable<T>` for the producer, process with concurrent tasks, collect results.

**Expected Output:**
```
=== Async Pipeline ===

[Producer] Generating 20 items...
[Worker-1] Processing Item #1...
[Worker-2] Processing Item #2...
[Worker-3] Processing Item #3...
[Worker-1] ✓ Item #1 processed (245ms)
[Consumer] Received Item #1: "PROCESSED_ABC123" (hash: 7F2A)
[Worker-1] Processing Item #4...
[Worker-2] ✓ Item #2 processed (312ms)
...

=== Pipeline Statistics ===
  Items Produced:  20
  Items Processed: 20
  Items Consumed:  20
  
  Avg Processing Time: 287ms
  Min Processing Time: 201ms
  Max Processing Time: 498ms
  
  Total Pipeline Time: 2.8s
  Throughput: 7.1 items/sec
  
  Worker Stats:
    Worker-1: 7 items (avg 275ms)
    Worker-2: 7 items (avg 291ms)
    Worker-3: 6 items (avg 296ms)
```

---

## Problem 5: TaskFlow Async Dashboard Refresher (Hard)
**Concept**: All async concepts combined

Build an async dashboard that periodically refreshes data from multiple "services":

**Service Simulations (all async):**
1. `TaskService` — fetches tasks (1-2s delay, 10% fail rate)
2. `UserService` — fetches active users (0.5-1s delay, 5% fail rate)
3. `NotificationService` — fetches notifications (0.3-0.8s delay, 15% fail rate)
4. `MetricsService` — fetches system metrics (2-3s delay, 20% fail rate)

**Dashboard Features:**
1. **Initial Load**: Fetch ALL services concurrently with `Task.WhenAll`
   - Show loading spinner while waiting
   - Display results as each completes (don't wait for all)

2. **Auto-Refresh**: Refresh every 10 seconds using a background loop
   - Each service refreshes independently
   - Failed services show "stale data" with last successful timestamp
   - Use `CancellationToken` to stop refreshing

3. **Retry with Circuit Breaker**:
   - If a service fails 3 times in a row, "open" the circuit (skip it for 30 seconds)
   - After 30 seconds, try once (half-open)
   - If it succeeds, close the circuit; if not, keep it open

4. **Manual Refresh**: User can press 'R' to force refresh (without waiting for auto-refresh)
   - Use `Task.WhenAny` to watch for both user input and auto-refresh timer

5. **Graceful Shutdown**: User presses 'Q' to quit
   - Cancel all pending operations
   - Wait for in-flight requests to cancel (with 3 second timeout)
   - Display final state

**Expected Output:**
```
╔══════════════════════════════════════╗
║      TaskFlow Live Dashboard         ║
╠══════════════════════════════════════╣

Loading dashboard data...
  [0.5s] ✓ Notifications loaded (3 new)
  [0.8s] ✓ Users loaded (12 active)
  [1.2s] ✓ Tasks loaded (28 total, 5 in progress)
  [2.5s] ✓ Metrics loaded (CPU: 45%, Memory: 62%)

╔══════════════════════════════════════╗
║ Tasks:        28 total, 5 in progress║
║ Users:        12 active              ║
║ Notifications: 3 new                 ║
║ System:       CPU 45% | RAM 62%      ║
╠══════════════════════════════════════╣
║ Last refresh: 10:30:05               ║
║ Next refresh: in 8s                  ║
║ [R] Refresh  [Q] Quit               ║
╚══════════════════════════════════════╝

[10:30:15] Auto-refresh...
  ✓ Notifications updated
  ✓ Users updated
  ✗ Tasks failed (showing stale data from 10:30:05)
  ✓ Metrics updated

[10:30:25] Auto-refresh...
  ✗ Tasks failed (2nd consecutive failure)
  
[10:30:35] Auto-refresh...
  ✗ Tasks failed (3rd failure — circuit OPEN, skipping for 30s)
  ⚠ Circuit breaker activated for TaskService

[10:31:05] Tasks circuit half-open — testing...
  ✓ Tasks recovered! Circuit CLOSED.

> Q
Shutting down... cancelling 2 pending requests.
Dashboard closed. Goodbye!
```

---

### Submission
- Create a new console project: `dotnet new console -n AsyncAwaitPractice`
- Solve all 5 problems in `Program.cs`
- **Important**: Use `await` everywhere — never use `.Result` or `.Wait()`
- Test cancellation by pressing keys or letting timeouts expire
- Tell me "check" when you're ready for review!
