# Phase 1 | Topic 6: Practice Problems — Arrays & Strings

---

## Problem 1: Array Statistics (Easy)
**Difficulty:** ⭐ Easy

Write a program that:
1. Asks the user for **5 numbers** and stores them in an array
2. Calculates and displays:
   - Sum
   - Average (formatted to 2 decimal places)
   - Minimum
   - Maximum
   - Count of numbers above average

**Expected Output:**
```
Enter 5 numbers:
Number 1: 85
Number 2: 92
Number 3: 78
Number 4: 95
Number 5: 88

=== STATISTICS ===
Numbers:  85, 92, 78, 95, 88
Sum:      438
Average:  87.60
Minimum:  78
Maximum:  95
Above Avg: 3 numbers (92, 95, 88)
```

**Requirements:**
- Use an `int[]` array
- Use a `for` loop to collect input and `foreach` to process
- Do NOT use built-in `.Min()`, `.Max()` — calculate manually with a loop

---

## Problem 2: Word Analyzer (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Write a program that:
1. Asks the user for a **sentence**
2. Analyzes and displays:
   - Total characters (including spaces)
   - Total characters (excluding spaces)
   - Word count
   - Number of vowels and consonants
   - Number of uppercase and lowercase letters
   - The sentence reversed (word by word)
   - Each word capitalized (first letter uppercase)

**Expected Output:**
```
Enter a sentence: hello world from taskflow

=== SENTENCE ANALYSIS ===
Original:     "hello world from taskflow"
Characters:   24 (with spaces), 20 (without)
Words:        4
Vowels:       7
Consonants:   13
Uppercase:    0
Lowercase:    20
Reversed:     "taskflow from world hello"
Capitalized:  "Hello World From Taskflow"
```

**Requirements:**
- Use `.Split()` to get words
- Use a `foreach` loop to count vowels/consonants
- Build the reversed sentence using `Array.Reverse()` and `string.Join()`

---

## Problem 3: Matrix Operations (Medium)
**Difficulty:** ⭐⭐ Medium

Write a program that:
1. Creates two **3×3 integer matrices** (hardcoded or user-input)
2. Displays both matrices in a formatted grid
3. Performs and displays:
   - **Matrix Addition** (A + B)
   - **Matrix Transpose** (rows become columns)
   - **Sum of diagonal** elements

**Expected Output:**
```
Matrix A:          Matrix B:
 1  2  3            9  8  7
 4  5  6            6  5  4
 7  8  9            3  2  1

A + B:
10 10 10
10 10 10
10 10 10

Transpose of A:
 1  4  7
 2  5  8
 3  6  9

Diagonal sum of A: 15 (1 + 5 + 9)
```

**Requirements:**
- Use `int[,]` 2D arrays
- Use nested `for` loops for all operations
- Format numbers with consistent column width

---

## Problem 4: String Builder Challenge (Medium)
**Difficulty:** ⭐⭐ Medium

Build a **text formatting tool** that:
1. Takes a paragraph of text as input
2. Provides a menu with these operations:
   - **Word Count** — count total words
   - **Find & Replace** — replace a word/phrase
   - **Censor** — replace a specific word with asterisks (same length)
   - **Alternate Case** — convert to aLtErNaTiNg CaSe
   - **Slug Generator** — convert to URL-friendly slug
   - **Summary** — show first N words

**Expected Output:**
```
Enter text: The quick brown fox jumps over the lazy dog

=== TEXT TOOLS ===
1. Word Count
2. Find & Replace
3. Censor Word
4. Alternate Case
5. Slug Generator
6. Summary
0. Exit

Choice: 3
Word to censor: fox
Result: "The quick brown *** jumps over the lazy dog"

Choice: 4
Result: "tHe QuIcK bRoWn FoX jUmPs OvEr ThE lAzY dOg"

Choice: 5
Result: "the-quick-brown-fox-jumps-over-the-lazy-dog"

Choice: 6
Show first N words: 5
Result: "The quick brown fox jumps..."
```

**Requirements:**
- Use `StringBuilder` for operations that modify the text
- Use `Split()` and `Join()` for word operations
- Handle case-insensitive operations where appropriate

---

## Problem 5: TaskFlow Task Manager with Arrays (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a complete Task Manager using **parallel arrays** (before we learn objects):

Store task data in separate arrays:
- `string[] titles` — task names
- `string[] priorities` — "High", "Medium", "Low"
- `bool[] completed` — completion status
- `DateTime[] dueDates` — due dates

Implement these features:
1. **Add Task** — with title, priority, and due date
2. **View All Tasks** — formatted table with # | Title | Priority | Due | Status
3. **Mark Complete** — mark a task as done by number
4. **Search Tasks** — search by keyword in title
5. **Sort Tasks** — sort by priority (High → Medium → Low) or by due date
6. **Filter Tasks** — show only pending, only completed, or by priority
7. **Task Summary** — total, completed, pending, overdue count, progress bar

**Expected Output:**
```
╔═══════════════════════════════════════════════════════════╗
║              TASKFLOW - TASK MANAGER                      ║
╚═══════════════════════════════════════════════════════════╝

1. Add Task    2. View All    3. Complete Task
4. Search      5. Sort        6. Filter
7. Summary     0. Exit

Choice: 2

#   Title                    Priority    Due Date      Status
─────────────────────────────────────────────────────────────
1   Fix login bug            High        Apr 05, 2026  ⬜ Pending
2   Update dashboard         Medium      Apr 10, 2026  ✅ Done
3   Write API docs           Low         Apr 15, 2026  ⬜ Pending
4   Deploy v2.0              Critical    Apr 03, 2026  ⬜ OVERDUE ⚠️

Choice: 7

📊 TASK SUMMARY
──────────────────
Total:     4
Completed: 1
Pending:   3
Overdue:   1
Progress:  [█████░░░░░░░░░░░░░░░] 25%
```

**Requirements:**
- Max 20 tasks using fixed-size arrays
- Use parallel arrays (all arrays indexed by the same task number)
- Display overdue tasks (due date < today) with a warning
- Sort must rearrange ALL parallel arrays together
- Use `StringBuilder` for building the summary report
- Use `string.PadRight()` / `PadLeft()` for table formatting
- Validate all user inputs

---

## Instructions

1. Solve each problem in the `PracticeProblems` project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Array Statistics
- [ ] Problem 2: Word Analyzer
- [ ] Problem 3: Matrix Operations
- [ ] Problem 4: String Builder Challenge
- [ ] Problem 5: TaskFlow Task Manager with Arrays
