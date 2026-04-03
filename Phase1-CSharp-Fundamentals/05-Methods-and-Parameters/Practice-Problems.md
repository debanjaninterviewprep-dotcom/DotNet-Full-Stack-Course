# Phase 1 | Topic 5: Practice Problems — Methods & Parameters

---

## Problem 1: Method Toolbox (Easy)
**Difficulty:** ⭐ Easy

Create the following utility methods and demonstrate each one:

1. `static void PrintSeparator()` — prints a line of 40 dashes
2. `static string Reverse(string text)` — returns the reversed string
3. `static int Max(int a, int b)` — returns the larger number
4. `static bool IsPalindrome(string text)` — returns true if the string reads the same forwards and backwards

**Expected Output:**
```
--- Method Toolbox Demo ---
────────────────────────────────────────
Reverse of "Debanjan": najnabeD
Max of 42 and 17: 42
Is "racecar" a palindrome? True
Is "hello" a palindrome? False
────────────────────────────────────────
```

**Requirements:**
- Use expression-bodied methods (`=>`) for at least 2 of them
- Call each method at least twice with different arguments

---

## Problem 2: Overloaded Calculator (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Create an overloaded `Calculate` method that works with different inputs:

1. `Calculate(int a, int b)` — returns sum as `int`
2. `Calculate(double a, double b)` — returns sum as `double`
3. `Calculate(int a, int b, string operation)` — performs +, -, *, / based on operation string
4. `Calculate(params int[] numbers)` — returns sum of all numbers

**Expected Output:**
```
=== OVERLOADED CALCULATOR ===

Calculate(5, 3):             8
Calculate(5.5, 3.2):         8.7
Calculate(10, 3, "multiply"): 30
Calculate(10, 3, "divide"):  3.33
Calculate(1,2,3,4,5):        15
```

**Requirements:**
- Handle division by zero gracefully
- Use at least one expression-bodied overload
- Format decimal results to 2 decimal places

---

## Problem 3: ref/out Swap & Split (Medium)
**Difficulty:** ⭐⭐ Medium

Create these methods demonstrating `ref` and `out`:

1. `static void Swap(ref int a, ref int b)` — swaps two integers using ref
2. `static void MinMax(int[] numbers, out int min, out int max)` — finds the min and max of an array using out
3. `static bool TryParseFullName(string fullName, out string firstName, out string lastName)` — splits "First Last" into two parts

**Expected Output:**
```
=== REF & OUT DEMO ===

Before swap: a = 10, b = 20
After swap:  a = 20, b = 10

Array: [34, 12, 78, 5, 91, 23]
Min: 5, Max: 91

ParseName("Debanjan Roy"):
  First: Debanjan
  Last:  Roy

ParseName("Madonna"):
  Could not parse — single name only.
```

**Requirements:**
- `Swap` must use `ref`
- `MinMax` must use `out`
- `TryParseFullName` must return `bool` (like TryParse pattern) and use `out`

---

## Problem 4: Recursive Power Calculator (Medium)
**Difficulty:** ⭐⭐ Medium

Build these recursive methods:

1. `static int Power(int baseNum, int exponent)` — calculates base^exponent recursively
2. `static int SumOfDigits(int number)` — returns the sum of all digits (e.g., 1234 → 10)
3. `static int CountDigits(int number)` — returns the number of digits

**Expected Output:**
```
=== RECURSION DEMO ===

Power(2, 10) = 1024
Power(5, 3)  = 125
Power(7, 0)  = 1

Sum of digits of 9876: 30
Sum of digits of 12345: 15

Count digits in 9876: 4
Count digits in 100000: 6
Count digits in 7: 1
```

**Requirements:**
- All methods must be **recursive** (no loops!)
- Each method must have a clear **base case**
- Trace through `Power(2, 4)` in a comment showing each recursive call

---

## Problem 5: TaskFlow Command System (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a mini command system for TaskFlow that demonstrates ALL method concepts:

1. **Menu system** using a `do-while` loop
2. **Add Task** — method with optional parameters: `AddTask(string title, string priority = "Medium", string assignee = "Unassigned")`
3. **View Tasks** — method that takes `params string[] filters` to filter by keywords
4. **Task Statistics** — method returning a **tuple**: `(int total, int completed, double percentage)`
5. **Search** — an **overloaded** method:
   - `Search(string keyword)` — search by title
   - `Search(int id)` — search by index
6. **Complete Task** — method using `ref` to modify task status

**Expected Output:**
```
╔═══════════════════════════════════╗
║   TASKFLOW COMMAND CENTER         ║
╚═══════════════════════════════════╝

1. Add Task
2. View Tasks
3. Search
4. Statistics
5. Complete Task
0. Exit

Choice: 1
Task title: Fix login bug
Priority (High/Medium/Low) [Medium]: High
Assignee [Unassigned]: Debanjan
✅ Task added: "Fix login bug" | Priority: High | Assignee: Debanjan

Choice: 1
Task title: Update docs
(using defaults)
✅ Task added: "Update docs" | Priority: Medium | Assignee: Unassigned

Choice: 4
📊 Total: 2 | Completed: 0 | Progress: 0.0%

Choice: 5
Task # to complete: 1
✅ "Fix login bug" marked as completed!

Choice: 4
📊 Total: 2 | Completed: 1 | Progress: 50.0%
```

**Requirements:**
- Use **optional parameters** with defaults
- Use **named parameters** in at least one call
- Use **params** for the filter feature
- Use **tuples** for statistics return
- Use **method overloading** for search
- Store tasks in arrays (max 20 tasks)

---

## Instructions

1. Solve each problem in the `PracticeProblems` project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Method Toolbox
- [ ] Problem 2: Overloaded Calculator
- [ ] Problem 3: ref/out Swap & Split
- [ ] Problem 4: Recursive Power Calculator
- [ ] Problem 5: TaskFlow Command System
