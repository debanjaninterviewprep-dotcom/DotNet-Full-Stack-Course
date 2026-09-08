# Topic 13: Indexes & Execution Plans

> Every query in this course so far has run correctly against 35 rows. TaskFlow in production has millions. The difference between a report that returns in 40ms and one that times out is almost never the SQL syntax — it's whether the right index exists, and whether you can read the execution plan well enough to know. This topic covers how indexes are physically structured, how the optimizer chooses (or fails to choose) to use them, and the systematic process for turning a slow query into a fast one.

---

## 1. The Physical Structure: B-Trees and Heaps

Every SQL Server index — clustered or nonclustered — is a **B+ tree**: a balanced tree of 8KB pages, root at the top, leaf pages at the bottom holding the actual data (or pointers to it), with intermediate levels enabling `O(log n)` seeks.

| Table state | Structure |
|---|---|
| No clustered index | **Heap** — rows in no particular order, located via a Row ID (RID) |
| Clustered index exists | Rows are physically **stored in leaf pages, ordered by the key** — the table *is* the index |

```sql
USE TaskFlowDb;
GO
SELECT OBJECT_NAME(i.object_id) AS TableName, i.name AS IndexName, i.type_desc, i.is_unique
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('app.Tasks');
-- PK_Tasks: CLUSTERED, is_unique = 1 -- app.Tasks has no heap; the clustered PK IS the table.
```

> **Rule of thumb:** A table without a clustered index (a heap) is rarely the right default. Heaps suffer forwarding pointers after row growth, have no natural scan order, and every nonclustered index must store a 8-byte RID instead of the (usually narrower, always more useful) clustering key. Give almost every table a clustered index — usually the primary key.

---

## 2. Clustered vs Nonclustered

| | Clustered | Nonclustered |
|---|---|---|
| How many per table | **Exactly 0 or 1** | Up to 999 |
| Leaf level contains | The actual row data | Index key columns + a **row locator** back to the base table |
| Row locator to base table | n/a (leaf **is** the data) | Clustering key (if clustered index exists) or RID (if heap) |
| Best default choice | Primary key, or the most common range-scan/ORDER BY column | Any column frequently filtered/joined/sorted that isn't the clustering key |

```sql
CREATE TABLE app.Example (
    Id INT IDENTITY PRIMARY KEY,          -- clustered by default
    ProjectId INT NOT NULL
);
CREATE NONCLUSTERED INDEX IX_Example_ProjectId ON app.Example (ProjectId);
-- Leaf row of IX_Example_ProjectId: (ProjectId, Id) -- Id is the row locator back to the clustered index.
```

> **Anti-pattern:** Clustering on a wide or frequently-updated column. Every nonclustered index carries a copy of the clustering key at its leaf level — a wide clustering key bloats **every other index** on the table. Updating the clustering key value physically **moves the row**, which is expensive and fragments the table.

---

## 3. Reading an Execution Plan: Seek vs Scan vs Lookup

```sql
SET STATISTICS IO ON;

SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.TaskId = 5;
-- Clustered Index Seek on PK_Tasks. Logical reads: 2.

SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.EstimatedHours > 30;
-- Clustered Index Scan (no index on EstimatedHours) -- every row inspected. Logical reads: ~5.
```

| Operator | What it means | Cost shape |
|---|---|---|
| **Seek** | Navigates the B-tree directly to matching row(s) using the index key | O(log n) — cheap, scales |
| **Scan** | Reads every leaf page of an index/table in order | O(n) — cheap on tiny tables, expensive at scale |
| **Key Lookup** (clustered table) | A nonclustered seek found matching keys, then goes **back to the clustered index** per row for columns not in the nonclustered index | One extra random I/O **per row** — deadly at high row counts |
| **RID Lookup** (heap) | Same idea as a Key Lookup, but against a heap using the Row ID | Same cost profile as Key Lookup |

```sql
CREATE INDEX IX_Tasks_ProjectId ON app.Tasks (ProjectId);

SELECT t.TaskId, t.Title, t.Description
FROM app.Tasks AS t
WHERE t.ProjectId = 1;
-- Index Seek on IX_Tasks_ProjectId (finds 9 matching TaskIds)
-- + Key Lookup on PK_Tasks x 9 (fetches Title, Description not present in IX_Tasks_ProjectId)
-- + Nested Loops joining them together.
```

A Key Lookup is not automatically bad for 9 rows — it becomes bad when it runs thousands or millions of times. The fix is almost always to **cover** the query (§4).

> **Rule of thumb:** Seek good, Scan suspicious-at-scale, Lookup-repeated-many-times a red flag. Always check the **row count** each operator actually processes (hover the operator in the graphical plan, or read `Actual Rows`) — a Scan of 8 rows is irrelevant; a Scan of 8 million is the whole problem.

---

## 4. Covering Indexes and `INCLUDE`

A **covering index** contains every column the query needs — in the key, in `INCLUDE`, or both — so the engine never has to leave the nonclustered index to satisfy the query. No Key Lookup, full stop.

```sql
-- Fixes the Key Lookup above: Title and Description ride along at the leaf level.
CREATE INDEX IX_Tasks_ProjectId_Covering
    ON app.Tasks (ProjectId)
    INCLUDE (Title, Description);

SELECT t.TaskId, t.Title, t.Description FROM app.Tasks AS t WHERE t.ProjectId = 1;
-- Index Seek on IX_Tasks_ProjectId_Covering only. No Key Lookup.
```

| Key column | `INCLUDE` column |
|---|---|
| Used for seeking/filtering/`ORDER BY`, or joining | Only ever selected/returned, never filtered/sorted on |
| Counts toward the 900-byte/16-column key limit | No practical width limit, doesn't count toward key limits |
| Present at every level of the B-tree | Present **only at the leaf level** — cheaper to add |

> **Rule of thumb:** Never put a column in the key that is only ever `SELECT`ed. `INCLUDE` it instead — smaller non-leaf pages, cheaper index maintenance, same query benefit.

---

## 5. Choosing Index Column Order

For a composite index, column order determines what the index can seek on. The rule is **equality columns first, then the single range/sort column, then anything only ever selected (as `INCLUDE`)**.

```sql
-- Query: filter ProjectId (=), filter StatusId (=), sort by CreatedAtUtc, select Title.
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE t.ProjectId = 1 AND t.StatusId = 3
ORDER BY t.CreatedAtUtc DESC;

CREATE INDEX IX_Tasks_Composite
    ON app.Tasks (ProjectId, StatusId, CreatedAtUtc DESC)
    INCLUDE (Title);
```

Get the order wrong (`CreatedAtUtc` before `StatusId`) and the index can still be used, but only for a **range scan** across `CreatedAtUtc`'s full span filtered by a residual predicate — not a tight seek on all three.

> **Rule of thumb:** Only **one** range/inequality/`ORDER BY` column can be usefully placed after the equality columns in a single index — once the tree branches on a range, every column after it can no longer be seeked, only scanned-and-filtered within that range.

---

## 6. Index Selectivity and the Optimizer's Choice

**Selectivity** = distinct values ÷ total rows. High selectivity (many distinct values, e.g. `Email`) makes an index highly effective for equality seeks. Low selectivity (few distinct values, e.g. `IsActive` with only `0`/`1`) usually means the optimizer prefers a scan — reading the whole table is cheaper than seeking, bookmark-looking-up, and re-assembling a large fraction of it.

```sql
SELECT
    COUNT(DISTINCT StatusId) AS DistinctStatuses,   -- 7
    COUNT(*) AS TotalRows,                            -- 35
    CAST(COUNT(DISTINCT StatusId) AS DECIMAL(5,2)) / COUNT(*) AS Selectivity  -- 0.20 -- low
FROM app.Tasks;
```

The optimizer decides seek-vs-scan using **statistics** — a histogram of up to 200 steps over the leading index column, kept in `sys.stats`, sampled or fully scanned, and refreshed automatically once enough rows change (`AUTO_UPDATE_STATISTICS`, on by default).

```sql
DBCC SHOW_STATISTICS ('app.Tasks', 'IX_Tasks_ProjectId') WITH HISTOGRAM;
-- Shows RANGE_HI_KEY, EQ_ROWS, AVG_RANGE_ROWS per step -- this is what cardinality estimation reads.
```

> **Anti-pattern:** Indexing a `BIT` or a 2–3 value status column **alone**. Low cardinality on its own rarely helps — combine it with a higher-selectivity column (composite index) or accept the scan.

---

## 7. Filtered Indexes

An index with a `WHERE` clause — smaller, cheaper to maintain, and can enforce uniqueness over a subset (Topic 11's fix for "unique among non-NULLs").

```sql
-- Most queries only care about OPEN tasks -- index just that slice.
CREATE INDEX IX_Tasks_Open
    ON app.Tasks (ProjectId, DueDate)
    WHERE StatusId NOT IN (6, 7);

-- Statistics and index size only reflect the ~22 open tasks, not all 35.
```

Filtered indexes are ideal for: soft-delete tables (`WHERE IsDeleted = 0`), status-based hot subsets, and the nullable-unique pattern (`WHERE JiraKey IS NOT NULL`). The optimizer will only use a filtered index when it can **prove** the query's `WHERE` clause is a subset of the filter — an exact literal match is safest; parameterised queries sometimes fail to match a filtered index unless the predicate is written identically.

---

## 8. Included Columns vs Separate Indexes, and Index Maintenance Cost

Every index is a **write cost**, not just a read benefit — each `INSERT`/`UPDATE`/`DELETE` that touches an indexed column must also update every index containing that column.

```sql
-- app.Tasks has: PK_Tasks (clustered) + whatever nonclustered indexes exist.
-- An INSERT into app.Tasks writes to the clustered index AND every nonclustered index, every time.
SELECT i.name, i.type_desc FROM sys.indexes AS i WHERE i.object_id = OBJECT_ID('app.Tasks');
```

| Consideration | Read impact | Write impact |
|---|---|---|
| Adding a covering index | Fewer/no Key Lookups | One more index to maintain on every write |
| Adding `INCLUDE` columns | Same seek, more leaf data returned | Slightly larger leaf pages to maintain |
| Wide composite key | More seekable predicates | Every included nonclustered index carries the whole key at leaf level too (via clustering key) |

> **Rule of thumb:** Don't create an index for every `WHERE` clause you've ever written. Index for the queries that actually run often and matter (dashboards, hot API paths), and periodically check `sys.dm_db_index_usage_stats` for indexes with high writes and near-zero reads — those are pure overhead.

---

## 9. Finding Missing and Unused Indexes

```sql
-- Missing index suggestions -- the optimizer's own "I would have used this" log.
SELECT
    d.statement AS TableName,
    d.equality_columns, d.inequality_columns, d.included_columns,
    s.user_seeks, s.avg_total_user_cost, s.avg_user_impact
FROM sys.dm_db_missing_index_details AS d
JOIN sys.dm_db_missing_index_groups AS g ON g.index_handle = d.index_handle
JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle
ORDER BY s.avg_user_impact DESC;

-- Unused indexes -- maintained on every write, never used to satisfy a read.
SELECT OBJECT_NAME(i.object_id) AS TableName, i.name AS IndexName,
       s.user_seeks, s.user_scans, s.user_lookups, s.user_updates
FROM sys.indexes AS i
LEFT JOIN sys.dm_db_index_usage_stats AS s
    ON s.object_id = i.object_id AND s.index_id = i.index_id AND s.database_id = DB_ID()
WHERE i.type_desc = 'NONCLUSTERED'
  AND (s.user_seeks IS NULL OR (s.user_seeks = 0 AND s.user_scans = 0 AND s.user_lookups = 0));
```

> **Caution:** `sys.dm_db_missing_index_details` is a **suggestion engine**, not a mandate — it doesn't know your write volume, doesn't consider indexes that already almost cover the need, and resets on every service restart. Treat it as a starting point for investigation, never as an auto-apply script. `sys.dm_db_index_usage_stats` also resets on restart/failover — a "zero usage" index might just be unlucky timing; correlate over a representative time window before dropping anything.

---

## 10. `SET STATISTICS IO/TIME` and the Actual Execution Plan

Two complementary diagnostic tools:

```sql
SET STATISTICS IO ON;      -- logical reads per table, per statement
SET STATISTICS TIME ON;    -- CPU time and elapsed time to parse/compile/execute

SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.ProjectId = 1;
```

```
Table 'Tasks'. Scan count 1, logical reads 3, physical reads 0, ...
SQL Server Execution Times: CPU time = 0 ms, elapsed time = 1 ms.
```

**Estimated** plan (no execution) is fast to obtain and fine for structural review (which operators, which indexes). **Actual** plan (statement runs) additionally shows **Actual Rows** per operator versus the optimizer's **Estimated Rows** — the single most useful number in performance tuning, because a large gap between estimated and actual is the signature of stale statistics, a bad parameter sniff, or a non-SARGable predicate (Topic 03).

```sql
SET STATISTICS XML ON;    -- returns the actual plan as queryable XML alongside the results
```

> **Rule of thumb:** If Estimated Rows and Actual Rows differ by an order of magnitude anywhere in a plan, stop looking at the SQL and start looking at statistics freshness (`UPDATE STATISTICS`) and parameter sniffing before you touch indexes at all.

---

## 11. `sys.dm_exec_query_stats` and the Plan Cache

Beyond a single query's plan, the whole server-wide picture lives in the plan cache:

```sql
SELECT TOP (10)
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS AvgCpuMicrosec,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(qt.text) ELSE qs.statement_end_offset END
          - qs.statement_start_offset)/2) + 1) AS StatementText
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY qs.total_logical_reads DESC;
```

This is how you find "the query that's actually killing the server" without guessing — sort by total logical reads, total worker (CPU) time, or execution count, depending on whether the symptom is I/O pressure, CPU pressure, or sheer call volume.

---

## 12. Index Fragmentation and Maintenance

Page splits (from random-order inserts, or updates that grow a variable-length column past its current page) leave pages **out of logical order** and **partially empty** — fragmentation.

```sql
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS ips
JOIN sys.indexes AS i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC;
```

| Fragmentation | Action |
|---|---|
| < 10% | Do nothing |
| 10–30% | `ALTER INDEX … REORGANIZE` — online, low-priority, defragments leaf level only |
| > 30% | `ALTER INDEX … REBUILD` — rewrites the whole index; `ONLINE = ON` (Enterprise/Azure SQL) avoids blocking |

```sql
ALTER INDEX IX_Tasks_ProjectId ON app.Tasks REORGANIZE;
ALTER INDEX IX_Tasks_ProjectId ON app.Tasks REBUILD WITH (ONLINE = ON, FILLFACTOR = 90);
```

`FILLFACTOR` leaves free space per leaf page at rebuild time, trading some wasted space for fewer immediate page splits from subsequent inserts — most useful on indexes with a non-sequential insert pattern (e.g. a `UNIQUEIDENTIFIER` key without `NEWSEQUENTIALID()`).

---

## Mental Model

> An index is a B-tree that trades write cost for read speed, and every design decision in this topic is that same trade in a different shape: a clustered index physically orders the table by its key, so choose it once and choose it narrow; a covering index moves columns from "fetched via a per-row Key Lookup" to "already sitting at the leaf level," turning a linear cost into a flat one; column order in a composite index encodes which predicates can be **seeked** versus merely **scanned-and-filtered**, and only one range column ever gets to seek. None of this is guesswork — the optimizer's choice is driven by statistics and selectivity you can inspect directly, and the actual execution plan's Estimated-vs-Actual row counts tell you, concretely, whether the optimizer's model of your data matches reality. Read the plan first, check `sys.dm_db_missing_index_details` and `sys.dm_exec_query_stats` for where the real pain is, and only then design the index — adding indexes speculatively just moves the cost from every read to every write.

Move to [Practice Problems](./Practice-Problems.md).
