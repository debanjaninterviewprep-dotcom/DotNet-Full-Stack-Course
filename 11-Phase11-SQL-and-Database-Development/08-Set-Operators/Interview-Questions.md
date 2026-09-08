# Topic 08: Set Operators — Interview Questions

---

## Q1. What is the difference between `UNION` and `UNION ALL`?
**Answer:**
`UNION` removes duplicate rows from the combined result, which requires a sort or hash operation over the whole set. `UNION ALL` simply concatenates both inputs with no dedup step.

```sql
SELECT u.Email FROM app.Users AS u
UNION ALL
SELECT p.ProjectCode FROM app.Projects AS p;   -- 20 + 8 = 28 rows, no sort
```

Because `Email` values and `ProjectCode` values never collide in this example, `UNION` would also return 28 rows here — but it would still pay for a distinct-sort that changed nothing. The default choice should be `UNION ALL` unless you have specifically proven duplicates can occur and need to be collapsed.

---

## Q2. What rules must both sides of a `UNION` satisfy?
**Answer:**
- The same **number of columns**.
- **Type-compatible columns by ordinal position** (column 1 with column 1, etc.) — not by name.
- Only the **first** query's column names/aliases appear in the final result.
- `ORDER BY` is legal exactly once, at the very end, governing the combined result — not inside an individual leg.

```sql
SELECT u.UserId AS Id FROM app.Users AS u
UNION ALL
SELECT p.ProjectId FROM app.Projects AS p;
-- The result column is named "Id" regardless of what the second SELECT calls it.
```

---

## Q3. How do `UNION`, `INTERSECT`, and `EXCEPT` treat NULL differently from an ordinary `=` comparison?
**Answer:**
Set operators use a "distinctness" comparison where two NULLs are considered **the same value** — unlike `=`, where `NULL = NULL` evaluates to `UNKNOWN` and never matches.

```sql
SELECT NULL AS x INTERSECT SELECT NULL;   -- 1 row: NULL
SELECT 1 WHERE NULL = NULL;               -- 0 rows
```

This means `INTERSECT`/`EXCEPT` can match or exclude rows containing NULLs in ways a `JOIN … ON a.col = b.col` never would — a frequent source of confusion when someone assumes the two are interchangeable.

---

## Q4. What does `EXCEPT` do, and why does the order of the two queries matter?
**Answer:**
`EXCEPT` returns rows from the first query that do **not** appear in the second, de-duplicated. It is a directional set difference — `A EXCEPT B` is not the same as `B EXCEPT A`.

```sql
-- Users with no task assignment. 6 rows.
SELECT u.UserId FROM app.Users AS u
EXCEPT
SELECT ta.UserId FROM app.TaskAssignments AS ta;

-- Assigned user ids missing from Users -- always empty; the foreign key guarantees it.
SELECT ta.UserId FROM app.TaskAssignments AS ta
EXCEPT
SELECT u.UserId FROM app.Users AS u;
```

Oracle spells the same operator `MINUS`.

---

## Q5. How would you use `EXCEPT` to regression-test a query rewrite?
**Answer:**
Run the old and new versions of the query and diff them in both directions. If both directions return zero rows, the two queries produce identical result sets:

```sql
SELECT * FROM dbo.OldReportQuery
EXCEPT
SELECT * FROM dbo.NewReportQuery;      -- rows only the OLD query produced

SELECT * FROM dbo.NewReportQuery
EXCEPT
SELECT * FROM dbo.OldReportQuery;      -- rows only the NEW query produced
```

The limitation: `EXCEPT` compares whole rows. If a row differs in only one column, the entire row is reported as "different" on both sides — it cannot isolate which column changed.

---

## Q6. What is the practical difference between `INTERSECT` and an `INNER JOIN`?
**Answer:**
`INTERSECT` compares **entire projected rows** across two queries and de-duplicates; it only returns the columns common to the comparison, not a merge of both sides' columns. An `INNER JOIN` correlates on an explicit key and can return columns from **both** tables.

```sql
-- INTERSECT: only the matching UserId values, one column, deduplicated.
SELECT t.LeadUserId FROM app.Teams AS t WHERE t.LeadUserId IS NOT NULL
INTERSECT
SELECT p.OwnerUserId FROM app.Projects AS p;

-- JOIN: can also pull FullName, Email, etc. from app.Users.
SELECT DISTINCT u.UserId, u.FullName
FROM app.Teams AS t
JOIN app.Projects AS p ON p.OwnerUserId = t.LeadUserId
JOIN app.Users AS u ON u.UserId = t.LeadUserId;
```

Use `INTERSECT` when the question really is "which rows appear in both sets," not "give me a combined row of data from both tables."

---

## Q7. Why is `UNION ALL` of several single-row `SELECT` statements considered an anti-pattern for building a small lookup table, and what should you use instead?
**Answer:**
Each `SELECT` is a separate query the optimizer must plan and then concatenate — more machinery than necessary for what is conceptually just a literal table. The `VALUES` table constructor expresses the same thing as a single row-source operator:

```sql
-- Works, but is several queries stapled together.
SELECT 'CRITICAL' AS Code, 4 AS SlaHours
UNION ALL SELECT 'HIGH', 24
UNION ALL SELECT 'MEDIUM', 72;

-- Preferred: one table constructor.
SELECT v.Code, v.SlaHours
FROM (VALUES ('CRITICAL', 4), ('HIGH', 24), ('MEDIUM', 72)) AS v (Code, SlaHours);
```

---

## Q8. Does SQL Server support `INTERSECT ALL` or `EXCEPT ALL` (i.e., set operations that preserve duplicates)?
**Answer:**
No. Every T-SQL set operator except `UNION ALL` de-duplicates. If you need multiset semantics (preserving duplicate counts) for an intersection or difference, you must simulate it — typically by numbering duplicates with `ROW_NUMBER() OVER (PARTITION BY <all columns> ORDER BY (SELECT NULL))` on each side first, then comparing on the numbered rows so that duplicate instances are treated as distinct.

---

## Q9. What is the operator precedence between `UNION`, `INTERSECT`, and `EXCEPT`, and why should you not rely on it?
**Answer:**
`INTERSECT` binds tighter than `UNION` and `EXCEPT`, which are evaluated left-to-right relative to each other. Relying on this in a mixed chain is a readability hazard — a future reader (or your future self) has to recall the precedence table to know what the query actually does:

```sql
-- INTERSECT evaluates first here, which may or may not be intended.
SELECT * FROM A EXCEPT SELECT * FROM B INTERSECT SELECT * FROM C;

-- Unambiguous:
SELECT * FROM A EXCEPT (SELECT * FROM B INTERSECT SELECT * FROM C);
```

Always parenthesize a mixed chain explicitly, even when the default precedence happens to already give the answer you want.

---

## Q10. A colleague says "let's just `UNION` these two queries to combine the projects table with the tasks table into one report." What's the concern?
**Answer:**
`UNION`/`UNION ALL` **stack** rows vertically — they require the same column count and compatible types by position; they do not merge different tables' columns side by side. Combining `app.Projects` and `app.Tasks` "into one report" almost always means the requirement is a **join** (correlating by `ProjectId`), not a set operator. Set operators are the right tool only when both queries already produce the *same shape* of row and you want to stack, intersect, or diff those shapes — not when you want project columns and task columns to appear together on the same output row.

---

## Q11. Explain what plan operator appears for `UNION ALL` versus plain `UNION`, and why that matters for performance.
**Answer:**
`UNION ALL` typically produces a **Concatenation** operator — it just appends rows from each input stream with no additional work. Plain `UNION` requires either a **Sort + Distinct Sort** or a **Hash Match (Union)** to remove duplicates across the combined set. That extra sort/hash is real CPU and possibly tempdb spill cost on large inputs — cost you pay even when, as in many real queries, no actual duplicates exist to remove.

---

## Q12. How do `EXCEPT` and `NOT EXISTS` differ when both are used to find "rows in A missing from B"?
**Answer:**

| | `EXCEPT` | `NOT EXISTS` |
|---|---|---|
| Compares | Whole projected row, all columns at once | Whatever correlation predicate you write |
| Can return extra columns from A | No — locked to the columns in the `SELECT` list being compared | **Yes** — any column from the outer table |
| De-duplicates | Always | No (unless you add `DISTINCT`) |
| NULL handling | Distinctness (NULL = NULL) | Ordinary predicate logic — you must guard NULLs yourself |

```sql
-- EXCEPT: only UserId comes back, deduplicated.
SELECT u.UserId FROM app.Users AS u
EXCEPT
SELECT ta.UserId FROM app.TaskAssignments AS ta;

-- NOT EXISTS: same 6 UserIds, but you can also select FullName, Email, etc.
SELECT u.UserId, u.FullName, u.Email
FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.TaskAssignments AS ta WHERE ta.UserId = u.UserId);
```

Prefer `NOT EXISTS` when you need more than the key column back, or when the correlation isn't a simple whole-row comparison. Prefer `EXCEPT` when you are literally diffing two same-shaped result sets (e.g. two versions of a report).

---

## Q13. Design question: you need to reconcile a nightly export table against the live `app.Tasks` table to detect drift (rows added, removed, or changed) for an ETL pipeline. How would you use set operators to build this?
**Answer:**
1. Select the same column list from both the export table and `app.Tasks`, in the same order and types.
2. Run `EXCEPT` from export → live to find rows present in the export but missing/changed in live (would-be deletions or updates since the export).
3. Run `EXCEPT` from live → export to find rows present live but missing/changed in the export (would-be insertions or updates since the export).
4. Because `EXCEPT` compares whole rows, any single-column change (e.g. a `Title` edit) causes that row to appear in **both** directions — one row "removed", one row "added" — which is the expected signature of an update rather than a genuine add/delete. Distinguish updates from true adds/deletes by also comparing just the primary key column(s) with a separate `INTERSECT`/`EXCEPT` pass, or by joining on the key and comparing non-key columns explicitly.
5. For production robustness, wrap the whole comparison in a stored procedure parameterized by table/schema name, and alert only when the reconciliation returns a non-empty result, rather than running full diffs manually.

The key interview point: `EXCEPT` alone tells you rows differ, not *how* — a real reconciliation pipeline usually needs a keyed join in addition to the set-operator diff to classify the drift as insert/update/delete.
