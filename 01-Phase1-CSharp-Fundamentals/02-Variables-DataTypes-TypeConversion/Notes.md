# Phase 1 | Topic 2: Variables, Data Types & Type Conversion

---

## 1. What is a Variable?

A variable is a **named container** that stores a value in your computer's memory.

Think of it like a **labeled box** — the label is the name, and the thing inside is the value.

```csharp
string playerName = "Debanjan";   // A box labeled "playerName" containing "Debanjan"
int score = 100;                   // A box labeled "score" containing 100
```

### Variable Declaration Syntax:

```
dataType variableName = value;
```

```csharp
int age = 25;           // Declare + Initialize (assign a value)
int height;             // Declare only (no value yet — will get default value)
height = 180;           // Assign value later
```

### Naming Rules (MUST follow):
| Rule | Example |
|------|---------|
| Must start with a letter or `_` | `name`, `_count` ✅ |
| Cannot start with a number | `1name` ❌ |
| Cannot use C# reserved keywords | `int`, `class`, `void` ❌ |
| Case-sensitive | `Name` and `name` are different |
| No spaces allowed | `my name` ❌, use `myName` ✅ |

### Naming Conventions (SHOULD follow):
| Convention | Usage | Example |
|-----------|-------|---------|
| **camelCase** | Local variables, parameters | `firstName`, `totalScore` |
| **PascalCase** | Classes, Methods, Properties | `PlayerName`, `GetScore()` |
| **_camelCase** | Private fields | `_connectionString` |
| **UPPER_SNAKE** | Constants (some teams) | `MAX_RETRY_COUNT` |

```csharp
// ✅ Good naming
string firstName = "Debanjan";
int totalTaskCount = 42;
bool isCompleted = false;

// ❌ Bad naming
string x = "Debanjan";          // What is "x"?
int a = 42;                     // Meaningless
bool flag = false;              // Flag for what?
```

---

## 2. Data Types in C#

Every variable in C# must have a **data type**. This tells the compiler:
- What **kind** of data it holds
- How much **memory** it uses
- What **operations** you can do with it

### 2.1 Value Types (stored directly in memory — Stack)

These store the **actual value** directly.

#### Integer Types (Whole Numbers):

| Type | Size | Range | Example |
|------|------|-------|---------|
| `byte` | 1 byte | 0 to 255 | `byte age = 25;` |
| `sbyte` | 1 byte | -128 to 127 | `sbyte temp = -10;` |
| `short` | 2 bytes | -32,768 to 32,767 | `short distance = 30000;` |
| `ushort` | 2 bytes | 0 to 65,535 | `ushort port = 8080;` |
| `int` | 4 bytes | -2.1B to 2.1B | `int population = 1400000000;` |
| `uint` | 4 bytes | 0 to 4.2B | `uint fileSize = 3000000000;` |
| `long` | 8 bytes | ±9.2 quintillion | `long galaxyStars = 100000000000L;` |
| `ulong` | 8 bytes | 0 to 18.4 quintillion | `ulong atoms = 10000000000000UL;` |

> **Which one to use?** Use `int` by default for whole numbers. Use `long` if values exceed 2 billion. Use `byte` only when you're sure values are 0-255 (like RGB colors).

#### Floating-Point Types (Decimal Numbers):

| Type | Size | Precision | Suffix | Example |
|------|------|-----------|--------|---------|
| `float` | 4 bytes | ~6-7 digits | `f` | `float price = 19.99f;` |
| `double` | 8 bytes | ~15-16 digits | (default) | `double pi = 3.14159265358979;` |
| `decimal` | 16 bytes | ~28-29 digits | `m` | `decimal salary = 75000.50m;` |

> **Which one to use?**
> - `double` — Default for general math, scientific calculations
> - `decimal` — **ALWAYS use for money/financial calculations** (no rounding errors)
> - `float` — Only when memory is tight (games, graphics)

```csharp
// ⚠️ WHY DECIMAL MATTERS FOR MONEY
double badMoney = 0.1 + 0.2;         // 0.30000000000000004 😱
decimal goodMoney = 0.1m + 0.2m;     // 0.3 ✅

Console.WriteLine(badMoney);   // 0.30000000000000004
Console.WriteLine(goodMoney);  // 0.3
```

#### Other Value Types:

| Type | Size | Description | Example |
|------|------|-------------|---------|
| `bool` | 1 byte | true or false | `bool isActive = true;` |
| `char` | 2 bytes | Single character (Unicode) | `char grade = 'A';` |

```csharp
bool isLoggedIn = true;
bool hasPermission = false;

char initial = 'D';           // Single quotes for char
char heart = '♥';             // Unicode characters work!
char newLine = '\n';          // Escape character
```

### 2.2 Reference Types (stored as a reference/pointer — Heap)

These store a **reference (address)** to the actual data in memory.

| Type | Description | Example |
|------|-------------|---------|
| `string` | Sequence of characters | `string name = "Debanjan";` |
| `object` | Base type of all types | `object anything = 42;` |
| `dynamic` | Type resolved at runtime | `dynamic value = "Hello";` |
| Arrays | Collection of items | `int[] nums = {1, 2, 3};` |
| Classes | Custom types | `Person p = new Person();` |

```csharp
// Strings use DOUBLE quotes
string greeting = "Hello, World!";
string empty = "";                    // Empty string
string nothing = null;                // No value at all (reference types can be null)

// String is IMMUTABLE — once created, it cannot be changed
string original = "Hello";
string modified = original + " World";  // Creates a NEW string, original unchanged
```

### 2.3 Value Types vs Reference Types — The Key Difference

```csharp
// VALUE TYPE — copies the value
int a = 10;
int b = a;     // b gets a COPY of 10
b = 20;        // Changing b does NOT affect a
Console.WriteLine(a);  // 10 (unchanged!)
Console.WriteLine(b);  // 20

// REFERENCE TYPE — copies the reference (address)
int[] arr1 = {1, 2, 3};
int[] arr2 = arr1;      // arr2 points to the SAME array
arr2[0] = 99;           // Changing arr2 ALSO changes arr1!
Console.WriteLine(arr1[0]);  // 99 (changed!)
```

```
VALUE TYPE (Stack):                REFERENCE TYPE (Heap):
┌──────────┐                      ┌──────────┐
│ a = 10   │                      │ arr1 ──────────┐
├──────────┤                      ├──────────┤     ▼
│ b = 20   │ (separate copy)      │ arr2 ──────────┤
└──────────┘                      └──────────┘     │
                                                   ▼
                                            ┌─────────────┐
                                            │ {99, 2, 3}  │ (shared data)
                                            └─────────────┘
```

---

## 3. The `var` Keyword (Implicit Typing)

C# can **infer** the type from the assigned value using `var`:

```csharp
var name = "Debanjan";      // Compiler knows it's string
var age = 25;               // Compiler knows it's int
var price = 19.99;          // Compiler knows it's double
var isActive = true;        // Compiler knows it's bool
```

### Rules for `var`:
```csharp
var x = 10;        // ✅ Compiler infers int
var y;             // ❌ ERROR — must assign a value (compiler needs to infer the type)
var z = null;      // ❌ ERROR — can't infer type from null
```

### When to use `var`:
```csharp
// ✅ Use var when the type is OBVIOUS from the right side
var name = "Debanjan";                           // Clearly a string
var tasks = new List<string>();                   // Clearly a List<string>
var result = GetTaskById(5);                      // Type clear from method name

// ❌ Avoid var when the type is NOT obvious
var data = ProcessResult();                       // What type is this?
var x = Calculate(a, b, c);                       // Unclear
```

---

## 4. Constants & Read-Only

### Constants (`const`):
Value set at **compile time** and **NEVER changes**.

```csharp
const double PI = 3.14159265358979;
const int MAX_RETRIES = 3;
const string APP_NAME = "TaskFlow";

// PI = 3.14;  // ❌ Compile ERROR — cannot change a constant
```

### Read-Only (`readonly`):
Value set at **runtime** (in constructor) and then **cannot change**.

```csharp
class AppConfig
{
    readonly string _connectionString;
    
    public AppConfig(string connStr)
    {
        _connectionString = connStr;   // ✅ Can set in constructor
    }
    
    public void Update()
    {
        // _connectionString = "new";  // ❌ Cannot change after constructor
    }
}
```

### `const` vs `readonly`:
| Feature | `const` | `readonly` |
|---------|---------|------------|
| Set at | Compile time | Runtime (constructor) |
| Can use with | Only primitive types & strings | Any type |
| Memory | Replaced inline at compile | Normal field |
| Best for | Mathematical constants, config | Values computed at startup |

---

## 5. Default Values

If you declare a variable without assigning a value (as a class field), it gets a **default value**:

| Type | Default Value |
|------|---------------|
| `int`, `long`, `short` | `0` |
| `float`, `double`, `decimal` | `0.0` |
| `bool` | `false` |
| `char` | `'\0'` (null character) |
| `string` | `null` |
| `object` | `null` |

```csharp
// ⚠️ IMPORTANT: Local variables MUST be assigned before use
int x;
Console.WriteLine(x);  // ❌ Compile ERROR — "Use of unassigned local variable"

// Class fields get default values automatically
class Player
{
    int score;           // Default: 0
    string name;         // Default: null
    bool isActive;       // Default: false
}
```

---

## 6. Nullable Types

What if you want an `int` that can also be `null` (no value)?

```csharp
// Regular int — CANNOT be null
int age = 25;
// age = null;  // ❌ ERROR

// Nullable int — CAN be null
int? age2 = 25;
age2 = null;   // ✅ OK

// Check if it has a value
if (age2.HasValue)
{
    Console.WriteLine($"Age is: {age2.Value}");
}
else
{
    Console.WriteLine("Age is not set");
}

// Null-coalescing operator (??) — provide a default if null
int displayAge = age2 ?? 0;  // If age2 is null, use 0
Console.WriteLine($"Display age: {displayAge}");
```

### Nullable Reference Types (C# 8+):

```csharp
// With nullable enabled (default in modern .NET projects)
string name = "Debanjan";     // Non-nullable — must always have a value
string? nickname = null;       // Nullable — explicitly allows null

// The compiler will WARN you if you try unsafe operations
Console.WriteLine(nickname.Length);    // ⚠️ Warning: may be null
Console.WriteLine(nickname?.Length);   // ✅ Safe: null-conditional operator
```

---

## 7. Type Conversion (Casting)

Often you need to convert one type to another. C# provides several ways:

### 7.1 Implicit Conversion (Automatic — Safe, No Data Loss)

The compiler does this automatically when it's **safe** (smaller → larger type):

```csharp
int myInt = 100;
long myLong = myInt;        // int → long (no data loss) ✅
float myFloat = myInt;      // int → float (no data loss) ✅
double myDouble = myFloat;  // float → double (no data loss) ✅

// Conversion hierarchy (safe direction →):
// byte → short → int → long → float → double → decimal
```

### 7.2 Explicit Conversion (Manual Cast — Possible Data Loss)

When converting from a **larger to smaller** type, you must explicitly cast:

```csharp
double myDouble = 9.78;
int myInt = (int)myDouble;    // Explicit cast — truncates to 9 (loses .78)
Console.WriteLine(myInt);     // 9

long bigNumber = 3000000000L;
int smallNumber = (int)bigNumber;  // ⚠️ DANGEROUS — may overflow!

// Safe casting with 'checked':
checked
{
    int safe = (int)bigNumber;  // Throws OverflowException if value is too large
}
```

### 7.3 Using Convert Class

```csharp
// String to Number
string ageText = "25";
int age = Convert.ToInt32(ageText);         // 25
double height = Convert.ToDouble("5.11");   // 5.11
bool isActive = Convert.ToBoolean("true");  // true

// Number to String
int score = 100;
string scoreText = Convert.ToString(score);  // "100"
// Or simply:
string scoreText2 = score.ToString();        // "100"

// Between numeric types
double pi = 3.14159;
int roundedPi = Convert.ToInt32(pi);         // 3 (rounds, unlike cast which truncates)
```

### 7.4 Parse & TryParse (String → Number)

This is the **most common conversion** you'll use (especially for user input):

```csharp
// Parse — throws exception if invalid
string input = "42";
int number = int.Parse(input);          // 42 ✅
double price = double.Parse("19.99");   // 19.99 ✅

// int.Parse("hello");  // ❌ FormatException — "hello" is not a number!
```

```csharp
// TryParse — SAFE, returns true/false (RECOMMENDED for user input)
string userInput = Console.ReadLine();

if (int.TryParse(userInput, out int result))
{
    Console.WriteLine($"You entered: {result}");
}
else
{
    Console.WriteLine("That's not a valid number!");
}

// The 'out' keyword means TryParse will store the converted value in 'result'
// if conversion succeeds. If it fails, 'result' will be 0.
```

### 7.5 The `as` and `is` Keywords (for Reference Types)

```csharp
// 'is' — checks if an object is a certain type
object value = "Hello";
if (value is string text)
{
    Console.WriteLine($"It's a string: {text}");
}

// 'as' — tries to cast, returns null if it fails (instead of throwing exception)
object data = "Hello";
string str = data as string;     // "Hello" ✅
int? num = data as int?;         // null (because data is a string, not int)
```

### Conversion Summary:

```
┌─────────────────────────────────────────────────────────┐
│              Type Conversion Methods                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Implicit:     int → long (automatic, safe)              │
│  Explicit:     (int)doubleValue (manual, may lose data)  │
│  Convert:      Convert.ToInt32("42") (utility class)     │
│  Parse:        int.Parse("42") (string→number, throws)   │
│  TryParse:     int.TryParse("42", out x) (safe, no throw)│
│  as/is:        obj is string s (reference type checks)   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 8. String Basics (Deep Dive)

Since strings are the most used data type, let's cover them well:

### Common String Operations:

```csharp
string name = "Debanjan";

// Length
Console.WriteLine(name.Length);          // 8

// Access characters (0-based index)
Console.WriteLine(name[0]);             // 'D'
Console.WriteLine(name[name.Length-1]); // 'n'

// Case conversion
Console.WriteLine(name.ToUpper());      // "DEBANJAN"
Console.WriteLine(name.ToLower());      // "debanjan"

// Trimming whitespace
string padded = "  Hello  ";
Console.WriteLine(padded.Trim());       // "Hello"
Console.WriteLine(padded.TrimStart());  // "Hello  "
Console.WriteLine(padded.TrimEnd());    // "  Hello"

// Searching
Console.WriteLine(name.Contains("jan"));     // True
Console.WriteLine(name.StartsWith("Deb"));   // True
Console.WriteLine(name.EndsWith("jan"));     // True
Console.WriteLine(name.IndexOf("a"));        // 3

// Replacing
Console.WriteLine(name.Replace("jan", "JAN")); // "DebaJAN"

// Substring
Console.WriteLine(name.Substring(0, 3));     // "Deb"
Console.WriteLine(name.Substring(3));        // "anjan"

// Split
string csv = "apple,banana,cherry";
string[] fruits = csv.Split(',');
// fruits[0] = "apple", fruits[1] = "banana", fruits[2] = "cherry"

// Join
string joined = string.Join(" - ", fruits);  // "apple - banana - cherry"
```

### String Formatting Methods:

```csharp
string name = "Debanjan";
int age = 25;

// 1. String Interpolation (RECOMMENDED)
string msg1 = $"Name: {name}, Age: {age}";

// 2. String.Format
string msg2 = string.Format("Name: {0}, Age: {1}", name, age);

// 3. Concatenation (avoid for multiple joins)
string msg3 = "Name: " + name + ", Age: " + age;

// 4. Formatting numbers
double price = 1234.5678;
Console.WriteLine($"Currency: {price:C}");     // Currency: $1,234.57
Console.WriteLine($"Fixed 2dp: {price:F2}");   // Fixed 2dp: 1234.57
Console.WriteLine($"Padded: {price,15:F2}");   // Right-aligned in 15 chars

// 5. Verbatim strings (ignore escape characters)
string path = @"C:\Users\Debanjan\Documents";   // No need to escape backslashes
string multiLine = @"Line 1
Line 2
Line 3";

// 6. Raw string literals (C# 11+)
string json = """
    {
        "name": "Debanjan",
        "age": 25
    }
    """;
```

### Escape Characters:

| Escape | Meaning |
|--------|---------|
| `\n` | New line |
| `\t` | Tab |
| `\\` | Backslash |
| `\"` | Double quote |
| `\0` | Null character |

---

## 9. Putting It All Together — A Practical Example

Let's build a **TaskFlow User Registration** input form:

```csharp
Console.WriteLine("╔═══════════════════════════════════╗");
Console.WriteLine("║     TASKFLOW - USER REGISTRATION  ║");
Console.WriteLine("╚═══════════════════════════════════╝");
Console.WriteLine();

// Collect user input
Console.Write("Enter your full name: ");
string fullName = Console.ReadLine() ?? "Unknown";

Console.Write("Enter your age: ");
string ageInput = Console.ReadLine() ?? "0";

Console.Write("Enter your hourly rate (₹): ");
string rateInput = Console.ReadLine() ?? "0";

Console.Write("Are you a premium member? (true/false): ");
string premiumInput = Console.ReadLine() ?? "false";

// Type conversion with TryParse (SAFE approach)
int age = 0;
if (!int.TryParse(ageInput, out age))
{
    Console.WriteLine("⚠️ Invalid age. Defaulting to 0.");
}

decimal hourlyRate = 0m;
if (!decimal.TryParse(rateInput, out hourlyRate))
{
    Console.WriteLine("⚠️ Invalid rate. Defaulting to 0.");
}

bool isPremium = false;
bool.TryParse(premiumInput, out isPremium);

// Calculations
decimal dailyEarning = hourlyRate * 8;
decimal monthlyEarning = dailyEarning * 22;

// Display formatted output
Console.WriteLine();
Console.WriteLine("╔═══════════════════════════════════╗");
Console.WriteLine("║        REGISTRATION SUMMARY       ║");
Console.WriteLine("╠═══════════════════════════════════╣");
Console.WriteLine($"║  Name:     {fullName,-23} ║");
Console.WriteLine($"║  Age:      {age,-23} ║");
Console.WriteLine($"║  Rate:     {hourlyRate,-23:C} ║");
Console.WriteLine($"║  Daily:    {dailyEarning,-23:C} ║");
Console.WriteLine($"║  Monthly:  {monthlyEarning,-23:C} ║");
Console.WriteLine($"║  Premium:  {(isPremium ? "Yes ⭐" : "No"),-23} ║");
Console.WriteLine("╚═══════════════════════════════════╝");
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Variable** | Named container for storing data |
| **Value Types** | Store actual value (int, double, bool, char, struct) — on Stack |
| **Reference Types** | Store address/reference (string, object, arrays, classes) — on Heap |
| **int** | Default for whole numbers (4 bytes) |
| **double** | Default for decimals (8 bytes) |
| **decimal** | Use for money/financial (16 bytes, suffix `m`) |
| **bool** | true or false |
| **string** | Text — immutable, reference type |
| **var** | Compiler infers type — use when type is obvious |
| **const** | Compile-time constant — never changes |
| **readonly** | Runtime constant — set in constructor |
| **Nullable `?`** | Allows value types to be null: `int?` |
| **`??`** | Null-coalescing: provide default if null |
| **Implicit cast** | Automatic (safe: small → large) |
| **Explicit cast** | Manual with `(type)` — may lose data |
| **Parse** | String → number, throws on failure |
| **TryParse** | String → number, returns bool (SAFE) |
| **Convert** | Utility class for type conversions |

---

## Real-World Use Cases

1. **User Input Processing** — Every web form, API request, or CLI tool must convert strings to proper types. `TryParse` is your best friend for this.
2. **Financial Applications** — Banks and payment systems MUST use `decimal` to avoid rounding errors. Using `double` for money is a classic bug.
3. **Configuration Settings** — Apps read config files as strings and convert them: `"true"` → `bool`, `"8080"` → `int`, `"5.0"` → `double`.
4. **Database Mapping** — When data comes from a database, you convert `DBNull` values using nullable types (`int?`, `string?`).
5. **API JSON Deserialization** — JSON values arrive as strings/objects and are converted to strongly-typed C# models.
6. **TaskFlow Project** — When a user creates a task, the form data (strings) must be converted to proper types: due date (`DateTime`), priority (`int`), is-completed (`bool`), estimated hours (`decimal`).

---
