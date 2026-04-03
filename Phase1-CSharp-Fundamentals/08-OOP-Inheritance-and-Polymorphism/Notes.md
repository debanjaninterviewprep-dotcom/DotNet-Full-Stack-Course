# Phase 1 | Topic 8: OOP — Inheritance & Polymorphism

---

## 1. What is Inheritance?

Inheritance lets a class **reuse** the data and behavior of another class, and then **extend or customize** it. It models the **"is-a"** relationship.

```
Real-world analogy:
─────────────────
Animal (has: Name, Age, Eat(), Sleep())
  ├── Dog (inherits all from Animal + Bark(), Fetch())
  ├── Cat (inherits all from Animal + Purr(), Scratch())
  └── Bird (inherits all from Animal + Fly(), Sing())

Dog IS-A Animal. Cat IS-A Animal. Bird IS-A Animal.
Each inherits common features and adds its own.
```

### Without Inheritance (Bad — Code Duplication):

```csharp
class FullTimeEmployee
{
    public string Name { get; set; }
    public string Email { get; set; }
    public decimal Salary { get; set; }    // Repeated everywhere!
    
    public void Display() { /*...*/ }       // Repeated everywhere!
    public decimal CalculateBonus() => Salary * 0.15m;
}

class Contractor
{
    public string Name { get; set; }        // Same as above 😱
    public string Email { get; set; }       // Same as above 😱
    public decimal HourlyRate { get; set; }
    
    public void Display() { /*...*/ }       // Same as above 😱
    public decimal CalculatePay(int hours) => HourlyRate * hours;
}
```

### With Inheritance (Good — Reuse):

```csharp
// BASE CLASS (Parent)
class Employee
{
    public string Name { get; set; }
    public string Email { get; set; }
    
    public void Display()
    {
        Console.WriteLine($"{Name} ({Email})");
    }
}

// DERIVED CLASS (Child) — inherits from Employee
class FullTimeEmployee : Employee    // ← Colon means "inherits from"
{
    public decimal Salary { get; set; }
    
    public decimal CalculateBonus() => Salary * 0.15m;
}

class Contractor : Employee          // Also inherits from Employee
{
    public decimal HourlyRate { get; set; }
    
    public decimal CalculatePay(int hours) => HourlyRate * hours;
}

// Usage:
FullTimeEmployee emp = new FullTimeEmployee();
emp.Name = "Debanjan";      // ✅ Inherited from Employee
emp.Email = "d@test.com";   // ✅ Inherited from Employee
emp.Salary = 75000m;        // Own property
emp.Display();               // ✅ Inherited method
```

---

## 2. Inheritance Syntax & Terminology

```csharp
class BaseClass          // Also called: Parent, Super class
{
    // Base members
}

class DerivedClass : BaseClass    // Also called: Child, Sub class
{
    // Inherited members + new members
}
```

### Inheritance Hierarchy:

```
         Employee (Base)
         ┌────┴────┐
   FullTime      Contractor
         │
     Manager (can inherit from FullTime)
```

```csharp
class Employee { }
class FullTimeEmployee : Employee { }
class Manager : FullTimeEmployee { }    // Manager inherits from FullTime, which inherits from Employee
// Manager has ALL members from both FullTimeEmployee AND Employee
```

### Inheritance Rules in C#:
- A class can inherit from **only ONE** base class (single inheritance)
- A class can implement **multiple interfaces** (covered in Topic 9)
- All classes implicitly inherit from `System.Object`
- `sealed` classes cannot be inherited from
- Constructors are **NOT inherited** (but can be called)

---

## 3. Constructor Inheritance & `base` Keyword

Constructors are **not inherited**, but the derived class can **call** the base constructor using `base`:

```csharp
class Employee
{
    public string Name { get; set; }
    public string Email { get; set; }
    
    public Employee(string name, string email)
    {
        Name = name;
        Email = email;
        Console.WriteLine("Employee constructor called");
    }
}

class FullTimeEmployee : Employee
{
    public decimal Salary { get; set; }
    
    // MUST call base constructor since Employee has no parameterless constructor
    public FullTimeEmployee(string name, string email, decimal salary) 
        : base(name, email)    // ← Calls Employee's constructor
    {
        Salary = salary;
        Console.WriteLine("FullTimeEmployee constructor called");
    }
}

var emp = new FullTimeEmployee("Debanjan", "d@test.com", 75000m);
// Output:
// Employee constructor called
// FullTimeEmployee constructor called
```

### Constructor Call Order:

```
new FullTimeEmployee("Debanjan", "d@test.com", 75000m)
  │
  ├─→ base(name, email)    → Employee constructor runs FIRST
  │     • Name = "Debanjan"
  │     • Email = "d@test.com"
  │
  └─→ FullTimeEmployee constructor runs SECOND
        • Salary = 75000m
```

> **Rule:** Base class constructor ALWAYS runs before the derived class constructor.

---

## 4. Method Overriding (`virtual` + `override`)

The derived class can **replace** a base class method with its own version:

```csharp
class Employee
{
    public string Name { get; set; }
    public decimal BaseSalary { get; set; }
    
    // 'virtual' means: derived classes CAN override this
    public virtual decimal CalculatePay()
    {
        return BaseSalary;
    }
    
    public virtual string GetRole()
    {
        return "Employee";
    }
}

class FullTimeEmployee : Employee
{
    public decimal Bonus { get; set; }
    
    // 'override' replaces the base version
    public override decimal CalculatePay()
    {
        return BaseSalary + Bonus;    // Custom calculation
    }
    
    public override string GetRole()
    {
        return "Full-Time Employee";
    }
}

class Contractor : Employee
{
    public int HoursWorked { get; set; }
    public decimal HourlyRate { get; set; }
    
    public override decimal CalculatePay()
    {
        return HourlyRate * HoursWorked;    // Completely different calculation
    }
    
    public override string GetRole()
    {
        return "Contractor";
    }
}
```

### Using `base` to Call the Original Method:

```csharp
class Manager : FullTimeEmployee
{
    public decimal LeadershipBonus { get; set; }
    
    public override decimal CalculatePay()
    {
        // Call the parent's version FIRST, then add more
        decimal basePay = base.CalculatePay();   // Calls FullTimeEmployee.CalculatePay()
        return basePay + LeadershipBonus;
    }
}
```

### Keywords Summary:

```
virtual   → "This method CAN be overridden by derived classes"
override  → "I'm replacing the base class version of this method"
base      → "Call the parent class's version"
```

---

## 5. What is Polymorphism?

Polymorphism means **"many forms"** — the same method call behaves differently depending on the **actual type** of the object.

```csharp
// All these are Employee references, but point to different types
Employee emp1 = new FullTimeEmployee("Debanjan", "d@test.com", 75000m) { Bonus = 10000m };
Employee emp2 = new Contractor("Rahul", "r@test.com", 0) { HourlyRate = 500m, HoursWorked = 160 };
Employee emp3 = new Employee("Priya", "p@test.com") { BaseSalary = 50000m };

// Same method call — DIFFERENT behavior!
Console.WriteLine($"{emp1.Name}: ₹{emp1.CalculatePay()}");  // 85000 (salary + bonus)
Console.WriteLine($"{emp2.Name}: ₹{emp2.CalculatePay()}");  // 80000 (hourly * hours)
Console.WriteLine($"{emp3.Name}: ₹{emp3.CalculatePay()}");  // 50000 (base salary)
```

### Polymorphism in Action — Array of Base Type:

```csharp
// Store different types in the same array!
Employee[] team = new Employee[]
{
    new FullTimeEmployee("Debanjan", "d@test.com", 75000m) { Bonus = 10000m },
    new Contractor("Rahul", "r@test.com", 0) { HourlyRate = 500m, HoursWorked = 160 },
    new FullTimeEmployee("Priya", "p@test.com", 60000m) { Bonus = 8000m },
};

// Process ALL employees with ONE loop — polymorphism handles the rest!
Console.WriteLine("=== PAYROLL ===");
decimal totalPayroll = 0;

foreach (Employee emp in team)
{
    decimal pay = emp.CalculatePay();   // Calls the RIGHT version based on actual type
    totalPayroll += pay;
    Console.WriteLine($"{emp.GetRole(),-20} {emp.Name,-15} ₹{pay,10:N2}");
}

Console.WriteLine($"\nTotal Payroll: ₹{totalPayroll:N2}");
```

```
Output:
=== PAYROLL ===
Full-Time Employee   Debanjan        ₹ 85,000.00
Contractor           Rahul           ₹ 80,000.00
Full-Time Employee   Priya           ₹ 68,000.00

Total Payroll: ₹2,33,000.00
```

### Why is This Powerful?

```
WITHOUT polymorphism:                WITH polymorphism:
──────────────────────              ──────────────────────
if (emp is FullTime)                foreach (Employee emp in team)
    pay = emp.Salary + emp.Bonus;   {
else if (emp is Contractor)             decimal pay = emp.CalculatePay();
    pay = emp.Rate * emp.Hours;         // That's it! One line!
else if (emp is Intern)             }
    pay = emp.Stipend;
// Grows forever as types increase  // Automatically works for new types
```

---

## 6. Method Hiding (`new` keyword)

If you want to define a method with the **same name** in a derived class WITHOUT overriding:

```csharp
class Animal
{
    public void Speak()    // NOT virtual
    {
        Console.WriteLine("Some generic sound");
    }
}

class Dog : Animal
{
    public new void Speak()    // 'new' hides the base method
    {
        Console.WriteLine("Woof! Woof!");
    }
}

Dog dog = new Dog();
dog.Speak();            // "Woof! Woof!" — Dog's version

Animal animal = dog;    // Reference type is Animal
animal.Speak();         // "Some generic sound" — Base version! ⚠️
```

### `new` (Hiding) vs `override`:

```csharp
class Base
{
    public virtual void Method1() => Console.WriteLine("Base.Method1");
    public void Method2() => Console.WriteLine("Base.Method2");
}

class Derived : Base
{
    public override void Method1() => Console.WriteLine("Derived.Method1");
    public new void Method2() => Console.WriteLine("Derived.Method2");
}

Base obj = new Derived();
obj.Method1();    // "Derived.Method1" — override: actual type wins ✅
obj.Method2();    // "Base.Method2"    — new/hide: reference type wins ⚠️
```

> **Rule:** Prefer `virtual` + `override` over `new`. Method hiding is rarely needed and can cause confusion.

---

## 7. `sealed` Keyword — Prevent Inheritance

```csharp
// sealed class — cannot be inherited
sealed class FinalReport
{
    public void Generate() { /* ... */ }
}

// ❌ Compile error — cannot inherit from sealed class
// class ExtendedReport : FinalReport { }

// sealed method — prevent further overriding
class Employee
{
    public virtual void Display() => Console.WriteLine("Employee");
}

class Manager : Employee
{
    public sealed override void Display() => Console.WriteLine("Manager");
    // sealed + override = "I override it, but NO ONE can override it further"
}

class Director : Manager
{
    // ❌ Compile error — Display() is sealed in Manager
    // public override void Display() => Console.WriteLine("Director");
}
```

---

## 8. Type Checking & Casting (`is`, `as`, Pattern Matching)

When working with polymorphism, you sometimes need to check or convert types:

```csharp
Employee emp = new FullTimeEmployee("Debanjan", "d@test.com", 75000m);

// 'is' — check type (returns bool)
if (emp is FullTimeEmployee)
{
    Console.WriteLine("It's a full-time employee!");
}

// 'is' with pattern matching (C# 7+) — check AND cast in one step
if (emp is FullTimeEmployee fte)
{
    Console.WriteLine($"Salary: {fte.Salary}");    // Access FullTimeEmployee-specific property
}

// 'as' — try to cast, return null if fails
FullTimeEmployee? fte2 = emp as FullTimeEmployee;
if (fte2 != null)
{
    Console.WriteLine($"Bonus: {fte2.Bonus}");
}

// Direct cast — throws InvalidCastException if wrong
FullTimeEmployee fte3 = (FullTimeEmployee)emp;     // ✅ Works because emp IS a FullTimeEmployee

// ❌ This would crash:
// Contractor c = (Contractor)emp;     // InvalidCastException!

// Switch with pattern matching (C# 7+)
string description = emp switch
{
    Manager m => $"Manager: {m.Name}",
    FullTimeEmployee f => $"Full-Time: {f.Name}, Salary: {f.Salary}",
    Contractor c => $"Contractor: {c.Name}, Rate: {c.HourlyRate}",
    _ => $"Employee: {emp.Name}"
};
```

---

## 9. The `object` Class — The Ultimate Base

Every class in C# inherits from `System.Object`. This means every object has these methods:

```csharp
class TaskItem
{
    public int Id { get; set; }
    public string Title { get; set; }
    
    // Override ToString() — controls how the object displays as string
    public override string ToString()
    {
        return $"Task #{Id}: {Title}";
    }
    
    // Override Equals() — controls equality comparison
    public override bool Equals(object? obj)
    {
        if (obj is TaskItem other)
        {
            return this.Id == other.Id;
        }
        return false;
    }
    
    // Override GetHashCode() — required when overriding Equals
    public override int GetHashCode()
    {
        return Id.GetHashCode();
    }
}

TaskItem task = new TaskItem { Id = 1, Title = "Fix bug" };
Console.WriteLine(task);                // "Task #1: Fix bug" (calls ToString())
Console.WriteLine(task.ToString());     // Same

TaskItem task2 = new TaskItem { Id = 1, Title = "Fix bug" };
Console.WriteLine(task.Equals(task2));  // True (same Id)
```

---

## 10. Putting It All Together — Practical Example

### TaskFlow Notification System:

```csharp
// ======= MAIN PROGRAM =======
Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║   TASKFLOW - NOTIFICATION SYSTEM       ║");
Console.WriteLine("╚═══════════════════════════════════════╝");

// Create different notification types
Notification[] notifications = new Notification[]
{
    new EmailNotification("Debanjan", "Task assigned to you", "debanjan@email.com"),
    new SmsNotification("Rahul", "Deadline tomorrow!", "+91-9876543210"),
    new PushNotification("Priya", "New comment on your task", "mobile-device-123"),
    new EmailNotification("Amit", "Weekly report ready", "amit@email.com"),
};

// Polymorphism — send all notifications with one loop!
foreach (Notification notif in notifications)
{
    notif.Send();    // Each type sends differently
}

// Statistics
Console.WriteLine($"\n📊 Total notifications sent: {Notification.TotalSent}");
Console.WriteLine($"📊 Email: {EmailNotification.EmailCount}");


// ======= CLASS DEFINITIONS =======

// BASE CLASS
class Notification
{
    public string Recipient { get; set; }
    public string Message { get; set; }
    public DateTime CreatedAt { get; }
    public static int TotalSent { get; private set; }
    
    public Notification(string recipient, string message)
    {
        Recipient = recipient;
        Message = message;
        CreatedAt = DateTime.Now;
    }
    
    // Virtual — can be overridden
    public virtual void Send()
    {
        Console.WriteLine($"📨 Sending to {Recipient}: {Message}");
        TotalSent++;
    }
    
    public override string ToString()
    {
        return $"[{CreatedAt:HH:mm}] To: {Recipient} — {Message}";
    }
}

// DERIVED: Email
class EmailNotification : Notification
{
    public string EmailAddress { get; set; }
    public static int EmailCount { get; private set; }
    
    public EmailNotification(string recipient, string message, string email) 
        : base(recipient, message)
    {
        EmailAddress = email;
    }
    
    public override void Send()
    {
        Console.WriteLine($"📧 Email to {EmailAddress}: {Message}");
        EmailCount++;
        // Still count total via base
        Notification.TotalSent++;    // Can't call base.Send() or it would print twice
    }
}

// DERIVED: SMS
class SmsNotification : Notification
{
    public string PhoneNumber { get; set; }
    
    public SmsNotification(string recipient, string message, string phone) 
        : base(recipient, message)
    {
        PhoneNumber = phone;
    }
    
    public override void Send()
    {
        Console.WriteLine($"📱 SMS to {PhoneNumber}: {Message}");
        Notification.TotalSent++;
    }
}

// DERIVED: Push
class PushNotification : Notification
{
    public string DeviceId { get; set; }
    
    public PushNotification(string recipient, string message, string deviceId) 
        : base(recipient, message)
    {
        DeviceId = deviceId;
    }
    
    public override void Send()
    {
        Console.WriteLine($"🔔 Push to device {DeviceId}: {Message}");
        Notification.TotalSent++;
    }
}
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Inheritance** | Derived class reuses base class members using `: BaseClass` |
| **is-a relationship** | Dog IS-A Animal, Manager IS-A Employee |
| **`base`** | Call base class constructor or methods |
| **Constructor order** | Base constructor runs FIRST, then derived |
| **`virtual`** | Marks a method as overridable |
| **`override`** | Replaces the base method in derived class |
| **Polymorphism** | Same method call, different behavior based on actual type |
| **Method hiding `new`** | Hides base method (reference type wins) — avoid |
| **`sealed`** | Prevents further inheritance or overriding |
| **`is`** | Type check — `if (obj is Type t)` |
| **`as`** | Safe cast — returns null if fails |
| **Pattern matching** | `switch` with type patterns |
| **`ToString()`** | Override to customize string representation |
| **`Equals()`** | Override to customize equality comparison |
| **Single inheritance** | C# allows only one base class (multiple interfaces OK) |

---

## Real-World Use Cases

1. **API Controllers** — `ControllerBase` → `ApiController` → `TaskController`. Each level adds more functionality.
2. **Logging** — Base `Logger` class, derived `FileLogger`, `DatabaseLogger`, `ConsoleLogger` — polymorphism picks the right one.
3. **Payment Processing** — Base `PaymentMethod`, derived `CreditCard`, `PayPal`, `BankTransfer`. One `ProcessPayment()` method, different implementations.
4. **UI Frameworks** — `Control` → `TextBox`, `Button`, `Label`. All share common properties (position, size) but render differently.
5. **Exception Handling** — `Exception` → `IOException` → `FileNotFoundException`. Catch specific or general types.
6. **TaskFlow Project** — Base `Notification` with `EmailNotification`, `SmsNotification`. Base `User` with `Admin`, `Developer`, `Manager`.

---
