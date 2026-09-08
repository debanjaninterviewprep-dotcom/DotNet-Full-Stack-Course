# Topic 04: Built-In Functions & Expressions — Interview Questions

---

## Q1. What are the categories of functions in SQL Server?
**Answer:**

| Category | Returns | Evaluated per | Examples |
|---|---|---|---|
| **Scalar** | One value | Row | `LEN`, `DATEADD`, `ISNULL`, `CAST`, `CASE` |
| **Aggregate** | One value | Group | `COUNT`, `SUM`, `AVG`, `STRING_AGG` |
| **Window / analytic** | One value per row, over a frame | Row | `ROW_NUMBER`, `LAG`, `SUM() OVER (…)` |
| **Rowset / table-valued** | A table | Query | `STRING_SPLIT`, `OPENJSON`, `OPENROWSET` |
| **System / metadata** | Server or session state | Statement | `@@ROWCOUNT`, `DB_NAME()`, `SUSER_SNAME()` |

The category tells you the cost model. A scalar function in a select list runs once per row. A rowset function participates in the plan as a table source and gets an (often terrible) cardinality estimate. A window function requires a sort or an ordered index.

---

## Q2. `LEN` vs `DATALENGTH` — what is the difference?
**Answer:**
`LEN` returns the **character** count and **ignores trailing spaces**. `DATALENGTH` returns the **byte** count and counts everything.

```sql
SELECT LEN('abc   ')         AS Chars,      -- 3
       DATALENGTH('abc   ')  AS VarcharBytes, -- 6
       DATALENGTH(N'abc   ') AS NvarcharBytes; -- 12  (NVARCHAR = 2 bytes/char)
```

Use `LEN` for "what will the user see". Use `DATALENGTH` for "will this fit / how much storage am I using", and whenever you are hunting a whitespace bug — it is the only one that can see trailing spaces.

`DATALENGTH` is also the correct way to size `NVARCHAR(MAX)` and `VARBINARY(MAX)` payloads, for example `app.Tasks.MetadataJson`. Note that a supplementary (non-BMP) character occupies two UTF-16 code units and therefore four bytes, so `DATALENGTH` is not always exactly `2 × LEN`.

---

## Q3. How do `+`, `CONCAT` and `CONCAT_WS` differ with `NULL`?
**Answer:**

| | `NULL` behaviour | Type coercion |
|---|---|---|
| `+` | **Propagates** — the whole result becomes `NULL` | None; you must `CAST` numbers |
| `CONCAT` | Treats `NULL` as `''` | Implicit for every argument |
| `CONCAT_WS` | **Skips** the argument entirely — no orphan separator | Implicit |

```sql
-- app.Users.JobTitle is NULL for UserId 19
SELECT u.FirstName + N' ' + u.JobTitle                          AS WithPlus,      -- NULL
       CONCAT(u.FirstName, N' ', u.JobTitle)                    AS WithConcat,    -- 'Sophie '
       CONCAT_WS(N' — ', u.FullName, u.JobTitle, u.CountryCode) AS WithConcatWs   -- 'Sophie Wilson — GB'
FROM   app.Users AS u WHERE u.UserId = 19;
```

`CONCAT_WS` is the right tool for label and address output because it does not leave a dangling separator. `+` is the right tool when a missing component means the whole value is meaningless — the `NULL` propagation stops you shipping a string with a hole in it.

`app.Users.FullName` is defined with `+` deliberately: both source columns are `NOT NULL`, and `+` is deterministic, which is what allows the column to be `PERSISTED` and indexed.

---

## Q4. `ISNULL` vs `COALESCE` — name every difference you can.
**Answer:**

| | `ISNULL(a, b)` | `COALESCE(a, b, c, …)` |
|---|---|---|
| Standard | T-SQL only | **ANSI SQL** |
| Arguments | Exactly 2 | 2 or more |
| Return type | Type of the **first** argument | **Highest-precedence** type among all arguments |
| Truncation | Silently truncates | Never truncates |
| Result nullability | `NOT NULL` if the second argument is non-nullable | Nullable unless an argument is a non-null literal |
| Implementation | Single intrinsic; each input evaluated once | Expands to `CASE` — the first input may be evaluated **twice** |
| All-`NULL` literals | `ISNULL(NULL, NULL)` returns `NULL` | `COALESCE(NULL, NULL)` is an **error** |

```sql
SELECT ISNULL(CAST(NULL AS VARCHAR(2)), 'abcdef')   AS Truncated,  -- 'ab'
       COALESCE(CAST(NULL AS VARCHAR(2)), 'abcdef') AS Intact;     -- 'abcdef'
```

The double-evaluation matters because `COALESCE(a, b)` is literally `CASE WHEN a IS NOT NULL THEN a ELSE b END` — `a` appears twice. If `a` is a scalar subquery or a non-deterministic function, it can run twice.

The nullability difference matters for schema design: `ISNULL(x, 0)` is inferred as `NOT NULL`, so it can be used in a `PERSISTED` computed column that participates in a primary key; the `COALESCE` form generally cannot.

Default to `COALESCE` — ANSI, N arguments, no truncation. Reach for `ISNULL` when you specifically need the `NOT NULL` inference or single evaluation.

---

## Q5. What is `NULLIF` for?
**Answer:**
`NULLIF(a, b)` returns `NULL` when `a = b`, otherwise `a`. It is implemented as a `CASE`, so `b` is evaluated twice.

Three real uses:

```sql
-- 1. Divide-by-zero protection (the canonical use)
SELECT t.EstimatedHours / NULLIF(t.StoryPoints, 0) AS HoursPerPoint FROM app.Tasks AS t;

-- 2. Turn a "not found" sentinel into a real NULL.
--    CHARINDEX returns 0 when absent, which SUBSTRING would happily accept.
SELECT SUBSTRING(u.Email, NULLIF(CHARINDEX(N'@', u.Email), 0) + 1, 100) AS Domain FROM app.Users AS u;

-- 3. Normalise empty string to NULL when importing external data
SELECT NULLIF(TRIM(th.NewValue), N'') AS Normalised FROM audit.TaskHistory AS th;
```

It is also useful in aggregates: `SUM(NULLIF(x, 0))` excludes zeros without a `WHERE` clause that would affect other columns.

---

## Q6. `CASE`, `IIF`, `CHOOSE` — when do you use each, and what are the traps?
**Answer:**
`CASE` is ANSI and comes in two forms:

```sql
-- Simple: compares one expression with = . CANNOT match NULL.
CASE t.PriorityId WHEN 1 THEN N'Critical' WHEN 2 THEN N'High' ELSE N'Normal' END

-- Searched: arbitrary predicates, including IS NULL.
CASE WHEN t.DueDate IS NULL THEN N'Undated'
     WHEN t.DueDate < CAST(SYSUTCDATETIME() AS DATE) THEN N'Overdue'
     ELSE N'Scheduled' END
```

Four traps:

1. **Simple `CASE` can never match `NULL`**, because it uses `=`. `CASE x WHEN NULL THEN …` never fires.
2. **First match wins**, top to bottom — order from most specific to least.
3. **No `ELSE` means `NULL`**, silently.
4. **The result type is the highest-precedence branch type.** `CASE WHEN … THEN 1 ELSE 'none' END` fails; `CASE WHEN … THEN 1 ELSE 2.5 END` silently returns `DECIMAL`.

`CASE` is *generally* evaluated left to right, but the documentation does **not** guarantee short-circuiting — the optimiser may hoist expressions, particularly with aggregates. Never use `CASE` as a guard against a conversion error or a divide-by-zero; use `TRY_CONVERT` and `NULLIF`.

`IIF(cond, t, f)` is sugar rewritten to a searched `CASE`, capped at 10 nesting levels. `CHOOSE(index, …)` is 1-based and returns `NULL` out of range. Both are T-SQL only.

`GREATEST` / `LEAST` (SQL Server 2022, Azure SQL) work **across columns in a row**, ignore `NULL`s, and return `NULL` only when every argument is `NULL`. The pre-2022 equivalent is `CROSS APPLY (SELECT MAX(v) FROM (VALUES (a),(b),(c)) AS d(v))`.

---

## Q7. `SELECT 7/2` returns 3. Explain, and explain how you would fix a "percent complete" calculation.
**Answer:**
`/` between two integers is integer division and truncates toward zero. There is no warning. The fix is to make at least one operand non-integer **before** the division:

```sql
SELECT t.ProjectId,
       -- WRONG: int / int -> 0, then * 100 -> 0
       SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100   AS PctWrong,
       -- RIGHT: promote first
       100.0 * SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END) / COUNT(*) AS PctRight
FROM   app.Tasks AS t
JOIN   ref.TaskStatuses AS s ON s.StatusId = t.StatusId
GROUP  BY t.ProjectId;
```

Put the decimal literal **first**. `100.0 * a / b` promotes the expression before the division; `a / b * 100.0` promotes after the damage is done.

Two related surprises: `ROUND` in T-SQL rounds **half away from zero** (`ROUND(2.5, 0)` = 3), unlike .NET's banker's rounding `Math.Round(2.5)` = 2 — which matters when a SQL report must reconcile with a C# calculation. And `ROUND` does **not** change the scale: `ROUND(12.50, 0)` returns `13.00`, so you still need `CAST(… AS INT)`.

---

## Q8. `GETDATE`, `GETUTCDATE`, `SYSDATETIME`, `SYSUTCDATETIME`, `SYSDATETIMEOFFSET` — which do you use and why?
**Answer:**

| Function | Type | Clock | Precision |
|---|---|---|---|
| `GETDATE()` | `DATETIME` | Server local | ~3.33 ms |
| `GETUTCDATE()` | `DATETIME` | UTC | ~3.33 ms |
| `SYSDATETIME()` | `DATETIME2(7)` | Server local | OS clock |
| `SYSUTCDATETIME()` | `DATETIME2(7)` | **UTC** | OS clock |
| `SYSDATETIMEOFFSET()` | `DATETIMEOFFSET(7)` | Local + offset | OS clock |
| `CURRENT_TIMESTAMP` | `DATETIME` | Server local | ANSI synonym for `GETDATE()` |

`SYSUTCDATETIME()` is the default answer: store UTC, convert at the edge. Every timestamp column in the TaskFlow schema — `CreatedAtUtc`, `CompletedAtUtc`, `PostedAtUtc`, `ChangedAtUtc` — is `DATETIME2(3)` in UTC with a `SYSUTCDATETIME()` default. `GETDATE()` on a server whose timezone changes (a regional failover, a DST shift) silently corrupts data that is already written.

Declared precision is not accuracy: `DATETIME2(7)` can *represent* 100 ns, but the value comes from the OS clock, which ticks roughly every millisecond. Never use `SYSDATETIME()` as a uniqueness generator.

---

## Q9. `DATEDIFF(YEAR, '2024-12-31', '2025-01-01')` returns 1 for two dates one day apart. Why?
**Answer:**
`DATEDIFF` counts **boundary crossings** of the specified part, not elapsed units. There is exactly one 1-January boundary between those two dates, so the answer is 1.

```sql
SELECT DATEDIFF(YEAR,  '2024-12-31', '2025-01-01') AS Years,   -- 1
       DATEDIFF(MONTH, '2025-01-31', '2025-02-01') AS Months,  -- 1
       DATEDIFF(HOUR,  '2025-01-01T09:59', '2025-01-01T10:00') AS Hours; -- 1
```

There is a second trap: `DATEDIFF` returns `INT`, so it **overflows**.

| `datepart` | Overflows after roughly |
|---|---|
| `SECOND` | 68 years |
| `MILLISECOND` | 24.8 days |
| `MICROSECOND` | 35.8 minutes |
| `NANOSECOND` | 2.1 seconds |

```sql
-- Msg 535: The datediff function resulted in an overflow.
SELECT DATEDIFF(MILLISECOND, '2024-02-05T09:00:00', SYSUTCDATETIME());

-- DATEDIFF_BIG (2016+) returns BIGINT
SELECT DATEDIFF_BIG(MILLISECOND, '2024-02-05T09:00:00', SYSUTCDATETIME());
```

Any `DATEDIFF` finer than `SECOND` over more than a few minutes must be `DATEDIFF_BIG`. This is the classic "worked in dev, blew up in production after six months of data" bug.

---

## Q10. Calculate a person's age in whole years, correctly.
**Answer:**
`DATEDIFF(YEAR, dob, today)` is wrong for exactly the reason in Q9. Count the boundaries, then subtract one if this year's anniversary has not happened yet:

```sql
DECLARE @Dob DATE = '2000-08-15', @Today DATE = '2025-08-14';

SELECT DATEDIFF(YEAR, @Dob, @Today) AS NaiveWrong,   -- 25
       DATEDIFF(YEAR, @Dob, @Today)
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @Dob, @Today), @Dob) > @Today
                THEN 1 ELSE 0 END AS CorrectAge;      -- 24
```

The same pattern gives whole months, whole quarters, or tenure in `app.TeamMembers`. Leap-day caveat: `DATEADD(YEAR, 1, '2024-02-29')` is `2025-02-28`, so a 29 February birthday reaches its anniversary on 28 February. That is a policy decision to document, not a bug to fix.

---

## Q11. `AT TIME ZONE`, `SWITCHOFFSET`, `TODATETIMEOFFSET` — explain each.
**Answer:**

| Construct | Behaviour | DST-aware |
|---|---|---|
| `d AT TIME ZONE 'X'` | If `d` has no offset, **attach** zone `X`; if it has one, **convert** to `X` | Yes |
| `SWITCHOFFSET(dto, '+05:30')` | Same instant, re-expressed at a fixed offset | No |
| `TODATETIMEOFFSET(dt, '-05:00')` | **Assert** a naive value was in that offset; no conversion | No |

The canonical, correct conversion is two steps:

```sql
SELECT t.CreatedAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time' AS IndiaTime
FROM   app.Tasks AS t WHERE t.TaskId = 5;
```

A single `AT TIME ZONE 'India Standard Time'` on a naive `DATETIME2` does **not** convert — it asserts the stored value was already IST and attaches `+05:30`. That is the most common timezone bug in T-SQL and it produces a value that is off by exactly the offset.

Zone names come from `sys.time_zone_info` (Windows names, on both Windows and Linux). Store UTC plus a zone **name** if you need to reconstruct local time — storing a raw offset is not enough, because `+01:00` does not tell you whether that was London in summer or Berlin in winter, and it cannot survive a DST rule change.

Performance note: `AT TIME ZONE` in a `WHERE` clause is non-SARGable. Convert the **parameter** to UTC in the application and filter on the raw UTC column.

---

## Q12. Why can `DATEPART(WEEKDAY, …)` return different answers for two users on the same server?
**Answer:**
Because it depends on the session's `DATEFIRST`, which defaults from the session `LANGUAGE`. `us_english` gives `@@DATEFIRST = 7` (Sunday first); British English gives `1` (Monday first). `DATEPART(WEEK, …)` has the same problem. That makes both effectively **non-deterministic across sessions**.

Two `DATEFIRST`-independent week-start expressions:

```sql
-- A. Anchor on 1900-01-01, which was a Monday
DATEADD(DAY, -(DATEDIFF(DAY, '19000101', d) % 7), d)

-- B. Neutralise @@DATEFIRST arithmetically
DATEADD(DAY, -((DATEPART(WEEKDAY, d) + @@DATEFIRST - 2) % 7), d)
```

`DATEPART(ISO_WEEK, d)` is also independent — it always follows ISO-8601 (weeks start Monday, week 1 contains the first Thursday). Prefer it over `DATEPART(WEEK, d)` in any report read across regions.

The production-grade answer is a **calendar dimension table** with pre-computed `WeekStart`, `IsoWeek`, `FiscalQuarter` and `IsWorkingDay`. It removes the session dependency entirely and restores SARGability, because you join instead of compute.

The same warning applies to `DATENAME` — its output is language-dependent. Never persist it, never compare against it, never put it in a `WHERE` clause.

---

## Q13. `CAST` vs `CONVERT`. Which date literal formats are safe?
**Answer:**
`CAST(expr AS type)` is ANSI and portable. `CONVERT(type, expr, style)` is T-SQL only but supports **style codes**, which is the only reason to use it.

| Style | Output | Use |
|---|---|---|
| `112` | `yyyymmdd` | Unambiguous, sortable, language-independent |
| `120` / `121` | `yyyy-mm-dd hh:mi:ss[.mmm]` | ODBC canonical, 24-hour |
| `126` | `yyyy-mm-ddThh:mi:ss.mmm` | ISO-8601 — the interop choice |
| `23` | `yyyy-mm-dd` | Date only |
| `101` / `103` | `mm/dd/yyyy` / `dd/mm/yyyy` | US / British — display only |

Only two **input** string formats are safe regardless of `SET LANGUAGE` and `SET DATEFORMAT`:

```sql
'20250830'                 -- always yyyymmdd
'2025-08-30T13:45:00'      -- ISO-8601 with the T separator
```

`'2025-08-30'` (dashes, no `T`) is safe for `DATE` and `DATETIME2` but is interpreted using `DATEFORMAT` for the legacy `DATETIME` type. `'08/30/2025'` is a bug waiting for a British user.

---

## Q14. `TRY_CAST`, `TRY_CONVERT`, `PARSE`, `TRY_PARSE` — when do you use each?
**Answer:**

| Function | On failure | Cost | Since |
|---|---|---|---|
| `CAST` / `CONVERT` | **Error**, statement aborts | Cheap | Always |
| `TRY_CAST` / `TRY_CONVERT` | Returns `NULL` | Cheap | 2012 |
| `PARSE` / `TRY_PARSE` | Error / `NULL` | **Very** expensive (CLR) | 2012 |

`TRY_CAST` is the default for untrusted input — parsing `audit.TaskHistory.NewValue`, validating an imported CSV, defending a report against one bad row. Note that it still raises an error if the conversion is **not permitted at all** (`TRY_CAST(GETDATE() AS XML)`); it only suppresses *data* conversion failures.

`PARSE`/`TRY_PARSE` are CLR-based and culture-aware — they are the only built-ins that can read `'30/08/2025'` as British — but they are roughly an order of magnitude slower and cannot be inlined or parallelised. Use them for one-off imports, never in a hot path.

---

## Q15. Why is `FORMAT` slow, and what should you use instead?
**Answer:**
Three reasons:

1. It is implemented in the **CLR**, so every row crosses the SQLCLR boundary.
2. It is **non-deterministic** (culture-dependent), so it cannot appear in a persisted computed column or an indexed view.
3. It forces **row-by-row** evaluation and blocks batch-mode processing.

In practice it is 30–50x slower than the `CONVERT` equivalent:

```sql
SELECT FORMAT(t.DueDate, 'yyyy-MM-dd')   AS Slow,
       CONVERT(CHAR(10), t.DueDate, 120) AS Fast
FROM   app.Tasks AS t;
```

The correct answer for most systems is: **do not format in SQL at all.** Return typed values and format in the presentation layer, where you have real culture information about the user. If you must format in SQL, use `CONVERT` with a style code. Reserve `FORMAT` for low-row-count, genuinely culture-sensitive output.

---

## Q16. `SCOPE_IDENTITY()`, `@@IDENTITY`, `IDENT_CURRENT()` — which is safe?  *(Senior)*
**Answer:**

| Function | Scope | Session | Failure mode |
|---|---|---|---|
| `SCOPE_IDENTITY()` | **Current scope** | Current | Returns `NUMERIC(38,0)` — cast it |
| `@@IDENTITY` | Any scope | Current | A trigger inserting elsewhere returns **that** table's identity |
| `IDENT_CURRENT('app.Tasks')` | Any scope | **Any session** | Race condition — you get another user's value |
| `OUTPUT` clause | Exact | Exact | None |

`@@IDENTITY` is the classic production bug: someone adds an audit trigger on `app.Tasks` that inserts into `audit.TaskHistory`, and every `INSERT` suddenly returns a `TaskHistoryId` instead of a `TaskId`. `IDENT_CURRENT` is worse — it is not session-scoped at all, so under concurrency it returns whatever another connection just inserted.

`SCOPE_IDENTITY()` is safe but only returns a single value. The modern answer is the `OUTPUT` clause, which is the only option that works for multi-row inserts:

```sql
DECLARE @Inserted TABLE (TaskId INT);

INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
OUTPUT inserted.TaskId INTO @Inserted (TaskId)
VALUES (1, N'Outbox worker', 1, 3, 4),
       (1, N'Outbox dispatcher', 1, 3, 4);

SELECT i.TaskId FROM @Inserted AS i;
```

Related fact worth stating: identity values are consumed even by a rolled-back transaction. Identity is **not** transactional, gaps are normal and expected, and you must never present an identity value to a user as a gapless sequence.

---

## Q17. What does "deterministic" mean, and what does it gate?  *(Senior)*
**Answer:**
A function is deterministic if it always returns the same result for the same inputs and the same database state. `LEN`, `DATEADD`, `ISNULL`, `CASE` are deterministic. `GETDATE`, `SYSUTCDATETIME`, `NEWID`, `RAND()`, `@@ROWCOUNT`, `SUSER_SNAME`, `FORMAT`, and `DATEPART(WEEKDAY, …)` are not.

It gates four real features:

- **`PERSISTED` computed columns** — must be deterministic *and* precise.
- **Indexes on computed columns** — same requirement.
- **Indexed views** — every referenced expression must be deterministic, plus `WITH SCHEMABINDING`.
- **Columns participating in `CHECK`, `PRIMARY KEY`, `UNIQUE` and `FOREIGN KEY` constraints.**

```sql
SELECT COLUMNPROPERTY(OBJECT_ID('app.Users'), 'FullName', 'IsDeterministic');  -- 1
```

`app.Users.FullName` is `FirstName + N' ' + LastName` — concatenation of two deterministic column references. That is precisely why the schema can declare it `PERSISTED` and index it. Redefine it using `FORMAT` or `GETDATE()` and the `PERSISTED` keyword becomes illegal.

**Precise** is a separate property: any expression involving `FLOAT`/`REAL` is imprecise and cannot be indexed even when deterministic. Use `DECIMAL` in computed columns you intend to index.

This also explains a powerful optimisation. Add `CreatedYear AS (YEAR(CreatedAtUtc)) PERSISTED` plus an index on it, and SQL Server will **automatically match** a query written as `WHERE YEAR(t.CreatedAtUtc) = 2025` to that index — without changing the query. That is how you fix a non-SARGable predicate in code you do not control.

---

## Q18. Why do T-SQL scalar UDFs destroy performance, and what changed in SQL Server 2019?  *(Senior)*
**Answer:**
Four independent problems:

| Problem | Effect |
|---|---|
| **Row-by-row invocation** | The function runs once per row with its own mini-plan. No set-based execution. |
| **No parallelism (pre-2019)** | A scalar UDF *anywhere* — select list, `WHERE`, or even a referenced computed column's definition — forces the **entire plan serial**. |
| **Costed as ~zero** | The optimiser assigns near-zero cost, so it picks plans based on a fiction. |
| **Invisible in the plan** | Pre-2019 the UDF's work does not appear as operators; the plan looks cheap while the query takes minutes. |

SQL Server 2019 under compatibility level 150 introduced **Scalar UDF Inlining** (the FROID framework), which rewrites a qualifying scalar UDF into an equivalent relational expression, restoring costing and parallelism:

```sql
SELECT OBJECT_NAME(sm.object_id) AS FunctionName, sm.is_inlineable
FROM   sys.sql_modules AS sm WHERE sm.is_inlineable IS NOT NULL;
```

Not every UDF qualifies — common disqualifiers are `EXECUTE`, table variables, recursion, aggregates in the return expression, and functions that write to the database. Inlining can also regress a query (different plan shape, larger memory grant), so it can be disabled per function with `WITH INLINE = OFF` or per query with `OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'))`.

The replacements, in order of preference:

| Instead of | Use |
|---|---|
| Scalar UDF in the select list | The expression inline, or `CROSS APPLY (VALUES (expr))` |
| Scalar UDF encapsulating a lookup | An **inline table-valued function** + `CROSS APPLY` — expanded into the calling plan, not called per row |
| Scalar UDF reused across many queries | A **persisted computed column**, if deterministic |
| Scalar UDF in `WHERE` | A SARGable predicate over an indexed column |

The rule: if you are about to write `CREATE FUNCTION … RETURNS INT`, write `RETURNS TABLE` instead. Inline table-valued functions are the only UDF form that is reliably free.

---

## Q19. A team ships a release and one endpoint goes from 5 ms to 4 seconds. The only SQL change was a new `WHERE` clause. Diagnose it, and then propose the standard you would put in place.  *(Architect)*
**Answer:**
**Diagnosis.** The overwhelmingly likely cause is that the column got wrapped — either explicitly by a function, or implicitly by a type mismatch. Both convert an Index Seek into a Scan.

```sql
-- Explicit: a function on the column
WHERE YEAR(t.CreatedAtUtc) = 2025
WHERE CAST(t.CompletedAtUtc AS DATE) = '2024-02-28'
WHERE t.CreatedAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time' >= @local

-- Implicit: app.Projects.ProjectCode is VARCHAR(10)
WHERE p.ProjectCode = N'TF-CORE'    -- CONVERT_IMPLICIT wraps the COLUMN
```

Data type precedence puts `NVARCHAR` above `VARCHAR`, so the *column* is converted, not the literal. This arrives from application code because .NET `string` maps to `NVARCHAR` by default. Confirm it by looking for `CONVERT_IMPLICIT` in the plan XML and for the "Type conversion in expression may affect CardinalityEstimate" warning.

**Fixes, in order.** Transform the literal, never the column: half-open date ranges instead of `YEAR()`/`CAST()`; convert the parameter to UTC in the application rather than converting the column; match the parameter type (`SqlDbType.VarChar`, Dapper `DbString { IsAnsi = true }`, EF Core `.IsUnicode(false)`). Only if you cannot change the query, add a persisted computed column plus an index, or an indexed view.

**The standard I would put in place.** Six rules, enforced in review and in CI:

1. **Types are declared, not inferred.** Every parameter in Dapper/EF/ADO.NET declares `DbType` and length. A parameter whose type does not match its column is a build failure, not a code review comment.
2. **Store UTC, format at the edge.** No `FORMAT` in SQL; no local-time columns; timezone conversion happens in the presentation layer or on the parameter, never on the column.
3. **No session-dependent functions in results.** No `DATENAME`, no `DATEPART(WEEKDAY)`, no `DATEPART(WEEK)` — `ISO_WEEK` or a calendar dimension table instead. A report must not depend on who ran it.
4. **No scalar UDFs.** `RETURNS TABLE` or nothing. Add a CI check over `sys.sql_modules` for scalar function definitions.
5. **`COALESCE` and `CASE` by default.** `ISNULL` and `IIF` only where the `NOT NULL` inference or single evaluation is genuinely required, with a comment saying so.
6. **Plans are part of the PR.** Any new or modified predicate ships with its actual plan and `SET STATISTICS IO` reads. `CONVERT_IMPLICIT` on a column, or a scan on a selective predicate, blocks the merge.

The unifying principle behind all six: a built-in function is cheap, but a built-in function applied to a **column** is a per-row tax on the entire table, because you have just traded an index seek for a scan. Everything else is a corollary.
