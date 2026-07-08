# Topic 06: Arrays and Strings — Interview Questions

---

## Q1. What is the difference between an array and a `List<T>`?
**Answer:**
| | Array (`T[]`) | `List<T>` |
|---|---|---|
| **Size** | Fixed at creation | Dynamic (resizes automatically) |
| **Performance** | Faster random access | Slight overhead for resizing |
| **Type** | Covariant (`object[] = string[]`) | Invariant |
| **Methods** | Limited (Array.Sort, Array.Find…) | Rich API (Add, Remove, Find, Sort…) |
| **Memory** | Contiguous block | Contiguous internal array, doubles when full |

Use arrays for fixed-size collections where performance is critical (buffers, math). Use `List<T>` for most general-purpose collections.

---

## Q2. What is a multidimensional array vs a jagged array?
**Answer:**
- **Multidimensional array** (`T[,]`) — a single rectangular block. All rows have the same length.
- **Jagged array** (`T[][]`) — an array of arrays. Each inner array can have a different length.

```csharp
// Multidimensional — 3 rows × 4 columns
int[,] matrix = new int[3, 4];
int val = matrix[1, 2];

// Jagged — rows of different lengths
int[][] jagged = new int[3][];
jagged[0] = new int[] { 1, 2 };
jagged[1] = new int[] { 3, 4, 5, 6 };
jagged[2] = new int[] { 7 };
```

Jagged arrays are generally **faster** to access because the CLR handles single-dimension arrays more efficiently. Multidimensional arrays are more natural for mathematical grids.

---

## Q3. What is string immutability and why does it matter?
**Answer:**
Strings in C# are **immutable** — once created, the content cannot be changed. Any operation that appears to modify a string actually creates a **new string object**.

```csharp
string s = "Hello";
s = s + " World";  // Creates a new string; original "Hello" is unchanged
```

**Implications:**
- Safe for use as dictionary keys and in multi-threaded code (no shared mutable state).
- String concatenation in a loop allocates many intermediate strings → use `StringBuilder`.
- The **string intern pool** allows the runtime to share identical string literals.

---

## Q4. What is `StringBuilder` and when should you use it?
**Answer:**
`StringBuilder` is a mutable string buffer. It avoids the allocation overhead of repeated string concatenation.

```csharp
// Bad for large loops — O(n²) allocations
string result = "";
for (int i = 0; i < 10000; i++)
    result += i.ToString(); // creates 10000 new strings

// Good — O(n) with StringBuilder
var sb = new StringBuilder();
for (int i = 0; i < 10000; i++)
    sb.Append(i);
string result = sb.ToString();
```

**Rule of thumb:** Use `StringBuilder` when concatenating more than 4–5 strings in a loop. For few fixed concatenations, `$"..."` or `string.Concat` is fine.

---

## Q5. What are the most important string methods?
**Answer:**
```csharp
string s = "  Hello, World!  ";

s.ToUpper()                    // "  HELLO, WORLD!  "
s.ToLower()                    // "  hello, world!  "
s.Trim()                       // "Hello, World!"
s.TrimStart() / s.TrimEnd()    // trim only one side
s.Contains("World")            // true
s.StartsWith("  H")            // true
s.EndsWith("!  ")              // true
s.Replace("World", "C#")       // "  Hello, C#!  "
s.Split(',')                   // ["  Hello", " World!  "]
s.IndexOf("World")             // 8
s.Substring(7, 5)              // "World"
s.Length                       // 17
string.IsNullOrEmpty(s)        // false
string.IsNullOrWhiteSpace("  ") // true
string.Join(", ", array)       // "a, b, c"
```

---

## Q6. What is the difference between `string.Compare()`, `==`, and `.Equals()`?
**Answer:**
- `==` and `.Equals()` — **ordinal** (byte-by-byte) comparison by default. Case-sensitive.
- `string.Compare()` — supports culture-aware and case-insensitive comparisons.

```csharp
string a = "hello";
string b = "HELLO";

a == b                                              // false
a.Equals(b, StringComparison.OrdinalIgnoreCase)     // true
string.Compare(a, b, StringComparison.OrdinalIgnoreCase) // 0 (equal)
```

**Best practice:** For user-facing string comparisons (names, UI), use `StringComparison.CurrentCultureIgnoreCase`. For internal/protocol comparisons, use `StringComparison.Ordinal` or `OrdinalIgnoreCase`.

---

## Q7. What is `string.Format()` vs string interpolation vs composite formatting?
**Answer:**
All three produce the same result, with different syntax:

```csharp
string name = "Debanjan"; double price = 9.99;

string.Format("Name: {0}, Price: {1:C2}", name, price);
$"Name: {name}, Price: {price:C2}";
Console.WriteLine("Name: {0}, Price: {1:C2}", name, price); // composite
```

String interpolation (`$"..."`) is the modern preferred form. All support format specifiers: `C` (currency), `D` (decimal), `F2` (2 decimal places), `yyyy-MM-dd` (dates), etc.

---

## Q8. How do you reverse a string in C#?
**Answer:**
```csharp
// Using LINQ + char array
string reversed = new string("hello".Reverse().ToArray()); // "olleh"

// Using char array manually
char[] chars = "hello".ToCharArray();
Array.Reverse(chars);
string reversed = new string(chars);

// Using StringBuilder
var sb = new StringBuilder();
for (int i = s.Length - 1; i >= 0; i--)
    sb.Append(s[i]);
```

In an interview, mention that naïve character reversal **does not handle surrogate pairs** (emoji / multi-codepoint characters) correctly. A proper implementation uses `StringInfo` for Unicode-aware reversal.

---

## Q9. What is the difference between `Array.Sort()` and LINQ `OrderBy()`?
**Answer:**
| | `Array.Sort()` | LINQ `OrderBy()` |
|---|---|---|
| **Mutates original** | Yes (in-place) | No (returns new `IEnumerable<T>`) |
| **Performance** | O(n log n) — faster (no allocation) | O(n log n) — extra allocation |
| **Stability** | Unstable (uses IntroSort) | Stable (preserves order of equal elements) |
| **Flexibility** | Custom `IComparer<T>` | Any key selector expression |

```csharp
int[] arr = { 3, 1, 2 };
Array.Sort(arr);                            // arr is now { 1, 2, 3 }

var sorted = arr.OrderBy(x => x).ToArray(); // new array
```

---

## Q10. What is the `Span<T>` type and how does it relate to arrays?
**Answer:**
`Span<T>` (C# 7.2+) is a **stack-allocated view** over a contiguous region of memory (array, string, or unmanaged memory) without copying.

```csharp
int[] arr = { 1, 2, 3, 4, 5 };
Span<int> slice = arr.AsSpan(1, 3); // view of elements [2, 3, 4]
slice[0] = 99; // modifies original arr[1]

// Zero-allocation string slicing
ReadOnlySpan<char> span = "Hello, World".AsSpan(7, 5); // "World"
```

`Span<T>` eliminates allocations in hot paths like parsers and serializers. `ReadOnlySpan<T>` is the read-only counterpart, commonly used for string processing.

---

## Q11. What is string interning?
**Answer:**
String interning is a CLR mechanism that maintains a pool of unique string objects. Identical **string literals** are interned automatically — they share the same memory address.

```csharp
string a = "hello";  // interned literal
string b = "hello";  // same interned object
Console.WriteLine(object.ReferenceEquals(a, b)); // true

// Dynamically created strings are NOT interned automatically
string c = new StringBuilder().Append("hello").ToString();
Console.WriteLine(object.ReferenceEquals(a, c)); // false

// Force intern
string d = string.Intern(c);
Console.WriteLine(object.ReferenceEquals(a, d)); // true

// Check if already interned
string e = string.IsInterned(c); // null if not interned
```

Interning saves memory when many identical strings exist (e.g., parsed CSV column names). Interned strings are **never GC'd** for the lifetime of the application.

---

## Q12. What are the `Array.Copy()`, `Array.Clone()`, and `Buffer.BlockCopy()` methods?
**Answer:**
```csharp
int[] source = { 1, 2, 3, 4, 5 };

// Array.Copy — type-safe, works with reference types, performs implicit casts
int[] dest = new int[5];
Array.Copy(source, dest, 5);

// Array.Clone — shallow copy of the entire array
int[] clone = (int[])source.Clone();

// Buffer.BlockCopy — raw byte-level copy (fastest for primitives)
byte[] bytes = new byte[20];
Buffer.BlockCopy(source, 0, bytes, 0, 20); // copies raw bytes

// With ranges (C# 8+)
int[] slice = source[1..4]; // { 2, 3, 4 } — new array
```

`Buffer.BlockCopy` is the fastest for large primitive arrays because it copies raw memory without type checks.

---

## Q13. How do you check if two arrays are equal in C#?
**Answer:**
```csharp
int[] a = { 1, 2, 3 };
int[] b = { 1, 2, 3 };

// WRONG — reference comparison
bool eq1 = a == b;                           // false (different objects)
bool eq2 = a.Equals(b);                     // false

// Correct — element-by-element
bool eq3 = a.SequenceEqual(b);              // true (LINQ)

// For nested/complex comparison
bool eq4 = Enumerable.SequenceEqual(a, b); // same as SequenceEqual

// For spans (zero allocation)
bool eq5 = a.AsSpan().SequenceEqual(b);    // true
```

---

## Q14. What is `string.Empty` vs `""` vs `null`?
**Answer:**
```csharp
string a = "";             // empty string — object exists, Length = 0
string b = string.Empty;   // same as "" — they are the same interned object
string c = null;           // no object — variable holds null reference

bool r1 = a == b;                   // true
bool r2 = object.ReferenceEquals(a, b); // true (both interned)

string.IsNullOrEmpty(null);   // true
string.IsNullOrEmpty("");     // true
string.IsNullOrEmpty("  ");   // false
string.IsNullOrWhiteSpace("  "); // true
```

Use `string.IsNullOrWhiteSpace()` for user-input validation. `string.Empty` is preferred over `""` for clarity but there is zero performance difference.

---

## Q15. What is `Encoding` and why does it matter when reading/writing strings?
**Answer:**
Encoding defines how characters are mapped to bytes. C# strings are **UTF-16** internally, but files/streams can use different encodings:

```csharp
// Default encoding for StreamWriter is UTF-8
using var sw = new StreamWriter("file.txt");                  // UTF-8
using var sw = new StreamWriter("file.txt", Encoding.ASCII);  // ASCII only
using var sw = new StreamWriter("file.txt", Encoding.UTF8);   // UTF-8 with BOM
using var sw = new StreamWriter("file.txt", new UTF8Encoding(encoderShouldEmitUTF8Identifier: false)); // UTF-8 without BOM

// Convert string to bytes
byte[] utf8  = Encoding.UTF8.GetBytes("Hello 世界");
byte[] utf16 = Encoding.Unicode.GetBytes("Hello 世界");

// Convert bytes back to string
string s = Encoding.UTF8.GetString(utf8);
```

Mismatched encodings are a common bug when reading files from external systems. Always specify the encoding explicitly when the source is unknown.
