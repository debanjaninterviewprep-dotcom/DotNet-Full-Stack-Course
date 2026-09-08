# Topic 20: Performance Tuning & Troubleshooting

> Topics 13 and 17 gave you the two biggest levers — indexes and concurrency — in isolation. Production TaskFlow presents them tangled together: a dashboard that got slow sometime in the last month, with no single obvious cause, competing for the same server as a nightly import job and forty concurrent users. This topic is the methodology for that situation — a repeatable process for going from "it's slow" to a specific, verified fix, plus the wait-stats and query-store tooling that makes the process evidence-based rather than guesswork.

---

## 1. A Repeatable Tuning Methodology

Performance tuning without a process degenerates into "try things and hope." The process:

1. **Define the symptom precisely.** Not "the app is slow" — "the project dashboard takes 8 seconds to load for project TF-CORE, starting sometime in the last two weeks, only during business hours."
2. **Identify the specific query/queries responsible.** Never guess — measure (§2).
3. **Classify the bottleneck**: CPU-bound, I/O-bound, or lock/wait-bound (§3). Each has a different fix.
4. **Form one hypothesis and test it in isolation.** Change one thing, measure again, keep or discard.
5. **Verify the fix under realistic load**, not just on an idle server — a fix that helps a lone session can make contention *worse* under concurrency (e.g. an index that speeds up reads but adds enough write overhead to create new blocking).
6. **Document what changed and why**, so the next investigation isn't starting from zero.

> **Anti-pattern:** Rebuilding every index, updating every statistic, and restarting the service, "just in case," without ever measuring which — if any — of those actions was the actual fix. This resolves the symptom by accident, teaches you nothing, and cannot be verified to work again next time.

---

## 2. Finding the Actual Culprit Query

```sql
-- Highest total CPU consumers currently in the plan cache.
SELECT TOP (10)
    qs.execution_count,
    qs.total_worker_time, qs.total_worker_time / qs.execution_count AS AvgCpu,
    qs.total_elapsed_time / qs.execution_count AS AvgDurationMicrosec,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(qt.text) ELSE qs.statement_end_offset END
          - qs.statement_start_offset)/2)+1) AS StatementText
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.total_worker_time DESC;
```

| Sort by | Finds |
|---|---|
| `total_worker_time` | Highest total CPU consumption |
| `total_logical_reads` | Highest total I/O (memory-buffer reads) |
| `total_elapsed_time` | Highest total wall-clock time (includes waiting, not just working) |
| `execution_count` | Sheer call volume — a cheap query run a million times can outweigh an expensive one run twice |

**Query Store** (on by default in newer databases; enable explicitly on older ones) is the superior tool for this specific problem — unlike the plan cache, which is wiped on restart/eviction, Query Store **persists** query and plan history to disk, explicitly tracks **plan changes over time**, and is purpose-built for exactly "this got slow, when did it change, and what changed."

```sql
ALTER DATABASE TaskFlowDb SET QUERY_STORE = ON;

-- The single most useful Query Store query: did a query's plan CHANGE, and did it get worse?
SELECT
    qsq.query_id, qsp.plan_id, qsrs.avg_duration, qsrs.avg_logical_io_reads,
    qsrs.last_execution_time
FROM sys.query_store_query AS qsq
JOIN sys.query_store_plan AS qsp ON qsp.query_id = qsq.query_id
JOIN sys.query_store_runtime_stats AS qsrs ON qsrs.plan_id = qsp.plan_id
WHERE qsq.query_id = 42          -- found via the query text search first
ORDER BY qsrs.last_execution_time DESC;
```

> **Rule of thumb:** If the symptom is "this got slower recently" (as opposed to "this has always been slow"), Query Store's plan-history view answers it directly — look for a **plan change** at roughly the time the symptom began, which is the single most common root cause of a sudden regression with no application deployment involved.

---

## 3. Classifying the Bottleneck: Wait Statistics

Every time a session isn't actively running on the CPU, it's **waiting** on something, and SQL Server tracks exactly what.

```sql
SELECT TOP (10)
    wait_type, wait_time_ms, waiting_tasks_count,
    wait_time_ms * 1.0 / NULLIF(waiting_tasks_count, 0) AS AvgWaitMs
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (N'CLR_SEMAPHORE', N'LAZYWRITER_SLEEP', N'SLEEP_TASK', N'BROKER_TASK_STOP')  -- benign/idle waits
ORDER BY wait_time_ms DESC;
```

| Wait type family | Means | Points toward |
|---|---|---|
| `PAGEIOLATCH_*` | Waiting for a data page to be read from disk | I/O bottleneck — missing index, insufficient memory/buffer pool, slow storage |
| `LCK_M_*` (e.g. `LCK_M_X`, `LCK_M_S`) | Waiting for a row/page/table lock | Blocking (Topic 17) — long transactions, missing indexes causing wider locking, lock escalation |
| `CXPACKET` / `CXCONSUMER` | Parallelism coordination overhead | Often not a problem by itself; investigate alongside `SOS_SCHEDULER_YIELD` and actual query cost |
| `SOS_SCHEDULER_YIELD` | A task voluntarily yielded the CPU to let others run | CPU pressure — many queries competing for limited cores |
| `WRITELOG` | Waiting for the transaction log to flush to disk | Log I/O bottleneck — slow storage, or excessive logging from large/unbatched DML |
| `RESOURCE_SEMAPHORE` | Waiting for a memory grant to become available | Memory pressure — often large sort/hash operations from bad estimates or missing indexes |

`sys.dm_os_wait_stats` is **cumulative since the last service restart** — for meaningful analysis, snapshot it before and after a specific reproduction window and diff the two, rather than reading the lifetime totals.

> **Rule of thumb:** Wait statistics tell you the **category** of problem (CPU, I/O, locking, memory) before you look at a single execution plan. Skipping this step and jumping straight to "let's look at the query plan" means you might spend an hour tuning a query that was never actually the bottleneck — it was waiting on a lock held by something else entirely.

---

## 4. `sys.dm_exec_requests` and Live Session Investigation

For "what's happening **right now**," rather than historical aggregates:

```sql
SELECT
    r.session_id, r.status, r.command, r.wait_type, r.wait_time, r.blocking_session_id,
    r.cpu_time, r.total_elapsed_time, r.logical_reads,
    SUBSTRING(t.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text) ELSE r.statement_end_offset END
          - r.statement_start_offset)/2)+1) AS CurrentStatementText
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE r.session_id <> @@SPID
ORDER BY r.cpu_time DESC;
```

This single query answers "who's running what, right now, and is anyone blocked" — the first thing to run when a symptom is actively occurring, before it disappears.

---

## 5. Statistics Freshness

Reread from Topic 13: the optimizer's row-count estimates come from statistics, and stale statistics are one of the most common, most fixable causes of a sudden regression.

```sql
SELECT
    OBJECT_NAME(s.object_id) AS TableName, s.name AS StatName,
    sp.last_updated, sp.rows, sp.rows_sampled, sp.modification_counter
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stat_id) AS sp
WHERE OBJECT_NAME(s.object_id) = 'Tasks';
```

`modification_counter` tracks rows changed since the last statistics update — `AUTO_UPDATE_STATISTICS` (on by default) refreshes automatically once enough rows change, but a very large table can go a long time between auto-updates by percentage, and an aggressive bulk load can make statistics stale **faster than the auto-update threshold catches**.

```sql
UPDATE STATISTICS app.Tasks WITH FULLSCAN;   -- full recompute, most accurate, most expensive
UPDATE STATISTICS app.Tasks;                  -- default sampled update, cheaper, usually sufficient
```

> **Rule of thumb:** After any bulk load, large batch delete, or major data shift, proactively update statistics on the affected tables rather than waiting for the automatic threshold — especially before a scheduled reporting job that will immediately query the freshly-changed data.

---

## 6. Fragmentation Revisited, at Scale

Topic 13 covered the mechanics; at the troubleshooting stage, fragmentation is one specific, checkable hypothesis among several, not the default first guess.

```sql
SELECT OBJECT_NAME(ips.object_id) AS TableName, i.name AS IndexName,
       ips.avg_fragmentation_in_percent, ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS ips
JOIN sys.indexes AS i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 500  -- ignore tiny indexes; fragmentation on them is noise
ORDER BY ips.avg_fragmentation_in_percent DESC;
```

> **Rule of thumb:** Fragmentation matters most for large range scans on spinning/networked storage; on modern SSD-backed storage its impact is smaller than online folklore suggests. Check it, but don't assume it's the cause without also checking waits and plan quality — a fragmented index that's rarely scanned in a range is not your bottleneck.

---

## 7. `tempdb` Contention

`tempdb` is shared by every database on the instance — worktables (spools, sorts, hash joins), row versioning (RCSI/SNAPSHOT, Topic 17), temp tables/table variables, and `MERGE`/DML internals all compete for it.

```sql
-- PFS/GAM/SGAM contention shows up as PAGELATCH waits on tempdb specifically.
SELECT wait_type, wait_time_ms FROM sys.dm_os_wait_stats
WHERE wait_type LIKE 'PAGELATCH%' ORDER BY wait_time_ms DESC;
```

Common causes: too few tempdb data files for the core count (Microsoft's general guidance is to configure multiple, equally-sized tempdb data files to reduce allocation-page contention), an unusually large number of concurrent `#temp` table creations, or wide-scale RCSI/SNAPSHOT version-store pressure from long-running transactions preventing old row versions from being cleaned up.

---

## 8. `Actual` Execution Plan Warnings

The graphical actual plan surfaces specific warning icons the optimizer itself flags — always read these before anything else in the plan:

| Warning | Meaning | Typical fix |
|---|---|---|
| **Missing statistics** | The optimizer needed statistics it couldn't find | Enable/run `AUTO_CREATE_STATISTICS`, or explicitly `UPDATE STATISTICS` |
| **Type conversion (implicit)** on an indexed column | A comparison forces a conversion, defeating index usage (Topic 02/03) | Match the parameter's declared type to the column's type exactly |
| **Excessive memory grant / memory grant spilled to tempdb** | The optimizer under-estimated rows, granted too little memory for a sort/hash, and it spilled to disk | Fix the underlying estimate (statistics, SARGability) rather than the symptom |
| **No join predicate** | A join with no `ON` condition — an accidental cross join | Check the query for a missing/incorrect join condition |

---

## 9. Query Rewrite Patterns That Actually Help

Beyond indexing, a handful of rewrite patterns consistently move the needle:

```sql
-- Split a large OR into a UNION ALL when each branch could use a DIFFERENT index seek.
-- (An OR across two different columns often forces a scan; UNION ALL lets each half seek.)
SELECT TaskId FROM app.Tasks WHERE ProjectId = 1 OR CreatedByUserId = 4;
-- vs.
SELECT TaskId FROM app.Tasks WHERE ProjectId = 1
UNION
SELECT TaskId FROM app.Tasks WHERE CreatedByUserId = 4;

-- Push a filter into a derived table BEFORE a join, rather than filtering after,
-- when the pre-filter meaningfully shrinks what the join has to process.
SELECT p.ProjectCode, o.Tasks
FROM (SELECT ProjectId, COUNT(*) AS Tasks FROM app.Tasks WHERE StatusId NOT IN (6,7) GROUP BY ProjectId) AS o
JOIN app.Projects AS p ON p.ProjectId = o.ProjectId;

-- Replace NOT IN over a nullable column with NOT EXISTS -- correctness AND performance (Topic 07).
```

---

## 10. Putting It Together: A Worked Diagnostic Narrative

*Symptom:* "The project task list API endpoint has gone from ~50ms to 3–4 seconds over the past week, only for larger projects."

1. **Query Store** shows the endpoint's underlying query has the **same** `query_id` but a **new** `plan_id` starting six days ago — a plan change, not a code change (no deployment that week).
2. **Comparing plans**: the old plan used an Index Seek + Key Lookup on `IX_Tasks_ProjectId`; the new plan uses a full Clustered Index Scan.
3. **Wait stats** for the endpoint's session profile show elevated `PAGEIOLATCH_SH` — consistent with a scan reading far more pages than the old seek-based plan did.
4. **Hypothesis**: statistics on `app.Tasks` went stale after a large data load, causing the optimizer to mis-estimate selectivity and choose a scan over a seek for this parameter shape (a parameter-sniffing-adjacent regression, Topic 15 §6, but rooted in statistics rather than caching).
5. **Test**: `UPDATE STATISTICS app.Tasks WITH FULLSCAN;` on a copy/staging environment first, then re-run the query and confirm the plan reverts to the seek.
6. **Verify under load**: replay a representative concurrent workload, confirm both response time and plan choice are stable, not just correct for a single lone execution.
7. **Fix and document**: apply in production during a low-traffic window, and add (or tighten) a scheduled statistics-maintenance job so this doesn't silently recur.

Notice every step is evidence, not guesswork — the fix was identified *before* it was applied, and verified *after*.

---

## Mental Model

> Performance tuning is a diagnostic discipline, not a bag of tricks — the process is always the same regardless of the symptom: define it precisely, find the actual query with data (the plan cache or, better, Query Store) rather than a guess, classify the bottleneck by category using wait statistics before touching a single execution plan, form one hypothesis, test it in isolation, and verify under real concurrency because a fix that helps one session can make contention worse for forty. Every tool in this topic answers one specific question in that process — `sys.dm_exec_query_stats` and Query Store answer "which query, and did its plan change," wait statistics answer "what category of problem," `sys.dm_exec_requests` answers "what's happening right now," and statistics/fragmentation checks answer "does the optimizer's model of the data still match reality." None of them is a substitute for the process itself — the actual discipline is refusing to apply a fix you haven't measured, and refusing to declare victory until you've verified it under the load that will actually hit it in production.

Move to [Practice Problems](./Practice-Problems.md).
