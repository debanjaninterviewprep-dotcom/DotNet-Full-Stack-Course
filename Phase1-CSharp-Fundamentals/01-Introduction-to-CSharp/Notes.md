# Phase 1 | Topic 1: Introduction to C#, .NET Ecosystem & Your First Program

---

## 1. What is C#?

C# (pronounced "C-sharp") is a **modern, object-oriented, type-safe** programming language developed by **Microsoft** in 2000, led by **Anders Hejlsberg**.

Think of C# as the language you *speak* to tell the computer what to do — just like English is a language for humans.

### Key Characteristics:
- **Strongly Typed** — Every variable must have a declared type (prevents bugs early)
- **Object-Oriented** — Everything revolves around "objects" (we'll master this later)
- **Managed Language** — Memory is handled for you (Garbage Collection)
- **Cross-Platform** — Runs on Windows, macOS, Linux (via .NET)
- **Versatile** — Web apps, desktop apps, mobile apps, games (Unity), cloud services

---

## 2. What is .NET?

.NET is the **platform/framework** that runs your C# code. Think of it like this:

```
C# = The Language (what you write)
.NET = The Engine (what runs your code)
```

### .NET Evolution (Brief History):

| Year | Framework | Notes |
|------|-----------|-------|
| 2002 | .NET Framework | Windows only |
| 2016 | .NET Core | Cross-platform, open-source |
| 2020 | .NET 5 | Unified platform (Core + Framework merged) |
| 2024 | .NET 8 | Latest LTS (Long Term Support) |
| 2025 | .NET 9 | Current release |

### Key Components of .NET:

```
┌─────────────────────────────────────┐
│            Your C# Code             │
├─────────────────────────────────────┤
│      .NET SDK (Compiler, CLI)       │
├─────────────────────────────────────┤
│    CLR (Common Language Runtime)    │  ← Executes your code
├─────────────────────────────────────┤
│    BCL (Base Class Library)         │  ← Built-in useful code
├─────────────────────────────────────┤
│        Operating System             │
└─────────────────────────────────────┘
```

- **CLR (Common Language Runtime)**: The engine that actually runs your code. It handles memory management, security, and converts your C# into machine code.
- **BCL (Base Class Library)**: Pre-written code you can use (like `Console.WriteLine`, file operations, networking, etc.)
- **SDK (Software Development Kit)**: Tools to build, run, and publish your apps.

### How C# Code Runs:

```
C# Source Code (.cs)
       ↓  [Compiler]
IL Code (Intermediate Language) → stored in .dll / .exe
       ↓  [CLR / JIT Compiler]
Machine Code → runs on your CPU
```

This two-step compilation is why .NET is **cross-platform** — the IL code is the same everywhere; only the JIT step adapts to the specific OS/CPU.

---

## 3. Setting Up Your Environment

### What You Need:
1. **.NET SDK** — Download from https://dotnet.microsoft.com/download
2. **Visual Studio 2022** (recommended) or **VS Code** with C# extension

### Verify Installation:
Open a terminal and run:
```bash
dotnet --version
```
You should see something like `8.0.x` or `9.0.x`.

---

## 4. Your First C# Program

### Step 1: Create a new project
```bash
dotnet new console -n HelloWorld
cd HelloWorld
```

This creates a **Console Application** — a program that runs in the terminal.

### Step 2: Look at the generated code

Open `Program.cs`:

```csharp
// Program.cs (Modern - Top-level statements, .NET 6+)
Console.WriteLine("Hello, World!");
```

Wait — that's it? Just ONE line? Yes! Modern C# uses **top-level statements** which removes boilerplate. But let's understand what's hiding behind this simplicity.

### Step 3: The Classic (Explicit) Version

```csharp
// Program.cs (Classic/Explicit version)
using System;                          // Import the System namespace

namespace HelloWorld                   // Your project's namespace (like a folder for code)
{
    class Program                      // A class — the container for your code
    {
        static void Main(string[] args)  // Entry point — where the program starts
        {
            Console.WriteLine("Hello, World!");  // Print to terminal
            Console.ReadLine();                   // Wait for user input before closing
        }
    }
}
```

### Breaking It Down:

| Code | What It Does |
|------|-------------|
| `using System;` | Imports the `System` namespace (gives access to `Console`, etc.) |
| `namespace HelloWorld` | Groups your code under a name (avoids naming conflicts) |
| `class Program` | A class is a blueprint/container for code |
| `static void Main(string[] args)` | The **entry point** — the first method that runs |
| `Console.WriteLine(...)` | Prints text to the terminal with a new line |
| `Console.ReadLine()` | Waits for the user to type something and press Enter |

### Step 4: Run it
```bash
dotnet run
```

Output:
```
Hello, World!
```

---

## 5. Understanding the Basics Deeper

### Namespaces
Think of namespaces like **folders** for your code. They prevent naming conflicts.

```csharp
// Without namespaces, if two libraries both have a class called "Logger", 
// there's a conflict. Namespaces solve this:

MyApp.Logging.Logger     // Your logger
ThirdParty.Logging.Logger // Someone else's logger
```

### The `Main` Method
- `static` — Can be called without creating an object
- `void` — Returns nothing
- `Main` — Special name recognized by .NET as the starting point
- `string[] args` — Command line arguments (we'll use these later)

### Console Input/Output

```csharp
// OUTPUT
Console.WriteLine("Hello!");          // Prints with newline
Console.Write("Hello ");              // Prints WITHOUT newline
Console.Write("World!");              // These two appear on same line: "Hello World!"

// INPUT
Console.Write("Enter your name: ");
string name = Console.ReadLine();     // Reads a full line of text
Console.WriteLine($"Hello, {name}!"); // String interpolation ($ sign)
```

### String Interpolation (`$"..."`)
Instead of concatenating strings the old way:
```csharp
// Old way (messy)
Console.WriteLine("Hello, " + name + "! You are " + age + " years old.");

// Modern way (clean) — use $ before the string
Console.WriteLine($"Hello, {name}! You are {age} years old.");
```

### Comments
```csharp
// This is a single-line comment

/* 
   This is a 
   multi-line comment 
*/

/// <summary>
/// This is an XML doc comment (used for documentation)
/// </summary>
```

---

## 6. A Practical Example

Let's build a simple **Greeting Program**:

```csharp
// Program.cs
using System;

Console.WriteLine("=== Welcome to TaskFlow ===");   // Our future project name!
Console.Write("What is your name? ");
string name = Console.ReadLine();

Console.Write("What is your role? (Developer/Designer/Manager): ");
string role = Console.ReadLine();

Console.WriteLine();
Console.WriteLine($"Hello, {name}!");
Console.WriteLine($"Role: {role}");
Console.WriteLine($"Date: {DateTime.Now.ToString("MMMM dd, yyyy")}");
Console.WriteLine("Let's build something amazing together!");
```

**Output:**
```
=== Welcome to TaskFlow ===
What is your name? Debanjan
What is your role? (Developer/Designer/Manager): Developer

Hello, Debanjan!
Role: Developer
Date: March 30, 2026
Let's build something amazing together!
```

---

## Summary Notes

| Concept | Key Point |
|---------|-----------|
| **C#** | Modern, object-oriented, strongly-typed language by Microsoft |
| **.NET** | Platform/runtime that executes C# code |
| **CLR** | Common Language Runtime — the engine that runs .NET apps |
| **BCL** | Base Class Library — built-in reusable code |
| **SDK** | Tools for building, running, publishing apps |
| **Top-level statements** | Modern C# lets you skip boilerplate (namespace, class, Main) |
| **Console.WriteLine** | Prints output with newline |
| **Console.ReadLine** | Reads user input as a string |
| **String Interpolation** | `$"Hello, {variable}"` for clean string formatting |
| **Namespaces** | Organize code and prevent naming conflicts |
| **Main method** | Entry point of a C# console application |

---

## Real-World Use Cases

1. **Console Apps** — CLI tools, automation scripts, background services (like the starter project we just made)
2. **Web APIs** — Backend services for websites/apps (Phase 4 — ASP.NET Core)
3. **Desktop Apps** — Windows desktop software (WPF, WinForms, MAUI)
4. **Game Development** — Unity game engine uses C# as its primary scripting language
5. **Cloud Services** — Azure Functions, microservices
6. **Mobile Apps** — .NET MAUI for cross-platform mobile development

### Why C# for our course?
> We're building **TaskFlow** (a full-stack Task Management App). C# will be our backend language, powering the Web API that Angular talks to. Understanding C# deeply = understanding how the server side works.

---
