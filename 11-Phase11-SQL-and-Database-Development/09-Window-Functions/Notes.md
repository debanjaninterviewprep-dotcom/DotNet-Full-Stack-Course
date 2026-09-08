# Topic 09: Window Functions

> Every screen in **TaskFlow** asks a question that `GROUP BY` cannot answer: *show me each task **and** its share of the project's estimate*; *show me the burn-down **and** yesterday's number beside it*; *show me the three newest tasks **per** project*; *show me each engineer's running billable total*. All of these need a value computed over a **set of rows** while still returning the **individual rows**. That is exactly what a window function does — it aggregates without collapsing. This topic covers the `OVER()` clause end to end: ranking, aggregate, offset and distribution functions, frames and the default-frame trap, the recipes that turn up in every reporting sprint, and the plan operators that decide whether any of it is fast.

---

## 1. The Core Idea: Aggregate Without Collapsing

`GROUP BY` **reduces** the result set. A window function **decorates** it.

```sql
USE TaskFlowDb;
GO

-- GROUP BY: 8 rows out of 35 in. The task-level detail is gone.
SELECT t.ProjectId, SUM(t.EstimatedHours) AS ProjectHours
FROM app.Tasks AS t
GROUP BY t.ProjectId;

-- OVER(): 35 rows out of 35 in. Every task still there, plus its project total.
SELECT t.TaskId, t.ProjectId, t.EstimatedHours,
       SUM(t.EstimatedHours) OVER (PARTITION BY t.ProjectId) AS ProjectHours
FROM app.Tasks AS t;
```

| | `GROUP BY` | `OVER()` |
|---|---|---|
| Rows returned | One per group (8) | One per input row (35) |
| Detail columns | Only grouping keys and aggregates | Anything |
| Evaluated at | Logical step 5 | Logical step 5.5 — **after** `GROUP BY`/`HAVING`, before `DISTINCT`/`ORDER BY` |
| Can be filtered in `WHERE`/`HAVING` | Yes | **No** — see §3 |
| Multiple different groupings in one query | No (needs `GROUPING SETS`) | Yes — one `OVER()` per column |

The last row is the one people underestimate. A single `SELECT` can carry a project total, a status total and a grand total side by side, because each `OVER()` is an independent window: `SUM(t.EstimatedHours) OVER (PARTITION BY t.ProjectId)`, `… OVER (PARTITION BY t.StatusId)` and `… OVER ()` (538.00) in one query, no self-joins.

---

## 2. Anatomy of `OVER()`

```
<function>( <args> ) OVER (
      [ PARTITION BY <expr> [, ...] ]     -- reset the window at every change
      [ ORDER BY <expr> [ASC|DESC] ... ]  -- give the window a direction
      [ <ROWS|RANGE> <frame> ]            -- narrow the window inside the partition
)
```

| Clause | Meaning | Omitted ⇒ |
|---|---|---|
| `PARTITION BY` | Splits rows into independent windows | One window over the whole result set |
| `ORDER BY` | Orders rows **within** the partition; required by ranking and offset functions | No order, therefore no frame; aggregates see the whole partition |
| Frame (`ROWS`/`RANGE`) | Which rows around the current row are in scope | `RANGE UNBOUNDED PRECEDING AND CURRENT ROW` **if `ORDER BY` is present**; whole partition if not |

Three critical clarifications: the `ORDER BY` inside `OVER()` has **nothing to do** with the query's final `ORDER BY` — it orders the computation, not the output; `PARTITION BY` is not `GROUP BY`, because it neither reduces rows nor constrains what you may select; and a frame is legal only when `ORDER BY` is present, and only on aggregate and `FIRST_VALUE`/`LAST_VALUE`/`NTH_VALUE` functions — never on `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE`, `LAG` or `LEAD`.

---

## 3. Where Window Functions Are Legal

Window functions are evaluated **after** `FROM`, `WHERE`, `GROUP BY` and `HAVING`. They are therefore legal in exactly two places: the `SELECT` list and the query's `ORDER BY`.

```sql
-- Msg 4108: Windowed functions can only appear in the SELECT or ORDER BY clauses.
SELECT t.TaskId
FROM app.Tasks AS t
WHERE ROW_NUMBER() OVER (PARTITION BY t.ProjectId ORDER BY t.TaskId) <= 2;
```

The consequence is the single most repeated pattern in this topic: **to filter on a window function, compute it in a CTE or derived table and filter in the outer query.**

```sql
WITH Ranked AS (
    SELECT t.TaskId, t.ProjectId, t.Title, t.CreatedAtUtc,
           ROW_NUMBER() OVER (PARTITION BY t.ProjectId
                              ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC) AS rn
    FROM app.Tasks AS t
)
SELECT r.ProjectId, r.TaskId, r.Title
FROM Ranked AS r
WHERE r.rn <= 2;          -- 16 rows: 8 projects x 2
```

Because they run after `HAVING`, a window function may take a **grouped** aggregate as its argument. `SUM(SUM(x)) OVER ()` is not a typo — the inner `SUM` aggregates within the group, the outer one windows across the groups:

```sql
SELECT
    t.ProjectId,
    SUM(t.EstimatedHours)                                                    AS ProjectHours,
    SUM(SUM(t.EstimatedHours)) OVER ()                                       AS AllHours,
    CAST(100.0 * SUM(t.EstimatedHours)
              / SUM(SUM(t.EstimatedHours)) OVER () AS DECIMAL(5,2))          AS PctOfTotal
FROM app.Tasks AS t
GROUP BY t.ProjectId;
```

| ProjectId | ProjectHours | AllHours | PctOfTotal |
|---|---|---|---|
| 1 | 140.00 | 538.00 | 26.02 |
| 2 | 104.00 | 538.00 | 19.33 |
| 3 | 62.00 | 538.00 | 11.52 |
| 4 | 64.00 | 538.00 | 11.90 |
| 5 | 34.00 | 538.00 | 6.32 |
| 6 | 20.00 | 538.00 | 3.72 |
| 7 | 84.00 | 538.00 | 15.61 |
| 8 | 30.00 | 538.00 | 5.58 |

> **Rule of thumb:** If you find yourself wanting a window function in `WHERE`, you want a CTE. If you find yourself wanting one in `GROUP BY`, you want two levels of query.

---

## 4. Ranking Functions

Four functions, one `ORDER BY`, four different answers on ties.

| Function | Ties get | Sequence has gaps | Needs `ORDER BY` | Frame allowed |
|---|---|---|---|---|
| `ROW_NUMBER()` | Different numbers (arbitrary order) | No | Yes | No |
| `RANK()` | The same number | **Yes** — skips to `n + tied` | Yes | No |
| `DENSE_RANK()` | The same number | No | Yes | No |
| `NTILE(n)` | May land in different buckets | n/a | Yes | No |

Worked side by side on project 1, ordered by estimate descending. Tasks 34 and 6 are both estimated at 8.00 hours, and task 8 has no estimate at all:

```sql
SELECT
    t.TaskId,
    t.EstimatedHours,
    ROW_NUMBER() OVER (ORDER BY t.EstimatedHours DESC) AS RN,
    RANK()       OVER (ORDER BY t.EstimatedHours DESC) AS RNK,
    DENSE_RANK() OVER (ORDER BY t.EstimatedHours DESC) AS DRNK,
    NTILE(3)     OVER (ORDER BY t.EstimatedHours DESC) AS NT3
FROM app.Tasks AS t
WHERE t.ProjectId = 1
ORDER BY RN;
```

| TaskId | EstimatedHours | RN | RNK | DRNK | NT3 |
|---|---|---|---|---|---|
| 7 | 40.00 | 1 | 1 | 1 | 1 |
| 4 | 32.00 | 2 | 2 | 2 | 1 |
| 1 | 24.00 | 3 | 3 | 3 | 1 |
| 5 | 12.00 | 4 | 4 | 4 | 2 |
| 3 | 10.00 | 5 | 5 | 5 | 2 |
| 34 | **8.00** | 6 | **6** | **6** | 2 |
| 6 | **8.00** | 7 | **6** | **6** | **3** |
| 2 | 6.00 | 8 | **8** | 7 | 3 |
| 8 | NULL | 9 | 9 | 8 | 3 |

Read the tied pair carefully — it contains four separate lessons:

- `ROW_NUMBER` gave 6 and 7. **Which task got which is arbitrary** and may change between executions, index choices or service packs. `ROW_NUMBER` over a non-unique `ORDER BY` is non-deterministic.
- `RANK` gave both 6 and then jumped to 8. The gap is the point: it answers "how many rows are strictly ahead of me".
- `DENSE_RANK` gave both 6 and then 7. It answers "how many distinct values are ahead of me". Use it for "the top 3 *estimate sizes*", not "the top 3 tasks".
- `NTILE(3)` split the tie across buckets 2 and 3. **`NTILE` divides by row count, not by value**, so equal values can land in different quantiles. It is fine for "split this queue across three workers" and wrong for "assign a grade band".

NULL handling: SQL Server sorts NULLs **first** ascending, **last** descending, and treats all NULLs as equal for ranking purposes — hence task 8's single rank at the bottom.

> **Rule of thumb:** Always make the window `ORDER BY` deterministic by appending a unique tie-breaker (`, t.TaskId`). The moment a `ROW_NUMBER` result is used to delete, page or pick a winner, non-determinism becomes a data-loss bug.

> **Portability:** All four are ANSI SQL and present in PostgreSQL, Oracle, MySQL 8.0+ and MariaDB 10.2+.

---

## 5. Aggregate Window Functions

`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`, `STDEV`, `VAR` and `STRING_AGG` all accept `OVER()`.

### Percent of partition

```sql
SELECT
    t.TaskId, t.EstimatedHours,
    SUM(t.EstimatedHours) OVER (PARTITION BY t.ProjectId) AS ProjectHours,
    CAST(100.0 * t.EstimatedHours
         / SUM(t.EstimatedHours) OVER (PARTITION BY t.ProjectId) AS DECIMAL(5,1)) AS PctOfProject
FROM app.Tasks AS t
WHERE t.ProjectId = 4;
```

| TaskId | EstimatedHours | ProjectHours | PctOfProject |
|---|---|---|---|
| 19 | 16.00 | 64.00 | 25.0 |
| 20 | 18.00 | 64.00 | 28.1 |
| 21 | 6.00 | 64.00 | 9.4 |
| 22 | 24.00 | 64.00 | 37.5 |

Note `100.0 *` — integer division would return 0. The same trap as Topic 05.

### `COUNT(*)` versus `COUNT(col)`

Exactly as in `GROUP BY`: `COUNT(*)` counts rows, `COUNT(col)` counts non-NULL values, and `AVG` ignores NULLs entirely.

```sql
SELECT DISTINCT
    t.ProjectId,
    COUNT(*)                OVER (PARTITION BY t.ProjectId) AS Tasks_,
    COUNT(t.EstimatedHours) OVER (PARTITION BY t.ProjectId) AS Estimated_,
    AVG(t.EstimatedHours)   OVER (PARTITION BY t.ProjectId) AS AvgEstimate
FROM app.Tasks AS t
WHERE t.ProjectId IN (1, 3);
```

Project 1: 9 tasks, 8 estimated, average 17.500000 — the average divides by 8, not 9. Project 3: 4 tasks, 3 estimated, average 20.666666.

### Running total

Add `ORDER BY` and a frame, and the aggregate becomes cumulative:

```sql
SELECT
    te.WorkDate, te.Hours,
    SUM(te.Hours) OVER (PARTITION BY te.TaskId ORDER BY te.WorkDate
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningHours
FROM app.TimeEntries AS te
WHERE te.TaskId = 1;
```

Task 1's three entries run 6.00 → 13.50 → 18.75. A **moving** average is the same construct with a bounded frame: `AVG(te.Hours) OVER (ORDER BY te.WorkDate ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)`.

`COUNT(DISTINCT x) OVER (…)` is **not supported** (Msg 10759). Work around it with `DENSE_RANK` forwards + backwards − 1, or pre-aggregate in a CTE.

---

## 6. Frames: `ROWS`, `RANGE`, and the Default-Frame Trap

A frame narrows the window *inside* the partition, relative to the current row.

```
{ROWS | RANGE} BETWEEN <start> AND <end>
   <start> : UNBOUNDED PRECEDING | n PRECEDING | CURRENT ROW | n FOLLOWING
   <end>   : n PRECEDING | CURRENT ROW | n FOLLOWING | UNBOUNDED FOLLOWING
```

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` may be shortened to `ROWS UNBOUNDED PRECEDING`.

| | `ROWS` | `RANGE` |
|---|---|---|
| Counts | Physical rows | **Values** of the `ORDER BY` expression |
| Peers (tied rows) | Treated separately | Always included together |
| Offsets (`n PRECEDING`) | Supported | **Not supported in SQL Server** (Msg 4194) |
| Implementation | Fast in-memory spool when the frame is < 10 000 rows | Always an on-disk worktable in tempdb |
| Deterministic on ties | No — depends on row order | Yes |

### The default-frame trap

**If you write `ORDER BY` inside `OVER()` and omit the frame, you get `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`** — not `ROWS`. With unique ordering values the two are identical, which is exactly why the bug survives testing. Introduce a tie and they diverge:

```sql
SELECT
    t.TaskId, t.EstimatedHours,
    SUM(t.EstimatedHours) OVER (ORDER BY t.EstimatedHours DESC)                          AS RangeDefault,
    SUM(t.EstimatedHours) OVER (ORDER BY t.EstimatedHours DESC ROWS UNBOUNDED PRECEDING) AS RowsRunning
FROM app.Tasks AS t
WHERE t.ProjectId = 1
ORDER BY t.EstimatedHours DESC;
```

| TaskId | EstimatedHours | RangeDefault | RowsRunning |
|---|---|---|---|
| 7 | 40.00 | 40.00 | 40.00 |
| 4 | 32.00 | 72.00 | 72.00 |
| 1 | 24.00 | 96.00 | 96.00 |
| 5 | 12.00 | 108.00 | 108.00 |
| 3 | 10.00 | 118.00 | 118.00 |
| 34 | 8.00 | **134.00** | **126.00** |
| 6 | 8.00 | 134.00 | 134.00 |
| 2 | 6.00 | 140.00 | 140.00 |
| 8 | NULL | 140.00 | 140.00 |

`RANGE` gave task 34 a running total of 134.00 — it already includes task 6, because they are *peers* on the ordering value. A running-balance report built this way shows money that has not been spent yet. `ROWS` gives the intuitive 126.00.

> **Anti-pattern:** `SUM(x) OVER (ORDER BY d)` with no frame. It is correct only while `d` is unique, it silently changes meaning the day a duplicate arrives, and it is measurably slower. Write `ROWS UNBOUNDED PRECEDING` every time — even when you believe the ordering column is unique.

> **Rule of thumb:** `RANGE` is the right choice in exactly one situation — when you *want* tied rows to share a value, e.g. a cumulative distribution where every task with the same story-point total must report the same percentile. Everywhere else, `ROWS`.

Frame quick reference:

| Requirement | Frame |
|---|---|
| Running total | `ROWS UNBOUNDED PRECEDING` |
| Whole partition (e.g. `LAST_VALUE`) | `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |
| Trailing 7 rows including current | `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` |
| Centred 3-point average | `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` |
| Everything still to come | `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING` |

> **Portability:** PostgreSQL, Oracle and MySQL 8.0.2+ all support `RANGE` with numeric and `INTERVAL` offsets (`RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW`). SQL Server does not — emulate a time-based frame with a join or `APPLY`.

---

## 7. Offset Functions

| Function | Returns | Frame-aware |
|---|---|---|
| `LAG(expr, offset, default)` | Value from *offset* rows earlier in the partition | No |
| `LEAD(expr, offset, default)` | Value from *offset* rows later | No |
| `FIRST_VALUE(expr)` | First value **in the frame** | **Yes** |
| `LAST_VALUE(expr)` | Last value **in the frame** | **Yes** |

`offset` defaults to 1 and `default` to NULL. Supplying a default removes a layer of `ISNULL` from the caller:

```sql
SELECT
    te.WorkDate, te.Hours,
    LAG(te.Hours)     OVER (PARTITION BY te.UserId ORDER BY te.WorkDate) AS PrevHours,
    LEAD(te.WorkDate) OVER (PARTITION BY te.UserId ORDER BY te.WorkDate) AS NextDate,
    DATEDIFF(DAY, LAG(te.WorkDate) OVER (PARTITION BY te.UserId ORDER BY te.WorkDate),
                  te.WorkDate)                                           AS DaysSincePrev
FROM app.TimeEntries AS te
WHERE te.UserId = 7
ORDER BY te.WorkDate;
```

| WorkDate | Hours | PrevHours | NextDate | DaysSincePrev |
|---|---|---|---|---|
| 2024-02-12 | 3.00 | NULL | 2024-02-13 | NULL |
| 2024-02-13 | 2.75 | 3.00 | 2024-03-11 | 1 |
| 2024-03-11 | 8.00 | 2.75 | 2024-03-12 | 27 |
| 2024-03-12 | 7.00 | 8.00 | NULL | 1 |

### `LAST_VALUE` almost never does what you expect

Because `LAST_VALUE` is frame-aware and the default frame ends at `CURRENT ROW`, "the last value" means "the value on this row".

```sql
SELECT
    t.TaskId, t.CreatedAtUtc,
    FIRST_VALUE(t.TaskId) OVER (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc) AS FirstTask,
    LAST_VALUE(t.TaskId)  OVER (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc) AS LastTask_Broken,
    LAST_VALUE(t.TaskId)  OVER (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc
                                ROWS BETWEEN UNBOUNDED PRECEDING
                                         AND UNBOUNDED FOLLOWING)                 AS LastTask_Fixed
FROM app.Tasks AS t
WHERE t.ProjectId = 2
ORDER BY t.CreatedAtUtc;
```

| TaskId | CreatedAtUtc | FirstTask | LastTask_Broken | LastTask_Fixed |
|---|---|---|---|---|
| 9 | 2024-02-20 09:00 | 9 | **9** | 35 |
| 10 | 2024-04-01 09:00 | 9 | **10** | 35 |
| 11 | 2024-04-02 09:00 | 9 | **11** | 35 |
| 12 | 2024-04-02 09:05 | 9 | **12** | 35 |
| 35 | 2025-08-05 09:00 | 9 | 35 | 35 |

(Tasks 13 and 14 elided; they follow the same pattern.) `LastTask_Broken` just echoes `TaskId`. `FIRST_VALUE` looks correct only by luck — the default frame happens to start at `UNBOUNDED PRECEDING`.

> **Rule of thumb:** Never write `LAST_VALUE` without an explicit frame. The alternative that avoids the trap entirely is `FIRST_VALUE(x) OVER (… ORDER BY … DESC)`.

---

## 8. Distribution Functions and Percentiles

| Function | Formula / meaning | Range |
|---|---|---|
| `PERCENT_RANK()` | `(RANK() - 1) / (rows - 1)` | 0 … 1, always starts at 0 |
| `CUME_DIST()` | `rows ≤ current value / total rows` | > 0 … 1, never 0 |
| `PERCENTILE_CONT(p)` | Interpolated value at percentile *p* | May not exist in the data |
| `PERCENTILE_DISC(p)` | Actual data value at or beyond percentile *p* | Always an existing value |

```sql
SELECT u.UserId, u.FullName, u.HourlyRate,
       CAST(PERCENT_RANK() OVER (ORDER BY u.HourlyRate) AS DECIMAL(5,3)) AS PctRank,
       CAST(CUME_DIST()    OVER (ORDER BY u.HourlyRate) AS DECIMAL(5,3)) AS CumeDist
FROM app.Users AS u
WHERE u.HourlyRate IS NOT NULL;
```

The 19 rated users produce `PERCENT_RANK` 0.000 for Hedy Lamarr (64.00) and 1.000 for Ada Lovelace (180.00); `CUME_DIST` gives 0.053 and 1.000. Ken Thompson and Dennis Ritchie both at 95.00 share `PctRank` 0.389 and `CumeDist` 0.474 — proof that both are peer-aware.

`PERCENTILE_CONT`/`PERCENTILE_DISC` use a different syntax — the ordering moves into `WITHIN GROUP`, and `OVER()` may contain **only** `PARTITION BY`:

```sql
SELECT DISTINCT
    tm.Department,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY u.HourlyRate) OVER (PARTITION BY tm.Department) AS MedianCont,
    PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY u.HourlyRate) OVER (PARTITION BY tm.Department) AS MedianDisc
FROM app.TeamMembers AS m
JOIN app.Teams       AS tm ON tm.TeamId = m.TeamId
JOIN app.Users       AS u  ON u.UserId  = m.UserId;
-- Engineering  95.0 / 95.00      R&D  140.0 / 140.00
```

Only two departments appear: `Product` owns exactly one team (`Design System`), which has no members. Two quirks worth knowing — these are the only window functions with no `GROUP BY` equivalent, hence the `SELECT DISTINCT`; and they are the only ones where an even-sized set makes `CONT` and `DISC` differ (`CONT` averages the two middle values, `DISC` picks one that really exists).

---

## 9. The `WINDOW` Clause (SQL Server 2022+)

Repeating a long `OVER()` five times is a copy-paste bug waiting to happen. Name it once:

```sql
SELECT
    te.TaskId, te.WorkDate, te.Hours,
    SUM(te.Hours) OVER w AS RunningHours,
    COUNT(*)      OVER w AS EntryNo,
    MAX(te.Hours) OVER w AS PeakSoFar
FROM app.TimeEntries AS te
WHERE te.TaskId IN (1, 4)
WINDOW w AS (PARTITION BY te.TaskId ORDER BY te.WorkDate ROWS UNBOUNDED PRECEDING)
ORDER BY te.TaskId, te.WorkDate;
```

The `WINDOW` clause sits between `HAVING` and `ORDER BY`. A named window can also be extended: `OVER (w ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)` inherits `w`'s partitioning and ordering and overrides only the frame.

Requires SQL Server 2022 / Azure SQL and database compatibility level 160 or higher. PostgreSQL, Oracle and MySQL 8.0 have had it for years; on SQL Server 2019 and earlier, repeat the `OVER()` or hide it in a CTE.

---

## 10. Classic Recipes

### Top-N per group

```sql
WITH Ranked AS (
    SELECT t.TaskId, t.ProjectId, t.Title,
           ROW_NUMBER() OVER (PARTITION BY t.ProjectId
                              ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC) AS rn
    FROM app.Tasks AS t
)
SELECT r.ProjectId, r.TaskId, r.Title FROM Ranked AS r WHERE r.rn <= 2;   -- 16 rows
```

Swap `ROW_NUMBER` for `RANK` if you want to keep ties; `DENSE_RANK` if "top 2 *values*" is the requirement.

### Deduplication

The canonical way to delete duplicates without a surrogate key. Note you can `DELETE FROM` the **CTE name** directly:

```sql
WITH D AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY i.ProjectCode, i.Title
                              ORDER BY i.LoadedAtUtc DESC) AS rn
    FROM #TaskImport AS i
)
DELETE FROM D WHERE rn > 1;      -- keeps the most recent row of each group
```

Run it as a `SELECT` first. `PARTITION BY` lists the columns that define "duplicate"; `ORDER BY` decides the survivor.

### Gaps and islands

The classic trick: for a dense sequence, `value − ROW_NUMBER()` is constant within an island.

```sql
WITH Days AS (
    SELECT DISTINCT te.UserId, te.WorkDate FROM app.TimeEntries AS te
),
Grouped AS (
    SELECT d.UserId, d.WorkDate,
           DATEADD(DAY, -ROW_NUMBER() OVER (PARTITION BY d.UserId ORDER BY d.WorkDate),
                   d.WorkDate) AS GrpKey
    FROM Days AS d
)
SELECT g.UserId, MIN(g.WorkDate) AS StreakStart, MAX(g.WorkDate) AS StreakEnd, COUNT(*) AS Days_
FROM Grouped AS g
GROUP BY g.UserId, g.GrpKey;
```

Dennis Ritchie (user 8) returns three islands: `2024-02-20 → 2024-02-21` (2 days), `2024-03-13` (1 day), `2025-07-16 → 2025-07-17` (2 days). The `DISTINCT` matters — two entries on the same day would otherwise break the arithmetic.

### Period-over-period delta

```sql
WITH Monthly AS (
    SELECT DATEFROMPARTS(YEAR(te.WorkDate), MONTH(te.WorkDate), 1) AS MonthStart,
           SUM(te.Hours) AS Hours_
    FROM app.TimeEntries AS te
    GROUP BY DATEFROMPARTS(YEAR(te.WorkDate), MONTH(te.WorkDate), 1)
)
SELECT m.MonthStart, m.Hours_,
       LAG(m.Hours_) OVER (ORDER BY m.MonthStart)              AS PrevHours,
       m.Hours_ - LAG(m.Hours_) OVER (ORDER BY m.MonthStart)   AS Delta
FROM Monthly AS m;
```

2024-02 logs 35.00 hours, 2024-03 logs 21.00, delta −14.00. **Caveat:** `LAG` fetches the *previous row*, not the *previous month*. TaskFlow has no time entries in 2024-05, so `LAG` silently compares April with June. If the requirement is calendar-adjacent, join to a dense date spine first.

### Running balance

```sql
SELECT
    te.WorkDate, t.TaskId,
    CAST(te.Hours * u.HourlyRate AS DECIMAL(12,2)) AS Cost,
    CAST(SUM(te.Hours * u.HourlyRate) OVER w AS DECIMAL(12,2))             AS RunningCost,
    CAST(p.Budget - SUM(te.Hours * u.HourlyRate) OVER w AS DECIMAL(12,2))  AS BudgetLeft
FROM app.TimeEntries AS te
JOIN app.Tasks    AS t ON t.TaskId    = te.TaskId
JOIN app.Projects AS p ON p.ProjectId = t.ProjectId
JOIN app.Users    AS u ON u.UserId    = te.UserId
WHERE t.ProjectId = 1
WINDOW w AS (ORDER BY te.WorkDate, te.TimeEntryId ROWS UNBOUNDED PRECEDING);
```

Project 1 burns 720.00 on day one and 7 166.25 in total, leaving 242 833.75 of its 250 000.00 budget. `te.TimeEntryId` in the `ORDER BY` is the tie-breaker that makes the running balance reproducible.

### Sessionisation

Two windows: one to flag a new session, one to number them.

```sql
WITH Flagged AS (
    SELECT c.CommentId, c.TaskId, c.PostedAtUtc,
           CASE WHEN DATEDIFF(MINUTE,
                              LAG(c.PostedAtUtc) OVER (PARTITION BY c.TaskId ORDER BY c.PostedAtUtc),
                              c.PostedAtUtc) <= 60
                THEN 0 ELSE 1 END AS IsNewSession
    FROM app.Comments AS c
)
SELECT f.TaskId, f.CommentId, f.PostedAtUtc,
       SUM(f.IsNewSession) OVER (PARTITION BY f.TaskId ORDER BY f.PostedAtUtc
                                 ROWS UNBOUNDED PRECEDING) AS SessionNo
FROM Flagged AS f;
```

Task 1's two comments are 22 minutes apart — one session. Task 20's are 90 minutes apart — two sessions. The first row of every partition has a NULL `LAG`, and `NULL <= 60` is `UNKNOWN`, so the `CASE` falls to `ELSE 1` and correctly opens session 1.

### First and last row per partition in one pass

```sql
SELECT DISTINCT
    t.ProjectId,
    FIRST_VALUE(t.Title) OVER w AS OldestTask,
    LAST_VALUE(t.Title)  OVER w AS NewestTask
FROM app.Tasks AS t
WINDOW w AS (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);
```

Project 1: `Design database schema` → `Add rate limiting middleware`. One scan instead of two `CROSS APPLY (TOP 1)` blocks.

---

## 11. Window Functions vs the Alternatives

| Requirement | `GROUP BY` | Correlated subquery | `APPLY` | Window function |
|---|---|---|---|---|
| One row per group | **Best** | — | — | Needs `DISTINCT` |
| Detail row + group aggregate | Needs a self-join | Works, one pass **per row** | Works | **Best** — one pass |
| Running total | No | O(n²) | O(n²) | **Best** |
| Rank / dense rank / percentile | No | Painful | No | **Best** |
| Previous / next row | No | Painful | Possible | **Best** (`LAG`/`LEAD`) |
| Top-N per group, small N, indexed | No | No | **Best** — one seek per group | Good |
| Top-N per group, scanning anyway | No | No | Good | **Best** |
| Filter on the computed value | `HAVING` | `WHERE` | `WHERE` | Requires a CTE |
| Needs columns from another table | Join first | Built in | Built in | Join first |

Two rules settle most arguments. **If the output grain is the group, use `GROUP BY`** — wrapping a window function in `SELECT DISTINCT` to fake it is slower and hides the intent. **If the output grain is the row, use a window function** — the self-join-to-an-aggregated-derived-table pattern (`JOIN (SELECT ProjectId, SUM(…) … GROUP BY ProjectId)`) is the pre-2005 workaround; it reads the table twice and multiplies rows if the join key is not unique.

---

## 12. Performance

### The operators

A window function compiles to a recognisable stack:

| Operator | Job |
|---|---|
| `Sort` | Orders by `PARTITION BY` columns then `ORDER BY` columns — unless an index already supplies that order |
| `Segment` | Marks partition boundaries |
| `Sequence Project` | Computes `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE` |
| `Window Spool` | Materialises the frame so aggregates can be evaluated over it |
| `Stream Aggregate` | Aggregates the spooled frame |
| `Window Aggregate` | Batch-mode replacement for the whole spool + aggregate stack (SQL Server 2016+) |

Both frame types produce a `Window Spool`, but they are not the same spool. The `ROWS` plan adds a `Sequence Project` to number the rows and in exchange gets the **fast in-memory worktable**, used whenever the frame holds fewer than 10 000 rows. The `RANGE` spool always writes an on-disk worktable in tempdb. On a wide table with large partitions this is routinely a several-fold difference, entirely invisible in the query text.

### The POC index

The one index pattern to memorise: **P**artition, **O**rder, **C**overing.

```sql
-- For: ROW_NUMBER() OVER (PARTITION BY ProjectId ORDER BY CreatedAtUtc DESC)
--      selecting TaskId, Title
CREATE INDEX IX_Tasks_POC
    ON app.Tasks (ProjectId, CreatedAtUtc DESC)
    INCLUDE (Title);
```

Key columns in `PARTITION BY` order, then `ORDER BY` order (matching the direction), then everything else the query needs in `INCLUDE`. It removes the `Sort` — usually the most expensive operator in the plan and the one that requests a memory grant and can spill to tempdb.

### Other levers

- **Batch mode** (columnstore, or rowstore batch mode on SQL Server 2019+) replaces the spool stack with a single `Window Aggregate` operator and is dramatically faster on large sets.
- **Filter before you window.** `WHERE` runs first, so pushing predicates into the CTE that computes the window shrinks the sort input.
- **Compute the window once.** Five `OVER()` clauses with *identical* specifications share one `Sort`/`Segment` pass; five *different* ones each get their own. Consolidating specifications — which is what the `WINDOW` clause encourages — is real tuning, not cosmetics. And watch the memory grant: a window over a large unsorted set is a sort, and a sort that spills turns a seconds query into a minutes query.

---

## 13. Restriction Museum

| What you wrote | Error | Why |
|---|---|---|
| Window function in `WHERE`/`GROUP BY`/`HAVING` | Msg 4108 | Evaluated after those clauses — wrap in a CTE |
| `RANGE BETWEEN 1 PRECEDING …` | Msg 4194 | SQL Server supports `RANGE` only with `UNBOUNDED`/`CURRENT ROW` |
| `ROW_NUMBER() OVER (ORDER BY x ROWS …)` | Msg 10752 | Ranking functions may not have a frame |
| `SUM(x) OVER (PARTITION BY p ROWS …)` | Msg 10756 | A frame requires `ORDER BY` |
| `COUNT(DISTINCT x) OVER (…)` | Msg 10759 | `DISTINCT` is not allowed with `OVER` |
| `LAG(x) OVER (PARTITION BY p)` | Msg 4112 | `LAG`/`LEAD`/ranking functions require `ORDER BY` |

---

## Mental Model

> A window function is an aggregate that **keeps its rows**. `PARTITION BY` says *which rows share a calculation*, `ORDER BY` says *in what direction the calculation moves*, and the frame says *how far it can see* — and the frame you get by default when you supply `ORDER BY` is `RANGE`, which lumps tied rows together and quietly breaks running totals, so write `ROWS UNBOUNDED PRECEDING` explicitly. Ranking functions differ only in how they treat ties: `ROW_NUMBER` breaks them arbitrarily, `RANK` shares and skips, `DENSE_RANK` shares and does not skip, `NTILE` ignores values entirely and splits by count. Offset functions look sideways instead of down, and `LAST_VALUE` is a trap until you give it `UNBOUNDED FOLLOWING`. Because all of this runs after `WHERE` and `GROUP BY`, you can never filter on the result in the same query — compute it in a CTE and filter outside, which is the shape of every classic recipe from top-N-per-group to deduplication to gaps-and-islands. And when it is slow, the answer is almost always the `Sort`: give it a POC index — Partition, Order, Covering — and the most expensive operator disappears.

Move to [Practice Problems](./Practice-Problems.md).
