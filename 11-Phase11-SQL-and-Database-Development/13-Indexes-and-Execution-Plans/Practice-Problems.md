# Topic 13: Indexes & Execution Plans — Practice Problems

> Seven exercises that build the diagnostic habit: look at the plan first, form a hypothesis, then design the index. All against the seeded `TaskFlowDb` — small enough that some effects need a larger synthetic table, which several problems ask you to build.

**Concept tags:** `clustered-index` `nonclustered-index` `covering-index` `key-lookup` `composite-index` `selectivity` `filtered-index` `missing-index-dmv` `fragmentation` `execution-plan`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Reading Seek vs Scan vs Key Lookup  *(Easy)*

**Tags:** `execution-plan` `seek` `scan` `key-lookup`

### Requirements

1. With `SET STATISTICS IO ON`, run a query filtering `app.Tasks` by `TaskId = 5` and record the operator and logical reads.
2. Run a query filtering `app.Tasks` by `EstimatedHours > 30` (no supporting index yet) and record the operator.
3. Create `IX_Tasks_ProjectId ON app.Tasks (ProjectId)`, then run a query selecting `TaskId, Title, Description WHERE ProjectId = 1`. Identify the Key Lookup in the plan and explain, in a comment, exactly why it's there.
4. Drop the index at the end of the script.

### Deliverable

`P1-seek-scan-lookup.sql`.

### Hints

- The graphical plan's tooltip (or `SET STATISTICS XML ON`) shows `Actual Rows` per operator — use it, don't guess.

### Look-fors (rubric)

- [ ] Step 1 correctly identifies a Clustered Index Seek.
- [ ] Step 2 correctly identifies a Clustered Index Scan.
- [ ] The Key Lookup explanation correctly names the missing columns (`Title`, `Description`) as the cause.
- [ ] The index is dropped at the end.

---

## P2 — Eliminating a Key Lookup with a Covering Index  *(Easy)*

**Tags:** `covering-index` `include` `key-lookup`

### Requirements

1. Reproduce the Key Lookup from P1 step 3.
2. Replace the index with a covering version using `INCLUDE (Title, Description)` and confirm the Key Lookup disappears.
3. Explain, in a comment, why `Title`/`Description` belong in `INCLUDE` rather than in the index key.
4. Compare `sys.dm_db_index_usage_stats` columns available for both index versions (conceptually — you don't need historical data) and state which practical signal you'd actually use to decide if the covering index is worth its write cost.

### Deliverable

`P2-covering-index.sql`.

### Hints

- Key vs `INCLUDE`: only columns used for seeking/filtering/sorting need to be in the key.

### Look-fors (rubric)

- [ ] The before/after plans are both shown, with the Key Lookup present then absent.
- [ ] The key-vs-include reasoning is correct (unused for seek/sort/filter → `INCLUDE`).
- [ ] The write-cost tradeoff argument references a genuine usage signal (e.g. `user_seeks` vs `user_updates`), not just "it should be fine."

---

## P3 — Composite Index Column Order  *(Medium)*

**Tags:** `composite-index` `column-order` `range-predicate`

### Requirements

1. For the query `WHERE ProjectId = 1 AND StatusId = 3 ORDER BY CreatedAtUtc DESC`, create a composite index with the **correct** column order (equality columns first, then the sort column) plus a covering `INCLUDE`.
2. Create a second, deliberately **wrong-ordered** index (sort column before an equality column) for the same query, and compare the two plans.
3. Explain in a comment, referencing "only one range column can seek," why the wrong-ordered version produces a less efficient plan even though it technically satisfies the query.
4. Drop both indexes at the end.

### Deliverable

`P3-composite-column-order.sql`.

### Hints

- "Wrong-ordered" here means putting `CreatedAtUtc` before `StatusId` in the key list.

### Look-fors (rubric)

- [ ] Both index versions are created and both plans are captured for comparison.
- [ ] The correct-order index produces a tight seek predicate on all three columns.
- [ ] The explanation correctly identifies which column(s) become scan-and-filter rather than seek in the wrong-ordered version.
- [ ] Both indexes are dropped.

---

## P4 — Selectivity and Statistics  *(Medium)*

**Tags:** `selectivity` `statistics` `histogram` `cardinality-estimation`

### Requirements

1. Compute the selectivity (distinct values ÷ total rows) of `app.Tasks.StatusId` and `app.Tasks.TaskId`, and state which is more useful as a standalone index key.
2. Run `DBCC SHOW_STATISTICS` against an index on a low-selectivity column and identify the histogram's `EQ_ROWS` for the most common value.
3. Create an index on `StatusId` alone, then show — via the plan — that the optimizer chooses a scan over a seek for a common status value, but a seek for a rare one (if one exists) or explain why it always scans if none is rare enough.
4. Explain, referencing the actual `EQ_ROWS` numbers you found, why the optimizer's choice is cost-based rather than a fixed rule.

### Deliverable

`P4-selectivity-and-statistics.sql`.

### Hints

- `StatusId` has only 7 distinct values across 35 rows — deliberately low selectivity.
- `TaskId` is the primary key — maximum selectivity by definition.

### Look-fors (rubric)

- [ ] Both selectivity ratios are computed correctly.
- [ ] The histogram inspection correctly reads `EQ_ROWS` for at least one specific value.
- [ ] The scan-vs-seek behavior is demonstrated with actual plans, not just asserted.
- [ ] The final explanation ties the optimizer's choice back to concrete cost numbers.

---

## P5 — Filtered Index for a Hot Subset  *(Medium)*

**Tags:** `filtered-index` `soft-delete-pattern` `predicate-match`

### Requirements

1. Create a filtered index on `app.Tasks (ProjectId, DueDate) WHERE StatusId NOT IN (6, 7)` (the "open tasks" subset).
2. Run a query with a `WHERE` clause that exactly matches the filter predicate plus an additional `ProjectId` filter, and confirm the optimizer uses the filtered index.
3. Run a query whose `WHERE` clause does **not** match the filter (e.g. `WHERE StatusId = 3` alone, without the `NOT IN` framing) and observe whether the optimizer still uses it — explain the result.
4. Compare `sys.dm_db_index_physical_stats` page counts (or just row counts via `sys.dm_db_index_usage_stats`/a manual count) between this filtered index and a hypothetical unfiltered equivalent, and state the storage saving in rows.

### Deliverable

`P5-filtered-index.sql`.

### Hints

- 22 of the 35 seeded tasks are "open" (`StatusId NOT IN (6, 7)`) — that's the row count the filtered index actually covers.

### Look-fors (rubric)

- [ ] The filtered index is created successfully with the exact predicate from Notes.md §7.
- [ ] The matching-predicate query is shown using the filtered index.
- [ ] The non-matching query's behavior is correctly explained (optimizer cannot always prove subset containment).
- [ ] The row-count/storage-saving comparison is numerically correct (22 vs 35).

---

## P6 — Missing Index DMVs on a Larger Synthetic Table  *(Hard)*

**Tags:** `missing-index-dmv` `synthetic-data` `index-usage-stats`

### Requirements

1. Using a cross-joined `VALUES`/`ROW_NUMBER` number series (Topic 07), build a `#BigTimeEntries` table with ~200,000 synthetic rows shaped like `app.TimeEntries` (random-ish `TaskId`, `UserId`, `WorkDate`, `Hours`).
2. Run a query against `#BigTimeEntries` filtering on a column with no supporting index, and check `sys.dm_db_missing_index_details` for a suggestion (note: this DMV only tracks **permanent** tables' indexes in some SQL Server versions for temp tables' behavior — if `#BigTimeEntries` doesn't register, redo this against a **permanent** scratch table `dbo.BigTimeEntriesPermanent` instead, and drop it at the end).
3. Create the suggested index and re-run the query, confirming improved logical reads via `SET STATISTICS IO ON`.
4. Query `sys.dm_db_index_usage_stats` for the new index immediately after use and confirm `user_seeks` incremented.
5. Explain in a comment why the missing-index DMV is a "suggestion engine, not a mandate" — name one thing it does not account for.

### Deliverable

`P6-missing-index-dmv.sql`. Drop all scratch objects at the end.

### Hints

- The DMVs reset on service restart — if results look empty, confirm you're running against a fresh session with no prior identical query cached differently.

### Look-fors (rubric)

- [ ] The synthetic table genuinely reaches ~200,000 rows.
- [ ] A missing-index suggestion is captured (on the permanent scratch table if necessary).
- [ ] The before/after logical reads comparison shows a real improvement.
- [ ] `user_seeks` is confirmed to have incremented after the query ran.
- [ ] The "suggestion, not mandate" limitation is specific (e.g. doesn't know write volume, doesn't consider near-miss existing indexes).

---

## P7 — Diagnose and Fix: A Slow Reporting Query  *(Hard)*

**Tags:** `execution-plan` `estimated-vs-actual` `sys-dm-exec-query-stats` `end-to-end-tuning`

### Requirements

Using the ~200,000-row synthetic table from P6 (recreate if needed):

1. Write a reporting query joining the synthetic time entries to `app.Tasks`/`app.Users`, grouping by user and month, filtering to the last 90 (synthetic) days, ordering by total hours descending.
2. Capture the actual execution plan and identify the single most expensive operator by cost percentage.
3. Compare Estimated Rows vs Actual Rows at that operator. If they diverge significantly, run `UPDATE STATISTICS` on the synthetic table and re-check.
4. Design and create the index(es) needed to remove the most expensive operator, re-run, and report the before/after logical reads and the before/after most-expensive-operator.
5. Query `sys.dm_exec_query_stats` (joined to `sys.dm_exec_sql_text`) to find your own query in the plan cache and report its `total_logical_reads` and `execution_count`.
6. Write a one-paragraph tuning report: symptom, diagnosis, fix, measured improvement.

### Deliverable

`P7-diagnose-and-fix.sql` plus the tuning report as a comment block at the top of the file.

### Hints

- A `GROUP BY` over a large unindexed join is usually dominated by a `Sort` or `Hash Match` — check which.
- `sys.dm_exec_query_stats` matches on the exact SQL text (parameterisation matters) — use a distinctive comment or literal in your query to find it easily.

### Look-fors (rubric)

- [ ] The most expensive operator is correctly identified by actual cost, not guessed.
- [ ] The Estimated-vs-Actual comparison is performed and interpreted correctly.
- [ ] The designed index(es) measurably reduce logical reads (report the before/after numbers).
- [ ] The query is successfully located in `sys.dm_exec_query_stats`.
- [ ] The tuning report is concrete: names the operator, the fix, and a real number for the improvement.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every index created for an experiment is dropped at the end of its own file, unless explicitly needed by a later problem in the same file.
- [ ] Every claim about plan operators or DMV results is backed by an actual captured plan/output, not assumed.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Rebuild P7's index strategy as a filtered index scoped to "the last 90 days" and measure whether it beats the unfiltered version at this data volume.
- Investigate `sys.dm_db_index_physical_stats` fragmentation on the P6/P7 synthetic table after the bulk load, and practice a `REORGANIZE` vs `REBUILD` decision based on the measured percentage.
- Read about columnstore indexes and batch-mode execution (a forward reference to Topic 20) and write two sentences on why they would change P7's answer entirely at true production scale (tens of millions of rows).
