# Phase 1 | Topic 4: Control Flow (if/else, switch, loops)

---

## 1. What is Control Flow?

By default, C# runs code **line by line, top to bottom**. Control flow lets you **change this order** — skip lines, repeat lines, or choose between paths.

```
Normal flow:     Control flow:
Line 1           Line 1
Line 2           if (condition)
Line 3             → Line 2A
Line 4           else
                   → Line 2B
                 Line 3 (continues)
```

There are 3 types:
1. **Selection** — Choose a path (if/else, switch)
2. **Iteration** — Repeat a block (for, while, foreach)
3. **Jump** — Skip or exit (break, continue, return)

---

## 2. if / else if / else

### Basic if:

```csharp
int temperature = 35;

if (temperature > 30)
{
    Console.WriteLine("It's hot outside! 🔥");
}
```

### if / else:

```csharp
int age = 16;

if (age >= 18)
{
    Console.WriteLine("You can vote.");
}
else
{
    Console.WriteLine("Too young to vote.");
}
```

### if / else if / else (Multiple Conditions):

```csharp
int score = 85;

if (score >= 90)
{
    Console.WriteLine("Grade: A");
}
else if (score >= 80)
{
    Console.WriteLine("Grade: B");   // This runs (85 >= 80)
}
else if (score >= 70)
{
    Console.WriteLine("Grade: C");
}
else if (score >= 60)
{
    Console.WriteLine("Grade: D");
}
else
{
    Console.WriteLine("Grade: F");
}
```

### Important Rules:
```csharp
// 1. Conditions are checked TOP to BOTTOM — first match wins
int x = 95;
if (x >= 60)
    Console.WriteLine("D");   // ⚠️ This runs! Even though x is also >= 90
else if (x >= 90)
    Console.WriteLine("A");   // Never reached

// Always check the MOST SPECIFIC condition first:
if (x >= 90)       // ✅ Check highest first
    Console.WriteLine("A");
else if (x >= 60)
    Console.WriteLine("D");

// 2. Single-line if (no braces) — works but NOT recommended
if (age >= 18)
    Console.WriteLine("Adult");  // Only THIS line is inside the if

// 3. Always use braces {} — prevents bugs
if (age >= 18)
{
    Console.WriteLine("Adult");
    Console.WriteLine("Can vote");  // Both lines are inside the if
}
```

### Nested if:

```csharp
bool isLoggedIn = true;
string role = "admin";

if (isLoggedIn)
{
    if (role == "admin")
    {
        Console.WriteLine("Welcome, Admin! Full access granted.");
    }
    else
    {
        Console.WriteLine("Welcome, User! Limited access.");
    }
}
else
{
    Console.WriteLine("Please log in first.");
}

// 💡 TIP: Flatten nested ifs when possible using &&
if (isLoggedIn && role == "admin")
{
    Console.WriteLine("Welcome, Admin! Full access granted.");
}
```

---

## 3. switch Statement

When you have **many conditions checking the same variable**, `switch` is cleaner than multiple `if/else if`:

### Basic switch:

```csharp
Console.Write("Enter a day number (1-7): ");
int day = int.Parse(Console.ReadLine());

switch (day)
{
    case 1:
        Console.WriteLine("Monday");
        break;
    case 2:
        Console.WriteLine("Tuesday");
        break;
    case 3:
        Console.WriteLine("Wednesday");
        break;
    case 4:
        Console.WriteLine("Thursday");
        break;
    case 5:
        Console.WriteLine("Friday");
        break;
    case 6:
        Console.WriteLine("Saturday");
        break;
    case 7:
        Console.WriteLine("Sunday");
        break;
    default:
        Console.WriteLine("Invalid day!");
        break;
}
```

### Multiple Cases (Fall-through):

```csharp
switch (day)
{
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
        Console.WriteLine("Weekday");
        break;
    case 6:
    case 7:
        Console.WriteLine("Weekend! 🎉");
        break;
    default:
        Console.WriteLine("Invalid day");
        break;
}
```

### Switch with Strings:

```csharp
Console.Write("Enter your role: ");
string role = Console.ReadLine()?.ToLower() ?? "";

switch (role)
{
    case "admin":
        Console.WriteLine("Full access");
        break;
    case "manager":
        Console.WriteLine("Department access");
        break;
    case "developer":
    case "designer":
        Console.WriteLine("Project access");
        break;
    default:
        Console.WriteLine("Basic access");
        break;
}
```

### Switch Expression (Modern C# 8+):

A more concise way to write switch:

```csharp
int score = 85;

string grade = score switch
{
    >= 90 => "A",
    >= 80 => "B",
    >= 70 => "C",
    >= 60 => "D",
    _     => "F"        // _ is the default (discard pattern)
};

Console.WriteLine($"Grade: {grade}");  // Grade: B
```

### Pattern Matching in Switch (C# 7+):

```csharp
object value = 42;

switch (value)
{
    case int i when i > 0:
        Console.WriteLine($"Positive integer: {i}");
        break;
    case int i:
        Console.WriteLine($"Non-positive integer: {i}");
        break;
    case string s:
        Console.WriteLine($"String: {s}");
        break;
    case null:
        Console.WriteLine("Null value");
        break;
    default:
        Console.WriteLine($"Other type: {value.GetType()}");
        break;
}
```

---

## 4. for Loop

Repeats code a **specific number of times**:

```
for (initialization; condition; update)
{
    // code to repeat
}
```

```csharp
// Print 1 to 5
for (int i = 1; i <= 5; i++)
{
    Console.WriteLine(i);
}
// Output: 1, 2, 3, 4, 5
```

### How it works step by step:

```
for (int i = 1; i <= 5; i++)
      ↓          ↓       ↓
   Step 1    Step 2   Step 4
   (once)  (each loop) (after each loop)

Execution:
1. int i = 1          → i = 1
2. i <= 5? Yes        → Run body
3. Print 1
4. i++                → i = 2
5. i <= 5? Yes        → Run body
6. Print 2
7. i++                → i = 3
... continues until i = 6, then i <= 5 is false → STOP
```

### Common for Loop Patterns:

```csharp
// Count backwards
for (int i = 10; i >= 1; i--)
{
    Console.Write($"{i} ");
}
// Output: 10 9 8 7 6 5 4 3 2 1

// Count by 2s (even numbers)
for (int i = 0; i <= 20; i += 2)
{
    Console.Write($"{i} ");
}
// Output: 0 2 4 6 8 10 12 14 16 18 20

// Multiplication table
int num = 7;
for (int i = 1; i <= 10; i++)
{
    Console.WriteLine($"{num} × {i} = {num * i}");
}
```

### Nested for Loops:

```csharp
// Print a right triangle pattern
for (int row = 1; row <= 5; row++)
{
    for (int col = 1; col <= row; col++)
    {
        Console.Write("* ");
    }
    Console.WriteLine();
}
/*
Output:
* 
* * 
* * * 
* * * * 
* * * * * 
*/
```

---

## 5. while Loop

Repeats **as long as a condition is true**. Use when you **don't know in advance** how many times to loop.

```csharp
// Basic while loop
int count = 1;
while (count <= 5)
{
    Console.WriteLine($"Count: {count}");
    count++;
}

// User input validation loop
string password;
while (true)
{
    Console.Write("Enter password: ");
    password = Console.ReadLine() ?? "";
    
    if (password.Length >= 8)
    {
        Console.WriteLine("Password accepted!");
        break;    // Exit the loop
    }
    
    Console.WriteLine("Too short! Must be at least 8 characters.");
}
```

### ⚠️ Infinite Loop Danger:

```csharp
// This will run FOREVER — forgot to increment!
int x = 1;
while (x <= 5)
{
    Console.WriteLine(x);
    // x++;  ← Missing! x is always 1, loop never ends
}

// Always ensure your condition will eventually become false!
```

---

## 6. do-while Loop

Same as `while`, but **runs at least once** (checks condition AFTER the first run):

```csharp
// do-while: body runs FIRST, then checks condition
int choice;
do
{
    Console.WriteLine("\n=== TASKFLOW MENU ===");
    Console.WriteLine("1. View Tasks");
    Console.WriteLine("2. Add Task");
    Console.WriteLine("3. Delete Task");
    Console.WriteLine("0. Exit");
    Console.Write("Enter choice: ");
    
    int.TryParse(Console.ReadLine(), out choice);
    
    switch (choice)
    {
        case 1: Console.WriteLine("Displaying tasks..."); break;
        case 2: Console.WriteLine("Adding task..."); break;
        case 3: Console.WriteLine("Deleting task..."); break;
        case 0: Console.WriteLine("Goodbye!"); break;
        default: Console.WriteLine("Invalid choice!"); break;
    }
    
} while (choice != 0);    // Keep going until user enters 0
```

### while vs do-while:

```csharp
// while — may never run
int x = 10;
while (x < 5)
{
    Console.WriteLine("This never prints");   // Condition is false from start
}

// do-while — always runs at least once
int y = 10;
do
{
    Console.WriteLine("This prints once!");   // Runs before checking condition
} while (y < 5);
```

---

## 7. foreach Loop

Iterates over **every item in a collection** (arrays, lists, strings, etc.):

```csharp
// Iterate over an array
string[] tasks = { "Code review", "Fix bugs", "Write tests", "Deploy" };

foreach (string task in tasks)
{
    Console.WriteLine($"📌 {task}");
}

// Iterate over a string (each character)
string name = "Debanjan";
foreach (char c in name)
{
    Console.Write($"{c} ");
}
// Output: D e b a n j a n

// With index (using LINQ — preview for later)
foreach (var (task, index) in tasks.Select((t, i) => (t, i)))
{
    Console.WriteLine($"{index + 1}. {task}");
}
```

### for vs foreach:

```csharp
string[] fruits = { "Apple", "Banana", "Cherry" };

// for — use when you need the INDEX
for (int i = 0; i < fruits.Length; i++)
{
    Console.WriteLine($"[{i}] {fruits[i]}");
}

// foreach — use when you just need the VALUE (cleaner)
foreach (string fruit in fruits)
{
    Console.WriteLine(fruit);
}

// ⚠️ foreach is READ-ONLY — you can't modify the collection
foreach (string fruit in fruits)
{
    // fruit = "Mango";  // ❌ ERROR: Cannot assign to 'fruit'
}
```

---

## 8. Loop Control: break, continue, return

### break — Exit the loop immediately:

```csharp
// Find the first number divisible by 7
for (int i = 1; i <= 100; i++)
{
    if (i % 7 == 0)
    {
        Console.WriteLine($"Found: {i}");
        break;    // Stop the loop — no need to check more
    }
}
// Output: Found: 7
```

### continue — Skip the rest of THIS iteration:

```csharp
// Print only odd numbers
for (int i = 1; i <= 10; i++)
{
    if (i % 2 == 0)
        continue;    // Skip even numbers, go to next i
    
    Console.Write($"{i} ");
}
// Output: 1 3 5 7 9
```

### return — Exit the entire method:

```csharp
static void FindTask(string[] tasks, string search)
{
    foreach (string task in tasks)
    {
        if (task == search)
        {
            Console.WriteLine($"Found: {task}");
            return;    // Exit the method entirely
        }
    }
    Console.WriteLine("Task not found.");
}
```

### Labeled break (for nested loops):

```csharp
// In C#, there's no labeled break. Use a flag or method instead:
bool found = false;
for (int i = 0; i < 5 && !found; i++)
{
    for (int j = 0; j < 5 && !found; j++)
    {
        if (i + j == 7)
        {
            Console.WriteLine($"Found: i={i}, j={j}");
            found = true;   // This will stop both loops
        }
    }
}
```

---

## 9. Putting It All Together — Practical Example

### TaskFlow Mini Task Manager:

```csharp
Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║     TASKFLOW - MINI TASK MANAGER       ║");
Console.WriteLine("╚═══════════════════════════════════════╝");

string[] tasks = new string[10];   // Max 10 tasks
int taskCount = 0;
int choice;

do
{
    Console.WriteLine("\n--- MENU ---");
    Console.WriteLine("1. Add Task");
    Console.WriteLine("2. View All Tasks");
    Console.WriteLine("3. Search Task");
    Console.WriteLine("4. Task Statistics");
    Console.WriteLine("0. Exit");
    Console.Write("Choice: ");
    
    int.TryParse(Console.ReadLine(), out choice);
    
    switch (choice)
    {
        case 1:  // Add Task
            if (taskCount >= 10)
            {
                Console.WriteLine("❌ Task list is full!");
                break;
            }
            Console.Write("Enter task name: ");
            string newTask = Console.ReadLine() ?? "";
            if (!string.IsNullOrWhiteSpace(newTask))
            {
                tasks[taskCount] = newTask;
                taskCount++;
                Console.WriteLine($"✅ Task added! ({taskCount}/10)");
            }
            break;
            
        case 2:  // View All Tasks
            if (taskCount == 0)
            {
                Console.WriteLine("📋 No tasks yet.");
                break;
            }
            Console.WriteLine("\n📋 YOUR TASKS:");
            for (int i = 0; i < taskCount; i++)
            {
                Console.WriteLine($"  {i + 1}. {tasks[i]}");
            }
            break;
            
        case 3:  // Search Task
            Console.Write("Search keyword: ");
            string keyword = Console.ReadLine()?.ToLower() ?? "";
            bool found = false;
            
            for (int i = 0; i < taskCount; i++)
            {
                if (tasks[i].ToLower().Contains(keyword))
                {
                    Console.WriteLine($"  🔍 Found: [{i + 1}] {tasks[i]}");
                    found = true;
                }
            }
            
            if (!found)
                Console.WriteLine("❌ No matching tasks.");
            break;
            
        case 4:  // Statistics
            Console.WriteLine($"\n📊 Total Tasks: {taskCount}");
            Console.WriteLine($"📊 Slots Remaining: {10 - taskCount}");
            
            if (taskCount > 0)
            {
                int totalChars = 0;
                string longestTask = "";
                foreach (string task in tasks)
                {
                    if (task == null) continue;
                    totalChars += task.Length;
                    if (task.Length > longestTask.Length)
                        longestTask = task;
                }
                Console.WriteLine($"📊 Avg Task Name Length: {totalChars / taskCount}");
                Console.WriteLine($"📊 Longest Task: {longestTask}");
            }
            break;
            
        case 0:
            Console.WriteLine("👋 Goodbye!");
            break;
            
        default:
            Console.WriteLine("❌ Invalid choice!");
            break;
    }
    
} while (choice != 0);
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **if/else** | Choose between paths based on a condition |
| **else if** | Chain multiple conditions — first match wins, check specific first |
| **switch** | Cleaner alternative for multiple values of the same variable |
| **switch expression** | Modern C# 8+ concise syntax: `x switch { pattern => result }` |
| **for loop** | Fixed number of iterations: `for (init; condition; update)` |
| **while loop** | Loop while condition is true — may never run |
| **do-while** | Same as while but runs **at least once** |
| **foreach** | Iterate over collections — cleanest for arrays/lists |
| **break** | Exit loop immediately |
| **continue** | Skip current iteration, go to next |
| **return** | Exit the entire method |
| **Nested loops** | Loop inside a loop — use for 2D patterns, grids |
| **Pattern matching** | switch with type checking and conditions (`case int i when i > 0`) |

---

## Real-World Use Cases

1. **User Authentication** — `if/else` chains: check credentials, verify roles, handle locked accounts, expired sessions.
2. **Menu Systems** — `do-while + switch`: CLI tools, game menus, admin panels — loop until exit.
3. **Data Processing** — `foreach`: iterate over database records, API responses, file lines.
4. **Retry Logic** — `while` with a counter: retry failed API calls up to 3 times before giving up.
5. **Batch Operations** — `for` loop: process items in batches of 100, paginate results.
6. **TaskFlow Project** — Menu-driven task management, filtering tasks by status (switch), iterating task lists (foreach), input validation loops (while).

---
