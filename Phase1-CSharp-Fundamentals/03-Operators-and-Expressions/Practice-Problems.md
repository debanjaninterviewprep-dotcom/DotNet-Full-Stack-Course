# Phase 1 | Topic 3: Practice Problems — Operators & Expressions

---

## Problem 1: Arithmetic Playground (Easy)
**Difficulty:** ⭐ Easy

Write a program that:
1. Asks the user for **two integers**
2. Performs and displays ALL arithmetic operations: `+`, `-`, `*`, `/`, `%`
3. Also show the result of **integer division** vs **decimal division**

**Expected Output:**
```
Enter first number: 17
Enter second number: 5

=== Arithmetic Results ===
17 + 5  = 22
17 - 5  = 12
17 * 5  = 85
17 / 5  = 3       (integer division)
17 / 5  = 3.40    (decimal division)
17 % 5  = 2       (remainder)
```

**Requirements:**
- Use `int` for integer division, cast to `double` for decimal division
- Format decimal result to 2 decimal places

---

## Problem 2: Pre/Post Increment Predictor (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Write a program that demonstrates the difference between pre-increment and post-increment.

1. Start with `int x = 10;`
2. Perform each operation below **one at a time**, printing the value of `x` and the result after each:
   - `int a = x++;`
   - `int b = ++x;`
   - `int c = x--;`
   - `int d = --x;`

**Expected Output:**
```
Starting: x = 10

int a = x++;  → a = 10, x = 11
int b = ++x;  → b = 12, x = 12
int c = x--;  → c = 12, x = 11
int d = --x;  → d = 10, x = 10
```

**Requirements:**
- Show the value of both the assigned variable AND `x` after each step
- Add a comment explaining **why** each result is what it is

---

## Problem 3: Grade Calculator with Logical Operators (Medium)
**Difficulty:** ⭐⭐ Medium

Build a program that:
1. Asks for scores in **3 subjects** (Math, Science, English) — each out of 100
2. Calculates the **average**
3. Determines the **grade** using these rules:
   - `A` : Average >= 90
   - `B` : Average >= 80
   - `C` : Average >= 70
   - `D` : Average >= 60
   - `F` : Average < 60
4. Also checks:
   - **Passed** = All subjects >= 40 AND average >= 60
   - **Distinction** = All subjects >= 75 AND average >= 85
   - **Failed subjects** = List any subject below 40

**Expected Output:**
```
Enter Math score: 92
Enter Science score: 78
Enter English score: 88

=== REPORT CARD ===
Math:       92
Science:    78
English:    88
Average:    86.00
Grade:      B
Status:     PASSED ✅
Distinction: No
```

**Requirements:**
- Use **logical operators** (`&&`, `||`, `!`) for pass/distinction checks
- Use **ternary operator** for at least one output
- Use **comparison operators** throughout
- Validate that scores are between 0-100

---

## Problem 4: Bitwise Permission System (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a simple **permission system** using bitwise operators:

Define permissions as:
```
Read    = 1  (binary: 001)
Write   = 2  (binary: 010)
Execute = 4  (binary: 100)
```

1. Ask the user which permissions to grant (Y/N for each)
2. Build the permission value using bitwise OR (`|`)
3. Display the binary representation and total value
4. Then ask the user to **check** a specific permission and use bitwise AND (`&`) to verify

**Expected Output:**
```
=== PERMISSION MANAGER ===

Grant READ permission? (Y/N): Y
Grant WRITE permission? (Y/N): Y
Grant EXECUTE permission? (Y/N): N

Permission Value: 3
Binary: 011
Permissions: Read, Write

Check permission - Enter R/W/E: E
Result: ❌ EXECUTE permission NOT granted
```

**Hints:**
- `permissions |= Read;` to add a permission
- `(permissions & Write) != 0` to check if Write is granted
- `Convert.ToString(value, 2)` to display binary

---

## Problem 5: Null-Safe User Profile (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a program that simulates loading a user profile where some fields might be missing:

1. Ask the user for: **Name**, **Email**, **Phone**, **City**
2. The user can **press Enter to skip** any field (making it null/empty)
3. Display the profile using **null-safe operators** throughout

**Expected Output (with some fields skipped):**
```
=== TASKFLOW PROFILE SETUP ===

Enter name (or press Enter to skip): Debanjan
Enter email (or press Enter to skip): 
Enter phone (or press Enter to skip): 9876543210
Enter city (or press Enter to skip): 

╔══════════════════════════════════════╗
║         USER PROFILE                 ║
╠══════════════════════════════════════╣
║  Name:    Debanjan                   ║
║  Email:   Not Provided               ║
║  Phone:   9876543210                 ║
║  City:    Not Provided               ║
╠══════════════════════════════════════╣
║  Name Length:    8 characters        ║
║  Email Domain:   N/A                 ║
║  Profile:        60% Complete        ║
╚══════════════════════════════════════╝
```

**Requirements:**
- Use `??` (null-coalescing) for default values
- Use `?.` (null-conditional) for safe property access
- Use `string.IsNullOrWhiteSpace()` to detect empty input
- Calculate **profile completeness** as a percentage (fields filled / total fields × 100)
- Extract **email domain** using `?.Split('@')` safely
- Use the ternary operator for conditional display

---

## Instructions

1. Solve each problem in the `PracticeProblems` project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Arithmetic Playground
- [ ] Problem 2: Pre/Post Increment Predictor
- [ ] Problem 3: Grade Calculator with Logical Operators
- [ ] Problem 4: Bitwise Permission System
- [ ] Problem 5: Null-Safe User Profile
