# Topic 05: Aggregations & Grouping

> Every screen in **TaskFlow** that a manager actually looks at is an aggregate. "How many open tasks does the Platform team have?" "What is the average story-point size of a Critical bug?" "Which projects burned more hours than they estimated?" None of that is a row-by-row question — it is a *collapse many rows into one number* question. `GROUP BY` is the single most misused clause in SQL: it silently double-counts when you join, it silently truncates when your column is an integer, and it silently swallows NULLs. This topic makes those failures visible so you stop shipping dashboards that are quietly wrong.

---

## 1. What an Aggregate Actually Is

An aggregate function takes a **multiset of rows** and returns **one scalar**. Two forms exist:

| Form | Syntax | Rows returned on empty input |
|---|---|---|
| **Scalar aggregate** (no `GROUP BY`) | `SELECT COUNT(*) FROM app.Tasks` | Exactly **1** row |
| **Vector aggregate** (with `GROUP BY`) | `SELECT ProjectId, COUNT(*) … GROUP BY ProjectId` | **0** rows |

That difference matters more than it looks:

```sql
USE TaskFlowDb;
GO

-- Scalar aggregate on an empty set: ONE row, COUNT = 0, SUM = NULL
SELECT COUNT(*)             AS Cnt,        -- 0
       SUM(t.EstimatedHours) AS TotalHours  -- NULL
FROM app.Tasks AS t
WHERE t.ProjectId = 999;

-- Vector aggregate on an empty set: ZERO rows. Your report shows nothing at all.
SELECT t.ProjectId, COUNT(*) AS Cnt
FROM app.Tasks AS t
WHERE t.ProjectId = 999
GROUP BY t.ProjectId;
```

> **Rule of thumb:** If a caller expects a number, wrap the sum: `ISNULL(SUM(x), 0)`. If a caller expects a row per project, you must drive the query from `app.Projects` with a `LEFT JOIN`, not from `app.Tasks`.

---

## 2. The Golden NULL Rule

**Every aggregate except `COUNT(*)` ignores NULL inputs.** Not "treats them as zero" — *removes them from the set before computing*.

```sql
SELECT
    COUNT(*)                    AS AllRows,          -- 35
    COUNT(t.TaskId)             AS NonNullIds,       -- 35 (PK, never NULL)
    COUNT(t.DueDate)            AS RowsWithDueDate,  -- 27  (8 tasks have NULL DueDate)
    COUNT(t.Description)        AS RowsWithDesc,     -- 0   (column is entirely NULL)
    COUNT(DISTINCT t.StatusId)  AS DistinctStatuses, -- 7
    COUNT(DISTINCT t.PriorityId) AS DistinctPriorities -- 5
FROM app.Tasks AS t;
```

### `COUNT(*)` vs `COUNT(col)` vs `COUNT(DISTINCT col)`

| Expression | Counts | NULL behaviour | Typical use |
|---|---|---|---|
| `COUNT(*)` | Rows in the group | N/A — never looks at values | "How many tasks?" |
| `COUNT(1)` | Identical to `COUNT(*)` | N/A | No performance difference. A myth. |
| `COUNT(col)` | Rows where `col IS NOT NULL` | Skips NULL | "How many tasks have a due date?" |
| `COUNT(DISTINCT col)` | Distinct non-NULL values | Skips NULL, then dedupes | "How many different statuses are in use?" |
| `COUNT_BIG(*)` | Same as `COUNT(*)` but returns `BIGINT` | N/A | > 2.1 billion rows; mandatory in indexed views |
| `APPROX_COUNT_DISTINCT(col)` | HyperLogLog estimate | Skips NULL | Billion-row cardinality, ±2 % is fine |

> **Anti-pattern:** `COUNT(t.TaskId)` when you mean `COUNT(*)`. It works only because `TaskId` is a NOT NULL primary key. The instant someone left-joins that table, `COUNT(t.TaskId)` and `COUNT(*)` diverge — and that divergence is usually the *correct* behaviour you did not ask for.

### The SUM / AVG trap

`AVG` divides by the count of **non-NULL** values, not by the row count:

```sql
SELECT
    COUNT(*)                     AS Projects,     -- 8
    COUNT(p.Budget)              AS WithBudget,   -- 6  (TF-MOB and TF-LAB are NULL)
    SUM(p.Budget)                AS TotalBudget,  -- 660000.00
    AVG(p.Budget)                AS AvgBudget,    -- 110000.00  = 660000 / 6
    SUM(p.Budget) / COUNT(*)     AS AvgIfNullIsZero -- 82500     = 660000 / 8
FROM app.Projects AS p;
```

Both numbers are defensible. **Only one answers the business question.** Decide explicitly:

| You mean | Write |
|---|---|
| Average of projects that *have* a budget | `AVG(p.Budget)` |
| Average across *all* projects, unbudgeted = 0 | `AVG(ISNULL(p.Budget, 0))` or `SUM(p.Budget) / COUNT(*)` |

### The integer-division trap

`AVG` returns the **data type of its argument**. `app.Tasks.StoryPoints` is `TINYINT`, so `AVG` does integer maths and truncates:

```sql
SELECT
    AVG(t.StoryPoints)                              AS Avg_Truncated,  -- 6
    AVG(CAST(t.StoryPoints AS DECIMAL(10,2)))       AS Avg_Correct,    -- 6.7741...
    SUM(t.StoryPoints)                              AS TotalPoints,    -- 210
    COUNT(t.StoryPoints)                            AS PointedTasks    -- 31 of 35
FROM app.Tasks AS t;
```

`210 / 31 = 6.774…` → integer `AVG` throws away 11 % of the value. This bug reaches production constantly because 6 *looks* like a plausible answer.

> **Rule of thumb:** Cast to `DECIMAL` before averaging anything declared `TINYINT`, `SMALLINT`, `INT`, or `BIGINT`. Cast the *column*, not the result — `CAST(AVG(x) AS DECIMAL(10,2))` is too late.

### The ANSI warning

With `SET ANSI_WARNINGS ON` (the default for most drivers, including SqlClient), skipping NULLs raises:

```
Warning: Null value is eliminated by an aggregate or other SET operation.
```

It is informational, not an error, but it is a useful smoke alarm in tests.

---

## 3. The Aggregate Function Catalogue (T-SQL)

| Function | Returns | Notes |
|---|---|---|
| `COUNT` / `COUNT_BIG` | `INT` / `BIGINT` | `COUNT(*)` is the only NULL-blind aggregate |
| `SUM` | Type of argument (int promoted to `INT`/`BIGINT`) | Overflow is a real risk on `INT` |
| `AVG` | Type of argument; `DECIMAL(p,s)` → `DECIMAL(38,s)` | Integer truncation trap |
| `MIN` / `MAX` | Type of argument | Work on strings and dates too |
| `STRING_AGG(expr, sep)` | `NVARCHAR` | SQL Server 2017+. Add `WITHIN GROUP (ORDER BY …)` |
| `STDEV` / `STDEVP` | `FLOAT` | **Sample** vs **Population** standard deviation |
| `VAR` / `VARP` | `FLOAT` | **Sample** vs **Population** variance |
| `APPROX_COUNT_DISTINCT` | `BIGINT` | SQL Server 2019+ / Azure SQL. ~2 % error, tiny memory |
| `CHECKSUM_AGG` | `INT` | Cheap change-detection hash over a group |

```sql
-- Rate dispersion across the org (HourlyRate is NULL for Sophie Wilson)
SELECT
    COUNT(u.HourlyRate) AS RatedUsers,   -- 19 of 20
    MIN(u.HourlyRate)   AS MinRate,      -- 64.00  (Hedy Lamarr)
    MAX(u.HourlyRate)   AS MaxRate,      -- 180.00 (Ada Lovelace)
    SUM(u.HourlyRate)   AS RateSum,      -- 2045.50
    STDEV(u.HourlyRate) AS SampleStdDev, -- divides by (n-1)
    STDEVP(u.HourlyRate) AS PopStdDev,   -- divides by n
    VAR(u.HourlyRate)   AS SampleVar,
    VARP(u.HourlyRate)  AS PopVar
FROM app.Users AS u;
```

**`STDEV` vs `STDEVP`:** use `STDEV` (sample, Bessel-corrected `n-1`) when your rows are a *sample* of a larger population; use `STDEVP` when the rows *are* the whole population. With a single non-NULL row `STDEV` returns `NULL` and `STDEVP` returns `0`.

### `STRING_AGG` — the row-to-string aggregate

```sql
-- One row per task, labels flattened into a sorted CSV
SELECT
    t.TaskId,
    t.Title,
    STRING_AGG(l.LabelName, N', ') WITHIN GROUP (ORDER BY l.LabelName) AS Labels
FROM app.Tasks AS t
JOIN app.TaskLabels AS tl ON tl.TaskId = t.TaskId
JOIN app.Labels     AS l  ON l.LabelId = tl.LabelId
WHERE t.TaskId IN (4, 6, 20)
GROUP BY t.TaskId, t.Title;
```

| TaskId | Title | Labels |
|---|---|---|
| 4 | Implement auth endpoints | `feature, security` |
| 6 | Fix N+1 query on project detail | `bug, performance` |
| 20 | Remove dynamic SQL from reports | `security, tech-debt` |

`STRING_AGG` skips NULLs. If the separator matters and you need a placeholder, use `STRING_AGG(ISNULL(l.LabelName, N'?'), N', ')`.

### Portability

| T-SQL | PostgreSQL | MySQL | Oracle |
|---|---|---|---|
| `STRING_AGG(x, ',') WITHIN GROUP (ORDER BY y)` | `string_agg(x, ',' ORDER BY y)` | `GROUP_CONCAT(x ORDER BY y SEPARATOR ',')` | `LISTAGG(x, ',') WITHIN GROUP (ORDER BY y)` |
| `STDEV` / `STDEVP` | `stddev_samp` / `stddev_pop` | `STDDEV_SAMP` / `STDDEV_POP` | `STDDEV_SAMP` / `STDDEV_POP` |
| `VAR` / `VARP` | `var_samp` / `var_pop` | `VAR_SAMP` / `VAR_POP` | `VAR_SAMP` / `VAR_POP` |
| `APPROX_COUNT_DISTINCT` | `hll_*` (extension) | — | `APPROX_COUNT_DISTINCT` |
| `COUNT_BIG` | `count()` is already `bigint` | — | — |

---

## 4. `GROUP BY` Semantics

`GROUP BY` partitions the intermediate result into buckets keyed by the grouping expression, then evaluates one aggregate per bucket.

### The rule that trips everyone up

> **Every column in the `SELECT` list must either be inside an aggregate or listed in the `GROUP BY`.**

```sql
-- FAILS: Msg 8120 — Column 'app.Tasks.Title' is invalid in the select list
-- because it is not contained in either an aggregate function or the GROUP BY clause.
SELECT t.ProjectId, t.Title, COUNT(*) AS Cnt
FROM app.Tasks AS t
GROUP BY t.ProjectId;
```

There is no "just pick one" in SQL Server. You must decide what you actually want:

```sql
-- I want a representative value  -> aggregate it
SELECT t.ProjectId, MAX(t.Title) AS SampleTitle, COUNT(*) AS Cnt
FROM app.Tasks AS t
GROUP BY t.ProjectId;

-- I want a row per title          -> group by it too
SELECT t.ProjectId, t.Title, COUNT(*) AS Cnt
FROM app.Tasks AS t
GROUP BY t.ProjectId, t.Title;
```

### Portability: how other engines relax the rule

| Engine | Behaviour |
|---|---|
| **SQL Server** | Strict. Always error 8120. No exceptions. |
| **PostgreSQL** | Strict, **plus functional-dependency relaxation**: if you `GROUP BY` a table's primary key, you may select any column of that table. |
| **MySQL** | `ONLY_FULL_GROUP_BY` is **on by default since 5.7.5**. With it off, MySQL returns an arbitrary row's value — the classic source of non-deterministic reports. |
| **Oracle** | Strict, like SQL Server. |
| **SQLite** | Permissive; picks an arbitrary row. |

> **Anti-pattern:** Porting a MySQL query that relies on `ONLY_FULL_GROUP_BY` being disabled. It will not compile on SQL Server, and when you "fix" it by wrapping columns in `MIN()` you may silently change the meaning.

### Grouping by expressions

You can group by any deterministic expression. You do **not** repeat the alias — T-SQL evaluates `SELECT` after `GROUP BY`, so aliases are not visible there.

```sql
-- Tasks created per month
SELECT
    DATEFROMPARTS(YEAR(t.CreatedAtUtc), MONTH(t.CreatedAtUtc), 1) AS CreatedMonth,
    COUNT(*) AS TasksCreated
FROM app.Tasks AS t
GROUP BY DATEFROMPARTS(YEAR(t.CreatedAtUtc), MONTH(t.CreatedAtUtc), 1)
ORDER BY CreatedMonth;   -- alias IS legal in ORDER BY (evaluated after SELECT)
```

> **Anti-pattern:** Grouping by a non-deterministic or non-sargable expression such as `CONVERT(VARCHAR(7), t.CreatedAtUtc, 120)`. It defeats every index on `CreatedAtUtc` and forces a sort of the whole table.

### NULL grouping semantics

`GROUP BY` uses **`IS NOT DISTINCT FROM`** semantics, not `=`. All NULLs collapse into **one** group, even though `NULL = NULL` is `UNKNOWN`.

```sql
-- One row where ManagerId IS NULL, containing Ada Lovelace and Guido van Rossum
SELECT u.ManagerId, COUNT(*) AS DirectReports
FROM app.Users AS u
GROUP BY u.ManagerId
ORDER BY u.ManagerId;
```

| ManagerId | DirectReports |
|---|---|
| NULL | 2 |
| 1 | 2 |
| 2 | 3 |
| 3 | 3 |
| 4 | 4 |
| 5 | 3 |
| 6 | 2 |
| 15 | 1 |

The `NULL` row is *not* "users without a manager grouped by accident" — it is a real, deliberate group. Same rule applies to `DISTINCT`, `UNION`, and `PARTITION BY`.

---

## 5. `WHERE` vs `HAVING` — Logical Processing Order

SQL is written in one order and *evaluated* in another. Memorise this:

```
1. FROM            -- produce the Cartesian/join input
2. ON              -- join predicates
3. JOIN            -- add outer rows back (LEFT/RIGHT/FULL)
4. WHERE           -- filter INDIVIDUAL ROWS      <-- no aggregates visible yet
5. GROUP BY        -- collapse rows into groups
6. HAVING          -- filter GROUPS               <-- aggregates visible
7. SELECT          -- evaluate expressions, assign aliases
8. DISTINCT
9. ORDER BY        -- aliases from step 7 usable here
10. TOP / OFFSET-FETCH
```

Two consequences:

- `WHERE` cannot reference an aggregate. `WHERE COUNT(*) > 3` → Msg 147.
- `HAVING` cannot reference a `SELECT` alias. `HAVING OpenTasks > 3` → Msg 207. Repeat the expression: `HAVING COUNT(*) > 3`.

### Decision table

| Predicate is about… | Put it in | Why |
|---|---|---|
| A single row's column value | `WHERE` | Filters before grouping — fewer rows to aggregate, index-usable |
| An aggregate (`COUNT`, `SUM`, `AVG`) | `HAVING` | The value does not exist until step 5 |
| A grouping-key column, and you want it to shrink the input | `WHERE` | Always faster |
| A grouping-key column, and you want the group to still appear with 0 | Neither — restructure with `LEFT JOIN` + conditional aggregation | See below |
| The outer table of a `LEFT JOIN` | `WHERE` | Fine |
| The inner table of a `LEFT JOIN` | `ON` (see Topic 06) | `WHERE` silently converts it to an `INNER JOIN` |

```sql
-- Projects with 4 or more OPEN tasks
SELECT p.ProjectCode, COUNT(*) AS OpenTasks
FROM app.Tasks           AS t
JOIN app.Projects        AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses    AS s ON s.StatusId  = t.StatusId
WHERE s.IsTerminal = 0                -- row filter: cheap, runs first
GROUP BY p.ProjectCode
HAVING COUNT(*) >= 4;                 -- group filter
```

| ProjectCode | OpenTasks |
|---|---|
| TF-CORE | 5 |
| TF-WEB | 4 |

Note what **disappeared**: `TF-MOB` has two tasks, both `CANCELLED`. The `WHERE` removed both rows, so the group never formed. If the business wants "0" for TF-MOB, you must not filter rows away — see §7.

> **Rule of thumb:** Push every non-aggregate predicate into `WHERE`. `HAVING` is for aggregates only. `HAVING t.PriorityId = 1` is legal but slower and misleading.

---

## 6. Conditional Aggregation — the Pivot Workhorse

`CASE` inside an aggregate lets you compute *several different filters in one pass* over the data. This is the single highest-leverage aggregation technique in SQL.

```sql
SELECT
    p.ProjectCode,
    COUNT(*)                                                         AS TotalTasks,
    SUM(CASE WHEN t.StatusId = 6 THEN 1 ELSE 0 END)                  AS Done,
    SUM(CASE WHEN t.StatusId = 7 THEN 1 ELSE 0 END)                  AS Cancelled,
    SUM(CASE WHEN t.StatusId IN (3, 4) THEN 1 ELSE 0 END)            AS InFlight,
    COUNT(CASE WHEN t.StatusId = 5 THEN 1 END)                       AS Blocked,
    SUM(CASE WHEN t.PriorityId = 1 THEN 1 ELSE 0 END)                AS Critical,
    CAST(100.0 * SUM(CASE WHEN t.StatusId = 6 THEN 1 ELSE 0 END)
         / COUNT(*) AS DECIMAL(5,2))                                 AS PctDone,
    AVG(CASE WHEN t.PriorityId <= 2
             THEN CAST(t.EstimatedHours AS DECIMAL(10,2)) END)       AS AvgHrsHighPri
FROM app.Tasks    AS t
JOIN app.Projects AS p ON p.ProjectId = t.ProjectId
GROUP BY p.ProjectCode
ORDER BY p.ProjectCode;
```

### The three idioms

| Idiom | Empty group returns | When to use |
|---|---|---|
| `SUM(CASE WHEN c THEN 1 ELSE 0 END)` | `0` | Counting — safest default |
| `COUNT(CASE WHEN c THEN 1 END)` | `0` | Counting — the `ELSE NULL` is implicit |
| `SUM(CASE WHEN c THEN x END)` | `NULL` | Summing a measure for a subset |
| `AVG(CASE WHEN c THEN x END)` | `NULL` | Averaging **only** matching rows (omit `ELSE 0`!) |

> **Anti-pattern:** `AVG(CASE WHEN c THEN x ELSE 0 END)`. The `ELSE 0` drags non-matching rows into the denominator and destroys the average. Leave the `ELSE` off so non-matches become NULL and are skipped.

### Filtering an aggregate without a subquery

```sql
-- Billable vs non-billable hours per user, single scan of app.TimeEntries
SELECT
    u.FullName,
    SUM(te.Hours)                                              AS AllHours,
    SUM(CASE WHEN te.IsBillable = 1 THEN te.Hours ELSE 0 END)  AS BillableHours,
    SUM(CASE WHEN te.IsBillable = 0 THEN te.Hours ELSE 0 END)  AS NonBillableHours
FROM app.TimeEntries AS te
JOIN app.Users       AS u ON u.UserId = te.UserId
GROUP BY u.FullName
HAVING SUM(CASE WHEN te.IsBillable = 0 THEN te.Hours ELSE 0 END) > 0;
```

Only Jean Bartik (3.00 non-billable on task 12) and Tim Berners-Lee (8.00 on task 28) survive the `HAVING`.

The naive alternative — two correlated subqueries, or two scans joined together — reads `app.TimeEntries` twice. Conditional aggregation reads it once.

> **Portability:** PostgreSQL has first-class syntax for this: `SUM(te.hours) FILTER (WHERE te.is_billable)`. T-SQL has no `FILTER`; `CASE` is the idiom.

---

## 7. Aggregating Over Joins — the Fan-Out Trap

This is the number one cause of "the dashboard says 42 hours but the timesheet says 21".

A join to a **one-to-many** child multiplies rows. Join to **two** independent children and you get a Cartesian product of the two child sets, *per parent row*.

```sql
-- WRONG. app.Tasks -> TaskAssignments (many) AND -> TimeEntries (many)
SELECT
    t.TaskId,
    COUNT(*)                        AS RowsAfterJoin,
    COUNT(DISTINCT ta.UserId)       AS Assignees,
    COUNT(DISTINCT te.TimeEntryId)  AS TimeEntries,
    SUM(te.Hours)                   AS Hours_WRONG
FROM app.Tasks           AS t
JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
JOIN app.TimeEntries     AS te ON te.TaskId = t.TaskId
WHERE t.TaskId IN (4, 10)
GROUP BY t.TaskId;
```

| TaskId | RowsAfterJoin | Assignees | TimeEntries | Hours_WRONG | Hours_TRUE |
|---|---|---|---|---|---|
| 4 | 6 | 2 | 3 | **42.00** | 21.00 |
| 10 | 6 | 2 | 3 | **43.00** | 21.50 |

Task 4 has 2 assignments (Ken, Dennis) and 3 time entries (8.00 + 7.00 + 6.00 = 21.00). `2 × 3 = 6` rows, so every hour is counted twice.

Notice that `COUNT(DISTINCT …)` gives the **right** answer for the counts — the duplicates dedupe away. But `SUM` cannot be rescued that way, because the duplicated values are genuinely equal.

### Fix 1 — pre-aggregate in derived tables (the general answer)

```sql
SELECT
    t.TaskId,
    t.Title,
    ISNULL(a.AssigneeCount, 0) AS Assignees,
    ISNULL(h.LoggedHours,  0)  AS LoggedHours
FROM app.Tasks AS t
LEFT JOIN (
    SELECT ta.TaskId, COUNT(*) AS AssigneeCount
    FROM app.TaskAssignments AS ta
    GROUP BY ta.TaskId
) AS a ON a.TaskId = t.TaskId
LEFT JOIN (
    SELECT te.TaskId, SUM(te.Hours) AS LoggedHours
    FROM app.TimeEntries AS te
    GROUP BY te.TaskId
) AS h ON h.TaskId = t.TaskId
WHERE t.TaskId IN (4, 10);
```

| TaskId | Title | Assignees | LoggedHours |
|---|---|---|---|
| 4 | Implement auth endpoints | 2 | 21.00 |
| 10 | Build task board component | 2 | 21.50 |

Each child is collapsed to one row per `TaskId` *before* the join, so no multiplication is possible. `LEFT JOIN` + `ISNULL` keeps tasks with no assignees and no time entries.

### Fix 2 — `COUNT(DISTINCT …)` (counts only)

Correct and concise when *every* measure you need is a count of a key. Useless for `SUM`/`AVG`.

### Fix 3 — scalar subqueries in the `SELECT` list

```sql
SELECT t.TaskId,
       (SELECT COUNT(*) FROM app.TaskAssignments ta WHERE ta.TaskId = t.TaskId) AS Assignees,
       (SELECT ISNULL(SUM(te.Hours), 0) FROM app.TimeEntries te WHERE te.TaskId = t.TaskId) AS Hours
FROM app.Tasks AS t
WHERE t.TaskId IN (4, 10);
```

Readable, and SQL Server usually decorrelates it into the same plan as Fix 1. Prefer Fix 1 when you need many measures from the same child.

> **Anti-pattern:** "Correcting" the fan-out with `SUM(te.Hours) / COUNT(DISTINCT ta.UserId)`. It happens to give 21.00 for task 4 and breaks the moment one assignee has no time entries, or a third child table joins in.

### Duplicate-row smell test

If `COUNT(*)` in your grouped query is larger than the row count of the driving table, you have a fan-out. Check it explicitly:

```sql
SELECT COUNT(*) AS RowsAfterJoin       -- 38
FROM app.Tasks           AS t
JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
JOIN app.TimeEntries     AS te ON te.TaskId = t.TaskId;
```

Only 16 tasks have any time entries at all, yet the join emits 38 rows. Any time the row count exceeds one per task, the grain has changed and every `SUM` downstream is inflated.

---

## 8. Subtotals: `ROLLUP`, `CUBE`, `GROUPING SETS`

These extensions produce **multiple grouping levels in one pass**, which is far cheaper than `UNION ALL`-ing three separate queries.

| Extension | Groupings produced for `(A, B)` | Row count on TaskFlow* |
|---|---|---|
| `GROUP BY A, B` | `(A,B)` | 25 |
| `GROUP BY ROLLUP (A, B)` | `(A,B)`, `(A)`, `()` — a **hierarchy** | 25 + 8 + 1 = **34** |
| `GROUP BY CUBE (A, B)` | `(A,B)`, `(A)`, `(B)`, `()` — **all combinations** | 25 + 8 + 7 + 1 = **41** |
| `GROUP BY GROUPING SETS ((A,B), (B))` | Exactly what you list | 25 + 7 = **32** |

\* with `A = p.ProjectCode` (8 values), `B = s.StatusCode` (7 values), 25 real combinations.

```sql
SELECT
    p.ProjectCode,
    s.StatusCode,
    COUNT(*) AS Tasks
FROM app.Tasks        AS t
JOIN app.Projects     AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses AS s ON s.StatusId  = t.StatusId
GROUP BY ROLLUP (p.ProjectCode, s.StatusCode)
ORDER BY
    GROUPING(p.ProjectCode), p.ProjectCode,
    GROUPING(s.StatusCode),  s.StatusCode;
```

`ROLLUP` is **order-sensitive** — `ROLLUP (A, B)` gives subtotals per `A`, not per `B`. `CUBE` is order-insensitive. `GROUPING SETS` is the explicit, no-surprises form and can express both:

```sql
GROUP BY GROUPING SETS ( (p.ProjectCode, s.StatusCode), (p.ProjectCode), () )  -- = ROLLUP(A,B)
GROUP BY GROUPING SETS ( (p.ProjectCode, s.StatusCode), (p.ProjectCode),
                         (s.StatusCode), () )                                  -- = CUBE(A,B)
```

### `GROUPING()` — real NULL or subtotal NULL?

Super-aggregate rows put `NULL` in the columns they rolled up. If the column *also* contains real NULLs you cannot tell them apart. `GROUPING(col)` returns `1` for a subtotal placeholder and `0` for a real value (including a real NULL).

`app.Users.JobTitle` is NULL for exactly one user (Sophie Wilson), which makes this concrete:

```sql
SELECT
    CASE
        WHEN GROUPING(u.JobTitle) = 1 THEN N'*** ALL TITLES ***'
        WHEN u.JobTitle IS NULL       THEN N'(no title on record)'
        ELSE u.JobTitle
    END                    AS JobTitleLabel,
    GROUPING(u.JobTitle)   AS IsSubtotalRow,
    COUNT(*)               AS Headcount
FROM app.Users AS u
GROUP BY ROLLUP (u.JobTitle)
ORDER BY GROUPING(u.JobTitle), u.JobTitle;
```

Two of the 14 rows:

| JobTitleLabel | IsSubtotalRow | Headcount |
|---|---|---|
| `(no title on record)` | 0 | 1 |
| `*** ALL TITLES ***` | 1 | 20 |

Without `GROUPING()`, `ISNULL(u.JobTitle, N'(none)')` would label **both** rows `(none)` and a reader would think one person is the whole company.

### `GROUPING_ID()` — the bitmask

`GROUPING_ID(A, B)` packs the `GROUPING()` bits into one integer, most-significant bit first.

| `GROUPING_ID(ProjectCode, StatusCode)` | Bits | Meaning |
|---|---|---|
| `0` | `00` | Detail row — grouped by both |
| `1` | `01` | Subtotal per project (status rolled up) |
| `2` | `10` | Subtotal per status (project rolled up) |
| `3` | `11` | Grand total |

```sql
SELECT
    GROUPING_ID(p.ProjectCode, s.StatusCode) AS Lvl,
    p.ProjectCode, s.StatusCode, COUNT(*) AS Tasks
FROM app.Tasks        AS t
JOIN app.Projects     AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses AS s ON s.StatusId  = t.StatusId
GROUP BY CUBE (p.ProjectCode, s.StatusCode)
ORDER BY Lvl, p.ProjectCode, s.StatusCode;
```

`Lvl` is the perfect column to `ORDER BY` and to switch formatting on in the application layer.

### Portability

| Feature | SQL Server | PostgreSQL | MySQL | Oracle |
|---|---|---|---|---|
| `ROLLUP` | Yes | Yes | `GROUP BY … WITH ROLLUP` only | Yes |
| `CUBE` | Yes | Yes | No | Yes |
| `GROUPING SETS` | Yes | Yes | No | Yes |
| `GROUPING()` | Yes | Yes | Yes | Yes |
| `GROUPING_ID()` | Yes | `GROUPING(a,b)` returns the bitmask | No | Yes |
| Legacy `WITH ROLLUP` | Deprecated | — | Current syntax | — |

> **Anti-pattern:** The old `GROUP BY a, b WITH ROLLUP` / `WITH CUBE` T-SQL syntax. It is deprecated, cannot express `GROUPING SETS`, and behaves differently under some compatibility levels. Use `GROUP BY ROLLUP (a, b)`.

---

## 9. `GROUP BY ALL` — a Historical Footnote

`GROUP BY ALL` was a T-SQL extension that returned **every group, including groups eliminated by `WHERE`**, with `NULL` in the aggregate columns for the empty ones.

```sql
-- Legacy, do not write this
SELECT t.StatusId, COUNT(*) AS Cnt
FROM app.Tasks AS t
WHERE t.PriorityId = 1
GROUP BY ALL t.StatusId;
```

It has been on the deprecation list since SQL Server 2008, it is incompatible with `ROLLUP`/`CUBE`/`GROUPING SETS`, and it is not something to rely on in Azure SQL or any modern compatibility level. The modern replacement is a `LEFT JOIN` from the dimension plus conditional aggregation:

```sql
SELECT
    s.StatusCode,
    COUNT(CASE WHEN t.PriorityId = 1 THEN 1 END) AS CriticalTasks
FROM ref.TaskStatuses AS s
LEFT JOIN app.Tasks   AS t ON t.StatusId = s.StatusId
GROUP BY s.StatusCode
ORDER BY s.StatusCode;
```

This returns all 7 statuses with `0` where there are no Critical tasks — which is what the report actually wanted.

> **Name collision warning:** Snowflake, Databricks, and DuckDB have introduced a *different* `GROUP BY ALL` that means "group by every non-aggregated column in the `SELECT` list". Same keywords, unrelated semantics. Do not carry the habit into T-SQL.

---

## 10. `DISTINCT` vs `GROUP BY`

For deduplication alone, they are equivalent and usually produce the identical plan:

```sql
SELECT DISTINCT t.ProjectId FROM app.Tasks AS t;          -- 8 rows
SELECT t.ProjectId FROM app.Tasks AS t GROUP BY t.ProjectId; -- 8 rows, same plan
```

| Use | Prefer |
|---|---|
| Remove duplicate rows, no aggregates | `DISTINCT` — states intent |
| Compute an aggregate per key | `GROUP BY` — `DISTINCT` cannot do it |
| Remove duplicates *and* aggregate | `GROUP BY` |
| Dedupe inside an aggregate | `COUNT(DISTINCT col)` |

> **Anti-pattern:** `SELECT DISTINCT` sprinkled on a query to hide duplicate rows caused by a join. `DISTINCT` is not a bug fix — it masks a fan-out (§7) and adds a sort or hash to every execution. Find the extra join and pre-aggregate it instead.

Note that `DISTINCT` applies to the **whole select list**, not the first column. `SELECT DISTINCT t.ProjectId, t.StatusId` returns 25 rows, not 8.

---

## 11. Performance: How SQL Server Actually Groups

Two physical operators implement aggregation.

| | **Stream Aggregate** | **Hash Match (Aggregate)** |
|---|---|---|
| Requires input sorted by grouping keys | **Yes** | No |
| Memory grant | Negligible | Proportional to distinct groups |
| Can spill to tempdb | Only via its feeding `Sort` | Yes — watch for spill warnings |
| Blocking | No (streams as it goes) | Build phase blocks |
| Parallel-friendly | Yes, but often needs a repartition | Yes — local/global aggregation |
| Optimizer picks it when | An index already supplies the order, or few groups | Many rows, no useful index, or many distinct groups |
| Always used for | Scalar aggregates (no `GROUP BY`) | — |

If no index supplies the order, the optimizer either inserts a **Sort** before a Stream Aggregate (`O(n log n)`, memory grant, potential tempdb spill) or picks **Hash Match**. On large tables, an unexpected `Sort` in front of a Stream Aggregate is one of the most common tuning finds.

### Indexes that help grouping

```sql
-- Grouping key first, measures INCLUDEd => index scan feeds Stream Aggregate, no Sort
CREATE INDEX IX_Tasks_Project_Status_Incl
    ON app.Tasks (ProjectId, StatusId)
    INCLUDE (EstimatedHours, StoryPoints);
```

Guidelines:

- The **leading columns** of the index must match the `GROUP BY` list (order matters for a Stream Aggregate, not for a Hash Aggregate).
- Add a `WHERE`-clause column *before* the grouping keys if it is highly selective; the seek shrinks the input.
- `INCLUDE` the aggregated measures to make the index covering — otherwise every group costs key lookups.
- For wide fact-style aggregation over millions of rows, a **clustered columnstore index** enables batch-mode aggregation and is usually an order of magnitude faster than any rowstore plan.
- An **indexed view** with `COUNT_BIG(*)` materialises the aggregate; SQL Server maintains it on write. `COUNT_BIG(*)` is mandatory — `COUNT(*)` is rejected.

### Cheap wins

| Symptom | Fix |
|---|---|
| `Sort` operator with a spill warning before `Stream Aggregate` | Index on the `GROUP BY` columns, or accept `Hash Match` |
| `COUNT(DISTINCT x)` is slow | It forces an extra distinct/sort step. Consider `APPROX_COUNT_DISTINCT` if ±2 % is acceptable |
| Grouping by `CONVERT(VARCHAR, dt, 112)` | Group by `CAST(dt AS DATE)` or a persisted computed column |
| Aggregating then filtering with `HAVING` on a non-aggregate | Move it to `WHERE` |
| Reading the child table twice for two measures | One pass with conditional aggregation |

`COUNT(DISTINCT …)` also cannot be used as a window function in T-SQL — `COUNT(DISTINCT x) OVER (…)` is a syntax error. Pre-aggregate in a CTE (Topic 07) or use `DENSE_RANK` tricks (Topic 09).

---

## 12. A Complete TaskFlow Aggregation

Everything above, in one production-shaped query: per-project health with correct hours, no fan-out, subtotal-safe labels, and zero-safe measures.

```sql
WITH TaskHours AS (          -- collapse the child to one row per task FIRST
    SELECT te.TaskId,
           SUM(te.Hours)                                          AS LoggedHours,
           SUM(CASE WHEN te.IsBillable = 1 THEN te.Hours ELSE 0 END) AS BillableHours
    FROM app.TimeEntries AS te
    GROUP BY te.TaskId
),
TaskAssignees AS (
    SELECT ta.TaskId, COUNT(*) AS AssigneeCount
    FROM app.TaskAssignments AS ta
    GROUP BY ta.TaskId
)
SELECT
    p.ProjectCode,
    COUNT(*)                                                      AS TotalTasks,
    SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END)             AS ClosedTasks,
    SUM(CASE WHEN a.AssigneeCount IS NULL THEN 1 ELSE 0 END)      AS UnassignedTasks,
    ISNULL(SUM(t.EstimatedHours), 0)                              AS EstimatedHours,
    ISNULL(SUM(h.LoggedHours), 0)                                 AS LoggedHours,
    ISNULL(SUM(h.BillableHours), 0)                               AS BillableHours,
    AVG(CAST(t.StoryPoints AS DECIMAL(10,2)))                     AS AvgStoryPoints,
    CAST(100.0 * SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END)
         / COUNT(*) AS DECIMAL(5,2))                              AS PctClosed
FROM app.Tasks         AS t
JOIN app.Projects      AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses  AS s ON s.StatusId  = t.StatusId
LEFT JOIN TaskHours    AS h ON h.TaskId    = t.TaskId
LEFT JOIN TaskAssignees AS a ON a.TaskId   = t.TaskId
GROUP BY p.ProjectCode
ORDER BY p.ProjectCode;
```

Checks you can run against the seed data: `SUM(TotalTasks) = 35`, `SUM(LoggedHours) = 160.00`, `SUM(BillableHours) = 149.00`, `SUM(UnassignedTasks) = 8`, `SUM(ClosedTasks) = 13`.

---

## Mental Model

> A `GROUP BY` query is a **funnel with a fixed grain**. Decide the grain first — "one row per project", "one row per project per status" — then ask three questions before you write anything else. **(1) Did a join change the grain?** If a child table can produce more than one row per parent, pre-aggregate it in a derived table before you join. **(2) Is the column nullable?** Everything except `COUNT(*)` silently drops NULLs, and `GROUP BY` silently merges them into one bucket. **(3) Is the column an integer?** Then `AVG` truncates. `WHERE` filters rows before the funnel; `HAVING` filters buckets after it; if you need a bucket that has no rows, you must drive from the dimension with a `LEFT JOIN` and count with `CASE`, because a group that never formed can never be filtered back in.

Move to [Practice Problems](./Practice-Problems.md).
