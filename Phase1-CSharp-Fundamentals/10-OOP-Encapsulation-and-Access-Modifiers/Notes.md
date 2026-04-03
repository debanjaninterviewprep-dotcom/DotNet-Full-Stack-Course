# Phase 1 | Topic 10: OOP — Encapsulation & Access Modifiers

---

## 1. What is Encapsulation?

Encapsulation means **bundling data and methods together** inside a class and **controlling access** to the internal details. It's about **protecting** an object's state from unauthorized or accidental modification.

```
Real-world analogy:
─────────────────
A bank ATM:
  ✅ You can: Check balance, Withdraw, Deposit (public interface)
  ❌ You can't: Directly modify the bank's database, change someone else's balance,
     bypass the PIN check (private internals)

The ATM ENCAPSULATES the bank's internal systems behind a controlled interface.
```

### Two Aspects of Encapsulation:
1. **Data Hiding** — Make fields private, expose through properties
2. **Access Control** — Use access modifiers to restrict who can see what

---

## 2. Access Modifiers

Access modifiers control **who can see and use** your classes, properties, methods, and fields:

| Modifier | Same Class | Same Assembly | Derived Class | Anywhere |
|----------|-----------|---------------|--------------|----------|
| `private` | ✅ | ❌ | ❌ | ❌ |
| `protected` | ✅ | ❌ | ✅ | ❌ |
| `internal` | ✅ | ✅ | ❌ | ❌ |
| `protected internal` | ✅ | ✅ | ✅ | ❌ |
| `public` | ✅ | ✅ | ✅ | ✅ |
| `private protected` | ✅ | ❌ | ✅ (same assembly) | ❌ |

### What is an Assembly?

```
An "assembly" is your compiled project output (.dll or .exe).
If you have:
  - MyApp.Core (one project → one assembly)
  - MyApp.Web  (another project → another assembly)

'internal' members in MyApp.Core are visible within MyApp.Core only,
NOT in MyApp.Web.
```

---

## 3. private — The Default (What Others Can't Touch)

`private` members are only accessible **inside the same class**:

```csharp
class BankAccount
{
    // Private field — only this class can access it directly
    private decimal _balance;
    private string _pin;
    
    public string AccountHolder { get; set; }
    
    public BankAccount(string holder, decimal initialBalance, string pin)
    {
        AccountHolder = holder;
        _balance = initialBalance;
        _pin = pin;
    }
    
    // Public method — controlled access to private data
    public bool Withdraw(decimal amount, string enteredPin)
    {
        // Private method used internally
        if (!ValidatePin(enteredPin))
        {
            Console.WriteLine("❌ Invalid PIN!");
            return false;
        }
        
        if (amount > _balance)
        {
            Console.WriteLine("❌ Insufficient funds!");
            return false;
        }
        
        _balance -= amount;
        Console.WriteLine($"✅ Withdrew ₹{amount:N2}. Balance: ₹{_balance:N2}");
        return true;
    }
    
    public decimal GetBalance(string enteredPin)
    {
        if (!ValidatePin(enteredPin))
        {
            Console.WriteLine("❌ Invalid PIN!");
            return -1;
        }
        return _balance;
    }
    
    // Private method — internal logic hidden from outside
    private bool ValidatePin(string enteredPin)
    {
        return enteredPin == _pin;
    }
}

// Usage:
BankAccount account = new BankAccount("Debanjan", 50000m, "1234");

// ✅ Can use public methods:
account.Withdraw(5000m, "1234");    // Works — goes through validation
Console.WriteLine(account.AccountHolder);    // Works — public property

// ❌ Cannot access private members:
// account._balance = 999999m;       // Compile error!
// account._pin = "0000";            // Compile error!
// account.ValidatePin("1234");      // Compile error!
```

### Why Not Make Everything Public?

```csharp
// ❌ BAD — no encapsulation
class BadBankAccount
{
    public decimal Balance;      // Anyone can set to anything!
    public string Pin;           // Anyone can read the PIN!
}

BadBankAccount bad = new BadBankAccount();
bad.Balance = -1000000;          // Negative balance? No validation!
bad.Pin = "";                     // Cleared the PIN? Security disaster!

// ✅ GOOD — encapsulated
class GoodBankAccount
{
    private decimal _balance;
    
    public decimal Balance => _balance;   // Read-only from outside
    
    public void Deposit(decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Deposit must be positive!");
        _balance += amount;               // Validated modification
    }
}
```

---

## 4. protected — For Inheritance Only

`protected` members are accessible in the **same class** and **derived classes**:

```csharp
class Employee
{
    public string Name { get; set; }
    
    // Protected — derived classes can access, outside code cannot
    protected decimal _baseSalary;
    
    public Employee(string name, decimal baseSalary)
    {
        Name = name;
        _baseSalary = baseSalary;
    }
    
    // Protected method
    protected decimal CalculateBasePay()
    {
        return _baseSalary;
    }
    
    public virtual decimal GetTotalPay()
    {
        return CalculateBasePay();
    }
}

class Manager : Employee
{
    private decimal _bonus;
    
    public Manager(string name, decimal baseSalary, decimal bonus) 
        : base(name, baseSalary)
    {
        _bonus = bonus;
    }
    
    public override decimal GetTotalPay()
    {
        // ✅ Can access protected members from base class
        return _baseSalary + _bonus;                // Protected field
        // Or: return CalculateBasePay() + _bonus;  // Protected method
    }
}

// Usage:
Manager mgr = new Manager("Debanjan", 75000m, 15000m);
Console.WriteLine(mgr.GetTotalPay());    // 90000 ✅

// ❌ Cannot access protected from outside:
// Console.WriteLine(mgr._baseSalary);    // Compile error!
// mgr.CalculateBasePay();                // Compile error!
```

### When to Use protected:

```
Use protected when:
  ✅ Derived classes NEED access to implement their behavior
  ✅ But outside code should NOT directly access it
  
Avoid protected when:
  ❌ A private field + public/protected method would work better
  ❌ It's just for convenience (breaks encapsulation)
```

---

## 5. internal — Same Project Only

`internal` members are accessible **anywhere within the same assembly (project)**:

```csharp
// In MyApp.Core project:
internal class DatabaseHelper   // Only visible within MyApp.Core
{
    internal string ConnectionString { get; set; }
    
    internal void ExecuteQuery(string sql)
    {
        Console.WriteLine($"Executing: {sql}");
    }
}

// Also in MyApp.Core — can access DatabaseHelper ✅
class TaskRepository
{
    private DatabaseHelper _db = new DatabaseHelper();
    
    public void GetAllTasks()
    {
        _db.ExecuteQuery("SELECT * FROM Tasks");   // ✅ Same assembly
    }
}

// In MyApp.Web project (different assembly):
// DatabaseHelper helper = new DatabaseHelper();   // ❌ Compile error!
// It's internal to MyApp.Core — invisible to MyApp.Web
```

### When to Use internal:

```
Use internal when:
  ✅ Implementation details needed across classes in the SAME project
  ✅ Helper/utility classes that shouldn't be exposed to other projects
  ✅ Internal service implementations (public interface, internal implementation)

Default: Classes without any modifier are 'internal' by default
```

---

## 6. protected internal & private protected

### protected internal (OR logic):

Accessible if the caller is in the **same assembly** OR a **derived class** (even in a different assembly):

```csharp
class Employee
{
    // Accessible within same assembly OR from derived classes anywhere
    protected internal decimal BaseSalary { get; set; }
}
```

### private protected (AND logic):

Accessible only from **derived classes** within the **same assembly**:

```csharp
class Employee
{
    // Accessible ONLY from derived classes within the SAME assembly
    private protected decimal InternalId { get; set; }
}
```

> These are less common — `private`, `protected`, `public`, and `internal` cover 95% of cases.

---

## 7. Properties — The Encapsulation Workhorse

Properties are the **primary tool** for encapsulation. They provide controlled access to data:

### Full Property (Maximum Control):

```csharp
class TaskItem
{
    private string _title;
    private int _priority;
    
    public string Title
    {
        get { return _title; }
        set
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("Title cannot be empty!");
            if (value.Length > 200)
                throw new ArgumentException("Title too long! Max 200 chars.");
            _title = value.Trim();
        }
    }
    
    public int Priority
    {
        get { return _priority; }
        set
        {
            if (value < 1 || value > 5)
                throw new ArgumentException("Priority must be between 1 and 5!");
            _priority = value;
        }
    }
}
```

### Auto-Properties with Access Level Mix:

```csharp
class TaskItem
{
    // Read from outside, set only within this class
    public int Id { get; private set; }
    
    // Read from outside, set from this class or derived classes
    public string Status { get; protected set; }
    
    // Full public access
    public string Title { get; set; }
    
    // Read-only (set only in constructor)
    public DateTime CreatedAt { get; }
    
    // Init-only (C# 9+)
    public string CreatedBy { get; init; }
    
    public TaskItem(int id, string title, string createdBy)
    {
        Id = id;
        Title = title;
        Status = "New";
        CreatedAt = DateTime.Now;
        CreatedBy = createdBy;
    }
    
    public void Complete()
    {
        Status = "Completed";  // ✅ Private set — can change internally
    }
}

TaskItem task = new TaskItem(1, "Fix bug", "Debanjan");
Console.WriteLine(task.Id);         // ✅ Can read
// task.Id = 999;                    // ❌ Compile error — private set
// task.CreatedAt = DateTime.MinValue; // ❌ Compile error — read-only
Console.WriteLine(task.CreatedBy);  // ✅ Can read
// task.CreatedBy = "Hacker";        // ❌ Compile error — init-only
```

---

## 8. Encapsulation Patterns & Best Practices

### Pattern 1: Immutable Objects

Objects whose state **never changes** after creation:

```csharp
class ImmutableTask
{
    public int Id { get; }
    public string Title { get; }
    public string Priority { get; }
    public DateTime CreatedAt { get; }
    
    public ImmutableTask(int id, string title, string priority)
    {
        Id = id;
        Title = title;
        Priority = priority;
        CreatedAt = DateTime.Now;
    }
    
    // To "change" something, create a new object
    public ImmutableTask WithTitle(string newTitle)
    {
        return new ImmutableTask(Id, newTitle, Priority);
    }
    
    public ImmutableTask WithPriority(string newPriority)
    {
        return new ImmutableTask(Id, Title, newPriority);
    }
}

var task = new ImmutableTask(1, "Fix bug", "High");
// task.Title = "New title";              // ❌ Can't change!
var updatedTask = task.WithTitle("Fix critical bug");  // ✅ New object
```

### Pattern 2: Builder Pattern (Complex Object Construction):

```csharp
class TaskBuilder
{
    private string _title = "Untitled";
    private string _priority = "Medium";
    private string _assignee = "Unassigned";
    private string _description = "";
    private DateTime? _dueDate;
    
    public TaskBuilder SetTitle(string title)
    {
        _title = title;
        return this;
    }
    
    public TaskBuilder SetPriority(string priority)
    {
        _priority = priority;
        return this;
    }
    
    public TaskBuilder SetAssignee(string assignee)
    {
        _assignee = assignee;
        return this;
    }
    
    public TaskBuilder SetDescription(string description)
    {
        _description = description;
        return this;
    }
    
    public TaskBuilder SetDueDate(DateTime date)
    {
        _dueDate = date;
        return this;
    }
    
    public TaskItem Build()
    {
        // Validate before building
        if (string.IsNullOrWhiteSpace(_title))
            throw new InvalidOperationException("Task must have a title!");
        
        return new TaskItem(_title, _priority, _assignee, _description, _dueDate);
    }
}

// Usage — clean and readable:
var task = new TaskBuilder()
    .SetTitle("Fix login bug")
    .SetPriority("High")
    .SetAssignee("Debanjan")
    .SetDueDate(DateTime.Now.AddDays(3))
    .Build();
```

### Pattern 3: Encapsulated Collection:

```csharp
class TaskList
{
    // Private list — outside code can't modify directly
    private readonly List<TaskItem> _tasks = new();
    
    // Read-only access — return a copy or read-only view
    public IReadOnlyList<TaskItem> Tasks => _tasks.AsReadOnly();
    
    public int Count => _tasks.Count;
    
    // Controlled modification methods
    public void Add(TaskItem task)
    {
        if (task == null)
            throw new ArgumentNullException(nameof(task));
        if (_tasks.Any(t => t.Title == task.Title))
            throw new InvalidOperationException("Duplicate task title!");
        
        _tasks.Add(task);
        Console.WriteLine($"✅ Added: {task.Title}");
    }
    
    public bool Remove(int id)
    {
        var task = _tasks.FirstOrDefault(t => t.Id == id);
        if (task == null) return false;
        
        _tasks.Remove(task);
        return true;
    }
}

// Usage:
TaskList list = new TaskList();
list.Add(new TaskItem("Fix bug"));

// ✅ Can read tasks:
foreach (var task in list.Tasks)
    Console.WriteLine(task.Title);

// ❌ Cannot modify the list directly:
// list.Tasks.Add(new TaskItem("Hack!"));   // Compile error — IReadOnlyList!
// list.Tasks.Clear();                       // Compile error!
```

---

## 9. Access Modifier Best Practices

```
🏆 RULES OF THUMB:

1. Default to PRIVATE — make everything private first, then open up only what's needed

2. Use PROPERTIES, not public fields — ALWAYS
   ❌ public string Name;
   ✅ public string Name { get; set; }

3. Start restrictive, loosen only when needed:
   private → protected → internal → public

4. Fields should ALWAYS be private (or private readonly)

5. Use 'private set' when outside code should read but not write

6. Use 'protected' only when derived classes genuinely need access

7. Use 'internal' for implementation details within a project

8. Use 'readonly' for fields that should never change after construction

9. Validate in property setters — never trust input

10. Expose collections as IReadOnlyList, not List
```

---

## 10. Putting It All Together — Practical Example

### TaskFlow Secure Task Management:

```csharp
// ======= MAIN PROGRAM =======
Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║   TASKFLOW - ENCAPSULATION DEMO        ║");
Console.WriteLine("╚═══════════════════════════════════════╝");

// Create a project with encapsulated task management
var project = new Project("Sprint 1");

// Add tasks through controlled methods
project.AddTask("Fix login bug", "High", "Debanjan");
project.AddTask("Update dashboard", "Medium", "Rahul");
project.AddTask("Write tests", "Low", "Priya");

// View tasks — read-only access
Console.WriteLine($"\n📋 {project.Name} — {project.TaskCount} tasks:");
foreach (var task in project.Tasks)    // IReadOnlyList — can't modify!
{
    Console.WriteLine($"  {task}");
}

// Complete a task through the method (not by setting a property directly)
project.CompleteTask(1);

// Show stats
project.PrintSummary();


// ======= CLASS DEFINITIONS =======

class Project
{
    // Private backing data
    private readonly List<TaskItem> _tasks = new();
    private static int _nextTaskId = 1;
    
    // Public read-only properties
    public string Name { get; }
    public IReadOnlyList<TaskItem> Tasks => _tasks.AsReadOnly();
    public int TaskCount => _tasks.Count;
    public int CompletedCount => _tasks.Count(t => t.IsCompleted);
    public double CompletionPercentage => TaskCount > 0 
        ? (double)CompletedCount / TaskCount * 100 : 0;
    
    public Project(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Project name required!");
        Name = name;
    }
    
    // Controlled methods for modifying state
    public TaskItem AddTask(string title, string priority, string assignee)
    {
        var task = new TaskItem(_nextTaskId++, title, priority, assignee);
        _tasks.Add(task);
        Console.WriteLine($"✅ Task #{task.Id} added: {title}");
        return task;
    }
    
    public bool CompleteTask(int taskId)
    {
        var task = _tasks.FirstOrDefault(t => t.Id == taskId);
        if (task == null)
        {
            Console.WriteLine($"❌ Task #{taskId} not found!");
            return false;
        }
        
        task.Complete();  // Uses internal method
        return true;
    }
    
    public void PrintSummary()
    {
        Console.WriteLine($"\n📊 PROJECT SUMMARY: {Name}");
        Console.WriteLine($"   Total: {TaskCount}");
        Console.WriteLine($"   Done:  {CompletedCount}");
        Console.WriteLine($"   Progress: {CompletionPercentage:F1}%");
        
        int barLen = 20;
        int filled = (int)(CompletionPercentage / 100 * barLen);
        string bar = new string('█', filled) + new string('░', barLen - filled);
        Console.WriteLine($"   [{bar}]");
    }
}

class TaskItem
{
    // Read-only from outside
    public int Id { get; }
    public DateTime CreatedAt { get; }
    
    // Controlled setters
    public string Title { get; private set; }
    public string Priority { get; private set; }
    public string Assignee { get; private set; }
    public bool IsCompleted { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    
    // Computed
    public string Status => IsCompleted ? "✅ Done" : "⬜ Pending";
    
    // Internal constructor — only Project class (same assembly) creates tasks
    internal TaskItem(int id, string title, string priority, string assignee)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Title required!");
        
        Id = id;
        Title = title.Trim();
        Priority = priority;
        Assignee = assignee;
        IsCompleted = false;
        CreatedAt = DateTime.Now;
    }
    
    // Controlled state changes
    internal void Complete()
    {
        if (IsCompleted)
        {
            Console.WriteLine($"⚠️ Task #{Id} is already completed!");
            return;
        }
        
        IsCompleted = true;
        CompletedAt = DateTime.Now;
        Console.WriteLine($"✅ Task #{Id} '{Title}' completed!");
    }
    
    public void Reassign(string newAssignee)
    {
        if (IsCompleted)
            throw new InvalidOperationException("Cannot reassign a completed task!");
        
        string old = Assignee;
        Assignee = newAssignee;
        Console.WriteLine($"👤 Task #{Id} reassigned: {old} → {newAssignee}");
    }
    
    public override string ToString()
    {
        return $"#{Id} [{Priority}] {Title} — {Assignee} {Status}";
    }
}
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Encapsulation** | Bundle data + methods, control access to internals |
| **`private`** | Same class only — default for fields |
| **`protected`** | Same class + derived classes |
| **`internal`** | Same assembly (project) only |
| **`protected internal`** | Same assembly OR derived classes |
| **`private protected`** | Derived classes in same assembly only |
| **`public`** | Accessible everywhere |
| **Properties** | Primary encapsulation tool — controlled get/set |
| **`private set`** | Read from outside, write only inside |
| **`init`** | Set only during object initialization (C# 9+) |
| **Validation** | Validate in setters — reject bad data |
| **IReadOnlyList** | Expose collections as read-only |
| **Immutable objects** | No setters — create new object to "change" |
| **Builder pattern** | Step-by-step construction of complex objects |
| **Rule of thumb** | Start private, open up only when needed |

---

## Real-World Use Cases

1. **API Models** — Properties with `{ get; init; }` ensure request data can't be modified after deserialization. Private setters on `Id` and `CreatedAt` prevent tampering.
2. **Configuration** — `AppSettings` class with read-only properties loaded once at startup. No one can change database connection strings at runtime.
3. **Domain Models** — `Order` class with private `_items` list. Items added through `AddItem()` method that validates stock, calculates totals, and fires events.
4. **Security** — `UserSession` with private `_token`, `_expiresAt`. Token validated through `IsAuthenticated()` method, never exposed directly.
5. **Financial Systems** — `BankAccount` with private balance. All changes go through `Deposit()` and `Withdraw()` with validation, logging, and audit trails.
6. **TaskFlow Project** — `TaskItem` with private set on `Status`, `CompletedAt`. State changes only through `Complete()`, `Reopen()`, `Assign()` methods that enforce business rules.

---
