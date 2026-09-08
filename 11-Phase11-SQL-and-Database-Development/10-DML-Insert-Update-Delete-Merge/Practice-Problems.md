# Topic 10: DML — Practice Problems

> Seven exercises covering every write statement, from a disciplined `INSERT` through a batched purge to a locked upsert. Work inside explicit transactions — every problem tells you when to commit and when to roll back. If your data drifts from the seeded state, re-run the create script.

**Concept tags:** `insert` `update` `delete` `output-clause` `merge` `upsert-race` `batching` `identity`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
-- This topic's DML is destructive. Wrap experiments in BEGIN TRANSACTION / ROLLBACK,
-- or re-run 00-create-taskflow-db.sql between problems to reset state.
```

---

## P1 — Disciplined `INSERT` and Identity Capture  *(Easy)*

**Tags:** `insert` `scope_identity` `output`

### Requirements

1. Insert three new rows into `app.Labels` using a single multi-row `VALUES` statement, with an explicit column list.
2. Capture all three generated `LabelId`s using `OUTPUT ... INTO` a table variable (not `SCOPE_IDENTITY()`, which only gives you the last one).
3. Demonstrate, with a comment showing the (bad) alternative, why omitting the column list is dangerous — simulate a reordered table by inserting into `(ColorHex, LabelName)` positionally against the real `(LabelName, ColorHex)` column order and show the wrong result.
4. Clean up your three inserted rows at the end of the script.

### Deliverable

`P1-insert-and-identity.sql`.

### Hints

- A table variable `DECLARE @NewLabels TABLE (LabelId INT, LabelName NVARCHAR(50))` is the standard way to capture multi-row `OUTPUT`.

### Look-fors (rubric)

- [ ] All three rows inserted in one statement.
- [ ] `OUTPUT INTO` correctly captures all three generated identities, not just one.
- [ ] The positional-insert danger is demonstrated concretely, not just described.
- [ ] Cleanup removes exactly the rows this script added.

---

## P2 — The `UPDATE ... FROM` Multi-Match Trap  *(Medium)*

**Tags:** `update-from` `non-determinism` `correlated-subquery`

### Requirements

1. Inside a transaction (rollback at the end), temporarily insert a second `IsPrimary = 1` row into `app.TaskAssignments` for a task that already has one — creating a genuine multi-match condition.
2. Write an `UPDATE ... FROM` that joins `app.Tasks` to `app.TaskAssignments` filtered on `IsPrimary = 1` and updates `app.Tasks.Title`. Run it and note that SQL Server does not error — it just picks one match.
3. Rewrite the same update using a correlated subquery that would instead **raise Msg 512** the moment more than one `IsPrimary = 1` row exists for a task.
4. Roll back the transaction and explain, in a comment, why the correlated-subquery version is the safer default even though it can fail loudly.

### Deliverable

`P2-update-from-trap.sql`.

### Hints

- `BEGIN TRANSACTION` at the top, `ROLLBACK TRANSACTION` at the bottom — never commit this experiment.

### Look-fors (rubric)

- [ ] The multi-match condition is genuinely created (verify with a `COUNT` before updating).
- [ ] The `UPDATE ... FROM` version is shown *not* erroring despite the ambiguity.
- [ ] The correlated-subquery version is shown *erroring* (Msg 512) under the same data.
- [ ] The transaction is rolled back — the seeded data is left unchanged.

---

## P3 — `OUTPUT` for an Audit Trail  *(Medium)*

**Tags:** `output` `audit` `inserted-deleted`

### Requirements

1. Update a single task's `StatusId` and `CompletedAtUtc`, and use `OUTPUT` to insert a row into `audit.TaskHistory` recording the column name, old value, and new value — in the same statement as the update.
2. Confirm `audit.TaskHistory` has no foreign key to `app.Tasks` (check `sys.foreign_keys`) and explain in a comment why that is deliberate.
3. Delete a task's comments (`app.Comments` for one `TaskId`) and use `OUTPUT` to simultaneously insert the deleted rows into a `#DeletedCommentsArchive` temp table, in one statement — no separate `SELECT` beforehand.
4. Verify the archived rows in the temp table match what was deleted.

### Deliverable

`P3-output-audit-trail.sql`. Roll back the `app.Tasks`/`app.Comments` changes at the end so the seed data is preserved.

### Hints

- `OUTPUT DELETED.col, ... INTO audit.TaskHistory (...)` for the `UPDATE`; `OUTPUT DELETED.* INTO #temp` for the `DELETE`.

### Look-fors (rubric)

- [ ] The audit row correctly captures old and new `StatusId` values.
- [ ] The "no FK on audit.TaskHistory" reasoning correctly explains survivability past task deletion.
- [ ] The comment archive is populated in the same statement as the delete, not a separate `SELECT` first.

---

## P4 — `DELETE` vs `TRUNCATE TABLE`: Side-by-Side Behaviour  *(Medium)*

**Tags:** `delete` `truncate` `identity-reseed` `foreign-key-block`

### Requirements

1. Copy `ref.Priorities` into a new unconstrained table `#PrioritiesCopy` (via `SELECT INTO`) with its own `IDENTITY`-like IntId column seeded from 1.
2. `DELETE` all rows from `#PrioritiesCopy`, then insert one row back, and observe the new identity value.
3. Reset `#PrioritiesCopy`, this time `TRUNCATE` it, insert one row back, and observe the new identity value. Compare against step 2.
4. Attempt to `TRUNCATE TABLE app.Tasks` (a table with incoming foreign keys) and capture the exact error. Explain why `DELETE FROM app.Tasks` with the same intent would behave differently (though also blocked by FK checks on any referenced-but-not-deleted child rows).

### Deliverable

`P4-delete-vs-truncate.sql`.

### Hints

- You'll need an `IDENTITY(1,1)` column on `#PrioritiesCopy` — `SELECT INTO` does not preserve the source's `IDENTITY` property, only values, so add it explicitly when creating the copy.

### Look-fors (rubric)

- [ ] The identity-reseed difference between `DELETE` and `TRUNCATE` is clearly demonstrated with actual before/after values.
- [ ] The `TRUNCATE` FK-block error is captured verbatim.
- [ ] The explanation of `DELETE`'s row-level FK check vs `TRUNCATE`'s blanket block is accurate.

---

## P5 — Batched Purge Loop  *(Medium)*

**Tags:** `delete-top` `batching` `while-loop`

### Requirements

1. Inside a throwaway `#temp` table, generate roughly 10,000 synthetic rows (use a cross-joined `VALUES`/`ROW_NUMBER` number series from Topic 07).
2. Write a `WHILE` loop that deletes from this temp table in batches of 1,000 using `DELETE TOP (1000)`, checking `@@ROWCOUNT` to terminate.
3. Add a `PRINT` (or `RAISERROR` with `NOWAIT`) inside the loop reporting progress after each batch.
4. In a comment, explain the two production risks (log growth, lock escalation) that this batching avoids compared to a single unbatched `DELETE`.

### Deliverable

`P5-batched-purge.sql`.

### Hints

- `SET NOCOUNT ON;` keeps the "(1 row affected)" messages from flooding the output inside the loop.
- Lock escalation's default row-count threshold is roughly 5,000 locks in one statement.

### Look-fors (rubric)

- [ ] The temp table actually reaches ~10,000 rows before the purge starts.
- [ ] The loop terminates correctly via `@@ROWCOUNT = 0`, not a hard-coded iteration count.
- [ ] Both named risks (log growth, lock escalation) are explained, not just listed.

---

## P6 — `MERGE` Upsert, `$action`, and Its Concurrency Caveat  *(Hard)*

**Tags:** `merge` `upsert` `holdlock` `dollar-action`

### Requirements

1. Write a `MERGE` against `app.Labels` that, from a `VALUES` source of 4 labels (2 existing, 2 new), updates `ColorHex` where it differs and inserts the missing ones. Use `OUTPUT $action` to report what happened per row.
2. Add a `WHEN NOT MATCHED BY SOURCE` branch that would delete any label not in the source list, but **guard it** with an additional condition so it only ever considers a specific test label (never accidentally wipe real labels) — explain why this guard matters.
3. Rewrite the same upsert as two explicit statements (`UPDATE` then `INSERT ... WHERE NOT EXISTS`) inside one transaction, and confirm they produce the same end state as the `MERGE` version.
4. Explain, in a comment, the specific concurrency race that an unguarded upsert (either the `MERGE` or the two-statement version) is vulnerable to, and which locking hint fixes it.

### Deliverable

`P6-merge-and-alternative.sql`. Roll back all changes at the end.

### Hints

- `WITH (HOLDLOCK)` on the `MERGE` target, or `WITH (UPDLOCK, HOLDLOCK)` on the `SELECT`/`IF NOT EXISTS` check in the two-statement version.

### Look-fors (rubric)

- [ ] `$action` correctly reports `'UPDATE'`/`'INSERT'` per affected row.
- [ ] The `WHEN NOT MATCHED BY SOURCE` guard is genuinely restrictive (cannot delete unrelated real labels even if the source list were empty).
- [ ] The two-statement alternative produces an identical end state to the `MERGE` version.
- [ ] The race condition explanation correctly names the locking hint and what it protects against (the *absence* of a row, not just an existing one).

---

## P7 — Cursor (RBAR) vs Set-Based Rewrite  *(Hard)*

**Tags:** `cursor` `rbar` `set-based`

### Requirements

1. Write a cursor-based loop that raises every `PriorityId = 3` (Medium) task on project 2 to `PriorityId = 2` (High), one row at a time.
2. Roll that back, then write the set-based single-statement equivalent.
3. Using `SET STATISTICS TIME ON`, compare the elapsed time of both approaches (the difference will be modest at this table's size, but the plan shape difference is the point).
4. Explain in a comment why the cursor version's cost does not scale linearly in a way you'd want in production — name the specific per-row overheads.

### Deliverable

`P7-cursor-vs-set-based.sql`. Roll back all changes at the end.

### Hints

- Per-row overheads to name: parsing/compilation reuse, locking granularity, transaction log records, network/procedure-call overhead if the loop lived in application code instead.

### Look-fors (rubric)

- [ ] The cursor version is syntactically correct and actually updates the right rows.
- [ ] The set-based rewrite produces an identical end state.
- [ ] At least two specific per-row overheads are named (not a generic "cursors are slow").

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every destructive experiment is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`, or the file ends by re-running the create script.
- [ ] No script leaves the seeded data permanently modified unless the problem explicitly says to keep the change (P1's cleanup step is the one exception, and it cleans up after itself).
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Wrap P6's safe upsert pattern in a reusable stored procedure `app.usp_UpsertLabel` and call it twice concurrently from two separate `sqlcmd` sessions to try to reproduce the race condition, with and without the locking hint.
- Investigate `sys.dm_tran_locks` during P5's batch loop to observe lock counts per batch and confirm they stay under the escalation threshold.
- Read the SQL Server documentation's known `MERGE` issues page and summarize, in your own words, one specific historical bug and the SQL Server version it was fixed in.
