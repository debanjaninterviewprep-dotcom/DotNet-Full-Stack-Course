# Phase 1 | Topic 6: Arrays & Strings

---

## 1. What is an Array?

An array is a **fixed-size collection** of elements of the **same type**, stored in **contiguous memory** locations. Each element has an **index** (position number) starting from **0**.

```
Index:    [0]      [1]      [2]      [3]      [4]
Value:  | "Code" | "Test" | "Deploy"| "Review"| "Ship" |
         ────────────────────────────────────────────────
         One contiguous block of memory
```

Think of it like a **row of lockers** — each locker has a number (index) and holds one item.

---

## 2. Declaring & Initializing Arrays

### Different Ways to Create Arrays:

```csharp
// 1. Declare with size (elements get default values)
int[] scores = new int[5];          // [0, 0, 0, 0, 0]
string[] names = new string[3];     // [null, null, null]
bool[] flags = new bool[4];         // [false, false, false, false]

// 2. Declare and initialize with values
int[] scores2 = new int[] { 85, 92, 78, 95, 88 };

// 3. Shorthand (type inferred)
int[] scores3 = { 85, 92, 78, 95, 88 };

// 4. Using var
var scores4 = new int[] { 85, 92, 78, 95, 88 };

// 5. Using new[] (type inferred from values)
var scores5 = new[] { 85, 92, 78, 95, 88 };
```

---

## 3. Accessing & Modifying Elements

```csharp
string[] tasks = { "Code", "Test", "Deploy", "Review", "Ship" };

// Access by index (0-based)
Console.WriteLine(tasks[0]);      // "Code" (first element)
Console.WriteLine(tasks[4]);      // "Ship" (last element)
Console.WriteLine(tasks[^1]);     // "Ship" (last element — C# 8+ index from end)
Console.WriteLine(tasks[^2]);     // "Review" (second from end)

// Modify by index
tasks[1] = "Unit Test";           // Changed "Test" → "Unit Test"

// Array length
Console.WriteLine(tasks.Length);   // 5

// ⚠️ Index out of bounds — RUNTIME ERROR
// Console.WriteLine(tasks[5]);   // IndexOutOfRangeException!

// Access last element safely
Console.WriteLine(tasks[tasks.Length - 1]);  // "Ship"
Console.WriteLine(tasks[^1]);                // "Ship" (modern way)
```

---

## 4. Iterating Over Arrays

### for Loop (when you need the index):

```csharp
int[] scores = { 85, 92, 78, 95, 88 };

for (int i = 0; i < scores.Length; i++)
{
    Console.WriteLine($"Student {i + 1}: {scores[i]}");
}
```

### foreach Loop (when you just need values):

```csharp
string[] tasks = { "Code", "Test", "Deploy" };

foreach (string task in tasks)
{
    Console.WriteLine($"📌 {task}");
}
```

### Backward Iteration:

```csharp
for (int i = scores.Length - 1; i >= 0; i--)
{
    Console.WriteLine($"[{i}] = {scores[i]}");
}
```

---

## 5. Common Array Operations

### Sorting:

```csharp
int[] numbers = { 42, 17, 95, 3, 68, 21 };

// Sort ascending
Array.Sort(numbers);
// numbers = { 3, 17, 21, 42, 68, 95 }

// Sort descending
Array.Sort(numbers);
Array.Reverse(numbers);
// numbers = { 95, 68, 42, 21, 17, 3 }

// Sort strings alphabetically
string[] names = { "Charlie", "Alice", "Bob" };
Array.Sort(names);
// names = { "Alice", "Bob", "Charlie" }
```

### Searching:

```csharp
int[] numbers = { 42, 17, 95, 3, 68, 21 };

// Find index of a value
int index = Array.IndexOf(numbers, 95);    // 2
int notFound = Array.IndexOf(numbers, 100); // -1 (not found)

// Check if contains
bool hasIt = Array.Exists(numbers, x => x == 95);  // true

// Find first element matching condition
int firstBig = Array.Find(numbers, x => x > 50);   // 95
int[] allBig = Array.FindAll(numbers, x => x > 50); // { 95, 68 }
```

### Copying:

```csharp
int[] original = { 1, 2, 3, 4, 5 };

// Copy to new array
int[] copy = new int[5];
Array.Copy(original, copy, 5);    // copy = { 1, 2, 3, 4, 5 }

// Clone (creates a shallow copy)
int[] clone = (int[])original.Clone();

// Resize (creates new array, copies elements)
int[] data = { 1, 2, 3 };
Array.Resize(ref data, 5);        // data = { 1, 2, 3, 0, 0 }

// ⚠️ Important: Arrays are FIXED size. Resize creates a NEW array and copies.
```

### Filling & Clearing:

```csharp
int[] scores = new int[5];
Array.Fill(scores, 100);          // { 100, 100, 100, 100, 100 }

Array.Clear(scores, 0, 3);        // { 0, 0, 0, 100, 100 } (clear first 3)
```

---

## 6. Multi-Dimensional Arrays

### 2D Arrays (Matrix/Grid):

```csharp
// Declare a 3x3 grid
int[,] grid = new int[3, 3];

// Declare and initialize
int[,] matrix = {
    { 1, 2, 3 },
    { 4, 5, 6 },
    { 7, 8, 9 }
};

// Access elements: matrix[row, column]
Console.WriteLine(matrix[0, 0]);   // 1 (top-left)
Console.WriteLine(matrix[1, 2]);   // 6 (row 1, col 2)
Console.WriteLine(matrix[2, 2]);   // 9 (bottom-right)

// Get dimensions
int rows = matrix.GetLength(0);    // 3
int cols = matrix.GetLength(1);    // 3

// Iterate over 2D array
for (int row = 0; row < rows; row++)
{
    for (int col = 0; col < cols; col++)
    {
        Console.Write($"{matrix[row, col],4}");
    }
    Console.WriteLine();
}
/*
Output:
   1   2   3
   4   5   6
   7   8   9
*/
```

### Jagged Arrays (Array of Arrays — Different Row Lengths):

```csharp
// Jagged array — each row can have different length
int[][] jagged = new int[3][];
jagged[0] = new int[] { 1, 2 };
jagged[1] = new int[] { 3, 4, 5, 6 };
jagged[2] = new int[] { 7 };

// Shorthand
int[][] jagged2 = {
    new[] { 1, 2 },
    new[] { 3, 4, 5, 6 },
    new[] { 7 }
};

// Access
Console.WriteLine(jagged[1][2]);   // 5

// Iterate
for (int i = 0; i < jagged.Length; i++)
{
    for (int j = 0; j < jagged[i].Length; j++)
    {
        Console.Write($"{jagged[i][j]} ");
    }
    Console.WriteLine();
}
```

### 2D Array vs Jagged Array:

```
2D Array (int[,]):              Jagged Array (int[][]):
┌───┬───┬───┐                  ┌───┬───┐
│ 1 │ 2 │ 3 │                  │ 1 │ 2 │
├───┼───┼───┤                  ├───┼───┼───┼───┐
│ 4 │ 5 │ 6 │                  │ 3 │ 4 │ 5 │ 6 │
├───┼───┼───┤                  ├───┤
│ 7 │ 8 │ 9 │                  │ 7 │
└───┴───┴───┘                  └───┘
Fixed rectangular shape         Variable row lengths
```

---

## 7. Array Slicing with Ranges (C# 8+)

```csharp
int[] numbers = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };

// Ranges using ..
int[] first3 = numbers[..3];      // { 0, 1, 2 }
int[] last3 = numbers[^3..];      // { 7, 8, 9 }
int[] middle = numbers[3..7];     // { 3, 4, 5, 6 }
int[] allButFirstAndLast = numbers[1..^1]; // { 1, 2, 3, 4, 5, 6, 7, 8 }

// Create a Range variable
Range r = 2..5;
int[] slice = numbers[r];         // { 2, 3, 4 }
```

---

## 8. Strings — Deep Dive

A `string` in C# is essentially a **read-only array of characters**. Many array concepts apply to strings.

### String as a Character Array:

```csharp
string name = "Debanjan";

// Access characters by index
char first = name[0];      // 'D'
char last = name[^1];      // 'n'

// Iterate over characters
foreach (char c in name)
{
    Console.Write($"{c} ");
}
// D e b a n j a n

// Convert to char array
char[] chars = name.ToCharArray();
Array.Reverse(chars);
string reversed = new string(chars);   // "najnabeD"
```

### String Comparison:

```csharp
string a = "Hello";
string b = "hello";

// == compares content (not reference) for strings
Console.WriteLine(a == b);              // false (case-sensitive)

// Case-insensitive comparison
Console.WriteLine(a.Equals(b, StringComparison.OrdinalIgnoreCase));   // true

// CompareTo (for sorting order)
Console.WriteLine("apple".CompareTo("banana"));   // negative (apple comes before banana)
Console.WriteLine("banana".CompareTo("apple"));   // positive (banana comes after apple)
Console.WriteLine("apple".CompareTo("apple"));    // 0 (equal)
```

### String Searching:

```csharp
string text = "The quick brown fox jumps over the lazy dog";

Console.WriteLine(text.Contains("fox"));          // True
Console.WriteLine(text.Contains("cat"));          // False
Console.WriteLine(text.StartsWith("The"));        // True
Console.WriteLine(text.EndsWith("dog"));          // True
Console.WriteLine(text.IndexOf("fox"));           // 16
Console.WriteLine(text.LastIndexOf("the"));       // 31
Console.WriteLine(text.Count(c => c == 'o'));     // 4 (using LINQ)
```

### String Modification (Remember: Strings are IMMUTABLE):

```csharp
string original = "Hello, World!";

// All these create NEW strings — original is unchanged
string upper = original.ToUpper();                   // "HELLO, WORLD!"
string lower = original.ToLower();                   // "hello, world!"
string replaced = original.Replace("World", "C#");   // "Hello, C#!"
string inserted = original.Insert(7, "Beautiful ");   // "Hello, Beautiful World!"
string removed = original.Remove(5);                  // "Hello"
string sub = original.Substring(7, 5);               // "World"
string trimmed = "  Hello  ".Trim();                  // "Hello"
string padded = "Hi".PadLeft(10, '*');                // "********Hi"

Console.WriteLine(original);   // Still "Hello, World!" — unchanged!
```

### String Splitting & Joining:

```csharp
// Split a string into an array
string csv = "Debanjan,25,Kolkata,Developer";
string[] parts = csv.Split(',');
// parts = ["Debanjan", "25", "Kolkata", "Developer"]

// Split with multiple delimiters
string messy = "apple;banana,cherry orange";
string[] fruits = messy.Split(new[] { ';', ',', ' ' });
// fruits = ["apple", "banana", "cherry", "orange"]

// Join an array into a string
string[] tags = { "C#", "dotnet", "azure" };
string tagLine = string.Join(", ", tags);     // "C#, dotnet, azure"
string hashTags = string.Join(" ", tags.Select(t => $"#{t}"));  // "#C# #dotnet #azure"
```

### StringBuilder (For Many Concatenations):

```csharp
using System.Text;

// ❌ BAD — creates a new string object EACH time (slow for loops)
string result = "";
for (int i = 0; i < 10000; i++)
{
    result += i.ToString();   // Creates 10,000 new string objects!
}

// ✅ GOOD — StringBuilder modifies in place (fast)
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 10000; i++)
{
    sb.Append(i);
}
string result2 = sb.ToString();

// StringBuilder methods
sb.Append("Hello");          // Add to end
sb.AppendLine(" World");     // Add with newline
sb.Insert(0, "Start: ");     // Insert at position
sb.Replace("Hello", "Hi");   // Replace text
sb.Remove(0, 7);             // Remove characters
sb.Clear();                  // Clear everything
```

### When to Use StringBuilder:
```
String concatenation in a loop  → StringBuilder ✅
2-3 concatenations              → Regular string + or $ ✅
Building HTML/SQL/JSON strings  → StringBuilder ✅
Simple formatting               → String interpolation ✅
```

---

## 9. Useful String Methods Reference

| Method | Description | Example |
|--------|-------------|---------|
| `.Length` | Number of characters | `"Hello".Length` → 5 |
| `.ToUpper()` | Convert to uppercase | `"hi".ToUpper()` → "HI" |
| `.ToLower()` | Convert to lowercase | `"HI".ToLower()` → "hi" |
| `.Trim()` | Remove whitespace from both ends | `" hi ".Trim()` → "hi" |
| `.Contains()` | Check if substring exists | `"hello".Contains("ell")` → true |
| `.StartsWith()` | Check prefix | `"hello".StartsWith("hel")` → true |
| `.EndsWith()` | Check suffix | `"hello".EndsWith("llo")` → true |
| `.IndexOf()` | Find first occurrence | `"hello".IndexOf('l')` → 2 |
| `.LastIndexOf()` | Find last occurrence | `"hello".LastIndexOf('l')` → 3 |
| `.Substring()` | Extract portion | `"hello".Substring(1, 3)` → "ell" |
| `.Replace()` | Replace text | `"hi".Replace("hi", "bye")` → "bye" |
| `.Split()` | Split into array | `"a,b,c".Split(',')` → ["a","b","c"] |
| `.Insert()` | Insert at position | `"hi".Insert(2, "!")` → "hi!" |
| `.Remove()` | Remove characters | `"hello".Remove(3)` → "hel" |
| `.PadLeft()` | Pad on left | `"5".PadLeft(3, '0')` → "005" |
| `.PadRight()` | Pad on right | `"hi".PadRight(5)` → "hi   " |
| `string.IsNullOrEmpty()` | Check null or "" | `string.IsNullOrEmpty("")` → true |
| `string.IsNullOrWhiteSpace()` | Check null or whitespace | `string.IsNullOrWhiteSpace(" ")` → true |
| `string.Join()` | Join array | `string.Join("-", arr)` |
| `string.Concat()` | Concatenate | `string.Concat("a", "b")` → "ab" |

---

## 10. Putting It All Together — Practical Example

### TaskFlow Task Board:

```csharp
using System.Text;

Console.WriteLine("╔═══════════════════════════════════════╗");
Console.WriteLine("║     TASKFLOW - TASK BOARD              ║");
Console.WriteLine("╚═══════════════════════════════════════╝");

// Task data stored in parallel arrays
string[] taskNames = { "Fix login bug", "Update dashboard", "Write API docs", "Deploy v2.0", "Code review" };
string[] priorities = { "High", "Medium", "High", "Critical", "Low" };
bool[] completed = { true, false, false, true, false };

// Display all tasks using arrays
Console.WriteLine("\n📋 ALL TASKS:");
Console.WriteLine(new string('─', 55));
Console.WriteLine($"{"#",-4} {"Task",-25} {"Priority",-12} {"Status",-10}");
Console.WriteLine(new string('─', 55));

for (int i = 0; i < taskNames.Length; i++)
{
    string status = completed[i] ? "✅ Done" : "⬜ Pending";
    Console.WriteLine($"{i + 1,-4} {taskNames[i],-25} {priorities[i],-12} {status,-10}");
}

// Statistics
int totalTasks = taskNames.Length;
int completedCount = completed.Count(c => c);
int pendingCount = totalTasks - completedCount;
double progressPercent = (double)completedCount / totalTasks * 100;

// Using StringBuilder for the report
StringBuilder report = new StringBuilder();
report.AppendLine();
report.AppendLine("📊 TASK STATISTICS:");
report.AppendLine(new string('─', 30));
report.AppendLine($"Total:     {totalTasks}");
report.AppendLine($"Completed: {completedCount}");
report.AppendLine($"Pending:   {pendingCount}");
report.AppendLine($"Progress:  {progressPercent:F1}%");

// Progress bar using string multiplication
int barLength = 20;
int filledBars = (int)(progressPercent / 100 * barLength);
string progressBar = new string('█', filledBars) + new string('░', barLength - filledBars);
report.AppendLine($"[{progressBar}] {progressPercent:F0}%");

Console.WriteLine(report.ToString());

// Search for high priority tasks
Console.WriteLine("🔴 HIGH PRIORITY TASKS:");
for (int i = 0; i < taskNames.Length; i++)
{
    if (priorities[i].Equals("High", StringComparison.OrdinalIgnoreCase) || 
        priorities[i].Equals("Critical", StringComparison.OrdinalIgnoreCase))
    {
        string status = completed[i] ? "Done" : "⚠️ PENDING";
        Console.WriteLine($"  → {taskNames[i]} [{status}]");
    }
}

// String manipulation — generate task slugs
Console.WriteLine("\n🔗 TASK SLUGS:");
foreach (string task in taskNames)
{
    string slug = task.ToLower().Replace(" ", "-");
    Console.WriteLine($"  {task} → /tasks/{slug}");
}
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **Array** | Fixed-size, same-type collection with 0-based indexing |
| **Declaration** | `int[] arr = new int[5];` or `int[] arr = { 1, 2, 3 };` |
| **Access** | `arr[0]` (first), `arr[^1]` (last — C# 8+) |
| **Length** | `arr.Length` — total number of elements |
| **Sort** | `Array.Sort(arr)` — sorts in place |
| **Search** | `Array.IndexOf()`, `Array.Find()`, `Array.Exists()` |
| **Copy** | `Array.Copy()`, `.Clone()` — creates copies |
| **2D Array** | `int[,] grid` — fixed rectangular grid |
| **Jagged Array** | `int[][] jagged` — array of arrays, variable lengths |
| **Ranges** | `arr[1..4]`, `arr[^3..]` — C# 8+ slicing |
| **String immutability** | Strings can't be changed — operations create new strings |
| **StringBuilder** | Use for many concatenations (loops) — mutable & fast |
| **Split/Join** | `str.Split(',')` → array, `string.Join(",", arr)` → string |
| **String methods** | `.Contains()`, `.Replace()`, `.Substring()`, `.Trim()`, etc. |

---

## Real-World Use Cases

1. **Data Processing** — Arrays hold records from CSV files, database queries, API responses. Loop through to transform, filter, aggregate.
2. **Batch Operations** — Process 1000 emails, 500 images, 200 database records stored in arrays.
3. **Game Development** — 2D arrays represent game boards (chess, tic-tac-toe, minesweeper).
4. **String Parsing** — Parse CSV files (`Split`), build HTML/JSON (`StringBuilder`), clean user input (`Trim`, `Replace`).
5. **Search & Filter** — Find matching items in product catalogs, filter tasks by keyword, search through logs.
6. **TaskFlow Project** — Store tasks in arrays, display as tables, filter by priority/status, generate URL slugs from task names, build report strings.

---
