# Topic 02: Variables, Data Types & Type Conversion — Interview Questions

---

## Q1. What are the built-in value types in C#?
**Answer:**
| Category | Types |
|---|---|
| **Integer** | `sbyte`, `byte`, `short`, `ushort`, `int`, `uint`, `long`, `ulong` |
| **Floating-point** | `float` (32-bit), `double` (64-bit) |
| **High-precision decimal** | `decimal` (128-bit) |
| **Boolean** | `bool` |
| **Character** | `char` (UTF-16, 16-bit) |

Special types: `nint` / `nuint` (native-sized integers, .NET 5+).

---

## Q2. What is the difference between `float`, `double`, and `decimal`?
**Answer:**
| | `float` | `double` | `decimal` |
|---|---|---|---|
| **Size** | 32-bit | 64-bit | 128-bit |
| **Precision** | ~7 digits | ~15-16 digits | 28-29 significant digits |
| **Suffix** | `f` or `F` | (default) | `m` or `M` |
| **Use case** | Graphics, sensors | General math | Financial/monetary |
| **Exact?** | No (binary float) | No (binary float) | Yes (base-10) |

```csharp
double d = 0.1 + 0.2;   // 0.30000000000000004 (floating-point error)
decimal m = 0.1m + 0.2m; // 0.3 (exact)
```

---

## Q3. What is the difference between `int` and `Int32`?
**Answer:**
They are identical — `int` is a C# keyword alias for `System.Int32`. The compiler treats them as the same type.

```csharp
int a = 5;
Int32 b = 5;
// typeof(int) == typeof(Int32) → true
```

Similarly: `bool` = `Boolean`, `string` = `String`, `long` = `Int64`, etc. The convention is to use the keyword alias (`int`, `string`) in code, and the CLR type name (`Int32`, `String`) when accessing static methods like `Int32.MaxValue`.

---

## Q4. What is the difference between `var` and `dynamic`?
**Answer:**
| | `var` | `dynamic` |
|---|---|---|
| **Type resolution** | Compile time (type inferred) | Runtime |
| **Type safety** | Yes — type is fixed after inference | No — any operation allowed at compile time |
| **Performance** | Same as explicit type | Slower (DLR overhead) |
| **IntelliSense** | Full support | Limited |
| **Use case** | Reduce verbosity in obvious cases | COM interop, reflection, scripting, JSON |

```csharp
var x = 42;       // x is int at compile time
x = "hello";      // ❌ Compile error

dynamic d = 42;
d = "hello";      // ✓ OK at compile time — fails/works at runtime
```

---

## Q5. What is implicit vs explicit type conversion?
**Answer:**
- **Implicit conversion** — happens automatically when there is no risk of data loss (widening). The compiler handles it.
- **Explicit conversion (casting)** — required when there is potential data loss (narrowing). You must signal intent.

```csharp
int i = 100;
long l = i;        // Implicit — int fits in long safely
double d = i;      // Implicit — int fits in double safely

double pi = 3.14;
int truncated = (int)pi; // Explicit — loses fractional part → 3
```

---

## Q6. What is the difference between `Convert.ToInt32()`, `(int)`, `int.Parse()`, and `int.TryParse()`?
**Answer:**
| Method | Input | On failure |
|---|---|---|
| `(int)cast` | Numeric types only | `InvalidCastException` |
| `Convert.ToInt32()` | String, object, other numerics | `FormatException` / `OverflowException` |
| `int.Parse()` | String only | `FormatException` / `OverflowException` |
| `int.TryParse()` | String only | Returns `false`, no exception |

**Best practice:** Use `int.TryParse()` when the input may be invalid (user input, file data). Use `int.Parse()` only when the string is guaranteed to be a valid integer.

```csharp
if (int.TryParse(input, out int value))
    Console.WriteLine(value);
else
    Console.WriteLine("Invalid input");
```

---

## Q7. What are nullable value types?
**Answer:**
Normally, value types cannot be `null`. Nullable types (`T?` / `Nullable<T>`) allow value types to hold `null`.

```csharp
int? age = null;      // nullable int
age = 25;

if (age.HasValue)
    Console.WriteLine(age.Value);

int result = age ?? 0; // null-coalescing: use 0 if null
```

Useful for database fields, optional parameters, or representing "not set" scenarios. Under the hood, `int?` is `Nullable<int>`.

---

## Q8. What is the `checked` and `unchecked` keyword?
**Answer:**
- **`checked`** — enables overflow checking. Throws `OverflowException` if an arithmetic operation overflows.
- **`unchecked`** — disables overflow checking (default). Overflow silently wraps around.

```csharp
int max = int.MaxValue;

unchecked
{
    int wrapped = max + 1;  // -2147483648 (wraps silently)
}

checked
{
    int overflow = max + 1; // OverflowException thrown
}
```

Use `checked` arithmetic in financial/security-sensitive code where silent overflow would be a bug.

---

## Q9. What is the difference between `const` and `readonly`?
**Answer:**
| | `const` | `readonly` |
|---|---|---|
| **Set when** | Compile time | Declaration or constructor |
| **Can be `static`?** | Always static (implicitly) | Can be instance or static |
| **Type restriction** | Primitive types and `string` only | Any type |
| **Value** | Inlined by compiler | Stored as a field |

```csharp
const double Pi = 3.14159;     // Compile-time constant
readonly DateTime CreatedAt;    // Set in constructor, then immutable

public MyClass()
{
    CreatedAt = DateTime.Now;  // ✓ Allowed in constructor
}
```

---

## Q10. What is string interpolation and what are the alternatives?
**Answer:**
String interpolation (prefix `$`) embeds expressions directly in string literals:

```csharp
string name = "Debanjan";
int age = 25;

string s1 = $"Name: {name}, Age: {age}";               // Interpolation (C# 6+)
string s2 = string.Format("Name: {0}, Age: {1}", name, age); // Format
string s3 = "Name: " + name + ", Age: " + age;          // Concatenation
```

Interpolation is preferred for readability. You can apply format specifiers: `{price:C2}`, `{date:yyyy-MM-dd}`. For very high-performance scenarios, `string.Create()` or `StringBuilder` may be better.

---

## Q11. What are numeric literal suffixes and digit separators?
**Answer:**
Suffixes disambiguate numeric literal types:

```csharp
long   l  = 100L;
ulong  ul = 100UL;
float  f  = 3.14F;
double d  = 3.14D;   // or just 3.14
decimal m = 3.14M;
uint   u  = 100U;
```

**Digit separators** (`_`) improve readability of large numbers (C# 7+):
```csharp
int million  = 1_000_000;
long big     = 9_223_372_036_854_775_807L;
byte mask    = 0b_1111_0000;   // binary literal
int hex      = 0xFF_AB_CD_EF;  // hex literal
```

---

## Q12. What is a verbatim string literal and a raw string literal?
**Answer:**
**Verbatim string** (`@"..."`) — backslashes are treated as literal characters, not escape sequences. Useful for file paths and regex patterns:

```csharp
string path    = @"C:\Users\Debanjan\docs\file.txt"; // no double-backslash needed
string regex   = @"\d{3}-\d{4}";
string multi   = @"Line 1
Line 2
Line 3";  // preserves newlines
```

**Raw string literal** (`"""..."""`, C# 11+) — no escaping needed at all, including quotes:

```csharp
string json = """
    {
        "name": "Debanjan",
        "age": 25
    }
    """;
```

Indentation is trimmed based on the closing `"""` position.

---

## Q13. What are `nint` and `nuint` (native-sized integers)?
**Answer:**
`nint` and `nuint` (C# 9+) are integer types whose size matches the **native pointer size** of the platform — 32 bits on 32-bit systems, 64 bits on 64-bit systems.

```csharp
nint  ptr = 0x1000;   // 4 bytes on x86, 8 bytes on x64
nuint uptr = 0xFFFF;
```

They map to `System.IntPtr` and `System.UIntPtr` respectively. Primarily used in low-level interop code, unsafe pointer arithmetic, and P/Invoke scenarios.

---

## Q14. What is the difference between `string` (reference type) and value-type-like behavior?
**Answer:**
Although `string` is a **reference type**, it behaves like a value type in practice:
- **Immutable** — content cannot change after creation.
- **Value-based equality** — `==` compares content, not reference.
- **String interning** — identical string literals often share the same object in memory.

```csharp
string a = "hello";
string b = "hello";
Console.WriteLine(object.ReferenceEquals(a, b)); // true  — interned

string c = new string("hello".ToCharArray());
Console.WriteLine(a == c);                        // true  — content equal
Console.WriteLine(object.ReferenceEquals(a, c)); // false — different heap objects
```

---

## Q15. What is `object` and what methods does it expose?
**Answer:**
`System.Object` is the **root of the entire .NET type hierarchy**. Every type — value or reference — ultimately inherits from `object`.

Key members:
| Member | Description |
|---|---|
| `ToString()` | Returns string representation (virtual, override to customize) |
| `Equals(object)` | Value equality (virtual) |
| `GetHashCode()` | Hash for dictionaries/sets (virtual) |
| `GetType()` | Returns `Type` object at runtime (not overridable) |
| `MemberwiseClone()` | Shallow copy (protected) |
| `ReferenceEquals(a, b)` | Checks if two variables point to the exact same object (static) |

```csharp
var x = new Person { Name = "D" };
object o = x;            // implicit upcast (boxing if value type)
Person p = (Person)o;    // explicit downcast
```
