# Phase 1 | Topic 4: Practice Problems — Control Flow

---

## Problem 1: Number Classifier (Easy)
**Difficulty:** ⭐ Easy

Write a program that:
1. Asks the user for a number
2. Tells them if it's **positive, negative, or zero**
3. Also tells them if it's **even or odd** (only if it's not zero)

**Expected Output:**
```
Enter a number: -7

Result:
-7 is Negative
-7 is Odd
```

**Requirements:**
- Use `if/else if/else`
- Use the modulus operator for even/odd

---

## Problem 2: Calculator with Switch (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Build a calculator that:
1. Asks for **two numbers** and an **operator** (`+`, `-`, `*`, `/`, `%`)
2. Uses a **switch statement** to perform the operation
3. Handles **division by zero** gracefully
4. Uses a **do-while loop** to let the user calculate again or exit

**Expected Output:**
```
=== TASKFLOW CALCULATOR ===

Enter first number: 20
Enter operator (+, -, *, /, %): /
Enter second number: 3

Result: 20 / 3 = 6.67

Calculate again? (Y/N): Y

Enter first number: 10
Enter operator (+, -, *, /, %): /
Enter second number: 0

Error: Cannot divide by zero!

Calculate again? (Y/N): N
Goodbye!
```

**Requirements:**
- Use `switch` (or switch expression) for the operator
- Use `do-while` for repeat functionality
- Use `double` for calculations
- Format result to 2 decimal places

---

## Problem 3: Number Guessing Game (Medium)
**Difficulty:** ⭐⭐ Medium

Build a number guessing game:
1. Generate a random number between 1 and 100
2. Give the user **7 attempts** to guess it
3. After each guess, say if it's **too high**, **too low**, or **correct**
4. Track the number of attempts used
5. After the game, ask if they want to play again

**Expected Output:**
```
=== NUMBER GUESSING GAME ===
I'm thinking of a number between 1 and 100.
You have 7 attempts.

Attempt 1/7 - Your guess: 50
📈 Too high!

Attempt 2/7 - Your guess: 25
📉 Too low!

Attempt 3/7 - Your guess: 37
📈 Too high!

Attempt 4/7 - Your guess: 31
🎉 CORRECT! You got it in 4 attempts!

Play again? (Y/N): N
Thanks for playing!
```

**Hints:**
- `Random random = new Random(); int secret = random.Next(1, 101);`
- Use a `for` loop with `break` when they guess correctly
- Use a `do-while` for play-again

---

## Problem 4: Star Pattern Printer (Medium)
**Difficulty:** ⭐⭐ Medium

Write a program that asks the user for a **number N** and prints these 4 patterns:

**Pattern A — Right Triangle:**
```
* 
* * 
* * * 
* * * * 
* * * * * 
```

**Pattern B — Inverted Triangle:**
```
* * * * * 
* * * * 
* * * 
* * 
* 
```

**Pattern C — Pyramid:**
```
        * 
      * * * 
    * * * * * 
  * * * * * * * 
* * * * * * * * * 
```

**Pattern D — Diamond:**
```
    *
   ***
  *****
 *******
*********
 *******
  *****
   ***
    *
```

**Requirements:**
- Use nested `for` loops
- Ask user which pattern to display (use `switch`)
- Ask for the number of rows N

---

## Problem 5: FizzBuzz Extended (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build an extended FizzBuzz:
1. Ask the user for a **range** (start and end numbers)
2. For each number in the range:
   - Divisible by 3 AND 5 → print `"TaskFlow"` 🚀
   - Divisible by 3 only → print `"Task"` 📋
   - Divisible by 5 only → print `"Flow"` 🌊
   - Divisible by 7 → also append `"Pro"` ⭐
   - Otherwise → print the number
3. At the end, display statistics:
   - Count of TaskFlow, Task, Flow, Pro, and regular numbers

**Expected Output (range 1-21):**
```
=== TASKFLOW FIZZBUZZ ===
Range: 1 to 21

1, 2, Task📋, 4, Flow🌊, Task📋, Pro⭐, 8, Task📋, Flow🌊,
11, Task📋, 13, Pro⭐, TaskFlow🚀, 16, 17, Task📋, 19, Flow🌊,
TaskFlowPro🚀⭐

=== STATISTICS ===
TaskFlow:  1
Task:      5
Flow:      3
Pro:       3
Numbers:   9
Total:     21
```

**Requirements:**
- Use a `for` loop for the range
- Use `if/else if/else` or ternary operators
- Use `continue` to skip certain conditions if needed
- Keep running counters for the statistics

---

## Instructions

1. Solve each problem in the `PracticeProblems` project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Number Classifier
- [ ] Problem 2: Calculator with Switch
- [ ] Problem 3: Number Guessing Game
- [ ] Problem 4: Star Pattern Printer
- [ ] Problem 5: FizzBuzz Extended
