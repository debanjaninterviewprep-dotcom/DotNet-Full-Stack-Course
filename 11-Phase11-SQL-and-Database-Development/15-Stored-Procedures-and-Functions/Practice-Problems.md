# Topic 15: Stored Procedures & Functions — Practice Problems

> Seven exercises from a basic parameterised procedure through the scalar-UDF performance trap to parameter sniffing. All against the seeded `TaskFlowDb`.

**Concept tags:** `stored-procedures` `output-parameters` `table-valued-parameters` `dynamic-sql` `sp_executesql` `try-catch` `throw` `scalar-functions` `inline-tvf` `parameter-sniffing`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — A Parameterised Procedure with Defaults and Output  *(Easy)*

**Tags:** `stored-procedures` `default-parameters` `output-parameters` `scope_identity`

### Requirements

1. Create `app.usp_GetTasksByProject (@ProjectId INT, @IncludeClosed BIT = 0)` returning `TaskId, Title, StatusId, PriorityId, DueDate`.
2. Call it once with only `@ProjectId` and once with `@IncludeClosed = 1`; confirm the row counts differ correctly.
3. Create `app.usp_CreateTask` with an `@NewTaskId INT OUTPUT` parameter, capturing `SCOPE_IDENTITY()`.
4. Call it, capture the output parameter into a variable, and use it in a follow-up `SELECT` proving the row exists.
5. Clean up the row you inserted and drop both procedures.

### Deliverable

`P1-basic-procedure.sql`.

### Hints

- `SET NOCOUNT ON` at the top of every procedure body.

### Look-fors (rubric)

- [ ] Both calls to the first procedure return correctly different row counts.
- [ ] The output parameter correctly captures the new `TaskId`.
- [ ] Cleanup removes the inserted row; both procedures are dropped.

---

## P2 — Table-Valued Parameters for Bulk Operations  *(Easy)*

**Tags:** `table-valued-parameters` `bulk-update` `user-defined-table-type`

### Requirements

1. Create a user-defined table type `app.TaskIdList (TaskId INT PRIMARY KEY)`.
2. Create `app.usp_BulkCloseTasks (@TaskIds app.TaskIdList READONLY)` that sets `StatusId = 6` and `CompletedAtUtc` for every task in the list.
3. Call it with 3 task IDs in one round trip (no loop), and confirm all 3 rows updated.
4. Roll back the data change; drop the procedure and the type.

### Deliverable

`P2-table-valued-parameters.sql`. Wrap the data change in a transaction you roll back.

### Hints

- TVPs must be declared `READONLY` in the procedure signature — this is not optional.

### Look-fors (rubric)

- [ ] The table type and procedure are both created successfully.
- [ ] All 3 rows are confirmed updated from a single procedure call.
- [ ] Everything is rolled back/dropped at the end.

---

## P3 — Safe Dynamic SQL with `sp_executesql`  *(Medium)*

**Tags:** `dynamic-sql` `sp_executesql` `sql-injection` `optional-filters`

### Requirements

1. Build `app.usp_SearchTasks` with three optional parameters (`@ProjectId`, `@StatusId`, `@TitleLike`), each defaulting to `NULL`, using `sp_executesql` with bound parameters to build the `WHERE` clause dynamically.
2. Call it with zero, one, and all three filters supplied, confirming each produces the correct result.
3. Write a **deliberately vulnerable** version that concatenates `@TitleLike` directly into the SQL string, and demonstrate a classic injection payload (e.g. `' OR '1'='1`) altering the query's behavior against your vulnerable version.
4. Explain, in a comment, exactly why the `sp_executesql`-parameterised version is immune to the same payload.

### Deliverable

`P3-dynamic-sql.sql`. Do not leave the vulnerable procedure in the database — drop it immediately after demonstrating the issue, inside the same script.

### Hints

- This is a preview of Topic 19 (SQL injection) — keep the demonstration contained and clearly labelled as intentionally vulnerable, for educational purposes only, in this single script.

### Look-fors (rubric)

- [ ] The parameterised version correctly handles all combinations of supplied/omitted filters.
- [ ] The vulnerable version demonstrably returns unintended rows with the injection payload.
- [ ] The parameterised version is shown to be unaffected by the same payload.
- [ ] The vulnerable procedure is dropped before the script ends.

---

## P4 — `TRY/CATCH`, `THROW`, and Transaction State  *(Medium)*

**Tags:** `try-catch` `throw` `xact_state` `xact_abort`

### Requirements

1. Create `app.usp_AssignTask (@TaskId INT, @UserId INT)` with `SET XACT_ABORT ON`, a `TRY/CATCH` block, an explicit transaction, and a `THROW 50001, ...` for a non-existent `TaskId`.
2. Call it with a valid `TaskId`/`UserId` and confirm the assignment succeeds; roll back afterward.
3. Call it with an invalid `TaskId` (e.g. 9999) and confirm the custom error is thrown with the correct message.
4. Modify the procedure to also handle a duplicate-assignment scenario (the same `TaskId`/`UserId` pair already exists — `PK_TaskAssignments` violation) by catching that specific error and re-`THROW`-ing with a friendlier message, using `ERROR_NUMBER()` to distinguish it from other failures.
5. Demonstrate all three paths (success, not-found, duplicate) and drop the procedure at the end.

### Deliverable

`P4-try-catch-throw.sql`.

### Hints

- `PK_TaskAssignments` violation is error 2627.
- `XACT_STATE()` inside `CATCH` tells you whether `ROLLBACK` is safe/necessary.

### Look-fors (rubric)

- [ ] The success path is demonstrated and rolled back.
- [ ] The not-found path throws the correct custom error (50001).
- [ ] The duplicate-assignment path is correctly detected via `ERROR_NUMBER() = 2627` and re-thrown with a friendlier message.
- [ ] The procedure is dropped at the end.

---

## P5 — The Scalar UDF Performance Trap  *(Hard)*

**Tags:** `scalar-functions` `inline-tvf` `cross-apply` `performance`

### Requirements

1. Create `app.ufn_TaskOpenDays (@TaskId INT) RETURNS INT` computing days since creation (or to completion), querying `app.Tasks` internally.
2. Run `SELECT t.TaskId, app.ufn_TaskOpenDays(t.TaskId) FROM app.Tasks AS t;` and capture `SET STATISTICS TIME ON` output.
3. Rewrite the same logic as an inline TVF `app.ufn_TaskOpenDaysTable (@TaskId INT) RETURNS TABLE`, and call it via `CROSS APPLY`. Capture the same statistics.
4. Check `OBJECTPROPERTY(..., 'IsDeterministic')` for both, and check (via documentation/testing on your SQL Server version) whether the scalar version qualifies for SQL Server 2019+ scalar UDF inlining — explain your finding.
5. Explain, in a comment, exactly why the scalar version's cost does not scale the way the inline TVF's does, even on this small 35-row table.
6. Drop both functions.

### Deliverable

`P5-scalar-udf-trap.sql`.

### Hints

- The row count here (35) is too small to show a dramatic wall-clock difference — the point is to correctly explain the *mechanism*, which is what interviews actually ask about.

### Look-fors (rubric)

- [ ] Both function versions are created correctly and produce identical results.
- [ ] `IsDeterministic` is checked and correctly explained (the `SYSUTCDATETIME()` fallback makes it non-deterministic).
- [ ] The scalar-vs-inline-TVF mechanism explanation is correct (per-row invocation vs plan folding), not just "one is faster."
- [ ] Both functions are dropped at the end.

---

## P6 — Observing Parameter Sniffing  *(Hard)*

**Tags:** `parameter-sniffing` `plan-cache` `optimize-for` `recompile`

### Requirements

1. Create `app.usp_TasksByStatus (@StatusId TINYINT)`.
2. Call it first with a `StatusId` that matches many rows, then with one that matches few, and inspect (via `sys.dm_exec_query_stats`/the actual plan) whether the same cached plan served both calls.
3. Add `OPTION (RECOMPILE)` and demonstrate that each call now gets a plan compiled for its own actual parameter.
4. Add `OPTIMIZE FOR (@StatusId UNKNOWN)` instead, and explain what estimate the optimizer uses for every call regardless of the actual value passed.
5. Write a comment table summarising when you'd choose each of the three approaches (default caching, `RECOMPILE`, `OPTIMIZE FOR`).
6. Drop the procedure(s).

### Deliverable

`P6-parameter-sniffing.sql`.

### Hints

- At this table's tiny size, the practical performance difference will be negligible — focus on correctly demonstrating and explaining the *mechanism*.

### Look-fors (rubric)

- [ ] Two calls with very different selectivity are correctly compared for plan reuse.
- [ ] `OPTION (RECOMPILE)`'s effect is correctly demonstrated (fresh plan per call).
- [ ] `OPTIMIZE FOR UNKNOWN`'s effect is correctly explained (density-based generic estimate, not the actual value).
- [ ] The summary table gives a correct, specific recommendation for each scenario.

---

## P7 — Design and Build: A Complete "Assign and Notify" Workflow  *(Hard)*

**Tags:** `end-to-end` `stored-procedures` `error-handling` `dml` `output-clause`

### Requirements

Design and implement `app.usp_AssignTaskWithHistory` that, in one procedure call:

1. Validates the task exists and is not already in a terminal status (6 or 7) — raise a clear custom error (`THROW`) if either check fails.
2. Inserts the new assignment (skip if the pair already exists — do not error in this specific case, per product requirements).
3. Uses the `OUTPUT` clause (Topic 10) to write a row into `audit.TaskHistory` recording the assignment as part of the same statement.
4. Wraps everything in a single transaction with `XACT_ABORT ON` and proper `TRY/CATCH`.
5. Returns (via a final `SELECT`) the task's full current assignee list after the change.
6. Write three test calls: a valid new assignment, an already-terminal task (expect the custom error), and a duplicate assignment (expect silent skip, not an error) — and demonstrate all three.
7. Roll back all data changes and drop the procedure.

### Deliverable

`P7-assign-and-notify-workflow.sql`.

### Hints

- "Skip if already exists" means checking with `IF NOT EXISTS (...)` before the `INSERT`, not catching the constraint violation.

### Look-fors (rubric)

- [ ] The terminal-status check correctly blocks tasks 1–4, 9–11, 15–16, 19, 23 (StatusId 6) and 26–27 (StatusId 7) with a clear custom error.
- [ ] The duplicate-assignment case is genuinely silent (no error), not caught-and-suppressed after the fact.
- [ ] `audit.TaskHistory` receives a correct row via `OUTPUT` in the same statement as the insert.
- [ ] The final `SELECT` correctly reflects the task's assignee list after the change.
- [ ] All three test scenarios are demonstrated; everything is rolled back/dropped at the end.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every procedure/function/type created for an experiment is dropped at the end of its own file.
- [ ] Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- [ ] The deliberately vulnerable procedure in P3 never persists beyond its own demonstration script.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Rewrite P7 to also accept a table-valued parameter of multiple `(TaskId, UserId)` pairs, assigning many tasks in one call instead of one.
- Investigate `sys.dm_exec_procedure_stats` (the procedure-level equivalent of `sys.dm_exec_query_stats`) and use it to find the single most expensive procedure by average logical reads in a database with realistic call volume.
- Read about natively compiled stored procedures and memory-optimized table types, and write a paragraph on what production symptom would justify the migration effort for a TaskFlow-shaped workload.
