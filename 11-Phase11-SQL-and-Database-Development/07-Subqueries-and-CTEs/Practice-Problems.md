# Topic 07: Subqueries & CTEs — Practice Problems

> Seven exercises that move from scalar subqueries to recursive tree walks. Every problem runs against the seeded `TaskFlowDb`. Write your `.sql` answer files in `PracticeProblemsSolutions/`.

**Concept tags:** `scalar-subquery` `in-any-all` `exists` `not-in-null-trap` `correlated-subquery` `derived-table` `cte` `recursive-cte` `cycle-detection`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Scalar Subqueries & the "More Than One Value" Trap  *(Easy)*

**Tags:** `scalar-subquery` `error-512`

### Requirements

1. Write a query that lists every task's `TaskId`, `Title`, `EstimatedHours`, and the **global average** `EstimatedHours` as a scalar subquery column.
2. Add a column `Delta` = the task's estimate minus the global average.
3. Deliberately write a scalar subquery that returns more than one row (e.g. `(SELECT FullName FROM app.Users WHERE CountryCode = 'GB')`) and capture the exact error message and number.
4. Fix it two ways: (a) aggregate the subquery, (b) restructure using `TOP (1) … ORDER BY` with an explicit, justified tiebreaker.

### Deliverable

`P1-scalar-subqueries.sql` with all four parts, the captured error as a comment, and a one-line comment explaining why `TOP (1)` **without** `ORDER BY` would have been wrong.

### Hints

- `AVG` ignores NULL `EstimatedHours` rows — decide whether that is what you want.
- Msg 512 is a **runtime** error — it will not show up until the data has two matching rows.

### Look-fors (rubric)

- [ ] Correct global average and per-row delta.
- [ ] The multi-row error is reproduced and the message is pasted verbatim.
- [ ] Both fixes are provided and both run without error.
- [ ] Explains why unguarded `TOP (1)` is an anti-pattern.

---

## P2 — `IN`, `ANY`, `ALL` and the Empty-Set Rules  *(Easy)*

**Tags:** `in` `any` `all` `empty-set`

### Requirements

1. List tasks belonging to any project owned by Margaret Hamilton (`UserId` 5), using `IN`.
2. Rewrite the same query using `= ANY`.
3. Using `> ALL`, find tasks whose `EstimatedHours` exceeds every task in project 5 (`TF-QA`) — run it once unguarded (include NULL estimates in the subquery) and once with `EstimatedHours IS NOT NULL` added to the subquery. Compare row counts and explain the difference in a comment.
4. Write one query where the subquery matches **zero rows**, for each of: `IN`, `NOT IN`, `= ANY`, `> ALL`, `EXISTS`, `NOT EXISTS`. State the boolean result of each in a comment without running a `COUNT` — then verify.

### Deliverable

`P2-in-any-all.sql`.

### Hints

- `> ALL (∅)` is vacuously `TRUE` — this trips up almost everyone the first time.
- Use a `CountryCode` that does not exist (e.g. `'ZZ'`) to build an empty subquery cheaply.

### Look-fors (rubric)

- [ ] `IN` and `= ANY` return identical row sets.
- [ ] The guarded vs unguarded `ALL` difference is explained, not just observed.
- [ ] All six empty-set predictions match their actual results.

---

## P3 — The `NOT IN` NULL Trap  *(Medium)*

**Tags:** `not-in` `null` `exists` `left-join-anti`

### Requirements

1. Write a query using `NOT IN` to find users who are **not** a manager (i.e., nobody reports to them), querying against `app.Users.ManagerId`. Run it and record the row count.
2. Explain in a comment, referencing three-valued logic, exactly why that row count is wrong.
3. Fix it three ways: `NOT EXISTS`, `LEFT JOIN … IS NULL`, and `NOT IN` with an explicit `IS NOT NULL` guard. Confirm all three return the same 13 rows.
4. Build a table comment (`-- | Approach | NULL-safe | Rows |`) summarising all four attempts.

### Deliverable

`P3-not-in-null-trap.sql`.

### Hints

- `app.Users.ManagerId` is nullable, and two rows are top-level (no manager).
- Do not filter `WHERE ManagerId IS NOT NULL` on the *outer* query — that changes the question being asked.

### Look-fors (rubric)

- [ ] The broken `NOT IN` version is kept in the file (commented as broken), not deleted.
- [ ] All three fixes agree on exactly 13 rows.
- [ ] The explanation names `UNKNOWN`/three-valued logic specifically, not just "NULLs are weird".

---

## P4 — Correlated Subqueries vs `APPLY`  *(Medium)*

**Tags:** `correlated-subquery` `decorrelation` `apply`

### Requirements

1. Write a correlated subquery that returns tasks whose `EstimatedHours` exceeds the **average for their own project** (not the global average).
2. Using `SET STATISTICS IO ON` (or the actual execution plan), determine whether SQL Server decorrelated your query into a join/aggregate or is looping per row. Paste the relevant plan operator name as a comment.
3. Write a query that pulls three measures from `app.TimeEntries` per task — entry count, total hours, most recent work date — first as three separate correlated scalar subqueries, then as a single `OUTER APPLY`. Confirm both give identical results.
4. In a comment, state the rule for when to escalate from a correlated subquery to `APPLY`.

### Deliverable

`P4-correlated-vs-apply.sql`.

### Hints

- `SET STATISTICS IO ON;` then look for `Scan count` in the messages tab.
- `OUTER APPLY`, not `CROSS APPLY`, so tasks with zero time entries are still returned.

### Look-fors (rubric)

- [ ] Per-project average query returns 12 rows (differs from the 11-row global-average version in Notes.md).
- [ ] Plan evidence (not a guess) backs the decorrelation claim.
- [ ] The three-subqueries and one-`APPLY` versions return identical values for every task.

---

## P5 — Derived Tables vs CTE Chains  *(Medium)*

**Tags:** `derived-table` `cte` `readability`

### Requirements

1. Write a single deeply nested query (three levels of subquery in `FROM`) that returns, per project with 3 or more **open** tasks (`StatusId NOT IN (6, 7)`), the project code and the open task count.
2. Rewrite the identical query as a three-step CTE chain, each step named for what it does.
3. Compare the actual execution plans of both versions and state in a comment whether they differ.
4. Explain in 2–3 sentences (as a comment) why the CTE chain is preferable even when the plan is identical.

### Deliverable

`P5-derived-vs-cte.sql`.

### Hints

- `StatusId` is `NOT NULL`, so `NOT IN (6, 7)` is safe here — say why that safety matters given P3.
- Name each CTE step after its output, not "Step1"/"Step2".

### Look-fors (rubric)

- [ ] Both versions return identical rows.
- [ ] Plan comparison is stated, not assumed.
- [ ] Readability argument references debuggability (selecting from an intermediate CTE), not just "it looks nicer".

---

## P6 — Recursive CTE: Full Org Chart with Depth and Path  *(Hard)*

**Tags:** `recursive-cte` `self-join` `hierarchy` `maxrecursion`

### Requirements

1. Write a recursive CTE over `app.Users`/`ManagerId` that produces every employee with `Depth` and a human-readable `Chain` (e.g. `Ada Lovelace > Alan Turing > Barbara Liskov`).
2. Add a zero-padded `SortPath` column and order the final output by it so the tree renders correctly indented.
3. Cap the recursion with an explicit, justified `MAXRECURSION` value (not 0).
4. Modify the anchor to produce **only** the subtree under Grace Hopper (`UserId` 2) and confirm the row count (12).
5. Modify the query again to walk **upward** from Hedy Lamarr (`UserId` 16) to the root, and explain in a comment which single change (anchor or join direction) made that possible.

### Deliverable

`P6-org-chart-recursive.sql` with all five parts as separate, labelled statement batches.

### Hints

- Two users have no manager: Ada Lovelace and Guido van Rossum — the full-company anchor must include both.
- Walking up means swapping which side of the join carries the CTE: `u.UserId = oc.ManagerId` instead of `oc.UserId = u.ManagerId`.

### Look-fors (rubric)

- [ ] Full org chart returns 20 rows across 4 depth levels.
- [ ] `SortPath` keeps every subtree contiguous when sorted (spot-check one branch).
- [ ] Subtree-under-Grace-Hopper returns exactly 12 rows.
- [ ] Ancestor walk from Hedy Lamarr returns exactly 4 rows, terminating at Ada Lovelace.

---

## P7 — Cycle Detection and a Rolled-Up Task Tree  *(Hard)*

**Tags:** `recursive-cte` `cycle-detection` `rollup`

### Requirements

1. Using `app.Tasks.ParentTaskId`, write a recursive CTE that, for **every** root task, returns the root's `TaskId`, `Title`, the count of nodes in its subtree, and the `SUM` of `EstimatedHours` across the whole subtree (root + descendants).
2. Confirm task 1 ("Design database schema") rolls up to 3 nodes and 40.00 hours, and task 10 rolls up to 3 nodes and 62.00 hours.
3. Build a small synthetic edge list with `VALUES` that contains a genuine cycle (three nodes each pointing to the next, looping back), and write a recursive CTE with a visited-path column that detects and stops on the cycle **without** relying on `MAXRECURSION` to bail you out.
4. In a markdown-comment table, list the four debugging steps you would take if a recursive CTE against production data hung.

### Deliverable

`P7-cycle-detection-and-rollup.sql`.

### Hints

- Carry the **root task id** forward through every generation so you can `GROUP BY` it at the end.
- Delimit the visited-path entries (e.g. `|101|103|`) — undelimited substring matching gives false positives (`1` matching `101`).

### Look-fors (rubric)

- [ ] Roll-up totals match exactly (3 nodes/40.00 for task 1; 3 nodes/62.00 for task 10).
- [ ] The synthetic cycle query terminates on its own and correctly flags the repeated node.
- [ ] Debugging checklist is specific (not "check the data") and matches the techniques from Notes.md §14.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every deliberately-broken query (P1's Msg 512, P3's `NOT IN`) is kept as a commented-out reproduction, not deleted.
- [ ] No query hard-codes a row count as a literal instead of computing it — comments may state the *expected* count for verification.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Rewrite P6's org chart as an **ancestors-and-descendants-in-one-query** using two recursive CTEs unioned together.
- Build a generic `dbo.ufn_TaskSubtree(@TaskId)` inline table-valued function wrapping P7's rollup logic, then call it with `CROSS APPLY` for every root task in one statement.
- Read about PostgreSQL's `AS MATERIALIZED` CTE hint and write two sentences on when SQL Server's lack of an equivalent hint would force you to use a `#temp` table instead.
