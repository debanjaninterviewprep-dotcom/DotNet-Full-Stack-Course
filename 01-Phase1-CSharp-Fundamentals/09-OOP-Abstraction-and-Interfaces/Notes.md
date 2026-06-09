# Phase 1 | Topic 9: OOP — Abstraction & Interfaces

---

## 1. What is Abstraction?

Abstraction means **hiding complex implementation details** and exposing only what's necessary. You show the **"what"** without revealing the **"how"**.

```
Real-world analogy:
─────────────────
When you drive a car:
  ✅ You know: Press accelerator → car goes faster
  ❌ You don't need to know: How fuel injection, combustion, 
     transmission, and wheel rotation work internally

The car ABSTRACTS away the complexity.
```

In C#, abstraction is achieved through:
1. **Abstract classes** — partially implemented base classes
2. **Interfaces** — contracts that define what a class must do

---

## 2. Abstract Classes

An **abstract class** is a class that:
- **Cannot be instantiated** (can't do `new AbstractClass()`)
- Can have **abstract methods** (no body — derived classes MUST implement them)
- Can have **regular methods** (with body — shared implementation)
- Can have **fields, properties, constructors** — everything a normal class has

```csharp
// Abstract class — cannot create instances directly
abstract class Shape
{
    // Regular property (shared by all shapes)
    public string Name { get; set; }
    public string Color { get; set; }
    
    // Constructor (called by derived classes)
    protected Shape(string name, string color)
    {
        Name = name;
        Color = color;
    }
    
    // Abstract method — NO body, MUST be implemented by derived classes
    public abstract double Area();
    public abstract double Perimeter();
    
    // Regular method — shared implementation
    public void Display()
    {
        Console.WriteLine($"{Name} ({Color}): Area = {Area():F2}, Perimeter = {Perimeter():F2}");
    }
}

// ❌ Cannot instantiate abstract class:
// Shape s = new Shape("Test", "Red");   // Compile error!

// Derived class MUST implement ALL abstract methods
class Rectangle : Shape
{
    public double Width { get; set; }
    public double Height { get; set; }
    
    public Rectangle(double width, double height, string color) 
        : base("Rectangle", color)
    {
        Width = width;
        Height = height;
    }
    
    // MUST implement — or this class must also be abstract
    public override double Area() => Width * Height;
    public override double Perimeter() => 2 * (Width + Height);
}

class Circle : Shape
{
    public double Radius { get; set; }
    
    public Circle(double radius, string color) : base("Circle", color)
    {
        Radius = radius;
    }
    
    public override double Area() => Math.PI * Radius * Radius;
    public override double Perimeter() => 2 * Math.PI * Radius;
}

// Now use polymorphism:
Shape[] shapes = { new Rectangle(10, 5, "Red"), new Circle(7, "Blue") };
foreach (Shape shape in shapes)
{
    shape.Display();    // Display() calls Area() and Perimeter() — polymorphism!
}
```

### Abstract vs Regular Class:

```
Regular Class:                    Abstract Class:
─────────────                    ─────────────
✅ Can instantiate               ❌ Cannot instantiate  
✅ All methods have body         ✅ Can have abstract methods (no body)
✅ Can be base class             ✅ Designed to be a base class
                                 ✅ Can have regular methods too
                                 ✅ Can have constructors, fields, properties
```

---

## 3. What is an Interface?

An interface is a **contract** — it defines **what** a class must do, but not **how**. Think of it as a job requirement checklist.

```
Interface analogy:
─────────────────
Job Requirement: "Must know how to code, test, and deploy"
  → The requirement doesn't specify HOW you do these things
  → Different people implement them differently
  → But everyone who meets the requirement CAN do all three
```

```csharp
// Interface — just defines the contract
interface ITaskService
{
    // Method signatures only (no body by default)
    void AddTask(string title);
    void DeleteTask(int id);
    List<string> GetAllTasks();
    int TaskCount { get; }    // Property signature
}

// A class "implements" the interface — provides the actual code
class InMemoryTaskService : ITaskService
{
    private List<string> _tasks = new();
    
    // MUST implement ALL interface members
    public void AddTask(string title) => _tasks.Add(title);
    public void DeleteTask(int id) => _tasks.RemoveAt(id);
    public List<string> GetAllTasks() => _tasks;
    public int TaskCount => _tasks.Count;
}
```

### Interface Naming Convention:

```csharp
// Interfaces start with 'I' by convention in C#
interface INotificationService { }    // ✅ Good
interface ILogger { }                  // ✅ Good
interface NotificationService { }      // ❌ Bad (looks like a class)
```

---

## 4. Interface Syntax & Rules

```csharp
interface IShape
{
    // Method signatures
    double Area();
    double Perimeter();
    
    // Properties (no backing field — just the signature)
    string Name { get; }
    string Color { get; set; }
    
    // Default implementation (C# 8+)
    void Display()
    {
        Console.WriteLine($"{Name}: Area = {Area():F2}");
    }
}
```

### Interface Rules:
- **Cannot** have fields (no `int x;`)
- **Cannot** have constructors
- **Can** have methods, properties, events, indexers
- **Can** have default implementations (C# 8+)
- Members are **public** by default (no access modifiers needed before C# 8)
- A class can implement **multiple interfaces**
- An interface can **extend** other interfaces

---

## 5. Multiple Interface Implementation

This is where interfaces really shine — a class can implement **multiple interfaces** (unlike inheritance where only one base class is allowed):

```csharp
interface IPrintable
{
    void Print();
}

interface ISaveable
{
    void SaveToFile(string path);
}

interface IExportable
{
    string ExportAsJson();
    string ExportAsCsv();
}

// A class implements ALL three interfaces
class TaskReport : IPrintable, ISaveable, IExportable
{
    public string Title { get; set; }
    public string Content { get; set; }
    
    public TaskReport(string title, string content)
    {
        Title = title;
        Content = content;
    }
    
    // IPrintable
    public void Print()
    {
        Console.WriteLine($"=== {Title} ===");
        Console.WriteLine(Content);
    }
    
    // ISaveable
    public void SaveToFile(string path)
    {
        Console.WriteLine($"Saving to {path}...");
        // File.WriteAllText(path, Content);
    }
    
    // IExportable
    public string ExportAsJson()
    {
        return $"{{ \"title\": \"{Title}\", \"content\": \"{Content}\" }}";
    }
    
    public string ExportAsCsv()
    {
        return $"\"{Title}\",\"{Content}\"";
    }
}
```

### Using Interface References (Polymorphism):

```csharp
TaskReport report = new TaskReport("Sprint Report", "All tasks completed!");

// Use as IPrintable
IPrintable printable = report;
printable.Print();

// Use as IExportable
IExportable exportable = report;
string json = exportable.ExportAsJson();

// Check if an object implements an interface
if (report is ISaveable saveable)
{
    saveable.SaveToFile("report.txt");
}

// Multiple different objects can implement the same interface
IPrintable[] printables = new IPrintable[]
{
    new TaskReport("Report 1", "Content 1"),
    new Invoice("INV-001", 5000m),       // Invoice also implements IPrintable
    new EmailDraft("Subject", "Body"),    // EmailDraft also implements IPrintable
};

foreach (IPrintable item in printables)
{
    item.Print();    // Each prints differently — polymorphism!
}
```

---

## 6. Interface Inheritance (Extending Interfaces)

Interfaces can extend other interfaces:

```csharp
interface IReadable
{
    string Read();
}

interface IWritable
{
    void Write(string data);
}

// IFileHandler extends both — any class implementing it must provide ALL methods
interface IFileHandler : IReadable, IWritable
{
    void Delete();
    long GetSize();
}

class TextFileHandler : IFileHandler
{
    private string _path;
    
    public TextFileHandler(string path) => _path = path;
    
    public string Read() => $"Reading from {_path}";
    public void Write(string data) => Console.WriteLine($"Writing to {_path}: {data}");
    public void Delete() => Console.WriteLine($"Deleting {_path}");
    public long GetSize() => 1024;
}
```

---

## 7. Default Interface Methods (C# 8+)

Interfaces can provide a **default implementation** — classes can use it or override it:

```csharp
interface ILogger
{
    void Log(string message);
    
    // Default implementation — classes don't HAVE to implement this
    void LogError(string message)
    {
        Log($"[ERROR] {message}");
    }
    
    void LogWarning(string message)
    {
        Log($"[WARNING] {message}");
    }
    
    void LogInfo(string message)
    {
        Log($"[INFO] {message}");
    }
}

class ConsoleLogger : ILogger
{
    // Only MUST implement Log() — the default methods work automatically
    public void Log(string message)
    {
        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] {message}");
    }
}

ILogger logger = new ConsoleLogger();
logger.Log("Hello");           // Direct implementation
logger.LogError("Something failed");   // Uses default: calls Log("[ERROR] Something failed")
logger.LogInfo("Started");             // Uses default: calls Log("[INFO] Started")
```

---

## 8. Abstract Class vs Interface — When to Use Which?

```
┌─────────────────────────┬──────────────────────┬──────────────────────┐
│ Feature                 │ Abstract Class        │ Interface            │
├─────────────────────────┼──────────────────────┼──────────────────────┤
│ Inheritance             │ Single only           │ Multiple allowed     │
│ Fields                  │ ✅ Yes                │ ❌ No                │
│ Constructors            │ ✅ Yes                │ ❌ No                │
│ Method bodies           │ ✅ Yes (regular)      │ ✅ Yes (C# 8+ default)│
│ Abstract methods        │ ✅ Yes                │ ✅ Yes (implicit)    │
│ Access modifiers        │ ✅ Any                │ Public (mostly)      │
│ State (data)            │ ✅ Can hold state     │ ❌ Stateless         │
│ "is-a" relationship     │ ✅ Dog IS-A Animal    │ ❌                   │
│ "can-do" relationship   │ ❌                    │ ✅ Dog CAN Swim      │
│ Instantiate             │ ❌ No                 │ ❌ No                │
└─────────────────────────┴──────────────────────┴──────────────────────┘
```

### When to Use What:

```csharp
// ABSTRACT CLASS — when classes share common STATE and BEHAVIOR
// "What something IS"
abstract class Animal           // Dog IS-A Animal
{
    public string Name { get; set; }     // Shared state
    public int Age { get; set; }         // Shared state
    
    public void Sleep()                  // Shared behavior
    {
        Console.WriteLine($"{Name} is sleeping...");
    }
    
    public abstract void MakeSound();    // Each animal sounds different
}

// INTERFACE — when unrelated classes share a CAPABILITY
// "What something CAN DO"
interface ISwimmable           // Dog CAN swim, Fish CAN swim, Robot CAN swim
{
    void Swim();
}

interface ITrainable           // Dog CAN be trained, Parrot CAN be trained
{
    void Learn(string trick);
}

// A class can use BOTH:
class Dog : Animal, ISwimmable, ITrainable
{
    public override void MakeSound() => Console.WriteLine("Woof!");
    public void Swim() => Console.WriteLine($"{Name} is swimming!");
    public void Learn(string trick) => Console.WriteLine($"{Name} learned {trick}!");
}
```

---

## 9. Common .NET Interfaces You'll Use

### IComparable — Sorting:

```csharp
class TaskItem : IComparable<TaskItem>
{
    public string Title { get; set; }
    public int Priority { get; set; }   // 1 = High, 2 = Medium, 3 = Low
    
    // Required by IComparable — enables sorting
    public int CompareTo(TaskItem? other)
    {
        if (other == null) return 1;
        return this.Priority.CompareTo(other.Priority);
    }
}

TaskItem[] tasks = {
    new TaskItem { Title = "Low task", Priority = 3 },
    new TaskItem { Title = "High task", Priority = 1 },
    new TaskItem { Title = "Medium task", Priority = 2 },
};

Array.Sort(tasks);   // Uses CompareTo() — sorts by priority!
foreach (var t in tasks)
    Console.WriteLine($"{t.Priority}: {t.Title}");
// 1: High task
// 2: Medium task
// 3: Low task
```

### IEquatable — Equality:

```csharp
class TaskItem : IEquatable<TaskItem>
{
    public int Id { get; set; }
    public string Title { get; set; }
    
    public bool Equals(TaskItem? other)
    {
        if (other == null) return false;
        return this.Id == other.Id;
    }
    
    public override bool Equals(object? obj) => Equals(obj as TaskItem);
    public override int GetHashCode() => Id.GetHashCode();
}

var task1 = new TaskItem { Id = 1, Title = "Fix bug" };
var task2 = new TaskItem { Id = 1, Title = "Fix bug" };
Console.WriteLine(task1.Equals(task2));   // True (same Id)
```

### IDisposable — Resource Cleanup:

```csharp
class DatabaseConnection : IDisposable
{
    private bool _disposed = false;
    
    public void Open()
    {
        Console.WriteLine("Connection opened");
    }
    
    public void Dispose()
    {
        if (!_disposed)
        {
            Console.WriteLine("Connection closed & resources freed");
            _disposed = true;
        }
    }
}

// 'using' statement automatically calls Dispose()
using (var conn = new DatabaseConnection())
{
    conn.Open();
    // ... use connection ...
}   // Dispose() called automatically here!

// Or C# 8+ using declaration:
using var conn2 = new DatabaseConnection();
conn2.Open();
// Dispose() called at end of scope
```

### IEnumerable — Iteration:

```csharp
class TaskList : IEnumerable<string>
{
    private string[] _tasks = { "Code", "Test", "Deploy" };
    
    public IEnumerator<string> GetEnumerator()
    {
        foreach (string task in _tasks)
            yield return task;
    }
    
    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() 
        => GetEnumerator();
}

// Now you can use foreach!
var list = new TaskList();
foreach (string task in list)
{
    Console.WriteLine(task);
}
```

---

## 10. Explicit Interface Implementation

When two interfaces have methods with the **same name**:

```csharp
interface IFileLogger
{
    void Log(string message);  // Log to file
}

interface IConsoleLogger
{
    void Log(string message);  // Log to console
}

class DualLogger : IFileLogger, IConsoleLogger
{
    // Explicit implementations — must use interface reference to call
    void IFileLogger.Log(string message)
    {
        Console.WriteLine($"[FILE] {message}");
    }
    
    void IConsoleLogger.Log(string message)
    {
        Console.WriteLine($"[CONSOLE] {message}");
    }
}

DualLogger logger = new DualLogger();
// logger.Log("test");          // ❌ Ambiguous — compile error!

IFileLogger fileLogger = logger;
fileLogger.Log("test");          // ✅ "[FILE] test"

IConsoleLogger consoleLogger = logger;
consoleLogger.Log("test");      // ✅ "[CONSOLE] test"
```

---

## 11. Putting It All Together — Practical Example

### TaskFlow Notification + Export System:

```csharp
// ======= INTERFACES =======
interface INotificationSender
{
    void Send(string recipient, string message);
    string ChannelName { get; }
}

interface IExportable
{
    string ExportAsText();
    string ExportAsJson();
}

// ======= ABSTRACT BASE =======
abstract class TaskBase : IExportable
{
    public int Id { get; }
    public string Title { get; set; }
    public abstract string TaskType { get; }
    
    private static int _nextId = 1;
    
    protected TaskBase(string title)
    {
        Id = _nextId++;
        Title = title;
    }
    
    public abstract double GetEstimatedHours();
    
    // IExportable — shared implementation
    public string ExportAsText() => $"{Id},{TaskType},{Title},{GetEstimatedHours()}";
    public string ExportAsJson() => $"{{\"id\":{Id},\"type\":\"{TaskType}\",\"title\":\"{Title}\",\"hours\":{GetEstimatedHours()}}}";
    
    public override string ToString() => $"[{TaskType}] #{Id}: {Title} ({GetEstimatedHours()}h)";
}

// ======= CONCRETE CLASSES =======
class BugTask : TaskBase
{
    public string Severity { get; set; }
    public override string TaskType => "Bug";
    
    public BugTask(string title, string severity) : base(title)
    {
        Severity = severity;
    }
    
    public override double GetEstimatedHours() => Severity switch
    {
        "Critical" => 16,
        "Major" => 8,
        "Minor" => 2,
        _ => 4
    };
}

class FeatureTask : TaskBase
{
    public int StoryPoints { get; set; }
    public override string TaskType => "Feature";
    
    public FeatureTask(string title, int storyPoints) : base(title)
    {
        StoryPoints = storyPoints;
    }
    
    public override double GetEstimatedHours() => StoryPoints * 4;
}

// ======= NOTIFICATION SENDERS (Interface implementations) =======
class EmailSender : INotificationSender
{
    public string ChannelName => "Email";
    
    public void Send(string recipient, string message)
    {
        Console.WriteLine($"📧 Email to {recipient}: {message}");
    }
}

class SlackSender : INotificationSender
{
    public string ChannelName => "Slack";
    
    public void Send(string recipient, string message)
    {
        Console.WriteLine($"💬 Slack to #{recipient}: {message}");
    }
}

// ======= MAIN PROGRAM =======
Console.WriteLine("╔════════════════════════════════════════╗");
Console.WriteLine("║   TASKFLOW - ABSTRACTION DEMO           ║");
Console.WriteLine("╚════════════════════════════════════════╝");

// Tasks array — polymorphism with abstract class
TaskBase[] tasks = {
    new BugTask("Login crash", "Critical"),
    new FeatureTask("User dashboard", 5),
    new BugTask("CSS alignment", "Minor"),
    new FeatureTask("Search feature", 3),
};

Console.WriteLine("\n📋 TASKS:");
double totalHours = 0;
foreach (TaskBase task in tasks)
{
    Console.WriteLine($"  {task}");    // Uses ToString() override
    totalHours += task.GetEstimatedHours();
}
Console.WriteLine($"\n⏱️ Total estimated: {totalHours}h");

// Export — using IExportable interface
Console.WriteLine("\n📤 EXPORT (JSON):");
foreach (IExportable exportable in tasks)   // TaskBase implements IExportable
{
    Console.WriteLine($"  {exportable.ExportAsJson()}");
}

// Notifications — using INotificationSender interface
INotificationSender[] channels = { new EmailSender(), new SlackSender() };
Console.WriteLine("\n🔔 SENDING NOTIFICATIONS:");
foreach (INotificationSender sender in channels)
{
    sender.Send("team", $"Sprint has {tasks.Length} tasks ({totalHours}h)");
}
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Abstraction** | Hide complexity, show only what's needed |
| **Abstract class** | Can't instantiate, can have abstract + regular members |
| **Abstract method** | No body — derived classes MUST implement |
| **Interface** | Contract — defines what a class must do |
| **`I` prefix** | Convention: `ILogger`, `IService`, `IExportable` |
| **Multiple interfaces** | A class can implement many interfaces |
| **Interface inheritance** | Interfaces can extend other interfaces |
| **Default methods** | C# 8+ — interfaces can have default implementations |
| **Abstract class** | Use for "is-a" + shared state/behavior |
| **Interface** | Use for "can-do" capabilities across unrelated types |
| **IComparable** | Enable sorting |
| **IEquatable** | Custom equality |
| **IDisposable** | Resource cleanup with `using` |
| **IEnumerable** | Enable `foreach` iteration |
| **Explicit implementation** | Resolve same-name conflicts between interfaces |

---

## Real-World Use Cases

1. **Dependency Injection** — Services are coded against interfaces: `ITaskService`, `IEmailService`. The actual implementation can be swapped (in-memory for testing, database for production) without changing calling code.
2. **Repository Pattern** — `IRepository<T>` defines CRUD operations. `SqlRepository`, `MongoRepository`, `InMemoryRepository` all implement it differently.
3. **Plugin Architecture** — Define an `IPlugin` interface. Any developer can create a class implementing it, and your app loads it dynamically.
4. **Testing** — Mock interfaces for unit tests: `IPaymentGateway` → use `FakePaymentGateway` in tests.
5. **SOLID Principles** — Interface Segregation Principle (ISP): many small interfaces > one fat interface.
6. **TaskFlow Project** — `ITaskRepository` (data access), `INotificationService` (sending alerts), `IExportService` (CSV/JSON export).

---
