# Topic 01: Introduction to C# — Interview Questions

---

## Q1. What is C# and what are its key features?
**Answer:**
C# is a modern, object-oriented, type-safe programming language developed by Microsoft as part of the .NET platform. Key features include:
- **Object-Oriented** — supports encapsulation, inheritance, and polymorphism
- **Type-Safe** — prevents unsafe type casts at compile time
- **Managed Code** — memory is managed by the CLR via garbage collection
- **Strongly Typed** — every variable must have a declared type
- **Component-Oriented** — supports properties, events, and attributes natively
- **Interoperability** — can call unmanaged C/C++ code via P/Invoke

---

## Q2. What is the difference between C# and .NET?
**Answer:**
- **.NET** is a platform/runtime (CLR + BCL) that executes code. It includes the runtime engine, base class libraries, and tooling.
- **C#** is a programming language that compiles to CIL (Common Intermediate Language), which is then executed by the .NET runtime.
- You can write .NET applications in C#, F#, or VB.NET — they all run on the same runtime.

---

## Q3. What is the CLR (Common Language Runtime)?
**Answer:**
The CLR is the virtual machine component of the .NET platform. It is responsible for:
- **JIT Compilation** — converting CIL/MSIL to native machine code at runtime
- **Memory Management** — garbage collection and heap management
- **Type Safety** — verifying type correctness before execution
- **Exception Handling** — providing a structured exception model
- **Thread Management** — managing threads and synchronization
- **Security** — enforcing code access security

---

## Q4. What is CIL / MSIL?
**Answer:**
CIL (Common Intermediate Language), formerly called MSIL (Microsoft Intermediate Language), is the CPU-independent instruction set that C# (and other .NET languages) compile to. When you run a .NET app, the CLR's JIT compiler converts CIL to native machine code. This is what makes .NET cross-platform — the same CIL can run on Windows, Linux, or macOS via the appropriate runtime.

---

## Q5. What is the difference between managed and unmanaged code?
**Answer:**
| | Managed Code | Unmanaged Code |
|---|---|---|
| **Memory** | Managed by CLR (garbage collected) | Manually managed (malloc/free) |
| **Safety** | Type-safe, bounds-checked | Can have buffer overflows, dangling pointers |
| **Examples** | C#, VB.NET, F# | C, C++, COM components |
| **Performance** | Slight overhead from GC | Potentially faster, but error-prone |

C# code is managed by default. You can use `unsafe` blocks to write unmanaged-style code.

---

## Q6. What is the difference between value types and reference types?
**Answer:**
| | Value Types | Reference Types |
|---|---|---|
| **Storage** | Stack (usually) | Heap |
| **Assignment** | Copies the value | Copies the reference (both point to same object) |
| **Default value** | Zero/false/null equivalent | `null` |
| **Examples** | `int`, `double`, `bool`, `struct`, `enum` | `class`, `string`, `array`, `delegate` |

```csharp
int a = 5;
int b = a;   // b is an independent copy
b = 10;      // a is still 5

var list1 = new List<int>();
var list2 = list1;   // both refer to the same list
```

---

## Q7. What is boxing and unboxing?
**Answer:**
- **Boxing** — converting a value type to `object` (or an interface type). The value is copied onto the heap.
- **Unboxing** — extracting the value type back from the object. Requires an explicit cast.

```csharp
int num = 42;
object boxed = num;        // Boxing — heap allocation
int unboxed = (int)boxed;  // Unboxing — explicit cast required
```

Boxing has a performance cost due to heap allocation. Avoid it in hot paths — prefer generics (e.g., `List<int>` instead of `ArrayList`).

---

## Q8. What is the garbage collector (GC) and how does it work?
**Answer:**
The GC automatically reclaims memory occupied by objects that are no longer reachable. It uses a **generational** model:
- **Gen 0** — short-lived objects (collected frequently, cheaply)
- **Gen 1** — medium-lived objects (buffer between Gen 0 and Gen 2)
- **Gen 2** — long-lived objects (collected infrequently)

The GC runs when Gen 0 is full, when the system is low on memory, or when `GC.Collect()` is called explicitly (not recommended). Objects with finalizers go through an extra finalization queue step before being collected.

---

## Q9. What is the entry point of a C# application?
**Answer:**
The entry point is the `Main` method inside a class. Supported signatures:
```csharp
static void Main() { }
static void Main(string[] args) { }
static int Main() { return 0; }
static int Main(string[] args) { return 0; }

// Async variants (.NET 5+)
static async Task Main() { }
static async Task<int> Main(string[] args) { }
```
In .NET 6+, **top-level statements** allow you to omit the `Main` method entirely — the compiler generates it automatically.

---

## Q10. What is the difference between `Console.Write` and `Console.WriteLine`?
**Answer:**
- `Console.Write` — outputs text without a newline at the end.
- `Console.WriteLine` — outputs text followed by a newline (`\n`).

```csharp
Console.Write("Hello ");
Console.Write("World");   // Output: Hello World (same line)

Console.WriteLine("Hello");
Console.WriteLine("World"); // Output: Hello\nWorld (separate lines)
```

---

## Q11. What is the `using` directive vs the `using` statement?
**Answer:**
- **`using` directive** (top of file) — imports a namespace so you don't need to fully qualify type names.
  ```csharp
  using System.Collections.Generic; // now you can write List<T> instead of System.Collections.Generic.List<T>
  ```
- **`using` statement** (inside code) — ensures `Dispose()` is called on an `IDisposable` object when the block exits, even on exception.
  ```csharp
  using (var reader = new StreamReader("file.txt"))
  {
      string content = reader.ReadToEnd();
  } // reader.Dispose() called automatically
  ```

---

## Q12. What are namespaces and why are they used?
**Answer:**
Namespaces are logical containers that organize related classes, interfaces, and other types to avoid name collisions. They mirror the folder/project structure in large codebases.

```csharp
namespace MyApp.Data
{
    class UserRepository { }
}

namespace MyApp.Services
{
    class UserService { }
}
```

You access types across namespaces using fully qualified names (`MyApp.Data.UserRepository`) or the `using` directive. The `global::` prefix refers to the root namespace.

---

## Q13. What are the types of JIT compilation in .NET?
**Answer:**
| Type | Description |
|---|---|
| **Normal JIT** | Compiles methods on first call; cached for subsequent calls. Default. |
| **Pre-JIT (NGen / ReadyToRun)** | Compiles the entire assembly to native code ahead of time (AOT). Faster startup; larger disk footprint. |
| **Econo-JIT** | Used on memory-constrained devices; discards compiled code to save memory (not in modern .NET). |

.NET 6+ also introduced **Tiered Compilation**: methods start with a quick low-optimization tier, then are recompiled at a higher tier if called frequently ("hot path" optimization).

---

## Q14. What is the difference between .NET Framework, .NET Core, and modern .NET?
**Answer:**
| | .NET Framework | .NET Core | .NET 5+ (modern .NET) |
|---|---|---|---|
| **Platform** | Windows only | Cross-platform | Cross-platform |
| **Open source** | Partial | Yes | Yes |
| **Side-by-side** | No | Yes | Yes |
| **Performance** | Baseline | Much faster | Fastest |
| **Status** | Maintenance mode | Merged into .NET 5 | Active, yearly releases |

Microsoft merged .NET Core and .NET Framework into a unified platform starting with .NET 5. The name ".NET Core" was dropped. Current LTS releases: .NET 8 (2023), .NET 10 (2025).

---

## Q15. What is an assembly in .NET?
**Answer:**
An assembly is the **fundamental unit of deployment, versioning, and security** in .NET. It is a compiled output file (`.dll` or `.exe`) containing:
- **CIL (bytecode)** — the compiled intermediate language
- **Metadata** — type definitions, member signatures, references
- **Manifest** — assembly identity (name, version, culture, public key)
- **Resources** — embedded strings, images, etc.

Types of assemblies:
- **Private assembly** — in the application's own folder.
- **Shared assembly** — installed in the GAC; shared across applications.
- **Satellite assembly** — contains only localized resources; no code.

```csharp
// Get assembly info at runtime
var asm = Assembly.GetExecutingAssembly();
Console.WriteLine(asm.FullName);   // Name, Version, Culture, PublicKeyToken
```

---

## Q16. What are attributes in C#?
**Answer:**
Attributes are **declarative metadata** attached to types, members, or assemblies. They are stored in the assembly and readable at runtime via reflection.

```csharp
[Obsolete("Use NewMethod() instead.", error: false)]
public void OldMethod() { }

[Serializable]
class Config { }

[HttpGet("/api/users")]
public IActionResult GetUsers() { }

// Custom attribute
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
class AuditAttribute : Attribute
{
    public string Reason { get; }
    public AuditAttribute(string reason) => Reason = reason;
}

[Audit("PCI compliance")]
class PaymentService { }
```

Built-in attributes: `[Obsolete]`, `[Serializable]`, `[DllImport]`, `[Conditional]`, `[CallerMemberName]`, `[Required]`.

---

## Q17. What is reflection in C#?
**Answer:**
Reflection allows you to inspect and interact with type metadata **at runtime** — discover types, members, attributes, and dynamically invoke methods or create instances.

```csharp
Type t = typeof(Person);
Console.WriteLine(t.Name);               // "Person"
Console.WriteLine(t.IsClass);            // true

foreach (var prop in t.GetProperties())
    Console.WriteLine(prop.Name);

// Dynamic invocation
var instance = Activator.CreateInstance(t);
MethodInfo method = t.GetMethod("Greet");
method.Invoke(instance, null);

// Read attributes
var attrs = t.GetCustomAttributes<AuditAttribute>();
```

Reflection is used in dependency injection containers, serialization frameworks, ORMs, and test runners. It is **slower** than direct calls — cache `MethodInfo` / `PropertyInfo` objects when performance matters.

---

## Q18. What are nullable reference types (C# 8+)?
**Answer:**
Nullable reference types (NRT) are a compiler feature that enables **null-safety analysis** for reference types. Enabled with `<Nullable>enable</Nullable>` in the project file.

```csharp
string name = "Debanjan"; // non-nullable — compiler warns if null assigned
string? nullable = null;  // explicitly nullable — must check before dereferencing

void PrintLength(string? s)
{
    // compiler warns here: s might be null
    Console.WriteLine(s.Length); // ⚠️ warning

    // Correct — guard check
    if (s != null)
        Console.WriteLine(s.Length); // ✓ no warning
    Console.WriteLine(s?.Length);    // ✓ null-conditional
}
```

This does **not** change runtime behavior — it is purely a compile-time analysis tool. Use it to make null contracts explicit and eliminate `NullReferenceException` bugs.

---

## Q19. What is the `unsafe` keyword and pointer arithmetic in C#?
**Answer:**
The `unsafe` keyword marks a block or method where you can use **unmanaged pointers** and direct memory manipulation — bypassing the CLR's memory safety guarantees.

```csharp
unsafe void Swap(int* a, int* b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

unsafe
{
    int x = 10, y = 20;
    Swap(&x, &y);
    Console.WriteLine(x); // 20
}
```

Requires `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>` in the project file. Used in high-performance scenarios (image processing, interop with native C libraries). Prefer `Span<T>` and `Memory<T>` over raw pointers in modern .NET.

---

## Q20. What is the Global Assembly Cache (GAC) and is it still relevant?
**Answer:**
The GAC is a **machine-wide repository** for shared .NET assemblies (in .NET Framework). Assemblies installed in the GAC can be shared by multiple applications on the same machine without copying.

Requirements for GAC registration:
- Assembly must have a **strong name** (signed with a public/private key pair).

```shell
gacutil /i MyLibrary.dll   # install
gacutil /l                 # list
```

**Modern relevance:** The GAC is a .NET Framework concept. **.NET Core and .NET 5+** do not use the GAC — they rely on NuGet packages and application-local deployment. The GAC is effectively obsolete for new development.
