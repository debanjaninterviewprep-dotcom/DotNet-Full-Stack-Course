# Phase 1 | Topic 8: Practice Problems — Inheritance & Polymorphism

---

## Problem 1: Vehicle Hierarchy (Easy)
**Difficulty:** ⭐ Easy

Create a vehicle inheritance hierarchy:

- **Base class `Vehicle`**: `Make`, `Model`, `Year`, `Speed`, constructor, `Accelerate(int amount)`, `Brake(int amount)`, `Display()`
- **`Car : Vehicle`**: `Doors` property, override `Display()` to include doors
- **`Motorcycle : Vehicle`**: `HasSidecar` property, override `Display()`
- **`Truck : Vehicle`**: `PayloadCapacity` (tons), override `Display()`

**Expected Output:**
```
=== VEHICLE SHOWCASE ===

🚗 Car: 2024 Toyota Camry | Speed: 0 km/h | Doors: 4
  Accelerating by 60...
  Speed: 60 km/h

🏍️ Motorcycle: 2023 Harley Davidson | Speed: 0 km/h | Sidecar: No
  Accelerating by 80...
  Speed: 80 km/h

🚛 Truck: 2022 Volvo FH16 | Speed: 0 km/h | Payload: 25 tons
  Accelerating by 40...
  Speed: 40 km/h
```

**Requirements:**
- Use `virtual` and `override` for `Display()`
- Use `base.Display()` in overrides
- Speed cannot go below 0

---

## Problem 2: Shape Calculator with Polymorphism (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Create:
- **Base class `Shape`**: `Name`, `Color`, virtual `Area()`, virtual `Perimeter()`, virtual `Display()`
- **`Rectangle : Shape`**: `Width`, `Height`
- **`Circle : Shape`**: `Radius`
- **`Triangle : Shape`**: `SideA`, `SideB`, `SideC`, `Height`

Store all shapes in a `Shape[]` array. Use **polymorphism** to:
1. Calculate total area of all shapes
2. Find the shape with the largest area
3. Display all shapes in a formatted table

**Expected Output:**
```
=== SHAPE CALCULATOR ===

Shape          Color     Area        Perimeter
──────────────────────────────────────────────────
Rectangle      Red       50.00       30.00
Circle         Blue      153.94      43.98
Triangle       Green     30.00       30.00

📊 Total area: 233.94
📊 Largest: Circle (153.94)
```

**Requirements:**
- Use `Shape[]` array and `foreach` — demonstrate polymorphism
- Override `ToString()` for each shape
- Use expression-bodied for Area/Perimeter where possible

---

## Problem 3: Employee Payroll System (Medium)
**Difficulty:** ⭐⭐ Medium

Build a complete payroll system:

- **Base `Employee`**: `Id`, `Name`, `Department`, virtual `CalculatePay()`, virtual `GetRole()`
- **`SalariedEmployee : Employee`**: `MonthlySalary`, `Bonus`
- **`HourlyEmployee : Employee`**: `HourlyRate`, `HoursWorked`, overtime (>40 hrs = 1.5x rate)
- **`CommissionEmployee : Employee`**: `BaseSalary`, `SalesAmount`, `CommissionRate`

Use an `Employee[]` array to:
1. Display a payroll report for all employees
2. Calculate total payroll cost
3. Find the highest and lowest paid
4. Show average pay by role type

**Expected Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                    PAYROLL REPORT                            ║
╠══════════════════════════════════════════════════════════════╣
║ #   Name            Role              Pay                    ║
║ 1   Debanjan        Salaried          ₹85,000.00            ║
║ 2   Rahul           Hourly            ₹32,000.00            ║
║ 3   Priya           Commission        ₹70,000.00            ║
║ 4   Amit            Hourly (OT)       ₹38,000.00            ║
╠══════════════════════════════════════════════════════════════╣
║ Total Payroll:    ₹2,25,000.00                               ║
║ Highest Paid:     Debanjan (₹85,000.00)                      ║
║ Lowest Paid:      Rahul (₹32,000.00)                         ║
╚══════════════════════════════════════════════════════════════╝
```

**Requirements:**
- All pay calculations must use `virtual`/`override` polymorphism
- Handle overtime: hours > 40 paid at 1.5x rate
- Commission: `BaseSalary + (SalesAmount * CommissionRate)`

---

## Problem 4: Type Checking & Casting Challenge (Medium)
**Difficulty:** ⭐⭐ Medium

Using the Vehicle hierarchy from Problem 1, create a `Vehicle[]` with a mix of Cars, Motorcycles, and Trucks.

Write methods that demonstrate:
1. **`is` keyword** — Count how many of each type
2. **Pattern matching with `is`** — Print car-specific info only for Cars
3. **`as` keyword** — Safely get Truck payload, print "N/A" if not a truck
4. **Switch pattern matching** — Classify each vehicle and print a custom message
5. **Filtering** — Get only vehicles that are Cars with > 2 doors

**Expected Output:**
```
=== TYPE CHECKING DEMO ===

Vehicle Count by Type:
  Cars: 3
  Motorcycles: 2
  Trucks: 1

Car Details (using 'is' pattern):
  2024 Toyota Camry — 4 doors
  2023 Honda Civic — 4 doors
  2022 Mini Cooper — 2 doors

Truck Payloads (using 'as'):
  Volvo FH16: 25 tons
  Honda Civic: N/A (not a truck)
  ...

Classification (switch pattern):
  Toyota Camry → 🚗 Family car (4 doors)
  Harley Davidson → 🏍️ Solo rider (no sidecar)
  Volvo FH16 → 🚛 Heavy hauler (25 tons)
```

---

## Problem 5: TaskFlow Task Type System (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build a TaskFlow system with different task types:

**Class hierarchy:**
- **Base `TaskBase`**: `Id`, `Title`, `Assignee`, `CreatedAt`, `IsCompleted`, virtual `GetEstimatedHours()`, virtual `GetPriority()`, virtual `Display()`, `Complete()`, override `ToString()`
- **`BugTask : TaskBase`**: `Severity` (Critical/Major/Minor), `StepsToReproduce`. Estimated hours based on severity. Priority = severity-based.
- **`FeatureTask : TaskBase`**: `StoryPoints`, `AcceptanceCriteria`. Estimated hours = story points × 4. Priority = story-points-based.
- **`ChoreTask : TaskBase`**: `IsRecurring`, `Frequency`. Fixed estimated hours. Low priority.

**Features:**
1. Add different task types via a menu
2. View all tasks — polymorphism handles display
3. View task details — use pattern matching to show type-specific info
4. Calculate sprint capacity (total estimated hours)
5. Show breakdown by task type
6. Mark tasks complete

**Expected Output:**
```
╔═══════════════════════════════════════════════════════════╗
║              TASKFLOW - SPRINT BOARD                      ║
╚═══════════════════════════════════════════════════════════╝

#  Type      Title                  Priority  Est.Hrs  Status
────────────────────────────────────────────────────────────
1  🐛 Bug    Fix login crash        Critical  16h      ⬜
2  ✨ Feature User dashboard         High      20h      ⬜
3  🔧 Chore  Update dependencies    Low       2h       ✅
4  🐛 Bug    CSS alignment issue    Minor     4h       ⬜

📊 Sprint Capacity: 42 hours
📊 Breakdown: Bugs: 20h | Features: 20h | Chores: 2h
📊 Progress: 1/4 (25%)
```

**Requirements:**
- Use `virtual`/`override` for all varying behavior
- Use polymorphism with `TaskBase[]` array
- Use pattern matching (`is`, `switch`) for type-specific details
- Override `ToString()` in each class
- Use `base` constructor chaining

---

## Instructions

1. Solve each problem in a project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Vehicle Hierarchy
- [ ] Problem 2: Shape Calculator with Polymorphism
- [ ] Problem 3: Employee Payroll System
- [ ] Problem 4: Type Checking & Casting Challenge
- [ ] Problem 5: TaskFlow Task Type System
