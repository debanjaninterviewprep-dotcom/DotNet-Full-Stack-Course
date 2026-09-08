# Topic 08: Set Operators

> TaskFlow needs to answer questions that are not about joining rows — they're about comparing entire **result sets**. Which users are missing from a report versus the roster? Which task IDs changed between last week's export and today's? Which labels exist in both the "active" and "archived" project buckets? `UNION`, `INTERSECT` and `EXCEPT` compare two queries as sets, not row-by-row — and they carry their own NULL rules, their own de-duplication cost, and their own place in the toolbox next to joins and `EXISTS`. This topic covers all three, the rules they share, and how to use them for real reconciliation work.

---

## 1. The Four Set Operators

| Operator | Meaning | Duplicates |
|---|---|---|
| `UNION` | Rows in either query | **Removed** |
| `UNION ALL` | Rows in either query | Kept |
| `INTERSECT` | Rows in **both** queries | Removed |
| `EXCEPT` | Rows in the first query but **not** the second | Removed |

There is no `INTERSECT ALL` or `EXCEPT ALL` in T-SQL — every one of these except `UNION ALL` de-duplicates, because they are set operations over the *distinct* rows each query produces first.

```sql
USE TaskFlowDb;
GO

-- Every distinct StatusId that appears in either Tasks or as a legal ref value:
-- trivial example -- both sides already agree, so UNION shows the shared domain.
SELECT DISTINCT t.StatusId FROM app.Tasks AS t
UNION
SELECT s.StatusId FROM ref.TaskStatuses AS s;
```

> **Portability:** Oracle spells `EXCEPT` as `MINUS` (identical semantics). PostgreSQL and MySQL 8.0.31+ support all four keywords with SQL Server's names. Older MySQL (< 8.0.31) has no `INTERSECT`/`EXCEPT` at all — you simulate them with `JOIN`/`NOT EXISTS`.

---

## 2. `UNION` vs `UNION ALL`

`UNION` runs a distinct-sort over the combined rows; `UNION ALL` does not.

```sql
-- UNION ALL: 20 + 8 = 28 rows, no sort, no dedup.
SELECT u.Email AS Contact FROM app.Users AS u
UNION ALL
SELECT p.ProjectCode FROM app.Projects AS p;

-- UNION: still 28 -- Emails and ProjectCodes never collide, so nothing was deduped
-- and you paid for a sort that changed nothing.
SELECT u.Email AS Contact FROM app.Users AS u
UNION
SELECT p.ProjectCode FROM app.Projects AS p;
```

> **Rule of thumb:** Default to `UNION ALL`. Reach for plain `UNION` only when you have proven duplicates can occur **and** you want them collapsed. Every unnecessary `UNION` is a silent sort over the entire combined set.

A realistic case where the dedup matters — combining two overlapping label sources:

```sql
-- Labels used on open tasks, UNIONed with labels used on tasks assigned to Ken Thompson.
-- Ken is assigned tasks 2, 4 and 6 (app.TaskAssignments), carrying labels
-- feature/security/bug/performance -- all four already appear on some open task,
-- so UNION collapses to the same 5 distinct labels while UNION ALL would repeat them.
SELECT l.LabelName
FROM app.TaskLabels AS tl
JOIN app.Labels AS l ON l.LabelId = tl.LabelId
JOIN app.Tasks AS t ON t.TaskId = tl.TaskId
WHERE t.StatusId NOT IN (6, 7)
UNION
SELECT l.LabelName
FROM app.TaskLabels AS tl
JOIN app.Labels AS l ON l.LabelId = tl.LabelId
JOIN app.TaskAssignments AS ta ON ta.TaskId = tl.TaskId
WHERE ta.UserId = 7;
```

---

## 3. Rules Every Set Operator Shares

1. **Same column count** on both sides.
2. **Type-compatible by ordinal position** — column 1 vs column 1, column 2 vs column 2, regardless of names. SQL Server picks a common type via [data type precedence](../02-Data-Types-and-DDL/Notes.md) if they differ (e.g. `INT` unioned with `DECIMAL` promotes to `DECIMAL`).
3. **Column names come from the first query.** The second query's aliases are ignored entirely.
4. **`ORDER BY` is legal only once, at the very end**, and it orders the *combined* result — it cannot appear inside an individual leg unless that leg is wrapped in a derived table with `TOP`.

```sql
SELECT u.UserId AS Id, u.FullName AS Label FROM app.Users AS u WHERE u.UserId = 1
UNION ALL
SELECT p.ProjectId, p.ProjectName FROM app.Projects AS p WHERE p.ProjectId = 1;
-- Column headers are "Id" and "Label" -- the second SELECT's aliases never surface.
```

```sql
-- Msg 156: Incorrect syntax near the keyword 'ORDER'.
SELECT u.UserId FROM app.Users AS u ORDER BY u.UserId
UNION ALL
SELECT p.ProjectId FROM app.Projects AS p;
```

```sql
-- Legal: exactly one ORDER BY, governing the whole combined result.
SELECT u.UserId FROM app.Users AS u
UNION ALL
SELECT p.ProjectId FROM app.Projects AS p
ORDER BY 1;
```

---

## 4. NULL Handling: Set Operators Use `IS NOT DISTINCT FROM` Semantics

This is the single most surprising rule in this topic. Ordinary `=` treats `NULL = NULL` as `UNKNOWN`. Set operators do **not** use `=` for row comparison — they use a distinctness test where **two NULLs are considered the same value**.

```sql
-- Two rows, both with a NULL EstimatedHours (tasks 8 and 18).
SELECT t.EstimatedHours FROM app.Tasks AS t WHERE t.TaskId IN (8, 18)
INTERSECT
SELECT t.EstimatedHours FROM app.Tasks AS t WHERE t.TaskId IN (18, 25);
-- Returns 1 row: NULL.
-- Contrast: WHERE t1.EstimatedHours = t2.EstimatedHours would NEVER match two NULLs.
```

```sql
SELECT NULL AS x
INTERSECT
SELECT NULL;
-- 1 row (NULL) -- proves the point outside any table.

SELECT NULL AS x
WHERE NULL = NULL;
-- 0 rows -- ordinary equality never matches NULL to NULL.
```

> **Rule of thumb:** If you need "NULL matches NULL" grouping/comparison logic, `INTERSECT`/`EXCEPT`/`UNION` already do it for you. If you need ordinary three-valued equality, use a `JOIN`/`WHERE =`, not a set operator, and be deliberate about which one the requirement actually calls for.

---

## 5. `INTERSECT`

Rows present in **both** queries, deduplicated, compared column-by-column by position.

```sql
-- Users who are BOTH a team lead (app.Teams.LeadUserId) AND a project owner
-- (app.Projects.OwnerUserId). 5 rows: Alan Turing (3), Linus Torvalds (4),
-- Margaret Hamilton (5), Barbara Liskov (6), Joan Clarke (15). Tim Berners-Lee (14)
-- owns TF-DS but leads no team, so he is the one owner excluded from the intersection.
SELECT t.LeadUserId AS UserId FROM app.Teams AS t WHERE t.LeadUserId IS NOT NULL
INTERSECT
SELECT p.OwnerUserId FROM app.Projects AS p;
```

`INTERSECT` is precedence: it binds **tighter** than `UNION`/`EXCEPT`. Mixing operators without parentheses is a readability hazard even where the precedence happens to give the right answer — always parenthesise mixed chains explicitly.

```sql
-- INTERSECT evaluates before EXCEPT here -- confirm this is really what you meant.
SELECT a.x FROM A
EXCEPT
SELECT b.x FROM B
INTERSECT
SELECT c.x FROM C;

-- Unambiguous, and the reader does not need to memorise precedence rules:
SELECT a.x FROM A
EXCEPT
(SELECT b.x FROM B INTERSECT SELECT c.x FROM C);
```

---

## 6. `EXCEPT`

Rows in the first query that do **not** appear in the second — a set difference, deduplicated both sides.

```sql
-- Users who have never been assigned a task. 6 rows: UserIds 1, 2, 3, 5, 17, 18.
SELECT u.UserId FROM app.Users AS u
EXCEPT
SELECT ta.UserId FROM app.TaskAssignments AS ta;
```

`EXCEPT` is **order-sensitive** — `A EXCEPT B` is not `B EXCEPT A`:

```sql
-- "Assigned users who are not in the Users table" -- always empty, FK guarantees it.
SELECT ta.UserId FROM app.TaskAssignments AS ta
EXCEPT
SELECT u.UserId FROM app.Users AS u;
```

### `EXCEPT` as a two-way reconciliation diff

The classic use: comparing a result set against itself across two points in time, or across two environments, to find drift.

```sql
-- Labels attached to tasks but with no corresponding row in app.Labels (should be empty --
-- FK_TaskLabels_Label guarantees it; this pattern is what you'd run WITHOUT that guarantee,
-- e.g. reconciling an export against a source system with no shared foreign keys).
SELECT tl.LabelId FROM app.TaskLabels AS tl
EXCEPT
SELECT l.LabelId FROM app.Labels AS l;

-- Two-directional diff: run both legs to see what's missing on EACH side.
SELECT LabelId FROM StagingImport.TaskLabels   -- present in staging, not yet in prod
EXCEPT
SELECT LabelId FROM app.TaskLabels;

SELECT LabelId FROM app.TaskLabels             -- present in prod, missing from staging
EXCEPT
SELECT LabelId FROM StagingImport.TaskLabels;
```

Run both directions and you have a complete reconciliation report: rows added, rows removed. This is the standard technique for regression-testing a query rewrite — run the old and new versions, `EXCEPT` each direction, and any row that surfaces is a behavioural difference.

```sql
-- Regression test: did my rewritten query change any results?
SELECT * FROM dbo.OldReportQuery
EXCEPT
SELECT * FROM dbo.NewReportQuery;
-- 0 rows expected in both directions if the rewrite is truly equivalent.

SELECT * FROM dbo.NewReportQuery
EXCEPT
SELECT * FROM dbo.OldReportQuery;
```

> **Rule of thumb:** `EXCEPT` compares *entire rows*, all columns at once. If two rows differ in even one column (a typo in a description, a stale timestamp), `EXCEPT` reports both as "different" — it cannot tell you *which* column changed. For column-level diffing, join on a key and compare column-by-column explicitly.

---

## 7. Set Operators vs Joins vs `EXISTS` — Decision Table

| Need | Best tool | Why |
|---|---|---|
| Rows in A matching rows in B, want columns from **both** | `JOIN` | Set operators only return columns from one shape, not a merge |
| Rows in A with **no** match in B (anti-join) | `NOT EXISTS` / `LEFT JOIN … IS NULL` | Correlated, NULL-safe, usually a better plan for a single-key check |
| Whole **result sets** compared, not correlated by a specific key | `EXCEPT` / `INTERSECT` | You want set difference/intersection of arbitrary shaped output, not a per-row match |
| Stacking two differently-sourced row sets into one report | `UNION ALL` | Not a comparison — just concatenation |
| "Does this specific value exist anywhere in that column" | `IN` / `EXISTS` | Cheaper than a whole-set operator for a single scalar test |
| Regression-testing whether two queries return the same rows | `EXCEPT` both directions | Purpose-built for exactly this |

`EXCEPT` behaves like an anti-join and `INTERSECT` behaves like a semi-join **when comparing on the same column list you'd join on** — the difference is that the set operators also de-duplicate and compare the *entire* projected row, while `NOT EXISTS`/`EXISTS` correlate on whatever predicate you write and can return any columns from the outer table.

```sql
-- These two return the same USER IDs (6 rows) but are not the same query:
SELECT u.UserId FROM app.Users AS u
EXCEPT
SELECT ta.UserId FROM app.TaskAssignments AS ta;

SELECT u.UserId FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.TaskAssignments AS ta WHERE ta.UserId = u.UserId);
```

The `NOT EXISTS` version can also project `u.FullName`, `u.Email`, anything else from `app.Users` — the `EXCEPT` version is locked to exactly the one column both legs agree on.

---

## 8. `UNION ALL` for Inline Lookup Sets — and the Better Alternative

`UNION ALL` of single-row `SELECT`s is a common way to fabricate a tiny inline table:

```sql
SELECT 'CRITICAL' AS Code, 4 AS SlaHours
UNION ALL SELECT 'HIGH', 24
UNION ALL SELECT 'MEDIUM', 72;
```

This works, but every leg is a separate `SELECT` the optimizer must union together. The `VALUES` **table constructor** expresses the same thing as one operator:

```sql
SELECT v.Code, v.SlaHours
FROM (VALUES ('CRITICAL', 4), ('HIGH', 24), ('MEDIUM', 72)) AS v (Code, SlaHours);
```

> **Rule of thumb:** Never `UNION ALL` a list of literal rows. Use a `VALUES` constructor — same result, one simpler plan operator, and it reads as "a table," not "three queries stapled together."

---

## 9. Combining Set Operators with CTEs

```sql
WITH ActiveAssignees AS (
    SELECT DISTINCT ta.UserId FROM app.TaskAssignments AS ta
    JOIN app.Tasks AS t ON t.TaskId = ta.TaskId
    WHERE t.StatusId NOT IN (6, 7)
),
EverAssigned AS (
    SELECT DISTINCT ta.UserId FROM app.TaskAssignments AS ta
)
-- Users who HAVE been assigned something historically, but have nothing open right now.
SELECT ea.UserId FROM EverAssigned AS ea
EXCEPT
SELECT aa.UserId FROM ActiveAssignees AS aa;
```

Each leg of a set operator can itself be arbitrarily complex — a join, a CTE reference, a windowed query wrapped in a derived table. The set operator only cares about the final column list and row shape each leg produces.

---

## 10. Performance and Execution Plans

| Plan operator | Appears for | What it does |
|---|---|---|
| **Concatenation** | `UNION ALL` | Simply appends rows from each input, no sort |
| **Merge Join (Union)** / **Sort + Distinct Sort** | `UNION` | Sorts the concatenated rows, then removes adjacent duplicates |
| **Hash Match (Union)** | `UNION` on unsorted/large inputs | Hash-based dedup instead of a sort, when no useful order exists |
| **Hash Match (Right Semi Join)** style plan | `INTERSECT` | Effectively a semi-join between the two distinct sets |
| **Hash Match (Right Anti Semi Join)** style plan | `EXCEPT` | Effectively an anti-join between the two distinct sets |

`UNION ALL` is the only one of the four operators with **zero** extra cost beyond running both legs — no sort, no hash build. This is the concrete performance reason to default to it, beyond the semantic argument in §2.

---

## 11. Portability Notes

| Feature | SQL Server | PostgreSQL | MySQL | Oracle |
|---|---|---|---|---|
| `UNION` / `UNION ALL` | Yes | Yes | Yes | Yes |
| `INTERSECT` | Yes | Yes | 8.0.31+ | Yes |
| `EXCEPT` | Yes | Yes | 8.0.31+ (`EXCEPT`) | Spelled `MINUS` |
| `INTERSECT ALL` / `EXCEPT ALL` (keep duplicates) | **No** | Yes | No | No |
| `CORRESPONDING BY` (ANSI: match legs by column name, not position) | **No** | No | No | No |

The ANSI standard defines `CORRESPONDING BY (col, …)`, letting legs list columns in different orders and matching by name. No major engine implements it — every engine matches strictly by ordinal position, which is why the "column names come from the first query" rule in §3 matters so much in practice.

---

## Mental Model

> Set operators compare **entire result sets**, not individual rows against a key — which is what makes them a different tool from a join. `UNION ALL` just concatenates and costs nothing extra; plain `UNION`, `INTERSECT` and `EXCEPT` all de-duplicate first, which means a sort or hash build you should only pay for when you have proven you need it. Their NULL rule is the opposite of ordinary `=`: two NULLs are treated as the same value, so `INTERSECT`/`EXCEPT` can match rows that a `WHERE a = b` join never would. `EXCEPT` is directional set difference — `A EXCEPT B` is not `B EXCEPT A` — and running it both ways is the standard technique for reconciling two versions of a dataset or regression-testing a query rewrite, though it compares whole rows at once and can't tell you *which* column changed. Reach for a set operator when the question is about the shape of two result sets against each other; reach for `EXISTS`/`JOIN` when the question is about matching individual rows by a specific key.

Move to [Practice Problems](./Practice-Problems.md).
