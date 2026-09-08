# Topic 15: Stored Procedures & Functions

> Every meaningful operation the TaskFlow API performs — assign a task, close a sprint, compute a burndown — eventually needs a name callable from application code, with parameters, error handling, and (ideally) a single round trip instead of five. Stored procedures and functions are how T-SQL packages logic as a first-class, callable, permissioned, plan-cached object. This topic covers both, where each fits, and the specific trap — scalar UDFs — that quietly destroys performance if you don't know what to look for.

---

## 1. Stored Procedures: Anatomy

```sql
USE TaskFlowDb;
GO

CREATE OR ALTER PROCEDURE app.usp_GetTasksByProject
    @ProjectId INT,
    @IncludeClosed BIT = 0                          -- default parameter
AS
BEGIN
    SET NOCOUNT ON;                                  -- suppress "(n rows affected)" chatter

    SELECT t.TaskId, t.Title, t.StatusId, t.PriorityId, t.DueDate
    FROM app.Tasks AS t
    WHERE t.ProjectId = @ProjectId
      AND (@IncludeClosed = 1 OR t.StatusId NOT IN (6, 7));
END;
GO

EXEC app.usp_GetTasksByProject @ProjectId = 1;                    -- open tasks only
EXEC app.usp_GetTasksByProject @ProjectId = 1, @IncludeClosed = 1; -- everything
```

| Benefit | Detail |
|---|---|
| **Plan caching** | A parameterised procedure's plan is compiled once and reused — no per-call compilation cost |
| **Reduced round trips** | Multiple statements, temp tables, control flow — one network call |
| **Security boundary** | Grant `EXECUTE` on the procedure without granting any permission on the underlying tables |
| **Encapsulation** | Business logic lives in one named, versioned place, not copy-pasted across every caller |
| **Parameter sniffing control** | You can deliberately manage it (§6), unlike ad hoc query text |

`SET NOCOUNT ON` is close to mandatory: without it, every statement inside the procedure sends a "(n rows affected)" message, which is wasted network chatter most client libraries discard anyway, and can measurably slow procedures with many statements or a loop.

---

## 2. Parameters: Input, Output, Table-Valued, Defaults

```sql
CREATE OR ALTER PROCEDURE app.usp_CreateTask
    @ProjectId       INT,
    @Title           NVARCHAR(200),
    @PriorityId      TINYINT = 3,                    -- default: Medium
    @CreatedByUserId INT,
    @NewTaskId       INT OUTPUT                        -- output parameter
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
    VALUES (@ProjectId, @Title, 1, @PriorityId, @CreatedByUserId);

    SET @NewTaskId = SCOPE_IDENTITY();
END;
GO

DECLARE @Id INT;
EXEC app.usp_CreateTask @ProjectId = 1, @Title = N'Add health-check endpoint',
                         @CreatedByUserId = 4, @NewTaskId = @Id OUTPUT;
SELECT @Id AS GeneratedTaskId;
```

**Table-valued parameters (TVPs)** pass a whole result set into a procedure in one call — the standard alternative to looping client-side calls or building a delimited-string parameter:

```sql
CREATE TYPE app.TaskIdList AS TABLE (TaskId INT PRIMARY KEY);
GO

CREATE OR ALTER PROCEDURE app.usp_BulkCloseTasks
    @TaskIds app.TaskIdList READONLY                 -- TVPs are always READONLY
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t
    SET t.StatusId = 6, t.CompletedAtUtc = SYSUTCDATETIME()
    FROM app.Tasks AS t
    JOIN @TaskIds AS ids ON ids.TaskId = t.TaskId;
END;
GO

DECLARE @Ids app.TaskIdList;
INSERT INTO @Ids VALUES (8), (14), (21);
EXEC app.usp_BulkCloseTasks @TaskIds = @Ids;
```

---

## 3. `sp_executesql` and Dynamic SQL

Dynamic SQL is unavoidable for genuinely variable structure — an optional-filters search screen, a dynamic `ORDER BY`, a pivoted column list. `sp_executesql` **parameterises** dynamic SQL the same way a static procedure call would, which is what makes it safe.

```sql
CREATE OR ALTER PROCEDURE app.usp_SearchTasks
    @ProjectId  INT = NULL,
    @StatusId   TINYINT = NULL,
    @TitleLike  NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT t.TaskId, t.Title, t.ProjectId, t.StatusId
        FROM app.Tasks AS t
        WHERE 1 = 1';

    IF @ProjectId IS NOT NULL SET @sql += N' AND t.ProjectId = @p_ProjectId';
    IF @StatusId  IS NOT NULL SET @sql += N' AND t.StatusId  = @p_StatusId';
    IF @TitleLike IS NOT NULL SET @sql += N' AND t.Title LIKE @p_TitleLike';

    EXEC sp_executesql @sql,
         N'@p_ProjectId INT, @p_StatusId TINYINT, @p_TitleLike NVARCHAR(200)',
         @p_ProjectId = @ProjectId, @p_StatusId = @StatusId, @p_TitleLike = @TitleLike;
END;
```

> **Anti-pattern (SQL injection):** Building the WHERE value directly into the string — `SET @sql += N' AND t.Title LIKE ''%' + @TitleLike + '%'''` — instead of a parameter. This is exactly the vulnerability Topic 19 covers in depth; `sp_executesql` with bound parameters is the mandatory pattern any time user input reaches dynamic SQL. `EXEC (@sql)` with concatenated values is never acceptable for anything derived from user input.

---

## 4. Error Handling: `TRY/CATCH` and `THROW`

```sql
CREATE OR ALTER PROCEDURE app.usp_AssignTask
    @TaskId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;                                -- runtime error => automatic rollback

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM app.Tasks AS t WHERE t.TaskId = @TaskId)
            THROW 50001, 'Task does not exist.', 1;

        INSERT INTO app.TaskAssignments (TaskId, UserId, IsPrimary)
        VALUES (@TaskId, @UserId, 0);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        THROW;                                         -- re-raise with original error info intact
    END CATCH;
END;
```

| | `THROW` | `RAISERROR` |
|---|---|---|
| Re-raise the original caught error, unmodified | `THROW;` (no arguments) — preserves original message/number/line | Cannot re-raise the exact original error |
| Custom error | `THROW 50001, N'message', 1;` | `RAISERROR (N'message', 16, 1);` |
| Requires a preceding semicolon | Yes, defensively | No |
| Automatically ends the batch on uncaught error | Yes | No — severity < 20 does not stop execution by default |

> **Rule of thumb:** `THROW` is the modern default. Use bare `THROW;` inside a `CATCH` block to propagate the real error to the caller unchanged; reserve `RAISERROR` only for legacy compatibility (e.g. the specific case of formatting with `WITH NOWAIT` for real-time progress messages).

`XACT_STATE()` inside `CATCH` distinguishes a **committable** transaction (1) from an **uncommittable, doomed** one (-1, typically after certain errors under `XACT_ABORT`) — rolling back unconditionally, as shown, is always safe in either state.

---

## 5. Scalar Functions, Inline Table-Valued Functions, and the Performance Trap

| Type | Returns | Can be used in `SELECT`/`WHERE`/`JOIN` inline | Typical performance |
|---|---|---|---|
| **Scalar function** | A single value | Yes, like any expression | **Often catastrophic** at scale — see below |
| **Multi-statement TVF** | A table, built up statement-by-statement in a function body | Only in `FROM`/`APPLY` | Poor — treated like a black-box loop internally |
| **Inline TVF** | A table, defined as a single `RETURN (SELECT ...)` | In `FROM`/`APPLY`, freely joined | **Good** — behaves like a parameterised view |

```sql
-- Scalar function: looks innocent, is not.
CREATE OR ALTER FUNCTION app.ufn_TaskOpenDays (@TaskId INT)
RETURNS INT
AS
BEGIN
    DECLARE @Days INT;
    SELECT @Days = DATEDIFF(DAY, t.CreatedAtUtc, ISNULL(t.CompletedAtUtc, SYSUTCDATETIME()))
    FROM app.Tasks AS t WHERE t.TaskId = @TaskId;
    RETURN @Days;
END;
GO

-- Looks like one query. Is actually 35 individual invocations, one per row,
-- each with its own execution context -- historically NOT parallelisable at all,
-- and even with SQL Server 2019+ scalar UDF inlining, only a subset of functions qualify.
SELECT t.TaskId, app.ufn_TaskOpenDays(t.TaskId) AS OpenDays FROM app.Tasks AS t;
```

Why this is so damaging: prior to SQL Server 2019, a scalar UDF referenced in a query is invoked **once per row**, each invocation paying its own mini-execution-context overhead, and the whole query is barred from parallelism as a result — a query that should take milliseconds can take seconds or worse at real row counts. SQL Server 2019+ introduced **scalar UDF inlining**, which can automatically rewrite qualifying simple scalar functions into the equivalent inline expression — but only when the function meets a specific list of requirements (no `TRY/CATCH`, no calls to other non-inlineable functions, no reference to certain system functions, etc.), so you cannot rely on it universally.

```sql
-- Inline TVF: the "good" alternative. The function body IS a single SELECT.
CREATE OR ALTER FUNCTION app.ufn_TaskOpenDaysTable (@TaskId INT)
RETURNS TABLE
AS
RETURN (
    SELECT DATEDIFF(DAY, t.CreatedAtUtc, ISNULL(t.CompletedAtUtc, SYSUTCDATETIME())) AS OpenDays
    FROM app.Tasks AS t
    WHERE t.TaskId = @TaskId
);
GO

-- The optimizer expands this like a parameterised view -- no per-row invocation penalty.
SELECT t.TaskId, x.OpenDays
FROM app.Tasks AS t
CROSS APPLY app.ufn_TaskOpenDaysTable(t.TaskId) AS x;
```

> **Rule of thumb:** Never write a scalar UDF that queries a table and gets called per-row in a `SELECT`. If the logic needs a table lookup, write it as an **inline TVF** and invoke it with `CROSS APPLY`/`OUTER APPLY` instead — same reusability, none of the per-row tax.

---

## 6. Parameter Sniffing

The first execution of a procedure compiles a plan using **that call's actual parameter values** to estimate row counts — and then, by default, **reuses that same plan** for every subsequent call, regardless of how different the next call's parameters are.

```sql
CREATE OR ALTER PROCEDURE app.usp_TasksByStatus @StatusId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.StatusId = @StatusId;
END;
GO

-- First call: StatusId = 6 (Done) matches 13 rows -- plan compiled and cached for THIS shape.
EXEC app.usp_TasksByStatus @StatusId = 6;

-- Second call: StatusId = 1 (Backlog) matches only 6 rows, but reuses the SAME cached plan --
-- fine here because the table is tiny, but at scale a plan optimised for "13 out of a million"
-- can be disastrous when reused for "600,000 out of a million," or vice versa.
EXEC app.usp_TasksByStatus @StatusId = 1;
```

| Mitigation | Mechanism | Trade-off |
|---|---|---|
| `OPTION (RECOMPILE)` | Recompiles every execution, using that call's actual parameters | Correct plan every time; pays compilation cost every time |
| `WITH RECOMPILE` (on the procedure) | Same, at the procedure level | Same trade-off, broader scope |
| Local variables instead of parameters | `DECLARE @p TINYINT = @StatusId;` then filter on `@p` | Optimizer uses a generic density-based estimate instead of sniffing — sometimes better, sometimes worse, never "correct for this call" |
| `OPTIMIZE FOR (@StatusId = n)` | Always compiles as if the parameter were a specific, chosen value | Good when one value's shape is overwhelmingly the common case |
| `OPTIMIZE FOR UNKNOWN` | Always uses the generic density estimate, ignoring the actual value on every call | Predictable, average-case plan — never great, never terrible |

> **Rule of thumb:** Don't reach for `OPTION (RECOMPILE)` reflexively — it defeats plan caching for genuinely stable, well-behaved procedures. Reach for it specifically when a procedure's row-count profile varies wildly by parameter (a classic case: `@StatusId` values with drastically different row counts, or a `@ProjectId` where one project has 100x the tasks of another) and you've confirmed via `sys.dm_exec_query_stats`/Estimated-vs-Actual (Topic 13) that plan reuse is actually the problem.

---

## 7. Natively Compiled and Deterministic Considerations

Regular (interpreted) T-SQL functions/procedures are compiled once and executed by the relational engine's usual query processor. SQL Server also supports **natively compiled** stored procedures/functions against memory-optimized tables (In-Memory OLTP) — compiled to native machine code ahead of time for very high-throughput OLTP workloads. This is a specialised, narrow-use feature (its own restricted T-SQL surface, memory-optimized tables required) — know it exists and what problem it solves (extreme-throughput OLTP), but it is not the default choice for TaskFlow-shaped workloads.

**Determinism** matters for functions specifically because a function's result can be persisted (in a computed column, Topic 02) or indexed (in an indexed view, Topic 14) only if it is **deterministic** — same inputs always produce the same output, with no dependence on the current time, random values, or external state.

```sql
SELECT OBJECTPROPERTY(OBJECT_ID('app.ufn_TaskOpenDaysTable'), 'IsDeterministic');
-- 0 -- ISNULL(..., SYSUTCDATETIME()) makes this function's result time-dependent, hence non-deterministic.
```

A non-deterministic function cannot be referenced in a `CHECK` constraint's underlying logic, a persisted computed column, or an indexed view — the same constraint that Topic 02 and Topic 14 already flagged from the other direction.

---

## 8. Stored Procedures vs Functions vs Views — Decision Table

| Need | Right tool |
|---|---|
| Encapsulate a reusable `SELECT`, joinable/filterable inline | View (Topic 14), or inline TVF if it needs parameters |
| Run `INSERT`/`UPDATE`/`DELETE`, multiple statements, control flow, error handling | **Stored procedure** — functions cannot perform DML against permanent tables at all |
| Return a single computed value, used inline in an expression, with no table lookup inside | Scalar function (fine — the per-row tax in §5 specifically concerns functions that query a table) |
| Return a single computed value that **does** need a table lookup, used per-row in a query | **Inline TVF** via `APPLY`, never a scalar function |
| A parameterised, reusable table shape joined into other queries | Inline TVF |
| A bulk operation over a client-supplied set of rows | Stored procedure with a **table-valued parameter** |
| Genuinely dynamic structure (optional filters, dynamic columns) | Stored procedure using `sp_executesql` with bound parameters |

> **Rule of thumb:** Functions compute; procedures do. The moment "compute a value" secretly involves "read this table for every row of the outer query," escalate to an inline TVF — the tool exists specifically to make that pattern free.

---

## Mental Model

> A stored procedure is where TaskFlow's business logic gets a name, a cached plan, and a security boundary independent of the tables underneath it — parameters (including table-valued ones for bulk work), `TRY/CATCH` with `THROW` for propagating real errors, and `sp_executesql` for the rare case where the query's *shape*, not just its values, must vary safely. Functions look similar but are a different tool with a sharp edge: a scalar function that queries a table and gets called once per row of an outer query is invoked that many separate times, barred from parallelism in the general case, and is one of the most common silent performance regressions in real T-SQL codebases — the fix is always the same, rewrite it as an inline table-valued function and call it with `APPLY`, which the optimizer can fold in like a parameterised view instead of a black-box per-row loop. And because a procedure's plan is cached and reused by default, the values used on its *first* call shape every subsequent call's plan — parameter sniffing is not a bug, it's the caching working as designed, and the fix is deliberate (`RECOMPILE`, `OPTIMIZE FOR`, or local variables), applied only once you've confirmed via the actual row-count profile that a single cached plan genuinely cannot serve every caller well.

Move to [Practice Problems](./Practice-Problems.md).
