# Topic 06: Joins & APPLY — Practice Problems

> Eight exercises that walk from a two-table inner join to correlated `APPLY` and plan reading. Several problems deliberately ask you to write a **wrong** query first and then explain the failure — that is the fastest way to make the `ON`/`WHERE` distinction and the `NOT IN` NULL trap permanent. Every problem runs against the shared **TaskFlowDb** sample database.

**Concept tags:** `inner-join` `left-join` `full-outer-join` `cross-join` `on-vs-where` `self-join` `anti-join` `semi-join` `not-in-null-trap` `many-to-many` `non-equi-join` `cross-apply` `outer-apply` `execution-plans`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Put each answer in `PracticeProblemsSolutions/Pn-*.sql`. Starter files with the problem statement are already there.

---

## P1 — Task Roster  *(Easy)*

**Tags:** `inner-join` `left-join` `row-counts`

### Requirements

1. **Query A (inner):** one row per task/assignee pair with `TaskId`, `Title`, `ProjectCode`, `StatusName`, `PriorityName`, `AssigneeName`. Join `app.Tasks`, `app.Projects`, `ref.TaskStatuses`, `ref.Priorities`, `app.TaskAssignments`, `app.Users`. State the row count before you run it, then verify.
2. **Query B (outer):** the same query with the assignee side made outer, so unassigned tasks still appear with `'(unassigned)'` instead of NULL. State and verify the row count.
3. **Query C:** the difference — list the `TaskId` and `Title` of every task that appears in B but not A.
4. Add a comment stating which of the six joins are many-to-one (grain-preserving) and which is one-to-many (grain-changing), and how you can tell from the schema alone.

### Deliverable

`P1-task-roster.sql`

### Hints

- The grain-changing join is the one whose right-hand side does **not** have the join column as a whole primary key.
- `ISNULL(u.FullName, N'(unassigned)')`.
- Query C is an anti-join; you will formalise it in P2.

### Look-fors (rubric)

- [ ] Query A returns 31 rows; Query B returns 39; Query C returns 8.
- [ ] Query C lists exactly tasks 8, 18, 22, 26, 27, 29, 30, 33.
- [ ] The chain from `app.TaskAssignments` to `app.Users` is `LEFT JOIN` in query B — not `INNER`.
- [ ] The comment correctly identifies `app.TaskAssignments` as the one-to-many join, justified by its composite primary key `(TaskId, UserId)`.
- [ ] Every table is aliased and every column qualified.

---

## P2 — The Missing-Rows Report  *(Easy)*

**Tags:** `anti-join` `not-exists` `not-in-null-trap`

### Requirements

Produce four "nothing here" reports, each written **three ways** (`NOT EXISTS`, `LEFT JOIN … IS NULL`, `NOT IN`) with a comment saying whether each version is correct and why:

1. Tasks with no assignee.
2. Users with no task assignment.
3. Labels never applied to any task.
4. **Individual contributors** — users who are nobody's manager (`app.Users.ManagerId`).

Report 4 is the trap. Capture the actual row count returned by the `NOT IN` version and explain it.

Then write one correct `NOT IN` version of report 4 by adding the necessary guard.

### Deliverable

`P2-missing-rows.sql`

### Hints

- `app.TaskAssignments.TaskId` and `.UserId` are both `NOT NULL`, which is why `NOT IN` is safe in reports 1–3.
- `app.Users.ManagerId` is nullable and contains NULLs.
- `x NOT IN (a, b, NULL)` expands to `x <> a AND x <> b AND x <> NULL`. Work out the truth value.

### Look-fors (rubric)

- [ ] Report 1 = 8 rows, report 2 = 6 rows, report 3 = 1 row (`good-first-issue`), report 4 = 13 rows.
- [ ] The `NOT IN` version of report 4 returns **0 rows** and this is documented, not "fixed" by accident.
- [ ] The explanation names three-valued logic explicitly.
- [ ] The guarded `NOT IN` version (`WHERE ManagerId IS NOT NULL`) returns 13.
- [ ] The write-up recommends `NOT EXISTS` as the default and says why.

---

## P3 — `ON` vs `WHERE`, Proven  *(Medium)*

**Tags:** `on-vs-where` `left-join` `null-semantics`

### Requirements

Using project 8 (`TF-DS`, tasks 31/32/33) as the scope, write **four** variants of the same query — `TaskId` plus assignee name — and record the exact result set of each:

| Variant | Predicate | Placement |
|---|---|---|
| V1 | none | baseline `LEFT JOIN` chain |
| V2 | `u.CountryCode = 'GB'` | in the `ON` of the join to `app.Users` |
| V3 | `u.CountryCode = 'GB'` | in `WHERE` |
| V4 | `u.CountryCode = 'US'` | in the `ON` |

Then:

5. Write a fifth variant that starts `LEFT JOIN app.TaskAssignments` but then uses `INNER JOIN app.Users`. Explain why it behaves like V3 even though nothing moved into `WHERE`.
6. Produce a two-column comment table: *"if the requirement is X, put the predicate in Y"*, covering at least four requirements.

### Deliverable

`P3-on-vs-where.sql`

### Hints

- Tim Berners-Lee (`UserId` 14) is the only assignee in project 8, and his `CountryCode` is `'GB'`.
- V4 should surprise you: all rows survive, all assignee values are NULL.
- The rule: `ON` runs at logical step 2, before outer rows are re-added at step 3; `WHERE` runs at step 4.

### Look-fors (rubric)

- [ ] V1 = 3 rows, V2 = 3 rows, V3 = **2 rows**, V4 = 3 rows with all-NULL assignees.
- [ ] The write-up states that V3 is functionally an `INNER JOIN`.
- [ ] Variant 5 is explained in terms of the outer join chain being broken downstream.
- [ ] The decision table distinguishes "keep unmatched rows" from "drop unmatched rows".
- [ ] `WHERE ta.TaskId IS NULL` is identified as the one legitimate `WHERE` predicate on the null-supplying side.

---

## P4 — Org Chart Self-Join  *(Medium)*

**Tags:** `self-join` `left-join` `aggregation`

### Requirements

1. **Roster:** every user with their manager's name and job title. Users with no manager must appear with `'(top level)'`. Verify the row count.
2. **Skip-level:** every user with manager and skip-level manager, three `app.Users` aliases.
3. **Span of control:** every manager with their direct-report count, ordered descending. Only users who actually manage somebody.
4. **Bench report:** users who are neither a manager nor assigned to any task. Use anti-joins.
5. **Peer pairs:** all pairs of users who share the same manager, without self-pairs and without each pair appearing twice.
6. Add a comment explaining why a self-join can only walk a **fixed** number of levels, and what construct you would use for arbitrary depth.

### Deliverable

`P4-org-chart-self-join.sql`

### Hints

- `app.Users.FullName` is a persisted computed column — use it, do not re-concatenate.
- Query 3 must group by the manager, not the employee. Decide whether you drive from `app.Users` as manager or aggregate `ManagerId`.
- Query 5 needs `b.UserId > a.UserId` on the join.
- Only 7 users have any direct reports.

### Look-fors (rubric)

- [ ] Query 1 returns 20 rows; an `INNER JOIN` version would return 18 and this is noted.
- [ ] Query 3 returns 7 rows, with Linus Torvalds at 4 and Ada Lovelace at 2.
- [ ] Query 5 produces no self-pairs and no mirror duplicates; row count is stated and justified.
- [ ] Query 4's result is correct and uses `NOT EXISTS`, not `NOT IN`.
- [ ] The comment names recursive CTEs as the arbitrary-depth answer.

---

## P5 — Many-to-Many and Row Multiplication  *(Medium)*

**Tags:** `many-to-many` `junction-table` `fan-out` `string-agg` `outer-apply`

### Requirements

1. Count the rows produced by `app.Tasks JOIN app.TaskLabels`. Explain the number in terms of tasks-with-labels and tasks-with-two-labels.
2. Write the **naive** report: task, project, label name, estimated hours — then `SUM(EstimatedHours)` grouped by project. Show that the total is inflated and state by how much for at least one project.
3. Write the **correct** report: exactly one row per task, with a comma-separated alphabetical label list and `'(unlabelled)'` where there are none. Use `OUTER APPLY` + `STRING_AGG`.
4. Do the same on the people side: one row per team with a comma-separated member list, including the team that has no members.
5. Find every user who is in **more than one** team, and every task that carries **more than one** label.
6. Write a query that returns tasks carrying **both** `security` **and** `tech-debt` labels — without using `DISTINCT`.

### Deliverable

`P5-many-to-many.sql`

### Hints

- 28 label rows over 25 labelled tasks.
- For requirement 6, the two idiomatic answers are two `EXISTS` clauses or a `GROUP BY … HAVING COUNT(DISTINCT l.LabelName) = 2`. Implement one and mention the other.
- `Design System` is the team with no members.
- `STRING_AGG(x, N', ') WITHIN GROUP (ORDER BY x)`.

### Look-fors (rubric)

- [ ] Requirement 1 answer is 28, explained as 25 tasks + 3 tasks with a second label.
- [ ] Requirement 3 returns exactly 35 rows.
- [ ] Requirement 4 returns exactly 7 rows with `Design System` present.
- [ ] Requirement 5 finds Ken Thompson (2 teams) and tasks 4, 6, 20 (2 labels each).
- [ ] Requirement 6 returns task 20 and uses no `DISTINCT`.
- [ ] The inflated total in requirement 2 is quantified, not just described.

---

## P6 — Non-Equi Join: SLA Bands  *(Medium)*

**Tags:** `non-equi-join` `range-join` `nulls` `cross-join`

### Requirements

1. Define an SLA band table inline with `(VALUES …) AS b (BandName, MinHours, MaxHours)`: `Same day` [0, 8), `Next day` [8, 24), `This week` [24, 168), `Backlog` [168, 8760).
2. Join `ref.Priorities` to the bands on a **half-open** range. Report which band each of the 5 priorities lands in.
3. Deliberately rewrite the predicate with `BETWEEN MinHours AND MaxHours` and show which priority now matches two bands. Explain why half-open intervals are mandatory.
4. Explain what happens to the `NONE` priority (whose `SlaHours` is NULL) under `INNER JOIN` versus `LEFT JOIN`, and pick one with a justification.
5. Roll the bands up to tasks: task count per band, including a row for tasks whose priority has no SLA. Verify the total is 35.
6. Build a dense band × status grid with `CROSS JOIN` so that every combination appears even with zero tasks. State the row count.
7. Add a comment on why a range join cannot use a Hash Match operator and what that implies for large band tables.

### Deliverable

`P6-sla-bands.sql`

### Hints

- `HIGH` has `SlaHours = 24`, sitting exactly on a boundary. That is the row that duplicates under `BETWEEN`.
- NULL never satisfies `>=` or `<`, so `NONE` matches nothing regardless of operator choice.
- Hashing requires equality; there is nothing to hash on a range predicate.

### Look-fors (rubric)

- [ ] Requirement 2 returns 5 rows with `CRITICAL`→`Same day`, `HIGH`→`This week`, `MEDIUM`→`This week`, `LOW`→`Backlog`, `NONE`→NULL.
- [ ] Requirement 3 identifies `HIGH` as the duplicating row and shows 6 rows instead of 5.
- [ ] Requirement 5 totals 35: Same day 4, This week 23, Backlog 5, no band 3.
- [ ] Requirement 6's row count is stated and matches `bands × statuses`.
- [ ] `LEFT JOIN` is chosen for the NULL case with a stated business justification.

---

## P7 — `CROSS APPLY` and `OUTER APPLY`  *(Hard)*

**Tags:** `cross-apply` `outer-apply` `top-n-per-group` `tvf` `openjson`

### Requirements

1. **Top-N per group:** the 2 most recently created tasks per project. State the row count.
2. **Latest child row:** the most recent time entry per task, with a deterministic tie-breaker. Write it with `CROSS APPLY` and then `OUTER APPLY`, and state both row counts.
3. **Several measures, one row per parent:** for every task, return `AssigneeCount`, `LoggedHours`, `BillableHours`, `CommentCount` using a single `OUTER APPLY` per child. Compare this against the four-`LEFT JOIN`-derived-table version from Topic 05 P5 — which do you prefer, and why?
4. **Table-valued function:** create an **inline** TVF `app.fn_TaskEffort(@TaskId)` returning logged hours, billable hours and entry count. Call it with `CROSS APPLY`. Explain why it returns a row even for tasks with no time entries, and what changes if you add a `GROUP BY` inside it.
5. **JSON expansion:** list the reviewers on task 1 from `MetadataJson`, and separately list every task's `epic` value, keeping tasks with no `epic`.
6. **Expression reuse:** use `CROSS APPLY (VALUES (…))` to compute a derived value once and reference it in `SELECT`, `WHERE` and `ORDER BY`.
7. Drop the TVF at the end.

### Deliverable

`P7-apply.sql`

### Hints

- Requirement 1: every project has at least 2 tasks, so the count is exact.
- Requirement 2: `ORDER BY te.WorkDate DESC` alone is non-deterministic — add `te.TimeEntryId DESC`.
- Requirement 4: a scalar aggregate with no `GROUP BY` always returns exactly one row.
- Requirement 5: `OPENJSON(t.MetadataJson, N'$.reviewers')`; `JSON_VALUE(t.MetadataJson, N'$.epic')`.
- Use `RETURNS TABLE` (inline), not `RETURNS @t TABLE` (multi-statement). Say why in a comment.

### Look-fors (rubric)

- [ ] Requirement 1 returns 16 rows.
- [ ] Requirement 2: `CROSS APPLY` = 16 rows, `OUTER APPLY` = 35 rows, both stated.
- [ ] Requirement 3 returns 35 rows with zeroes, not NULLs, for childless tasks.
- [ ] The TVF is inline and the explanation of the scalar-aggregate row is correct.
- [ ] Requirement 5 returns 2 reviewers for task 1 and keeps all 35 tasks in the `epic` listing.
- [ ] `DROP FUNCTION IF EXISTS app.fn_TaskEffort;` runs at the end.
- [ ] A comment compares `APPLY` (nested loops, correlated) against `JOIN` and says when each wins.

---

## P8 — Physical Join Operators and Plan Reading  *(Hard)*

**Tags:** `execution-plans` `nested-loops` `merge-join` `hash-match` `join-hints` `indexes`

### Requirements

1. Enable the actual execution plan and `SET STATISTICS IO, TIME ON`.
2. Run `app.Tasks JOIN app.TaskAssignments JOIN app.Users` and record which physical operator each join used.
3. Force each of the three operators in turn with `INNER LOOP JOIN`, `INNER MERGE JOIN`, `INNER HASH JOIN`. Record logical reads and any warnings for each.
4. Demonstrate that a **hash join cannot be used for a non-equi join**: attempt `OPTION (HASH JOIN)` on the SLA range join from P6 and capture the error.
5. Create `IX_TaskAssignments_UserId` on `app.TaskAssignments (UserId) INCLUDE (TaskId)` and re-run step 2. Record any change in operator choice.
6. Run the anti-join from P2 report 1 three ways (`NOT EXISTS`, `LEFT JOIN … IS NULL`, `NOT IN`) and compare the three plans. Which two are identical? Why is the third different?
7. Add `OPTION (FORCE ORDER)` to a four-table join and explain, in a comment, why a join hint in the `FROM` clause has the same effect on the whole query.
8. Drop the index.

### Deliverable

`P8-join-operators.sql` — statements plus a comment results table: *scenario / operator / logical reads / warnings*.

### Hints

- 35 rows is far too small for cost to matter. Compare **plan shape and logical reads**, never elapsed time.
- The hash-join error in step 4 is a query-processor error about the hint not being usable; quote it verbatim.
- In step 6, `NOT EXISTS` and `LEFT JOIN … IS NULL` normally produce the same anti-semi-join. `NOT IN` over a `NOT NULL` column may too — check whether the optimizer knows the column is `NOT NULL`.
- A `FROM`-clause join hint implicitly enables `FORCE ORDER` for the entire query. Confirm it in the plan.

### Look-fors (rubric)

- [ ] All three physical operators are observed and named correctly.
- [ ] The step-4 error is quoted verbatim and the reason (hashing requires equality) is stated.
- [ ] Step 6 correctly identifies which plans match.
- [ ] The write-up lists what to try **before** a join hint: statistics, indexes, sargability, `RECOMPILE`, Query Store plan forcing.
- [ ] Estimated vs actual row counts are compared on at least one operator.
- [ ] The index is dropped at the end.

---

## Submission Checklist

- [ ] Every file runs top-to-bottom against a freshly seeded `TaskFlowDb` with no errors.
- [ ] Every table reference is schema-qualified: `app.`, `ref.`, `audit.`.
- [ ] Every table has an alias and every column is qualified with it.
- [ ] No `SELECT *`.
- [ ] No comma joins (`FROM a, b WHERE`). Every join uses `JOIN … ON`.
- [ ] No `SELECT DISTINCT` used to suppress duplicate rows from a join.
- [ ] `NOT IN` appears only over `NOT NULL` columns, and each such use is justified in a comment.
- [ ] Predicates on the null-supplying side of an outer join are in `ON`, unless the demotion to inner is deliberate and commented.
- [ ] Every `TOP (n)` inside an `APPLY` has a deterministic `ORDER BY` with a tie-breaker.
- [ ] Every expected row count in the rubric is verified, not assumed.
- [ ] Any object you create (index, function) is dropped at the end of the file.

## Stretch Goals

1. **Rewrite P7 requirement 1 with `ROW_NUMBER()`** in a CTE and compare the plan against `CROSS APPLY`. At what N does one overtake the other? Explain the shape of each plan.
2. **`FULL OUTER JOIN` reconciliation:** write a query that compares `app.TaskAssignments` against `app.TimeEntries` at `(TaskId, UserId)` grain and classifies every pair as `AssignedNoTime`, `TimeNoAssignment`, or `Both`. Find the rows where somebody logged time on a task they are not assigned to.
3. **Simulate `FULL OUTER JOIN` in MySQL style** using `LEFT JOIN … UNION … RIGHT JOIN`, and prove it returns the same rows as the native version. Note the `UNION` vs `UNION ALL` decision and its cost.
4. **Legacy conversion:** write a query using the ANSI-89 comma syntax, then convert it to ANSI-92. Then write a comment on what the `*=` operator would have looked like and why it was removed.
5. **Optimizer experiment:** join five tables and count the join orders the optimizer could theoretically consider. Then check the plan's `Reason For Early Termination` property in the XML. What does `Good Enough Plan Found` versus `Timeout` tell you?
6. **`APPLY` with a scalar function:** write the same logic as a scalar UDF and as an inline TVF called with `CROSS APPLY`. Compare the plans, and note whether scalar UDF inlining (SQL Server 2019+) kicked in.
