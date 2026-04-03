# Topic 11: Exception Handling — Practice Problems

## Problem 1: Safe Calculator (Easy)
**Concept**: try-catch with multiple exception types

Build a console calculator that:
1. Asks the user for two numbers and an operator (+, -, *, /)
2. Performs the calculation
3. Handles ALL of these gracefully (no crashes):
   - Non-numeric input → `FormatException`
   - Division by zero → `DivideByZeroException`
   - Number too large → `OverflowException` (use `checked` context)
   - Invalid operator → your own validation message
4. After each calculation, ask "Continue? (y/n)"
5. Use a `finally` block to print "--- Calculation complete ---" after every attempt

**Expected Output:**
```
=== Safe Calculator ===
Enter first number: abc
Error: 'abc' is not a valid number.
--- Calculation complete ---

Enter first number: 100
Enter second number: 0
Enter operator (+, -, *, /): /
Error: Cannot divide by zero.
--- Calculation complete ---

Enter first number: 50
Enter second number: 8
Enter operator (+, -, *, /): *
Result: 50 * 8 = 400
--- Calculation complete ---
```

---

## Problem 2: Input Validator with Retry (Easy-Medium)
**Concept**: Exception handling loops, guard clauses, TryParse pattern

Create a method `GetValidatedInput` that:
1. Asks for the user's **name** (non-empty, no digits)
2. Asks for their **age** (integer, 1–120)
3. Asks for their **email** (must contain `@` and `.`)
4. Each input allows **3 attempts** before giving up
5. Use `ArgumentException` for validation failures
6. Display a summary if all inputs are valid, or "Registration failed" if any input exhausted retries

**Requirements:**
- Use `TryParse` for age (not try-catch with `int.Parse`)
- Throw `ArgumentException` from a validation method, catch it in the input loop
- Track remaining attempts

**Expected Output:**
```
=== User Registration ===
Enter your name: 123
Invalid: Name cannot contain digits. (2 attempts left)
Enter your name: 
Invalid: Name cannot be empty. (1 attempt left)
Enter your name: Debanjan
✓ Name accepted.

Enter your age: two hundred
Invalid: Please enter a valid number. (2 attempts left)
Enter your age: 200
Invalid: Age must be between 1 and 120. (1 attempt left)
Enter your age: 25
✓ Age accepted.

Enter your email: debanjan
Invalid: Email must contain '@' and '.'. (2 attempts left)
Enter your email: debanjan@email.com
✓ Email accepted.

=== Registration Complete ===
Name: Debanjan
Age: 25
Email: debanjan@email.com
```

---

## Problem 3: Custom Exception — Student Grade System (Medium)
**Concept**: Custom exceptions, exception chaining, throw

Create a student grade system with custom exceptions:

**Custom Exceptions to Create:**
1. `InvalidGradeException` — grade is outside 0–100
   - Properties: `AttemptedGrade`, `StudentName`
2. `DuplicateStudentException` — student name already exists
   - Property: `DuplicateName`

**System Requirements:**
1. Store students and their grades in a list
2. `AddStudent(name)` — throws `DuplicateStudentException` if name exists
3. `AddGrade(name, grade)` — throws `InvalidGradeException` if grade < 0 or > 100
4. `GetAverage(name)` — throws `InvalidOperationException` if student has no grades
5. Display each student's average and letter grade (A: 90+, B: 80+, C: 70+, D: 60+, F: below 60)
6. Wrap everything in a menu-driven console app with proper exception handling

**Expected Output:**
```
=== Student Grade System ===
1. Add Student
2. Add Grade
3. View Average
4. View All Students
5. Exit

Choice: 1
Enter student name: Debanjan
✓ Student 'Debanjan' added.

Choice: 2
Enter student name: Debanjan
Enter grade (0-100): 150
Error: Grade 150 is invalid for student 'Debanjan'. Must be 0-100.

Choice: 2
Enter student name: Debanjan
Enter grade (0-100): 85
✓ Grade 85 added for Debanjan.

Choice: 3
Enter student name: Debanjan
Debanjan's Average: 85.00 (B)

Choice: 1
Enter student name: Debanjan
Error: Student 'Debanjan' already exists.
```

---

## Problem 4: File-Based Task Logger with IDisposable (Medium-Hard)
**Concept**: IDisposable, using statement, finally, file exceptions

Build a `TaskLogger` class that implements `IDisposable`:

**TaskLogger Specifications:**
- Constructor takes a file path and opens a `StreamWriter`
- `LogTask(string task, string priority)` — writes timestamped entries
  - Validates: task not empty, priority must be "Low", "Medium", or "High"
  - Throws `ArgumentException` for invalid inputs
- `LogError(string errorMessage)` — writes error entries with [ERROR] prefix
- `GetLogSummary()` — returns count of tasks and errors logged
- `Dispose()` — flushes and closes the writer, prints "Logger disposed"
- After disposal, any method call should throw `ObjectDisposedException`

**Program Requirements:**
1. Use `using` statement to create the TaskLogger
2. Log several tasks with different priorities
3. Intentionally cause errors (empty task, invalid priority) and handle them
4. Try to use the logger AFTER the using block — catch `ObjectDisposedException`
5. Read and display the log file contents at the end
6. Handle `FileNotFoundException`, `IOException`, and `UnauthorizedAccessException`

**Expected Output:**
```
=== Task Logger ===
✓ Logged: "Design database schema" [High]
✓ Logged: "Write unit tests" [Medium]
Error: Task description cannot be empty.
Error: Priority 'Urgent' is invalid. Use Low, Medium, or High.
✓ Error logged: "Connection timeout on server"

Summary: 2 tasks, 1 error logged.
Logger disposed.

Attempting to use disposed logger...
Error: Cannot access a disposed object. (TaskLogger)

=== Log File Contents ===
[2026-04-04 10:30:15] [High] Design database schema
[2026-04-04 10:30:15] [Medium] Write unit tests
[2026-04-04 10:30:16] [ERROR] Connection timeout on server
```

---

## Problem 5: TaskFlow Exception-Safe Task Processor (Hard)
**Concept**: All exception handling concepts combined

Build a TaskFlow task processing system that demonstrates comprehensive exception handling:

**Custom Exceptions:**
1. `TaskValidationException` : Exception — invalid task data
   - Properties: `FieldName`, `InvalidValue`
2. `TaskProcessingException` : Exception — error during processing
   - Property: `TaskId`, wraps inner exception
3. `TaskQuotaExceededException` : Exception — too many tasks
   - Properties: `CurrentCount`, `MaxAllowed`

**TaskProcessor Class:**
- Maximum 5 tasks allowed (`TaskQuotaExceededException` when exceeded)
- `AddTask(id, title, priority, dueDate)` with validation:
  - ID must be positive
  - Title must be 3–50 characters
  - Priority: 1 (Low), 2 (Medium), 3 (High)
  - DueDate must be in the future
  - Each violation throws `TaskValidationException`
- `ProcessTask(id)` — simulates processing:
  - 30% chance of random failure (use `Random`) → throws `TaskProcessingException`
  - On success, marks task as processed
- `ProcessAllTasks()` — processes all tasks, collects failures, reports results
  - Uses exception filters: `catch (TaskProcessingException ex) when (ex.TaskId > 0)`
  - Does NOT stop on first failure — processes all tasks and reports summary
- Implements `IDisposable` — cleanup and final report

**Program Flow:**
1. Create TaskProcessor with `using`
2. Add 5 valid tasks and 2 invalid ones (handle validation errors)
3. Try to add a 6th valid task (handle quota exception)
4. Process all tasks — report successes and failures
5. Display final summary

**Expected Output:**
```
=== TaskFlow Task Processor ===

Adding tasks...
✓ Task 1: "Setup project structure" added [High, Due: 2026-04-10]
✓ Task 2: "Create database models" added [High, Due: 2026-04-12]
✗ Validation Error: Field 'Title' has invalid value 'AB' — Title must be 3-50 characters.
✓ Task 3: "Write API endpoints" added [Medium, Due: 2026-04-15]
✗ Validation Error: Field 'DueDate' has invalid value '2025-01-01' — Due date must be in the future.
✓ Task 4: "Build Angular frontend" added [Medium, Due: 2026-04-20]
✓ Task 5: "Deploy to Azure" added [Low, Due: 2026-04-25]
✗ Quota Error: Cannot add more tasks. Current: 5, Maximum: 5.

Processing all tasks...
✓ Task 1 "Setup project structure" — Processed successfully.
✗ Task 2 "Create database models" — Processing failed: Random system error.
✓ Task 3 "Write API endpoints" — Processed successfully.
✓ Task 4 "Build Angular frontend" — Processed successfully.
✗ Task 5 "Deploy to Azure" — Processing failed: Random system error.

=== Processing Summary ===
Total: 5 | Succeeded: 3 | Failed: 2
Failed Tasks: #2, #5

TaskProcessor disposed. Resources cleaned up.
```

---

### Submission
- Create a new console project: `dotnet new console -n ExceptionHandlingPractice`
- Solve all 5 problems in `Program.cs` (use `#region` to separate them or methods)
- Test edge cases: empty inputs, extreme values, disposed objects
- Tell me "check" when you're ready for review!
