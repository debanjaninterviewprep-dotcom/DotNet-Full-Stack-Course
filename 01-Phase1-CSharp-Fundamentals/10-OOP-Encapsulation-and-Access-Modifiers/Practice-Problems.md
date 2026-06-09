# Phase 1 | Topic 10: Practice Problems — Encapsulation & Access Modifiers

---

## Problem 1: Secure User Profile (Easy)
**Difficulty:** ⭐ Easy

Create a `UserProfile` class with proper encapsulation:

- `Id` — read-only (set in constructor only)
- `Username` — read from outside, private set (set only through `ChangeUsername()` method with validation: 3-20 chars, no spaces)
- `Email` — public get, private set (set through `ChangeEmail()` with basic validation)
- `Password` — FULLY private (never readable from outside), validate min 8 chars
- `CreatedAt` — read-only
- Method: `Authenticate(string password)` — returns bool

**Expected Output:**
```
=== USER PROFILE DEMO ===

Created: Debanjan (debanjan@email.com)

Changing username to "Deb_Roy"...
✅ Username changed to: Deb_Roy

Changing username to "D"...
❌ Username must be between 3-20 characters!

Authenticate with correct password: ✅ Success
Authenticate with wrong password: ❌ Failed

Attempting to read password: [Not accessible — compile error!]
```

**Requirements:**
- No public fields
- All state changes through methods with validation
- Password never exposed

---

## Problem 2: Temperature Sensor (Easy–Medium)
**Difficulty:** ⭐⭐ Easy–Medium

Create a `TemperatureSensor` class:

- Private field `_readings` (List of double)
- `Location` property (read-only, set in constructor)
- `MaxCapacity` — constant, 100 readings max
- `Count` — computed property (readings count)
- `AddReading(double temp)` — validates range (-50 to 60°C), adds to list
- `GetAverage()`, `GetMin()`, `GetMax()` — computed from private readings
- `GetReadings()` — returns `IReadOnlyList<double>` (not the actual list!)
- `ClearReadings()` — clears with confirmation message
- Static: `SensorCount`, incremented in constructor

**Expected Output:**
```
Sensor: "Living Room" (0 readings)

Adding readings: 22.5, 23.1, 21.8, 24.0, 99.9
✅ Added: 22.5°C
✅ Added: 23.1°C
✅ Added: 21.8°C
✅ Added: 24.0°C
❌ 99.9°C out of range! (-50 to 60)

Stats: Avg: 22.85°C | Min: 21.80°C | Max: 24.00°C

Attempting to modify readings directly: [Not possible!]
Total sensors created: 1
```

---

## Problem 3: Banking System (Medium)
**Difficulty:** ⭐⭐ Medium

Build a secure banking system:

**`BankAccount` class:**
- Private: `_balance`, `_pin`, `_transactionHistory` (List of strings)
- Public read-only: `AccountNumber`, `HolderName`, `CreatedAt`
- Public computed: `Balance` (read-only property)
- Methods:
  - `Deposit(decimal amount)` — validate positive amount
  - `Withdraw(decimal amount, string pin)` — validate pin, check balance
  - `Transfer(BankAccount target, decimal amount, string pin)` — withdraw from self, deposit to target
  - `GetStatement(string pin)` — returns transaction history (requires pin!)
  - `ChangePin(string oldPin, string newPin)` — validate old pin first

**`Bank` static class:**
- Private list of all accounts
- `CreateAccount(string name, string pin, decimal initialDeposit)` — generates account number
- `GetAccount(string accountNumber)` — returns account
- `GetTotalDeposits()` — sum of all account balances

**Expected Output:**
```
=== TASKFLOW BANK ===

Created: ACC-001 (Debanjan) — ₹10,000.00
Created: ACC-002 (Rahul) — ₹5,000.00

Depositing ₹3,000 to ACC-001...
✅ Deposited ₹3,000.00

Transferring ₹2,000 from ACC-001 to ACC-002...
✅ Transferred ₹2,000.00 from ACC-001 to ACC-002

Statement for ACC-001 (requires PIN):
  1. [12:30] Initial deposit: +₹10,000.00
  2. [12:31] Deposit: +₹3,000.00
  3. [12:31] Transfer to ACC-002: -₹2,000.00
  Balance: ₹11,000.00

Total deposits across all accounts: ₹18,000.00
```

---

## Problem 4: Encapsulated Game Character (Medium)
**Difficulty:** ⭐⭐ Medium

Build an RPG character system with proper encapsulation:

**`Character` class:**
- Private: `_health`, `_maxHealth`, `_attackPower`, `_defense`, `_xp`, `_level`
- Protected: `_inventory` (List of strings) — derived classes can access
- Public read-only: `Name`, `CharacterClass`
- Public computed: `Health`, `Level`, `IsAlive`
- Methods:
  - `Attack(Character target)` — deals damage based on attack vs defense
  - `TakeDamage(int amount)` — reduces health (can't go below 0)
  - `Heal(int amount)` — restores health (can't exceed max)
  - `GainXp(int amount)` — adds XP, levels up at 100 XP (increases stats)
  - Protected: `LevelUp()` — derived classes can customize

**Derived classes** (use `protected` access):
- `Warrior : Character` — higher defense, has `Shield()` method
- `Mage : Character` — higher attack, has `CastSpell()` method

**Expected Output:**
```
=== CHARACTER BATTLE ===

Warrior "Thor" — HP: 150/150 | ATK: 15 | DEF: 20 | LVL: 1
Mage "Merlin" — HP: 100/100 | ATK: 25 | DEF: 8 | LVL: 1

Thor attacks Merlin!
⚔️ Thor deals 15 damage (25 - 8 defense = 17 actual)
💚 Merlin HP: 83/100

Merlin casts Fireball on Thor!
🔥 Merlin deals 25 damage (25 - 20 defense = 5 actual)
💚 Thor HP: 145/150

Thor gains 50 XP (50/100 to next level)
Merlin gains 120 XP
🎉 Merlin leveled up to Level 2! ATK: 28, DEF: 9
```

---

## Problem 5: TaskFlow Complete OOP System (Medium–Hard)
**Difficulty:** ⭐⭐⭐ Medium–Hard

Build the ultimate TaskFlow system combining ALL OOP concepts (encapsulation, inheritance, abstraction, polymorphism, interfaces):

**Interfaces:**
- `IDisplayable` — `void Display()`, `string ToShortString()`
- `ICompletable` — `void Complete()`, `bool IsCompleted { get; }`

**Abstract base:**
- `WorkItem : IDisplayable, ICompletable` — encapsulated `Id`, `Title`, `CreatedAt`, `IsCompleted`, abstract `GetPriorityLevel()`

**Derived classes:**
- `BugReport : WorkItem` — `Severity`, `StepsToReproduce` (private set)
- `Feature : WorkItem` — `StoryPoints`, `AcceptanceCriteria` (private set)  
- `Improvement : WorkItem` — `CurrentBehavior`, `DesiredBehavior` (private set)

**`Sprint` class (heavily encapsulated):**
- Private: `_workItems` list, `_maxCapacity`
- Read-only: `Name`, `StartDate`, `EndDate`
- Computed: `Velocity`, `CompletionRate`, `RemainingCapacity`
- Methods: `AddItem()` (with validation), `CompleteItem(int id)`, `GetBoard()`, `GetBurndownData()`
- `GetBoard()` returns items grouped: To Do, In Progress, Done

**`TeamMember` class:**
- Private: `_assignedItems` list
- Read-only: `Name`, `Role`
- `AssignItem(WorkItem item)` — max 5 items per person
- `GetWorkload()` — returns `IReadOnlyList`

**Expected Output:**
```
╔═══════════════════════════════════════════════════════════╗
║              TASKFLOW - SPRINT BOARD                      ║
║              Sprint: "April Sprint" (10 days)             ║
╠═══════════════════════════════════════════════════════════╣

⬜ TO DO (3):
   #1 🐛 [Critical] Login crash                    → Debanjan
   #3 ✨ [5pts]     User search feature             → Priya
   #5 🔧            Improve load time               → Unassigned

✅ DONE (2):
   #2 🐛 [Minor]   CSS alignment fix               → Rahul
   #4 ✨ [2pts]    Add tooltip                      → Debanjan

📊 SPRINT METRICS
   Capacity: 5/8 items | Velocity: 2 done
   Progress: [████████░░░░░░░░░░░░] 40%
   
👥 TEAM WORKLOAD
   Debanjan: 2 items (1 done)
   Rahul:    1 item  (1 done)
   Priya:    1 item  (0 done)
```

**Requirements:**
- EVERY field must be private or have controlled access
- Use ALL access modifiers: private, protected, internal, public
- Interfaces for polymorphic display and completion
- Abstract class for shared work item behavior
- Encapsulated collections (IReadOnlyList)
- Validation in all setters and methods
- Builder or factory pattern for creating work items

---

## Instructions

1. Solve each problem in a project folder
2. Try solving each problem **on your own first**
3. If stuck for more than 15 minutes, ask me for a hint
4. Say **"check [problem number]"** when you want me to review your solution
5. Say **"next"** when you've completed all problems and are ready to move on

---

## Checklist
- [ ] Problem 1: Secure User Profile
- [ ] Problem 2: Temperature Sensor
- [ ] Problem 3: Banking System
- [ ] Problem 4: Encapsulated Game Character
- [ ] Problem 5: TaskFlow Complete OOP System
