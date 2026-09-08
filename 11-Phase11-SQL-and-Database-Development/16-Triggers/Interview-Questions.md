# Topic 16: Triggers — Interview Questions

---

## Q1. What is the difference between an `AFTER` trigger and an `INSTEAD OF` trigger?
**Answer:**
An `AFTER` trigger fires once the data modification has already happened (still inside the same transaction) — `inserted`/`deleted` reflect the post-modification state, and it exists only on tables. An `INSTEAD OF` trigger fires **in place of** the modification — the base operation never runs unless the trigger body explicitly performs it — and it exists on both tables and views, most commonly used to make a non-updatable view writable or to redirect a `DELETE` into a soft-delete `UPDATE`.

---

## Q2. What are `inserted` and `deleted`, and what do they contain for each statement type?
**Answer:**
Two special, in-memory pseudo-tables available inside a trigger body, reflecting the rows affected by the firing statement — the same pseudo-tables the `OUTPUT` clause exposes.

| Statement | `inserted` | `deleted` |
|---|---|---|
| `INSERT` | New rows | Empty |
| `DELETE` | Empty | Removed rows |
| `UPDATE` | New values | Old values |

Critically, both always contain the **entire set** of rows the statement affected — never just one row, even for a single-row-looking `UPDATE ... WHERE Id = 5`.

---

## Q3. Why must every trigger be written "set-based," and what does a broken example look like?
**Answer:**
Because a single firing statement can affect many rows at once, and `inserted`/`deleted` always hold the whole set. A trigger that assumes exactly one row (e.g. `SELECT @var = col FROM inserted`) will, for a multi-row statement, either silently pick an arbitrary row's value or otherwise process only a fraction of what actually changed — with no error to reveal the bug.

```sql
-- WRONG: only "sees" one arbitrary row if the firing UPDATE touched several.
SELECT @TaskId = TaskId FROM inserted;

-- RIGHT: joins the whole inserted set, correct for any row count.
UPDATE p SET p.IsArchived = 0 FROM app.Projects AS p JOIN inserted AS i ON i.ProjectId = p.ProjectId;
```

---

## Q4. How would you detect whether a column's *value* actually changed inside an `UPDATE` trigger, versus merely being present in the `SET` list?
**Answer:**
`UPDATE(ColumnName)` only tells you the column was targeted by the statement's `SET` list — it says nothing about whether the value is actually different. To detect a genuine value change, compare `deleted.Col <> inserted.Col` (joined on the row's key) explicitly:

```sql
IF NOT UPDATE(StatusId) RETURN;   -- fast exit: column wasn't even targeted

INSERT INTO audit.TaskHistory (TaskId, ColumnName, OldValue, NewValue)
SELECT d.TaskId, N'StatusId', d.StatusId, i.StatusId
FROM deleted AS d JOIN inserted AS i ON i.TaskId = d.TaskId
WHERE d.StatusId <> i.StatusId;    -- only rows where the value genuinely differs
```

---

## Q5. Can a trigger stop a write from happening? How?
**Answer:**
Yes, for `AFTER` triggers — a `ROLLBACK TRANSACTION` or an uncaught `THROW`/error inside the trigger body rolls back the **entire transaction**, including the original statement that fired it. This is what gives triggers real enforcement power for rules a `CHECK` constraint can't express (rules spanning multiple rows). For `INSTEAD OF` triggers, the trigger simply decides whether to perform any operation at all — the original statement never runs on its own.

---

## Q6. Why can't a `CHECK` constraint enforce "total logged hours on a task must not exceed twice its estimate," and what's the correct mechanism?
**Answer:**
A `CHECK` constraint can only evaluate expressions using columns of the **same row** being written — it has no way to look at sibling rows (other time entries for the same task) or aggregate across them. An `AFTER INSERT, UPDATE` trigger on the time-entries table can re-query the aggregate after the write and roll back if it exceeds the limit:

```sql
CREATE TRIGGER app.trg_TimeEntries_HoursCap ON app.TimeEntries AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM (SELECT DISTINCT TaskId FROM inserted) AS chg
        JOIN app.Tasks AS t ON t.TaskId = chg.TaskId
        WHERE (SELECT SUM(Hours) FROM app.TimeEntries WHERE TaskId = chg.TaskId) > 2 * t.EstimatedHours
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, N'Logged hours would exceed twice the estimate.', 1;
    END;
END;
```

(An indexed view, per Topic 14, is an alternative mechanism for a similar-shaped rule, discussed there.)

---

## Q7. How do you make a multi-table view support `UPDATE`/`INSERT`/`DELETE`?
**Answer:**
An `INSTEAD OF` trigger on the view. The trigger receives `inserted`/`deleted` reflecting what the write against the view *would* have meant, and its body decides explicitly which base table(s) to actually modify:

```sql
CREATE TRIGGER app.trg_vw_TaskWithProjectName_Update
ON app.vw_TaskWithProjectName INSTEAD OF UPDATE
AS
BEGIN
    UPDATE t SET t.Title = i.Title, t.StatusId = i.StatusId
    FROM app.Tasks AS t JOIN inserted AS i ON i.TaskId = t.TaskId;
    -- Deliberately not propagating ProjectName to app.Projects -- a design choice to document.
END;
```

---

## Q8. What's a common pattern for implementing "soft delete" using triggers?
**Answer:**
An `INSTEAD OF DELETE` trigger that, instead of allowing the real row removal, performs an `UPDATE` setting a flag (e.g. `IsArchived = 1` or `DeletedAtUtc = SYSUTCDATETIME()`):

```sql
CREATE TRIGGER app.trg_Projects_SoftDelete ON app.Projects INSTEAD OF DELETE
AS
BEGIN
    UPDATE p SET p.IsArchived = 1 FROM app.Projects AS p JOIN deleted AS d ON d.ProjectId = p.ProjectId;
END;
```

Callers issuing a plain `DELETE FROM app.Projects WHERE ...` never actually remove the row — a design decision that must be well documented, since it silently changes what `DELETE` means for that table.

---

## Q9. Can more than one trigger exist on the same table for the same event? What controls their firing order?
**Answer:**
`AFTER` triggers: yes, multiple can coexist for the same event on the same table, but their execution order among each other is **not guaranteed** by default — only `sp_settriggerorder` lets you designate one as `FIRST` and one as `LAST`; anything else remains unordered. `INSTEAD OF` triggers: only **one** per DML event per table/view is allowed. The practical guidance is to prefer a single trigger per table per timing, using `IF UPDATE(...)` checks inside it to handle different concerns, rather than relying on multiple independent triggers with an unpredictable relative order.

---

## Q10. What's the difference between "nested triggers" and "recursive triggers" as SQL Server settings?
**Answer:**
**Nested triggers** (a server-level setting, on by default) controls whether a trigger's own DML can fire a trigger on a **different** table — e.g. a trigger on `app.Tasks` inserting into `audit.TaskHistory` can, if `audit.TaskHistory` itself had a trigger, cause that one to fire too. **Recursive triggers** (a database-level setting, off by default) controls whether a trigger's DML against the **same table** it's already firing on can re-trigger itself, which would otherwise risk infinite loops. The off-by-default recursive setting is why a trigger that updates its own table (e.g. touching a `ModifiedAtUtc` column) doesn't infinitely re-fire itself under default settings.

---

## Q11. Give an example of a business rule that sounds like a trigger candidate but should NOT be implemented as one.
**Answer:**
"When a task's status changes to Done, send the assignee an email notification." A trigger runs **inside** the write's own transaction — a slow, unreliable, or failing external call (an email/webhook service) inside a trigger would block or fail the underlying `UPDATE` itself, coupling completely unrelated failure domains (a flaky email provider now breaks task status updates). The correct pattern is to record the event durably within the transaction (e.g. an outbox table row, or the audit trail itself) and have a separate, independent process poll and send notifications asynchronously outside the database transaction.

---

## Q12. What's a concrete downside of triggers from a maintainability perspective?
**Answer:**
They are **invisible at the call site**. Reading `UPDATE app.Tasks SET StatusId = 6 WHERE TaskId = 5;` in application code gives no indication that this single statement might also write an audit row, enforce an hours cap, or update a `ModifiedAtUtc` timestamp — that logic only becomes visible by separately querying `sys.triggers`/`sys.trigger_events` or knowing to look. This "spooky action at a distance" is manageable with a small number of well-documented triggers per table, but becomes a real liability as trigger chains grow across multiple tables.

---

## Q13. Design question: your team wants an audit trail of every change to `app.Tasks`. Compare implementing it via a trigger versus via the `OUTPUT` clause on every write statement (Topic 10).
**Answer:**
**Trigger**: guarantees the audit trail fires for **every** write path, including ad hoc scripts, ETL jobs, and any future code nobody remembers to update — you cannot forget to call it, because it isn't called, it's attached to the table. Cost: invisible at the call site, adds overhead to every write whether needed or not, and one more object to keep in sync with schema changes.

**`OUTPUT` clause on every statement**: fully visible in the calling code, no hidden behavior, and slightly better performance (no separate trigger invocation machinery) — but only works if **every single write path** remembers to include it. A single missed `UPDATE` anywhere in the codebase (or a DBA's manual fix) silently produces no audit row, and there's no enforcement mechanism catching the omission.

The deciding factor is usually: how many independent write paths exist, and how much do you trust every one of them to remember the `OUTPUT` clause? For a table written only through one well-controlled stored-procedure layer, `OUTPUT` is often preferable for its visibility. For a table that might be touched by ad hoc scripts, migrations, or multiple applications, a trigger is the safer default because it cannot be bypassed by omission.
