# Phase 1 | Topic 7: Practice Problems — Classes & Objects

---

## Problem 1: Bank Account Class (Easy)
**Difficulty:** ⭐ Easy

Create a `BankAccount` class with:
- Properties: `AccountNumber` (read-only), `HolderName`, `Balance` (private set)
- Constructor that takes account number, holder name, and initial balance
- Methods: `Deposit(decimal amount)`, `Withdraw(decimal amount)`, `Display()`
- Withdrawal should fail if insufficient balance

**Expected Output:**
```
=== BANK ACCOUNT DEMO ===

Account: ACC-001 | Debanjan | Balance: ₹10,000.00

Depositing ₹5,000...
✅ Deposited ₹5,000.00. New balance: ₹15,000.00

Withdrawing ₹3,000...
✅ Withdrew ₹3,000.00. New balance: ₹12,000.00

Withdrawing ₹20,000...
❌ Insufficient balance! Available: ₹12,000.00
```

**Requirements:**
- Use auto-properties with appropriate access
- Use `decimal` for money
- Validate: no negative deposits/withdrawals

---

## Problem 2: Student Grade Book (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Create a `Student` class with:
- Properties: `Id` (auto-increment, read-only), `Name`, `Scores` (int array)
- A **static** counter for auto-incrementing IDs
- Methods:
  - `AddScore(int score)` — add a score (max 5 subjects)
  - `GetAverage()` — returns average as double
  - `GetGrade()` — returns letter grade based on average
  - `GetHighest()` / `GetLowest()` — return highest & lowest score
  - `Display()` — formatted report card

Create 3 students with different scores and display all report cards.

**Expected Output:**
```
╔══════════════════════════════════╗
║         REPORT CARD              ║
╠══════════════════════════════════╣
║  ID:       1                     ║
║  Name:     Debanjan              ║
║  Scores:   85, 92, 78, 95, 88   ║
║  Average:  87.60                 ║
║  Grade:    B                     ║
║  Highest:  95                    ║
║  Lowest:   78                    ║
╚══════════════════════════════════╝
```

**Requirements:**
- Use a static field for auto-increment ID
- Use static method `Student.GetTotalStudents()`
- Handle edge case: no scores added

---

## Problem 3: Rectangle & Circle with Static Utility (Medium)
**Difficulty:** ⭐⭐ Medium

Create:
1. A `Rectangle` class with `Width`, `Height`, constructor, `Area()`, `Perimeter()`, `Display()`
2. A `Circle` class with `Radius`, constructor, `Area()`, `Circumference()`, `Display()`
3. A **static class** `ShapeHelper` with:
   - `CompareAreas(double area1, double area2)` — returns which is bigger
   - `IsSquare(Rectangle r)` — checks if width == height

**Expected Output:**
```
Rectangle: 10 x 5
  Area: 50.00
  Perimeter: 30.00
  Is Square: No

Circle: radius 7
  Area: 153.94
  Circumference: 43.98

Comparing: Rectangle area (50.00) vs Circle area (153.94)
→ Circle is bigger by 103.94
```

**Requirements:**
- Use expression-bodied members for simple calculations
- Use appropriate access modifiers
- Format all numbers to 2 decimal places

---

## Problem 4: Constructor Overloading - Employee System (Medium)
**Difficulty:** ⭐⭐ Medium

Create an `Employee` class with:
- Properties: `Id`, `Name`, `Department`, `Salary`, `JoinDate`, `IsActive`
- **4 constructors** demonstrating overloading and chaining:
  1. `Employee(string name)` — defaults for everything else
  2. `Employee(string name, string department)` — default salary
  3. `Employee(string name, string department, decimal salary)` — default join date
  4. `Employee(string name, string department, decimal salary, DateTime joinDate)` — primary
- All constructors should **chain** to the primary constructor using `: this(...)`
- Methods: `Promote(decimal raiseAmount)`, `Deactivate()`, `Display()`
- A **static** method to display all employees created

**Expected Output:**
```
Creating employees with different constructors:

Employee 1 (name only):
  #1 | Debanjan | General | ₹30,000.00 | Joined: Apr 03, 2026 | Active

Employee 2 (name + dept):
  #2 | Rahul | Engineering | ₹30,000.00 | Joined: Apr 03, 2026 | Active

Employee 3 (name + dept + salary):
  #3 | Priya | Design | ₹50,000.00 | Joined: Apr 03, 2026 | Active

Employee 4 (full details):
  #4 | Amit | Management | ₹80,000.00 | Joined: Jan 15, 2025 | Active

Promoting Debanjan by ₹10,000...
  ✅ New salary: ₹40,000.00

Total employees: 4
```

---

## Problem 5: TaskFlow Project Manager (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a complete **TaskFlow Project Manager** using classes:

**Classes to create:**

1. `User` class:
   - Properties: `Id`, `Name`, `Email`, `Role`
   - Auto-increment ID
   - `Display()` method

2. `TaskItem` class:
   - Properties: `Id`, `Title`, `Description`, `Priority`, `IsCompleted`, `CreatedAt`, `CompletedAt?`, `AssignedTo` (User?)
   - Auto-increment ID
   - Methods: `Assign(User user)`, `Complete()`, `Display()`
   - Static: `TotalTasks`, `CompletedTasks`

3. `Project` class:
   - Properties: `Name`, `Tasks` (array of TaskItem, max 20), `TaskCount`
   - Methods: `AddTask(TaskItem task)`, `GetTasksByPriority(string priority)`, `GetCompletionPercentage()`, `DisplayBoard()`
   - `DisplayBoard()` should show tasks in a formatted Kanban-style view

**Expected Output:**
```
╔═══════════════════════════════════════════════════════╗
║              TASKFLOW PROJECT BOARD                    ║
║              Project: Sprint 1                         ║
╠═══════════════════════════════════════════════════════╣

📋 PENDING TASKS:
  #1 [High]   Fix login bug          → Debanjan
  #3 [Medium] Write tests            → Unassigned

✅ COMPLETED TASKS:
  #2 [Low]    Update README           → Rahul  (Completed: Apr 03)

📊 PROGRESS: 1/3 tasks (33.3%)
[███████░░░░░░░░░░░░░] 33%
```

**Requirements:**
- Use proper constructors with chaining
- Use auto-properties and computed properties
- Use static members for counters
- Use null checks for AssignedTo
- Use object initializers somewhere
- Interactive menu: Add Task, View Board, Assign Task, Complete Task, Stats

---

## Instructions

1. Solve each problem in a project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Bank Account Class
- [ ] Problem 2: Student Grade Book
- [ ] Problem 3: Rectangle & Circle with Static Utility
- [ ] Problem 4: Constructor Overloading - Employee System
- [ ] Problem 5: TaskFlow Project Manager
