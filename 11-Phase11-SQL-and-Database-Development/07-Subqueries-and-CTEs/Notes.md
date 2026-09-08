# Topic 07: Subqueries & CTEs

> Every non-trivial **TaskFlow** screen asks a question inside a question. "Which tasks are over their project's average estimate?" needs the average before it can filter. "Show me the whole reporting chain under Grace Hopper" needs a query that calls itself. "Render this comment thread" needs a tree walked from arbitrary depth. Subqueries, derived tables and CTEs are the three ways to nest one result set inside another, and recursive CTEs are the only way to walk `app.Users.ManagerId`, `app.Tasks.ParentTaskId` or `app.Comments.ParentCommentId` to the bottom. This topic covers every form, the NULL traps that make two of them silently wrong, and the performance myth that makes people reach for the wrong one.

---

## 1. Subquery Taxonomy

A subquery is a `SELECT` nested inside another statement. Classify every one you write on two independent axes: **shape** (how many rows and columns it returns) and **dependence** (whether it references the outer query).

| Shape | Returns | Legal where | Failure mode |
|---|---|---|---|
| **Scalar** | 1 row, 1 column | Anywhere an expression is legal | Msg 512 if it returns >1 row |
| **Multi-row** | n rows, 1 column | `IN`, `NOT IN`, `ANY`/`SOME`, `ALL` | Msg 116 if you give it 2 columns |
| **Multi-column** | n rows, m columns | `EXISTS`, `FROM` | T-SQL has no row constructor for `IN` |
| **Table** | n rows, m columns, aliased | `FROM`, `JOIN`, `APPLY` | Msg 102 if you forget the alias |

| Dependence | Definition | Evaluation |
|---|---|---|
| **Non-correlated** | Self-contained; runnable on its own | Conceptually once |
| **Correlated** | References a column from the outer query | Conceptually once *per outer row* |

Where each is actually legal in T-SQL:

| Clause | Scalar | `IN` / `ANY` / `ALL` | `EXISTS` | Table (derived) |
|---|---|---|---|---|
| `SELECT` list | Yes | No | Yes (wrap in `CASE`) | No |
| `FROM` / `JOIN` | No | No | No | **Yes** (alias required) |
| `JOIN … ON` | Yes | Yes | Yes | No |
| `WHERE` | Yes | Yes | Yes | No |
| `GROUP BY` | **No** — Msg 144 | No | No | No |
| `HAVING` | Yes | Yes | Yes | No |
| `ORDER BY` | Yes | No | No | No |
| `CHECK` constraint | **No** — Msg 1046 | No | No | No |
| `DEFAULT` / computed column | **No** | No | No | No |

The two "no" rows people are surprised by:

```sql
-- Msg 144: Cannot use an aggregate or a subquery in an expression used for
--          the group by list of a GROUP BY clause.
SELECT COUNT(*) FROM app.Tasks AS t
GROUP BY (SELECT MAX(p.ProjectId) FROM app.Projects AS p);

-- Msg 1046: Subqueries are not allowed in this context. Only scalar
--           expressions are allowed.
ALTER TABLE app.Tasks ADD CONSTRAINT CK_Bad
    CHECK (ProjectId IN (SELECT ProjectId FROM app.Projects));
```

A `CHECK` constraint cannot see another table. That job belongs to a foreign key — which is exactly why `app.Tasks` has `FK_Tasks_Project`.

---

## 2. Scalar Subqueries

One row, one column, usable anywhere a value is.

```sql
USE TaskFlowDb;
GO

-- In the SELECT list: every task's estimate against the global average (17.354838).
SELECT
    t.TaskId,
    t.Title,
    t.EstimatedHours,
    (SELECT AVG(t2.EstimatedHours) FROM app.Tasks AS t2) AS GlobalAvg,
    t.EstimatedHours - (SELECT AVG(t2.EstimatedHours) FROM app.Tasks AS t2) AS Delta
FROM app.Tasks AS t
WHERE t.EstimatedHours > (SELECT AVG(t2.EstimatedHours) FROM app.Tasks AS t2);
```

11 rows. `AVG` ignores NULLs, so the denominator is 31, not 35 — the four tasks with a NULL `EstimatedHours` (8, 18, 25, 29) contribute nothing and are also excluded by the `>` predicate, because `NULL > 17.35` is `UNKNOWN`.

### The "returned more than one value" error

```sql
-- Works: exactly one user has CountryCode 'FI'.
SELECT (SELECT u.FullName FROM app.Users AS u WHERE u.CountryCode = 'FI') AS OnlyFinn;
-- Linus Torvalds

-- Fails: five users have CountryCode 'GB'.
SELECT (SELECT u.FullName FROM app.Users AS u WHERE u.CountryCode = 'GB') AS X;
```

```
Msg 512, Level 16, State 1
Subquery returned more than 1 value. This is not permitted when the subquery
follows =, !=, <, <= , >, >= or when the subquery is used as an expression.
```

This is a **runtime** error, not a compile error. It fires only when the data actually produces a second row — which means it ships to production and detonates six months later when somebody adds a user. Aggregate the subquery (`MAX`, `MIN`, `TOP (1) … ORDER BY`) or restructure it as a join.

> **Anti-pattern:** `TOP (1)` without `ORDER BY` to silence Msg 512. It converts a loud error into a silently arbitrary answer. If more than one row is legitimate, decide *which* one you want and say so in an `ORDER BY` with a unique tie-breaker.

A scalar subquery that matches nothing returns `NULL`, not zero rows:

```sql
SELECT (SELECT u.FullName FROM app.Users AS u WHERE u.CountryCode = 'JP') AS Nobody;  -- NULL
```

That matters in arithmetic: `Budget - (SELECT …)` becomes NULL, not `Budget`. Wrap with `ISNULL`/`COALESCE` when a missing child should mean zero.

---

## 3. `IN`, `ANY`/`SOME` and `ALL`

```sql
-- IN: 13 tasks live in the three projects owned by Margaret Hamilton (2, 3, 6).
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE t.ProjectId IN (SELECT p.ProjectId FROM app.Projects AS p WHERE p.OwnerUserId = 5);
```

`ANY` and `SOME` are synonyms. They pair a comparison operator with a set:

| Written | Means |
|---|---|
| `x = ANY (S)` | `x IN (S)` |
| `x <> ALL (S)` | `x NOT IN (S)` |
| `x > ANY (S)` | `x > MIN(S)` — greater than *at least one* |
| `x > ALL (S)` | `x > MAX(S)` — greater than *every one* |

### The `ALL` NULL asymmetry

Project 5 (`TF-QA`) has three tasks with estimates `14.00`, `20.00` and **NULL**.

```sql
-- 0 rows. Silently.
SELECT COUNT(*) FROM app.Tasks AS t
WHERE t.EstimatedHours > ALL (SELECT q.EstimatedHours FROM app.Tasks AS q WHERE q.ProjectId = 5);

-- 14 rows.
SELECT COUNT(*) FROM app.Tasks AS t
WHERE t.EstimatedHours > ANY (SELECT q.EstimatedHours FROM app.Tasks AS q WHERE q.ProjectId = 5);

-- 8 rows: guard the NULL and ALL behaves.
SELECT COUNT(*) FROM app.Tasks AS t
WHERE t.EstimatedHours > ALL (SELECT q.EstimatedHours FROM app.Tasks AS q
                              WHERE q.ProjectId = 5 AND q.EstimatedHours IS NOT NULL);
```

`ALL` is a conjunction: `x > 14 AND x > 20 AND x > NULL`. The last term is `UNKNOWN`, so the whole thing can never be `TRUE` — the same three-valued-logic failure as `NOT IN`. `ANY` is a disjunction: `x > 14 OR x > 20 OR x > NULL`. One `TRUE` disjunct wins, so `ANY` survives NULLs whenever a genuine match exists.

Empty-set behaviour is the other thing to memorise:

| Predicate | Subquery returns no rows |
|---|---|
| `x IN (∅)` | `FALSE` |
| `x NOT IN (∅)` | `TRUE` |
| `x = ANY (∅)` | `FALSE` |
| `x > ALL (∅)` | **`TRUE`** — vacuous truth |
| `EXISTS (∅)` | `FALSE` |
| `NOT EXISTS (∅)` | `TRUE` |

> **Rule of thumb:** `ANY`/`ALL` read badly and hide NULL bugs. Write `> (SELECT MAX(…))` or `> (SELECT MIN(…))` with an explicit `IS NOT NULL` filter. The intent is obvious and the NULL decision is visible in the code.

### Multi-column `IN`

```sql
-- Msg 116: Only one expression can be specified in the select list
--          when the subquery is not introduced with EXISTS.
WHERE t.TaskId IN (SELECT ta.TaskId, ta.UserId FROM app.TaskAssignments AS ta)
```

> **Portability:** PostgreSQL and MySQL support row constructors — `WHERE (TaskId, UserId) IN (SELECT TaskId, UserId FROM …)`. T-SQL does not. Use `EXISTS` with a two-column correlation, or `INTERSECT` (Topic 08).

---

## 4. `EXISTS` and `NOT EXISTS`

`EXISTS` returns `TRUE` or `FALSE` — never `UNKNOWN`. That single property makes it the NULL-safe default.

```sql
-- 9 tasks have at least one comment; 26 have none.
SELECT COUNT(*) FROM app.Tasks AS t
WHERE EXISTS (SELECT 1 FROM app.Comments AS c WHERE c.TaskId = t.TaskId);

SELECT COUNT(*) FROM app.Tasks AS t
WHERE NOT EXISTS (SELECT 1 FROM app.Comments AS c WHERE c.TaskId = t.TaskId);
```

The select list inside `EXISTS` is **never evaluated**. `SELECT 1`, `SELECT *` and `SELECT NULL` are identical, and so is this:

```sql
-- 27 rows. No divide-by-zero error, because the expression is never computed.
SELECT COUNT(*) FROM app.Tasks AS t
WHERE EXISTS (SELECT 1/0 FROM app.TaskAssignments AS ta WHERE ta.TaskId = t.TaskId);
```

Write `SELECT 1` by convention — it signals to the reader that no column is being used.

Multi-column correlation, which `IN` cannot express:

```sql
-- Assignments where the assignee also logged time on that same task. 18 pairs.
SELECT ta.TaskId, ta.UserId
FROM app.TaskAssignments AS ta
WHERE EXISTS (
    SELECT 1 FROM app.TimeEntries AS te
    WHERE te.TaskId = ta.TaskId
      AND te.UserId = ta.UserId
);
```

13 assignment pairs have no matching time entry; zero time entries exist without a matching assignment.

---

## 5. The `NOT IN` + NULL Trap

`x NOT IN (a, b, NULL)` expands to `x <> a AND x <> b AND x <> NULL`. The last term is `UNKNOWN`, so the conjunction can never be `TRUE`. **One NULL anywhere in the subquery makes `NOT IN` return zero rows.**

`app.Users.ManagerId` is nullable and does contain NULLs — Ada Lovelace and Guido van Rossum have no manager.

```sql
-- Individual contributors: users nobody reports to.
-- Returns 0 ROWS. No error, no warning.
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);
```

Four ways to write it correctly, all returning **13 rows**:

```sql
-- (1) NOT EXISTS  -- default choice
SELECT u.UserId, u.FullName FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.Users AS m WHERE m.ManagerId = u.UserId);

-- (2) LEFT JOIN ... IS NULL
SELECT u.UserId, u.FullName FROM app.Users AS u
LEFT JOIN app.Users AS m ON m.ManagerId = u.UserId
WHERE m.UserId IS NULL;

-- (3) NOT IN with an explicit guard
SELECT u.UserId, u.FullName FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m WHERE m.ManagerId IS NOT NULL);

-- (4) EXCEPT (Topic 08) -- keys only, and it de-duplicates
SELECT u.UserId FROM app.Users AS u
EXCEPT
SELECT m.ManagerId FROM app.Users AS m;
```

| Approach | NULL-safe | Returns columns from the outer table | Plan | Verdict |
|---|---|---|---|---|
| `NOT EXISTS` | **Yes** | Yes | Anti-semi-join; short-circuits on first match | **Default** |
| `LEFT JOIN … IS NULL` | Yes | Yes | Usually the same anti-semi-join | Fine; noisier to read |
| `NOT IN` + guard | Yes, *if you remember the guard* | Yes | Extra null-check branch | Fragile — the guard is easy to drop |
| `NOT IN` unguarded | **No** | Yes | Extra null-check branch | Wrong, and slower |
| `EXCEPT` | Yes | Only the compared columns | Distinct + anti-semi-join | Whole-result-set comparison |

Two extra points worth knowing:

- `NOT IN` over a nullable column is not merely wrong, it is **slower**. The optimizer must emit machinery to implement the three-valued logic, which the anti-semi-join for `NOT EXISTS` does not need.
- The bug is a **schema time bomb**. `NOT IN` over a `NOT NULL` column is correct today; a later migration that drops the `NOT NULL` silently breaks every query that relied on it, with no compile error anywhere.

> **Rule of thumb:** Ban `NOT IN` over a subquery by convention. Use `NOT EXISTS`. Reserve `NOT IN` for hard-coded literal lists, where you can see the absence of NULL with your own eyes.

---

## 6. Correlated Subqueries

A correlated subquery references the outer row. Read it as *"for each outer row, run this"*.

```sql
-- Tasks above their OWN project's average estimate. 12 rows.
SELECT t.TaskId, t.ProjectId, t.Title, t.EstimatedHours
FROM app.Tasks AS t
WHERE t.EstimatedHours > (
    SELECT AVG(t2.EstimatedHours)
    FROM app.Tasks AS t2
    WHERE t2.ProjectId = t.ProjectId        -- <-- the correlation
);
```

Drop the `WHERE t2.ProjectId = t.ProjectId` line and it becomes non-correlated: 11 rows against the global average instead of 12 against per-project averages. One line, two entirely different reports.

### Decorrelation

The "once per outer row" model is **semantics, not execution**. SQL Server routinely rewrites a correlated subquery into a join or an aggregate, so the child table is scanned once rather than 35 times. Check the plan: if you see `Nested Loops` with a scan on the inner side and a large outer row count, decorrelation did **not** happen and the query is genuinely O(n × m).

Decorrelation typically fails when the subquery contains `TOP`, `ORDER BY`, a scalar UDF, a non-deterministic function, or an `OR` that spans the correlation boundary.

```sql
-- Decorrelates cleanly: becomes an aggregate + hash join.
WHERE t.EstimatedHours > (SELECT AVG(x.EstimatedHours) FROM app.Tasks AS x WHERE x.ProjectId = t.ProjectId)

-- Will not decorrelate: TOP + ORDER BY forces a per-row loop.
(SELECT TOP (1) te.WorkDate FROM app.TimeEntries AS te WHERE te.TaskId = t.TaskId ORDER BY te.WorkDate DESC)
```

### The N-scalar-subqueries anti-pattern

```sql
-- Three correlated passes over app.TimeEntries for three measures.
SELECT
    t.TaskId,
    (SELECT COUNT(*)         FROM app.TimeEntries AS te WHERE te.TaskId = t.TaskId) AS Entries,
    (SELECT SUM(te.Hours)    FROM app.TimeEntries AS te WHERE te.TaskId = t.TaskId) AS LoggedHours,
    (SELECT MAX(te.WorkDate) FROM app.TimeEntries AS te WHERE te.TaskId = t.TaskId) AS LastWorked
FROM app.Tasks AS t;

-- One pass, one row per task, 35 rows. Same result.
SELECT t.TaskId, x.Entries, x.LoggedHours, x.LastWorked
FROM app.Tasks AS t
OUTER APPLY (
    SELECT COUNT(*) AS Entries, SUM(te.Hours) AS LoggedHours, MAX(te.WorkDate) AS LastWorked
    FROM app.TimeEntries AS te
    WHERE te.TaskId = t.TaskId
) AS x;
```

> **Rule of thumb:** One correlated scalar subquery is fine. Two against the same child table is a smell. Three is an `APPLY`.

---

## 7. Derived Tables (Inline Views)

A subquery in the `FROM` clause. It **must** have an alias, and any computed column inside it must be named.

```sql
-- Msg 102, Level 15: Incorrect syntax near ';'.
SELECT x.ProjectId FROM (SELECT t.ProjectId FROM app.Tasks AS t);
```

Why the alias is mandatory: the outer query needs a name to qualify columns with, and SQL Server has no rule for inventing one. The same applies to `(VALUES …) AS b (Col1, Col2)`.

```sql
-- Two projects have 5 or more tasks: TF-CORE (9) and TF-WEB (7).
SELECT p.ProjectCode, a.Tasks, a.Est
FROM (
    SELECT t.ProjectId, COUNT(*) AS Tasks, SUM(t.EstimatedHours) AS Est
    FROM app.Tasks AS t
    GROUP BY t.ProjectId
) AS a
JOIN app.Projects AS p ON p.ProjectId = a.ProjectId
WHERE a.Tasks >= 5
ORDER BY a.Tasks DESC;
```

Derived tables are how you filter on an aggregate you also want to project, and how you pre-aggregate a child table before joining so the grain does not change (Topic 06, §9).

Their weakness is composition. Two levels of nesting is readable; four is not, and there is no way to reference the same derived table twice without repeating it verbatim. That is precisely what CTEs fix.

---

## 8. Common Table Expressions

```sql
WITH ProjectStats AS (
    SELECT t.ProjectId, COUNT(*) AS Tasks, SUM(t.EstimatedHours) AS Est
    FROM app.Tasks AS t
    GROUP BY t.ProjectId
),
Busy AS (
    SELECT ps.ProjectId, ps.Tasks, ps.Est
    FROM ProjectStats AS ps                  -- a later CTE may reference an earlier one
    WHERE ps.Tasks >= 4
)
SELECT p.ProjectCode, b.Tasks, b.Est
FROM Busy AS b
JOIN app.Projects AS p ON p.ProjectId = b.ProjectId
ORDER BY b.Tasks DESC, p.ProjectCode;
```

| ProjectCode | Tasks | Est |
|---|---|---|
| TF-CORE | 9 | 140.00 |
| TF-WEB | 7 | 104.00 |
| TF-RPT | 4 | 62.00 |
| TF-SEC | 4 | 64.00 |

The rules that bite:

**Terminating semicolon.** `WITH` must be the first token of the batch or be preceded by `;`.

```sql
DECLARE @x INT = 1
WITH C AS (SELECT 1 AS n) SELECT n FROM C;
```
```
Msg 319, Level 15, State 1
Incorrect syntax near the keyword 'with'. If this statement is a common table
expression, an xmlnamespaces clause or a change tracking context clause, the
previous statement must be terminated with a semicolon.
```

The defensive `;WITH` idiom exists for this reason. Terminating **every** statement with a semicolon is the better habit — it is ANSI, and Microsoft has deprecated omitting it.

**Scope is one statement.** The CTE dies at the semicolon.

```sql
WITH C AS (SELECT 1 AS n) SELECT n FROM C;
SELECT n FROM C;                              -- Msg 208: Invalid object name 'C'.
```

**No forward references.** `WITH A AS (SELECT … FROM B), B AS (…)` fails with `Msg 208: Invalid object name 'B'`. Order matters; the dependency graph must be a DAG written top-down.

**Column list.** `WITH C (a, b) AS (…)` names the columns externally, which is mandatory when the inner query produces unnamed expressions.

**Not read-only.** A CTE can be the target of `INSERT`, `UPDATE`, `DELETE` or `MERGE`, which is the standard de-duplication idiom:

```sql
WITH Dupes AS (
    SELECT tl.TaskId, tl.LabelId,
           ROW_NUMBER() OVER (PARTITION BY tl.TaskId ORDER BY tl.LabelId) AS rn
    FROM app.TaskLabels AS tl
)
DELETE FROM Dupes WHERE rn > 1;   -- would remove 3 rows: the second label on tasks 4, 6, 20
```

### A CTE is not a temp table

This is the single most common misconception. A non-recursive CTE is a **named subquery** that the optimizer inlines into the outer query. There is no materialisation, no statistics, no guarantee of single evaluation.

```sql
SET STATISTICS IO ON;
WITH C AS (SELECT t.ProjectId, COUNT(*) AS N FROM app.Tasks AS t GROUP BY t.ProjectId)
SELECT a.ProjectId, a.N, b.N FROM C AS a JOIN C AS b ON b.ProjectId = a.ProjectId;
-- Table 'Tasks'. Scan count 2, logical reads 6.
```

**Scan count 2.** The CTE was referenced twice and executed twice. Reference it ten times and it runs ten times. If the CTE is expensive, materialise it deliberately into `#temp`.

The corollary is worse: a CTE containing `NEWID()`, `RAND()` or `SYSUTCDATETIME()` produces **different values** in each reference.

> **Portability:** PostgreSQL before version 12 materialised every CTE — it was an optimisation fence, and people used it deliberately. PostgreSQL 12+ inlines by default and exposes `AS MATERIALIZED` / `AS NOT MATERIALIZED` to control it. SQL Server has no such hint. MySQL 8.0+ and Oracle 11gR2+ both support `WITH`; Oracle has the `/*+ MATERIALIZE */` hint.

---

## 9. CTE vs Derived Table vs Temp Table vs Table Variable vs View

| | **CTE** | **Derived table** | **`#temp` table** | **Table variable** | **View** |
|---|---|---|---|---|---|
| Scope | One statement | One statement | Session/batch | Batch | Permanent, database-wide |
| Materialised | No | No | **Yes** | **Yes** (in tempdb) | No |
| Referenced twice | Executed twice | Must be repeated | Written once, read n times | Written once, read n times | Executed per reference |
| Statistics | Inherited from base tables | Inherited | **Full**, auto-created | **None** (1-row estimate)¹ | Inherited |
| Indexes | No | No | Yes, including after load | Only inline (PK/UNIQUE) | Only if indexed view |
| Recursion | **Yes** | No | No | No | No |
| Transaction logging | n/a | n/a | Minimal, but logged | Not rolled back | n/a |
| Parallelism on read | Yes | Yes | Yes | Yes | Yes |
| Reusable across queries | No | No | Within the session | Within the batch | **Yes** |
| Best for | Readability, chained steps, recursion | One-off nesting | Large intermediate sets reused several times | Small sets (< ~100 rows), or when rollback must not undo it | A contract other code depends on |

¹ SQL Server 2019+ at compatibility level 150 adds *table variable deferred compilation*, which gives a real cardinality estimate on first compile. It is still not statistics — there is no histogram.

Decision path:

1. Nesting one query in another, used once → **derived table**.
2. Same thing but you want to name the step or chain three of them → **CTE**.
3. Walking a hierarchy → **recursive CTE**. Nothing else does this.
4. The intermediate result is expensive **and** referenced more than once → **`#temp` table**.
5. The intermediate result is tiny and referenced more than once → **table variable**.
6. Other queries, reports or applications need the same definition → **view**.

> **Anti-pattern:** Rewriting a five-step `#temp` pipeline as a five-CTE chain "for performance". It is usually slower. The `#temp` version gave the optimizer real row counts at each step; the CTE version collapses into one giant plan built on estimates.

---

## 10. Recursive CTEs — Mechanics

```sql
WITH cte AS (
    <anchor member>              -- runs once, seeds the result
    UNION ALL
    <recursive member>           -- references cte; runs repeatedly
)
SELECT … FROM cte;
```

Execution:

1. Run the **anchor**. Its output is generation 0.
2. Run the **recursive member** against generation *n*, producing generation *n+1*.
3. Repeat until a generation returns zero rows.
4. The CTE's value is the `UNION ALL` of every generation.

The recursive member sees **only the previous generation**, not the accumulated result. That is why a level counter must be carried forward as a column.

### T-SQL restrictions on the recursive member

Every one of these is a hard error, verified:

| Written | Error |
|---|---|
| `UNION` instead of `UNION ALL` | Msg 252 — *does not contain a top-level UNION ALL operator* |
| `LEFT`/`RIGHT`/`FULL JOIN` to the CTE | Msg 462 — *Outer join is not allowed in the recursive part* |
| `GROUP BY`, `HAVING` or an aggregate | Msg 467 |
| `TOP` or `OFFSET` | Msg 461 |
| Referencing the CTE twice | Msg 253 — *has multiple recursive references* |
| `SELECT DISTINCT` | Msg 460 |

Anchor and recursive member must also agree on column **count and data type**. `CAST` the anchor's path column to its final width or you will get a truncation error on the first recursion.

### `MAXRECURSION`

Default 100. Exceeding it aborts the whole statement:

```sql
WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 500)
SELECT COUNT(*) FROM N;
```
```
Msg 530, Level 16, State 1
The statement terminated. The maximum recursion 100 has been exhausted before
statement completion.
```

```sql
-- 500. OPTION goes on the outer statement, never inside the CTE.
WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 500)
SELECT COUNT(*) AS C FROM N OPTION (MAXRECURSION 0);
```

`MAXRECURSION 0` means **unlimited**. Set it only when you have proved the data is acyclic or you carry a cycle guard (§14) — otherwise a single bad row spins until tempdb fills.

> **Rule of thumb:** Set `MAXRECURSION` to the deepest legitimate depth plus a safety margin, not to 0. If your org chart is never more than 12 deep, `OPTION (MAXRECURSION 20)` turns a runaway into a loud, fast, diagnosable error.

---

## 11. Worked Example: the Org Chart

`app.Users.ManagerId` self-references `app.Users.UserId`. Two users have no manager: Ada Lovelace (`UserId` 1) and Guido van Rossum (`UserId` 20).

```sql
WITH OrgChart AS (
    -- Anchor: everyone with no manager
    SELECT
        u.UserId,
        u.FullName,
        u.JobTitle,
        u.ManagerId,
        1                                       AS Depth,
        CAST(u.FullName AS NVARCHAR(4000))      AS Chain,
        CAST(RIGHT('0000' + CAST(u.UserId AS VARCHAR(5)), 5) AS VARCHAR(4000)) AS SortPath
    FROM app.Users AS u
    WHERE u.ManagerId IS NULL

    UNION ALL

    -- Recursive: everyone reporting to a row already in the set
    SELECT
        u.UserId,
        u.FullName,
        u.JobTitle,
        u.ManagerId,
        oc.Depth + 1,
        CAST(oc.Chain + N' > ' + u.FullName AS NVARCHAR(4000)),
        CAST(oc.SortPath + '/' + RIGHT('0000' + CAST(u.UserId AS VARCHAR(5)), 5) AS VARCHAR(4000))
    FROM app.Users AS u
    JOIN OrgChart AS oc ON oc.UserId = u.ManagerId
)
SELECT
    REPLICATE(N'    ', Depth - 1) + FullName AS Tree,
    JobTitle,
    Depth,
    Chain
FROM OrgChart
ORDER BY SortPath
OPTION (MAXRECURSION 20);
```

20 rows — the whole company, because the anchor picks up both roots.

| Depth | Users |
|---|---|
| 1 | 2 — Ada Lovelace, Guido van Rossum |
| 2 | 2 — Grace Hopper, Alan Turing |
| 3 | 6 |
| 4 | 10 |

Sample `Chain` values:

| UserId | Depth | Chain |
|---|---|---|
| 13 | 4 | Ada Lovelace > Alan Turing > Barbara Liskov > Shafi Goldwasser |
| 16 | 4 | Ada Lovelace > Grace Hopper > Joan Clarke > Hedy Lamarr |
| 20 | 1 | Guido van Rossum |

Three variations, all one-line changes to the anchor:

```sql
-- Subtree: everyone under Ada Lovelace, inclusive. 19 rows.
WHERE u.UserId = 1

-- Subtree under Grace Hopper (UserId 2). 12 rows: Grace + 3 + 8.
WHERE u.UserId = 2

-- Ancestors: walk UP from Hedy Lamarr to the CEO. 4 rows.
--   anchor:    WHERE u.UserId = 16
--   recursive: JOIN app.Users AS u ON u.UserId = oc.ManagerId
```

The **direction** of the recursion is decided entirely by which side of the join carries the CTE. `oc.UserId = u.ManagerId` walks down; `u.UserId = oc.ManagerId` walks up.

The `SortPath` column is what makes an indented tree render correctly. Sorting by `Depth` alone interleaves unrelated branches; sorting by a zero-padded materialised path keeps each subtree contiguous. Pad to a fixed width — without `RIGHT('0000' + …, 5)`, `UserId` 10 sorts before `UserId` 2.

Depth limiting without `MAXRECURSION`:

```sql
-- Ada plus two levels down. 9 rows (1 + 2 + 6).
WITH Org AS (
    SELECT u.UserId, 1 AS Depth FROM app.Users AS u WHERE u.UserId = 1
    UNION ALL
    SELECT c.UserId, o.Depth + 1
    FROM app.Users AS c
    JOIN Org AS o ON o.UserId = c.ManagerId
    WHERE o.Depth < 3
)
SELECT COUNT(*) AS C FROM Org;
```

A `WHERE` on the recursive member is a **business** limit and returns rows. `MAXRECURSION` is a **safety** limit and raises an error. They are not interchangeable.

---

## 12. Worked Example: the Sub-Task Tree

`app.Tasks.ParentTaskId` gives 31 root tasks and 4 sub-tasks (2 and 3 under task 1; 11 and 12 under task 10).

```sql
WITH TaskTree AS (
    SELECT
        t.TaskId, t.ParentTaskId, t.Title, t.EstimatedHours,
        0 AS Depth,
        CAST(t.TaskId AS VARCHAR(4000)) AS Path
    FROM app.Tasks AS t
    WHERE t.ParentTaskId IS NULL

    UNION ALL

    SELECT
        c.TaskId, c.ParentTaskId, c.Title, c.EstimatedHours,
        tt.Depth + 1,
        CAST(tt.Path + '.' + CAST(c.TaskId AS VARCHAR(10)) AS VARCHAR(4000))
    FROM app.Tasks AS c
    JOIN TaskTree AS tt ON tt.TaskId = c.ParentTaskId
)
SELECT Depth, COUNT(*) AS Tasks FROM TaskTree GROUP BY Depth ORDER BY Depth;
-- Depth 0: 31   Depth 1: 4
```

The report that actually matters — **roll-up of effort including all descendants**:

```sql
-- Task 1 'Design database schema': 3 nodes, 40.00 estimated hours
-- (24.00 itself + 6.00 + 10.00 from its two sub-tasks).
WITH Subtree AS (
    SELECT t.TaskId, t.EstimatedHours FROM app.Tasks AS t WHERE t.TaskId = 1
    UNION ALL
    SELECT c.TaskId, c.EstimatedHours
    FROM app.Tasks AS c
    JOIN Subtree AS s ON s.TaskId = c.ParentTaskId
)
SELECT COUNT(*) AS Nodes, SUM(EstimatedHours) AS RolledUpEstimate FROM Subtree;
```

Generalised to every root task with `OUTER APPLY` over a recursive inline TVF, or — more simply — by carrying the root id through the recursion:

```sql
WITH Tree AS (
    SELECT t.TaskId, t.TaskId AS RootTaskId, t.EstimatedHours
    FROM app.Tasks AS t WHERE t.ParentTaskId IS NULL
    UNION ALL
    SELECT c.TaskId, tr.RootTaskId, c.EstimatedHours
    FROM app.Tasks AS c JOIN Tree AS tr ON tr.TaskId = c.ParentTaskId
)
SELECT r.TaskId, r.Title, SUM(tr.EstimatedHours) AS TotalEstimate, COUNT(*) AS Nodes
FROM Tree AS tr
JOIN app.Tasks AS r ON r.TaskId = tr.RootTaskId
GROUP BY r.TaskId, r.Title
ORDER BY TotalEstimate DESC;
```

31 rows, one per root. Task 10 totals 62.00 across 3 nodes; task 1 totals 40.00 across 3.

> **Rule of thumb:** Carry the root id down through every generation. It converts "walk one tree" into "walk every tree and group", which is nearly always the report you actually wanted.

---

## 13. Worked Example: Comment Threads

`app.Comments.ParentCommentId` holds 9 root comments and 3 replies. Rendering a thread needs replies to appear directly under their parent, indented — which is a sort problem, not a recursion problem.

```sql
WITH Thread AS (
    SELECT
        c.CommentId, c.TaskId, c.ParentCommentId, c.AuthorUserId, c.Body, c.PostedAtUtc,
        0 AS Depth,
        CAST(RIGHT('000000000' + CAST(c.CommentId AS VARCHAR(10)), 10) AS VARCHAR(4000)) AS SortPath
    FROM app.Comments AS c
    WHERE c.ParentCommentId IS NULL

    UNION ALL

    SELECT
        r.CommentId, r.TaskId, r.ParentCommentId, r.AuthorUserId, r.Body, r.PostedAtUtc,
        th.Depth + 1,
        CAST(th.SortPath + '/' + RIGHT('000000000' + CAST(r.CommentId AS VARCHAR(10)), 10) AS VARCHAR(4000))
    FROM app.Comments AS r
    JOIN Thread AS th ON th.CommentId = r.ParentCommentId
)
SELECT
    th.TaskId,
    REPLICATE(N'  ', th.Depth) + u.FullName AS Author,
    th.Body,
    th.PostedAtUtc
FROM Thread AS th
JOIN app.Users AS u ON u.UserId = th.AuthorUserId
WHERE th.TaskId = 20
ORDER BY th.SortPath;
```

| Author | Body |
|---|---|
| Barbara Liskov | Every dynamic statement must be parameterised. |
| ␣␣Shafi Goldwasser | Rewriting with sp_executesql and typed params. |

12 rows unfiltered — 9 at depth 0, 3 at depth 1.

Sorting by `PostedAtUtc` alone would be wrong: a reply posted later than an unrelated root comment would jump out of its thread. The materialised `SortPath` is what preserves thread structure. If you want *newest thread first* with replies still nested, build the root segment of the path from an inverted timestamp and keep the child segments ascending.

---

## 14. Series, Calendars and Cycle Detection

### Number series

```sql
-- Recursive: readable, but one row per recursion level. Fine to ~1000.
WITH N AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM N WHERE n < 1000
)
SELECT n FROM N OPTION (MAXRECURSION 0);
```

```sql
-- Set-based: 10 x 10 x 10 x 10 = 10,000 candidate rows, no recursion at all.
-- Faster, and it does not need MAXRECURSION.
WITH L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS v (c)),
     L1 AS (SELECT 1 AS c FROM L0 AS a CROSS JOIN L0 AS b),
     L2 AS (SELECT 1 AS c FROM L1 AS a CROSS JOIN L1 AS b),
     Nums AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM L2)
SELECT n FROM Nums WHERE n <= 1000;
```

> **Rule of thumb:** Recursion for *hierarchies*, cross-joined `VALUES` for *series*. A recursive counter is O(n) round trips through a spool; the cross-join doubles rows per level and is O(log n) operators.

### Calendar spine

A burndown chart needs a row for every day, including days with no activity.

```sql
-- 31 days in August 2025; 4 of them have a task due (tasks 25, 20, 35, 5).
WITH Calendar AS (
    SELECT CAST('2025-08-01' AS DATE) AS CalendarDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CalendarDate) FROM Calendar WHERE CalendarDate < '2025-08-31'
)
SELECT
    c.CalendarDate,
    x.TasksDue
FROM Calendar AS c
CROSS APPLY (
    SELECT COUNT(*) AS TasksDue
    FROM app.Tasks AS t
    WHERE t.DueDate = c.CalendarDate
) AS x
ORDER BY c.CalendarDate;
```

September 2025 has 30 days and 6 tasks due. Without the spine, a `GROUP BY t.DueDate` returns 4 rows for August and the chart has 27 invisible holes.

### Cycle detection

The `FK_Users_Manager` constraint guarantees referential integrity but **not acyclicity**. Nothing stops `UPDATE app.Users SET ManagerId = 16 WHERE UserId = 2` from creating a loop. A naive recursive CTE then runs forever — or until `MAXRECURSION` kills it, with no indication of *where* the cycle is.

Carry a visited-set in the path column and stop when you see a repeat:

```sql
WITH Edges (ChildId, ParentId) AS (
    SELECT * FROM (VALUES (101, 103), (102, 101), (103, 102)) AS v (ChildId, ParentId)
),
Walk AS (
    SELECT
        e.ChildId, e.ParentId, 1 AS Depth,
        CAST('|' + CAST(e.ChildId AS VARCHAR(10)) + '|' AS VARCHAR(4000)) AS Visited,
        0 AS IsCycle
    FROM Edges AS e
    WHERE e.ChildId = 101

    UNION ALL

    SELECT
        e.ChildId, e.ParentId, w.Depth + 1,
        CAST(w.Visited + CAST(e.ChildId AS VARCHAR(10)) + '|' AS VARCHAR(4000)),
        CASE WHEN w.Visited LIKE '%|' + CAST(e.ChildId AS VARCHAR(10)) + '|%' THEN 1 ELSE 0 END
    FROM Edges AS e
    JOIN Walk AS w ON w.ParentId = e.ChildId
    WHERE w.IsCycle = 0                       -- stop expanding once a cycle is seen
)
SELECT ChildId, Depth, Visited, IsCycle FROM Walk ORDER BY Depth;
```

| ChildId | Depth | Visited | IsCycle |
|---|---|---|---|
| 101 | 1 | `\|101\|` | 0 |
| 103 | 2 | `\|101\|103\|` | 0 |
| 102 | 3 | `\|101\|103\|102\|` | 0 |
| 101 | 4 | `\|101\|103\|102\|101\|` | **1** |

The query terminates on its own and the offending row is identifiable. The delimiters around each id are essential — without them, `LIKE '%1%'` matches `101`, `12` and `21`.

### Debugging infinite recursion

1. Set `OPTION (MAXRECURSION 5)` and look at what comes back. If the same key appears twice, that is your cycle.
2. Add the visited-path column above and select `WHERE IsCycle = 1`.
3. Check the join direction. `JOIN cte ON cte.UserId = u.UserId` (instead of `= u.ManagerId`) joins each row to itself and recurses forever.
4. Check the anchor. An anchor of `WHERE u.ManagerId IS NULL` on a table where **every** row has a manager returns nothing, and the CTE is silently empty — the opposite failure, and just as quiet.
5. Never "fix" it with `MAXRECURSION 0`. That converts a fast error into a tempdb-filling hang.

---

## 15. When to Reach for `APPLY` Instead

| Requirement | Correlated subquery | `APPLY` |
|---|---|---|
| One aggregate from a child table | Fine | Overkill |
| Two or more measures from the same child | Repeats the scan per measure | **One pass** |
| The "latest" child row, several columns | One `TOP (1)` subquery per column | **One `CROSS APPLY`** |
| Top-N children per parent | Impossible | **`CROSS APPLY … TOP (n)`** |
| Call a table-valued function per row | Impossible | **Mandatory** |
| Expand JSON or a delimited string | Impossible | **`CROSS APPLY OPENJSON`** |
| Existence test only | **`EXISTS`** | Wrong tool |

The rule reduces to: a correlated subquery returns **one value**; `APPLY` returns a **row set**. The moment you want a second column out of the same correlated query, switch.

---

## 16. Readability: Chains Beat Nesting

Nested subqueries read inside-out. CTE chains read top-down, in execution order.

```sql
-- Nested: you must find the innermost query first and read outward.
SELECT p.ProjectCode, o.Tasks
FROM (
    SELECT a.ProjectId, a.Tasks
    FROM (
        SELECT t.ProjectId, COUNT(*) AS Tasks
        FROM app.Tasks AS t
        WHERE t.StatusId NOT IN (6, 7)
        GROUP BY t.ProjectId
    ) AS a
    WHERE a.Tasks >= 3
) AS o
JOIN app.Projects AS p ON p.ProjectId = o.ProjectId;

-- Chained: read top to bottom, each step named.
WITH OpenTasks AS (
    SELECT t.ProjectId, t.TaskId
    FROM app.Tasks AS t
    WHERE t.StatusId NOT IN (6, 7)          -- StatusId is NOT NULL, so NOT IN is safe
),
PerProject AS (
    SELECT ot.ProjectId, COUNT(*) AS Tasks
    FROM OpenTasks AS ot
    GROUP BY ot.ProjectId
),
Busy AS (
    SELECT pp.ProjectId, pp.Tasks FROM PerProject AS pp WHERE pp.Tasks >= 3
)
SELECT p.ProjectCode, b.Tasks
FROM Busy AS b
JOIN app.Projects AS p ON p.ProjectId = b.ProjectId
ORDER BY b.Tasks DESC;
```

Identical plans. The second is the one you can debug at 3 a.m., because you can select from any intermediate step by changing the final `SELECT`.

> **Anti-pattern:** A twelve-CTE chain where each step is used once and the whole thing compiles into one 200-operator plan. Past roughly five steps, the optimizer's estimates compound into nonsense. Break the pipeline with a `#temp` table at the point where the row count changes by an order of magnitude.

---

## 17. Performance Myths

| Claim | Reality |
|---|---|
| "CTEs are faster than subqueries." | Identical. A non-recursive CTE is inlined; the plans are usually byte-for-byte the same. |
| "A CTE is evaluated once." | No. Each reference is a separate evaluation — `Scan count 2` for two references. |
| "CTEs avoid tempdb." | So do derived tables. Neither materialises. A recursive CTE *does* use a tempdb worktable/spool. |
| "`EXISTS` is faster than `IN`." | For a non-correlated, NULL-free set they compile to the same semi-join. `EXISTS` wins on **correctness** with NULLs, not speed. |
| "Correlated subqueries always run per row." | Often decorrelated into a join or aggregate. Read the plan before rewriting. |
| "Recursive CTEs are slow." | They are O(nodes). What is slow is running one per row of an outer query, or scanning the parent table without an index on the parent-key column. |
| "`MAXRECURSION 0` makes it faster." | It removes a safety limit. It changes nothing about speed. |
| "Rewriting `IN` as a `JOIN` speeds it up." | It can also *change the result* by duplicating outer rows when the inner set has duplicates. |

The one genuine performance lever for recursive CTEs: **index the recursion key**. `app.Users.ManagerId` and `app.Tasks.ParentTaskId` are foreign keys, and SQL Server does not index foreign keys automatically. Every generation issues a lookup by parent id; without an index that is a full scan per generation.

```sql
CREATE INDEX IX_Users_ManagerId ON app.Users (ManagerId) INCLUDE (FullName, JobTitle);
CREATE INDEX IX_Tasks_ParentTaskId ON app.Tasks (ParentTaskId) INCLUDE (Title, EstimatedHours);
```

---

## Mental Model

> A subquery is a question asked **inside** another question, and the only two things that matter are its **shape** and whether it can **see the outer row**. Shape decides where it is legal: one row and one column goes anywhere an expression goes; many rows go next to `IN`/`ANY`/`ALL`/`EXISTS`; a whole table goes in `FROM` and must be given a name. Seeing the outer row makes it correlated — semantically once per row, though the optimizer usually rewrites it into a join, and you check the plan rather than guess. `NOT IN` and `> ALL` are conjunctions over the set, so a single NULL turns them permanently `UNKNOWN` and the result is silently empty; `EXISTS` is two-valued and cannot do that, which is why it is the default. A CTE is not a temp table — it is a **name for a subquery**, inlined, re-executed once per reference, alive for exactly one statement — so use it for readability and reach for `#temp` when you need materialisation, statistics or reuse. And when a row's relationship is to another row in the *same* table, no join count is ever enough: anchor at the roots, `UNION ALL` a member that joins back to the CTE, carry a depth and a padded path so you can sort and detect cycles, and cap the depth with a number you chose rather than a zero.

Move to [Practice Problems](./Practice-Problems.md).
