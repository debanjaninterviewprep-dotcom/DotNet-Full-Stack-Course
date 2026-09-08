# Topic 14: Views & Synonyms — Practice Problems

> Six exercises covering ordinary views, the updatable-view boundary, indexed views, and synonyms as a location abstraction. All against the seeded `TaskFlowDb`.

**Concept tags:** `views` `updatable-views` `check-option` `indexed-views` `schemabinding` `synonyms` `security-views`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — A Basic Encapsulating View  *(Easy)*

**Tags:** `views` `encapsulation`

### Requirements

1. Create `app.vw_OpenTasks` exposing `TaskId, Title, ProjectId, StatusId, PriorityId, DueDate` for tasks where `StatusId NOT IN (6, 7)`.
2. Query it filtered by `ProjectId` and confirm the row count matches a hand-written equivalent query against `app.Tasks` directly.
3. Add a column to a **copy** of `app.Tasks` (a scratch table, not the real one) that has a view defined with `SELECT *`, and demonstrate that the view does **not** pick up the new column until refreshed.
4. Run `sp_refreshview` and confirm the new column now appears.

### Deliverable

`P1-basic-view.sql`. Drop all scratch objects at the end.

### Hints

- Use `SELECT ... INTO #ScratchTasks FROM app.Tasks;` for the scratch copy so you don't touch the real table.

### Look-fors (rubric)

- [ ] The view's row count matches the hand-written query exactly.
- [ ] The stale `SELECT *` behavior is demonstrated concretely (query the view before and after adding the column).
- [ ] `sp_refreshview` is shown fixing it.

---

## P2 — The Updatable View Boundary  *(Easy)*

**Tags:** `updatable-views` `multi-table-write` `error-4405`

### Requirements

1. Create `app.vw_TaskWithProject` joining `app.Tasks` and `app.Projects`.
2. Successfully update a `Tasks`-only column through the view.
3. Successfully update a `Projects`-only column through the view.
4. Attempt to update one column from each table in a single `UPDATE` statement against the view, and capture the exact error (Msg 4405).
5. Roll back everything (wrap in a transaction).

### Deliverable

`P2-updatable-view-boundary.sql`.

### Hints

- `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION` around the whole file.

### Look-fors (rubric)

- [ ] Both single-table updates succeed.
- [ ] The multi-table update fails with the exact Msg 4405 text captured.
- [ ] The transaction is rolled back at the end.

---

## P3 — `WITH CHECK OPTION`  *(Medium)*

**Tags:** `check-option` `updatable-views`

### Requirements

1. Create a view over `app.Tasks` filtered to `PriorityId IN (1, 2) AND StatusId NOT IN (6, 7)`, with `WITH CHECK OPTION`.
2. Attempt to `UPDATE` a row through the view to set `PriorityId = 4` (which would make it disappear from the view's own result set) and capture the rejection.
3. Recreate the same view **without** `WITH CHECK OPTION` and show the identical update now succeeds, but the row silently vanishes from a subsequent `SELECT` against the view.
4. Explain, in a comment, which behavior is safer for an application that assumes "if I can write it through this view, I can read it back through this view."

### Deliverable

`P3-check-option.sql`. Roll back all data changes.

### Hints

- The "silently vanishes" behavior is the entire point of `WITH CHECK OPTION` existing.

### Look-fors (rubric)

- [ ] The `WITH CHECK OPTION` version correctly rejects the disqualifying update.
- [ ] The version without it is shown succeeding and then the row is shown missing from the view.
- [ ] The safety explanation correctly argues for `CHECK OPTION` in read-after-write scenarios.

---

## P4 — Building and Measuring an Indexed View  *(Medium)*

**Tags:** `indexed-views` `schemabinding` `count-big` `materialisation`

### Requirements

1. Create `app.vw_ProjectTaskCounts` (per-project `TaskCount` and `SUM(EstimatedHours)`) with `WITH SCHEMABINDING`, using `COUNT_BIG(*)`.
2. Add a `UNIQUE CLUSTERED INDEX` on `ProjectId` to materialise it.
3. Insert a new task into project 1, then immediately query the indexed view and confirm the count updated **without** any manual refresh or scheduled job.
4. Attempt to `ALTER TABLE app.Tasks` in a way that would break the schemabound view's assumptions (e.g. attempt to drop a column the view references) and capture the blocking error.
5. Drop the indexed view (index and view) and any test data changes.

### Deliverable

`P4-indexed-view.sql`. Roll back all data changes.

### Hints

- Dropping a column referenced by a schemabound view/index fails with a clear dependency error — you don't need to actually succeed in dropping it, just prove the block.

### Look-fors (rubric)

- [ ] The indexed view is created successfully with all SQL Server restrictions satisfied (`COUNT_BIG`, `SCHEMABINDING`, two-part names, unique clustered index first).
- [ ] The automatic, transactional update after the `INSERT` is demonstrated.
- [ ] The schema-change block is captured with its error message.
- [ ] Everything is cleaned up (index, view, inserted test row).

---

## P5 — Views for Column and Row Security  *(Medium)*

**Tags:** `security-views` `column-restriction` `row-restriction`

### Requirements

1. Create `app.vw_UserDirectory` exposing every `app.Users` column **except** `HourlyRate`.
2. Explain, in a comment, the exact condition under which this view provides real security (who must NOT have direct table permissions) versus when it provides none.
3. Create `app.vw_MyDirectReports`, parameterised via `SESSION_CONTEXT`, that returns only the direct reports of a given manager. Test it by setting the session context to Grace Hopper's `UserId` (2) and confirming the result matches her known direct reports.
4. Explain why SQL Server's dedicated Row-Level Security feature (name it) is the more robust tool than this view pattern for a requirement that must hold even against users with base-table access.

### Deliverable

`P5-security-views.sql`.

### Hints

- `EXEC sp_set_session_context @key = N'CurrentUserId', @value = 2;` sets the session context for testing.
- Grace Hopper's (`UserId` 2) direct reports are Linus Torvalds (4) and Margaret Hamilton (5).

### Look-fors (rubric)

- [ ] `HourlyRate` is genuinely absent from the view's column list.
- [ ] The "real security only if..." explanation is precise (no `SELECT` grant on the base table).
- [ ] The session-context-driven view correctly returns exactly Linus Torvalds and Margaret Hamilton for manager 2.
- [ ] Row-Level Security is correctly named as the more robust alternative, with a reason.

---

## P6 — Synonyms for Location Abstraction and Cutover  *(Hard)*

**Tags:** `synonyms` `blue-green-cutover` `environment-abstraction`

### Requirements

1. Create `app.CurrentTasks` as a synonym for `app.Tasks`, and confirm querying it returns identical results to querying `app.Tasks` directly.
2. Create a scratch table `app.Tasks_v2` (a structurally identical copy via `SELECT INTO`, plus a `PRIMARY KEY` so it's a fair comparison) with one extra row not present in `app.Tasks`.
3. Simulate a zero-downtime cutover: drop and recreate `app.CurrentTasks` to point at `app.Tasks_v2` instead, and confirm a query using the **same unchanged synonym name** now returns the extra row.
4. Cut back to `app.Tasks` and drop `app.Tasks_v2` and the synonym.
5. Build a comparison table (as a comment) contrasting synonyms, views, and linked servers across at least four dimensions, and state which one is the right tool for "our application's connection string always points at `app.ReportingSource`, but which physical table that means changes twice a year."

### Deliverable

`P6-synonyms-cutover.sql`. Ensure the database ends in its original state (no leftover synonym or scratch table).

### Hints

- `CREATE SYNONYM` cannot be `ALTER`ed — cutover means `DROP SYNONYM` then `CREATE SYNONYM` again pointing elsewhere, which is why the cutover is a two-statement operation, not a single atomic one (worth noting as a caveat).

### Look-fors (rubric)

- [ ] The synonym correctly proxies `app.Tasks` in step 1.
- [ ] The cutover in step 3 is demonstrated with the same query text before and after, showing different underlying data.
- [ ] Final state has zero leftover objects.
- [ ] The comparison table correctly recommends a synonym for the stated environment-abstraction scenario.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All six `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every view, synonym, index, and scratch table created for an experiment is dropped at the end of its own file.
- [ ] Every destructive statement against a **real** TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Build a two-layer pattern like Notes.md §7: a synonym for location, a view on top of the synonym for shape/security, and demonstrate that changing the synonym's target leaves the view's callers unaffected.
- Investigate `sys.dm_exec_query_stats` to confirm, empirically, that querying a plain view produces an identical plan/cost to querying the equivalent hand-written join.
- Research `NOEXPAND` and explain, in a paragraph, the SQL Server Standard vs Enterprise Edition difference in how the optimizer automatically considers indexed views for queries that don't directly reference them.
