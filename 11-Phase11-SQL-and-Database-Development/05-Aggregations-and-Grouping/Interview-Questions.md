# Topic 05: Aggregations & Grouping — Interview Questions

---

## Q1. What is the difference between `COUNT(*)`, `COUNT(1)`, `COUNT(column)` and `COUNT(DISTINCT column)`?
**Answer:**

| Expression | Semantics |
|---|---|
| `COUNT(*)` | Number of rows in the group. Never inspects values, so it is the only count that is NULL-blind. |
| `COUNT(1)` | Identical to `COUNT(*)`. The optimizer produces the same plan. There is no performance difference — this is a persistent myth. |
| `COUNT(column)` | Number of rows where `column IS NOT NULL`. |
| `COUNT(DISTINCT column)` | Number of distinct non-NULL values. NULLs are removed *before* deduplication, so a group of all-NULLs returns 0, not 1. |

```sql
USE TaskFlowDb;
GO
SELECT
    COUNT(*)                     AS AllRows,        -- 35
    COUNT(t.DueDate)             AS WithDueDate,    -- 27  (8 rows are NULL)
    COUNT(t.Description)         AS WithDescription,-- 0   (column entirely NULL)
    COUNT(DISTINCT t.StatusId)   AS DistinctStatus  -- 7
FROM app.Tasks AS t;
```

The trap is writing `COUNT(t.TaskId)` when you mean `COUNT(*)`. It gives the same answer today because `TaskId` is a NOT NULL primary key, but the instant the table appears on the null-able side of a `LEFT JOIN`, the two diverge — and the divergence is usually the behaviour you wanted but did not ask for.

---

## Q2. How do aggregate functions treat NULL?
**Answer:**
**Every aggregate except `COUNT(*)` removes NULL inputs from the set before computing.** It does *not* treat them as zero.

The consequence people miss is that `AVG` divides by the count of non-NULL values, not by the row count:

```sql
SELECT
    COUNT(*)                 AS Projects,        -- 8
    COUNT(p.Budget)          AS Budgeted,        -- 6
    SUM(p.Budget)            AS TotalBudget,     -- 660000.00
    AVG(p.Budget)            AS AvgOfBudgeted,   -- 110000.00  (660000 / 6)
    SUM(p.Budget) / COUNT(*) AS AvgAcrossAll     -- 82500      (660000 / 8)
FROM app.Projects AS p;
```

Both answers are arithmetically correct; only one answers the business question. Decide explicitly and, if you want NULL treated as zero, say so: `AVG(ISNULL(p.Budget, 0))`.

With `SET ANSI_WARNINGS ON` (the default for .NET's `SqlClient`), SQL Server raises the informational message *"Null value is eliminated by an aggregate or other SET operation"* — a useful smoke alarm in integration tests.

---

## Q3. What is the difference between `WHERE` and `HAVING`?
**Answer:**
`WHERE` filters **rows** before grouping. `HAVING` filters **groups** after aggregation.

```sql
SELECT p.ProjectCode, COUNT(*) AS OpenTasks
FROM app.Tasks        AS t
JOIN app.Projects     AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses AS s ON s.StatusId  = t.StatusId
WHERE s.IsTerminal = 0          -- row filter, index-usable, shrinks the input
GROUP BY p.ProjectCode
HAVING COUNT(*) >= 4;           -- group filter, needs the aggregate to exist
```

Consequences:

- `WHERE COUNT(*) > 3` fails with **Msg 147** — the aggregate does not exist yet.
- `HAVING OpenTasks > 3` fails with **Msg 207** — `SELECT` aliases are assigned after `HAVING` runs. Repeat the expression.
- `HAVING t.PriorityId = 1` is legal but wrong practice: it filters after aggregating, so you pay to aggregate rows you then throw away.

The subtle behavioural difference: a `WHERE` predicate can remove *all* rows of a group, so the group never forms and never appears in the output. In the query above, `TF-MOB` vanishes entirely because both of its tasks are `CANCELLED`. If the report needs `TF-MOB: 0`, you cannot use `WHERE` at all — you must drive from `app.Projects` with a `LEFT JOIN` and count conditionally.

---

## Q4. What is the logical processing order of a `SELECT` statement?
**Answer:**

```
1. FROM              -- build the join input
2. ON                -- join predicates
3. JOIN              -- re-add outer rows (LEFT / RIGHT / FULL)
4. WHERE             -- filter rows
5. GROUP BY          -- form groups
6. HAVING            -- filter groups
7. SELECT            -- evaluate expressions; aliases created here
8. DISTINCT
9. ORDER BY          -- aliases from step 7 are visible
10. TOP / OFFSET-FETCH
```

This is a *logical* contract, not an execution plan — the optimizer is free to reorder anything as long as the result is identical. But every "why can't I use my alias here?" and "why did my `LEFT JOIN` become an `INNER JOIN`?" question is answered by this list.

Two direct consequences worth stating in an interview:
- Aliases are usable in `ORDER BY` but not in `WHERE`, `GROUP BY`, or `HAVING`.
- A predicate on the null-supplying side of an outer join belongs in `ON` (step 2, before the outer rows are added back), not `WHERE` (step 4, after).

---

## Q5. Why does `AVG` sometimes return a truncated integer, and how do you fix it?
**Answer:**
`AVG` returns the **data type of its argument**. If the column is `TINYINT`/`SMALLINT`/`INT`/`BIGINT`, the division is integer division and the fractional part is discarded.

`app.Tasks.StoryPoints` is `TINYINT`:

```sql
SELECT
    SUM(t.StoryPoints)                        AS TotalPoints,   -- 210
    COUNT(t.StoryPoints)                      AS PointedTasks,  -- 31
    AVG(t.StoryPoints)                        AS AvgWrong,      -- 6
    AVG(CAST(t.StoryPoints AS DECIMAL(10,2))) AS AvgCorrect     -- 6.7741...
FROM app.Tasks AS t;
```

`210 / 31 = 6.774…` and the integer version silently throws away 11 % of the value — a number that still *looks* plausible, which is why it reaches production.

Fix by casting the **column**, inside the aggregate. `CAST(AVG(t.StoryPoints) AS DECIMAL(10,2))` is too late: the truncation already happened.

---

## Q6. How does `GROUP BY` treat NULL values?
**Answer:**
`GROUP BY` uses *not-distinct* semantics, not equality. All NULLs collapse into a **single group**, even though `NULL = NULL` evaluates to `UNKNOWN`.

```sql
SELECT u.ManagerId, COUNT(*) AS DirectReports
FROM app.Users AS u
GROUP BY u.ManagerId;
-- The NULL row has DirectReports = 2 (Ada Lovelace and Guido van Rossum)
```

The same rule applies to `DISTINCT`, `UNION`, `INTERSECT`, `EXCEPT`, and `PARTITION BY`. It is the one place in SQL where NULLs are treated as equal to each other, and it is worth calling out because it contradicts the three-valued logic you use everywhere else.

---

## Q7. Why must every non-aggregated `SELECT` column appear in `GROUP BY`? Do all engines enforce it?
**Answer:**
Because after grouping, a non-aggregated column has no single value — the group contains many rows with potentially different values. SQL Server refuses to guess and raises **Msg 8120**: *"Column '…' is invalid in the select list because it is not contained in either an aggregate function or the GROUP BY clause."*

Engines differ:

| Engine | Behaviour |
|---|---|
| **SQL Server** | Strict, always. No relaxation. |
| **Oracle** | Strict. |
| **PostgreSQL** | Strict, **plus functional-dependency relaxation**: grouping by a table's primary key lets you select any column of that table, because the value is provably unique per group. |
| **MySQL** | `ONLY_FULL_GROUP_BY` is on by default since 5.7.5. With it disabled, MySQL returns an arbitrary row's value — non-deterministic and a classic source of wrong reports. |
| **SQLite** | Permissive; arbitrary value. |

Migration hazard: a MySQL query written under a relaxed mode will not compile on SQL Server, and "fixing" it by wrapping columns in `MIN()` can silently change meaning. Decide instead whether you want a representative value (`MAX(t.Title)`) or a finer grain (`GROUP BY t.ProjectId, t.Title`).

---

## Q8. `DISTINCT` versus `GROUP BY` — when are they the same, and when is one wrong?
**Answer:**
For pure deduplication with no aggregates they are semantically identical and usually produce the same plan (a Hash Match or Stream Aggregate distinct):

```sql
SELECT DISTINCT t.ProjectId FROM app.Tasks AS t;             -- 8 rows
SELECT t.ProjectId FROM app.Tasks AS t GROUP BY t.ProjectId; -- 8 rows, same plan
```

Choose by intent: `DISTINCT` says "remove duplicate rows"; `GROUP BY` says "collapse into buckets and measure them". `DISTINCT` cannot compute an aggregate, so anything with `COUNT`/`SUM` must be `GROUP BY`.

Two things candidates get wrong:
- `DISTINCT` applies to the **entire** select list, not the first column. `SELECT DISTINCT t.ProjectId, t.StatusId FROM app.Tasks` returns 25 rows, not 8.
- Sprinkling `DISTINCT` to make duplicate rows disappear is not a fix — it hides a join fan-out, adds a sort or hash to every execution, and leaves any `SUM` in the query still wrong.

---

## Q9. Explain the "fan-out" problem when aggregating across joins. How do you fix it?
**Answer:**
Joining a parent to a one-to-many child multiplies rows. Joining to **two** independent children produces the Cartesian product of both child sets per parent row, so every measure from either child is inflated.

```sql
-- WRONG
SELECT t.TaskId, COUNT(*) AS Rows_, SUM(te.Hours) AS Hours_Wrong
FROM app.Tasks           AS t
JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
JOIN app.TimeEntries     AS te ON te.TaskId = t.TaskId
WHERE t.TaskId IN (4, 10)
GROUP BY t.TaskId;
```

Task 4 has 2 assignments and 3 time entries (8.00 + 7.00 + 6.00 = **21.00**). The join emits `2 × 3 = 6` rows and `SUM(te.Hours)` returns **42.00**.

Three fixes:

1. **Pre-aggregate each child to one row per key before joining** — the general answer, works for every aggregate:

```sql
SELECT t.TaskId,
       ISNULL(a.AssigneeCount, 0) AS Assignees,
       ISNULL(h.LoggedHours, 0)   AS LoggedHours
FROM app.Tasks AS t
LEFT JOIN (SELECT TaskId, COUNT(*)   AS AssigneeCount FROM app.TaskAssignments GROUP BY TaskId) AS a ON a.TaskId = t.TaskId
LEFT JOIN (SELECT TaskId, SUM(Hours) AS LoggedHours   FROM app.TimeEntries     GROUP BY TaskId) AS h ON h.TaskId = t.TaskId;
```

2. **`COUNT(DISTINCT key)`** — correct, but only for counts. `SUM` cannot be rescued this way because the duplicated values are genuinely equal and indistinguishable.

3. **Scalar subqueries in the `SELECT` list** — readable, and SQL Server usually decorrelates them into the same plan. Prefer fix 1 when you need several measures from one child.

The anti-pattern to name explicitly: "correcting" the total by dividing by the other child's cardinality (`SUM(te.Hours) / COUNT(DISTINCT ta.UserId)`). It coincidentally works on one row and breaks as soon as an assignee logs no time.

**Diagnostic:** if `COUNT(*)` after the join exceeds one row per parent key, the grain changed.

---

## Q10. What is conditional aggregation and why is it preferable to multiple subqueries?
**Answer:**
Putting a `CASE` inside an aggregate lets you compute several differently-filtered measures in **one pass** over the data.

```sql
SELECT
    p.ProjectCode,
    COUNT(*)                                              AS TotalTasks,
    SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END)     AS Closed,
    COUNT(CASE WHEN t.PriorityId = 1 THEN 1 END)          AS Critical,
    AVG(CASE WHEN t.PriorityId <= 2
             THEN CAST(t.EstimatedHours AS DECIMAL(10,2)) END) AS AvgHrsHighPriority
FROM app.Tasks        AS t
JOIN app.Projects     AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses AS s ON s.StatusId  = t.StatusId
GROUP BY p.ProjectCode;
```

The alternative — one correlated subquery per measure — scans the fact table once per column. Conditional aggregation scans once, full stop. It is also how you pivot without the `PIVOT` operator, which matters because `PIVOT` requires a hard-coded column list.

Two idiom details that separate juniors from seniors:
- `SUM(CASE … THEN 1 ELSE 0 END)` returns `0` for an empty group; `SUM(CASE … THEN x END)` returns `NULL`. Pick deliberately.
- Never write `AVG(CASE WHEN c THEN x ELSE 0 END)`. The `ELSE 0` drags non-matching rows into the denominator. Omit the `ELSE` so they become NULL and are skipped.

PostgreSQL has dedicated syntax for this: `SUM(hours) FILTER (WHERE is_billable)`. T-SQL has no `FILTER`; `CASE` is the idiom.

---

## Q11. Compare `ROLLUP`, `CUBE` and `GROUPING SETS`.
**Answer:**
All three produce multiple grouping levels in a **single pass**, which is far cheaper than `UNION ALL`-ing separate queries.

| Clause | Groupings for `(A, B)` | Shape |
|---|---|---|
| `GROUP BY A, B` | `(A,B)` | Detail only |
| `GROUP BY ROLLUP (A, B)` | `(A,B)`, `(A)`, `()` | Hierarchy — **order-sensitive** |
| `GROUP BY CUBE (A, B)` | `(A,B)`, `(A)`, `(B)`, `()` | All combinations — order-insensitive |
| `GROUP BY GROUPING SETS (…)` | Exactly what you list | Explicit; can express both |

On TaskFlow with `A = ProjectCode` (8 values), `B = StatusCode` (7 values) and 25 real combinations: plain grouping returns 25 rows, `ROLLUP` 34 (`25 + 8 + 1`), `CUBE` 41 (`25 + 8 + 7 + 1`).

```sql
SELECT p.ProjectCode, s.StatusCode, COUNT(*) AS Tasks
FROM app.Tasks        AS t
JOIN app.Projects     AS p ON p.ProjectId = t.ProjectId
JOIN ref.TaskStatuses AS s ON s.StatusId  = t.StatusId
GROUP BY ROLLUP (p.ProjectCode, s.StatusCode)
ORDER BY GROUPING(p.ProjectCode), p.ProjectCode,
         GROUPING(s.StatusCode),  s.StatusCode;
```

`GROUPING SETS` is the form to reach for in production — it says exactly which levels you want with no ordering surprises. The deprecated T-SQL forms `GROUP BY a, b WITH ROLLUP` / `WITH CUBE` should not appear in new code.

Portability: PostgreSQL and Oracle support all three; MySQL supports only `WITH ROLLUP`.

---

## Q12. What do `GROUPING()` and `GROUPING_ID()` do, and why do you need them?
**Answer:**
Super-aggregate rows put `NULL` in the columns they rolled up. If the column *also* contains real NULLs, the output is ambiguous. `GROUPING(col)` returns `1` for a subtotal placeholder and `0` for a real value — including a real NULL.

`app.Users.JobTitle` is NULL for exactly one user, which makes the ambiguity concrete:

```sql
SELECT
    CASE WHEN GROUPING(u.JobTitle) = 1 THEN N'*** ALL TITLES ***'
         WHEN u.JobTitle IS NULL       THEN N'(no title on record)'
         ELSE u.JobTitle END      AS JobTitleLabel,
    COUNT(*)                      AS Headcount
FROM app.Users AS u
GROUP BY ROLLUP (u.JobTitle)
ORDER BY GROUPING(u.JobTitle), u.JobTitle;
```

Two of the 14 rows are `(no title on record)` = 1 and `*** ALL TITLES ***` = 20. Using `ISNULL(u.JobTitle, N'(none)')` instead would label both rows `(none)` and a reader would conclude one person is the entire company.

`GROUPING_ID(A, B)` packs the bits into one integer, most-significant first:

| Value | Bits | Meaning |
|---|---|---|
| 0 | `00` | Detail row |
| 1 | `01` | Subtotal per A |
| 2 | `10` | Subtotal per B |
| 3 | `11` | Grand total |

It is the ideal column to `ORDER BY` and to switch formatting on in the presentation layer.

---

## Q13. What does an aggregate return when the input set is empty?
**Answer:**
It depends on whether there is a `GROUP BY`.

| Query shape | Rows returned | `COUNT(*)` | `SUM(x)` / `AVG(x)` / `MIN` / `MAX` |
|---|---|---|---|
| **Scalar aggregate** (no `GROUP BY`) | Exactly 1 | `0` | `NULL` |
| **Vector aggregate** (with `GROUP BY`) | `0` | — | — |

```sql
SELECT COUNT(*) AS Cnt, SUM(t.EstimatedHours) AS Hrs
FROM app.Tasks AS t WHERE t.ProjectId = 999;
-- 1 row: Cnt = 0, Hrs = NULL

SELECT t.ProjectId, COUNT(*) AS Cnt
FROM app.Tasks AS t WHERE t.ProjectId = 999
GROUP BY t.ProjectId;
-- 0 rows
```

Practical impact: an API that reads `reader.GetDecimal(1)` on the first query throws on the NULL; an API that expects "a row per project" gets nothing back from the second. Wrap sums that feed a UI in `ISNULL(SUM(x), 0)`, and drive per-entity reports from the dimension table with a `LEFT JOIN` rather than from the fact table.

---

## Q14. `STDEV` vs `STDEVP`, `VAR` vs `VARP` — what is the difference?
**Answer:**
The suffix `P` means **population**; without it means **sample**.

| Function | Divisor | Use when |
|---|---|---|
| `STDEV` / `VAR` | `n - 1` (Bessel-corrected) | Your rows are a *sample* drawn from a larger population |
| `STDEVP` / `VARP` | `n` | Your rows *are* the entire population |

```sql
SELECT STDEV(u.HourlyRate) AS SampleSd, STDEVP(u.HourlyRate) AS PopSd
FROM app.Users AS u;   -- 19 non-NULL rates; Sophie Wilson's is NULL and is skipped
```

Edge cases worth naming: with one non-NULL value `STDEV` returns `NULL` (division by zero avoided) while `STDEVP` returns `0`. All four skip NULLs, and all four return `FLOAT`, so do not compare their output for exact equality.

Portability: everyone else spells these `stddev_samp` / `stddev_pop` / `var_samp` / `var_pop`.

---

## Q15. How do you concatenate a group's values into one string?
**Answer:**
`STRING_AGG` (SQL Server 2017+ and Azure SQL):

```sql
SELECT t.TaskId,
       STRING_AGG(l.LabelName, N', ') WITHIN GROUP (ORDER BY l.LabelName) AS Labels
FROM app.Tasks      AS t
JOIN app.TaskLabels AS tl ON tl.TaskId  = t.TaskId
JOIN app.Labels     AS l  ON l.LabelId  = tl.LabelId
GROUP BY t.TaskId;
-- Task 20 -> 'security, tech-debt'
```

Key points:
- `WITHIN GROUP (ORDER BY …)` is what makes the output deterministic. Without it the order is undefined.
- NULL elements are skipped, not rendered as empty strings. Use `ISNULL(x, N'?')` if you need a placeholder.
- The return type is `NVARCHAR(4000)` unless an input is `NVARCHAR(MAX)`, in which case it is `NVARCHAR(MAX)`. Long lists can be silently truncated at 4000 if you forget to widen the input.
- Before 2017 the idiom was `FOR XML PATH('')` with `STUFF()`, which also required `.value('.', 'nvarchar(max)')` to survive `&`, `<` and `>`. Recognise it in legacy code; do not write it.

Portability: `string_agg(x, ',' ORDER BY y)` in PostgreSQL, `GROUP_CONCAT` in MySQL, `LISTAGG` in Oracle.

---

## Q16. When would you use `APPROX_COUNT_DISTINCT` instead of `COUNT(DISTINCT …)`?
**Answer:**
`APPROX_COUNT_DISTINCT` (SQL Server 2019+ / Azure SQL) implements HyperLogLog. It guarantees roughly **2 % error at 97 % probability** and uses a bounded amount of memory (under ~1.5 KB per group) instead of building a full distinct set.

Use it when **all** of the following hold:
- The cardinality is genuinely large (millions of distinct values).
- The result feeds a dashboard, capacity plan, or trend line — not billing, compliance, or a `HAVING` boundary condition.
- `COUNT(DISTINCT …)` is demonstrably spilling to tempdb or dominating the plan.

Do **not** use it for anything a human will reconcile against another number, because two approximate counts will not add up.

```sql
SELECT t.ProjectId,
       COUNT(DISTINCT t.CreatedByUserId)        AS ExactCreators,
       APPROX_COUNT_DISTINCT(t.CreatedByUserId) AS ApproxCreators
FROM app.Tasks AS t
GROUP BY t.ProjectId;
```

On a 35-row table the two agree exactly; the difference only appears at scale. Also note that `COUNT(DISTINCT …)` cannot be used as a window function in T-SQL — `COUNT(DISTINCT x) OVER (…)` is a syntax error — so you often need a pre-aggregating CTE anyway.

---

## Q17. *(Senior)* Which physical operators implement `GROUP BY`, and how do you decide which one you want?
**Answer:**
Two, plus a scalar special case.

| | **Stream Aggregate** | **Hash Match (Aggregate)** |
|---|---|---|
| Input must be sorted on the grouping keys | Yes | No |
| Memory grant | Negligible | Proportional to distinct group count |
| Spills to tempdb | Only via a feeding `Sort` | Yes — watch for the spill warning |
| Blocking | No, streams as it goes | Build phase blocks |
| Chosen when | An index already supplies the order, or there are few groups | Large unsorted input, no useful index, many distinct groups |
| Always used for | Scalar aggregates (no `GROUP BY`) | — |

If no index supplies the order, the optimizer either injects a `Sort` (`O(n log n)`, memory grant, possible tempdb spill) in front of a Stream Aggregate, or picks Hash Match. **An unexpected `Sort` feeding a `Stream Aggregate` is one of the most common tuning finds** — it usually means the index that would have supplied the order does not exist or has the wrong leading columns.

In parallel plans you will see a *partial* (local) aggregate per thread followed by a global aggregate; this is normal and desirable. With columnstore, batch-mode aggregation replaces both and is typically an order of magnitude faster.

You can force the comparison during investigation with `OPTION (ORDER GROUP)` and `OPTION (HASH GROUP)` — for diagnosis, not for production code.

---

## Q18. *(Senior)* How do you index for an aggregation-heavy workload?
**Answer:**
Work backwards from the plan you want.

1. **Match the leading key columns to the `GROUP BY` list**, in order, if you want a Stream Aggregate with no `Sort`. Order matters for Stream Aggregate; it is irrelevant to Hash Match.
2. **Put a highly selective `WHERE` column first** if one exists — a seek that eliminates 99 % of rows beats any aggregate optimisation.
3. **`INCLUDE` the measures** so the index is covering; otherwise every group costs key lookups.
4. **Avoid non-sargable grouping expressions.** `GROUP BY CONVERT(VARCHAR(7), CreatedAtUtc, 120)` cannot use an index on `CreatedAtUtc`. Use `CAST(CreatedAtUtc AS DATE)`, or a persisted computed column that you index.

```sql
CREATE INDEX IX_Tasks_Project_Status_Incl
    ON app.Tasks (ProjectId, StatusId)
    INCLUDE (EstimatedHours, StoryPoints);
```

Beyond ordinary indexes:
- **Clustered columnstore** for wide fact-style aggregation over millions of rows — batch mode plus segment elimination.
- **Indexed (materialised) views** when the same aggregate is read constantly and written rarely. `COUNT_BIG(*)` is mandatory (`COUNT(*)` is rejected), the view must be `SCHEMABINDING`, and you must accept the write amplification on every DML against the base table.
- **Pre-aggregated summary tables** refreshed on a schedule when even the write amplification of an indexed view is unacceptable.

Always state the trade-off out loud: every one of these makes reads faster and writes slower.

---

## Q19. *(Senior)* A report says a task took 42 hours; the timesheet says 21. Walk me through your diagnosis.
**Answer:**
This is a grain defect, and the diagnosis is mechanical:

1. **State the intended grain.** "One row per task." Everything else follows.
2. **Count rows before aggregating.** Strip the `GROUP BY`, run the raw join, and count rows per key. If any key returns more than one row, the grain changed.
   ```sql
   SELECT t.TaskId, COUNT(*) AS RowsAfterJoin
   FROM app.Tasks AS t
   JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
   JOIN app.TimeEntries     AS te ON te.TaskId = t.TaskId
   GROUP BY t.TaskId
   HAVING COUNT(*) > (SELECT COUNT(*) FROM app.TimeEntries x WHERE x.TaskId = t.TaskId);
   ```
3. **Identify the multiplier.** 42 / 21 = 2, and task 4 has exactly 2 assignees. The signature of a fan-out is that the error is an exact integer multiple.
4. **Remove joins one at a time** until the number is right. The join you removed last is the culprit.
5. **Fix by pre-aggregating**, not by dividing back out and not by adding `DISTINCT`.
6. **Add a regression test** that asserts the total: `SUM(LoggedHours)` across all tasks must equal `SELECT SUM(Hours) FROM app.TimeEntries` — 160.00 in the seeded database. A single assertion like that catches every future fan-out in that query.

The organisational answer matters too: this class of bug is invisible in code review because the SQL looks correct. The defence is a reconciliation test per report, not more careful reading.

---

## Q20. *(Architect)* Design aggregate serving for a multi-tenant TaskFlow with a billion-row `TimeEntries` table and per-tenant dashboards at high request rates.
**Answer:**
Do not compute a billion-row aggregate per request. Layer the system:

| Layer | Mechanism | Latency | Freshness |
|---|---|---|---|
| **1. Physical design** | Partition `TimeEntries` by `WorkDate`; clustered columnstore; tenant id as the leading key of every index | seconds | live |
| **2. Incremental pre-aggregation** | A summary table at `(TenantId, ProjectId, WorkDate)` grain, updated by the write path or a micro-batch | ms | seconds–minutes |
| **3. Materialised roll-ups** | Daily/weekly grains built from layer 2, not from raw | ms | daily |
| **4. Cache** | Redis keyed on `(tenant, report, params, version)`, invalidated by a per-tenant version stamp bumped on write | sub-ms | seconds |

Design decisions to defend:

- **Grain contract.** Every summary table has a documented grain and a reconciliation job that compares it against the raw source nightly. Silent drift is the real risk, not latency.
- **Additivity.** `COUNT` and `SUM` are additive and can be rolled up from a lower grain. `AVG` is **not** — store `SUM` and `COUNT` separately and divide at read time. `COUNT(DISTINCT)` is not additive either; use HyperLogLog sketches if you need distinct counts to be rollable, or `APPROX_COUNT_DISTINCT` at query time.
- **Tenant isolation.** Tenant id leads every index and every partition scheme so one large tenant cannot make another tenant's dashboard slow. Enforce the predicate with row-level security so an application bug cannot leak across tenants.
- **Late-arriving data.** Time entries can be backdated. The incremental job must be idempotent and must re-process a trailing window (say 7 days), not just "since last watermark".
- **Read/write split.** Point dashboards at a readable secondary replica so analytical scans never take locks on the OLTP path.
- **Escape hatch.** Keep the exact, slow query available and reachable from the UI ("recalculate"), so a user who distrusts a number can get the authoritative answer.

The wrong answers to avoid: "add more indexes" (does not help a billion-row scan), "use `NOLOCK`" (trades correctness for a problem you have not measured), and "cache the query result" without a version-stamped invalidation strategy.
