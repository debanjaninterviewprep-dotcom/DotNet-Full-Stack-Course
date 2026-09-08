# Topic 15: Stored Procedures & Functions — Interview Questions

---

## Q1. What are the main benefits of a stored procedure over sending ad hoc SQL from the application?
**Answer:**
Plan caching (compiled once, reused across calls with the same shape), fewer network round trips for multi-statement logic, a security boundary (grant `EXECUTE` on the procedure without granting any permission on the underlying tables), and a single, versioned place for business logic instead of duplicated query text across callers.

---

## Q2. What does `SET NOCOUNT ON` do, and why is it recommended in almost every procedure?
**Answer:**
It suppresses the "(n rows affected)" message SQL Server sends after each DML statement. Most client libraries discard these messages anyway, so sending them is wasted network chatter — measurably slowing down procedures with many statements or a loop. It's close to a mandatory first line in any procedure body.

---

## Q3. How do you return a generated value (like a new identity) from a stored procedure to the caller?
**Answer:**
An `OUTPUT` parameter:

```sql
CREATE PROCEDURE app.usp_CreateTask @ProjectId INT, @Title NVARCHAR(200), @NewTaskId INT OUTPUT
AS
BEGIN
    INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId) VALUES (...);
    SET @NewTaskId = SCOPE_IDENTITY();
END;

DECLARE @Id INT;
EXEC app.usp_CreateTask @ProjectId = 1, @Title = N'x', @NewTaskId = @Id OUTPUT;
```

`SCOPE_IDENTITY()` (not `@@IDENTITY`) is used inside the procedure for the same reason it's preferred everywhere else (Topic 10) — it's immune to a trigger on another table generating its own identity in the same scope.

---

## Q4. What is a table-valued parameter (TVP), and what problem does it solve?
**Answer:**
A TVP lets you pass an entire result set into a stored procedure as a single parameter, using a user-defined table type. It solves the "bulk operation from the client" problem without looping one call per row or building a fragile delimited-string parameter:

```sql
CREATE TYPE app.TaskIdList AS TABLE (TaskId INT PRIMARY KEY);

CREATE PROCEDURE app.usp_BulkCloseTasks @TaskIds app.TaskIdList READONLY
AS
BEGIN
    UPDATE t SET t.StatusId = 6 FROM app.Tasks AS t JOIN @TaskIds AS ids ON ids.TaskId = t.TaskId;
END;
```

TVPs must be declared `READONLY` — you cannot modify the passed-in table variable inside the procedure.

---

## Q5. Why is `sp_executesql` preferred over `EXEC(@sql)` for dynamic SQL?
**Answer:**
`sp_executesql` accepts a parameter definition and bound parameter values, the same way a static parameterised query would — the actual user-supplied *values* never become part of the SQL text itself, which is what prevents SQL injection and also allows the resulting plan to be cached and reused across calls with different parameter values. `EXEC(@sql)` with values concatenated directly into the string has neither property: it's vulnerable to injection whenever any part of the string comes from user input, and every distinct string produces a separate cached plan.

---

## Q6. What is the difference between `THROW` and `RAISERROR`?
**Answer:**
`THROW` (no arguments) inside a `CATCH` block re-raises the original caught error with its exact original message, number, and line intact — `RAISERROR` cannot do this. For custom errors, `THROW 50001, N'message', 1;` is simpler syntax than the equivalent `RAISERROR`, and an uncaught `THROW` always terminates the batch, whereas `RAISERROR` with a severity below 20 does not stop execution by default. `THROW` is the modern default; `RAISERROR` remains relevant mainly for legacy compatibility or specific formatting/`WITH NOWAIT` needs.

---

## Q7. Inside a `CATCH` block, what does `XACT_STATE()` tell you, and why does it matter?
**Answer:**
It reports whether the current transaction is committable (`1`), has no active transaction (`0`), or is in an uncommittable/doomed state (`-1`) — which can happen after certain errors, especially under `XACT_ABORT ON`. Checking `IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;` before attempting further work is the safe pattern, since attempting to `COMMIT` a doomed transaction, or failing to roll one back, leaves the session in an inconsistent state.

---

## Q8. Why is a scalar function that queries a table considered dangerous for performance?
**Answer:**
Historically (pre-SQL Server 2019), a scalar UDF referenced once per row of an outer query is invoked that many separate times, each with its own execution-context overhead, and the presence of the scalar UDF call typically **prevents the whole query from running in parallel**. A query that should scan a table once instead pays for N mini-executions, each doing its own lookup:

```sql
-- Invoked once PER ROW of app.Tasks -- not once overall.
SELECT t.TaskId, app.ufn_TaskOpenDays(t.TaskId) FROM app.Tasks AS t;
```

SQL Server 2019+ can sometimes automatically inline a *qualifying* scalar function (no `TRY/CATCH`, no non-inlineable calls, etc.) into the equivalent expression, removing the penalty — but this only applies to functions meeting a specific list of requirements, so it cannot be relied on universally.

---

## Q9. What is an inline table-valued function, and how does it avoid the scalar UDF problem?
**Answer:**
An inline TVF's entire body is a single `RETURN (SELECT ...)` — no procedural statements, no loop. The optimizer treats it like a **parameterised view**: it expands/inlines the function's definition into the surrounding query's plan, exactly as it would a view, rather than invoking it as a separate black-box execution per row.

```sql
CREATE FUNCTION app.ufn_TaskOpenDaysTable (@TaskId INT) RETURNS TABLE
AS RETURN (SELECT DATEDIFF(DAY, t.CreatedAtUtc, ISNULL(t.CompletedAtUtc, SYSUTCDATETIME())) AS OpenDays
           FROM app.Tasks AS t WHERE t.TaskId = @TaskId);

SELECT t.TaskId, x.OpenDays FROM app.Tasks AS t CROSS APPLY app.ufn_TaskOpenDaysTable(t.TaskId) AS x;
```

Any time reusable per-row logic needs a table lookup, this is the correct tool — never a scalar function.

---

## Q10. What is parameter sniffing, and is it a bug?
**Answer:**
Not a bug — it's plan caching working exactly as designed, with a specific downside. The first time a parameterised procedure runs, SQL Server compiles a plan using that call's **actual parameter values** to estimate row counts and choose join strategies, then caches and reuses that plan for subsequent calls **regardless of their parameter values**. If different callers' parameters produce wildly different row-count profiles (e.g. a status value matching 10 rows versus one matching 500,000), the cached plan — great for whichever call happened to compile it — can be badly wrong for the others.

---

## Q11. What are three ways to mitigate a parameter-sniffing problem, and what's the trade-off of each?
**Answer:**

| Mitigation | Effect | Trade-off |
|---|---|---|
| `OPTION (RECOMPILE)` | Fresh plan compiled from that call's actual parameters, every time | Correct plan every call; pays full compilation cost every call |
| `OPTIMIZE FOR (@p = <value>)` | Always compiles as if `@p` were a specific chosen value | Great if one value's profile dominates real traffic; wrong for the rest |
| `OPTIMIZE FOR UNKNOWN` / local variable indirection | Uses a generic, density-based estimate, ignoring the actual value every time | Predictable "average" plan — never optimal for any specific value, never catastrophic for any either |

The right choice depends on the actual distribution of calls, confirmed via `sys.dm_exec_query_stats` or the plan's Estimated-vs-Actual row counts (Topic 13) — not applied reflexively.

---

## Q12. Can a scalar or table-valued function perform an `INSERT`/`UPDATE`/`DELETE` against a permanent table?
**Answer:**
No — functions in SQL Server cannot modify permanent database state. A function may only modify **table variables local to itself**. Any operation that needs to write to a real table (or call something that does) must be a stored procedure. This is one of the clearest lines between "function" (compute/return a value) and "procedure" (do something, including side effects).

---

## Q13. Why does a function's determinism matter, and how do you check it?
**Answer:**
Determinism (same inputs always produce the same output, with no dependence on the clock, randomness, or external state) is required for a function to be used inside a `CHECK` constraint's logic, a **persisted** computed column, or an **indexed view** — the engine must be able to guarantee the stored/persisted value never silently goes stale relative to its inputs. Check with:

```sql
SELECT OBJECTPROPERTY(OBJECT_ID('app.ufn_TaskOpenDaysTable'), 'IsDeterministic');
```

A function calling `SYSUTCDATETIME()`, `NEWID()`, `RAND()`, or any function that reads external/mutable state is non-deterministic.

---

## Q14. Design question: you need a search endpoint supporting five optional filter parameters, any combination of which might be supplied. How do you implement it, and what must you guard against?
**Answer:**
Use a stored procedure with all five parameters defaulting to `NULL`, building the `WHERE` clause dynamically via `sp_executesql` with bound parameters — appending each filter's SQL fragment only when its parameter is non-`NULL`, and always passing the actual value through the parameter list rather than concatenating it into the string:

```sql
DECLARE @sql NVARCHAR(MAX) = N'SELECT ... FROM app.Tasks AS t WHERE 1 = 1';
IF @ProjectId IS NOT NULL SET @sql += N' AND t.ProjectId = @p_ProjectId';
-- ... repeat per filter ...
EXEC sp_executesql @sql, N'@p_ProjectId INT, ...', @p_ProjectId = @ProjectId, ...;
```

Must guard against: SQL injection (never concatenate a raw value into `@sql`, always bind it as a parameter), plan cache bloat from too many distinct dynamic shapes (each unique combination of appended clauses produces its own cached plan — acceptable for 5 filters/32 combinations, potentially a concern at much higher filter counts), and parameter sniffing on the dynamic statement itself (each shape is sniffed independently, same as any other parameterised query).

---

## Q15. A stored procedure that used to run in milliseconds suddenly takes 30 seconds after a routine deployment that changed no SQL in it. What's your first hypothesis, and how do you confirm it?
**Answer:**
First hypothesis: **parameter sniffing regression** — a plan recompile (from the deployment touching something like statistics, an index rebuild, or even an unrelated schema change invalidating the cached plan) picked up an unlucky first-caller's parameter value and cached a plan that's bad for the *typical* caller. Confirm by:
1. Checking `sys.dm_exec_query_stats`/`sys.dm_exec_procedure_stats` for the procedure's current cached plan and its `total_elapsed_time`/`execution_count`.
2. Comparing the plan's **Estimated Rows** (from whichever parameter compiled it) against the **Actual Rows** for a typical, current call — a large mismatch confirms sniffing.
3. Forcing a recompile (`sp_recompile`, or `OPTION (RECOMPILE)` on a test run) and re-measuring — if performance returns to normal immediately, that confirms the cached plan (not the underlying data or logic) was the cause.

The key interview point: "no SQL changed" does not mean "no plan changed" — plan cache eviction/recompilation is triggered by many events (statistics updates, index changes, even memory pressure), and the resulting new plan can be compiled against an unrepresentative parameter value at any time, not just on first deployment.
