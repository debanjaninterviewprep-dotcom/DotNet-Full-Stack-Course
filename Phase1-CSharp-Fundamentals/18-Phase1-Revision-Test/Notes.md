# Topic 18: Phase 1 Revision Test

## About This Test

This is a **comprehensive revision test** covering ALL 17 topics from Phase 1: C# Fundamentals. It's designed to test your understanding before moving to Phase 2: Data Structures & Algorithms.

**Rules:**
- Solve ALL problems without looking at previous notes
- Time yourself — target 3-4 hours for the complete test
- Write clean, production-quality code
- Use proper exception handling, naming conventions, and best practices
- After finishing, tell me "check" for a detailed review and score

---

## Section A: Quick-Fire Concepts (10 Questions)

Answer each in 1-3 sentences. Write your answers as comments in your code.

1. What is the difference between **value types** and **reference types**? Give one example of each.
2. What does the `??` operator do? Write a one-line example.
3. What is the difference between `break` and `continue` in a loop?
4. Explain the difference between **method overloading** and **method overriding**.
5. What is **polymorphism**? Give a real-world analogy.
6. Why should you use `throw;` instead of `throw ex;` in a catch block?
7. What is the difference between `List<T>` and `HashSet<T>`? When would you use each?
8. What does `deferred execution` mean in LINQ?
9. What is the difference between `Action<T>` and `Func<T>`?
10. Why should you avoid `async void`?

---

## Section B: Code Output Prediction (5 Questions)

Predict the output of each code snippet WITHOUT running it. Write your predictions as comments.

### B1.
```csharp
int x = 5;
object obj = x;
x = 10;
Console.WriteLine($"x={x}, obj={obj}");
```

### B2.
```csharp
string? name = null;
string result = name?.ToUpper() ?? "UNKNOWN";
Console.WriteLine(result);
```

### B3.
```csharp
List<int> nums = new List<int> { 1, 2, 3, 4, 5 };
var query = nums.Where(n => n > 2);
nums.Add(6);
Console.WriteLine(string.Join(", ", query));
```

### B4.
```csharp
for (int i = 0; i < 5; i++)
{
    if (i == 2) continue;
    if (i == 4) break;
    Console.Write($"{i} ");
}
```

### B5.
```csharp
Action<string> greet = name => Console.Write($"Hi {name}! ");
greet += name => Console.Write($"Hello {name}! ");
greet("Dev");
```

---

## Section C: Bug Fix Challenge (3 Problems)

Each code snippet has 1-3 bugs. Find and fix them.

### C1. Null Reference Bug
```csharp
List<string> names = new List<string> { "Alice", null, "Bob", null, "Charlie" };
foreach (string name in names)
{
    Console.WriteLine(name.ToUpper());
}
```

### C2. Exception Handling Bug
```csharp
StreamReader reader = new StreamReader("data.txt");
try
{
    string content = reader.ReadToEnd();
    Console.WriteLine(content);
}
catch (Exception ex)
{
    throw ex;
}
```

### C3. Async Bug
```csharp
async void LoadData()
{
    string data = await File.ReadAllTextAsync("config.json");
    Console.WriteLine(data);
}

LoadData();
Console.WriteLine("Done!");
```

---

## Section D: Coding Challenges (5 Problems)

### D1. Multi-Feature String Analyzer (Topics 1-6)
**Covers**: Variables, operators, control flow, methods, arrays, strings

Write a method `AnalyzeText(string text)` that returns a `TextReport` with:
- Character count (with and without spaces)
- Word count
- Sentence count (split by `.`, `!`, `?`)
- Most frequent word
- Most frequent character (excluding spaces)
- Longest word
- Reversed text
- Is palindrome (ignoring spaces and case)
- Vowel to consonant ratio
- Title case version of the text

Test with: `"the quick brown fox jumps over the lazy dog"`

**Expected Output:**
```
=== Text Analysis Report ===
Text: "the quick brown fox jumps over the lazy dog"
Characters: 43 (35 without spaces)
Words: 9
Sentences: 0 (no sentence-ending punctuation)
Most Frequent Word: "the" (2 times)
Most Frequent Char: 'o' (4 times)
Longest Word: "jumps" (5 chars)
Reversed: "god yzal eht revo spmuj xof nworb kciuq eht"
Palindrome: No
Vowel:Consonant Ratio: 11:24
Title Case: "The Quick Brown Fox Jumps Over The Lazy Dog"
```

---

### D2. Shape Hierarchy with Full OOP (Topics 7-10)
**Covers**: Classes, inheritance, polymorphism, abstraction, interfaces, encapsulation

Build a complete shape system:

**Interface:** `IDrawable` with `Draw()` method
**Abstract Class:** `Shape` with abstract `Area()`, `Perimeter()`, protected name, static shape counter
**Concrete Classes:**
- `Circle(radius)` — implements IDrawable, draws ASCII circle hint
- `Rectangle(width, height)` — implements IDrawable
- `Triangle(base, height, side1, side2, side3)` — implements IDrawable
- `Square(side)` — inherits from Rectangle

**Requirements:**
- Use encapsulation (private fields, public properties with validation)
- Override `ToString()` to show shape info
- Implement `IComparable<Shape>` to compare by area
- Create a `ShapeCollection` class that stores shapes and provides:
  - `TotalArea()`, `LargestShape()`, `SmallestShape()`
  - `GetByType<T>()` — return all shapes of a specific type
  - Sort shapes by area

**Expected Output:**
```
=== Shape System ===

Created 5 shapes (Shape.Count = 5)

Shapes sorted by area:
  1. Triangle (base:3, h:4) — Area: 6.00
  2. Square (side:4) — Area: 16.00
  3. Circle (r:3) — Area: 28.27
  4. Rectangle (5x8) — Area: 40.00
  5. Circle (r:5) — Area: 78.54

Total Area: 168.81
Largest: Circle (r:5)
Smallest: Triangle (base:3, h:4)

Circles only: 2 found
  Circle (r:3) — Area: 28.27
  Circle (r:5) — Area: 78.54

Drawing Square (side:4):
  ████
  ████
  ████
  ████
```

---

### D3. Exception-Safe Data Processor (Topics 11-12)
**Covers**: Exception handling, custom exceptions, collections

Build a **student enrollment system** with:

**Custom Exceptions:**
- `EnrollmentException` (base) → `CourseFullException`, `PrerequisiteException`, `DuplicateEnrollmentException`

**Classes:**
- `Course` { Id, Name, MaxStudents, Prerequisites (list of course IDs), EnrolledStudents }
- `Student` { Id, Name, CompletedCourses, CurrentEnrollments }
- `EnrollmentService` — handles enrollment logic with proper exceptions

**Logic:**
- Can't enroll if course is full → `CourseFullException`
- Can't enroll if prerequisites not met → `PrerequisiteException`
- Can't enroll in the same course twice → `DuplicateEnrollmentException`
- Process a batch of enrollments, collect ALL errors (don't stop at first)
- Use `Dictionary<string, List<Student>>` for course rosters
- Use `HashSet<int>` for tracking completed courses

Test by enrolling 5 students in various courses with some intentional failures.

---

### D4. Async Report Generator (Topics 13-15)
**Covers**: LINQ, delegates/events, async/await

Build an async report generator that:

1. Simulates fetching data from 3 "databases" concurrently (use Task.Delay):
   - `FetchEmployeesAsync()` — returns 10 employees (1.5s delay)
   - `FetchProjectsAsync()` — returns 5 projects (1s delay)
   - `FetchTimesheetsAsync()` — returns 30 timesheet entries (2s delay)

2. Uses **LINQ** to generate these reports:
   - Employee hours per project (GroupBy + Join)
   - Top 3 employees by total hours
   - Project utilization (actual vs budgeted hours)
   - Employees with overtime (>40 hours/week)

3. Uses **events** to notify when each report section is ready
4. Uses **delegates** for custom formatting (user chooses: table, CSV, or simple)
5. Supports **cancellation** — cancel if total time exceeds 10 seconds
6. Reports **progress** — "Generating report... 25%... 50%... 75%... 100%"

---

### D5. TaskFlow Mini-App (Topics 16-17 + All)
**Covers**: File I/O, serialization, generics + everything

Build a **simplified TaskFlow** console application combining ALL Phase 1 concepts:

**Generic Data Layer:**
- `JsonRepository<T> : IRepository<T>` — generic CRUD with JSON file persistence
- Each entity type saved to its own file: `projects.json`, `tasks.json`, `users.json`

**Entity Hierarchy (OOP):**
- `BaseEntity` (abstract): Id, CreatedAt — implements `IEntity`
- `Project : BaseEntity` — Name, Description, Status
- `TaskItem : BaseEntity` — Title, Description, ProjectId, AssigneeId, Priority, Status, DueDate
- `User : BaseEntity` — Name, Email, Role

**Service Layer:**
- `TaskFlowService` — business logic using generic repositories
  - Create project with tasks
  - Assign tasks to users
  - Complete tasks (validate state transitions)
  - Get project summary (LINQ queries)

**Features Required:**
1. **Menu-driven console UI** with input validation
2. **JSON persistence** — data survives app restart
3. **LINQ queries**: tasks by status, overdue tasks, user workload
4. **Async file operations** — all reads/writes are async
5. **Exception handling** — custom exceptions for business rules
6. **Events** — fire events on task completion, project milestones
7. **Generics** — repository pattern works for all entity types

**Expected Output:**
```
=== TaskFlow Mini-App ===
Loading data... ✓ (3 projects, 8 tasks, 4 users)

1. Projects  2. Tasks  3. Users  4. Reports  5. Save & Exit

> 1
--- Projects ---
  #1 TaskFlow API [Active] — 3/5 tasks done (60%)
  #2 TaskFlow UI [Active] — 1/3 tasks done (33%)
  #3 Documentation [Planning] — 0/2 tasks done (0%)

> 4
--- Reports ---
  Overdue Tasks: 2
    ⚠ #4 "Deploy v1" (was due 2026-04-01) — assigned to Debanjan
    ⚠ #7 "Write API docs" (was due 2026-04-03) — unassigned

  User Workload:
    Debanjan: 3 tasks (1 done, 2 in progress)
    Alice: 2 tasks (2 done)
    Bob: 1 task (0 done, 1 overdue)

  Project Health:
    TaskFlow API: 🟢 On Track
    TaskFlow UI: 🟡 At Risk (33% done)
    Documentation: 🔴 Behind (0% done)

> 5
Saving... ✓ All data persisted to JSON.
Goodbye!
```

---

## Grading Criteria

| Section | Points | Criteria |
|---|---|---|
| A. Concepts | 20 | Accuracy, clarity, examples |
| B. Output Prediction | 10 | Correct predictions with reasoning |
| C. Bug Fixes | 15 | All bugs found and properly fixed |
| D1. String Analyzer | 10 | All features working, clean code |
| D2. Shape System | 15 | Full OOP, interfaces, encapsulation |
| D3. Enrollment System | 10 | Custom exceptions, collections usage |
| D4. Report Generator | 10 | Async + LINQ + events combined |
| D5. TaskFlow Mini-App | 10 | All concepts integrated, working app |
| **Total** | **100** | |

**Passing Score:** 70/100
**Excellence Score:** 90/100

---

## Submission

- Create a new console project: `dotnet new console -n Phase1RevisionTest`
- Organize code clearly with `#region` blocks or separate methods/classes
- Include your answers to Section A and B as comments
- Tell me "check" when you're ready — I'll review and give a detailed score breakdown!

**Good luck, Debanjan! This test covers everything from Topic 1 to Topic 17. Take your time and show what you've learned! 💪**
