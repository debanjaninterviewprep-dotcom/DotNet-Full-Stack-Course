# Phase 1 | Topic 7: Object-Oriented Programming — Classes & Objects

---

## 1. What is Object-Oriented Programming (OOP)?

OOP is a **programming paradigm** (a style/approach) where you organize code around **objects** — things that have **data** (properties) and **behavior** (methods).

Think about the real world:
- A **Car** has data (color, model, speed) and behavior (accelerate, brake, honk)
- A **Task** has data (title, priority, due date) and behavior (complete, assign, update)

Instead of writing loose variables and functions everywhere, OOP bundles related data and behavior together.

### Why OOP?
```
Without OOP (procedural):           With OOP:
─────────────────────────          ─────────────────────────
string task1Title = "Fix bug";     Task task1 = new Task("Fix bug", "High");
string task1Priority = "High";     task1.Complete();
bool task1Done = false;            Console.WriteLine(task1.Status);
                                   
string task2Title = "Add feature"; Task task2 = new Task("Add feature", "Medium");
string task2Priority = "Medium";   task2.AssignTo("Debanjan");
bool task2Done = false;

// Hard to manage as app grows!    // Clean, organized, scalable!
```

### The 4 Pillars of OOP:
```
┌──────────────────────────────────────────────┐
│              4 PILLARS OF OOP                 │
├───────────────┬──────────────────────────────┤
│ Encapsulation │ Hide internal details         │
│ Abstraction   │ Show only what's necessary    │
│ Inheritance   │ Reuse code from parent types  │
│ Polymorphism  │ Same action, different forms  │
└───────────────┴──────────────────────────────┘
```

We'll cover **Classes & Objects** in this topic, and the 4 pillars in Topics 8-10.

---

## 2. Classes — The Blueprint

A **class** is a **blueprint/template** that defines what data and behavior an object will have. It doesn't hold actual data — it just describes the **structure**.

```csharp
// Blueprint for a Task
class TaskItem
{
    // DATA (Fields & Properties)
    public string Title;
    public string Priority;
    public bool IsCompleted;
    
    // BEHAVIOR (Methods)
    public void Complete()
    {
        IsCompleted = true;
        Console.WriteLine($"✅ '{Title}' marked as completed!");
    }
    
    public void Display()
    {
        string status = IsCompleted ? "✅ Done" : "⬜ Pending";
        Console.WriteLine($"[{Priority}] {Title} — {status}");
    }
}
```

### Anatomy of a Class:

```
class ClassName
{
    // Fields       → variables that store data
    // Properties   → controlled access to data (get/set)
    // Constructors → initialize the object
    // Methods      → actions the object can perform
    // Events       → notifications (covered later)
}
```

---

## 3. Objects — Instances of a Class

An **object** is a **specific instance** created from a class blueprint. Each object has its own copy of the data.

```csharp
// Create objects (instances) from the TaskItem class
TaskItem task1 = new TaskItem();
task1.Title = "Fix login bug";
task1.Priority = "High";

TaskItem task2 = new TaskItem();
task2.Title = "Update dashboard";
task2.Priority = "Medium";

// Each object has its own data
task1.Display();   // [High] Fix login bug — ⬜ Pending
task2.Display();   // [Medium] Update dashboard — ⬜ Pending

task1.Complete();  // ✅ 'Fix login bug' marked as completed!
task1.Display();   // [High] Fix login bug — ✅ Done
task2.Display();   // [Medium] Update dashboard — ⬜ Pending (unaffected!)
```

### Class vs Object:

```
Class (Blueprint):              Objects (Instances):
┌─────────────────┐            ┌─────────────────┐
│    TaskItem      │            │ task1:           │
│  ─────────────── │    new     │  Title: "Fix bug"│
│  Title           │ ────────→  │  Priority: "High"│
│  Priority        │            │  IsCompleted: T  │
│  IsCompleted     │            └─────────────────┘
│  ─────────────── │            ┌─────────────────┐
│  Complete()      │    new     │ task2:           │
│  Display()       │ ────────→  │  Title: "Update" │
└─────────────────┘            │  Priority: "Med" │
                               │  IsCompleted: F  │
One blueprint                  └─────────────────┘
                               Multiple instances
```

---

## 4. Constructors

A **constructor** is a special method that runs **automatically when an object is created**. It's used to **initialize** the object with starting values.

### Default Constructor:

```csharp
class TaskItem
{
    public string Title;
    public string Priority;
    public bool IsCompleted;
    
    // Default constructor (no parameters)
    public TaskItem()
    {
        Title = "Untitled";
        Priority = "Medium";
        IsCompleted = false;
        Console.WriteLine("📌 New task created with defaults.");
    }
}

TaskItem task = new TaskItem();   // Constructor runs automatically
Console.WriteLine(task.Title);     // "Untitled"
```

### Parameterized Constructor:

```csharp
class TaskItem
{
    public string Title;
    public string Priority;
    public bool IsCompleted;
    
    // Parameterized constructor
    public TaskItem(string title, string priority)
    {
        Title = title;
        Priority = priority;
        IsCompleted = false;
    }
}

// Now you MUST provide title and priority:
TaskItem task = new TaskItem("Fix bug", "High");
Console.WriteLine(task.Title);     // "Fix bug"
```

### Multiple Constructors (Constructor Overloading):

```csharp
class TaskItem
{
    public string Title;
    public string Priority;
    public bool IsCompleted;
    public DateTime CreatedAt;
    
    // Constructor 1: Just title
    public TaskItem(string title)
    {
        Title = title;
        Priority = "Medium";
        IsCompleted = false;
        CreatedAt = DateTime.Now;
    }
    
    // Constructor 2: Title + Priority
    public TaskItem(string title, string priority)
    {
        Title = title;
        Priority = priority;
        IsCompleted = false;
        CreatedAt = DateTime.Now;
    }
    
    // Constructor 3: Full details
    public TaskItem(string title, string priority, bool isCompleted)
    {
        Title = title;
        Priority = priority;
        IsCompleted = isCompleted;
        CreatedAt = DateTime.Now;
    }
}

// All valid:
TaskItem t1 = new TaskItem("Fix bug");
TaskItem t2 = new TaskItem("Fix bug", "High");
TaskItem t3 = new TaskItem("Fix bug", "High", true);
```

### Constructor Chaining (`this`):

Avoid repeating initialization code by having constructors call each other:

```csharp
class TaskItem
{
    public string Title;
    public string Priority;
    public bool IsCompleted;
    public DateTime CreatedAt;
    
    // Primary constructor (does all the work)
    public TaskItem(string title, string priority, bool isCompleted)
    {
        Title = title;
        Priority = priority;
        IsCompleted = isCompleted;
        CreatedAt = DateTime.Now;
    }
    
    // Chain to the primary constructor
    public TaskItem(string title, string priority) : this(title, priority, false) { }
    
    public TaskItem(string title) : this(title, "Medium", false) { }
    
    public TaskItem() : this("Untitled", "Medium", false) { }
}
```

---

## 5. Fields vs Properties

### Fields (Simple Variables):

```csharp
class Player
{
    public string Name;     // Field — direct access, no control
    public int Score;       // Anyone can set any value!
}

Player p = new Player();
p.Score = -500;              // ⚠️ Negative score? No validation!
p.Name = "";                 // ⚠️ Empty name? No checks!
```

### Properties (Controlled Access — THE RIGHT WAY):

```csharp
class Player
{
    // Private field (backing field)
    private string _name;
    private int _score;
    
    // Property with get and set
    public string Name
    {
        get { return _name; }
        set
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("Name cannot be empty!");
            _name = value;
        }
    }
    
    public int Score
    {
        get { return _score; }
        set
        {
            if (value < 0)
                throw new ArgumentException("Score cannot be negative!");
            _score = value;
        }
    }
}

Player p = new Player();
p.Name = "Debanjan";     // ✅ Calls the 'set' accessor
p.Score = 100;            // ✅ Valid
// p.Score = -500;        // ❌ Throws exception — validation works!
```

### Auto-Properties (Shorthand — Most Common):

When you don't need custom logic in get/set:

```csharp
class TaskItem
{
    // Auto-properties — compiler generates the backing field
    public string Title { get; set; }
    public string Priority { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; }
    
    // Read-only property (set only in constructor)
    public int Id { get; }
    
    // Property with default value
    public string Status { get; set; } = "Pending";
    
    // Computed property (no setter)
    public string Summary => $"[{Priority}] {Title} — {Status}";
    
    public TaskItem(int id, string title, string priority)
    {
        Id = id;           // Can set read-only property in constructor
        Title = title;
        Priority = priority;
        CreatedAt = DateTime.Now;
    }
}
```

### Property Variants:

```csharp
class Example
{
    // Read-Write (most common)
    public string Name { get; set; }
    
    // Read-Only (set only in constructor)
    public int Id { get; }
    
    // Init-Only (C# 9+ — set only during initialization)
    public string Code { get; init; }
    
    // Private set (can read from outside, set only inside class)
    public DateTime CreatedAt { get; private set; }
    
    // Computed (derived from other properties)
    public string Display => $"{Id}: {Name}";
}

// Using init:
var ex = new Example { Code = "ABC" };   // ✅ Can set during init
// ex.Code = "XYZ";                       // ❌ Cannot change after init
```

---

## 6. The `this` Keyword

`this` refers to the **current instance** of the class:

```csharp
class TaskItem
{
    private string title;
    private string priority;
    
    public TaskItem(string title, string priority)
    {
        // 'this.title' = the field, 'title' = the parameter
        this.title = title;
        this.priority = priority;
    }
    
    public void Display()
    {
        // 'this' refers to the current object
        Console.WriteLine($"Task: {this.title}, Priority: {this.priority}");
    }
    
    // Return 'this' for method chaining
    public TaskItem SetTitle(string title)
    {
        this.title = title;
        return this;    // Return the current object
    }
    
    public TaskItem SetPriority(string priority)
    {
        this.priority = priority;
        return this;
    }
}

// Method chaining:
var task = new TaskItem("", "")
    .SetTitle("Fix bug")
    .SetPriority("High");
```

---

## 7. Static vs Instance Members

### Instance Members (belong to each object):

```csharp
class TaskItem
{
    public string Title { get; set; }      // Each object has its own Title
    
    public void Display()                   // Called on an object
    {
        Console.WriteLine(Title);
    }
}

TaskItem t1 = new TaskItem { Title = "Bug" };
TaskItem t2 = new TaskItem { Title = "Feature" };
t1.Display();   // "Bug"
t2.Display();   // "Feature"   — different data!
```

### Static Members (belong to the CLASS, not objects):

```csharp
class TaskItem
{
    // Static field — shared across ALL objects
    private static int _nextId = 1;
    
    // Instance fields — unique to each object
    public int Id { get; }
    public string Title { get; set; }
    
    public TaskItem(string title)
    {
        Id = _nextId;       // Use the static counter
        _nextId++;          // Increment for next task
        Title = title;
    }
    
    // Static method — called on the CLASS, not an object
    public static int GetTotalTasksCreated()
    {
        return _nextId - 1;
    }
    
    // Instance method — called on an object
    public void Display()
    {
        Console.WriteLine($"#{Id}: {Title}");
    }
}

TaskItem t1 = new TaskItem("Fix bug");       // Id = 1
TaskItem t2 = new TaskItem("Add feature");   // Id = 2
TaskItem t3 = new TaskItem("Write docs");    // Id = 3

t1.Display();                                // #1: Fix bug
t2.Display();                                // #2: Add feature

// Static method called on the CLASS name:
Console.WriteLine(TaskItem.GetTotalTasksCreated());  // 3

// ❌ Cannot call static method on an instance:
// t1.GetTotalTasksCreated();  // Compile error
```

### Static vs Instance:

```
Instance Members:                  Static Members:
─────────────────                 ─────────────────
• Belong to each object           • Belong to the class itself
• Accessed via object: obj.Name   • Accessed via class: Class.Method()
• Each object has its own copy    • Only ONE copy, shared by all
• Need an object to access        • No object needed
• Use for object-specific data    • Use for shared data/utility methods
```

### Static Classes:

```csharp
// A class that ONLY has static members — cannot create objects
static class MathHelper
{
    public static double CircleArea(double radius) => Math.PI * radius * radius;
    public static double CelsiusToFahrenheit(double c) => (c * 9 / 5) + 32;
    public static bool IsEven(int n) => n % 2 == 0;
}

// Use without creating an object:
double area = MathHelper.CircleArea(5);
double temp = MathHelper.CelsiusToFahrenheit(37);

// ❌ Cannot create instance:
// MathHelper m = new MathHelper();  // Compile error
```

---

## 8. Object Initializer Syntax

A cleaner way to create and initialize objects in one statement:

```csharp
class TaskItem
{
    public string Title { get; set; }
    public string Priority { get; set; }
    public bool IsCompleted { get; set; }
}

// Traditional way:
TaskItem task1 = new TaskItem();
task1.Title = "Fix bug";
task1.Priority = "High";
task1.IsCompleted = false;

// Object initializer (cleaner):
TaskItem task2 = new TaskItem
{
    Title = "Fix bug",
    Priority = "High",
    IsCompleted = false
};

// Target-typed new (C# 9+):
TaskItem task3 = new()
{
    Title = "Add feature",
    Priority = "Medium"
};
```

---

## 9. Null Objects & Null Checks

```csharp
TaskItem task = null;

// ❌ CRASH — NullReferenceException
// Console.WriteLine(task.Title);

// ✅ Check for null first
if (task != null)
{
    Console.WriteLine(task.Title);
}

// ✅ Null-conditional operator (from Topic 3)
Console.WriteLine(task?.Title);               // prints nothing (null)
Console.WriteLine(task?.Title ?? "No task");  // "No task"

// ✅ Pattern matching null check
if (task is not null)
{
    Console.WriteLine(task.Title);
}

// ✅ is null (preferred over == null)
if (task is null)
{
    Console.WriteLine("Task doesn't exist");
}
```

---

## 10. Records (C# 9+ — Immutable Data Objects)

For objects that mainly hold **data** and should be **immutable**:

```csharp
// Record — immutable by default, with built-in equality
public record TaskRecord(string Title, string Priority, bool IsCompleted);

// Create
var task = new TaskRecord("Fix bug", "High", false);

// Access
Console.WriteLine(task.Title);      // "Fix bug"

// ❌ Cannot modify (immutable)
// task.Title = "New title";        // Compile error!

// Create a copy with modifications using 'with'
var updatedTask = task with { IsCompleted = true };
Console.WriteLine(updatedTask);     // TaskRecord { Title = Fix bug, Priority = High, IsCompleted = True }

// Built-in equality (compares values, not references)
var task1 = new TaskRecord("Fix bug", "High", false);
var task2 = new TaskRecord("Fix bug", "High", false);
Console.WriteLine(task1 == task2);   // True! (compares all properties)

// Built-in ToString()
Console.WriteLine(task);   // TaskRecord { Title = Fix bug, Priority = High, IsCompleted = False }
```

### When to Use Records vs Classes:
```
Class:  When objects have behavior, state changes, identity matters
Record: When objects mainly hold data, should be immutable, equality = values
```

---

## 11. Putting It All Together — Practical Example

### TaskFlow Task System with Classes:

```csharp
// ======= MAIN PROGRAM =======
Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║   TASKFLOW - OOP TASK SYSTEM           ║");
Console.WriteLine("╚═══════════════════════════════════════╝");

// Create tasks using different constructors
TaskItem task1 = new TaskItem("Fix login bug", "High");
TaskItem task2 = new TaskItem("Update dashboard", "Medium");
TaskItem task3 = new TaskItem("Write API documentation");    // Uses default priority

// Display all tasks
Console.WriteLine("\n📋 ALL TASKS:");
task1.Display();
task2.Display();
task3.Display();

// Complete a task
task1.MarkComplete();
Console.WriteLine($"\n📊 Total tasks created: {TaskItem.TotalCount}");
Console.WriteLine($"📊 Completed: {TaskItem.CompletedCount}");

// Assign task
task2.AssignTo("Debanjan");
task2.Display();


// ======= CLASS DEFINITION =======
class TaskItem
{
    // Static fields (shared)
    private static int _nextId = 1;
    public static int TotalCount { get; private set; } = 0;
    public static int CompletedCount { get; private set; } = 0;
    
    // Instance properties
    public int Id { get; }
    public string Title { get; set; }
    public string Priority { get; set; }
    public bool IsCompleted { get; private set; }
    public string? Assignee { get; private set; }
    public DateTime CreatedAt { get; }
    
    // Computed property
    public string Status => IsCompleted ? "✅ Done" : "⬜ Pending";
    public string Summary => $"#{Id} [{Priority}] {Title} — {Status}";
    
    // Constructors
    public TaskItem(string title, string priority)
    {
        Id = _nextId++;
        Title = title;
        Priority = priority;
        IsCompleted = false;
        CreatedAt = DateTime.Now;
        TotalCount++;
    }
    
    public TaskItem(string title) : this(title, "Medium") { }
    
    // Methods
    public void MarkComplete()
    {
        if (!IsCompleted)
        {
            IsCompleted = true;
            CompletedCount++;
            Console.WriteLine($"✅ Task #{Id} '{Title}' completed!");
        }
        else
        {
            Console.WriteLine($"⚠️ Task #{Id} is already completed.");
        }
    }
    
    public void AssignTo(string assignee)
    {
        Assignee = assignee;
        Console.WriteLine($"👤 Task #{Id} assigned to {assignee}");
    }
    
    public void Display()
    {
        string assigneeInfo = Assignee != null ? $" (Assigned: {Assignee})" : "";
        Console.WriteLine($"  {Summary}{assigneeInfo}");
    }
    
    // Static method
    public static void PrintStats()
    {
        double percentage = TotalCount > 0 ? (double)CompletedCount / TotalCount * 100 : 0;
        Console.WriteLine($"📊 {CompletedCount}/{TotalCount} completed ({percentage:F1}%)");
    }
}
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **OOP** | Organize code around objects with data + behavior |
| **Class** | Blueprint/template — defines structure |
| **Object** | Instance of a class — holds actual data |
| **Field** | Variable inside a class — stores data |
| **Property** | Controlled access to data — use `{ get; set; }` |
| **Constructor** | Runs on `new` — initializes the object |
| **Constructor overloading** | Multiple constructors with different parameters |
| **Constructor chaining** | `: this(...)` — one constructor calls another |
| **`this`** | Refers to the current instance |
| **Static** | Belongs to the class, not individual objects |
| **Static class** | Only static members — can't create instances |
| **Object initializer** | `new Task { Title = "X" }` — inline property setting |
| **Auto-property** | `public string Name { get; set; }` — compiler generates backing field |
| **`init`** | Set only during initialization (C# 9+) |
| **Record** | Immutable data class with value equality (C# 9+) |
| **`with`** | Create copy of record with changes |

---

## Real-World Use Cases

1. **Domain Models** — Every real application has classes: `User`, `Product`, `Order`, `Invoice`, `Task`. Each has properties and methods that model the business domain.
2. **Services** — Classes like `EmailService`, `PaymentService`, `AuthService` contain behavior (methods) that operate on data.
3. **API Models** — `TaskDto`, `UserResponse`, `ErrorResponse` — classes/records used to send/receive data from APIs.
4. **Configuration** — `AppSettings`, `DatabaseConfig` — classes that hold application configuration loaded at startup.
5. **Utility Classes** — Static classes like `StringHelper`, `DateHelper`, `ValidationHelper` — common utility methods.
6. **TaskFlow Project** — `TaskItem`, `User`, `Project`, `Comment` — core domain classes that model the task management system.

---
