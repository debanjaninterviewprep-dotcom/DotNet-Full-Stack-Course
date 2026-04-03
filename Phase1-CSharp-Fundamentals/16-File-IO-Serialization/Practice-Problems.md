# Topic 16: File I/O & Serialization — Practice Problems

## Problem 1: Text File Manager (Easy)
**Concept**: File.WriteAllText, ReadAllText, ReadAllLines, AppendAllText

Build a console note-taking app:

1. **Create Note**: Ask for a title (used as filename), write content to `notes/{title}.txt`
2. **Read Note**: Ask for title, display contents
3. **List Notes**: Show all `.txt` files in the `notes/` folder with size and date
4. **Append to Note**: Add more content to an existing note with a timestamp separator
5. **Delete Note**: Remove a note file (with confirmation)
6. **Search Notes**: Search for a keyword across ALL notes, show matching filenames and lines

**Requirements:**
- Create `notes/` directory if it doesn't exist
- Handle `FileNotFoundException` and `DirectoryNotFoundException` gracefully
- Display file sizes in human-readable format (B, KB, MB)

**Expected Output:**
```
=== Note Manager ===
1. Create  2. Read  3. List  4. Append  5. Delete  6. Search  7. Exit

> 1
Title: dotnet-basics
Content: C# is a strongly-typed language.
.NET provides the runtime and libraries.
(empty line to finish)

✓ Note saved: notes/dotnet-basics.txt

> 3
--- All Notes ---
  1. dotnet-basics.txt    (85 B)   2026-04-04 10:30
  2. todo-list.txt        (1.2 KB) 2026-04-04 09:15
  Total: 2 notes

> 6
Search for: C#
Found in 1 file(s):
  dotnet-basics.txt (Line 1): "C# is a strongly-typed language."
```

---

## Problem 2: CSV Data Processor (Easy-Medium)
**Concept**: StreamReader/StreamWriter, CSV parsing, line-by-line processing

Build a CSV employee data processor:

1. **Generate sample CSV** (`employees.csv`) with 10 employees:
   - Columns: Id, Name, Department, Salary, JoinDate
2. **Read & Display** as a formatted table
3. **Filter & Export**: Ask user for a department, export matching employees to `{department}.csv`
4. **Statistics**: Calculate and display:
   - Total employees per department
   - Average salary per department
   - Highest and lowest paid employee
   - Employees who joined in the last year
5. **Add Employee**: Append a new row to the CSV
6. **Sort & Rewrite**: Sort the CSV by any column (user's choice) and overwrite

**Expected Output:**
```
=== CSV Processor ===

--- employees.csv (10 records) ---
┌────┬──────────────┬──────────────┬──────────┬────────────┐
│ ID │ Name         │ Department   │ Salary   │ Join Date  │
├────┼──────────────┼──────────────┼──────────┼────────────┤
│ 1  │ Debanjan     │ Engineering  │ $85,000  │ 2024-03-15 │
│ 2  │ Alice        │ Engineering  │ $92,000  │ 2022-07-01 │
│ ...│ ...          │ ...          │ ...      │ ...        │
└────┴──────────────┴──────────────┴──────────┴────────────┘

--- Department Stats ---
  Engineering: 4 employees, Avg: $95,000
  Marketing:   3 employees, Avg: $67,000
  HR:          3 employees, Avg: $72,500

  Highest: Charlie ($105,000 - Engineering)
  Lowest:  Eve ($58,000 - Marketing)
```

---

## Problem 3: JSON Task Manager with Persistence (Medium)
**Concept**: System.Text.Json — Serialize, Deserialize, file-based CRUD

Build a task manager that **persists** all data in a `tasks.json` file:

**Task Model:**
```csharp
class TaskItem
{
    public int Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public string Priority { get; set; } // Low, Medium, High
    public string Status { get; set; }   // Todo, InProgress, Done
    public DateTime CreatedDate { get; set; }
    public DateTime? CompletedDate { get; set; }
    public List<string> Tags { get; set; }
}
```

**Features:**
1. **Add Task** — auto-increment ID, save to JSON after every add
2. **List Tasks** — filter by status or priority, display as formatted table
3. **Update Task** — change status, title, or priority
4. **Delete Task** — remove by ID
5. **Complete Task** — set status to Done, record CompletedDate
6. **Statistics** — total, by status, by priority, avg completion time
7. **Export** — export filtered tasks to a separate JSON file
8. **Backup** — copy `tasks.json` to `backups/tasks_{timestamp}.json`

**Requirements:**
- Data persists between app restarts (load from file on startup)
- Use `JsonSerializerOptions` with `WriteIndented = true` and `camelCase`
- Handle corrupted JSON files gracefully

**Expected Output:**
```
=== JSON Task Manager ===
Loaded 3 tasks from tasks.json

1. Add  2. List  3. Update  4. Delete  5. Complete  6. Stats  7. Export  8. Backup  9. Exit

> 1
Title: Build REST API
Description: Create CRUD endpoints for tasks
Priority (Low/Medium/High): High
Tags (comma-separated): api, backend, dotnet
✓ Task #4 created.

> 2
Filter by status (all/todo/inprogress/done): all

┌────┬─────────────────┬──────────┬────────────┬─────────────┐
│ ID │ Title           │ Priority │ Status     │ Created     │
├────┼─────────────────┼──────────┼────────────┼─────────────┤
│ 1  │ Setup project   │ High     │ ✓ Done     │ 2026-04-01  │
│ 2  │ Design database │ High     │ → Progress │ 2026-04-02  │
│ 3  │ Write tests     │ Medium   │ ○ Todo     │ 2026-04-03  │
│ 4  │ Build REST API  │ High     │ ○ Todo     │ 2026-04-04  │
└────┴─────────────────┴──────────┴────────────┴─────────────┘

> 8
✓ Backup saved: backups/tasks_20260404_103015.json
```

---

## Problem 4: Multi-Format Data Converter (Medium-Hard)
**Concept**: JSON, XML, CSV conversion — all serialization formats

Build a data converter that transforms between formats:

**Supported Formats:** JSON ↔ CSV ↔ XML

**Product Model:**
```csharp
class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Category { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public bool IsActive { get; set; }
}
```

**Features:**
1. **Import from any format**: Load data from JSON, CSV, or XML file
2. **Export to any format**: Save to JSON, CSV, or XML
3. **Convert**: `convert products.json products.csv` — reads JSON, writes CSV
4. **Validate**: Check data integrity after conversion (round-trip test)
5. **Compare**: Show diff between two files in different formats
6. **Merge**: Combine data from multiple files (any format), deduplicate by Id

**Program Flow:**
1. Create sample data in JSON format
2. Convert JSON → CSV → XML → JSON (round trip)
3. Compare original JSON with round-tripped JSON — should be identical
4. Import from two different files, merge, and export

**Expected Output:**
```
=== Multi-Format Converter ===

[Generate] Created products.json with 5 products.

[Convert] products.json → products.csv
  ✓ Converted 5 records to CSV

[Convert] products.csv → products.xml
  ✓ Converted 5 records to XML

[Convert] products.xml → products_roundtrip.json
  ✓ Converted 5 records to JSON

[Validate] Round-trip test:
  Original:    products.json (5 records)
  Round-trip:  products_roundtrip.json (5 records)
  Result: ✓ IDENTICAL — all data preserved!

[Merge] products.json + extra_products.json → merged.json
  Original: 5 products
  Extra: 3 products (1 duplicate)
  Merged: 7 unique products ✓

--- Products (merged.json) ---
  ID  Name              Category      Price    Stock  Active
  1   Laptop            Electronics   $999.99  50     ✓
  2   Mouse             Electronics   $29.99   200    ✓
  ...
```

---

## Problem 5: TaskFlow Data Persistence Layer (Hard)
**Concept**: All File I/O + Serialization concepts combined

Build a complete data persistence layer for the TaskFlow project:

**Data Models:**
```csharp
class Project { int Id; string Name; string Description; DateTime Created; List<int> TaskIds; }
class TaskItem { int Id; string Title; string Description; int ProjectId; int? AssigneeId; 
                 string Status; string Priority; DateTime Created; DateTime? Completed; 
                 List<string> Tags; List<Comment> Comments; }
class User { int Id; string Name; string Email; string Role; }
class Comment { int Id; int UserId; string Text; DateTime Posted; }
```

**DataStore Class Features:**

1. **File-per-collection storage**:
   - `data/projects.json`
   - `data/tasks.json`
   - `data/users.json`
   - Auto-create `data/` directory

2. **CRUD operations**: Create, Read, Update, Delete for each entity
   - Auto-increment IDs
   - Cascading: deleting a project deletes its tasks
   - Referential integrity: can't assign task to non-existent user

3. **Auto-save**: Save to file after every modification

4. **Backup system**:
   - Manual backup: copies all files to `data/backups/{timestamp}/`
   - Restore: restore from a specific backup

5. **Export options**:
   - Full export: all data in a single `taskflow_export.json`
   - Project report: export one project with all its tasks, comments, and assigned users as a formatted text report
   - CSV export: tasks as CSV for import into spreadsheet

6. **Async I/O**: All file operations should be `async`

7. **Error recovery**: If JSON file is corrupted, attempt to restore from latest backup

**Program Flow:**
1. Initialize DataStore, create sample data (3 projects, 8 tasks, 4 users)
2. Perform several CRUD operations
3. Export project report as text
4. Create backup, modify data, then restore from backup
5. Export everything as CSV
6. Show storage statistics (file sizes, record counts)

**Expected Output:**
```
=== TaskFlow Data Persistence ===

[Init] Data store initialized at ./data/
  Created: projects.json, tasks.json, users.json

[Seed] Sample data created:
  3 projects, 8 tasks, 4 users

[CRUD] Create Task: "Implement login page" → Task #9 ✓
[CRUD] Update Task #3: Status → "Done" ✓
[CRUD] Delete Task #5 ✓
[CRUD] Delete Project #2 → cascaded delete of 3 tasks ✓

[Export] Project Report: "TaskFlow API" → reports/taskflow-api-report.txt
  === Project: TaskFlow API ===
  Status: Active | Tasks: 4 | Created: 2026-04-01
  
  Tasks:
    #1 [Done] Setup project (High) — Debanjan
    #2 [InProgress] Build endpoints (High) — Alice
    #3 [Done] Write tests (Medium) — Bob
    #9 [Todo] Implement login page (High) — Unassigned
  
  Team: Debanjan, Alice, Bob

[Backup] Created: data/backups/20260404_103500/
  Backed up: 3 files (4.2 KB total)

[Modify] Changed 2 tasks, added 1 user...

[Restore] Restoring from backup 20260404_103500...
  ✓ Restored 3 files. Changes reverted.

[CSV Export] tasks.csv — 5 tasks exported

[Stats]
  projects.json: 1.2 KB (2 projects)
  tasks.json:    2.8 KB (5 tasks)
  users.json:    0.8 KB (4 users)
  Backups: 1 (4.2 KB)
  Total storage: 9.0 KB
```

---

### Submission
- Create a new console project: `dotnet new console -n FileIOPractice`
- Solve all 5 problems in `Program.cs`
- JSON files should be pretty-printed and use camelCase
- All file operations should use `using` statements
- Handle all file-related exceptions (FileNotFound, IO, unauthorized access)
- Tell me "check" when you're ready for review!
