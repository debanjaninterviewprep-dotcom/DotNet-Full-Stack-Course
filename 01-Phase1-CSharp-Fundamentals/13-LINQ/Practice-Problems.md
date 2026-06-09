# Topic 13: LINQ — Practice Problems

## Problem 1: Student Grade Report with LINQ (Easy)
**Concept**: Where, Select, OrderBy, Average, Min, Max

Given this data:

```csharp
var students = new[]
{
    new { Name = "Debanjan", Subject = "Math", Score = 92 },
    new { Name = "Debanjan", Subject = "Science", Score = 88 },
    new { Name = "Debanjan", Subject = "English", Score = 95 },
    new { Name = "Alice", Subject = "Math", Score = 78 },
    new { Name = "Alice", Subject = "Science", Score = 85 },
    new { Name = "Alice", Subject = "English", Score = 80 },
    new { Name = "Bob", Subject = "Math", Score = 95 },
    new { Name = "Bob", Subject = "Science", Score = 72 },
    new { Name = "Bob", Subject = "English", Score = 68 },
    new { Name = "Charlie", Subject = "Math", Score = 60 },
    new { Name = "Charlie", Subject = "Science", Score = 55 },
    new { Name = "Charlie", Subject = "English", Score = 70 },
};
```

Use LINQ to answer ALL of these (one query each):
1. All scores above 80, sorted descending
2. Each student's average score (use GroupBy)
3. The student with the highest average
4. The subject with the lowest average across all students
5. Students who scored above 90 in any subject
6. Rank students by their total score (highest first) — display rank, name, total
7. For each subject, show the topper (highest scorer)

**Expected Output (partial):**
```
--- Scores Above 80 ---
Debanjan - English: 95
Bob - Math: 95
Debanjan - Math: 92
...

--- Student Averages ---
Debanjan: 91.67
Alice: 81.00
Bob: 78.33
Charlie: 61.67

--- Highest Average ---
Debanjan with 91.67

--- Subject Toppers ---
Math: Bob (95)
Science: Debanjan (88)
English: Debanjan (95)
```

---

## Problem 2: E-Commerce Order Analyzer (Easy-Medium)
**Concept**: GroupBy, Sum, SelectMany, OrderByDescending, Take

Create this data:

```csharp
var orders = new List<Order>
{
    // Order: OrderId, Customer, Items (list of OrderItem)
    // OrderItem: ProductName, Price, Quantity
};
```

Create at least 5 orders with multiple items each. Then use LINQ to compute:

1. **Total revenue** across all orders
2. **Revenue per customer** (sorted highest first)
3. **Top 3 best-selling products** by total quantity sold
4. **Most expensive single item purchased** (product name & price)
5. **Average order value** (total per order, then average)
6. **Customers who spent more than $500**
7. **Products bought by ALL customers** (intersection)
8. **Orders sorted by total value**, showing: Order#, Customer, Item Count, Total

**Hint**: Use `SelectMany` to flatten order items across all orders.

---

## Problem 3: Employee Directory with Complex Queries (Medium)
**Concept**: Join, GroupJoin, multiple GroupBy, chained queries

Create two collections:

```csharp
// Employees: Id, Name, DepartmentId, Salary, JoinDate, ManagerId (nullable)
// Departments: Id, Name, Budget, Location
```

Create at least 8 employees across 4 departments. Some employees should be managers of others.

**LINQ Queries to Write:**

1. **Join**: List each employee with their department name and location
2. **GroupJoin**: For each department, list employees — include departments with no employees
3. **Department salary report**: Department name, employee count, total salary, remaining budget (Budget - TotalSalary)
4. **Employees with their manager's name** (self-join on ManagerId)
5. **Departments over budget** (total salaries exceed department budget)
6. **Newest hire per department** (most recent JoinDate in each department)
7. **Salary percentile**: For each employee, show what percentage of employees earn less than them
8. **Cross-department salary comparison**: Is each employee above or below the company average?

**Expected Output (partial):**
```
--- Department Report ---
Engineering (3 employees):
  Total Salary: $280,000 | Budget: $300,000 | Remaining: $20,000 ✓
Marketing (2 employees):
  Total Salary: $133,000 | Budget: $120,000 | Over Budget: -$13,000 ⚠

--- Employee vs Company Average ($82,875) ---
Charlie: $105,000 (+$22,125 above avg) ▲
Debanjan: $85,000 (+$2,125 above avg) ▲
Bob: $65,000 (-$17,875 below avg) ▼
```

---

## Problem 4: Log File Analyzer (Medium-Hard)
**Concept**: String processing with LINQ, GroupBy, TakeWhile, Aggregate

Simulate a server log file as a list of strings:

```csharp
var logs = new List<string>
{
    "2026-04-01 08:15:23 INFO  User 'debanjan' logged in",
    "2026-04-01 08:16:45 INFO  User 'alice' logged in",
    "2026-04-01 08:20:10 WARN  High memory usage: 85%",
    "2026-04-01 08:25:33 ERROR Database connection timeout",
    "2026-04-01 09:00:15 INFO  User 'debanjan' accessed /api/tasks",
    "2026-04-01 09:05:22 INFO  User 'bob' logged in",
    "2026-04-01 09:10:44 ERROR Null reference in TaskService.GetAll()",
    "2026-04-01 09:15:30 WARN  API response time > 2s for /api/reports",
    "2026-04-01 10:00:00 INFO  User 'alice' accessed /api/dashboard",
    "2026-04-01 10:05:12 ERROR File not found: config.json",
    "2026-04-01 10:30:45 INFO  User 'debanjan' logged out",
    "2026-04-01 11:00:00 INFO  System backup started",
    "2026-04-01 11:15:30 WARN  Disk usage: 90%",
    "2026-04-01 11:20:00 ERROR Backup failed: insufficient space",
    "2026-04-01 12:00:00 INFO  User 'alice' logged out",
    // Add more if you want...
};
```

Use LINQ to:
1. **Count by log level**: How many INFO, WARN, ERROR entries?
2. **All ERROR messages** with timestamps
3. **Hourly breakdown**: Group by hour, show count per level per hour
4. **Active users**: Extract unique usernames (parse from log messages)
5. **Most active user**: User with the most log entries
6. **Error rate**: Percentage of logs that are ERROR
7. **Time between consecutive errors**: Parse timestamps, calculate durations
8. **Peak hour**: The hour with the most log entries
9. **Warnings that preceded errors**: For each ERROR, find the WARN that came right before it (if any)
10. **Summary dashboard**: Combine all analysis into a formatted report

**Expected Output (partial):**
```
=== Log Analysis Dashboard ===

Log Level Distribution:
  INFO:  8 (53.3%)
  WARN:  3 (20.0%)
  ERROR: 4 (26.7%)

Errors:
  [08:25:33] Database connection timeout
  [09:10:44] Null reference in TaskService.GetAll()
  [10:05:12] File not found: config.json
  [11:20:00] Backup failed: insufficient space

Peak Hour: 08:00-09:00 (4 entries)

Active Users: alice (3), debanjan (3), bob (1)
```

---

## Problem 5: TaskFlow Analytics Dashboard (Hard)
**Concept**: All LINQ concepts combined — complex chaining, GroupBy, Join, aggregation

Build a complete analytics system for TaskFlow project data:

**Data Models:**
```csharp
class Project { int Id; string Name; DateTime StartDate; DateTime? EndDate; }
class Task { int Id; string Title; int ProjectId; int AssigneeId; string Status; string Priority; int EstimatedHours; int ActualHours; DateTime CreatedDate; DateTime? CompletedDate; }
class Developer { int Id; string Name; string Role; string Team; }
```

Create at least:
- 3 projects
- 12+ tasks (spread across projects, various statuses/priorities)
- 5 developers across 2 teams

**Analytics to Build (ALL using LINQ):**

1. **Project Summary**: For each project — task count, % complete, total estimated vs actual hours
2. **Developer Productivity**: Tasks completed per developer, average actual vs estimated hours (efficiency %)
3. **Priority Distribution**: Count of tasks per priority per project (cross-tab style)
4. **Overdue Tasks**: Tasks where ActualHours > EstimatedHours * 1.5 (50% over budget)
5. **Team Comparison**: Average completion rate and efficiency per team
6. **Sprint Velocity**: Group tasks by completion week, show tasks completed per week
7. **Bottleneck Detector**: Developer with the most in-progress tasks
8. **Project Health Score**: 
   - Green: >80% tasks done, avg efficiency >90%
   - Yellow: >50% tasks done OR efficiency 70-90%
   - Red: <50% tasks done AND efficiency <70%
9. **Top Performers**: Rank developers by: tasks completed × efficiency score
10. **Full Dashboard**: Combine all above into a formatted console report

**Expected Output (partial):**
```
╔══════════════════════════════════════════╗
║       TaskFlow Analytics Dashboard       ║
╠══════════════════════════════════════════╣

📊 Project Summary:
┌──────────────┬───────┬──────────┬───────────┬───────────┐
│ Project      │ Tasks │ Complete │ Est Hours │ Act Hours │
├──────────────┼───────┼──────────┼───────────┼───────────┤
│ TaskFlow API │   5   │   80%    │    40     │    38     │
│ TaskFlow UI  │   4   │   50%    │    32     │    35     │
│ TaskFlow DB  │   3   │  100%    │    20     │    18     │
└──────────────┴───────┴──────────┴───────────┴───────────┘

👥 Developer Productivity:
  1. Alice     — 4 tasks, 95% efficiency ⭐
  2. Debanjan  — 3 tasks, 88% efficiency
  3. Bob       — 2 tasks, 105% efficiency (over-estimated!)

🏥 Project Health:
  TaskFlow API: 🟢 Green (80% done, 95% efficient)
  TaskFlow UI:  🟡 Yellow (50% done, 91% efficient)
  TaskFlow DB:  🟢 Green (100% done, 90% efficient)
```

---

### Submission
- Create a new console project: `dotnet new console -n LINQPractice`
- Solve all 5 problems in `Program.cs`
- Use **method syntax** (fluent) for all queries
- Challenge: Try rewriting Problem 1 in **query syntax** as well
- Tell me "check" when you're ready for review!
