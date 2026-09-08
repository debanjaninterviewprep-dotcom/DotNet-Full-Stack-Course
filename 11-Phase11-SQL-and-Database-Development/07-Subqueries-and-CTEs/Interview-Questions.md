# Topic 07: Subqueries & CTEs — Interview Questions

---

## Q1. What is the difference between a correlated and a non-correlated subquery?
**Answer:**
A **non-correlated** subquery is self-contained — it can run on its own with no reference to the outer query, and conceptually executes once.

```sql
-- Non-correlated: runs by itself, then the outer query filters against one value.
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE t.EstimatedHours > (SELECT AVG(t2.EstimatedHours) FROM app.Tasks AS t2);
```

A **correlated** subquery references a column from the outer row, so it conceptually runs once per outer row:

```sql
-- Correlated: t2.ProjectId = t.ProjectId ties it to the current outer row.
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE t.EstimatedHours > (
    SELECT AVG(t2.EstimatedHours) FROM app.Tasks AS t2 WHERE t2.ProjectId = t.ProjectId
);
```

In practice, SQL Server frequently **decorrelates** the second form into a join or aggregate, so "once per row" describes semantics, not necessarily execution — check the plan.

---

## Q2. Why does `NOT IN` sometimes return zero rows when you expect matches?
**Answer:**
If the subquery's column contains **any** NULL, `NOT IN` returns zero rows for the entire query — silently, with no error.

```sql
-- app.Users.ManagerId has NULLs (Ada Lovelace, Guido van Rossum have no manager).
-- This returns 0 rows, not the 13 individual contributors you expect.
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);
```

`x NOT IN (a, b, NULL)` expands to `x <> a AND x <> b AND x <> NULL`. The last comparison evaluates to `UNKNOWN`, and `TRUE AND UNKNOWN` is `UNKNOWN` — never `TRUE` — so the row is excluded no matter what `x` is.

Fix with `NOT EXISTS`, which is two-valued and immune to this:

```sql
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.Users AS m WHERE m.ManagerId = u.UserId);
```

---

## Q3. Why is `EXISTS` generally preferred over `IN` for subqueries?
**Answer:**
- `EXISTS` returns `TRUE`/`FALSE` only, so it cannot be poisoned by NULLs the way `NOT IN` can.
- The subquery's `SELECT` list is never evaluated for `EXISTS` — `SELECT 1`, `SELECT *`, even `SELECT 1/0` are all equivalent, because the optimizer only asks "does at least one row exist".
- For non-correlated, NULL-free sets, `IN` and `EXISTS` typically compile to the same semi-join plan — so the difference is about **correctness**, not raw speed.

```sql
SELECT COUNT(*) FROM app.Tasks AS t
WHERE EXISTS (SELECT 1 FROM app.Comments AS c WHERE c.TaskId = t.TaskId);
```

---

## Q4. What is a derived table, and why must it always have an alias?
**Answer:**
A derived table is a subquery used in the `FROM` clause — an inline, unnamed view. SQL Server requires an alias because the outer query needs a name to qualify its columns with, and there is no implicit name to fall back on:

```sql
-- Msg 102: Incorrect syntax near ')'.
SELECT x.ProjectId FROM (SELECT t.ProjectId FROM app.Tasks AS t);

-- Correct — the alias `a` is mandatory.
SELECT a.ProjectId, a.Tasks
FROM (SELECT t.ProjectId, COUNT(*) AS Tasks FROM app.Tasks AS t GROUP BY t.ProjectId) AS a;
```

Every computed/aggregate expression inside the derived table must also be named, since the outer query references it by that name.

---

## Q5. Is a CTE materialized like a temp table?
**Answer:**
No. A non-recursive CTE is a **named subquery** — the optimizer inlines its definition wherever it is referenced. There is no storage, no statistics, and no guarantee it executes only once.

```sql
SET STATISTICS IO ON;
WITH C AS (SELECT t.ProjectId, COUNT(*) AS N FROM app.Tasks AS t GROUP BY t.ProjectId)
SELECT a.ProjectId, a.N, b.N FROM C AS a JOIN C AS b ON b.ProjectId = a.ProjectId;
-- Table 'Tasks'. Scan count 2 — the CTE body ran twice, once per reference.
```

Referencing the same CTE ten times executes its definition ten times. If a CTE is expensive and reused, materialize it explicitly into a `#temp` table instead.

---

## Q6. What is the terminating-semicolon rule for CTEs, and why does it exist?
**Answer:**
`WITH` must be the first statement in a batch, or the previous statement must end with a semicolon:

```sql
DECLARE @x INT = 1
WITH C AS (SELECT 1 AS n) SELECT n FROM C;
-- Msg 319: Incorrect syntax near the keyword 'with'. ... the previous statement
-- must be terminated with a semicolon.
```

The parser needs an unambiguous boundary to know a new statement — potentially a CTE — is starting, since `WITH` is also used elsewhere (`XMLNAMESPACES`, change tracking). The defensive habit is to terminate **every** statement with `;`, which Microsoft recommends generally since omitting it is deprecated.

---

## Q7. Can you use a CTE with `INSERT`, `UPDATE`, or `DELETE`?
**Answer:**
Yes — a CTE is not read-only. This is the standard way to de-duplicate rows using `ROW_NUMBER`:

```sql
WITH Dupes AS (
    SELECT tl.TaskId, tl.LabelId,
           ROW_NUMBER() OVER (PARTITION BY tl.TaskId ORDER BY tl.LabelId) AS rn
    FROM app.TaskLabels AS tl
)
DELETE FROM Dupes WHERE rn > 1;
```

The CTE's scope is still just this one statement — you cannot reference `Dupes` again afterward.

---

## Q8. What is the difference between a CTE, a derived table, and a `#temp` table? When would you pick each?
**Answer:**

| | CTE | Derived table | `#temp` table |
|---|---|---|---|
| Materialized | No | No | Yes |
| Referenced twice | Runs twice | Must be repeated verbatim | Written once, read many |
| Statistics | Inherited from base tables | Inherited | Full, auto-created |
| Supports recursion | Yes | No | No |
| Reusable across statements | No (one statement only) | No | Yes (session/batch) |

Pick a **derived table** for a one-off nested query used once. Pick a **CTE** to name that same nesting for readability, or when you need recursion (nothing else supports it). Pick a **`#temp` table** when the intermediate result is expensive to compute **and** is read more than once — the physical materialization and real statistics pay for themselves.

---

## Q9. Write a recursive CTE to find all direct and indirect reports of a manager.
**Answer:**
```sql
WITH Reports AS (
    SELECT u.UserId, u.FullName, u.ManagerId, 1 AS Depth
    FROM app.Users AS u
    WHERE u.ManagerId = 2                 -- Grace Hopper's direct reports seed the walk

    UNION ALL

    SELECT u.UserId, u.FullName, u.ManagerId, r.Depth + 1
    FROM app.Users AS u
    JOIN Reports AS r ON r.UserId = u.ManagerId
)
SELECT UserId, FullName, Depth
FROM Reports
OPTION (MAXRECURSION 20);
```

The anchor seeds generation 1 (direct reports). The recursive member joins `app.Users` back to `Reports` on `ManagerId = UserId`, pulling in the next generation until no more rows match.

---

## Q10. What restrictions does SQL Server place on the recursive member of a recursive CTE?
**Answer:**
The recursive member may **not** contain:

| Restriction | Error if violated |
|---|---|
| `UNION` instead of `UNION ALL` | Msg 252 |
| `LEFT`/`RIGHT`/`FULL OUTER JOIN` to the CTE itself | Msg 462 |
| `GROUP BY`, `HAVING`, or an aggregate | Msg 467 |
| `TOP` or `OFFSET` | Msg 461 |
| More than one reference to the CTE | Msg 253 |
| `SELECT DISTINCT` | Msg 460 |

The recursive member also sees only the **immediately preceding generation**, never the accumulated total — any running total (depth, path) must be carried forward explicitly as a column.

---

## Q11. What does `MAXRECURSION` control, and what is the default?
**Answer:**
It caps how many times the recursive member can re-execute before SQL Server aborts the statement. The default is **100**. `OPTION (MAXRECURSION 0)` means unlimited, and `OPTION (MAXRECURSION n)` sets an explicit ceiling. The hint goes on the **outer** statement, never inside the CTE body.

```sql
WITH N AS (SELECT 1 AS n UNION ALL SELECT n + 1 FROM N WHERE n < 500)
SELECT COUNT(*) FROM N OPTION (MAXRECURSION 0);   -- without this: Msg 530 at 100
```

> Setting `MAXRECURSION 0` on untrusted or unvalidated hierarchical data is dangerous — a cyclic reference will spin until tempdb fills, rather than failing fast.

---

## Q12. How would you detect a cycle in hierarchical data using a recursive CTE?
**Answer:**
Carry a delimited "visited" path forward and stop expanding once a node reappears in its own ancestry:

```sql
WITH Walk AS (
    SELECT ChildId, ParentId, 1 AS Depth,
           CAST('|' + CAST(ChildId AS VARCHAR(10)) + '|' AS VARCHAR(4000)) AS Visited,
           0 AS IsCycle
    FROM Edges WHERE ChildId = 101

    UNION ALL

    SELECT e.ChildId, e.ParentId, w.Depth + 1,
           CAST(w.Visited + CAST(e.ChildId AS VARCHAR(10)) + '|' AS VARCHAR(4000)),
           CASE WHEN w.Visited LIKE '%|' + CAST(e.ChildId AS VARCHAR(10)) + '|%' THEN 1 ELSE 0 END
    FROM Edges AS e
    JOIN Walk AS w ON w.ParentId = e.ChildId
    WHERE w.IsCycle = 0
)
SELECT * FROM Walk;
```

The `WHERE w.IsCycle = 0` guard stops expanding a branch the moment it revisits a node, so the query terminates on its own even over cyclic data — you never need to rely on `MAXRECURSION` as the safety net. Delimiters (`|101|`) around each id are essential, or substring matching produces false positives (`1` matching inside `101`).

---

## Q13. What is the difference between `x > ALL (subquery)` and `x > ANY (subquery)`?
**Answer:**
`x > ALL (S)` means `x` is greater than **every** value in `S` — equivalent to `x > MAX(S)`. `x > ANY (S)` (a synonym of `SOME`) means `x` is greater than **at least one** value — equivalent to `x > MIN(S)`.

```sql
-- ALL: 0 rows if S contains a NULL (conjunction poisoned by UNKNOWN).
WHERE t.EstimatedHours > ALL (SELECT q.EstimatedHours FROM app.Tasks AS q WHERE q.ProjectId = 5)

-- ANY: survives a NULL in S as long as one real comparison succeeds (disjunction).
WHERE t.EstimatedHours > ANY (SELECT q.EstimatedHours FROM app.Tasks AS q WHERE q.ProjectId = 5)
```

`ALL` is internally a conjunction (`AND` across every row); `ANY` is a disjunction (`OR` across every row) — which is exactly why `ALL` inherits the same NULL fragility as `NOT IN`, and `ANY` does not.

---

## Q14. Why can't you reference a `SELECT`-list column alias inside a `WHERE` clause, but you can in `ORDER BY`?
**Answer:**
Logical query processing evaluates `WHERE` **before** `SELECT`, so the alias does not exist yet when `WHERE` is evaluated. `ORDER BY` runs **after** `SELECT`, so the alias is already in scope.

```sql
SELECT t.EstimatedHours * 1.15 AS Padded
FROM app.Tasks AS t
WHERE Padded > 20;              -- Msg 207: Invalid column name 'Padded'.

SELECT t.EstimatedHours * 1.15 AS Padded
FROM app.Tasks AS t
ORDER BY Padded;                 -- Works fine.
```

To filter on a computed expression, either repeat the expression in `WHERE` or wrap the query in a CTE/derived table and filter the outer query against the now-materialized-as-a-name column.

---

## Q15. Your correlated subquery contains `TOP (1) … ORDER BY`. Why might that block SQL Server from decorrelating it, and what's the performance impact?
**Answer:**
Decorrelation rewrites a correlated subquery into a join or aggregate so the child table is scanned once instead of once per outer row. `TOP` and `ORDER BY` impose a specific per-row *order and limit* semantic that the optimizer generally cannot fold into a set-based join — so it falls back to a nested-loop, executing the subquery once per outer row.

```sql
-- Will not decorrelate: TOP + ORDER BY forces a per-row lookup.
SELECT t.TaskId,
       (SELECT TOP (1) te.WorkDate FROM app.TimeEntries AS te
        WHERE te.TaskId = t.TaskId ORDER BY te.WorkDate DESC) AS LastWorked
FROM app.Tasks AS t;
```

For a small outer row count this is harmless. For a large one, it is O(n) subquery executions. The fix, when you need more than one "latest row" column, is `CROSS APPLY`/`OUTER APPLY` with `TOP (1) … ORDER BY` inside — same semantics, but expressed as a row-set operator the optimizer plans holistically rather than a scalar expression it must re-run per row.

---

## Q16. What's wrong with this query, and how would you fix it?
```sql
SELECT p.ProjectCode
FROM app.Projects AS p
WHERE p.ProjectId IN (SELECT ta.TaskId, ta.UserId FROM app.TaskAssignments AS ta);
```
**Answer:**
Msg 116 — `IN` only accepts a single-column subquery in T-SQL (unlike PostgreSQL/MySQL, which support row-value constructors). Also, semantically, comparing `ProjectId` against a mix of `TaskId`/`UserId` values makes no sense — the subquery needs to actually resolve to project ids:

```sql
SELECT p.ProjectCode
FROM app.Projects AS p
WHERE EXISTS (
    SELECT 1 FROM app.Tasks AS t
    JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
    WHERE t.ProjectId = p.ProjectId
);
```

`EXISTS` with an explicit correlation replaces the illegal multi-column `IN` and is also NULL-safe.

---

## Q17. Explain the difference in behavior between `WITH C (a, b) AS (...)` and `WITH C AS (SELECT x AS a, y AS b ...)`.
**Answer:**
Both name the CTE's output columns `a` and `b` — the difference is *where* naming happens. The external column-list form (`WITH C (a, b) AS (...)`) names columns **outside** the inner query, which is mandatory when the inner `SELECT` produces an unnamed expression (e.g. a literal, or an unaliased computation):

```sql
-- Requires the external list: `1 + 1` has no name of its own.
WITH C (Total) AS (SELECT 1 + 1)
SELECT Total FROM C;
```

Aliasing inside the `SELECT` list (`SELECT x AS a`) is usually preferred for readability, since the column name sits next to the expression it names.

---

## Q18. A junior developer says "I'll just replace this slow correlated subquery with a CTE — CTEs are faster." Is this correct?
**Answer:**
No. A non-recursive CTE is inlined exactly like a derived table or a subquery — there is no inherent performance advantage. Renaming a correlated subquery as a CTE does not decorrelate it or change the plan at all:

```sql
-- Still a correlated subquery under the hood — same plan as the raw subquery version.
WITH PerTask AS (
    SELECT t.TaskId,
           (SELECT AVG(t2.EstimatedHours) FROM app.Tasks AS t2 WHERE t2.ProjectId = t.ProjectId) AS ProjAvg
    FROM app.Tasks AS t
)
SELECT * FROM PerTask;
```

Real performance work means checking the actual plan for a Nested Loops with a per-row inner scan, then rewriting as a join/aggregate or an `APPLY`, or materializing into a `#temp` table if the CTE is referenced multiple times (each reference re-executes the definition).

---

## Q19. How do you build a reusable "number series" without recursion, and why might you prefer that over a recursive CTE for large ranges?
**Answer:**
Cross-join small `VALUES` blocks to generate rows combinatorially instead of one row per recursion level:

```sql
WITH L0 AS (SELECT 1 AS c FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS v(c)),
     L1 AS (SELECT 1 AS c FROM L0 AS a CROSS JOIN L0 AS b),          -- 100
     L2 AS (SELECT 1 AS c FROM L1 AS a CROSS JOIN L1 AS b),          -- 10,000
     Nums AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM L2)
SELECT n FROM Nums WHERE n <= 1000;
```

A recursive CTE for 1,000 rows means 1,000 sequential re-executions of the recursive member (an O(n) spool). The cross-join approach doubles the row count per level, reaching 10,000 rows in just 3 joins — no `MAXRECURSION` limit involved, and typically a much cheaper plan for large ranges.

---

## Q20. Design question: you need a "roll-up" report showing, for every top-level task, the total estimated hours across itself and all descendants. Walk through your approach.
**Answer:**
1. Identify the self-referencing key: `app.Tasks.ParentTaskId` → `app.Tasks.TaskId`.
2. Write a recursive CTE anchored on root tasks (`ParentTaskId IS NULL`), carrying the **root task id** forward as a column through every recursive generation — this is what makes grouping possible afterward.
3. `UNION ALL` the recursive member joining child rows to the previous generation.
4. `GROUP BY` the carried root id in the final `SELECT`, aggregating `SUM(EstimatedHours)` and `COUNT(*)`.

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
GROUP BY r.TaskId, r.Title;
```

Considerations to raise in an interview: index `ParentTaskId` (foreign keys are not auto-indexed), guard against cycles even though a well-formed tree shouldn't have any, and decide whether `NULL` `EstimatedHours` values on leaf tasks should be treated as zero (`ISNULL`) or should make the whole rollup `NULL` (the default `SUM` behavior, which silently ignores NULLs rather than propagating them).
