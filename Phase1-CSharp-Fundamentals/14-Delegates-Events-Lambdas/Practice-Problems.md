# Topic 14: Delegates, Events & Lambda Expressions — Practice Problems

## Problem 1: Function Toolkit with Delegates (Easy)
**Concept**: Func, Action, Predicate basics

Build a toolkit of reusable operations using built-in delegate types:

1. Create a `Func<int, int, int>` for each: Add, Subtract, Multiply, Divide
2. Create an `Action<string>` that prints text with a border:
   ```
   ╔══════════════════╗
   ║ Your text here   ║
   ╚══════════════════╝
   ```
3. Create a `Predicate<string>` for each: IsEmpty, IsAllCaps, ContainsDigit, IsEmail
4. Create a method `ApplyOperation(int a, int b, Func<int, int, int> operation, string opName)` that prints: `"5 Add 3 = 8"`
5. Create a method `TestAll(string input, params Predicate<string>[] tests)` that runs all predicates and reports which pass/fail

**Expected Output:**
```
=== Function Toolkit ===

--- Math Operations ---
5 Add 3 = 8
10 Subtract 4 = 6
6 Multiply 7 = 42
20 Divide 5 = 4

--- Bordered Print ---
╔═══════════════════════╗
║ Hello from delegates! ║
╚═══════════════════════╝

--- String Tests for "Hello123" ---
  IsEmpty:       ✗ FAIL
  IsAllCaps:     ✗ FAIL
  ContainsDigit: ✓ PASS
  IsEmail:       ✗ FAIL
```

---

## Problem 2: Custom Sort Engine (Easy-Medium)
**Concept**: Delegates as parameters, Comparison\<T\>, lambda expressions

Build a sorting system that accepts **custom comparison strategies**:

1. Create a `Product` class (Name, Price, Rating, Category)
2. Create a list of 8+ products
3. Build a method `SortAndDisplay(List<Product> products, Comparison<T> comparer, string description)`
4. Sort and display by:
   - Price (lowest first)
   - Price (highest first)
   - Name (alphabetical)
   - Rating (highest first)
   - Category then Price
   - Custom: "Best value" = Rating / Price ratio (highest first)
5. All sort criteria should be passed as **lambda expressions**

**Expected Output:**
```
=== Sort Engine ===

--- By Price (Low → High) ---
  Mouse         $29.99  ⭐4.2  Electronics
  Keyboard      $69.99  ⭐4.5  Electronics
  Headphones    $149.99 ⭐4.8  Electronics
  ...

--- By Best Value (Rating/Price) ---
  Mouse         $29.99  ⭐4.2  (Value: 0.140)
  Keyboard      $69.99  ⭐4.5  (Value: 0.064)
  ...

--- By Category, then Price ---
  [Electronics]
    Mouse         $29.99
    Keyboard      $69.99
  [Furniture]
    Desk Lamp     $45.99
    ...
```

---

## Problem 3: Event-Driven Chat Room (Medium)
**Concept**: Events, EventHandler\<T\>, custom EventArgs, subscribe/unsubscribe

Build a chat room system with events:

**Classes:**
1. `MessageEventArgs : EventArgs` — Sender, Message, Timestamp
2. `UserEventArgs : EventArgs` — Username, Action (joined/left)
3. `ChatRoom` — manages the room:
   - Events: `MessageSent`, `UserJoined`, `UserLeft`
   - Methods: `Join(username)`, `Leave(username)`, `SendMessage(username, message)`
   - Tracks connected users in a `HashSet<string>`
4. `ChatLogger` — subscribes to all events, logs with timestamps
5. `ProfanityFilter` — subscribes to `MessageSent`, checks for banned words
6. `UserNotifier` — subscribes to `UserJoined`/`UserLeft`, displays notifications

**Rules:**
- Can't send messages if not joined
- Can't join twice
- When a user leaves, unsubscribe their personal notifications
- ProfanityFilter replaces banned words with `***`

**Expected Output:**
```
=== Chat Room ===

[10:30:01] 🔔 Debanjan has joined the room.
[10:30:01] 📝 LOG: UserJoined — Debanjan

[10:30:05] 🔔 Alice has joined the room.
[10:30:05] 📝 LOG: UserJoined — Alice

[10:30:10] Debanjan: Hello everyone!
[10:30:10] 📝 LOG: Message from Debanjan: "Hello everyone!"

[10:30:15] Alice: Hi Debanjan! How are you?
[10:30:15] 📝 LOG: Message from Alice: "Hi Debanjan! How are you?"

[10:30:20] Bob tried to send a message but hasn't joined.
Error: Bob must join the room before sending messages.

[10:30:25] 🔔 Alice has left the room.
[10:30:25] 📝 LOG: UserLeft — Alice

Online users: Debanjan (1 user)
```

---

## Problem 4: Pipeline Builder with Higher-Order Functions (Medium-Hard)
**Concept**: Func chaining, closures, returning functions, generic delegates

Build a data transformation pipeline where operations are **composed dynamically**:

**Pipeline\<T\> Class:**
```csharp
// Should support chaining like:
var pipeline = new Pipeline<string>()
    .AddStep(s => s.Trim())
    .AddStep(s => s.ToLower())
    .AddStep(s => s.Replace(" ", "-"))
    .AddStep(s => $"processed-{s}");

string result = pipeline.Execute("  Hello World  ");
// "processed-hello-world"
```

**Build These Pipelines:**

1. **String Cleaner**: Trim → ToLower → remove special chars → collapse spaces
2. **Number Pipeline**: Parse string → double it → add 10 → convert to formatted string
3. **Slug Generator**: Trim → lowercase → replace spaces with hyphens → remove non-alphanumeric (except hyphens) → remove consecutive hyphens
4. **Pipeline with conditions**: Add a `AddConditionalStep(Predicate<T>, Func<T, T>)` that only applies the step if the predicate is true
5. **Pipeline composition**: Combine two pipelines into one

Also build a **Pipeline\<TIn, TOut\>** version that can change the type:
```csharp
var intToString = new Pipeline<int, string>()
    .Process(n => n * 2)      // int → int
    .Process(n => n + 100)    // int → int
    .Finish(n => $"Result: {n}"); // int → string

string output = intToString.Execute(5); // "Result: 110"
```

**Expected Output:**
```
=== Pipeline Builder ===

--- String Cleaner ---
Input:  "  Hello,   World!!!  "
Output: "hello world"

--- Slug Generator ---
Input:  "  My Blog Post Title!!! (2026)  "
Output: "my-blog-post-title-2026"

--- Conditional Pipeline ---
Input: "hello" (length ≤ 10 → uppercase)
Output: "HELLO"
Input: "this is a longer string" (length > 10 → no change)
Output: "this is a longer string"

--- Composed Pipeline ---
Pipeline A: Trim + Lowercase
Pipeline B: Replace spaces + Add prefix
Combined: "  HELLO WORLD  " → "url-hello-world"
```

---

## Problem 5: TaskFlow Event-Driven Notification System (Hard)
**Concept**: All concepts — delegates, events, lambdas, closures, EventHandler, higher-order functions

Build a complete notification system for TaskFlow:

**Event Args:**
1. `TaskEventArgs` — TaskId, Title, AssignedTo, Priority, EventType (Created/Updated/Completed/Deleted)
2. `DeadlineEventArgs : TaskEventArgs` — DueDate, IsOverdue

**TaskManager (Publisher):**
- Events: `TaskCreated`, `TaskUpdated`, `TaskCompleted`, `TaskDeleted`, `DeadlineApproaching`
- Methods: CreateTask, UpdateTask, CompleteTask, DeleteTask, CheckDeadlines
- Stores tasks in a `Dictionary<int, TaskItem>`

**Subscribers:**
1. `NotificationService` — sends notifications (console output) with configurable channels:
   - Accepts a `List<Action<string>>` of notification channels (Email, SMS, Push, Slack)
   - User configures which channels to use via lambdas at setup
2. `AuditLogger` — logs ALL events with timestamps to a `List<string>`
   - Method to export audit log (print all entries)
3. `TaskStatistics` — tracks metrics using closures:
   - Total created, completed, deleted
   - Average completion time
   - Completion rate
   - Most active user (most tasks completed)
4. `EscalationManager` — uses Func delegates for rules:
   - `AddRule(Predicate<TaskEventArgs> condition, Action<TaskEventArgs> action)`
   - Example rules: "If high-priority task overdue → notify manager", "If task updated 3+ times → flag for review"

**Program Flow:**
1. Set up TaskManager and all subscribers
2. Create 5 tasks with various priorities and due dates
3. Update some tasks
4. Complete some tasks
5. Check deadlines (some should trigger DeadlineApproaching)
6. Apply escalation rules
7. Print audit log
8. Print statistics dashboard

**Expected Output:**
```
=== TaskFlow Notification System ===

[CREATE] Task #1: "Design API" (High) assigned to Debanjan
  📧 Email: New task assigned — "Design API"
  💬 Slack: [#engineering] Task "Design API" created
  📝 Audit: 2026-04-04 10:00:00 — CREATED Task #1

[CREATE] Task #2: "Write Tests" (Medium) assigned to Alice
  📧 Email: New task assigned — "Write Tests"
  📝 Audit: 2026-04-04 10:00:01 — CREATED Task #2

[COMPLETE] Task #1: "Design API" completed by Debanjan
  📧 Email: Task completed — "Design API" 🎉
  💬 Slack: [#engineering] ✓ "Design API" completed!
  📝 Audit: 2026-04-04 10:05:00 — COMPLETED Task #1

[DEADLINE] Task #3: "Deploy v1" is OVERDUE (was due 2026-04-03)
  🚨 Escalation: High-priority overdue task — notifying manager!
  📧 Email: URGENT — "Deploy v1" is overdue!
  📱 SMS: Overdue alert: Task #3

=== Audit Log (6 entries) ===
  [10:00:00] CREATED  Task #1 "Design API" → Debanjan
  [10:00:01] CREATED  Task #2 "Write Tests" → Alice
  ...

=== Statistics Dashboard ===
  Tasks Created:    5
  Tasks Completed:  2
  Completion Rate:  40%
  Avg Completion:   5 min
  Most Active:      Debanjan (1 completed)

=== Escalation Report ===
  🚨 1 high-priority overdue task
  ⚠ 0 tasks flagged for excessive updates
```

---

### Submission
- Create a new console project: `dotnet new console -n DelegatesEventsPractice`
- Solve all 5 problems in `Program.cs`
- Use **lambdas** wherever an anonymous function is needed (not `delegate` keyword)
- Use **Func/Action/Predicate** instead of custom delegate types where possible
- Tell me "check" when you're ready for review!
