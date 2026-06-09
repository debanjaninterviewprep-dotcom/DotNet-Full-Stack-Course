# Phase 1 | Topic 3: Operators & Expressions

---

## 1. What Are Operators?

Operators are **symbols** that tell the compiler to perform a specific operation on one or more values (called **operands**).

```csharp
int result = 10 + 5;
//          ↑    ↑  ↑
//     operand  op  operand
//     (left)       (right)
```

An **expression** is any combination of operators and operands that produces a value:
```csharp
int x = (a + b) * c - d / e;   // This entire right side is an expression
```

---

## 2. Arithmetic Operators

These work with numeric types (`int`, `double`, `decimal`, etc.):

| Operator | Name | Example | Result |
|----------|------|---------|--------|
| `+` | Addition | `10 + 3` | `13` |
| `-` | Subtraction | `10 - 3` | `7` |
| `*` | Multiplication | `10 * 3` | `30` |
| `/` | Division | `10 / 3` | `3` (integer!) |
| `%` | Modulus (remainder) | `10 % 3` | `1` |

### ⚠️ Integer Division Trap

```csharp
// Integer / Integer = Integer (truncated, NOT rounded)
int a = 10 / 3;        // 3 (NOT 3.33)
int b = 7 / 2;         // 3 (NOT 3.5)

// To get decimal result, at least ONE operand must be a decimal type
double c = 10.0 / 3;   // 3.3333333333333335
double d = (double)10 / 3;  // 3.3333333333333335 (explicit cast)
```

### Modulus Operator `%` — More Useful Than You Think

```csharp
// Check if a number is even or odd
int num = 17;
if (num % 2 == 0)
    Console.WriteLine("Even");
else
    Console.WriteLine("Odd");    // Output: Odd

// Get last digit of a number
int lastDigit = 1234 % 10;      // 4

// Wrap around (circular behavior)
int hour = 25 % 24;             // 1 (25th hour wraps to 1 AM)

// Check divisibility
bool divisibleBy5 = (num % 5 == 0);  // False (17 is not divisible by 5)
```

---

## 3. Increment & Decrement Operators

| Operator | Name | Example | Explanation |
|----------|------|---------|-------------|
| `++x` | Pre-increment | `y = ++x;` | Increment first, then use |
| `x++` | Post-increment | `y = x++;` | Use first, then increment |
| `--x` | Pre-decrement | `y = --x;` | Decrement first, then use |
| `x--` | Post-decrement | `y = x--;` | Use first, then decrement |

```csharp
int x = 5;

// Post-increment: use THEN increment
int a = x++;    // a = 5, x = 6 (x was used as 5, THEN became 6)

// Pre-increment: increment THEN use
int b = ++x;    // x becomes 7 first, then b = 7

Console.WriteLine($"a = {a}");  // 5
Console.WriteLine($"b = {b}");  // 7
Console.WriteLine($"x = {x}");  // 7
```

### Tracing Through Step by Step:

```
START:        x = 5

int a = x++;  → a gets current x (5), THEN x increments
              → a = 5, x = 6

int b = ++x;  → x increments first (6 → 7), THEN b gets x
              → b = 7, x = 7
```

---

## 4. Assignment Operators

| Operator | Equivalent To | Example |
|----------|--------------|---------|
| `=` | Assign | `x = 10;` |
| `+=` | `x = x + y` | `x += 5;` → x is now 15 |
| `-=` | `x = x - y` | `x -= 3;` → x is now 12 |
| `*=` | `x = x * y` | `x *= 2;` → x is now 24 |
| `/=` | `x = x / y` | `x /= 4;` → x is now 6 |
| `%=` | `x = x % y` | `x %= 4;` → x is now 2 |

```csharp
int score = 100;
score += 50;    // 150 (gained 50 points)
score -= 20;    // 130 (lost 20 points)
score *= 2;     // 260 (double points bonus!)
score /= 10;    // 26  
score %= 7;     // 5   (26 / 7 = 3 remainder 5)
```

---

## 5. Comparison (Relational) Operators

These **compare two values** and return `true` or `false` (a `bool`):

| Operator | Meaning | Example | Result |
|----------|---------|---------|--------|
| `==` | Equal to | `5 == 5` | `true` |
| `!=` | Not equal to | `5 != 3` | `true` |
| `>` | Greater than | `5 > 3` | `true` |
| `<` | Less than | `5 < 3` | `false` |
| `>=` | Greater or equal | `5 >= 5` | `true` |
| `<=` | Less or equal | `5 <= 3` | `false` |

```csharp
int age = 25;
bool canVote = age >= 18;            // true
bool isTeenager = age >= 13 && age <= 19;  // false

string name = "Debanjan";
bool isDebanjan = name == "Debanjan";  // true (case-sensitive!)
bool isEqual = name == "debanjan";     // false! (different case)

// For case-insensitive comparison:
bool isMatch = name.Equals("debanjan", StringComparison.OrdinalIgnoreCase); // true
```

### ⚠️ Common Mistake: `=` vs `==`

```csharp
int x = 5;

// WRONG — this ASSIGNS, not compares
// if (x = 10)  // ❌ Compile error in C# (thankfully!)

// CORRECT — this COMPARES
if (x == 10)    // ✅ Returns false
```

---

## 6. Logical Operators

These combine boolean expressions:

| Operator | Name | Description | Example |
|----------|------|-------------|---------|
| `&&` | AND | Both must be true | `true && false` → `false` |
| `\|\|` | OR | At least one must be true | `true \|\| false` → `true` |
| `!` | NOT | Reverses the boolean | `!true` → `false` |

### Truth Tables:

```
AND (&&):                OR (||):                NOT (!):
┌───────┬───────┬────┐   ┌───────┬───────┬────┐   ┌───────┬────┐
│   A   │   B   │ A&&B│   │   A   │   B   │A||B│   │   A   │ !A │
├───────┼───────┼────┤   ├───────┼───────┼────┤   ├───────┼────┤
│ true  │ true  │true│   │ true  │ true  │true│   │ true  │false│
│ true  │ false │false│  │ true  │ false │true│   │ false │true│
│ false │ true  │false│  │ false │ true  │true│   └───────┴────┘
│ false │ false │false│  │ false │ false │false│
└───────┴───────┴────┘   └───────┴───────┴────┘
```

### Practical Example:

```csharp
int age = 25;
bool hasID = true;
bool isMember = false;

// Can enter if: age >= 18 AND has ID
bool canEnter = age >= 18 && hasID;          // true

// Gets discount if: is a member OR is a senior (65+)
bool getsDiscount = isMember || age >= 65;   // false

// Is NOT a member
bool isNotMember = !isMember;               // true

// Complex: Can access VIP area?
bool vipAccess = canEnter && (isMember || age >= 65);  // false
```

### Short-Circuit Evaluation

C# is **smart** — it stops evaluating as soon as the result is known:

```csharp
// AND: If left is false, right is NEVER evaluated
bool result1 = false && SomeExpensiveCheck();  // SomeExpensiveCheck() never runs!

// OR: If left is true, right is NEVER evaluated  
bool result2 = true || SomeExpensiveCheck();   // SomeExpensiveCheck() never runs!

// This is useful to avoid errors:
string name = null;
if (name != null && name.Length > 0)  // Safe! If name is null, .Length is never called
{
    Console.WriteLine(name);
}
```

---

## 7. Bitwise Operators (Interview Favorite)

These operate on **individual bits** (binary representation) of integers:

| Operator | Name | Example (decimal) | Binary Operation |
|----------|------|--------------------|-----------------|
| `&` | AND | `5 & 3` = `1` | `101 & 011 = 001` |
| `\|` | OR | `5 \| 3` = `7` | `101 \| 011 = 111` |
| `^` | XOR | `5 ^ 3` = `6` | `101 ^ 011 = 110` |
| `~` | NOT | `~5` = `-6` | Flips all bits |
| `<<` | Left shift | `5 << 1` = `10` | `101 → 1010` |
| `>>` | Right shift | `5 >> 1` = `2` | `101 → 10` |

### Visualizing Bitwise AND:

```
  5 in binary:  1 0 1
  3 in binary:  0 1 1
  ─────────────────────
  5 & 3:        0 0 1  → 1

  Rule: Both bits must be 1 to get 1
```

### Visualizing Bitwise OR:

```
  5 in binary:  1 0 1
  3 in binary:  0 1 1
  ─────────────────────
  5 | 3:        1 1 1  → 7

  Rule: At least one bit must be 1 to get 1
```

### Visualizing Bitwise XOR:

```
  5 in binary:  1 0 1
  3 in binary:  0 1 1
  ─────────────────────
  5 ^ 3:        1 1 0  → 6

  Rule: Bits must be DIFFERENT to get 1
```

### Practical Uses:

```csharp
// Check if a number is even/odd using AND
int num = 7;
bool isOdd = (num & 1) == 1;   // true (faster than num % 2)

// Swap without temp variable using XOR (from Topic 1!)
int a = 5, b = 10;
a = a ^ b;   // a = 15
b = a ^ b;   // b = 5
a = a ^ b;   // a = 10

// Left shift = multiply by 2
int doubled = 5 << 1;   // 10  (5 * 2)
int quadrupled = 5 << 2; // 20 (5 * 4)

// Right shift = divide by 2
int halved = 10 >> 1;   // 5  (10 / 2)
```

---

## 8. Ternary (Conditional) Operator

A **shorthand if/else** in a single line:

```
condition ? valueIfTrue : valueIfFalse
```

```csharp
int age = 25;

// Instead of:
string status;
if (age >= 18)
    status = "Adult";
else
    status = "Minor";

// You can write:
string status = age >= 18 ? "Adult" : "Minor";   // "Adult"

// More examples:
int score = 85;
string grade = score >= 90 ? "A" : score >= 80 ? "B" : score >= 70 ? "C" : "F";
// grade = "B"

// With string interpolation:
Console.WriteLine($"You are {(age >= 18 ? "an adult" : "a minor")}");

// Null check:
string name = null;
string displayName = name ?? "Anonymous";  // "Anonymous" (null-coalescing, from Topic 2)
```

### ⚠️ Don't Over-Nest Ternary Operators

```csharp
// ❌ Hard to read
string result = a > b ? a > c ? "a wins" : "c wins" : b > c ? "b wins" : "c wins";

// ✅ Use if/else for complex conditions
if (a > b && a > c) result = "a wins";
else if (b > c) result = "b wins";
else result = "c wins";
```

---

## 9. Null-Related Operators (Very Important in Real Projects)

### Null-Coalescing `??`

```csharp
string name = null;
string displayName = name ?? "Guest";     // "Guest" (if left is null, use right)

int? score = null;
int finalScore = score ?? 0;              // 0
```

### Null-Coalescing Assignment `??=`

```csharp
string name = null;
name ??= "Default User";    // name is now "Default User"
// Equivalent to: if (name == null) name = "Default User";

string name2 = "Debanjan";
name2 ??= "Default User";   // name2 is still "Debanjan" (wasn't null)
```

### Null-Conditional `?.`

```csharp
string name = null;

// Without null-conditional — CRASHES with NullReferenceException
// int length = name.Length;   // ❌ Runtime error!

// With null-conditional — returns null safely
int? length = name?.Length;    // null (no crash!)

// Chain it:
string city = person?.Address?.City?.ToUpper();  // Safe even if any part is null

// With methods:
string upper = name?.ToUpper();  // null (doesn't crash)
```

### Null-Forgiving `!` (Tells compiler "trust me, it's not null")

```csharp
string? name = GetNameFromDatabase();  // Might return null
string definitelyNotNull = name!;      // You're telling the compiler: "I know this isn't null"
// ⚠️ Use carefully — if it IS null, you'll get a runtime error
```

---

## 10. Operator Precedence (Order of Operations)

Just like math (PEMDAS/BODMAS), operators have a priority order:

| Priority | Operator | Direction |
|----------|----------|-----------|
| 1 (highest) | `()` Parentheses | Left → Right |
| 2 | `!`, `~`, `++`, `--`, unary `+`/`-` | Right → Left |
| 3 | `*`, `/`, `%` | Left → Right |
| 4 | `+`, `-` | Left → Right |
| 5 | `<<`, `>>` | Left → Right |
| 6 | `<`, `>`, `<=`, `>=` | Left → Right |
| 7 | `==`, `!=` | Left → Right |
| 8 | `&` (bitwise AND) | Left → Right |
| 9 | `^` (bitwise XOR) | Left → Right |
| 10 | `\|` (bitwise OR) | Left → Right |
| 11 | `&&` (logical AND) | Left → Right |
| 12 | `\|\|` (logical OR) | Left → Right |
| 13 | `?:` (ternary) | Right → Left |
| 14 | `=`, `+=`, `-=`, etc. | Right → Left |

### Example:

```csharp
int result = 2 + 3 * 4;       // 14 (NOT 20 — multiplication first)
int result2 = (2 + 3) * 4;    // 20 (parentheses override)

bool check = 5 > 3 && 10 < 20 || false;
// Step 1: 5 > 3 → true
// Step 2: 10 < 20 → true
// Step 3: true && true → true
// Step 4: true || false → true
```

> **Pro Tip:** When in doubt, **use parentheses**. They make your code clearer and prevent bugs.

---

## 11. Putting It All Together — Practical Example

### TaskFlow Task Priority Calculator:

```csharp
Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║   TASKFLOW - TASK PRIORITY CALCULATOR  ║");
Console.WriteLine("╚═══════════════════════════════════════╝");
Console.WriteLine();

Console.Write("Enter task name: ");
string taskName = Console.ReadLine() ?? "Untitled";

Console.Write("Is it urgent? (true/false): ");
bool isUrgent = bool.TryParse(Console.ReadLine(), out bool u) && u;

Console.Write("Is it important? (true/false): ");
bool isImportant = bool.TryParse(Console.ReadLine(), out bool imp) && imp;

Console.Write("Days until deadline: ");
int daysLeft = int.TryParse(Console.ReadLine(), out int d) ? d : 30;

Console.Write("Estimated hours: ");
double hours = double.TryParse(Console.ReadLine(), out double h) ? h : 1;

// Calculate priority score using operators
int priorityScore = 0;
priorityScore += isUrgent ? 50 : 0;          // Ternary
priorityScore += isImportant ? 30 : 0;       // Ternary
priorityScore += daysLeft <= 3 ? 20 : daysLeft <= 7 ? 10 : 0;  // Nested ternary
priorityScore -= (int)(hours / 2);            // Explicit cast

// Determine priority level
string priority = priorityScore >= 80 ? "🔴 CRITICAL" :
                  priorityScore >= 50 ? "🟠 HIGH" :
                  priorityScore >= 30 ? "🟡 MEDIUM" :
                                        "🟢 LOW";

// Eisenhower Matrix quadrant
string quadrant = isUrgent && isImportant   ? "DO IT NOW" :        // && operator
                  !isUrgent && isImportant  ? "SCHEDULE IT" :      // ! operator
                  isUrgent && !isImportant  ? "DELEGATE IT" :
                                              "ELIMINATE IT";

Console.WriteLine();
Console.WriteLine($"Task:      {taskName}");
Console.WriteLine($"Score:     {priorityScore}/100");
Console.WriteLine($"Priority:  {priority}");
Console.WriteLine($"Quadrant:  {quadrant}");
Console.WriteLine($"Deadline:  {(daysLeft <= 3 ? "⚠️ SOON!" : $"{daysLeft} days")}");
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Arithmetic** | `+`, `-`, `*`, `/`, `%` — watch out for integer division! |
| **`%` Modulus** | Returns remainder — great for even/odd, divisibility, wrap-around |
| **`++`/`--`** | Pre (++x) changes before use, Post (x++) changes after use |
| **Assignment** | `+=`, `-=`, `*=`, `/=`, `%=` — shorthand for modify-and-assign |
| **Comparison** | `==`, `!=`, `>`, `<`, `>=`, `<=` — return `bool` |
| **Logical** | `&&` (AND), `\|\|` (OR), `!` (NOT) — combine boolean conditions |
| **Short-circuit** | `&&` stops if left is false; `\|\|` stops if left is true |
| **Bitwise** | `&`, `\|`, `^`, `~`, `<<`, `>>` — operate on individual bits |
| **Ternary** | `condition ? trueVal : falseVal` — shorthand if/else |
| **`??`** | Null-coalescing — provide default if null |
| **`??=`** | Null-coalescing assignment — assign only if null |
| **`?.`** | Null-conditional — safe navigation through possibly null objects |
| **Precedence** | Use parentheses when in doubt! |

---

## Real-World Use Cases

1. **Form Validation** — Comparison + logical operators: `if (age >= 18 && hasConsent && !isBanned)` — checking multiple conditions before allowing registration.
2. **Pricing & Discounts** — Ternary + arithmetic: `decimal finalPrice = isMember ? price * 0.8m : price;` — applying conditional discounts.
3. **Permission Systems** — Bitwise operators are used in **flags/permissions**: Read=1, Write=2, Execute=4. A user with Read+Write has permission value `3` (`1 | 2`).
4. **Null-Safe API Responses** — `?.` and `??` are used everywhere in real APIs: `var city = response?.Data?.User?.Address?.City ?? "Unknown";`
5. **TaskFlow Project** — When displaying tasks: priority calculation, overdue checks (`dueDate < DateTime.Now`), conditional formatting, null-safe user profile access.

---
