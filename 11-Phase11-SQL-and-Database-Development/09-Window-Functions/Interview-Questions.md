# Topic 09: Window Functions — Interview Questions

---

## Q1. What is the fundamental difference between `GROUP BY` and a window function?
**Answer:**
`GROUP BY` **collapses** the result set to one row per group. A window function **decorates** every input row with a calculation over a set of related rows, without reducing the row count.

```sql
-- GROUP BY: 8 rows out of 35 tasks.
SELECT t.ProjectId, SUM(t.EstimatedHours) AS ProjectHours
FROM app.Tasks AS t GROUP BY t.ProjectId;

-- Window function: 35 rows out of 35, each annotated with its project total.
SELECT t.TaskId, t.ProjectId, t.EstimatedHours,
       SUM(t.EstimatedHours) OVER (PARTITION BY t.ProjectId) AS ProjectHours
FROM app.Tasks AS t;
```

---

## Q2. Why can't you use a window function in a `WHERE` clause?
**Answer:**
Logical query processing evaluates window functions **after** `FROM`, `WHERE`, `GROUP BY` and `HAVING` — at the same conceptual stage as the `SELECT` list. `WHERE` runs too early to see a window function's result.

```sql
-- Msg 4108: Windowed functions can only appear in the SELECT or ORDER BY clauses.
SELECT t.TaskId FROM app.Tasks AS t
WHERE ROW_NUMBER() OVER (PARTITION BY t.ProjectId ORDER BY t.TaskId) <= 2;
```

The fix is always the same shape: compute the window function in a CTE or derived table, then filter the outer query against the now-materialized column name.

```sql
WITH Ranked AS (
    SELECT t.TaskId, t.ProjectId,
           ROW_NUMBER() OVER (PARTITION BY t.ProjectId ORDER BY t.TaskId) AS rn
    FROM app.Tasks AS t
)
SELECT TaskId, ProjectId FROM Ranked WHERE rn <= 2;
```

---

## Q3. Explain the difference between `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()` when there are ties.
**Answer:**
Given two tasks tied at 8.00 `EstimatedHours` (ranked 6th and 7th by position):

| Function | Tied rows get | Next value after the tie |
|---|---|---|
| `ROW_NUMBER()` | Different numbers, arbitrary order among ties | Continues sequentially (7, 8) |
| `RANK()` | The **same** number (6, 6) | **Skips** ahead by the tie count (8) |
| `DENSE_RANK()` | The same number (6, 6) | Continues with **no gap** (7) |

`RANK` answers "how many rows are strictly ahead of me" (so a gap is mathematically correct); `DENSE_RANK` answers "how many distinct values are ahead of me." `ROW_NUMBER` guarantees a unique, but arbitrary, ordering among ties — it is non-deterministic unless the `ORDER BY` itself is unique.

---

## Q4. What is the default window frame when `ORDER BY` is specified but no frame clause is given, and why is this dangerous?
**Answer:**
The default is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` — **not** `ROWS`. With `RANGE`, all rows that tie on the `ORDER BY` value are treated as peers and included together in every peer row's frame.

```sql
-- Tasks 34 and 6 both have EstimatedHours = 8.00.
SUM(t.EstimatedHours) OVER (ORDER BY t.EstimatedHours DESC)                          -- RANGE default
SUM(t.EstimatedHours) OVER (ORDER BY t.EstimatedHours DESC ROWS UNBOUNDED PRECEDING)  -- explicit ROWS
```

The `RANGE` version gives **both** tied rows the same (larger) running total, because each one's frame already includes its peer. This is invisible while the ordering column happens to be unique in your test data, and then produces a silently wrong running total the day a duplicate value appears. Always write `ROWS UNBOUNDED PRECEDING` explicitly for running totals.

---

## Q5. What is the difference between `ROWS` and `RANGE` frames?
**Answer:**
`ROWS` counts physical rows relative to the current row. `RANGE` counts logical **values** of the `ORDER BY` expression — every row with the same value is a "peer" and is included or excluded together. SQL Server also only supports `RANGE` with `UNBOUNDED PRECEDING`/`CURRENT ROW`/`UNBOUNDED FOLLOWING` — `RANGE BETWEEN 1 PRECEDING AND CURRENT ROW` raises Msg 4194 because a numeric offset for `RANGE` isn't supported. `ROWS` frames are also generally faster: a small `ROWS` frame gets a fast in-memory spool, while `RANGE` always uses an on-disk tempdb worktable.

---

## Q6. Why does `LAST_VALUE()` frequently return "wrong" results, and how do you fix it?
**Answer:**
`LAST_VALUE` is frame-aware, and the default frame ends at `CURRENT ROW` — so "the last value in the frame" is just the current row's own value, which looks like a no-op:

```sql
LAST_VALUE(t.TaskId) OVER (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc)
-- Returns the current row's own TaskId on every row -- not the last task in the partition.
```

Fix with an explicit frame spanning the whole partition:

```sql
LAST_VALUE(t.TaskId) OVER (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc
                            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
```

An equivalent, frame-trap-free alternative is `FIRST_VALUE(x) OVER (... ORDER BY ... DESC)`.

---

## Q7. What is `NTILE(n)`, and how does it differ from `RANK`/`DENSE_RANK`?
**Answer:**
`NTILE(n)` divides the partition into `n` roughly equal-sized buckets **by row count**, not by value. Two rows with an identical value can land in different buckets if they fall on either side of a bucket boundary — unlike `RANK`/`DENSE_RANK`, which always group identical values together. `NTILE` is appropriate for "split this queue evenly across 3 workers"; it is the wrong tool for "assign a grade band by score," where `DENSE_RANK` (or a `CASE` on the value itself) is correct.

---

## Q8. How would you compute a running total, and what's the most common mistake?
**Answer:**
```sql
SELECT te.WorkDate, te.Hours,
       SUM(te.Hours) OVER (PARTITION BY te.TaskId ORDER BY te.WorkDate
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningHours
FROM app.TimeEntries AS te
WHERE te.TaskId = 1;
```

The most common mistake is omitting the frame and relying on the default `RANGE` behavior, which is only safe when the `ORDER BY` column is guaranteed unique (see Q4). The second most common mistake is forgetting `PARTITION BY` entirely, which silently produces a running total across the *whole table* instead of per group.

---

## Q9. How do you find the top 2 most recent tasks per project?
**Answer:**
```sql
WITH Ranked AS (
    SELECT t.TaskId, t.ProjectId, t.Title,
           ROW_NUMBER() OVER (PARTITION BY t.ProjectId
                              ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC) AS rn
    FROM app.Tasks AS t
)
SELECT ProjectId, TaskId, Title FROM Ranked WHERE rn <= 2;
```

`ROW_NUMBER` is used instead of `RANK` because "top 2 rows" (not "top 2 distinct creation timestamps") is the requirement, and a deterministic tie-breaker (`, t.TaskId DESC`) is added because `CreatedAtUtc` could theoretically tie.

---

## Q10. How would you remove duplicate rows from a table that has no natural unique key?
**Answer:**
Number the "duplicate" groups with `ROW_NUMBER`, then delete everything but rank 1, using a CTE as the `DELETE` target:

```sql
WITH D AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY ProjectCode, Title
                              ORDER BY LoadedAtUtc DESC) AS rn
    FROM #TaskImport
)
DELETE FROM D WHERE rn > 1;
```

`PARTITION BY` defines what counts as "the same row"; `ORDER BY` decides which copy survives (here, the most recently loaded). Always run the `SELECT` version first to inspect what will be deleted before switching to `DELETE`.

---

## Q11. Explain the "gaps and islands" problem and the classic technique for solving it.
**Answer:**
Given a sequence of dates (or numbers) with some missing, "islands" are the maximal consecutive runs and "gaps" are the missing spans between them. The classic technique subtracts a row number from the ordering value — for a run of consecutive dates, `date − ROW_NUMBER()` (in days) is **constant**:

```sql
WITH Grouped AS (
    SELECT UserId, WorkDate,
           DATEADD(DAY, -ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY WorkDate), WorkDate) AS GrpKey
    FROM (SELECT DISTINCT UserId, WorkDate FROM app.TimeEntries) AS d
)
SELECT UserId, MIN(WorkDate) AS StreakStart, MAX(WorkDate) AS StreakEnd, COUNT(*) AS Days_
FROM Grouped GROUP BY UserId, GrpKey;
```

Every row in the same consecutive run produces the same `GrpKey`, so grouping by it isolates each island. The `DISTINCT` is required first — duplicate same-day rows would break the arithmetic.

---

## Q12. What is a POC index, and why does it matter for window function performance?
**Answer:**
"POC" stands for **P**artition columns, then **O**rder columns (matching direction), then **C**overing (`INCLUDE`) columns — the ideal index shape for a windowed query:

```sql
-- For: ROW_NUMBER() OVER (PARTITION BY ProjectId ORDER BY CreatedAtUtc DESC) selecting TaskId, Title
CREATE INDEX IX_Tasks_POC ON app.Tasks (ProjectId, CreatedAtUtc DESC) INCLUDE (Title);
```

Without it, the window function's plan needs an explicit `Sort` to arrange rows by partition and order — often the single most expensive operator in the plan, and one that can request a large memory grant and spill to tempdb. With the POC index, rows already arrive pre-sorted, and the `Sort` operator disappears entirely.

---

## Q13. Can you filter directly on the result of `RANK()` in the same query it's computed in? Why or why not?
**Answer:**
No — for the same logical-processing-order reason as any window function (Q2). `RANK()` is computed at the `SELECT`/`ORDER BY` stage, after `WHERE`/`HAVING` have already run, so those clauses cannot see it. It must be computed in a CTE/derived table and filtered in an outer query:

```sql
WITH Ranked AS (
    SELECT t.TaskId, RANK() OVER (ORDER BY t.EstimatedHours DESC) AS r FROM app.Tasks AS t
)
SELECT * FROM Ranked WHERE r <= 3;
```

---

## Q14. What plan operators does SQL Server use to implement window functions, and what does each do?
**Answer:**

| Operator | Role |
|---|---|
| `Sort` | Orders rows by `PARTITION BY` then `ORDER BY` columns, unless an index already provides that order |
| `Segment` | Marks where one partition ends and the next begins |
| `Sequence Project` | Computes `ROW_NUMBER`/`RANK`/`DENSE_RANK`/`NTILE` |
| `Window Spool` | Materializes the rows in the current frame so an aggregate can run over them |
| `Stream Aggregate` | Aggregates the spooled frame (`SUM`, `AVG`, etc.) |
| `Window Aggregate` | A single batch-mode operator (SQL Server 2016+) that replaces the spool + aggregate pair, much faster on large sets |

The `Sort` is usually the most expensive step and the one a POC index eliminates.

---

## Q15. What's the difference between `PERCENTILE_CONT` and `PERCENTILE_DISC`?
**Answer:**
Both compute a percentile within a group via `WITHIN GROUP (ORDER BY ...)`. `PERCENTILE_CONT` **interpolates** between the two nearest data points if the target percentile falls between them — the result may not exist in the underlying data (e.g. a median of an even-sized set averages the two middle values). `PERCENTILE_DISC` always returns an **actual value present in the data** — it picks the first value whose cumulative distribution meets or exceeds the target percentile, never interpolating.

```sql
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY u.HourlyRate) OVER () AS MedianCont,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY u.HourlyRate) OVER () AS MedianDisc
FROM app.Users AS u WHERE u.HourlyRate IS NOT NULL;
```

Both functions restrict their `OVER()` clause to `PARTITION BY` only — no `ORDER BY` is allowed there, since ordering is already supplied via `WITHIN GROUP`.

---

## Q16. Why might two consecutive calls to `LAG()`/`DATEDIFF` silently compare the wrong two rows?
**Answer:**
`LAG` fetches the row that is immediately **previous in the partition's ordering**, not the previous calendar period. If the data has a gap (e.g. no time entries logged in a given month), `LAG` will happily compare across the gap without any indication it happened:

```sql
-- If no entries exist for April, LAG on May's row silently returns March's value.
LAG(m.Hours_) OVER (ORDER BY m.MonthStart)
```

If the requirement is genuinely calendar-adjacent (month-over-month, day-over-day), you must first join the data to a complete date/period spine so that every period is represented as a row — including periods with a zero or NULL value — before applying `LAG`.

---

## Q17. Design question: build a query that returns each project's oldest and newest task title in a single pass, without scanning the table twice.
**Answer:**
```sql
SELECT DISTINCT
    t.ProjectId,
    FIRST_VALUE(t.Title) OVER w AS OldestTask,
    LAST_VALUE(t.Title)  OVER w AS NewestTask
FROM app.Tasks AS t
WINDOW w AS (PARTITION BY t.ProjectId ORDER BY t.CreatedAtUtc
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);
```

Both `FIRST_VALUE` and `LAST_VALUE` share the same named window (`w`), spanning the whole partition explicitly (avoiding the `LAST_VALUE` default-frame trap). `SELECT DISTINCT` collapses the per-row output down to one row per project, since every row in a partition carries the identical `OldestTask`/`NewestTask` values. This scans `app.Tasks` once, versus the pre-window-function idiom of two separate `CROSS APPLY (SELECT TOP (1) ... ORDER BY ...)` blocks.

---

## Q18. A teammate says "window functions are always slower than a `GROUP BY` self-join, since they scan more data." Do you agree?
**Answer:**
No. A self-join pattern (`JOIN (SELECT ProjectId, SUM(x) AS Total FROM T GROUP BY ProjectId) AS agg ON agg.ProjectId = t.ProjectId`) reads the base table **twice** — once for the detail rows, once to build the aggregated derived table — and if the join key isn't unique on either side, it can also multiply rows unexpectedly. A window function reads the table **once**; the optimizer computes the partition/order/frame in a single pass (or a highly optimized batch-mode operator on modern SQL Server). The self-join pattern is the pre-2005 workaround for exactly the problem window functions were introduced to solve.

---

## Q19. When would you deliberately choose a correlated subquery or `APPLY` over a window function?
**Answer:**
Window functions require access to every row you're windowing over, in one query, and cannot themselves invoke a table-valued function or arbitrary correlated logic per row. Reach for `CROSS APPLY`/`OUTER APPLY` instead when:
- You need to call a table-valued function (e.g. splitting JSON/XML) once per outer row.
- The "top N per group" also needs a join into a different table for each group's rows (`APPLY ... (SELECT TOP (n) ... FROM OtherTable WHERE OtherTable.Key = Outer.Key ORDER BY ...)`), which is often a better plan (seek-based, one execution per outer row) than a window function's global sort when N is small and an index supports the seek.
- The computation genuinely only needs a single scalar answer per outer row and there's no benefit to expressing it as a partitioned window (a plain correlated subquery is simpler to read).
