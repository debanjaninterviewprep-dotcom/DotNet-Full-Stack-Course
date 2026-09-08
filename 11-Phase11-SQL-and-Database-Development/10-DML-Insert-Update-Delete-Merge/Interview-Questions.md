# Topic 10: DML — Interview Questions

---

## Q1. Why should you always specify a column list on `INSERT`, even for a table you know well?
**Answer:**
A positional `INSERT INTO Table VALUES (...)` maps values to columns purely by their current physical order. Any later `ALTER TABLE` that adds, drops, or reorders columns silently changes what each value means — with no compile error, only wrong data landing in the wrong column.

```sql
-- Fragile: relies on column order never changing.
INSERT INTO app.Labels VALUES (N'urgent', '#FF0000');

-- Robust: correct regardless of physical column order.
INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'urgent', '#FF0000');
```

---

## Q2. What is the difference between `SCOPE_IDENTITY()`, `@@IDENTITY`, and `IDENT_CURRENT()`?
**Answer:**

| Function | Scope | Risk |
|---|---|---|
| `SCOPE_IDENTITY()` | Last identity generated in the **current scope** (batch/procedure) | Safe default |
| `@@IDENTITY` | Last identity generated in the **current session**, any scope | Returns a trigger's identity instead of yours if a trigger on another table also inserts |
| `IDENT_CURRENT('table')` | Last identity generated for that table, **by any session** | Race condition under concurrency |

`SCOPE_IDENTITY()` is the correct default almost always, because it is immune to both traps.

---

## Q3. Why is `UPDATE ... FROM` with a join considered risky in T-SQL?
**Answer:**
If the joined table produces more than one matching row for a given target row, SQL Server does not error — it silently applies **one arbitrary match**, and the choice is undocumented and not guaranteed stable.

```sql
-- If a task somehow has two IsPrimary = 1 assignment rows, which one "wins" is undefined.
UPDATE t SET t.Title = t.Title + u.FullName
FROM app.Tasks AS t
JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId AND ta.IsPrimary = 1
JOIN app.Users AS u ON u.UserId = ta.UserId;
```

A correlated subquery is a safer default because it **fails loudly** (Msg 512) the moment the "exactly one match" assumption breaks, instead of silently picking one.

---

## Q4. What does the `OUTPUT` clause do, and what are `INSERTED`/`DELETED`?
**Answer:**
`OUTPUT` returns the rows a DML statement affected, using the same `INSERTED`/`DELETED` pseudo-tables that triggers use. `INSERT` populates `INSERTED` only; `DELETE` populates `DELETED` only; `UPDATE` populates both (new and old values respectively).

```sql
DECLARE @NewIds TABLE (TaskId INT);
INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
OUTPUT INSERTED.TaskId INTO @NewIds
VALUES (1, N'New task', 1, 2, 4);
```

`OUTPUT` is especially useful for capturing generated keys from a multi-row insert (where `SCOPE_IDENTITY()` only gives you the last one) and for building an audit trail without a separate trigger.

---

## Q5. Can `OUTPUT` feed directly into another statement?
**Answer:**
Yes — this is the composable DML pattern, most commonly used for archive-and-purge:

```sql
INSERT INTO audit.TaskHistory (TaskId, ColumnName, OldValue, NewValue)
SELECT TaskId, N'ARCHIVED', N'active', N'purged'
FROM (
    DELETE FROM app.Tasks
    OUTPUT DELETED.TaskId
    WHERE StatusId = 7 AND CreatedAtUtc < DATEADD(YEAR, -2, SYSUTCDATETIME())
) AS Purged;
```

This removes the window where a row exists in neither the source nor the archive — a separate `SELECT` followed by a `DELETE` has a gap between the two statements where a crash could lose the row entirely.

---

## Q6. What is the difference between `DELETE`, `TRUNCATE TABLE`, and `DROP TABLE`?
**Answer:**

| | `DELETE` | `TRUNCATE TABLE` | `DROP TABLE` |
|---|---|---|---|
| Scope | Rows matching `WHERE` (or all) | All rows, unconditionally | The table itself |
| `WHERE` clause | Yes | No | n/a |
| Logging | Fully logged, row-by-row | Minimally logged | Minimally logged |
| Fires triggers | Yes | No | n/a |
| Resets `IDENTITY` seed | No | Yes | n/a |
| Blocked by incoming FKs | Only if the specific row is referenced | Blocked outright, even with zero child rows | Blocked if dependents exist |
| Transactional/rollback-capable | Yes | **Yes** (a common misconception is that it isn't) | Yes |

---

## Q7. Why can `TRUNCATE TABLE` fail on a table that currently has zero rows referencing it from a child table?
**Answer:**
`TRUNCATE` is blocked by the mere **existence** of a foreign key referencing the table — it does not check whether any child rows currently exist. This is because `TRUNCATE` works by deallocating pages rather than deleting rows one at a time with referential checks, so SQL Server refuses it outright rather than verify emptiness first. `DELETE`, by contrast, checks referential integrity per row and succeeds as long as no *actual* child row currently references each deleted row.

---

## Q8. What does `MERGE` do, and what is `$action` used for?
**Answer:**
`MERGE` compares a source result set to a target table and applies `INSERT`/`UPDATE`/`DELETE` in a single statement based on `WHEN MATCHED`, `WHEN NOT MATCHED BY TARGET`, and `WHEN NOT MATCHED BY SOURCE` clauses — the classic "upsert."  `$action` in the `OUTPUT` clause reports which action fired per affected row (`'INSERT'`, `'UPDATE'`, or `'DELETE'`), useful for logging or downstream processing that needs to know exactly what happened.

```sql
MERGE app.Labels AS tgt
USING (VALUES (N'bug', '#D73A4A')) AS src (LabelName, ColorHex)
ON tgt.LabelName = src.LabelName
WHEN MATCHED THEN UPDATE SET tgt.ColorHex = src.ColorHex
WHEN NOT MATCHED THEN INSERT (LabelName, ColorHex) VALUES (src.LabelName, src.ColorHex)
OUTPUT $action, INSERTED.LabelName;
```

---

## Q9. Why do many experienced SQL Server teams avoid `MERGE` despite it being the "obvious" upsert tool?
**Answer:**
Several documented, non-obvious risks:
- **Historical correctness bugs** — Microsoft has shipped and fixed multiple `MERGE`-specific bugs over the years, particularly around triggers and constraints interacting with `MERGE`'s internal processing.
- **Concurrency requires an explicit locking hint** — under default isolation, two concurrent `MERGE` statements can both evaluate "not matched" for the same key and both attempt an insert, causing a primary-key violation instead of the expected atomic upsert; the fix is `WITH (HOLDLOCK)` on the target, which most examples omit.
- **Halloween-protection spooling** can add plan complexity.
- **A single `MERGE` can fire `INSERT`, `UPDATE`, and `DELETE` triggers all in one statement** — easy to overlook when a trigger assumes it only ever runs from one specific statement type.
- **Readability** — three independent `WHEN` branches are harder to review than two explicit, separately testable statements.

Many teams prefer an explicit `UPDATE` followed by `INSERT ... WHERE NOT EXISTS`, in a transaction, with `WITH (UPDLOCK, HOLDLOCK)` guarding the existence check.

---

## Q10. Describe a concurrency race condition in a naive upsert, and how to fix it.
**Answer:**
Two sessions can both run "check if a row exists, if not insert it" at nearly the same time:

1. Session A checks: row does not exist.
2. Session B checks: row does not exist (A hasn't committed/inserted yet).
3. Both proceed to `INSERT` — one succeeds, one raises a unique-constraint violation.

```sql
BEGIN TRANSACTION;
IF NOT EXISTS (SELECT 1 FROM app.Labels WITH (UPDLOCK, HOLDLOCK) WHERE LabelName = N'ai-generated')
    INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'ai-generated', '#6F42C1');
COMMIT TRANSACTION;
```

`UPDLOCK` takes an update lock as soon as the row (or the key range, if absent) is read, so a second session's read blocks until the first transaction commits. `HOLDLOCK` extends that protection to cover the *absence* of a row (equivalent to `SERIALIZABLE` for this statement) — without it, the key range isn't protected and both sessions can still race.

---

## Q11. What is RBAR, and why is it usually the wrong default in SQL Server?
**Answer:**
"Row-By-Agonizing-Row" — processing data one row at a time via a cursor or `WHILE` loop, instead of expressing the operation as a single set-based statement. Each iteration pays independent overhead: parsing/plan reuse, per-row locking, per-row log records, and (if the loop lives in application code) a network round trip per row.

```sql
-- RBAR: ~35 iterations, each with its own overhead.
DECLARE @TaskId INT;
DECLARE cur CURSOR FOR SELECT TaskId FROM app.Tasks WHERE PriorityId = 1;
OPEN cur; FETCH NEXT FROM cur INTO @TaskId;
WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE app.Tasks SET PriorityId = 2 WHERE TaskId = @TaskId;
    FETCH NEXT FROM cur INTO @TaskId;
END;

-- Set-based: one statement, one plan.
UPDATE app.Tasks SET PriorityId = 2 WHERE PriorityId = 1;
```

Legitimate cursor use is rare — mostly sequential administrative scripts (e.g. looping over database names to run a system procedure against each).

---

## Q12. How would you safely purge millions of old rows from a large, actively-used table?
**Answer:**
Batch the delete instead of running one giant transaction:

```sql
SET NOCOUNT ON;
WHILE 1 = 1
BEGIN
    DELETE TOP (1000) FROM audit.TaskHistory
    WHERE ChangedAtUtc < DATEADD(YEAR, -2, SYSUTCDATETIME());
    IF @@ROWCOUNT = 0 BREAK;
    WAITFOR DELAY '00:00:00.100';
END;
```

Batching bounds transaction log growth (so the log can truncate/ship between batches instead of holding every record until one massive commit), avoids lock escalation (SQL Server escalates to a table lock around roughly 5,000 locks in a single statement by default, blocking other sessions entirely), and keeps the operation resumable — if it's cancelled partway, the already-committed batches stay deleted rather than the whole thing rolling back.

---

## Q13. What happens to an `INSERT ... SELECT` of 1,000 rows if row 501 violates a `CHECK` constraint?
**Answer:**
The entire statement rolls back — **none** of the 1,000 rows are inserted, not just the offending one. A constraint violation aborts the whole DML statement it occurred in, because SQL statements are atomic by default (each statement is its own implicit transaction unless a larger explicit transaction wraps it). This is why validating or cleaning staged data before a bulk `INSERT ... SELECT` — or being prepared to diagnose and retry — matters for large loads.

---

## Q14. Why might `SELECT INTO` be a poor substitute for a properly designed target table?
**Answer:**
`SELECT ... INTO NewTable` creates a table with only the bare column types of the query's output — no primary key, no foreign keys, no `CHECK`/`DEFAULT` constraints, no indexes, and no `IDENTITY` property (only identity *values* carry over, not the property itself, unless you use the `IDENTITY()` function explicitly in the select list). It is well suited to a quick, disposable snapshot or staging table, but using it to "create" a real application table skips every integrity guarantee the schema is supposed to enforce.

---

## Q15. Design question: you need to upsert a batch of 10,000 rows from an external import into `app.Tasks` (some are new, some are updates to existing tasks matched by an external `SourceSystemId`). Walk through your approach, including how you would test correctness before running it against production.
**Answer:**
1. **Stage first.** Load the 10,000 rows into a `#StagingImport` (or a real staging table) with no constraints — this isolates "did the file parse/load correctly" from "did the upsert apply correctly."
2. **Validate before touching the target.** Run `SELECT` queries against the staging table checking for: duplicate `SourceSystemId`s within the batch itself, NULLs in required columns, values that would violate target `CHECK` constraints — fail fast with a clear report rather than letting the upsert statement itself error midway.
3. **Choose the upsert mechanism deliberately** — either a guarded `MERGE` (`WITH (HOLDLOCK)` on the target, tested for the specific SQL Server version's known issues) or two explicit statements (`UPDATE ... FROM` a correlated match, then `INSERT ... WHERE NOT EXISTS`) inside one explicit transaction with `SET XACT_ABORT ON`.
4. **Batch it** if 10,000 rows is large relative to the table's normal write volume, to bound lock duration; for 10,000 this is usually still fine as one transaction, but the decision should be based on measured lock/log impact, not a guess.
5. **Capture `OUTPUT $action`** (or the two-statement equivalent's row counts) so the run produces a concrete report: N inserted, N updated, N skipped/rejected — essential for validating a production run after the fact, and for re-running safely (idempotency) if the import needs to be retried.
6. **Test on a copy first.** Restore a recent backup or use a staging environment with production-like data volume, run the exact same script, and verify the reported counts match expectations before running against the live database.
