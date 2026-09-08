# Topic 11: Constraints & Data Integrity

> Every layer above the database in **TaskFlow** is optional. The Angular client validates a form and then a mobile client skips it. The API validates a DTO and then a nightly ETL job bypasses the API entirely. A support engineer runs an `UPDATE` in SSMS at 2am. A `MERGE` in a stored procedure gets a join predicate wrong. Constraints are the only rule in the system that *nothing* can go around — they are checked inside the same transaction as the write, under the same locks, for every session, forever. That is why the database is the last line of defence and not the first: it is the only line that cannot be skipped. This topic covers every declarative constraint SQL Server offers, the metadata that tells you whether the optimizer actually believes them, and the rules that constraints genuinely cannot express.

---

## 1. Four Kinds of Integrity

Textbooks split data integrity into four categories. Each maps onto specific enforcement mechanisms, and knowing the mapping tells you immediately where a new rule belongs.

| Integrity type | Guarantees | Enforced in TaskFlow by |
|---|---|---|
| **Entity** | Every row is uniquely identifiable; no duplicate rows | `PRIMARY KEY`, `UNIQUE`, unique index, `IDENTITY` |
| **Referential** | Every reference points at a row that exists | `FOREIGN KEY` + referential actions |
| **Domain** | Every value is drawn from the legal set for its column | Data type, `NOT NULL`, `CHECK`, `DEFAULT`, lookup table + FK |
| **User-defined** | Business rules that span rows, tables, or time | Filtered indexes, indexed views, triggers, stored procedures, application code |

The seeded schema shows all four:

```sql
USE TaskFlowDb;
GO

-- Entity      : PK_Tasks, PK_TaskAssignments (TaskId, UserId), UQ_Projects_Code
-- Referential : FK_Tasks_Project, FK_Tasks_Parent (self), FK_TaskAssign_Task (CASCADE)
-- Domain      : StatusId TINYINT NOT NULL + FK to ref.TaskStatuses; CK_TimeEntries_Hours
-- User-defined: "at most one primary assignee per task" — nothing above expresses this (§5)
```

Domain integrity has a design fork worth naming early: an allowed-values list can be a `CHECK (StatusCode IN (…))` or a **lookup table plus a foreign key**. TaskFlow chose the latter for `ref.TaskStatuses` and `ref.Priorities`. Lookup tables win whenever the list has attributes of its own (`IsTerminal`, `SortOrder`, `SlaHours`), needs to be joined for display, or changes without a deployment. `CHECK` wins for genuinely closed, attribute-free sets — a two-value flag, a fixed set of ISO codes you control.

---

## 2. `NOT NULL` — the Cheapest Constraint

`NOT NULL` is part of the column definition, not a named constraint object, and it is the highest-value declaration you can make. It costs nothing at runtime, it removes an entire branch of three-valued logic from every query written against the column, and it unlocks optimizer transformations that nullable columns block outright.

```sql
-- 515 on violation, and note the message names the fully-qualified table
INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
VALUES (1, NULL, 1, 3, 4);
/*
Msg 515, Level 16, State 2
Cannot insert the value NULL into column 'Title', table 'TaskFlowDb.app.Tasks';
column does not allow nulls. INSERT fails.
*/
```

What nullability buys you elsewhere in this course:

- `NOT IN` is safe only over a `NOT NULL` column (Topic 06, §8).
- `COUNT(col)` and `COUNT(*)` agree only when `col` is `NOT NULL` (Topic 05).
- Join elimination requires the child FK column to be `NOT NULL` **and** the FK to be trusted (§13).
- `SUM` over a `NOT NULL` column is legal in an indexed view; over a nullable column it is not.

Nullable columns in the seeded schema are deliberate, not accidental: `ref.Priorities.SlaHours` (NULL = "no SLA"), `app.Users.ManagerId` (NULL = "top of the org chart"), `app.Projects.EndDate` (NULL = "still running"), `app.Tasks.CompletedAtUtc` (NULL = "not finished"). Each NULL there carries a distinct, documented meaning.

> **Rule of thumb:** Declare a column `NOT NULL` unless you can write one sentence explaining what a NULL in it *means*. "We do not know yet" and "does not apply" are valid meanings. "The developer did not pass a value" is not.

> **Anti-pattern:** Making everything nullable "so inserts do not fail". You have not removed the failure — you have moved it from a 515 at insert time to a `NullReferenceException` in the C# mapper six months later, on a row nobody can explain.

---

## 3. `PRIMARY KEY`

A `PRIMARY KEY` is three guarantees bundled together: **unique**, **not null**, and **the identifying key of the row**. Physically, SQL Server implements it as a unique index — **clustered by default** if the table has no clustered index yet.

```sql
-- Every PK in TaskFlow is clustered because none of the tables declared
-- a clustered index first.
SELECT
    i.name                AS IndexName,
    i.type_desc           AS IndexType,
    i.is_primary_key,
    i.is_unique_constraint,
    i.is_unique
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'app.Users')
  AND i.index_id > 0
ORDER BY i.index_id;
```

| IndexName | IndexType | is_primary_key | is_unique_constraint | is_unique |
|---|---|---|---|---|
| PK_Users | CLUSTERED | 1 | 0 | 1 |
| UQ_Users_Email | NONCLUSTERED | 0 | 1 | 1 |

Two rows, and they encode the whole §4 lesson: a `UNIQUE` constraint *is* a unique index with a metadata flag set.

### `NOT NULL` is implied, not optional

```sql
-- 'NOT NULL' is redundant here but write it anyway: it documents intent and
-- survives the day somebody drops the PK to rebuild it.
CREATE TABLE app.SprintScratch
(
    SprintId INT NOT NULL CONSTRAINT PK_SprintScratch PRIMARY KEY,
    Name     NVARCHAR(50) NOT NULL
);
DROP TABLE app.SprintScratch;
```

Omitting `NOT NULL` on a PK column does not fail — SQL Server silently changes the column to `NOT NULL`. Dropping the PK later does **not** change it back, which surprises people.

### Composite keys

`app.TeamMembers`, `app.TaskAssignments` and `app.TaskLabels` all use composite primary keys made of their two foreign keys. That is the correct shape for a pure junction table: the key *is* the pair, and it enforces "a user is on a team at most once" for free.

```sql
-- PK_TaskAssignments PRIMARY KEY (TaskId, UserId)
-- Column order matters: the clustered index is keyed (TaskId, UserId), so
-- "all assignees of a task" seeks and "all tasks of a user" scans.
SELECT COUNT(*) FROM app.TaskAssignments;  -- 31
```

Choose composite key column order by the **most common access path**, then add a nonclustered index for the reverse direction if you need it (Topic 13).

### Surrogate vs natural — the TaskFlow pattern

| Table | Surrogate PK | Natural key kept as | Why |
|---|---|---|---|
| `app.Projects` | `ProjectId INT IDENTITY` | `UQ_Projects_Code` on `ProjectCode` | Codes get renamed; FKs must not |
| `app.Users` | `UserId INT IDENTITY` | `UQ_Users_Email` on `Email` | People change email addresses |
| `app.Teams` | `TeamId INT IDENTITY` | `UQ_Teams_Name` on `TeamName` | Teams get renamed constantly |
| `ref.TaskStatuses` | **none** — `StatusId TINYINT`, hand-assigned | `UQ_TaskStatuses_Code` on `StatusCode` | Reference IDs must be stable and identical across environments |

The last row is the one people get wrong. Reference data must **not** use `IDENTITY`: if dev, test and production seed their lookup tables independently, `IDENTITY` gives them different numbers, and every hard-coded `StatusId = 6` in a report becomes environment-specific. Hand-assign small integers and keep them forever.

> **Rule of thumb:** Surrogate key for the primary key, natural key as a `UNIQUE` alternate key. You get stable foreign keys *and* enforced business uniqueness. Choosing one and dropping the other is what causes pain.

---

## 4. `UNIQUE` Constraints, Unique Indexes, and the One-NULL Rule

A `UNIQUE` constraint and a `CREATE UNIQUE INDEX` enforce the same thing through the same physical structure. The differences are small but real.

| | `UNIQUE` constraint | `UNIQUE INDEX` |
|---|---|---|
| Physical implementation | Unique index | Unique index |
| Can be the target of a `FOREIGN KEY` | Yes | Yes |
| Can have a filter (`WHERE`) | **No** | **Yes** |
| Can have `INCLUDE`d columns | No | Yes |
| Appears in `sys.key_constraints` | Yes | No |
| `is_unique_constraint` in `sys.indexes` | 1 | 0 |
| Duplicate-key error number | **2627** | **2601** |
| Portable declaration | Yes (ANSI) | No (vendor DDL) |

The error-number difference is the fastest way to tell which one a production incident hit:

```
Msg 2627, Level 14, State 1
Violation of UNIQUE KEY constraint 'UQ_Projects_Code'. Cannot insert duplicate key
in object 'app.Projects'. The duplicate key value is (TF-CORE).

Msg 2601, Level 14, State 1
Cannot insert duplicate key row in object 'app.TaskAssignments' with unique index
'UX_TaskAssignments_OnePrimary'. The duplicate key value is (4).
```

### The one-NULL rule

This is the single most surprising behaviour in SQL Server's constraint model.

**SQL Server treats NULLs as equal to each other for uniqueness purposes.** A single-column `UNIQUE` constraint therefore permits **exactly one** NULL row. The ANSI standard says the opposite — NULLs are distinct, so unlimited NULLs are allowed — and PostgreSQL, Oracle and MySQL all follow the standard.

```sql
CREATE TABLE app.ProjectExternalRefs
(
    ProjectId INT         NOT NULL CONSTRAINT PK_ProjectExternalRefs PRIMARY KEY,
    JiraKey   VARCHAR(20) NULL     CONSTRAINT UQ_ProjectExternalRefs_JiraKey UNIQUE,
    CONSTRAINT FK_ProjectExternalRefs_Project FOREIGN KEY (ProjectId)
        REFERENCES app.Projects (ProjectId)
);

INSERT INTO app.ProjectExternalRefs (ProjectId, JiraKey) VALUES (1, 'TFC-1');
INSERT INTO app.ProjectExternalRefs (ProjectId, JiraKey) VALUES (2, NULL);   -- OK
INSERT INTO app.ProjectExternalRefs (ProjectId, JiraKey) VALUES (3, NULL);   -- FAILS
/*
Msg 2627 ... Violation of UNIQUE KEY constraint 'UQ_ProjectExternalRefs_JiraKey'.
The duplicate key value is (<NULL>).
*/
```

Two projects out of eight have no Jira key and you cannot record that fact. This is not a corner case — it is the default outcome of "optional but unique", which is one of the most common column shapes in any product.

---

## 5. Filtered Unique Indexes — the Fix for Everything §4 Broke

A filtered unique index applies the uniqueness rule to a **subset** of rows. It solves the one-NULL problem, soft-delete uniqueness, and "at most one X per parent" — three rules that no ANSI constraint can express.

### Unique among non-NULLs

```sql
ALTER TABLE app.ProjectExternalRefs DROP CONSTRAINT UQ_ProjectExternalRefs_JiraKey;

CREATE UNIQUE INDEX UX_ProjectExternalRefs_JiraKey
    ON app.ProjectExternalRefs (JiraKey)
    WHERE JiraKey IS NOT NULL;

INSERT INTO app.ProjectExternalRefs (ProjectId, JiraKey) VALUES (3, NULL);  -- OK now
INSERT INTO app.ProjectExternalRefs (ProjectId, JiraKey) VALUES (4, NULL);  -- OK
INSERT INTO app.ProjectExternalRefs (ProjectId, JiraKey) VALUES (5, 'TFC-1'); -- 2601

DROP TABLE app.ProjectExternalRefs;
```

### At most one X per parent

`app.TaskAssignments.IsPrimary` carries a business rule the schema does not enforce: *a task has at most one primary assignee*. The seed data honours it — 27 assigned tasks, 27 rows with `IsPrimary = 1` — but nothing stops a second one.

```sql
-- Succeeds against the seeded data: the 27 IsPrimary=1 rows have distinct TaskIds.
CREATE UNIQUE INDEX UX_TaskAssignments_OnePrimary
    ON app.TaskAssignments (TaskId)
    WHERE IsPrimary = 1;

-- Task 4 already has Ken (UserId 7) as primary; promoting Dennis now fails.
UPDATE app.TaskAssignments SET IsPrimary = 1 WHERE TaskId = 4 AND UserId = 8;
-- Msg 2601 ... with unique index 'UX_TaskAssignments_OnePrimary'. The duplicate key value is (4).

DROP INDEX UX_TaskAssignments_OnePrimary ON app.TaskAssignments;
```

A `CHECK` constraint cannot express this: it can only see the row being written, never its siblings.

### Soft-delete uniqueness

`app.Projects.IsArchived` and `app.Users.IsActive` are soft-delete flags. Once a row can be logically deleted, "the code must be unique" almost always means "unique among the live rows".

```sql
-- Reserve TF-MOB for reuse after archiving, while keeping live codes unique.
-- (UQ_Projects_Code is the strict version; this is the soft-delete-aware version.)
-- ALTER TABLE app.Projects DROP CONSTRAINT UQ_Projects_Code;
-- CREATE UNIQUE INDEX UX_Projects_Code_Active
--     ON app.Projects (ProjectCode) WHERE IsArchived = 0;
```

Two caveats before you reach for filtered indexes everywhere:

1. **`SET` options.** Any session that writes to a table with a filtered index must have `ANSI_NULLS` and `QUOTED_IDENTIFIER` `ON`. Modern drivers do; some legacy ODBC and linked-server paths do not, and they fail with error 1934.
2. **Query matching is literal.** A filtered index on `WHERE IsPrimary = 1` is not usable by a query written `WHERE IsPrimary <> 0`. Match the predicate exactly.

> **Portability:** PostgreSQL has partial unique indexes with identical syntax. MySQL has none — emulate with a generated column that is NULL when the filter is false, exploiting MySQL's multiple-NULLs rule. Oracle has none — emulate with a function-based unique index returning NULL for excluded rows.

---

## 6. `FOREIGN KEY`

A foreign key asserts that every non-NULL value in the child column exists in the referenced parent column. The parent side must be a `PRIMARY KEY` or `UNIQUE` constraint — SQL Server needs a unique index to make the check a single seek.

```sql
-- Table-level declaration, always named. TaskFlow uses this form throughout.
CONSTRAINT FK_Tasks_Project FOREIGN KEY (ProjectId) REFERENCES app.Projects (ProjectId)
```

Three shapes appear in the seeded schema:

| Shape | Example | Note |
|---|---|---|
| Single column | `FK_Tasks_Status` → `ref.TaskStatuses (StatusId)` | The common case |
| **Composite** | `(TaskId, UserId)` → `app.TaskAssignments (TaskId, UserId)` | Must match the parent key's **column order** |
| **Self-referencing** | `FK_Users_Manager`, `FK_Tasks_Parent`, `FK_Comments_Parent` | Child and parent are the same table |

Self-referencing FKs have two consequences worth memorising. First, the column must be nullable — otherwise no row could ever be inserted first. Second, they can **never** use `ON DELETE CASCADE` (§8).

```sql
-- 20 foreign keys, 6 of them cascading, 3 of them self-referencing.
SELECT
    fk.name                                   AS ForeignKey,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + N'.' + OBJECT_NAME(fk.parent_object_id)         AS ChildTable,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + N'.' + OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    fk.delete_referential_action_desc         AS OnDelete,
    fk.update_referential_action_desc         AS OnUpdate
FROM sys.foreign_keys AS fk
ORDER BY ChildTable, fk.name;
```

Note what is *missing*: `audit.TaskHistory.TaskId` has **no** foreign key, deliberately. Audit rows must survive the deletion of the row they describe. Omitting an FK is a legitimate design decision — but it must be a decision, written down in the DDL as a comment, not an oversight.

> **Anti-pattern:** "We removed the foreign keys for performance." An FK check on insert is a single seek into an index that already exists. What it actually costs you is the *lock* on the parent row, and what removing it costs you is join elimination, trusted-constraint plan simplification, correct ORM navigation-property mapping, and a data-repair project. Measure before you believe the claim.

**Indexing the child column** is on you. SQL Server automatically indexes the *parent* side (it must, to be a key) but creates nothing on the child. Without it, every parent `DELETE` or `UPDATE` of the key scans the child table to check the constraint, and cascades are worse. In TaskFlow, `app.TaskAssignments.UserId` and `app.Tasks.ProjectId` are the obvious candidates — Topic 13 covers the mechanics.

---

## 7. Referential Actions

`ON DELETE` and `ON UPDATE` decide what happens to child rows when the parent key is removed or changed.

| Action | On parent `DELETE` | On parent `UPDATE` of the key | Requires |
|---|---|---|---|
| `NO ACTION` (default) | Raise error 547, roll back the statement | Raise error 547 | — |
| `CASCADE` | Delete the child rows too | Propagate the new key value | No multiple cascade paths |
| `SET NULL` | Set the child FK column(s) to NULL | Same | Child column **nullable** |
| `SET DEFAULT` | Set the child FK column(s) to their `DEFAULT` | Same | A `DEFAULT` constraint exists **and** that value exists in the parent (or is NULL) |

`NO ACTION` and the ANSI `RESTRICT` differ in theory (deferred vs immediate) but behave identically in SQL Server, which has no deferred constraints.

TaskFlow's cascade choices encode a clear ownership model:

```sql
-- Owned rows: meaningless without the parent -> CASCADE
FK_TaskAssign_Task   ON DELETE CASCADE   -- app.Tasks -> app.TaskAssignments
FK_TaskLabels_Task   ON DELETE CASCADE
FK_TaskLabels_Label  ON DELETE CASCADE
FK_Comments_Task     ON DELETE CASCADE
FK_TimeEntries_Task  ON DELETE CASCADE
FK_TeamMembers_Team  ON DELETE CASCADE   -- app.Teams -> app.TeamMembers

-- Referenced rows: the child is independent -> NO ACTION (the other 14 FKs)
FK_TaskAssign_User   -- deleting a user must NOT silently delete their work
FK_TimeEntries_User  -- billable hours are financial records
FK_Tasks_Project     -- deleting a project with tasks must be an explicit decision
```

Deleting task 35 therefore removes exactly five rows: the task, one assignment, one label link, one comment and one time entry.

```sql
BEGIN TRANSACTION;
    DELETE FROM app.Tasks WHERE TaskId = 35;   -- (1 row affected) — the cascades are silent
    SELECT
        (SELECT COUNT(*) FROM app.TaskAssignments WHERE TaskId = 35) AS Assignments,  -- 0
        (SELECT COUNT(*) FROM app.TaskLabels      WHERE TaskId = 35) AS Labels,       -- 0
        (SELECT COUNT(*) FROM app.Comments        WHERE TaskId = 35) AS Comments,     -- 0
        (SELECT COUNT(*) FROM app.TimeEntries     WHERE TaskId = 35) AS TimeEntries;  -- 0
ROLLBACK TRANSACTION;
```

`@@ROWCOUNT` reports only the rows the *statement* touched. Cascaded deletes are invisible — the single most under-appreciated risk of `CASCADE`, and the reason an audit trail must not depend on the row it audits.

Deleting task 1 behaves differently, because tasks 2 and 3 name it as their `ParentTaskId` and `FK_Tasks_Parent` is `NO ACTION`:

```
Msg 547, Level 16, State 0
The DELETE statement conflicted with the SAME TABLE REFERENCE constraint "FK_Tasks_Parent".
The conflict occurred in database "TaskFlowDb", table "app.Tasks", column 'TaskId'.
```

> **Rule of thumb:** `CASCADE` only down a **composition** edge — where the child has no independent existence and no independent audit value. Use `NO ACTION` for everything else and let the application delete children explicitly, in a transaction, where it can log what it did.

`ON UPDATE CASCADE` is almost always a smell: it exists to propagate changes to a key value, and a surrogate key never changes. If you need it, you are using a natural key as a primary key.

---

## 8. Multiple Cascade Paths — Error 1785

SQL Server statically analyses the cascade graph at DDL time and **refuses** any configuration where a single table can be reached by two cascade paths, or where a cascade cycle exists. Other engines allow it and resolve at runtime; SQL Server does not.

```sql
-- Path 1: app.Tasks -> app.TaskAssignments (CASCADE) -> app.TaskReviews (CASCADE)
-- Path 2: app.Tasks -> app.TaskReviews (CASCADE)
CREATE TABLE app.TaskReviews
(
    TaskId         INT         NOT NULL,
    ReviewerUserId INT         NOT NULL,
    ReviewedOn     DATE        NOT NULL,
    Outcome        VARCHAR(20) NOT NULL,
    CONSTRAINT PK_TaskReviews PRIMARY KEY (TaskId, ReviewerUserId),
    CONSTRAINT FK_TaskReviews_Assignment FOREIGN KEY (TaskId, ReviewerUserId)
        REFERENCES app.TaskAssignments (TaskId, UserId) ON DELETE CASCADE,
    CONSTRAINT FK_TaskReviews_Task FOREIGN KEY (TaskId)
        REFERENCES app.Tasks (TaskId) ON DELETE CASCADE
);
/*
Msg 1785, Level 16, State 0
Introducing FOREIGN KEY constraint 'FK_TaskReviews_Task' on table 'TaskReviews' may cause
cycles or multiple cascade paths. Specify ON DELETE NO ACTION or ON UPDATE NO ACTION, or
modify other FOREIGN KEY constraints.
Msg 1750, Level 16, State 1
Could not create constraint or index. See previous errors.
*/
```

The same error blocks every self-referencing cascade, which is why `FK_Tasks_Parent`, `FK_Users_Manager` and `FK_Comments_Parent` are all `NO ACTION`:

```sql
ALTER TABLE app.Tasks
    ADD CONSTRAINT FK_Tasks_Parent_Cascade FOREIGN KEY (ParentTaskId)
        REFERENCES app.Tasks (TaskId) ON DELETE CASCADE;
-- Msg 1785 again. A self-referencing FK can never cascade in SQL Server.
```

### Resolving it

| Option | How | When |
|---|---|---|
| Drop one cascade to `NO ACTION` | Change the redundant path — here, `FK_TaskReviews_Task` | **First choice.** The other path already deletes the row |
| `INSTEAD OF DELETE` trigger on the parent | Delete children explicitly in the trigger body, then the parent | When both paths are genuinely needed |
| `AFTER DELETE` trigger on the intermediate table | Clean up the second-path descendants | Fragile: order and recursion depth matter |
| Application-side delete in a transaction | Delete children, then parent, in the repository/service | **Preferred** when deletion has business meaning (audit, notification, quota release) |

In the example above, path 1 already removes the review row when the assignment goes, and the assignment goes when the task goes. `FK_TaskReviews_Task` should simply be `NO ACTION` — the redundancy was the bug, not the constraint.

> **Anti-pattern:** Reaching for a trigger the moment 1785 appears. Nine times out of ten the second cascade path is redundant and the correct fix is one word of DDL. Triggers reintroduce the ordering and recursion problems that `CASCADE` existed to remove, and `@@ROWCOUNT` lies inside them too.

---

## 9. `CHECK` Constraints

A `CHECK` constraint is a boolean expression evaluated **against the row being written**. The row is rejected only when the expression evaluates to `FALSE`.

```sql
CONSTRAINT CK_TimeEntries_Hours CHECK (Hours > 0 AND Hours <= 24)
CONSTRAINT CK_Projects_Dates    CHECK (EndDate IS NULL OR EndDate >= StartDate)   -- multi-column
CONSTRAINT CK_Labels_ColorHex   CHECK (ColorHex LIKE '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')
CONSTRAINT CK_Tasks_Json        CHECK (MetadataJson IS NULL OR ISJSON(MetadataJson) = 1)
```

Violations report **547**, the same number as a foreign key violation — read the message text, not the number:

```
Msg 547, Level 16, State 0
The INSERT statement conflicted with the CHECK constraint "CK_TimeEntries_Hours".
The conflict occurred in database "TaskFlowDb", table "app.TimeEntries", column 'Hours'.
```

### The NULL trap

**`UNKNOWN` is not `FALSE`, so a row containing NULL passes.** This is the highest-frequency constraint bug in production.

```sql
-- These two are IDENTICAL in behaviour. Both allow NULL.
CHECK (EstimatedHours > 0)
CHECK (EstimatedHours IS NULL OR EstimatedHours > 0)   -- CK_Tasks_Estimate
```

The seed script writes the second form deliberately: it costs nothing and it tells the next reader that NULL was *intended* rather than forgotten. If NULL must be rejected, the tool is `NOT NULL` — a `CHECK` will never do it. And a `CHECK` that is *supposed* to reject NULL must say so explicitly:

```sql
-- Rejects NULL: NULL IS NOT NULL is FALSE, not UNKNOWN.
CHECK (EstimatedHours IS NOT NULL AND EstimatedHours > 0)
```

### The collation trap

Pattern checks are evaluated under the column's collation, which is case-**insensitive** by default. `CHECK (CountryCode LIKE '[A-Z][A-Z]')` therefore happily accepts `'gb'`.

```sql
-- Correct: force a binary collation for the comparison.
ALTER TABLE app.Users WITH CHECK
    ADD CONSTRAINT CK_Users_CountryCode
        CHECK (CountryCode COLLATE Latin1_General_BIN2 LIKE '[A-Z][A-Z]');
-- Succeeds: all 20 seeded rows are GB/US/FI/IL/AT/NL.
ALTER TABLE app.Users DROP CONSTRAINT CK_Users_CountryCode;
```

### What a `CHECK` cannot see

A `CHECK` expression is restricted to the current row. Subqueries are rejected outright:

```sql
ALTER TABLE app.TaskAssignments ADD CONSTRAINT CK_TaskAssign_OnePrimary
    CHECK ((SELECT COUNT(*) FROM app.TaskAssignments AS x
            WHERE x.TaskId = TaskId AND x.IsPrimary = 1) <= 1);
/*
Msg 1046, Level 15, State 1
Subqueries are not allowed in this context. Only scalar expressions are allowed.
*/
```

> **Anti-pattern:** Wrapping the subquery in a scalar UDF to get past error 1046. It compiles and it is **wrong**. The function is evaluated only for rows the statement touches, so a `DELETE` that breaks the rule is never checked; under `READ COMMITTED` two concurrent sessions can both pass the check and both commit; and the constraint becomes a per-row scalar function call on every write. Cross-row rules belong in a filtered unique index (§5), an indexed view with a unique clustered index, or a trigger — never in a `CHECK`.

### Where cross-row rules actually belong

| Rule shape | Mechanism |
|---|---|
| Uniqueness over a subset of rows | **Filtered unique index** |
| "At most N children per parent", N = 1 | **Filtered unique index** |
| An aggregate over a group must satisfy a predicate | **Indexed view** with a unique clustered index, or a trigger |
| Two date ranges in the same group must not overlap | **Trigger** (PostgreSQL: `EXCLUDE` constraint) |
| A state machine — which status transitions are legal | **Trigger** (needs `deleted` and `inserted`) or a stored procedure |
| A rule involving another table's rows | **Trigger** or application logic in a transaction |

---

## 10. `DEFAULT` Constraints

A `DEFAULT` supplies a value when the column is omitted from an `INSERT` — or when `DEFAULT` is written explicitly. It is **not** applied when you insert an explicit `NULL`.

```sql
-- CountryCode omitted -> 'GB'; IsActive omitted -> 1; CreatedAtUtc omitted -> SYSUTCDATETIME()
INSERT INTO app.Users (Email, FirstName, LastName, JobTitle)
VALUES (N'temp@taskflow.io', N'Temp', N'User', N'Engineer');

-- Explicit NULL is NOT replaced by the default -> 515, CountryCode is NOT NULL
INSERT INTO app.Users (Email, FirstName, LastName, CountryCode)
VALUES (N'temp2@taskflow.io', N'Temp', N'Two', NULL);

DELETE FROM app.Users WHERE Email IN (N'temp@taskflow.io', N'temp2@taskflow.io');
```

Sixteen `DEFAULT` constraints exist in TaskFlow, and they fall into three purposes:

| Purpose | Examples |
|---|---|
| **Audit stamps** | `DF_Users_CreatedAt`, `DF_Tasks_CreatedAt`, `DF_Comments_Posted`, `DF_TaskHistory_At`, `DF_TaskHistory_By` |
| **Safe-by-default flags** | `DF_Users_IsActive` (1), `DF_Projects_Archived` (0), `DF_TaskAssign_Primary` (0), `DF_TimeEntries_Billable` (1) |
| **Sensible business defaults** | `DF_Users_Country` ('GB'), `DF_TeamMembers_Role` (N'Member'), `DF_Labels_Color` ('#808080') |

Always use `SYSUTCDATETIME()`, never `GETDATE()`. Every timestamp column in TaskFlow is named `...Utc` for exactly this reason.

A `DEFAULT` cannot be altered in place — it must be dropped and recreated, which is the practical argument for naming it:

```sql
ALTER TABLE app.Users DROP CONSTRAINT DF_Users_Country;
ALTER TABLE app.Users ADD CONSTRAINT DF_Users_Country DEFAULT ('GB') FOR CountryCode;
```

---

## 11. Naming Constraints

Every constraint in TaskFlow is named, using one prefix per type:

| Prefix | Type | Example |
|---|---|---|
| `PK_` | Primary key | `PK_TaskAssignments` |
| `FK_` | Foreign key — `FK_<child>_<role>` | `FK_Tasks_Parent`, `FK_Comments_Author` |
| `UQ_` | Unique constraint — `UQ_<table>_<column>` | `UQ_Users_Email` |
| `CK_` | Check — `CK_<table>_<rule>` | `CK_Projects_Dates` |
| `DF_` | Default — `DF_<table>_<column>` | `DF_TimeEntries_Billable` |
| `UX_` / `IX_` | Unique / non-unique index | `UX_TaskAssignments_OnePrimary` |

Note `FK_Tasks_Parent` and `FK_Comments_Author`: the suffix names the **role**, not the column. That matters when one child references the same parent twice — `app.Projects` points at `app.Users` as owner and at `app.Teams` as team, and `app.Comments` points at `app.Users` as author while `app.Tasks` points at it as creator.

An unnamed constraint gets a system-generated name with a random hex suffix:

```
CK__Tasks__Estimated__3E52440B
```

That name is **different in every environment**. Consequences: schema-comparison tools report false differences forever, `DROP CONSTRAINT` cannot be scripted, error messages are unreadable in a support ticket, and idempotent migration scripts become impossible to write. Only `PRIMARY KEY` and `UNIQUE` declared inline are safe to leave unnamed — and even they should not be.

> **Rule of thumb:** If you cannot type the constraint's name from memory when it fires at 3am, it is not named well enough.

---

## 12. Error Numbers and Evaluation Order

| Error | Raised by | Message begins |
|---|---|---|
| **515** | `NOT NULL` | `Cannot insert the value NULL into column …` |
| **2627** | `PRIMARY KEY` or `UNIQUE` **constraint** | `Violation of PRIMARY KEY constraint …` / `Violation of UNIQUE KEY constraint …` |
| **2601** | Unique **index** (including filtered) | `Cannot insert duplicate key row in object … with unique index …` |
| **547** | `FOREIGN KEY` **or** `CHECK` | `The <stmt> statement conflicted with the …` |
| **1785** | DDL: multiple cascade paths | `Introducing FOREIGN KEY constraint … may cause cycles …` |
| **1046** | DDL: subquery in a `CHECK` | `Subqueries are not allowed in this context.` |
| **8152 / 2628** | Data type overflow | `String or binary data would be truncated …` |

Two behaviours to internalise:

1. **The statement stops at the first violation and the whole statement rolls back.** A 1000-row `INSERT … SELECT` that hits one bad row inserts *nothing*. This is statement-level atomicity and it is not configurable. If you need partial success, batch the rows or stage-and-validate (§14).
2. **Only the first error is reported.** A row that violates three constraints produces one message. Fixing it and retrying reveals the next.

The order in which constraint types are evaluated is not contractually documented across all cases, so do not build logic on it. What *is* reliable: `DEFAULT` values are materialised before any constraint runs; `INSTEAD OF` triggers fire before constraints; and all constraints are checked before `AFTER` triggers fire. If an `AFTER` trigger runs, every constraint on the table has already passed.

---

## 13. Untrusted Constraints — the Silent Optimizer Tax

This is the part of the topic that separates people who *declare* constraints from people who *rely* on them.

SQL Server tracks, per constraint, whether it has verified that **all existing rows** satisfy it. That flag is `is_not_trusted`. An untrusted constraint is still enforced for new writes — but the query optimizer **ignores it completely** when simplifying plans.

| Statement | Enforced for new DML | Trusted (optimizer uses it) |
|---|---|---|
| `ALTER TABLE … ADD CONSTRAINT …` (default is `WITH CHECK`) | Yes | **Yes** |
| `ALTER TABLE … WITH NOCHECK ADD CONSTRAINT …` | Yes | **No** |
| `ALTER TABLE … NOCHECK CONSTRAINT …` | **No** | No |
| `ALTER TABLE … CHECK CONSTRAINT …` | Yes | **No** — still untrusted |
| `ALTER TABLE … WITH CHECK CHECK CONSTRAINT …` | Yes | **Yes** |

The doubled `CHECK CHECK` is not a typo. The first is the validation option, the second is the verb.

### What you lose

**Join elimination.** With a trusted FK and a `NOT NULL` child column, SQL Server knows the parent row must exist and removes the join entirely when no parent columns are selected:

```sql
-- Plan touches app.Tasks ONLY. app.Projects is eliminated.
SELECT t.TaskId, t.Title
FROM app.Tasks    AS t
JOIN app.Projects AS p ON p.ProjectId = t.ProjectId;
```

Untrust the constraint and the join comes back:

```sql
ALTER TABLE app.Tasks NOCHECK CONSTRAINT FK_Tasks_Project;
-- Re-run the query: the plan now scans app.Projects and joins. Same rows, more work.
ALTER TABLE app.Tasks WITH CHECK CHECK CONSTRAINT FK_Tasks_Project;
```

**Predicate simplification.** A trusted `CHECK (Hours > 0 AND Hours <= 24)` lets the optimizer prove `WHERE te.Hours > 30` returns nothing and compile a constant scan that reads zero pages. Untrusted, it scans the table to discover the same thing.

Also lost: partition elimination that depends on a `CHECK`, indexed-view matching, and the constraint-based contradiction detection that makes filtered indexes usable.

### Finding them

```sql
SELECT
    'FOREIGN KEY' AS Kind,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + N'.' + OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.name       AS ConstraintName,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys AS fk
WHERE fk.is_not_trusted = 1 OR fk.is_disabled = 1
UNION ALL
SELECT
    'CHECK',
    OBJECT_SCHEMA_NAME(cc.parent_object_id) + N'.' + OBJECT_NAME(cc.parent_object_id),
    cc.name,
    cc.is_disabled,
    cc.is_not_trusted
FROM sys.check_constraints AS cc
WHERE cc.is_not_trusted = 1 OR cc.is_disabled = 1
ORDER BY Kind, TableName, ConstraintName;
```

On a freshly seeded `TaskFlowDb` this returns **0 rows** — every constraint was created with its table and validated on the spot. On a database that has survived three years of data migrations it typically returns dozens, and nobody knows.

> **Rule of thumb:** Run this query in every environment as part of your deployment health check, and fail the pipeline if it returns rows. An untrusted constraint is a silent, permanent, compounding performance regression that no amount of index tuning will fix.

---

## 14. Disabling and Re-Enabling for Bulk Loads

Loading tens of millions of rows into a table with a dozen foreign keys is the one legitimate reason to switch constraints off.

```sql
-- 1. Disable every FK and CHECK on the target
ALTER TABLE app.TimeEntries NOCHECK CONSTRAINT ALL;

-- 2. Bulk load (BULK INSERT / bcp / SqlBulkCopy / INSERT ... SELECT)

-- 3. Re-enable AND revalidate. Both keywords are required.
ALTER TABLE app.TimeEntries WITH CHECK CHECK CONSTRAINT ALL;

-- 4. Prove it worked
SELECT fk.name, fk.is_disabled, fk.is_not_trusted
FROM sys.foreign_keys AS fk
WHERE fk.parent_object_id = OBJECT_ID(N'app.TimeEntries');
-- is_disabled = 0 AND is_not_trusted = 0 on every row, or the load is not finished.
```

Step 3 is where teams fail. Writing `ALTER TABLE … CHECK CONSTRAINT ALL` re-enables enforcement without validating the loaded rows, leaving `is_not_trusted = 1` forever. And if the data really is bad, `WITH CHECK` tells you immediately:

```
Msg 547, Level 16, State 0
The ALTER TABLE statement conflicted with the FOREIGN KEY constraint "FK_TimeEntries_Task".
The conflict occurred in database "TaskFlowDb", table "app.Tasks", column 'TaskId'.
```

Find the offending rows with the anti-join the constraint would have run:

```sql
SELECT te.TimeEntryId, te.TaskId
FROM app.TimeEntries AS te
WHERE NOT EXISTS (SELECT 1 FROM app.Tasks AS t WHERE t.TaskId = te.TaskId);
```

Two limits: **you cannot `NOCHECK` a `PRIMARY KEY` or `UNIQUE` constraint** — uniqueness is a property of the index, so the only lever is `ALTER INDEX … DISABLE`, and disabling a *clustered* index makes the entire table inaccessible until it is rebuilt. And `NOCHECK` is metadata-only and takes a schema-modification lock, so it is not free on a busy table.

---

## 15. Where Should a Rule Live?

| Rule | Declarative constraint | Application code | Trigger | Verdict |
|---|---|---|---|---|
| `Title` must have a value | `NOT NULL` | Also, for the message | — | **Both** — DB for truth, app for UX |
| `StatusId` must be a known status | FK to `ref.TaskStatuses` | — | — | **Constraint** |
| `Hours` between 0 and 24 | `CHECK` | Also | — | **Both** |
| `EndDate >= StartDate` | `CHECK` | Also | — | **Both** |
| `Email` unique | `UNIQUE` | Pre-check for a friendly message | — | **Constraint** is authoritative; the pre-check is a race |
| Project code unique among non-archived | Filtered unique index | — | — | **Filtered index** |
| At most one primary assignee per task | Filtered unique index | — | — | **Filtered index** |
| Logged hours must not exceed 2× the estimate | — | Convenient | Correct | **Trigger** — it is cross-row |
| A task cannot move from `Done` back to `Backlog` | — | — | Needs `deleted`/`inserted` | **Trigger** or stored procedure |
| Password ≥ 12 characters | — | Yes | — | **Application** — never store the raw value |
| Field-level error messages for the UI | — | Yes | — | **Application** — 2627 is not user copy |
| Only a team lead may archive a project | — | Authorisation layer | — | **Application** (+ RLS, Topic 19) |

Three principles fall out of that table:

1. **Validate in the application for the user, in the database for the truth.** They are different jobs. The API returns "Email already registered" in 20ms without a round trip; the `UNIQUE` constraint is what makes the claim actually true under concurrency.
2. **Every application-only rule is eventually violated.** Not by the application — by the import job, the hotfix script, or the second service that was written later.
3. **A constraint is documentation that cannot go stale.** `CK_Projects_Dates` tells the next developer more reliably than any wiki page that an end date is never before a start date.

> **Anti-pattern:** "The ORM validates it, so we do not need the constraint." Entity Framework validates the rows *it* writes. It does not validate the reporting ETL, the Dapper-based bulk importer, the admin console, the support script, or the replica that a data engineer writes to directly. Constraints do.

---

## 16. Interrogating Constraints

```sql
-- Primary keys and unique constraints: 13 PK + 6 UQ
SELECT
    OBJECT_SCHEMA_NAME(kc.parent_object_id) + N'.' + OBJECT_NAME(kc.parent_object_id) AS TableName,
    kc.name      AS ConstraintName,
    kc.type_desc AS ConstraintType
FROM sys.key_constraints AS kc
ORDER BY ConstraintType, TableName;

-- Check constraints with their expressions: 6 rows
SELECT
    OBJECT_NAME(cc.parent_object_id) AS TableName,
    cc.name                          AS ConstraintName,
    cc.definition                    AS Expression,
    cc.is_not_trusted
FROM sys.check_constraints AS cc
ORDER BY TableName, cc.name;

-- Default constraints: 16 rows
SELECT
    OBJECT_NAME(dc.parent_object_id)                   AS TableName,
    COL_NAME(dc.parent_object_id, dc.parent_column_id) AS ColumnName,
    dc.name                                            AS ConstraintName,
    dc.definition                                      AS DefaultExpression
FROM sys.default_constraints AS dc
ORDER BY TableName, ColumnName;

-- Foreign key columns, in key order (catches composite-FK mistakes): 20 rows
SELECT
    fk.name                                                      AS ForeignKey,
    fkc.constraint_column_id                                     AS Ordinal,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id)         AS ChildColumn,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM sys.foreign_keys        AS fk
JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
ORDER BY ForeignKey, Ordinal;

-- Tables with no primary key: 0 rows here, and it must stay that way
SELECT s.name + N'.' + t.name AS TableName
FROM sys.tables  AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE NOT EXISTS (SELECT 1 FROM sys.key_constraints AS kc
                  WHERE kc.parent_object_id = t.object_id AND kc.type = 'PK');
```

| View | Use it for | Blind spot |
|---|---|---|
| `sys.key_constraints` | PK and UQ, `type_desc` | Does not include standalone unique indexes |
| `sys.foreign_keys` | Referential actions, **trust**, disabled state | — |
| `sys.foreign_key_columns` | Composite FK column order | Column *names* need `COL_NAME()` |
| `sys.check_constraints` | Expression text, trust | — |
| `sys.default_constraints` | Default expression text | — |
| `sys.indexes` | `is_unique`, `is_unique_constraint`, `has_filter`, `filter_definition` | — |
| `sys.columns` | `is_nullable`, `is_computed`, `is_identity` | — |
| `INFORMATION_SCHEMA.*` | ANSI-portable inventory | **No trust state, no filtered indexes, no disabled flag** |

`INFORMATION_SCHEMA` is the right choice only when the same script must run on PostgreSQL or MySQL. For anything SQL Server-specific — and *trust is SQL Server-specific* — use `sys.`.

---

## 17. Portability

| Behaviour | SQL Server | PostgreSQL | MySQL (InnoDB) | Oracle |
|---|---|---|---|---|
| NULLs in a single-column `UNIQUE` | **Exactly one** | Unlimited; `NULLS NOT DISTINCT` in 15+ | Unlimited | Unlimited |
| Partial / filtered unique index | `CREATE UNIQUE INDEX … WHERE` | `CREATE UNIQUE INDEX … WHERE` | **No** | **No** (function-based index trick) |
| PK creates a clustered index by default | **Yes** | No (heap + B-tree) | Yes (InnoDB clusters on PK) | No |
| `ON DELETE SET DEFAULT` | Yes | Yes | **Not supported** | **Not supported** |
| Deferrable constraints | **No** | `DEFERRABLE INITIALLY DEFERRED` | No | Yes |
| Multiple cascade paths | **Rejected (1785)** | Allowed | Allowed | Allowed |
| `CHECK` constraints enforced | Yes | Yes | 8.0.16+ (parsed and ignored before) | Yes |
| Trust / validation metadata | `is_not_trusted` | `pg_constraint.convalidated` | n/a | `USER_CONSTRAINTS.VALIDATED` + `RELY` |
| Add a constraint without validating | `WITH NOCHECK` | `NOT VALID`, then `VALIDATE CONSTRAINT` | `SET FOREIGN_KEY_CHECKS = 0` (session) | `ENABLE NOVALIDATE` |
| Range-overlap exclusion | Trigger | `EXCLUDE USING gist (… WITH &&)` | Trigger | Trigger |
| Case sensitivity of a `LIKE` check | Collation-dependent | Case-sensitive by default | Collation-dependent | Case-sensitive by default |

The two rows that break real migrations are the first and the fifth. Porting a PostgreSQL table with three NULL rows in a `UNIQUE` column into SQL Server fails at load time; porting a SQL Server design that relies on the one-NULL rule to PostgreSQL silently loses the constraint.

---

## 18. Anti-Pattern Museum

| Anti-pattern | Why it is wrong | Do this instead |
|---|---|---|
| No primary key on a table | No stable row identity; replication, EF Core tracking and `MERGE` all break | Every table gets a PK, no exceptions |
| Unnamed constraints | System names differ per environment; scripts and diffs break | `PK_`/`FK_`/`UQ_`/`CK_`/`DF_` on everything |
| `WITH NOCHECK` left in place after a migration | Silent, permanent optimizer regression | `WITH CHECK CHECK CONSTRAINT` and verify `is_not_trusted = 0` |
| Scalar UDF inside a `CHECK` to fake a cross-row rule | Not evaluated on `DELETE`; not concurrency-safe; per-row function call | Filtered index, indexed view, or trigger |
| `CHECK (col > 0)` used to mean "required and positive" | NULL passes | Add `NOT NULL`, or write `col IS NOT NULL AND col > 0` |
| FKs removed "for performance" | Loses join elimination and correctness | Index the child column instead |
| `ON DELETE CASCADE` everywhere | Invisible mass deletions; `@@ROWCOUNT` does not report them | Cascade only down composition edges |
| `ON UPDATE CASCADE` on a surrogate key | Surrogate keys never change; the constraint is dead weight signalling a design error | Remove it |
| Uniqueness enforced by a `SELECT` before the `INSERT` | Two sessions both pass the check, both insert | `UNIQUE` constraint; catch 2627 |
| Storing "unknown" as `''`, `0`, `'N/A'` or `1900-01-01` | Poisons aggregates and comparisons; the sentinel eventually collides with a real value | `NULL`, plus a documented meaning |
| Constraints only in the ORM | Every non-ORM writer bypasses them | Both layers |

---

## Mental Model

> Constraints are the **only** rules in the system that nothing can bypass — not the ORM, not the ETL, not the 2am hotfix script — because they are enforced inside the write's own transaction. Four categories cover almost everything: entity integrity is `PRIMARY KEY`/`UNIQUE`, referential integrity is `FOREIGN KEY`, domain integrity is the data type plus `NOT NULL`, `CHECK` and `DEFAULT`, and everything left over is user-defined. The traps are all about NULL and trust: a `UNIQUE` constraint in SQL Server allows exactly **one** NULL where the standard allows many, so "optional but unique" needs a **filtered unique index**; a `CHECK` passes on NULL because `UNKNOWN` is not `FALSE`, so "required" is always `NOT NULL` and never a `CHECK`; and a constraint added `WITH NOCHECK` is still enforced but is **invisible to the optimizer** until you run `WITH CHECK CHECK CONSTRAINT` and confirm `is_not_trusted = 0`. A `CHECK` can only see its own row — the moment a rule needs a sibling row, it belongs in a filtered index, an indexed view, or a trigger. And when SQL Server refuses your `CASCADE` with error 1785, the second cascade path is nearly always redundant: fix the design, do not write a trigger.

Move to [Practice Problems](./Practice-Problems.md).
