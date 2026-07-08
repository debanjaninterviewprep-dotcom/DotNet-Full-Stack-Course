# Topic 03: Operators and Expressions — Interview Questions

---

## Q1. What is the null-coalescing operator `??` and the null-coalescing assignment `??=`?
**Answer:**
- `??` returns the left operand if it is not null; otherwise returns the right operand.
- `??=` assigns the right-hand value to the variable only if the variable is currently null.

```csharp
string name = null;
string display = name ?? "Unknown";    // "Unknown"

name ??= "Default";                    // name is now "Default" (was null)
name ??= "Other";                      // name stays "Default" (not null)
```

---

## Q2. What is the null-conditional operator `?.` and `?[]`?
**Answer:**
Returns `null` if the object is `null` instead of throwing a `NullReferenceException`.

```csharp
string name = null;
int? length = name?.Length;  // null (not an exception)

List<int>? list = null;
int? first = list?[0];        // null (not an IndexOutOfRangeException)

// Chaining
string city = user?.Address?.City ?? "Unknown";
```

This is called **safe navigation** and is extremely useful when traversing object graphs.

---

## Q3. What is the difference between `==` and `Equals()`?
**Answer:**
- `==` for value types compares values. For reference types, it compares references (unless overloaded).
- `Equals()` is a virtual method that can be overridden to compare values.

```csharp
string a = new string("hello".ToCharArray());
string b = new string("hello".ToCharArray());

Console.WriteLine(a == b);        // true  — string overloads == to compare content
Console.WriteLine(object.ReferenceEquals(a, b)); // false — different objects

int x = 5; int y = 5;
Console.WriteLine(x == y);        // true  — value comparison
Console.WriteLine(x.Equals(y));   // true
```

For custom classes, override both `Equals()` and `GetHashCode()` together.

---

## Q4. What is the ternary (conditional) operator?
**Answer:**
The ternary operator `? :` is a compact `if-else` expression:

```csharp
int age = 20;
string status = age >= 18 ? "Adult" : "Minor";
```

It returns one of two values based on a boolean condition. Avoid nesting ternaries — it hurts readability.

---

## Q5. What is the difference between `is` and `as` operators?
**Answer:**
- `is` — checks if an object is of a given type. Returns `bool`. Can also bind to a variable (pattern matching).
- `as` — attempts a cast; returns `null` if it fails (no exception). Only works with reference types and nullable types.

```csharp
object obj = "Hello";

if (obj is string s)          // Pattern matching — type check + cast in one
    Console.WriteLine(s.ToUpper());

string result = obj as string; // result is "Hello"
int? num = obj as int?;        // num is null (obj is not int)
```

**Prefer `is` with pattern matching** over `as` + null check in modern C#.

---

## Q6. What is the difference between `&`/`|` and `&&`/`||`?
**Answer:**
- `&&` and `||` are **short-circuit** operators — the right operand is only evaluated if needed.
- `&` and `|` are **non-short-circuit** (bitwise) — both operands are always evaluated.

```csharp
string s = null;

// Safe — short-circuit prevents NullReferenceException
if (s != null && s.Length > 0) { }

// Dangerous — s.Length throws even if s is null
if (s != null & s.Length > 0) { }
```

Use `&&` and `||` for boolean logic. Use `&` and `|` for bitwise operations on integers.

---

## Q7. What is operator overloading?
**Answer:**
C# allows you to define custom behaviour for operators on your own types using the `operator` keyword.

```csharp
class Vector
{
    public int X, Y;
    public Vector(int x, int y) { X = x; Y = y; }

    public static Vector operator +(Vector a, Vector b)
        => new Vector(a.X + b.X, a.Y + b.Y);

    public static bool operator ==(Vector a, Vector b)
        => a.X == b.X && a.Y == b.Y;
}

var v1 = new Vector(1, 2);
var v2 = new Vector(3, 4);
var v3 = v1 + v2; // X=4, Y=6
```

Rules: overloadable operators include `+`, `-`, `*`, `/`, `==`, `!=`, `>`, `<`, etc. If you overload `==`, you must also overload `!=`. You must also override `Equals()` and `GetHashCode()`.

---

## Q8. What are the bitwise operators and when are they used?
**Answer:**
| Operator | Name | Example |
|---|---|---|
| `&` | AND | `5 & 3` → `1` |
| `\|` | OR | `5 \| 3` → `7` |
| `^` | XOR | `5 ^ 3` → `6` |
| `~` | NOT (complement) | `~5` → `-6` |
| `<<` | Left shift | `1 << 3` → `8` |
| `>>` | Right shift | `8 >> 1` → `4` |

Common uses: flags/permissions using `[Flags]` enums, low-level hardware/protocol code, hash functions.

```csharp
[Flags]
enum Permissions { None = 0, Read = 1, Write = 2, Execute = 4 }

var perms = Permissions.Read | Permissions.Write;  // 3
bool canRead = (perms & Permissions.Read) != 0;     // true
```

---

## Q9. What is the `nameof` operator?
**Answer:**
`nameof` returns the simple name (string) of a variable, type, or member at compile time. It avoids hard-coded strings that break during refactoring.

```csharp
public void SetName(string name)
{
    if (name == null)
        throw new ArgumentNullException(nameof(name)); // "name" — refactor-safe
}

Console.WriteLine(nameof(DateTime.Now)); // "Now"
Console.WriteLine(nameof(List<int>));    // "List"
```

---

## Q10. What is the `sizeof` operator?
**Answer:**
`sizeof` returns the size in bytes of an unmanaged value type at compile time:

```csharp
Console.WriteLine(sizeof(int));     // 4
Console.WriteLine(sizeof(double));  // 8
Console.WriteLine(sizeof(bool));    // 1
Console.WriteLine(sizeof(char));    // 2
```

For custom structs with only primitive fields, it can be used in an `unsafe` context. For reference types or complex structs, use `Marshal.SizeOf()` instead.

---

## Q11. What is operator precedence and associativity in C#?
**Answer:**
Operator precedence determines the **order of evaluation**. Higher-precedence operators bind more tightly.

Simplified precedence (high → low):
```
1.  x.y  x?.y  x?[y]  f(x)  a[x]  x++  x--  new  typeof  sizeof
2.  +x  -x  !  ~  ++x  --x  (T)x  await
3.  *  /  %
4.  +  -
5.  <<  >>  >>>
6.  <  >  <=  >=  is  as
7.  ==  !=
8.  &
9.  ^
10. |
11. &&
12. ||
13. ??
14. ?:  (ternary)
15. =  +=  -=  *=  /=  %=  etc.
```

Associativity is left-to-right for most operators; assignment and ternary are right-to-left.

```csharp
int result = 2 + 3 * 4;    // 14 (not 20) — * binds tighter than +
bool x = true || false && false; // true — && binds tighter than ||
```

---

## Q12. What are the index (`^`) and range (`..`) operators (C# 8+)?
**Answer:**
These operators work with arrays, `Span<T>`, strings, and any type that supports `Index`/`Range`:

```csharp
int[] arr = { 0, 1, 2, 3, 4 };

// ^ operator — index from end (^1 is last element)
int last   = arr[^1];    // 4
int second = arr[^2];    // 3

// .. operator — range (start inclusive, end exclusive)
int[] slice = arr[1..4];  // { 1, 2, 3 }
int[] last2  = arr[^2..]; // { 3, 4 }
int[] all    = arr[..];   // full copy

string s = "Hello, World!";
string world = s[7..12];  // "World"
```

---

## Q13. What is the `typeof()` operator vs `GetType()`?
**Answer:**
- `typeof(T)` — **compile-time** operator; returns the `Type` object for a known type. Works with generic type parameters.
- `GetType()` — **runtime** method on any object; returns the actual runtime type of the instance.

```csharp
Type t1 = typeof(string);         // compile-time — always System.String
Type t2 = "hello".GetType();      // runtime  — System.String
Type t3 = typeof(List<int>);      // works with constructed generics

object obj = new Dog();
Console.WriteLine(obj.GetType()); // Dog (not Animal)
Console.WriteLine(obj is Animal); // true (is checks inheritance)

// typeof cannot call on an instance
// obj.GetType() != typeof(obj) — typeof needs a type name, not a variable
```

---

## Q14. What is the difference between `i++` (postfix) and `++i` (prefix)?
**Answer:**
- **`i++`** (postfix) — returns the **current** value, then increments.
- **`++i`** (prefix) — increments first, then returns the **new** value.

```csharp
int i = 5;
int a = i++;   // a = 5, i = 6
int b = ++i;   // i = 7, b = 7

// In a loop, both are equivalent — no observable difference
for (int j = 0; j < 10; j++) { }  // same as ++j for the loop variable
```

In modern C# with primitives, the performance difference is zero. In operator-overloaded types (iterators, custom types), prefer `++i` to avoid creating a temporary copy.

---

## Q15. What is the `with` expression for records and structs?
**Answer:**
`with` (C# 9+) creates a **copy** of a record or struct with specified properties changed — it does not mutate the original:

```csharp
record Person(string Name, int Age, string City);

var p1 = new Person("Debanjan", 25, "Delhi");
var p2 = p1 with { Age = 26 };            // new record, same Name and City
var p3 = p1 with { Age = 26, City = "Mumbai" };

Console.WriteLine(p1); // Person { Name = Debanjan, Age = 25, City = Delhi }
Console.WriteLine(p2); // Person { Name = Debanjan, Age = 26, City = Delhi }
```

`with` also works on `struct` types (C# 10+). Under the hood it calls `Clone()` and sets the specified properties.
