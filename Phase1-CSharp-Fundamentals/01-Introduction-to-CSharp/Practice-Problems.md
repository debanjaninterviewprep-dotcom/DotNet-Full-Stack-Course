# Phase 1 | Topic 1: Practice Problems

---

## Problem 1: Personal Introduction (Easy)
**Difficulty:** ⭐ Easy

Write a C# console program that:
1. Asks the user for their **name**, **age**, and **city**
2. Prints a formatted introduction like:

```
Hi! My name is Debanjan. I am 25 years old and I live in Kolkata.
```

**Requirements:**
- Use `Console.ReadLine()` for input
- Use **string interpolation** (`$"..."`) for output
- Display the output on a single line

---

## Problem 2: Simple Calculator (Easy)
**Difficulty:** ⭐ Easy

Write a C# console program that:
1. Asks the user for **two numbers**
2. Prints their **sum, difference, product, and quotient**

**Example Output:**
```
Enter first number: 10
Enter second number: 3

Results:
Sum: 13
Difference: 7
Product: 30
Quotient: 3.33
```

**Hint:** `Console.ReadLine()` returns a `string`. You'll need to convert it to a number. Try googling: *"C# convert string to int"* or *"C# Convert.ToInt32"*.

---

## Problem 3: Swap Two Variables (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Write a program that:
1. Takes two numbers as input
2. **Swaps** their values (the first becomes the second and vice versa)
3. Prints the values **before** and **after** swapping

**Example Output:**
```
Enter first number: 5
Enter second number: 10

Before swap: a = 5, b = 10
After swap: a = 10, b = 5
```

**Challenge:** Can you do it **without using a third/temporary variable**? (Think mathematically!)

---

## Problem 4: Temperature Converter (Medium)
**Difficulty:** ⭐⭐ Medium

Write a program that:
1. Asks the user for a temperature in **Celsius**
2. Converts it to **Fahrenheit** and **Kelvin**
3. Displays all three values formatted to 2 decimal places

**Formulas:**
- Fahrenheit = (Celsius × 9/5) + 32
- Kelvin = Celsius + 273.15

**Example Output:**
```
Enter temperature in Celsius: 37.5

Temperature Conversions:
Celsius:    37.50 °C
Fahrenheit: 99.50 °F
Kelvin:     310.65 K
```

**Hint:** For formatting to 2 decimal places, research `ToString("F2")` or `:F2` inside string interpolation.

---

## Problem 5: ASCII Art Profile Card (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Write a program that:
1. Takes the user's **name**, **role**, and **email**
2. Generates a formatted **profile card** in the console using ASCII art/box drawing

**Expected Output (approximate):**
```
╔══════════════════════════════════╗
║        TASKFLOW PROFILE          ║
╠══════════════════════════════════╣
║  Name:  Debanjan                 ║
║  Role:  Developer                ║
║  Email: debanjan@email.com       ║
╠══════════════════════════════════╣
║  Joined: March 30, 2026         ║
╚══════════════════════════════════╝
```

**Requirements:**
- The box should have a **fixed width** (e.g., 36 characters inner width)
- Text should be **padded** properly so the right border aligns
- The "Joined" date should be **auto-generated** using `DateTime.Now`

**Hint:** Look into `String.PadRight()` method to pad strings to a fixed width.

---

## Instructions

1. Create each solution as a separate project:
   ```bash
   dotnet new console -n Problem1-Introduction
   dotnet new console -n Problem2-Calculator
   ```
   (or solve them all in one project by commenting/uncommenting)

2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Personal Introduction
- [ ] Problem 2: Simple Calculator
- [ ] Problem 3: Swap Two Variables
- [ ] Problem 4: Temperature Converter
- [ ] Problem 5: ASCII Art Profile Card
