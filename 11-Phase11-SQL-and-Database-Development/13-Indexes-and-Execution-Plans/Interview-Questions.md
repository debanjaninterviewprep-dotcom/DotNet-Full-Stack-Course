# Topic 13: Indexes & Execution Plans — Interview Questions

---

## Q1. What is the physical difference between a clustered and a nonclustered index?
**Answer:**
A clustered index physically orders the table's rows by the index key — the leaf level of the clustered index **is** the actual data, so a table can have at most one. A nonclustered index is a separate structure whose leaf level holds the indexed key columns plus a **row locator** back to the base table — either the clustering key (if a clustered index exists) or a Row ID (if the table is a heap). A table can have many nonclustered indexes.

---

## Q2. What is a "heap," and why is it usually not the right default?
**Answer:**
A heap is a table with no clustered index — rows have no defined physical order and are located via a Row ID. Heaps suffer forwarding pointers when a row grows past its original page (adding an extra I/O to follow the pointer), have no natural scan order for range queries, and force every nonclustered index to store a RID rather than a (usually more useful) clustering key. Nearly every table should have a clustered index — typically the primary key.

---

## Q3. What is a Key Lookup, and when does it become a performance problem?
**Answer:**
A Key Lookup happens when a nonclustered index seek finds the matching row(s) but the query needs additional columns not present in that index — so the engine goes back to the clustered index, once per matching row, to fetch them.

```sql
SELECT t.TaskId, t.Title, t.Description FROM app.Tasks AS t WHERE t.ProjectId = 1;
-- Index Seek on IX_Tasks_ProjectId + Key Lookup x 9 (Title, Description not in the index)
```

It's fine for a handful of rows; it becomes a serious problem when it executes thousands or millions of times, since each lookup is effectively a random I/O. The fix is a **covering index** — adding the missing columns via `INCLUDE`.

---

## Q4. What's the difference between an index key column and an `INCLUDE`d column?
**Answer:**
Key columns are used for seeking, filtering, joining, or ordering, and are present at **every level** of the B-tree — they count toward the 900-byte/16-column key size limit. `INCLUDE`d columns exist **only at the leaf level**, are never used to navigate the tree, but ride along so a query can be satisfied without a Key Lookup. Any column only ever appearing in the `SELECT` list (never filtered/sorted/joined on) belongs in `INCLUDE`, not the key — it's cheaper to maintain and doesn't count toward the key limits.

---

## Q5. For a composite index, how do you decide column order?
**Answer:**
Equality-filtered columns first (in any order relative to each other), then at most **one** range/inequality/`ORDER BY` column, then everything else only ever selected goes into `INCLUDE`.

```sql
-- WHERE ProjectId = 1 AND StatusId = 3 ORDER BY CreatedAtUtc DESC
CREATE INDEX IX_Tasks_Composite ON app.Tasks (ProjectId, StatusId, CreatedAtUtc DESC) INCLUDE (Title);
```

Only one range column can usefully sit after the equality columns — once the B-tree branches on a range predicate, every column listed after it can no longer be seeked, only scanned-and-filtered within that range.

---

## Q6. What is selectivity, and how does it influence whether the optimizer uses an index?
**Answer:**
Selectivity is the ratio of distinct values to total rows for a column. High selectivity (e.g. a primary key, or an email address) makes an equality seek return very few rows, which is cheap. Low selectivity (e.g. a status flag with 2–3 possible values) means an equality predicate might still match a large fraction of the table — at that point, a full scan is often cheaper than seeking plus doing a Key/RID Lookup for a large percentage of all rows. The optimizer makes this decision using **statistics** (a histogram of value frequencies), not a fixed rule of thumb.

---

## Q7. What is a filtered index, and name two good use cases for one.
**Answer:**
An index with a `WHERE` clause, covering only a subset of the table's rows — smaller to store and cheaper to maintain than a full index.

```sql
CREATE INDEX IX_Tasks_Open ON app.Tasks (ProjectId, DueDate) WHERE StatusId NOT IN (6, 7);
```

Good use cases: a soft-delete table where almost every query filters `WHERE IsDeleted = 0`, and enforcing "unique among non-NULL values" (a filtered unique index) — the fix for SQL Server's `UNIQUE` constraint allowing only one NULL (Topic 11).

---

## Q8. What's the difference between `SET STATISTICS IO ON` and the estimated vs. actual execution plan?
**Answer:**
`SET STATISTICS IO ON` reports **logical/physical reads per table** for the statement as text output — a quick way to see I/O cost without opening a graphical plan. The **estimated** plan shows the optimizer's chosen strategy without running the query (fast, useful for structural review). The **actual** plan runs the query and additionally reports **Actual Rows** per operator alongside **Estimated Rows** — the single most useful diagnostic number, because a large gap between the two signals stale statistics, parameter sniffing, or a non-SARGable predicate.

---

## Q9. Your query's actual plan shows Estimated Rows = 5 but Actual Rows = 500,000 at one operator. What do you check first?
**Answer:**
Statistics freshness first — run `UPDATE STATISTICS` on the relevant table(s) and re-check, since a large under-estimate is the classic signature of stale or low-sample statistics. If statistics are current, check for **parameter sniffing** (the plan was compiled for a different parameter value with very different selectivity) and **non-SARGable predicates** (a function wrapped around the filtered column prevents the optimizer from using the index's histogram accurately). Index redesign is a later step, not the first one — a bad row-count estimate usually means the optimizer's *model* of the data is wrong, and no index fixes a wrong model.

---

## Q10. What does `sys.dm_db_missing_index_details` tell you, and what's its biggest limitation?
**Answer:**
It's the engine's own log of "I would have used an index like this, had it existed" — surfaced whenever a query's plan would have benefited from an index that wasn't there, including suggested equality/inequality/included columns and an estimated impact score. Its biggest limitation: it's a **suggestion engine, not a mandate**. It doesn't know your actual write volume (so it can't weigh the read benefit against write cost), doesn't consider indexes that already almost cover the need, and resets on every service restart/failover. Always investigate and design deliberately rather than blindly creating every suggested index.

---

## Q11. What causes index fragmentation, and how do you fix it?
**Answer:**
Page splits — caused by inserts landing in the middle of existing pages (e.g. a random `GUID` key) or updates that grow a row past its current page's free space — leave pages out of logical order and partially empty. Fix based on measured fragmentation from `sys.dm_db_index_physical_stats`: under roughly 10% fragmentation, do nothing; 10–30%, `ALTER INDEX ... REORGANIZE` (online, defragments the leaf level only); above 30%, `ALTER INDEX ... REBUILD` (rewrites the whole index; use `ONLINE = ON` where available to avoid blocking).

---

## Q12. Why isn't "add an index for every WHERE clause" a good strategy?
**Answer:**
Every index is a write cost paid on every `INSERT`/`UPDATE`/`DELETE` that touches an indexed column — the engine must maintain every index containing that column, not just the base table. Indexing every filter clause ever written accumulates indexes that are rarely read but always maintained, which slows down writes for no corresponding benefit. The better process: index for queries that run often and matter (dashboards, hot API paths, confirmed via the missing-index DMVs and query-stats DMVs), and periodically audit `sys.dm_db_index_usage_stats` for indexes with high `user_updates` and near-zero `user_seeks`/`user_scans`/`user_lookups` — those are candidates for removal.

---

## Q13. How would you find the single most expensive query currently running on a server, without a monitoring tool?
**Answer:**
Query the plan cache directly:

```sql
SELECT TOP (10)
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS AvgCpuMicrosec,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    qt.text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.total_logical_reads DESC;
```

Sort by `total_logical_reads` for I/O-bound pain, `total_worker_time` for CPU-bound pain, or `execution_count` for sheer call-volume issues — the right sort column depends on which resource is actually under pressure, which you'd confirm from server-level wait statistics or resource monitoring first.

---

## Q14. Design question: a reporting query joins a 200,000-row time-entry table to `Tasks` and `Users`, groups by user and month, and takes 8 seconds. Walk through your diagnostic process.
**Answer:**
1. **Capture the actual execution plan** and identify the single most expensive operator by cost percentage — for a large `GROUP BY` over a join, this is usually a `Sort` or `Hash Match`.
2. **Compare Estimated vs Actual Rows** at that operator and at the join. A large mismatch means statistics or parameter sniffing, not indexing, is the first thing to fix.
3. **Check for missing/unused indexes** — is the join predicate (e.g. `TaskId`, `UserId`) actually indexed on the large table? Is the date-range filter SARGable?
4. **Design the index deliberately** — likely a covering index on the time-entry table keyed on the filter/join columns, including the columns needed for the aggregate, following the equality-then-range-then-include ordering rule.
5. **Re-measure** — logical reads before and after, and the plan's new most-expensive operator (there is always a new bottleneck; confirm it's now acceptable rather than assuming the job is done).
6. **Check the plan cache** (`sys.dm_exec_query_stats`) to confirm the fix actually reduced the query's real-world cost and execution count didn't just move the pain elsewhere (e.g. onto a background job re-running it many times per minute).

The key interview point: diagnosis before treatment — an execution plan and its row-count estimates tell you *what kind* of fix is needed (statistics, index, or query rewrite) before you touch any DDL.
