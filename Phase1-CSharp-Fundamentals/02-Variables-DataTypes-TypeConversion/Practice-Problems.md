# Phase 1 | Topic 2: Practice Problems — Variables, Data Types & Type Conversion

---

## Problem 1: Variable Explorer (Easy)
**Difficulty:** ⭐ Easy

Write a C# console program that declares **one variable of each type** below, assigns a value, and prints them all with labels:

- `int`, `double`, `decimal`, `float`, `long`
- `char`, `bool`, `string`

**Expected Output:**
```
=== Variable Explorer ===
int:      42
double:   3.14159265358979
decimal:  9999.99
float:    2.718
long:     9876543210
char:     D
bool:     True
string:   Hello, TaskFlow!
```

**Requirements:**
- Use correct type suffixes (`f` for float, `m` for decimal, `L` for long)
- Use string interpolation for output

---

## Problem 2: Smart Type Converter (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Write a program that:
1. Asks the user to enter a **string value**
2. Attempts to convert it to **int**, **double**, and **bool**
3. For each conversion, print whether it succeeded or failed, and the result

**Example Output (input: "42"):**
```
Enter a value: 42

Conversion Results:
To int:     Success → 42
To double:  Success → 42
To bool:    Failed  → Not a valid boolean
```

**Example Output (input: "true"):**
```
Enter a value: true

Conversion Results:
To int:     Failed  → Not a valid integer
To double:  Failed  → Not a valid double
To bool:    Success → True
```

**Hint:** Use `int.TryParse()`, `double.TryParse()`, `bool.TryParse()`. Each returns `true` if conversion succeeds.

---

## Problem 3: Salary Calculator (Medium)
**Difficulty:** ⭐⭐ Medium

Write a program that:
1. Asks for the employee's **name**, **hourly rate** (decimal), and **hours worked this week**
2. Calculates:
   - **Gross pay** = hourly rate × hours
   - **Tax** (20% of gross)
   - **Net pay** = gross - tax
3. Displays a formatted pay slip

**Expected Output:**
```
=== TASKFLOW PAYROLL ===

Enter employee name: Debanjan
Enter hourly rate (₹): 850.50
Enter hours worked: 45

╔════════════════════════════════╗
║         PAY SLIP               ║
╠════════════════════════════════╣
║  Employee:   Debanjan          ║
║  Rate:       ₹850.50/hr       ║
║  Hours:      45                ║
║  Gross Pay:  ₹38,272.50       ║
║  Tax (20%):  ₹7,654.50        ║
║  Net Pay:    ₹30,618.00       ║
╚════════════════════════════════╝
```

**Requirements:**
- Use `decimal` for all money calculations (NOT `double`)
- Use `TryParse` for safe input conversion
- Format money values with commas and 2 decimal places

---

## Problem 4: Data Type Size Reporter (Medium)
**Difficulty:** ⭐⭐ Medium

Write a program that prints a formatted table showing:
- The **name** of each C# numeric data type
- Its **size in bytes** (use `sizeof()`)
- Its **minimum** and **maximum** values (use `int.MinValue`, `int.MaxValue`, etc.)

**Expected Output:**
```
╔════════════╦═══════════╦══════════════════════╦══════════════════════╗
║ Type       ║ Size (B)  ║ Min Value            ║ Max Value            ║
╠════════════╬═══════════╬══════════════════════╬══════════════════════╣
║ byte       ║ 1         ║ 0                    ║ 255                  ║
║ short      ║ 2         ║ -32768               ║ 32767                ║
║ int        ║ 4         ║ -2147483648          ║ 2147483647           ║
║ long       ║ 8         ║ -9223372036854775808 ║ 9223372036854775807  ║
║ float      ║ 4         ║ -3.4028235E+38       ║ 3.4028235E+38        ║
║ double     ║ 8         ║ -1.79769313...E+308  ║ 1.79769313...E+308   ║
║ decimal    ║ 16        ║ -79228162514...      ║ 79228162514...       ║
╚════════════╩═══════════╩══════════════════════╩══════════════════════╝
```

**Hints:**
- `sizeof(int)` returns `4`
- `int.MinValue` gives the minimum
- Use `PadRight()` to align columns

---

## Problem 5: Nullable Score Tracker (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a program that tracks scores for 3 subjects. The user can enter a score OR leave it blank (meaning "not yet graded").

1. Ask the user for scores in **Math**, **Science**, and **English**
2. If the user presses Enter without typing anything, store it as `null` (use `int?`)
3. Display a report card showing:
   - Each subject's score (or "Not Graded" if null)
   - The **average** of only the graded subjects
   - The **total** subjects graded vs total subjects

**Example Output:**
```
=== TASKFLOW SCORE TRACKER ===

Enter Math score (or press Enter to skip): 85
Enter Science score (or press Enter to skip): 
Enter English score (or press Enter to skip): 90

╔══════════════════════════════════╗
║          REPORT CARD             ║
╠══════════════════════════════════╣
║  Math:       85                  ║
║  Science:    Not Graded          ║
║  English:    90                  ║
╠══════════════════════════════════╣
║  Graded:     2 / 3 subjects     ║
║  Average:    87.50               ║
╚══════════════════════════════════╝
```

**Requirements:**
- Use `int?` (nullable int) for scores
- Use `string.IsNullOrWhiteSpace()` to check empty input
- Use `int.TryParse()` for safe conversion
- Use the null-coalescing operator `??` or `.HasValue` / `.Value`
- Calculate average only from non-null scores

---

## Instructions

1. Solve each problem in the `PracticeProblems` project folder
   - Replace `Program.cs` content for each problem, or create separate projects
   
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Variable Explorer
- [ ] Problem 2: Smart Type Converter
- [ ] Problem 3: Salary Calculator
- [ ] Problem 4: Data Type Size Reporter
- [ ] Problem 5: Nullable Score Tracker
