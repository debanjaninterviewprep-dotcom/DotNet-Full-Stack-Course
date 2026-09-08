# Topic 05: Aggregations & Grouping — Practice Problems

> Eight exercises that force you to meet every aggregation trap in a controlled setting: NULL elimination, integer truncation, the fan-out double-count, `HAVING` versus `WHERE`, subtotal NULLs, and the two physical aggregate operators. Every problem runs against the shared **TaskFlowDb** sample database. Write real, runnable T-SQL — not pseudocode.

**Concept tags:** `count` `sum` `avg` `null-handling` `group-by` `having` `conditional-aggregation` `rollup` `cube` `grouping-sets` `fan-out` `string-agg` `execution-plans`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Put each answer in `PracticeProblemsSolutions/Pn-*.sql`. Starter files with the problem statement are already there.

---

## P1 — Aggregate Vital Signs  *(Easy)*

**Tags:** `count` `null-handling` `distinct`

### Requirements

Produce a **single-row** "vital signs" result over `app.Tasks` with these columns, in this order:

| Column | Definition |
|---|---|
| `TotalTasks` | Every row |
| `TasksWithDueDate` | Rows where `DueDate` is populated |
| `TasksWithEstimate` | Rows where `EstimatedHours` is populated |
| `TasksWithDescription` | Rows where `Description` is populated |
| `DistinctProjects` | Distinct `ProjectId` values |
| `DistinctStatuses` | Distinct `StatusId` values |
| `DistinctPriorities` | Distinct `PriorityId` values |
| `EarliestCreated` | Oldest `CreatedAtUtc` |
| `LatestCreated` | Newest `CreatedAtUtc` |

Then write a **second** statement that runs the same shape against `WHERE ProjectId = 999` and add a comment explaining, in one line each, why `TotalTasks` is `0` but `SUM(EstimatedHours)` is `NULL`.

### Deliverable

`P1-aggregate-vital-signs.sql` — two `SELECT` statements plus the explanatory comment.

### Hints

- `COUNT(*)` and `COUNT(col)` are not interchangeable. Exactly one column above should use `COUNT(*)`.
- `app.Tasks.Description` is never populated by the seed script. That is deliberate.
- `MIN`/`MAX` work on `DATETIME2` without any casting.

### Look-fors (rubric)

- [ ] `TotalTasks` = 35, `TasksWithDueDate` = 27, `TasksWithEstimate` = 31, `TasksWithDescription` = 0.
- [ ] `DistinctProjects` = 8, `DistinctStatuses` = 7, `DistinctPriorities` = 5.
- [ ] Every table reference is schema-qualified (`app.Tasks`).
- [ ] The comment correctly states that `COUNT` returns 0 on an empty set while every other aggregate returns `NULL`.
- [ ] No `SELECT *` anywhere.

---

## P2 — Project Scorecard  *(Easy)*

**Tags:** `group-by` `sum` `avg` `integer-truncation` `isnull`

### Requirements

One row per project (use `ProjectCode`), with:

1. `TaskCount` — number of tasks.
2. `EstimatedHours` — total estimate, **0 not NULL** when nothing is estimated.
3. `AvgEstimateHours` — average estimate, rounded to 2 decimals, over tasks that *have* an estimate.
4. `AvgStoryPoints` — average story points to **4 decimal places**.
5. `AvgStoryPointsNaive` — the same expression written the way a beginner would (`AVG` straight on the column), so the two can be compared side by side.
6. `MaxStoryPoints`, `MinStoryPoints`.

Order by `TaskCount` descending, then `ProjectCode`.

Add a comment line stating the numeric difference you observe between columns 4 and 5 for at least one project, and explain the cause in one sentence.

### Deliverable

`P2-project-scorecard.sql`

### Hints

- `app.Tasks.StoryPoints` is `TINYINT`. That is the whole point of columns 4 and 5.
- Cast the **column**, not the result of `AVG`.
- Four projects are missing at least one estimate; `SUM` will still return a number for them because other rows have values.

### Look-fors (rubric)

- [ ] `TF-CORE` shows `TaskCount` = 9, `EstimatedHours` = 140.00.
- [ ] `AvgStoryPointsNaive` is visibly lower than `AvgStoryPoints` for at least one project.
- [ ] `ISNULL` (or `COALESCE`) is used only where a NULL is actually possible — not sprayed everywhere.
- [ ] Join to `app.Projects` is an `INNER JOIN` and you can explain why that is safe here.
- [ ] The `ORDER BY` uses the alias, not a repeated expression.

---

## P3 — `WHERE` vs `HAVING`, Proven  *(Medium)*

**Tags:** `having` `where` `logical-processing-order` `left-join`

### Requirements

Write **three** statements that answer the same business question — *"How many non-terminal (open) tasks does each project have, and which projects have 4 or more?"* — and demonstrate their differences.

1. **Query A:** filter with `WHERE s.IsTerminal = 0`, `GROUP BY`, `HAVING COUNT(*) >= 4`. Record the row count.
2. **Query B:** move the `IsTerminal` predicate into `HAVING` instead (using conditional aggregation) so that projects with **zero** open tasks still appear with `0`. Drive the query from `app.Projects`.
3. **Query C:** deliberately write `WHERE COUNT(*) >= 4` and capture the exact error number and message as a comment.

Then add a comment table listing which projects appear in A but not B, and vice versa, with the reason.

### Deliverable

`P3-where-vs-having.sql`

### Hints

- Query A returns exactly 2 rows.
- `TF-MOB` is the project you should be thinking about. Both of its tasks are `CANCELLED`.
- Query B needs `LEFT JOIN` from `app.Projects` all the way down, plus `COUNT(CASE WHEN … THEN 1 END)`.
- The error for Query C is `Msg 147`.

### Look-fors (rubric)

- [ ] Query A yields `TF-CORE` (5) and `TF-WEB` (4).
- [ ] Query B yields all 8 projects, with `TF-MOB` = 0.
- [ ] The captured error message for Query C is quoted verbatim.
- [ ] The write-up explicitly names the logical processing step (`WHERE` = step 4, `HAVING` = step 6) that causes the difference.
- [ ] Query B does **not** put any `app.Tasks` or `ref.TaskStatuses` predicate in `WHERE`.

---

## P4 — Status Pivot Without `PIVOT`  *(Medium)*

**Tags:** `conditional-aggregation` `pivot` `percentages`

### Requirements

Build the board summary that the TaskFlow web client renders: **one row per project**, one column per status, plus totals.

Columns: `ProjectCode`, `Backlog`, `ToDo`, `InProgress`, `InReview`, `Blocked`, `Done`, `Cancelled`, `TotalTasks`, `PctComplete`.

Rules:

- Use **conditional aggregation only** — no `PIVOT` operator, no subqueries per column.
- Reference statuses by joining `ref.TaskStatuses` and testing `StatusCode`, **not** by hard-coding `StatusId` integers.
- `PctComplete` = percentage of tasks whose status `IsTerminal = 1`, as `DECIMAL(5,2)`.
- Include every project, even one with no tasks (there is none in the seed data, but your query must survive one being added).
- Add a final `WITH ROLLUP`-free grand-total row using `UNION ALL` **or** state in a comment why you would prefer `ROLLUP` here.

### Deliverable

`P4-status-pivot.sql`

### Hints

- `100.0 * SUM(CASE …) / COUNT(*)` — the `100.0` forces decimal arithmetic. `100 *` would truncate.
- To include task-less projects you must drive from `app.Projects` with `LEFT JOIN` and switch `COUNT(*)` to `COUNT(t.TaskId)`.
- The seven status counts must add up to `TotalTasks` on every row. Assert it.

### Look-fors (rubric)

- [ ] Column totals across the whole result: Backlog 6, ToDo 5, InProgress 8, InReview 1, Blocked 2, Done 11, Cancelled 2 (sum 35).
- [ ] `TF-MOB` shows `Cancelled` = 2 and `PctComplete` = 100.00.
- [ ] No `StatusId` literal appears in the `CASE` expressions.
- [ ] `COUNT(t.TaskId)` (not `COUNT(*)`) is used on the `LEFT JOIN` side.
- [ ] Exactly one scan of `app.Tasks` in the execution plan.

---

## P5 — The Fan-Out Trap  *(Medium)*

**Tags:** `fan-out` `double-counting` `derived-tables` `count-distinct`

### Requirements

1. Write the **broken** query: join `app.Tasks` to both `app.TaskAssignments` and `app.TimeEntries`, group by `TaskId`, and output `COUNT(*)`, `COUNT(DISTINCT ta.UserId)`, `COUNT(DISTINCT te.TimeEntryId)`, and `SUM(te.Hours)`. Restrict to tasks 1, 4, 6, 10, 19.
2. Add a comment giving, for each of those five tasks, the **true** logged hours and the **inflated** value your query produced, plus the multiplication factor.
3. Write the **fixed** query using pre-aggregated derived tables (or CTEs) that returns, for **all 35 tasks**: `TaskId`, `Title`, `AssigneeCount`, `LoggedHours`, `BillableHours`, `CommentCount`, `LabelCount` — with `0` (never `NULL`) for tasks with no children.
4. Prove the fix: a final statement asserting `SUM(LoggedHours) = 160.00` and `SUM(BillableHours) = 149.00` across the whole result.

### Deliverable

`P5-fan-out-trap.sql`

### Hints

- Task 4 has 2 assignees and 3 time entries; task 19 has 2 assignees and 1 time entry.
- `COUNT(DISTINCT …)` survives the fan-out. `SUM` does not. Explain why in a comment.
- Four separate one-row-per-task pre-aggregates are needed: assignments, time entries, comments, labels.
- Consider whether `OUTER APPLY` would be cleaner than four `LEFT JOIN`s — you will meet it formally in Topic 06.

### Look-fors (rubric)

- [ ] Broken query shows task 4 = 6 rows / 42.00 hours and task 10 = 6 rows / 43.00 hours.
- [ ] Fixed query returns exactly 35 rows.
- [ ] Eight tasks show `AssigneeCount` = 0; `LabelCount` = 0 for exactly 10 tasks.
- [ ] `ISNULL`/`COALESCE` wraps every measure coming from a `LEFT JOIN`ed aggregate.
- [ ] The comment explains that `COUNT(DISTINCT)` dedupes but `SUM` cannot, because the duplicated values are genuinely equal.
- [ ] No `SELECT DISTINCT` is used as a workaround anywhere.

---

## P6 — Subtotals That Tell the Truth  *(Hard)*

**Tags:** `rollup` `cube` `grouping-sets` `grouping` `grouping-id`

### Requirements

1. Produce a project × status matrix with **project subtotals and a grand total** using `ROLLUP`. Report the exact row count and reconcile it with the arithmetic `(real combinations) + (projects) + 1`.
2. Repeat with `CUBE`. Report the row count and reconcile it the same way.
3. Express the `ROLLUP` result exactly using `GROUPING SETS`, and prove the two are equivalent (identical row counts and identical `Tasks` values).
4. Build a headcount report over `app.Users` grouped by `ROLLUP (JobTitle)` that **correctly distinguishes** the one user with a NULL `JobTitle` from the grand-total row. Use `GROUPING()`.
5. Add a `GROUPING_ID()` column to the `CUBE` query and produce a legend comment mapping each value (0/1/2/3) to its meaning.

### Deliverable

`P6-rollup-cube-grouping-sets.sql`

### Hints

- There are 25 real project/status combinations, 8 projects, 7 statuses.
- `ORDER BY GROUPING(a), a, GROUPING(b), b` puts subtotals after their detail rows instead of interleaving them.
- `GROUPING_ID(a, b)` is most-significant-bit-first: `a` is the high bit.
- Sophie Wilson (`UserId` 19) is the NULL-title user.

### Look-fors (rubric)

- [ ] `ROLLUP` = 34 rows, `CUBE` = 41 rows, plain `GROUP BY` = 25 rows — all three stated and verified.
- [ ] The `GROUPING SETS` rewrite is byte-for-byte equivalent in output to the `ROLLUP` version.
- [ ] The headcount report shows a `(no title on record)` row with 1 and an `ALL TITLES` row with 20 — as two distinct rows.
- [ ] `GROUPING()` is used, not `ISNULL()`, to make that distinction.
- [ ] The `GROUPING_ID` legend is correct for all four values.
- [ ] `ROLLUP (a, b)` is used, not the deprecated `GROUP BY a, b WITH ROLLUP`.

---

## P7 — Team Utilisation Report  *(Hard)*

**Tags:** `multi-level-aggregation` `string-agg` `fan-out` `having` `nulls`

### Requirements

Produce a management report with **one row per team** (all 7 teams, including `Design System` which has no members):

| Column | Definition |
|---|---|
| `TeamName`, `Department` | From `app.Teams` |
| `LeadName` | `FullName` of the lead, or `'(no lead)'` |
| `MemberCount` | Distinct users in `app.TeamMembers` |
| `MemberList` | Comma-separated `FullName`s, alphabetical |
| `ProjectCount` | Projects owned by the team |
| `TaskCount` | Tasks across those projects |
| `OpenTaskCount` | Non-terminal tasks |
| `LoggedHours` | Hours logged **by team members** on those tasks, 0 if none |
| `BilledValue` | `SUM(Hours × HourlyRate)` for billable entries only, 0 if none |
| `AvgHourlyRate` | Average rate of members who have one, 4 dp, NULL-safe |

Constraints:

- Absolutely no row multiplication. Every child must be pre-aggregated to the correct grain before it is joined.
- One user (Ken Thompson) belongs to two teams. Confirm your `MemberCount` handles that correctly and say what "correctly" means in a comment.
- One user (Sophie Wilson) has a `NULL` `HourlyRate`. Document how she affects `AvgHourlyRate` and `BilledValue`.

Then add a second statement that filters to teams whose `OpenTaskCount` exceeds their `MemberCount`, using `HAVING` or an outer filter — and justify your choice.

### Deliverable

`P7-team-utilisation.sql`

### Hints

- Three grains are in play: team → project → task → time entry. Collapse upward one level at a time.
- `STRING_AGG(u.FullName, N', ') WITHIN GROUP (ORDER BY u.FullName)`.
- `Design System` (team 7) must appear with `MemberCount` 0, `MemberList` NULL, `LeadName` `'(no lead)'`.
- Total `LoggedHours` across all teams will be less than 160.00 — work out why before you assume you have a bug.

### Look-fors (rubric)

- [ ] Exactly 7 rows.
- [ ] `Design System` present with zeroes, not missing.
- [ ] `Platform` shows 5 members and a correctly sorted `MemberList`.
- [ ] The comment about Ken Thompson is correct: he is counted once *per team*, twice across the report, and that is intended.
- [ ] `BilledValue` skips non-billable entries and rows where `HourlyRate` is NULL — and the comment says so.
- [ ] No `SELECT DISTINCT`; no aggregate over an already-fanned-out join.
- [ ] Every derived table is named and every column is schema- or alias-qualified.

---

## P8 — Grouping Performance Lab  *(Hard)*

**Tags:** `execution-plans` `stream-aggregate` `hash-match` `indexes` `statistics-io`

### Requirements

1. Turn on `SET STATISTICS IO, TIME ON;` and enable the actual execution plan.
2. Run a baseline: `SELECT ProjectId, StatusId, COUNT(*), SUM(EstimatedHours) FROM app.Tasks GROUP BY ProjectId, StatusId;`. Record the aggregate operator used, logical reads, and whether a `Sort` appears.
3. Create `IX_Tasks_Project_Status_Incl` on `app.Tasks (ProjectId, StatusId) INCLUDE (EstimatedHours, StoryPoints)`. Re-run. Record what changed.
4. Change the `GROUP BY` to `StatusId, ProjectId` (reversed) and re-run. Explain whether the index still avoids the `Sort` and why.
5. Run a `COUNT(DISTINCT CreatedByUserId)` variant and describe the extra operator it introduces.
6. Run the same query with `APPROX_COUNT_DISTINCT` and compare plan shape (the row count is far too small for a difference in *result*, so comment on what would change at scale).
7. Drop the index at the end so the database returns to its seeded state.

### Deliverable

`P8-grouping-performance.sql` — the statements, plus a results table in comments with one row per experiment: *scenario / aggregate operator / sort present / logical reads*.

### Hints

- 35 rows is tiny; the optimizer may pick either operator. Read the plan, do not guess. Use `OPTION (RECOMPILE)` between runs and clear plan cache **only on a local dev instance**.
- To force the comparison, you can add `OPTION (ORDER GROUP)` and `OPTION (HASH GROUP)` and compare the two plans directly.
- `SET STATISTICS IO` reports logical reads per table; that is the number to compare, not elapsed milliseconds.
- Step 4's answer depends on whether the aggregate is a Stream Aggregate (order-sensitive) or a Hash Match (order-insensitive).

### Look-fors (rubric)

- [ ] Both `Stream Aggregate` and `Hash Match (Aggregate)` are observed and named correctly.
- [ ] The write-up states that a Stream Aggregate needs sorted input and a Hash Match does not.
- [ ] Step 4 is answered correctly: a Hash Aggregate does not care about the `GROUP BY` order; a Stream Aggregate does, and the index only supplies `(ProjectId, StatusId)` order.
- [ ] The `COUNT(DISTINCT)` experiment identifies the extra distinct/sort step.
- [ ] The index is dropped at the end.
- [ ] No conclusions are drawn from elapsed time alone on a 35-row table.

---

## Submission Checklist

- [ ] Every file runs top-to-bottom against a freshly seeded `TaskFlowDb` with no errors.
- [ ] Every table reference is schema-qualified: `app.`, `ref.`, `audit.`.
- [ ] Every table has an alias and every column is qualified with it.
- [ ] No `SELECT *`.
- [ ] No `SELECT DISTINCT` used to hide a join fan-out.
- [ ] Every `AVG` over an integer column is explicitly cast.
- [ ] Every `SUM` that feeds a UI number is wrapped in `ISNULL(..., 0)` — or you can justify why NULL is correct there.
- [ ] Non-aggregate predicates live in `WHERE`, aggregate predicates in `HAVING`.
- [ ] Row counts stated in the rubric are verified, not assumed.
- [ ] Files are named `Pn-<slug>.sql` and committed under `PracticeProblemsSolutions/`.

## Stretch Goals

1. **Re-write P4 with the `PIVOT` operator** and compare the plan against the conditional-aggregation version. Which is more readable? Which handles a new status being added to `ref.TaskStatuses` better?
2. **Dynamic pivot:** build the P4 query as dynamic SQL that reads the status list from `ref.TaskStatuses` at runtime. Parameterise it safely with `sp_executesql` and `QUOTENAME` — no string concatenation of user input.
3. **Indexed view:** create a schema-bound indexed view that materialises task counts per project. You must use `COUNT_BIG(*)`. Measure the write amplification by timing an `INSERT` into `app.Tasks` before and after.
4. **Median:** SQL Server has no `MEDIAN` aggregate. Compute the median `EstimatedHours` per project using `PERCENTILE_CONT(0.5)` and explain why it is a window function, not an aggregate.
5. **`CHECKSUM_AGG` change detection:** build a per-project fingerprint that changes whenever any task in the project changes status. Then explain the collision risk and what you would use instead in production.
6. **Portability drill:** rewrite P4's conditional aggregation using PostgreSQL's `FILTER (WHERE …)` clause and MySQL's `SUM(cond)` boolean shorthand. Note which reads best.
