# Phase 1 | Topic 9: Practice Problems — Abstraction & Interfaces

---

## Problem 1: Abstract Shape System (Easy)
**Difficulty:** ⭐ Easy

Create:
- **Abstract class `Shape`**: abstract `Area()`, abstract `Perimeter()`, regular `Describe()` method
- **`Rectangle : Shape`**, **`Circle : Shape`**, **`Triangle : Shape`**

The `Describe()` method should call `Area()` and `Perimeter()` (which are abstract — polymorphism!)

**Expected Output:**
```
=== SHAPE GALLERY ===

Rectangle (5 x 10):
  Area: 50.00
  Perimeter: 30.00

Circle (radius 7):
  Area: 153.94
  Perimeter: 43.98

Triangle (3, 4, 5):
  Area: 6.00
  Perimeter: 12.00
```

**Requirements:**
- Use `abstract` class and methods
- Use `override` in each derived class
- Store shapes in a `Shape[]` and loop with `foreach`

---

## Problem 2: Interface-Based Logger (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Create an `ILogger` interface with:
- `void Log(string message)`
- `void LogError(string message)`
- `void LogWarning(string message)`

Implement it in 3 classes:
- `ConsoleLogger` — prints to console with colors (use emoji for color suggestion)
- `FileLogger` — simulates writing to a file (just print "Writing to file...")
- `MemoryLogger` — stores logs in a `List<string>` and can dump all logs

Demonstrate **interface polymorphism** by storing all loggers in an `ILogger[]` and sending the same message through all of them.

**Expected Output:**
```
=== LOGGING DEMO ===

Sending "App started" through all loggers:

  [Console] ℹ️ App started
  [File] Writing to app.log: App started
  [Memory] Stored: App started

MemoryLogger dump:
  1. [INFO] App started
  2. [ERROR] Connection failed
  3. [WARNING] Low memory
```

---

## Problem 3: Interface Segregation — Document System (Medium)
**Difficulty:** ⭐⭐ Medium

Demonstrate the **Interface Segregation Principle** — don't force classes to implement methods they don't need.

Create small, focused interfaces:
- `IPrintable` — `void Print()`
- `IScannable` — `void Scan()`
- `IFaxable` — `void Fax(string number)`
- `IEmailable` — `void Email(string address)`

Create these classes:
- `MultiFunctionPrinter` — implements ALL four
- `SimplePrinter` — only `IPrintable`
- `DigitalDocument` — `IPrintable`, `IEmailable`
- `OldFaxMachine` — `IFaxable` only

Create a method that accepts `IPrintable` — demonstrate that multiple different classes can be passed.

**Expected Output:**
```
=== DOCUMENT SYSTEM ===

All printable devices:
  🖨️ MultiFunctionPrinter printing...
  🖨️ SimplePrinter printing...
  📄 DigitalDocument printing...

Email-capable devices:
  📧 MultiFunctionPrinter emailing to boss@company.com
  📧 DigitalDocument emailing to boss@company.com

Fax-capable devices:
  📠 MultiFunctionPrinter faxing to +91-1234567890
  📠 OldFaxMachine faxing to +91-1234567890
```

---

## Problem 4: Sortable & Equatable Task System (Medium)
**Difficulty:** ⭐⭐ Medium

Create a `TaskItem` class that implements:
- `IComparable<TaskItem>` — sort by priority (High > Medium > Low), then by title
- `IEquatable<TaskItem>` — two tasks are equal if they have the same `Id`
- `IFormattable` — custom format strings: `"S"` for short, `"D"` for detailed

**Expected Output:**
```
=== BEFORE SORTING ===
#3 [Low] Write docs
#1 [High] Fix critical bug
#2 [Medium] Update UI
#4 [High] Security patch

=== AFTER SORTING (by priority) ===
#1 [High] Fix critical bug
#4 [High] Security patch
#2 [Medium] Update UI
#3 [Low] Write docs

=== EQUALITY CHECK ===
Task #1 == Task #1 (different object)? True
Task #1 == Task #2? False

=== FORMATTED OUTPUT ===
Short:    #1: Fix critical bug
Detailed: Task #1 | Fix critical bug | Priority: High | Status: Pending
```

**Requirements:**
- Implement all three interfaces properly
- Override `ToString()`, `Equals()`, `GetHashCode()`
- Use `Array.Sort()` with your `IComparable` implementation

---

## Problem 5: TaskFlow Service Layer (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a service-based architecture for TaskFlow using interfaces and abstract classes:

**Interfaces:**
- `IRepository<T>` — generic CRUD: `Add(T item)`, `GetById(int id)`, `GetAll()`, `Update(T item)`, `Delete(int id)`, `Count` property
- `INotificationService` — `Send(string to, string subject, string body)`, `SendBulk(string[] recipients, string subject, string body)`
- `IExportService` — `ExportToCsv(IEnumerable<T> items)`, `ExportToJson(IEnumerable<T> items)`

**Abstract class:**
- `TaskBase` — `Id`, `Title`, `Description`, `IsCompleted`, abstract `GetCategory()`, abstract `GetPriorityScore()`

**Concrete classes:**
- `BugTask : TaskBase`, `FeatureTask : TaskBase`, `ChoreTask : TaskBase`
- `InMemoryTaskRepository : IRepository<TaskBase>`
- `ConsoleNotificationService : INotificationService`
- `SimpleExportService : IExportService`

**Build an interactive app** that demonstrates:
1. Add different task types
2. View all tasks (sorted by priority using IComparable)
3. Export tasks as CSV or JSON
4. Send notification when task is created/completed
5. Show statistics

**Expected Output:**
```
╔════════════════════════════════════════════════╗
║       TASKFLOW SERVICE LAYER DEMO              ║
╚════════════════════════════════════════════════╝

1. Add Task    2. View All    3. Complete
4. Export       5. Notify All  6. Stats
0. Exit

Choice: 1
Type (B)ug/(F)eature/(C)hore: B
Title: Login crash
Severity: Critical
✅ Bug added! ID: 1
🔔 Notification sent: "New Bug: Login crash"

Choice: 4
Format (C)sv/(J)son: J
[
  {"id":1,"type":"Bug","title":"Login crash","priority":10},
  {"id":2,"type":"Feature","title":"Dashboard","priority":7}
]

Choice: 6
📊 Total: 3 | Bugs: 1 | Features: 1 | Chores: 1
📊 Completed: 0/3 (0%)
📊 Total Priority Score: 20
```

**Requirements:**
- Code against **interfaces**, not concrete classes
- Use abstract class + interface together
- All services used via interface references
- Demonstrate that services could be swapped (mention in comments)

---

## Instructions

1. Solve each problem in a project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Abstract Shape System
- [ ] Problem 2: Interface-Based Logger
- [ ] Problem 3: Interface Segregation — Document System
- [ ] Problem 4: Sortable & Equatable Task System
- [ ] Problem 5: TaskFlow Service Layer
