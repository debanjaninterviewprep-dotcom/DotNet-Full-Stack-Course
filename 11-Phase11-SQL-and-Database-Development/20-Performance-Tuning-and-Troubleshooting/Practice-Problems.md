# Topic 20: Performance Tuning & Troubleshooting — Practice Problems

> Six exercises applying the diagnostic methodology end to end — wait stats, Query Store, live session investigation, and statistics freshness — culminating in a full worked incident. Several problems benefit from the larger synthetic dataset built in Topic 13.

**Concept tags:** `wait-statistics` `query-store` `sys-dm-exec-requests` `statistics-freshness` `tempdb-contention` `diagnostic-methodology`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Reading Wait Statistics  *(Easy)*

**Tags:** `wait-statistics` `sys-dm-os-wait-stats`

### Requirements

1. Query `sys.dm_os_wait_stats`, excluding the benign/idle wait types listed in Notes.md §3, and report the top 10 by total wait time.
2. Snapshot the results into a `#WaitsBefore` temp table.
3. Generate some artificial load (e.g. a large `CROSS JOIN`-based query, or the synthetic table from Topic 13 if available) and re-snapshot into `#WaitsAfter`.
4. Diff the two snapshots (by wait type) to find which specific waits increased during your artificial workload, and explain in a comment why snapshotting-and-diffing is necessary rather than reading the lifetime cumulative view directly.

### Deliverable

`P1-wait-statistics.sql`.

### Hints

- `sys.dm_os_wait_stats` accumulates since the last service restart — a fresh server has mostly zeros; a long-running one has months of noise mixed with your five-second experiment unless you diff.

### Look-fors (rubric)

- [ ] The excluded benign wait types are correctly filtered out.
- [ ] The before/after diff correctly isolates waits attributable to the generated workload.
- [ ] The snapshot-and-diff reasoning is correctly explained.

---

## P2 — Finding the Culprit Query via the Plan Cache  *(Easy)*

**Tags:** `sys-dm-exec-query-stats` `sql-text-offsets`

### Requirements

1. Run three or four different queries against `app.Tasks`/`app.Projects` with deliberately different costs (e.g. one simple seek, one full scan, one with a sort).
2. Query `sys.dm_exec_query_stats` joined to `sys.dm_exec_sql_text`, correctly using the statement offset columns to extract just the relevant statement text (not the whole batch).
3. Sort by `total_logical_reads` and confirm your most expensive query (by I/O) is correctly identified at the top.
4. Re-sort by `execution_count` after running your cheapest query many times in a loop, and confirm the ranking changes to reflect volume rather than per-call cost.

### Deliverable

`P2-plan-cache-culprit.sql`.

### Hints

- The offset arithmetic (`statement_start_offset/2`, handling `-1` for `statement_end_offset`) is fiddly — get it right once and keep it as a reusable snippet.

### Look-fors (rubric)

- [ ] The extracted statement text correctly matches just the relevant statement, not extra surrounding text.
- [ ] The I/O-sorted ranking correctly surfaces the scan/sort-heavy query at the top.
- [ ] The volume-sorted ranking correctly changes after the loop, demonstrating the two sort orders answer different questions.

---

## P3 — Query Store: Detecting a Plan Regression  *(Medium)*

**Tags:** `query-store` `plan-regression` `forced-plans`

### Requirements

1. Enable Query Store on `TaskFlowDb`.
2. Run a parameterised query (as a stored procedure, to make it easy to force a specific plan shape) several times with a parameter value chosen to compile a particular plan.
3. Force a statistics update or an artificial data change designed to make a **different** plan preferable for the same query, and run it again — confirm Query Store recorded a second `plan_id` for the same `query_id`.
4. Query `sys.query_store_runtime_stats` to compare the two plans' average duration/logical reads.
5. If the newer plan is worse, use `sp_query_store_force_plan` to force the better one, and confirm subsequent executions use it.
6. Unforce the plan and disable Query Store if you don't want it enabled going forward.

### Deliverable

`P3-query-store-regression.sql`.

### Hints

- Forcing two genuinely different plans for the *same* logical query on this small a table is somewhat artificial — document clearly what you did to induce the second plan (e.g. an index added/dropped between runs, or a parameter sniffing scenario from Topic 15).

### Look-fors (rubric)

- [ ] Query Store correctly shows two distinct `plan_id`s for one `query_id`.
- [ ] The runtime-stats comparison correctly identifies which plan is better by a concrete metric.
- [ ] `sp_query_store_force_plan` is correctly applied and subsequently verified.

---

## P4 — Live Session Investigation  *(Medium — requires two sessions)*

**Tags:** `sys-dm-exec-requests` `live-diagnostics` `blocking`

### Requirements

1. **Session A:** start a deliberately slow query (e.g. a large unindexed scan, or an open transaction holding a lock) and leave it running/open.
2. **Session B (or a third window):** query `sys.dm_exec_requests` joined to `sys.dm_exec_sessions` and `sys.dm_exec_sql_text`, reporting `session_id`, `status`, `wait_type`, `blocking_session_id`, `cpu_time`, and the currently executing statement text for every active request.
3. Confirm you can identify Session A's query and its current wait state from this output alone, without knowing in advance what Session A was running.
4. Let Session A finish (or roll back), and confirm it disappears from the live results.

### Deliverable

`P4-live-session-investigation.sql`, sessions clearly labelled.

### Hints

- This is the single query you'd run first, in production, the moment someone says "something is slow right now."

### Look-fors (rubric)

- [ ] The live-session query correctly surfaces Session A's activity with accurate wait/blocking information.
- [ ] The statement-text extraction correctly identifies what Session A is actually running.
- [ ] The session correctly disappears from the results once finished.

---

## P5 — Statistics Staleness and Its Consequences  *(Medium)*

**Tags:** `statistics-freshness` `modification-counter` `update-statistics`

### Requirements

1. Query `sys.dm_db_stats_properties` for `app.Tasks`'s statistics, reporting `last_updated`, `rows`, and `modification_counter`.
2. Insert/update/delete a meaningful number of rows (using a scratch table if you don't want to permanently alter the seeded row count — or the synthetic table from Topic 13) and re-check `modification_counter`.
3. Capture an execution plan's estimated row count for a query filtering on the changed data **before** updating statistics, and again **after** running `UPDATE STATISTICS ... WITH FULLSCAN`, and compare the estimates against the actual row count.
4. Explain, in a comment, the relationship between `modification_counter`, the auto-update threshold, and why a large bulk load can outpace automatic statistics maintenance.

### Deliverable

`P5-statistics-staleness.sql`.

### Hints

- On a 35-row real table, meaningful percentage-based staleness is easiest to demonstrate using the larger synthetic table from Topic 13, if you still have it (recreate if needed).

### Look-fors (rubric)

- [ ] `modification_counter` is correctly shown increasing after the data change.
- [ ] The before/after estimated-row-count comparison correctly shows improved accuracy after `UPDATE STATISTICS`.
- [ ] The auto-update-threshold explanation is accurate and specific.

---

## P6 — Full Diagnostic Narrative: Reproduce and Resolve a Regression  *(Hard)*

**Tags:** `end-to-end` `diagnostic-methodology` `worked-incident`

### Requirements

Using the synthetic large table from Topic 13 (recreate if needed) and everything from this topic:

1. Deliberately induce a plan regression — e.g. build an index that makes a query fast, then invalidate the optimizer's confidence in it (stale statistics after a large data change, or a competing index that confuses the choice), such that the same query now performs materially worse.
2. Following the methodology in Notes.md §1 and the worked narrative in §10, produce a **written diagnostic report** (as a comment block) with each of the seven numbered steps from §10 completed for **your own** induced scenario: symptom, culprit query identification, plan comparison, wait-stats correlation, hypothesis, tested fix, and verification under a repeated/looped workload (not just once).
3. Apply the fix and demonstrate the query returns to its original performance profile, with before/after numbers for at least two metrics (e.g. logical reads and elapsed time).
4. Clean up all scratch objects.

### Deliverable

`P6-full-diagnostic-narrative.sql`, containing both the executable reproduction/fix and the written report as a structured comment block.

### Hints

- This problem is intentionally open-ended in *which* regression you induce — the rigor of the methodology you demonstrate matters more than the specific scenario.

### Look-fors (rubric)

- [ ] All seven diagnostic steps from Notes.md §10 are addressed for the student's own scenario, not copied verbatim from the example.
- [ ] The regression and its fix are both genuinely demonstrated with real captured numbers, not asserted.
- [ ] Verification includes a repeated/looped workload, not a single lucky execution.
- [ ] All scratch objects are cleaned up.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All six deliverables exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every diagnostic claim (which query is the culprit, which wait type dominates, whether a plan changed) is backed by captured output, not asserted.
- [ ] Query Store, if enabled for these exercises, is left in a documented state (forced plans unforced, disabled if not needed going forward).
- [ ] All scratch/synthetic tables are dropped at the end of their own files.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Set up an Extended Events session tracking `sql_statement_completed` filtered to `TaskFlowDb`, and use it as a lighter-weight alternative to Query Store for a short-duration investigation.
- Investigate `sys.dm_os_performance_counters` for buffer cache hit ratio and page life expectancy, and correlate a drop in either with a workload you generate.
- Research the "Query Store for secondary replicas" feature (if using Availability Groups) and write a paragraph on why read-workload tuning on a replica needs its own Query Store visibility.
