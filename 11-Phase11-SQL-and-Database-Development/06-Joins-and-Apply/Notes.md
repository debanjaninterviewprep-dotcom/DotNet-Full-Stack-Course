# Topic 06: Joins & APPLY

> A relational database stores **TaskFlow** in a dozen narrow tables precisely so that nothing is duplicated. Every screen the user sees puts them back together. Joins are therefore the single most exercised construct in the product — and the single largest source of silent defects: a `WHERE` clause in the wrong place turns a `LEFT JOIN` into an `INNER JOIN` and 8 unassigned tasks vanish from the backlog; a many-to-many join multiplies rows and the timesheet doubles; `NOT IN` meets a NULL and the report goes empty. This topic covers the logical model, every join flavour, `APPLY`, and the three physical operators the optimizer actually uses.

---

## 1. The Conceptual Model: Cartesian Product, Then Filter

Logically, **every** join starts as a Cartesian product and is then filtered by the `ON` predicate.

```
FROM A JOIN B ON <pred>
  ==  every row of A paired with every row of B, keeping pairs where <pred> is TRUE
```

The engine never actually materialises the product — the optimizer picks a physical algorithm (§12) that produces the same result far more cheaply. But reasoning about it as *product-then-filter* explains everything else, including why `ON` and `WHERE` behave differently for outer joins.

Cardinality on the seeded database:

| Query | Rows | Why |
|---|---|---|
| `app.Tasks CROSS JOIN app.TaskAssignments` | 35 × 31 = **1085** | No predicate at all |
| `app.Tasks JOIN app.TaskAssignments ON TaskId` | **31** | Every assignment matches exactly one task |
| `app.Tasks LEFT JOIN app.TaskAssignments ON TaskId` | **39** | 31 matched + 8 unassigned tasks |
| `app.Users LEFT JOIN app.TaskAssignments ON UserId` | **37** | 31 matched + 6 users with no work |
| `app.Tasks LEFT JOIN app.TaskLabels ON TaskId` | **38** | 28 label rows + 10 unlabelled tasks |

Memorise the discipline: **before you write a join, state the expected row count.** If the result does not match, stop and find out why.

---

## 2. `CROSS JOIN`

### Deliberate

A `CROSS JOIN` is the right tool when you need a **dense grid** — every combination must exist in the output even when there is no data for it.

```sql
USE TaskFlowDb;
GO

-- 8 projects x 7 statuses = 56 rows, guaranteed, even for empty cells
SELECT
    p.ProjectCode,
    s.StatusCode,
    COUNT(t.TaskId) AS Tasks          -- COUNT(col), not COUNT(*)
FROM app.Projects     AS p
CROSS JOIN ref.TaskStatuses AS s
LEFT JOIN app.Tasks   AS t
       ON t.ProjectId = p.ProjectId
      AND t.StatusId  = s.StatusId
GROUP BY p.ProjectCode, s.StatusCode
ORDER BY p.ProjectCode, s.StatusCode;
```

56 rows; `SUM(Tasks)` = 35. Without the `CROSS JOIN`, only the 25 real combinations appear and the UI grid has holes.

Other legitimate uses: generating date spines from a numbers table, expanding a config matrix, building test data.

### Accidental

```sql
-- Missing ON predicate. 1085 rows. Every "total" downstream is 31x too big.
SELECT t.TaskId, ta.UserId
FROM app.Tasks AS t, app.TaskAssignments AS ta;
```

> **Anti-pattern:** Comma-separated `FROM` lists (ANSI-89 syntax). The join predicate hides among the row filters in `WHERE`, so forgetting one produces a silent Cartesian product instead of a syntax error. `JOIN … ON` makes an omitted predicate a compile error.

---

## 3. `INNER JOIN`

Returns only rows where the predicate is `TRUE`. `UNKNOWN` (a NULL comparison) is not `TRUE`, so NULL keys never match — not even against each other.

```sql
SELECT
    t.TaskId,
    t.Title,
    p.ProjectCode,
    s.StatusName,
    pr.PriorityName
FROM app.Tasks        AS t
JOIN app.Projects     AS p  ON p.ProjectId  = t.ProjectId
JOIN ref.TaskStatuses AS s  ON s.StatusId   = t.StatusId
JOIN ref.Priorities   AS pr ON pr.PriorityId = t.PriorityId
WHERE p.IsArchived = 0;
```

`JOIN` is a synonym for `INNER JOIN`. Write `JOIN` for inner and always spell out `LEFT JOIN` / `FULL JOIN` — the asymmetry deserves the extra word.

Every join above is safe from row multiplication because `ProjectId`, `StatusId` and `PriorityId` are foreign keys to a **primary key**, so each task matches exactly one row. That is the property to look for: *many-to-one joins do not change the grain; one-to-many joins do.*

---

## 4. Outer Joins — a Worked Result Set

The seed data is built for this: 8 tasks are deliberately unassigned and 6 users deliberately have no assignments.

### `LEFT OUTER JOIN`

Keeps every row of the **left** table; fills the right side with NULL when there is no match.

```sql
SELECT t.TaskId, t.Title, ta.UserId, u.FullName AS Assignee
FROM app.Tasks           AS t
LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
LEFT JOIN app.Users           AS u  ON u.UserId  = ta.UserId
WHERE t.ProjectId = 8              -- TF-DS: tasks 31, 32, 33
ORDER BY t.TaskId;
```

| TaskId | Title | UserId | Assignee |
|---|---|---|---|
| 31 | Audit existing components | 14 | Tim Berners-Lee |
| 32 | Publish token package | 14 | Tim Berners-Lee |
| 33 | Write contribution guide | NULL | NULL |

Task 33 is the whole point. An `INNER JOIN` would return 2 rows and the product manager would never see the unassigned task.

### `RIGHT OUTER JOIN`

Keeps every row of the **right** table. Identical power to `LEFT`, mirrored.

```sql
SELECT ta.TaskId, u.UserId, u.FullName
FROM app.TaskAssignments AS ta
RIGHT JOIN app.Users     AS u ON u.UserId = ta.UserId
WHERE u.UserId IN (1, 2, 15, 16)
ORDER BY u.UserId, ta.TaskId;
```

| TaskId | UserId | FullName |
|---|---|---|
| NULL | 1 | Ada Lovelace |
| NULL | 2 | Grace Hopper |
| 23 | 15 | Joan Clarke |
| 24 | 16 | Hedy Lamarr |
| 25 | 16 | Hedy Lamarr |

> **Rule of thumb:** Prefer `LEFT JOIN` everywhere. Reading a query top-to-bottom, `LEFT` means "keep what I have so far"; `RIGHT` forces the reader to look ahead. Any `RIGHT JOIN` can be rewritten by swapping the table order. Mixed `LEFT` and `RIGHT` in one `FROM` clause is a code smell.

### `FULL OUTER JOIN`

Keeps unmatched rows from **both** sides. Used for reconciliation: "what is in A but not B, in B but not A, and in both".

```sql
WITH T AS (
    SELECT t.TaskId, t.Title
    FROM app.Tasks AS t
    WHERE t.ProjectId = 8                      -- 31, 32, 33
),
A AS (
    SELECT ta.TaskId, ta.UserId
    FROM app.TaskAssignments AS ta
    WHERE ta.UserId IN (14, 15)                -- (23,15) (28,14) (31,14) (32,14)
)
SELECT T.TaskId AS TaskSideId, T.Title, A.TaskId AS AssignSideId, A.UserId
FROM T
FULL OUTER JOIN A ON A.TaskId = T.TaskId
ORDER BY T.TaskId, A.TaskId;
```

| TaskSideId | Title | AssignSideId | UserId |
|---|---|---|---|
| 31 | Audit existing components | 31 | 14 |
| 32 | Publish token package | 32 | 14 |
| 33 | Write contribution guide | NULL | NULL |
| NULL | NULL | 23 | 15 |
| NULL | NULL | 28 | 14 |

Three shapes in one result: **matched** (31, 32), **left-only** (33), **right-only** (23, 28). Classify them with `CASE WHEN T.TaskId IS NULL THEN 'RightOnly' WHEN A.TaskId IS NULL THEN 'LeftOnly' ELSE 'Matched' END`.

> **Portability:** MySQL has no `FULL OUTER JOIN`. Emulate with `LEFT JOIN … UNION … RIGHT JOIN …`. PostgreSQL, Oracle and SQL Server all support it natively.

---

## 5. `ON` vs `WHERE` — the Silent Downgrade

This is the most expensive five minutes in this topic.

Recall the logical processing order: `ON` is evaluated at step 2, **before** the outer rows are added back at step 3. `WHERE` runs at step 4, **after**. So a predicate on the null-supplying table means two completely different things depending on where you put it.

```sql
-- (a) Predicate in ON: task 33 survives with NULLs
SELECT t.TaskId, u.FullName
FROM app.Tasks AS t
LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
LEFT JOIN app.Users           AS u  ON u.UserId  = ta.UserId
                                   AND u.CountryCode = 'GB'
WHERE t.ProjectId = 8;
```

| TaskId | FullName |
|---|---|
| 31 | Tim Berners-Lee |
| 32 | Tim Berners-Lee |
| 33 | NULL |

```sql
-- (b) Same predicate in WHERE: the LEFT JOIN silently became an INNER JOIN
SELECT t.TaskId, u.FullName
FROM app.Tasks AS t
LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
LEFT JOIN app.Users           AS u  ON u.UserId  = ta.UserId
WHERE t.ProjectId = 8
  AND u.CountryCode = 'GB';      -- <-- NULL <> 'GB' is UNKNOWN, row eliminated
```

| TaskId | FullName |
|---|---|
| 31 | Tim Berners-Lee |
| 32 | Tim Berners-Lee |

Task 33 is gone. Nothing warned you.

```sql
-- (c) Non-matching predicate in ON: all rows survive, all values NULL
--     ... AND u.CountryCode = 'US'  ->  31 NULL, 32 NULL, 33 NULL  (3 rows)
```

### Decision rule

| Predicate is on… | Put it in | Effect |
|---|---|---|
| The **preserved** (left) table | `WHERE` | Normal row filter |
| The **null-supplying** (right) table, and unmatched rows must be **kept** | `ON` | Filters what counts as a match |
| The **null-supplying** table, and unmatched rows should be **dropped** | `WHERE` | Intentional downgrade to inner join — add a comment saying so |
| An anti-join test (`ta.TaskId IS NULL`) | `WHERE` | This is the one legitimate `WHERE` on the right table |

> **Anti-pattern:** `WHERE rightTable.col = 'x' OR rightTable.col IS NULL` as a workaround. It is a hidden `ON` predicate, it is not sargable, and it breaks the moment `col` is genuinely NULL in a matched row. Move the predicate to `ON`.

The same trap applies to a `LEFT JOIN` followed by an `INNER JOIN` that references the outer table:

```sql
-- The INNER JOIN to app.Users kills every task with no assignment,
-- even though the join to app.TaskAssignments is LEFT.
FROM app.Tasks AS t
LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
JOIN      app.Users           AS u  ON u.UserId  = ta.UserId
```

Once you go outer, stay outer down the whole chain.

---

## 6. `SELF JOIN`

A table joined to itself, distinguished by aliases. `app.Users.ManagerId` is a self-reference, so the org chart is a self-join.

```sql
-- Every user with their manager. LEFT keeps Ada Lovelace and Guido van Rossum,
-- who have no manager. 20 rows.
SELECT
    e.UserId,
    e.FullName            AS Employee,
    e.JobTitle,
    m.FullName            AS Manager,
    m.JobTitle            AS ManagerTitle
FROM app.Users AS e
LEFT JOIN app.Users AS m ON m.UserId = e.ManagerId
ORDER BY e.UserId;
```

Change `LEFT` to `JOIN` and you get 18 rows — the two top-level users disappear. That is exactly the class of bug that makes a headcount report not add up.

Two levels up (employee → manager → skip-level):

```sql
SELECT
    e.FullName  AS Employee,
    m.FullName  AS Manager,
    mm.FullName AS SkipLevel
FROM app.Users AS e
LEFT JOIN app.Users AS m  ON m.UserId  = e.ManagerId
LEFT JOIN app.Users AS mm ON mm.UserId = m.ManagerId
WHERE e.UserId IN (9, 16, 20)
ORDER BY e.UserId;
```

| Employee | Manager | SkipLevel |
|---|---|---|
| Anita Borg | Linus Torvalds | Grace Hopper |
| Hedy Lamarr | Joan Clarke | Grace Hopper |
| Guido van Rossum | NULL | NULL |

Self-joins handle a **fixed** number of levels. For arbitrary depth you need a recursive CTE — Topic 07.

Self-joins are also how you compare rows within a table:

```sql
-- Pairs of tasks in the same project with the same due date
SELECT a.TaskId, b.TaskId, a.ProjectId, a.DueDate
FROM app.Tasks AS a
JOIN app.Tasks AS b
      ON b.ProjectId = a.ProjectId
     AND b.DueDate   = a.DueDate
     AND b.TaskId    > a.TaskId;      -- '>' prevents self-pairs AND mirror duplicates
```

> **Rule of thumb:** In a self-join used to compare rows, always add an inequality on the key (`b.TaskId > a.TaskId`). Without it you get each row paired with itself plus every pair twice.

---

## 7. Multi-Table Joins and Join Order

For **inner** joins, the written order carries no meaning: they are commutative and associative, and the optimizer will reorder them freely based on statistics. Writing the "small table first" is folklore.

For **outer** joins, order is semantically significant. `A LEFT JOIN B LEFT JOIN C` is not the same as `A LEFT JOIN C LEFT JOIN B` when the `ON` predicates reference each other, and mixing inner and outer joins constrains what the optimizer is allowed to reorder.

```sql
-- Six tables, one row per task, no grain change: every join is many-to-one.
SELECT
    p.ProjectCode,
    tm.TeamName,
    t.TaskId,
    t.Title,
    s.StatusName,
    pr.PriorityName,
    creator.FullName AS CreatedBy,
    po.FullName      AS ProjectOwner
FROM app.Tasks        AS t
JOIN app.Projects     AS p       ON p.ProjectId   = t.ProjectId
JOIN app.Teams        AS tm      ON tm.TeamId     = p.TeamId
JOIN ref.TaskStatuses AS s       ON s.StatusId    = t.StatusId
JOIN ref.Priorities   AS pr      ON pr.PriorityId = t.PriorityId
JOIN app.Users        AS creator ON creator.UserId = t.CreatedByUserId
JOIN app.Users        AS po      ON po.UserId      = p.OwnerUserId
WHERE t.StatusId NOT IN (6, 7);
```

35 tasks in, 22 rows out (only the `WHERE` reduced the count). If you had joined `app.TaskAssignments` or `app.TaskLabels` in that list, the grain would have changed — see §9.

`OPTION (FORCE ORDER)` makes the optimizer honour your written order. It is a diagnostic tool, not a fix (§13).

---

## 8. Semi-Joins and Anti-Joins

A **semi-join** asks *"does a match exist?"* and returns rows of the left table only, never duplicated. An **anti-join** asks *"does no match exist?"*.

Neither has dedicated syntax in T-SQL; you express them with `EXISTS` / `NOT EXISTS`, and the optimizer produces a physical semi-join or anti-semi-join operator.

### Semi-join

```sql
-- Users with at least one Critical task assigned. 5 rows: Barbara, Ken,
-- Dennis, Jean, Shafi. No duplicates even though Shafi has two.
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE EXISTS (
    SELECT 1
    FROM app.TaskAssignments AS ta
    JOIN app.Tasks           AS t ON t.TaskId = ta.TaskId
    WHERE ta.UserId  = u.UserId
      AND t.PriorityId = 1
);
```

Compare with an `INNER JOIN`, which returns 6 rows because Shafi Goldwasser is assigned to two Critical tasks, and then needs a `DISTINCT` to fix it. `EXISTS` short-circuits on the first match and cannot duplicate. Prefer it whenever you need existence rather than data.

### Anti-join — three ways, one trap

```sql
-- Tasks with no assignee. 8 rows: 8, 18, 22, 26, 27, 29, 30, 33.

-- (1) NOT EXISTS   <-- the default choice
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE NOT EXISTS (SELECT 1 FROM app.TaskAssignments AS ta WHERE ta.TaskId = t.TaskId);

-- (2) LEFT JOIN ... IS NULL
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
WHERE ta.TaskId IS NULL;

-- (3) NOT IN  -- safe HERE only because TaskAssignments.TaskId is NOT NULL
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE t.TaskId NOT IN (SELECT ta.TaskId FROM app.TaskAssignments AS ta);
```

### The `NOT IN` NULL trap

`x NOT IN (a, b, NULL)` expands to `x <> a AND x <> b AND x <> NULL`. The last term is `UNKNOWN`, so the whole conjunction can never be `TRUE`. **One NULL in the subquery makes `NOT IN` return zero rows.**

`app.Users.ManagerId` is nullable and does contain NULLs:

```sql
-- Individual contributors (nobody reports to them).
-- Returns 0 ROWS. Silently. Because ManagerId is NULL for Ada and Guido.
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);

-- Correct: 13 rows.
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.Users AS m WHERE m.ManagerId = u.UserId);

-- Also correct, but you must remember the guard:
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m WHERE m.ManagerId IS NOT NULL);
```

### Comparison

| Approach | NULL-safe | Reads | Plan | Verdict |
|---|---|---|---|---|
| `NOT EXISTS` | **Yes** | Clearly states intent | Anti-semi-join; short-circuits | **Default choice** |
| `LEFT JOIN … IS NULL` | Yes | Requires two mental steps | Usually the same anti-semi-join | Fine; slightly noisier |
| `NOT IN` | **No** | Shortest | Adds a null-check branch when the column is nullable | Only over a `NOT NULL` column |
| `EXCEPT` | Yes | Whole-row comparison only | Distinct + anti-join | When comparing entire result sets (Topic 08) |

On modern SQL Server, `NOT EXISTS` and `LEFT JOIN … IS NULL` typically compile to the **same** plan. `NOT IN` over a nullable column compiles to a more complex plan *because* it has to implement the three-valued logic — so it is both wrong and slower.

---

## 9. Many-to-Many Joins and Row Multiplication

`app.TaskLabels` and `app.TeamMembers` are junction tables. Joining through them multiplies rows by design.

```sql
SELECT COUNT(*) FROM app.Tasks AS t
JOIN app.TaskLabels AS tl ON tl.TaskId = t.TaskId;   -- 28, not 35
```

25 tasks carry at least one label; tasks 4, 6 and 20 carry two, giving 28 rows. Ten tasks carry none and disappear entirely under `INNER JOIN`.

```sql
-- Full label picture, one row per task, no multiplication
SELECT
    t.TaskId,
    t.Title,
    ISNULL(l.Labels, N'(unlabelled)') AS Labels
FROM app.Tasks AS t
OUTER APPLY (
    SELECT STRING_AGG(lb.LabelName, N', ') WITHIN GROUP (ORDER BY lb.LabelName) AS Labels
    FROM app.TaskLabels AS tl
    JOIN app.Labels     AS lb ON lb.LabelId = tl.LabelId
    WHERE tl.TaskId = t.TaskId
) AS l;
```

35 rows. Task 20 shows `security, tech-debt`; task 2 shows `(unlabelled)`.

The same effect on the people side: Ken Thompson belongs to both `Platform` and `Security`, so `app.Users JOIN app.TeamMembers` returns 19 rows for 16 distinct users. Four users belong to no team at all and vanish under `INNER JOIN`.

> **Rule of thumb:** Any join to a junction table changes the grain. If the query already aggregates something else, pre-aggregate the junction side (Topic 05, §7) or use `OUTER APPLY` with `STRING_AGG`. Do not reach for `SELECT DISTINCT`.

---

## 10. Non-Equi Joins

The `ON` predicate can be any boolean expression. Range joins are the common case: mapping a continuous value onto bands.

```sql
-- Map each priority's SLA onto a response band.
SELECT p.PriorityCode, p.SlaHours, b.BandName
FROM ref.Priorities AS p
LEFT JOIN (VALUES
        (N'Same day',    0,    8),
        (N'Next day',    8,   24),
        (N'This week',  24,  168),
        (N'Backlog',   168, 8760)
    ) AS b (BandName, MinHours, MaxHours)
    ON p.SlaHours >= b.MinHours
   AND p.SlaHours <  b.MaxHours;
```

| PriorityCode | SlaHours | BandName |
|---|---|---|
| CRITICAL | 4 | Same day |
| HIGH | 24 | This week |
| MEDIUM | 72 | This week |
| LOW | 168 | Backlog |
| NONE | NULL | NULL |

Two lessons in five rows:

1. **Half-open intervals (`>= min AND < max`) are mandatory.** With `BETWEEN` on both ends, `SlaHours = 24` matches both `Next day` and `This week` and the row silently duplicates.
2. **NULL never satisfies a range predicate.** `NONE` matched nothing. `INNER JOIN` would have dropped it; `LEFT JOIN` keeps it with a NULL band. Choosing between those two *is* the design decision.

Rolled up to tasks: Same day 4, This week 23, Backlog 5, no band 3 — total 35.

> **Performance note:** Range joins cannot use a hash join (hashing requires equality) and rarely use a merge join. They typically compile to Nested Loops with a range seek on the inner side, which is fine against a small band table and catastrophic against a large one. Keep band tables tiny and indexed on the lower bound.

---

## 11. `CROSS APPLY` and `OUTER APPLY`

`APPLY` is a **correlated join**: the right-hand expression is evaluated once **per row** of the left, and may reference the left row's columns. A `JOIN` subquery cannot do that.

| | Rows kept from the left |
|---|---|
| `CROSS APPLY` | Only rows where the right side returned ≥ 1 row (behaves like `INNER JOIN`) |
| `OUTER APPLY` | All rows; right side NULL-filled when it returned nothing (behaves like `LEFT JOIN`) |

### Use 1 — Top-N per group

The canonical `APPLY` use case, and far more readable than the `ROW_NUMBER()` alternative.

```sql
-- The two most recently created tasks in every project. 8 x 2 = 16 rows.
SELECT p.ProjectCode, x.TaskId, x.Title, x.CreatedAtUtc
FROM app.Projects AS p
CROSS APPLY (
    SELECT TOP (2) t.TaskId, t.Title, t.CreatedAtUtc
    FROM app.Tasks AS t
    WHERE t.ProjectId = p.ProjectId
    ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC
) AS x
ORDER BY p.ProjectCode, x.CreatedAtUtc DESC;
```

```sql
-- Latest time entry per task. CROSS APPLY -> 16 rows (only tasks with entries).
-- Swap to OUTER APPLY -> all 35 rows, NULLs for the 19 with no time logged.
SELECT t.TaskId, t.Title, le.WorkDate, le.Hours
FROM app.Tasks AS t
OUTER APPLY (
    SELECT TOP (1) te.WorkDate, te.Hours
    FROM app.TimeEntries AS te
    WHERE te.TaskId = t.TaskId
    ORDER BY te.WorkDate DESC, te.TimeEntryId DESC
) AS le;
```

> **Rule of thumb:** Always add a tie-breaker to the `ORDER BY` inside a `TOP (n)` apply. `ORDER BY te.WorkDate DESC` alone is non-deterministic when two entries share a date.

### Use 2 — Table-valued functions

`APPLY` is the **only** way to call a TVF once per row with that row's values.

```sql
CREATE OR ALTER FUNCTION app.fn_TaskEffort (@TaskId INT)
RETURNS TABLE
AS
RETURN
    SELECT
        SUM(te.Hours)                                             AS LoggedHours,
        SUM(CASE WHEN te.IsBillable = 1 THEN te.Hours ELSE 0 END) AS BillableHours,
        COUNT(*)                                                  AS EntryCount
    FROM app.TimeEntries AS te
    WHERE te.TaskId = @TaskId;
GO

SELECT t.TaskId, t.Title, e.LoggedHours, e.BillableHours, e.EntryCount
FROM app.Tasks AS t
CROSS APPLY app.fn_TaskEffort(t.TaskId) AS e
WHERE t.ProjectId = 1;
```

Subtlety worth internalising: the function body is a **scalar aggregate** with no `GROUP BY`, so it always returns exactly one row — even for a task with no time entries, where `LoggedHours` is NULL and `EntryCount` is 0. `CROSS APPLY` therefore keeps all 9 rows of project 1. Add a `GROUP BY te.TaskId` inside and the same `CROSS APPLY` would drop tasks with no entries. The `CROSS`/`OUTER` choice is not the only thing controlling row survival.

Use **inline** TVFs (`RETURNS TABLE`) — they are expanded into the outer query. **Multi-statement** TVFs (`RETURNS @t TABLE`) are opaque to the optimizer and estimate 1 row (100 from SQL Server 2017 with interleaved execution), which routinely produces catastrophic nested-loop plans.

### Use 3 — Splitting strings and JSON

```sql
-- JSON array -> rows. Task 1's metadata is {"epic":"foundation","reviewers":["grace","alan"]}
SELECT t.TaskId, r.value AS Reviewer
FROM app.Tasks AS t
CROSS APPLY OPENJSON(t.MetadataJson, N'$.reviewers') AS r
WHERE t.TaskId = 1;
-- 2 rows: grace, alan

-- Delimited string -> rows
SELECT t.TaskId, s.value AS Word
FROM app.Tasks AS t
CROSS APPLY STRING_SPLIT(t.Title, N' ') AS s
WHERE t.TaskId = 1;
-- 3 rows: Design | database | schema
```

`CROSS APPLY` here silently drops tasks whose `MetadataJson` is NULL or has no `reviewers` key. `OUTER APPLY` keeps them. Choose deliberately.

### Use 4 — Naming an expression once

```sql
-- Compute once, reuse in SELECT, WHERE and ORDER BY without repeating it
SELECT t.TaskId, t.Title, v.Epic
FROM app.Tasks AS t
CROSS APPLY (VALUES (JSON_VALUE(t.MetadataJson, N'$.epic'))) AS v (Epic)
WHERE v.Epic IS NOT NULL
ORDER BY v.Epic, t.TaskId;
```

10 rows — the tasks that carry an `epic` key.

### `APPLY` vs `JOIN` decision table

| Requirement | Use |
|---|---|
| Right side is a plain table or view, predicate is a simple equality | `JOIN` |
| Right side must see the left row's columns | `APPLY` |
| Top-N rows per parent | `CROSS APPLY` (or `ROW_NUMBER()` + filter) |
| Calling a table-valued function per row | `APPLY` (mandatory) |
| Expanding JSON / XML / delimited strings per row | `CROSS APPLY` with `OPENJSON` / `STRING_SPLIT` |
| Several aggregates from one child, one row per parent | `OUTER APPLY` with aggregates, or a pre-aggregated derived table |
| Reuse a computed expression in `WHERE` and `SELECT` | `CROSS APPLY (VALUES (…))` |
| Right side is large and unfiltered | `JOIN` — `APPLY` forces a per-row loop |

> **Performance note:** `APPLY` is executed as Nested Loops. That is excellent when the left side is small and the right side has a supporting index, and terrible when the left side has a million rows and the inner query scans. If the correlated subquery is simple, SQL Server often *decorrelates* it into a hash join — check the plan rather than assuming.

> **Portability:** `CROSS APPLY` = `CROSS JOIN LATERAL`, `OUTER APPLY` = `LEFT JOIN LATERAL … ON TRUE`. Supported in PostgreSQL 9.3+, Oracle 12c+ (which also accepts `CROSS APPLY`/`OUTER APPLY` verbatim), and MySQL 8.0.14+.

---

## 12. The Three Physical Join Operators

The optimizer picks one of three algorithms. Reading which one it chose — and why — is the core skill of query tuning.

| | **Nested Loops** | **Merge Join** | **Hash Match** |
|---|---|---|---|
| Algorithm | For each outer row, probe the inner input | Walk two sorted inputs in lockstep | Build a hash table from the smaller input, probe with the larger |
| Best when | Outer input is small **and** inner has a useful index | Both inputs already sorted on the join key | Large inputs, no useful index/order |
| Join type support | All, including non-equi | Equi-joins (plus `FULL OUTER` with sorted inputs) | **Equi-joins only** |
| Needs an index on inner | Effectively yes — otherwise it rescans | Wants sorted input (index or an explicit `Sort`) | No |
| Memory grant | Negligible | Small (large if a `Sort` is injected) | Significant; **spills to tempdb** if underestimated |
| Blocking | No | No (the feeding `Sort` blocks) | Build phase blocks |
| Complexity | O(N × cost of inner probe) | O(N + M) once sorted | O(N + M) |
| Red flag in a plan | Huge outer row count with a scan inside | An unexpected `Sort` feeding it | A yellow spill warning; or being chosen for a tiny join |

Practical readings:

- **Nested Loops over a big outer input** almost always means a missing index on the inner join column, or a cardinality underestimate.
- **Hash Match where you expected Nested Loops** usually means the optimizer thinks the outer input is large. Check statistics before adding a hint.
- **Merge Join with a Sort in front of it** means the ordering you were counting on is not there. An index in join-key order removes both the sort and its memory grant.
- **Adaptive Join** (SQL Server 2017+ for batch mode, 2019 for rowstore batch mode) defers the Hash/Nested-Loops decision to runtime based on actual row counts. If you see it, the optimizer is telling you the estimate was unreliable.

The single highest-value habit: after writing a join, look at whether the **estimated** and **actual** row counts on each operator are within an order of magnitude. Nearly every bad join plan is a cardinality-estimation failure, not an algorithm failure.

---

## 13. Join Hints — a Last Resort

```sql
-- Syntax 1: on the join itself
FROM app.Tasks AS t
INNER LOOP JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId

-- Syntax 2: query-level
OPTION (HASH JOIN)
OPTION (FORCE ORDER)
```

Reasons to avoid them:

1. A hint is a **permanent** answer to a **temporary** question. It was right for the data volume you had when you wrote it.
2. A join hint in the `FROM` clause **implicitly enables `FORCE ORDER` for the entire query**, freezing every other join too. Almost nobody expects this.
3. They mask the real problem — a stale statistic, a missing index, a non-sargable predicate, or parameter sniffing.

Try, in order: update statistics → fix the index → make predicates sargable → simplify the query → `OPTIMIZE FOR`/`RECOMPILE` → Query Store plan forcing → *then* a hint, with a code comment recording the date, the reason, and the metric that justified it.

---

## 14. Anti-Pattern Museum

### Comma joins (ANSI-89)

```sql
-- Legacy
SELECT t.TaskId, p.ProjectCode
FROM app.Tasks AS t, app.Projects AS p
WHERE p.ProjectId = t.ProjectId;
```

Identical plan to `JOIN … ON`, but join predicates and row filters are mixed in one `WHERE` clause. Delete one line and you get 280 silent rows instead of an error. Never write it; convert it whenever you touch it.

### `*=` and `=*`

```sql
-- SELECT ... FROM app.Tasks t, app.TaskAssignments ta WHERE t.TaskId *= ta.TaskId
```

The old Sybase-inherited outer join operators. They were ambiguous when combined with `WHERE` predicates, required database compatibility level 80, and **do not work on SQL Server 2012 or later**. Oracle's equivalent `(+)` is likewise superseded by ANSI syntax. If you find them in a migration, rewrite as `LEFT JOIN` and re-test — the results are not always identical.

### `MERGE` is not "merge two result sets"

Three unrelated things share the word:

| Term | What it is |
|---|---|
| **`MERGE` statement** | DML upsert: insert/update/delete a target from a source in one statement. Topic 10. Carries well-documented correctness bugs; many teams ban it. |
| **Merge Join** | A physical join operator (§12). Nothing to do with the statement. |
| **Combining two result sets vertically** | That is `UNION` / `UNION ALL` / `INTERSECT` / `EXCEPT`. Topic 08. |

Joins combine tables **horizontally** (more columns). Set operators combine them **vertically** (more rows).

---

## 15. Duplicate-Row Diagnosis Checklist

You expected one row per task and got 38. Work through this in order:

1. **State the intended grain.** "One row per task." Everything below tests that claim.
2. **Count rows per key.**
   ```sql
   SELECT t.TaskId, COUNT(*) AS Rows_
   FROM app.Tasks AS t
   JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
   JOIN app.TimeEntries     AS te ON te.TaskId = t.TaskId
   GROUP BY t.TaskId
   HAVING COUNT(*) > 1;
   ```
3. **Remove joins one at a time** until the count is right. The last one you removed is the culprit.
4. **Check each join's cardinality.** Is the right-hand column a primary key or unique constraint? If not, the join is one-to-many and *will* multiply.
5. **Check for a second one-to-many join.** Two independent children multiply against each other — this is the fan-out from Topic 05, §7.
6. **Check for a missing predicate on a composite key.** Joining `app.TeamMembers` on `TeamId` alone, forgetting `UserId`, multiplies by the team size.
7. **Check for duplicate rows in the source itself**, especially in a staging or import table with no unique constraint.
8. **Fix the cause, not the symptom.** Pre-aggregate the child, use `OUTER APPLY` with `STRING_AGG`, or convert the join to `EXISTS` if you only needed existence.

> **Anti-pattern:** Adding `DISTINCT` and moving on. It hides the multiplication for `SELECT`ed columns while leaving every `SUM` in the query wrong, and it adds a sort or hash to every execution forever.

---

## Mental Model

> A join is a **product filtered by a predicate**, and the only two questions that matter are *which rows survive* and *does the grain change*. `INNER` keeps matches; `LEFT` also keeps unmatched left rows; `FULL` keeps both sides' orphans. `ON` decides what counts as a match — it runs before outer rows are added back; `WHERE` runs after, which is why a `WHERE` predicate on the null-supplying table silently demotes your outer join to an inner one. A join to a primary key preserves the grain; a join to anything else multiplies it, and two such joins multiply against each other. When you need existence, use `EXISTS`, not a join plus `DISTINCT`; when you need absence, use `NOT EXISTS`, never `NOT IN` over a nullable column. And when the right-hand side has to see the left-hand row — top-N per group, a table-valued function, a JSON array — that is not a join at all, that is `APPLY`.

Move to [Practice Problems](./Practice-Problems.md).
