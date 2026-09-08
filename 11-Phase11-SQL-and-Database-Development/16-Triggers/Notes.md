# Topic 16: Triggers

> A `CHECK` constraint can only see one row. A foreign key can only enforce "this value exists elsewhere." The moment TaskFlow needs a rule that spans rows within the same statement, needs to log *what changed* rather than just *that* a row changed, or needs a table to be read-only except through a specific view, none of the mechanisms from Topic 11 or Topic 14 are enough — that is exactly the gap triggers fill. This topic covers `AFTER` and `INSTEAD OF` triggers, the `inserted`/`deleted` pseudo-tables that make them work, why every trigger must be written set-based, and a clear-eyed look at when a trigger is the wrong answer.

---

## 1. What a Trigger Is, and the Two Kinds

A trigger is a block of T-SQL that fires automatically when a DML statement (or certain DDL statements) runs against a table or view — never called directly.

| Type | Fires | Sees the change as | Can it stop the write? |
|---|---|---|---|
| **`AFTER`** (`FOR` is a synonym) | After the data modification has happened, still inside the same transaction | `inserted`/`deleted` reflect the **post-modification** state | Yes — a `ROLLBACK`/`THROW` inside it undoes everything, including the base operation |
| **`INSTEAD OF`** | **In place of** the modification — the base operation never runs unless the trigger explicitly performs it | `inserted`/`deleted` reflect what *would have* been written | The trigger decides entirely what (if anything) actually happens |

```sql
USE TaskFlowDb;
GO

CREATE OR ALTER TRIGGER audit.trg_Tasks_StatusChange
ON app.Tasks
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(StatusId) RETURN;                  -- fast exit if this column wasn't touched

    INSERT INTO audit.TaskHistory (TaskId, ColumnName, OldValue, NewValue)
    SELECT d.TaskId, N'StatusId', CAST(d.StatusId AS NVARCHAR(400)), CAST(i.StatusId AS NVARCHAR(400))
    FROM deleted AS d
    JOIN inserted AS i ON i.TaskId = d.TaskId
    WHERE d.StatusId <> i.StatusId;
END;
GO
```

`AFTER` triggers exist only on **tables** (never views). `INSTEAD OF` triggers exist on **both tables and views** — and are the standard mechanism for making a non-updatable view (Topic 14 §3) writable.

---

## 2. `inserted` and `deleted`: The Pseudo-Tables

Every trigger has access to two special, in-memory tables reflecting the rows affected by the statement that fired it — the same two tables the `OUTPUT` clause exposes (Topic 10).

| Statement | `inserted` | `deleted` |
|---|---|---|
| `INSERT` | New rows | Empty |
| `DELETE` | Empty | Removed rows |
| `UPDATE` | New values | Old values |
| `MERGE` | Depends on which action fired, per row | Depends on which action fired, per row |

```sql
-- A single statement can insert MANY rows -- inserted/deleted always hold the WHOLE set,
-- never just one row. This is the entire reason "write it set-based" is not optional.
INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
VALUES (1, N'Task A', 1, 3, 4), (1, N'Task B', 1, 3, 4), (1, N'Task C', 1, 3, 4);
-- trg would see 3 rows in `inserted` for this one firing, not three separate firings.
```

`UPDATE(ColumnName)` inside a trigger body is a cheap, column-level check of whether that column appeared in the statement's `SET` list at all — it says nothing about whether the *value* actually changed, only whether it was targeted. Comparing `deleted.Col <> inserted.Col` (as in §1) is how you detect an actual value change.

---

## 3. The Cardinal Rule: Always Set-Based, Never Row-by-Row

The single most common trigger bug is assuming exactly one row fired the trigger.

```sql
-- WRONG: assumes a single-row UPDATE. Silently processes only ONE of several rows,
-- or errors, if the firing statement affected more than one row.
CREATE OR ALTER TRIGGER audit.trg_Tasks_Bad
ON app.Tasks AFTER UPDATE
AS
BEGIN
    DECLARE @TaskId INT, @NewStatus TINYINT;
    SELECT @TaskId = TaskId, @NewStatus = StatusId FROM inserted;   -- picks an arbitrary row if >1
    UPDATE app.Projects SET IsArchived = 0 WHERE ProjectId = (SELECT ProjectId FROM app.Tasks WHERE TaskId = @TaskId);
END;
```

```sql
-- RIGHT: joins the whole inserted/deleted set, correct for 1 row or 10,000.
CREATE OR ALTER TRIGGER audit.trg_Tasks_Good
ON app.Tasks AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET p.IsArchived = 0
    FROM app.Projects AS p
    JOIN inserted AS i ON i.ProjectId = p.ProjectId;
END;
```

> **Rule of thumb:** If a trigger body contains `SELECT @var = col FROM inserted` with no `TOP`/aggregate reasoning, it is almost certainly broken for multi-row statements. Every trigger must be written and tested against a multi-row `INSERT`/`UPDATE`/`DELETE`, not just a single-row one.

---

## 4. `AFTER` Triggers for Cross-Row Business Rules

This is the mechanism Topic 11 promised for rules a `CHECK` constraint cannot express — anything that must inspect **other rows**, not just the row being written.

```sql
-- Rule: total logged hours on a task must not exceed twice its estimate.
CREATE OR ALTER TRIGGER app.trg_TimeEntries_HoursCap
ON app.TimeEntries
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT TaskId FROM inserted) AS chg
        JOIN app.Tasks AS t ON t.TaskId = chg.TaskId
        WHERE t.EstimatedHours IS NOT NULL
          AND (SELECT SUM(te.Hours) FROM app.TimeEntries AS te WHERE te.TaskId = chg.TaskId)
              > 2 * t.EstimatedHours
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Logged hours would exceed twice the task''s estimate.', 1;
    END;
END;
```

Notice the trigger re-reads `app.TimeEntries` **after** the write already happened (`AFTER` semantics) to compute the new total — this is correct and necessary, because the rule depends on the aggregate across all rows for the task, not just the newly inserted ones.

Multiple `AFTER` triggers can exist on the same table and same event; execution order among them is not guaranteed unless explicitly set via `sp_settriggerorder` (`FIRST`/`LAST`; anything in between is unordered) — a good reason to prefer **one** trigger per table per timing (`INSERT`/`UPDATE`/`DELETE` can share one trigger body via `IF UPDATE(...)`/`COLUMNS_UPDATED()` checks) rather than several independent ones.

---

## 5. `INSTEAD OF` Triggers: Making a View Writable

A view joining multiple tables, or containing aggregation, is not directly updatable (Topic 14 §3). An `INSTEAD OF` trigger intercepts the write and decides, in code, what should actually happen to the base tables.

```sql
CREATE VIEW app.vw_TaskWithProjectName AS
SELECT t.TaskId, t.Title, t.StatusId, p.ProjectName
FROM app.Tasks AS t
JOIN app.Projects AS p ON p.ProjectId = t.ProjectId;
GO

CREATE OR ALTER TRIGGER app.trg_vw_TaskWithProjectName_Update
ON app.vw_TaskWithProjectName
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET t.Title = i.Title, t.StatusId = i.StatusId
    FROM app.Tasks AS t
    JOIN inserted AS i ON i.TaskId = t.TaskId;

    -- Deliberately NOT propagating ProjectName back to app.Projects here --
    -- a design decision to make, documented, not an oversight.
END;
GO

UPDATE app.vw_TaskWithProjectName SET Title = N'Renamed via view' WHERE TaskId = 1;  -- now works
```

`INSTEAD OF` triggers are also used directly on **tables** for soft-delete enforcement — intercepting a `DELETE` and turning it into an `UPDATE` instead:

```sql
CREATE OR ALTER TRIGGER app.trg_Projects_SoftDelete
ON app.Projects
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p SET p.IsArchived = 1
    FROM app.Projects AS p
    JOIN deleted AS d ON d.ProjectId = p.ProjectId;
    -- The actual DELETE never happens -- rows are archived instead.
END;
```

> **Rule of thumb:** A table can have only one `INSTEAD OF` trigger per DML event (`INSERT`/`UPDATE`/`DELETE`), unlike `AFTER` triggers which allow several. Design it as the single source of truth for "what does a delete against this table actually mean."

---

## 6. `THROW`/`ROLLBACK` Inside Triggers, and the Danger of Silent Failure

An uncaught error or explicit `ROLLBACK` inside an `AFTER` trigger rolls back the **entire transaction**, including the original statement that fired the trigger — this is what makes triggers a genuine enforcement mechanism, not just a notification.

```sql
BEGIN TRY
    INSERT INTO app.TimeEntries (TaskId, UserId, WorkDate, Hours) VALUES (1, 4, '2025-09-01', 100.00);
    -- If trg_TimeEntries_HoursCap fires and rolls back, this whole statement (and any
    -- earlier work in the same transaction) is undone.
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
```

The opposite danger is a trigger that **swallows an error silently** (a `CATCH` block that logs and does nothing else) — the calling application believes its `INSERT` succeeded, `@@ROWCOUNT` may even look normal, but a side effect the business depends on quietly never happened. Triggers should either enforce a rule loudly (`THROW`) or perform a side effect reliably — never both attempt and silently give up.

---

## 7. Nested and Recursive Triggers

| Setting | Controls | Default |
|---|---|---|
| **Nested triggers** (server-level, `sp_configure`) | Whether a trigger's own DML (e.g. the trigger's `INSERT` into `audit.TaskHistory`) can fire *another* table's trigger | **On** by default |
| **Recursive triggers** (database-level, `ALTER DATABASE ... SET RECURSIVE_TRIGGERS`) | Whether a trigger's DML against **the same table** it's already firing on can re-fire itself | **Off** by default |

```sql
-- With RECURSIVE_TRIGGERS OFF (the default), this trigger's own UPDATE against app.Tasks
-- does NOT re-fire itself -- preventing an infinite loop by default.
CREATE OR ALTER TRIGGER app.trg_Tasks_TouchModified
ON app.Tasks AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Title) OR UPDATE(StatusId)
        UPDATE t SET t.ModifiedAtUtc = SYSUTCDATETIME() FROM app.Tasks AS t JOIN inserted AS i ON i.TaskId = t.TaskId;
END;
```

A chain of triggers across **different** tables (nested) can still cascade unexpectedly deep — an `INSERT` into A fires a trigger that inserts into B, which fires a trigger that updates C, and so on. Beyond two or three hops, this becomes very difficult to reason about or debug, and is one of the concrete reasons triggers get a reputation for "spooky action at a distance."

---

## 8. Triggers vs Application Logic vs Constraints — Decision Table

| Requirement shape | Right tool |
|---|---|
| A rule about one row's own columns | `CHECK` constraint (Topic 11) |
| A rule referencing another table's existing row | `FOREIGN KEY` (Topic 11) |
| A rule spanning **multiple rows of the same table**, enforced synchronously, must never be bypassable | **`AFTER` trigger** |
| Making a complex view writable | **`INSTEAD OF` trigger** |
| Redirecting a `DELETE` into a soft-delete `UPDATE` | **`INSTEAD OF` trigger** |
| An audit trail of every change | `AFTER` trigger, or `OUTPUT` in the originating DML (Topic 10) if you control every write path |
| A rule that's really a UI/UX concern (e.g. "warn but allow") | Application logic — a trigger cannot "warn," only allow or roll back |
| A rule requiring calling an external system (email, webhook) | **Never a trigger** — triggers run inside the write's transaction; a slow or failing external call blocks/fails the write itself |
| Complex, frequently-changing business logic | Application logic — easier to test, version, and deploy independently of a schema migration |

> **Rule of thumb:** Reach for a trigger only when the rule must hold **no matter which client or code path performs the write** — including a DBA's ad hoc script, an ETL job, and a future developer who's never read the application code. If every write path already goes through one application layer or one stored procedure, put the logic there instead; it's easier to read, test, and change.

---

## 9. Performance and Maintenance Considerations

- **Every trigger adds cost to every qualifying DML statement**, even a trigger that ultimately does nothing (an early `IF NOT UPDATE(...) RETURN;` still costs a small check). A `BULK INSERT` of a million rows through a table with an expensive `AFTER INSERT` trigger pays that trigger's cost for the whole batch, not per row — but the trigger body itself must still be efficient, because it runs once against a potentially huge `inserted` set.
- **Triggers are invisible at the call site.** A plain `UPDATE app.Tasks SET StatusId = 6 WHERE TaskId = 5;` gives no textual hint that it will also write to `audit.TaskHistory`, check an hours cap, and touch `ModifiedAtUtc` — discoverability requires checking `sys.triggers`, not just reading the calling code.
- **`sys.triggers`** and **`sys.trigger_events`** are the catalog views for auditing what triggers exist and what events they respond to — a periodic "what triggers exist on this database and why" review is worthwhile precisely because they're easy to forget about.

```sql
SELECT OBJECT_NAME(tr.parent_id) AS TableName, tr.name AS TriggerName,
       tr.is_instead_of_trigger, tr.is_disabled
FROM sys.triggers AS tr
WHERE tr.is_ms_shipped = 0;
```

---

## Mental Model

> A trigger is the enforcement mechanism for exactly the rules Topic 11's constraints cannot express — anything that needs to see other rows, needs to run as a side effect of a write, or needs to redirect a write into something else entirely — and it earns that power by running inside the same transaction as the statement that fired it, so a `ROLLBACK`/`THROW` inside one undoes the whole write, not just the trigger's own action. That power comes with one non-negotiable discipline: `inserted` and `deleted` always represent the *entire set* of rows the firing statement touched, never just one, so a trigger written as if only a single row could ever fire it is not an edge case away from broken — it is already broken, waiting for the first multi-row `UPDATE` to prove it. `AFTER` triggers enforce and audit; `INSTEAD OF` triggers redirect and make the un-updatable updatable; and the deepest lesson of this topic is knowing when *not* to reach for either — a trigger is invisible at the call site, adds cost to every write whether it does anything or not, and is the wrong place for anything that's really an application concern, a UI warning, or a call to a system outside the database's own transaction.

Move to [Practice Problems](./Practice-Problems.md).
