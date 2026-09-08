# Topic 20: Performance Tuning & Troubleshooting — Interview Questions

---

## Q1. Describe your general methodology when told "the application is slow," with no other information.
**Answer:**
1. Get a **precise** symptom definition — which feature, since when, under what conditions (not "slow," but "the project dashboard takes 8 seconds, started two weeks ago, only for larger projects").
2. Identify the **specific query** responsible using measurement (plan cache/Query Store, live session DMVs) — never guess.
3. Classify the bottleneck category using **wait statistics** — CPU, I/O, locking, or memory each point to a different fix.
4. Form **one** hypothesis and test it in isolation.
5. Verify the fix under **realistic concurrent load**, not just a single idle-server execution.
6. Document what changed and why.

---

## Q2. Why should you check wait statistics before looking at a specific execution plan?
**Answer:**
Wait statistics tell you the **category** of problem — CPU pressure, I/O, locking/blocking, or memory — before you invest time examining any single query's plan. If the actual bottleneck is a lock held by an entirely different session, spending an hour tuning a query's indexes accomplishes nothing, because that query was never the real constraint; it was simply waiting on something else.

---

## Q3. What's the difference between the plan cache (`sys.dm_exec_query_stats`) and Query Store for finding a regression?
**Answer:**
The plan cache reflects **whatever is currently cached** — it's wiped on service restart, plan eviction under memory pressure, or a recompile, so it has no memory of history. **Query Store** persists query and plan history to disk over time, explicitly tracking multiple plans per query and their performance over time — making it purpose-built for "this got slower, when did it change, and what changed" in a way the plan cache fundamentally cannot answer on its own.

---

## Q4. What does `PAGEIOLATCH_*` wait type generally indicate, and what's a typical fix?
**Answer:**
A session is waiting for a data page to be physically read from disk into the buffer pool — indicating an I/O bottleneck, often from a missing index forcing a larger scan than necessary, insufficient buffer pool memory causing pages to be evicted and re-read, or genuinely slow underlying storage. The typical fix targets the root cause: add the supporting index (Topic 13) to reduce the pages that must be read, rather than simply provisioning faster storage as a first response.

---

## Q5. What does `LCK_M_*` wait type generally indicate?
**Answer:**
A session is waiting to acquire a lock (shared, exclusive, etc.) held by another session — this is blocking (Topic 17), made visible in the aggregate wait statistics. High cumulative `LCK_M_*` wait time points toward long-running transactions holding locks too long, missing indexes causing broader-than-necessary locking, or lock escalation from unbatched large DML operations.

---

## Q6. Why is `sys.dm_os_wait_stats` cumulative, and why does that matter for analysis?
**Answer:**
It accumulates from the last service restart with no automatic reset — reading it directly on a server that's been up for months mixes years of background noise with whatever specific five-minute workload you're actually investigating. The correct technique is to **snapshot** the view before a reproduction window, generate/observe the workload, snapshot again afterward, and **diff** the two snapshots by wait type — isolating exactly what changed during your specific window of interest.

---

## Q7. What is the relationship between `modification_counter` and automatic statistics updates?
**Answer:**
`modification_counter` (visible via `sys.dm_db_stats_properties`) tracks how many rows have changed since a statistic was last updated. `AUTO_UPDATE_STATISTICS` (on by default) triggers an automatic refresh once enough rows have changed relative to the table's size — but a very large table can accumulate a large **absolute** number of changes while still being a small **percentage**, meaning a large bulk load can leave statistics meaningfully stale well before the automatic threshold fires. This is why proactively running `UPDATE STATISTICS` after a large data load is good practice rather than relying solely on the automatic mechanism.

---

## Q8. Your query's actual plan shows a "memory grant spilled to tempdb" warning. What does this mean, and what's the real fix?
**Answer:**
The optimizer estimated how much memory a sort/hash operation would need, based on its row-count estimate, and reserved (granted) that much — but the operation actually needed more, so it spilled intermediate results to tempdb, which is dramatically slower than an in-memory operation. The warning icon itself is a **symptom**, not the root cause — the real fix is almost always correcting the underlying row-count estimate (updating stale statistics, fixing a non-SARGable predicate, addressing parameter sniffing), not simply granting more memory as a blanket workaround, since a bad estimate will eventually cause a different symptom even if this specific spill is suppressed.

---

## Q9. What DMV would you query to see what's happening on the server *right now*, as opposed to historical aggregates?
**Answer:**
`sys.dm_exec_requests`, typically joined to `sys.dm_exec_sessions` and `sys.dm_exec_sql_text`:

```sql
SELECT r.session_id, r.status, r.wait_type, r.blocking_session_id, r.cpu_time, t.text
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE r.session_id <> @@SPID;
```

This is the first query to run the moment a symptom is actively occurring — it shows exactly what every active session is doing, its current wait state, and whether it's blocked by another session, all in real time.

---

## Q10. Why might rebuilding all indexes "just in case" be a poor troubleshooting strategy, even if the symptom subsequently disappears?
**Answer:**
It changes many things simultaneously (index physical order, potentially triggering statistics updates as a side effect, clearing related cached plans) without measuring which specific change — if any — was the actual fix. The symptom disappearing afterward is not evidence the *rebuild itself* was the cause; it could equally have been the incidental statistics refresh, a plan eviction forcing a recompile, or an unrelated change in workload. This approach also produces no verified, repeatable understanding for the next time a similar symptom appears — the whole point of the methodology in this topic is that a fix should be understood and verified in isolation before being trusted.

---

## Q11. What is the difference between diagnosing fragmentation as a first hypothesis versus a checked possibility?
**Answer:**
Index fragmentation genuinely matters for large range scans, particularly on storage where sequential I/O outperforms random I/O significantly — but it is one of several possible causes of a performance symptom, not the default first assumption. On modern SSD-backed storage its impact is often smaller than commonly believed, and a fragmented index that's rarely accessed via a range scan (e.g. always seeked on a unique key) may not be contributing to the symptom at all. The methodology in this topic treats fragmentation as one specific, checkable hypothesis (via `sys.dm_db_index_physical_stats`) alongside wait statistics and plan analysis — not a step you jump to before gathering broader evidence.

---

## Q12. Design question: a nightly batch job and daytime interactive users share the same database, and users report intermittent slowness that seems to correlate with, but doesn't perfectly match, the batch job's schedule. How would you investigate?
**Answer:**
1. Get **precise timing data** — exact start/end times of user-reported slowness versus the batch job's actual (not scheduled) start/end times, since "correlates with but doesn't perfectly match" suggests the relationship might be indirect (e.g. the batch job's *tail* causing lock/resource contention that outlasts the job itself, or a downstream effect like stale statistics after the batch completes).
2. Snapshot `sys.dm_os_wait_stats` immediately before, during, and after the batch job's actual run to identify which wait category dominates during the overlap window — locking (`LCK_M_*`) would point to the batch job holding locks that block interactive queries; I/O (`PAGEIOLATCH_*`)/memory pressure would point to resource contention rather than blocking.
3. During a live occurrence, run the `sys.dm_exec_requests` live-session query to see directly whether interactive sessions are shown blocked by the batch job's session, or merely slow due to shared resource pressure (CPU/I/O) with no explicit blocking relationship.
4. Check whether the batch job itself is running large, unbatched DML (Topic 10) that could be triggering lock escalation to table-level locks, which would explain contention outlasting individual row-level operations.
5. Check whether the batch job's completion is followed by a statistics update or index maintenance step, and whether the "slowness" the interactive users experience is actually a **subsequent** effect (e.g. plan recompilations happening right after fresh statistics land, momentarily using worse-than-steady-state plans) rather than concurrent contention during the job itself.

The key interview point: "correlates with but doesn't perfectly match" is itself a clue — it argues against a naive first assumption ("the batch job blocks users") and toward investigating a lagged or indirect causal relationship, which only becomes visible with actual timestamped wait-stat and session data, not by assumption.
