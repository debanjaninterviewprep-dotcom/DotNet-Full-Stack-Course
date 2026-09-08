# Topic 01: Relational Databases & SQL Fundamentals — Interview Questions

---

## Q1. Define relation, tuple, attribute, domain, degree and cardinality. Map each to SQL.
**Answer:**
These are Codd's terms from the 1970 relational model; SQL renamed all of them.

| Relational term | SQL term | TaskFlow example |
|---|---|---|
| Relation | Table | `app.Tasks` |
| Tuple | Row | One task |
| Attribute | Column | `app.Tasks.DueDate` |
| Domain | The set of legal values: data type plus constraints | `TINYINT`, further narrowed by `FK_Tasks_Status` |
| Degree | Number of attributes | `ref.Priorities` has degree 4 |
| Cardinality | Number of tuples | `ref.Priorities` has cardinality 5 |

```sql
SELECT  SCHEMA_NAME(t.schema_id) + N'.' + t.name AS TableName,
        COUNT(c.column_id)                       AS Degree
FROM sys.tables  AS t
JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE SCHEMA_NAME(t.schema_id) IN (N'app', N'ref', N'audit')
GROUP BY t.schema_id, t.name
ORDER BY Degree DESC;
```

The distinction that matters in practice: a true relation is a **set** — unordered, no duplicates. A SQL table without a key can hold duplicate rows, and `SELECT` returns a **multiset**. That single deviation is the root of most `DISTINCT` bugs.

---

## Q2. What is the difference between a superkey, a candidate key, a primary key and an alternate key?
**Answer:**
- **Superkey** — any set of attributes that uniquely identifies a row. `{UserId, Email}` in `app.Users`.
- **Candidate key** — a *minimal* superkey: remove any column and uniqueness breaks. `app.Users` has two: `{UserId}` and `{Email}`.
- **Primary key** — the candidate key you nominated. Implies `NOT NULL`, and in SQL Server creates a clustered index by default.
- **Alternate key** — every candidate key you did *not* nominate, normally enforced with `UNIQUE`. `UQ_Users_Email`.

```sql
-- Prove {Email} is a candidate key: zero rows means the uniqueness holds.
SELECT Email, COUNT(*) AS Dupes
FROM app.Users
GROUP BY Email
HAVING COUNT(*) > 1;
```

The trap: `{UserId, Email}` is unique, so candidates who only test uniqueness call it a candidate key. It is not — it is not minimal.

---

## Q3. Surrogate key or natural key? Defend your choice.
**Answer:**
Use a **narrow surrogate as the primary key** and enforce the natural key as a `UNIQUE` constraint alongside it. `app.Projects` does exactly this: `ProjectId INT IDENTITY` is the PK, `UQ_Projects_Code` keeps `ProjectCode` trustworthy.

| Factor | Surrogate | Natural |
|---|---|---|
| Stability | Immutable | Business will rename it |
| Width | 4 bytes | `VARCHAR(10)` = up to 10 bytes, duplicated into every FK and every nonclustered index |
| Update cost | None | Cascades to every child row |
| Readability | Poor | Excellent |
| Security | Leaks row counts if exposed in URLs | Safe |

If `app.Tasks.ProjectId` were `ProjectCode VARCHAR(10)`, then every nonclustered index on `app.Tasks` would silently carry 10 bytes instead of 4, and renaming `TF-MOB` would rewrite task rows, assignment rows and time-entry rows.

The exception is a pure junction table: `app.TaskLabels` has PK `(TaskId, LabelId)` and needs no surrogate, because the pair *is* the row.

---

## Q4. What is a composite key, and when is it the right choice?
**Answer:**
A key spanning two or more columns. TaskFlow has three: `PK_TeamMembers (TeamId, UserId)`, `PK_TaskAssignments (TaskId, UserId)`, `PK_TaskLabels (TaskId, LabelId)`.

It is right when the relationship *is* the identity — a many-to-many junction with no attributes of its own worth identifying independently. It becomes wrong the moment the junction grows child tables of its own, because every child then has to carry both columns.

```sql
SELECT c.name AS KeyColumn, ic.key_ordinal
FROM sys.key_constraints AS kc
JOIN sys.index_columns   AS ic ON ic.object_id = kc.parent_object_id
                              AND ic.index_id  = kc.unique_index_id
JOIN sys.columns         AS c  ON c.object_id  = ic.object_id
                              AND c.column_id  = ic.column_id
WHERE kc.name = N'PK_TeamMembers'
ORDER BY ic.key_ordinal;
```

Column order in a composite key is not cosmetic: it determines the clustered index key order and therefore which range seeks are possible. `(TeamId, UserId)` supports "all members of a team" efficiently; "all teams for a user" needs a separate index.

---

## Q5. What does a foreign key actually enforce, and what do the `ON DELETE` options do?
**Answer:**
A foreign key enforces **referential integrity**: every non-`NULL` value in the child column must exist in the referenced candidate key of the parent. It does *not* create an index on the child column — a very common and expensive misconception.

| `ON DELETE` action | Behaviour |
|---|---|
| `NO ACTION` (default) | Block the parent delete with error 547 |
| `CASCADE` | Delete the child rows too |
| `SET NULL` | Set the child FK column to `NULL` (column must be nullable) |
| `SET DEFAULT` | Set it to the column's `DEFAULT` |

```sql
SELECT  fk.name AS ForeignKeyName,
        OBJECT_SCHEMA_NAME(fk.parent_object_id) + N'.' + OBJECT_NAME(fk.parent_object_id) AS ChildTable,
        fk.delete_referential_action_desc AS OnDelete,
        fk.is_not_trusted
FROM sys.foreign_keys AS fk
ORDER BY ChildTable;
```

In TaskFlow, `FK_TaskAssign_Task`, `FK_TaskLabels_Task`, `FK_Comments_Task` and `FK_TimeEntries_Task` cascade — deleting a task removes its assignments, labels, comments and time entries. `audit.TaskHistory` deliberately has **no** FK so audit rows survive.

Follow-up they will ask: *what is an untrusted foreign key?* One created or re-enabled with `WITH NOCHECK`. The optimizer stops using it to eliminate joins, so you lose plan quality silently.

---

## Q6. Name the five SQL sublanguages with one statement each.
**Answer:**

| Sublanguage | Statements | TaskFlow example |
|---|---|---|
| **DDL** | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` | `CREATE TABLE app.TaskWatchers (...)` |
| **DML** | `INSERT`, `UPDATE`, `DELETE`, `MERGE` | `UPDATE app.Tasks SET StatusId = 6 WHERE TaskId = 5;` |
| **DQL** | `SELECT` | `SELECT TaskId, Title FROM app.Tasks;` |
| **DCL** | `GRANT`, `REVOKE`, `DENY` | `GRANT SELECT ON SCHEMA::app TO TaskFlowReporting;` |
| **TCL** | `BEGIN TRAN`, `COMMIT`, `ROLLBACK`, `SAVE TRAN` | Wrapping a status change and its audit row |

Some sources fold DQL into DML, giving four. Say so — it shows you know the taxonomy is a convention, not a standard.

---

## Q7. Is DDL transactional? Can you roll back a `CREATE TABLE`?
**Answer:**
In **SQL Server and PostgreSQL, yes.** DDL participates fully in the transaction.

```sql
BEGIN TRANSACTION;
    CREATE TABLE app.TaskWatchers (TaskId INT NOT NULL, UserId INT NOT NULL);
    SELECT OBJECT_ID(N'app.TaskWatchers') AS ExistsInsideTran;   -- non-NULL
ROLLBACK TRANSACTION;
SELECT OBJECT_ID(N'app.TaskWatchers') AS ExistsAfterRollback;    -- NULL
```

In **Oracle and MySQL**, DDL performs an implicit commit — any open transaction is committed before the DDL runs, and the DDL itself cannot be rolled back. This is why SQL Server migration tooling can wrap an entire schema change in one atomic transaction and MySQL tooling cannot.

Caveat for SQL Server: `TRUNCATE TABLE` is fully rollback-able (it is minimally logged, not unlogged), but it will not run if the table is referenced by a foreign key.

---

## Q8. What is the logical query processing order, and why does it matter?
**Answer:**
```
FROM -> ON -> JOIN (outer rows re-added) -> WHERE -> GROUP BY -> HAVING
     -> SELECT -> DISTINCT -> ORDER BY -> TOP / OFFSET-FETCH
```

It matters because it is the **semantic contract**: it defines what a query *means*, independent of how the optimizer executes it. Three whole classes of bug are explained by it and nothing else:

1. `SELECT` aliases are invisible to `WHERE`, `GROUP BY` and `HAVING`, but visible to `ORDER BY`.
2. On an outer join, a predicate in `ON` runs before the `NULL` rows are added; the same predicate in `WHERE` runs after and removes them.
3. `TOP` without `ORDER BY` is non-deterministic, because `TOP` slices a set that was never ordered.

```sql
-- Msg 207: Invalid column name 'TaskCount'. WHERE (4) precedes SELECT (6).
SELECT p.ProjectName, COUNT(*) AS TaskCount
FROM app.Projects AS p
JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
WHERE TaskCount > 3
GROUP BY p.ProjectName;

-- Correct: group-level filter goes in HAVING; ORDER BY can see the alias.
SELECT p.ProjectName, COUNT(*) AS TaskCount
FROM app.Projects AS p
JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
GROUP BY p.ProjectName
HAVING COUNT(*) > 3
ORDER BY TaskCount DESC;
```

State explicitly that *physical* execution order is whatever the optimizer chooses. It will push `WHERE` predicates below joins whenever that is provably equivalent.

---

## Q9. What is the difference between `WHERE` and `HAVING`?
**Answer:**
`WHERE` filters **rows** before grouping (step 4). `HAVING` filters **groups** after aggregation (step 5b). `HAVING` can reference aggregates; `WHERE` cannot.

```sql
-- Both, doing different jobs: WHERE removes archived projects before grouping;
-- HAVING removes low-volume projects after counting.
SELECT p.ProjectCode, COUNT(t.TaskId) AS OpenTasks
FROM app.Projects AS p
JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
WHERE p.IsArchived = 0
  AND t.StatusId NOT IN (6, 7)
GROUP BY p.ProjectCode
HAVING COUNT(t.TaskId) >= 3
ORDER BY OpenTasks DESC;
```

Performance note worth mentioning: a non-aggregate predicate belongs in `WHERE`, not `HAVING`. `HAVING p.IsArchived = 0` is legal only if `IsArchived` is grouped, and it forces the engine to aggregate rows it will then discard.

---

## Q10. A predicate in `ON` versus the same predicate in `WHERE` — when do they differ?
**Answer:**
Never for an **inner** join. Always potentially for an **outer** join.

```sql
-- 8 rows minimum: every project survives, non-Done tasks show as NULL.
SELECT p.ProjectCode, t.Title
FROM app.Projects AS p
LEFT JOIN app.Tasks AS t
       ON t.ProjectId = p.ProjectId
      AND t.StatusId  = 6;

-- The LEFT JOIN silently becomes an INNER JOIN: NULL = 6 is UNKNOWN,
-- so every placeholder row is filtered out at step 4.
SELECT p.ProjectCode, t.Title
FROM app.Projects AS p
LEFT JOIN app.Tasks AS t ON t.ProjectId = p.ProjectId
WHERE t.StatusId = 6;
```

The second form is not an error, which is what makes it dangerous — it returns plausible-looking results that are quietly missing rows. The exception is the anti-join idiom, where filtering on `NULL` after the join is exactly the intent:

```sql
-- Projects with no tasks at all.
SELECT p.ProjectCode
FROM app.Projects AS p
LEFT JOIN app.Tasks AS t ON t.ProjectId = p.ProjectId
WHERE t.TaskId IS NULL;
```

---

## Q11. Explain `NULL` and three-valued logic. Why does `NOT IN` with `NULL`s return nothing?
**Answer:**
`NULL` is a marker for "unknown" or "not applicable", not a value. Any comparison with it evaluates to **UNKNOWN**. `WHERE` and `ON` keep only rows that evaluate to **TRUE**, so `UNKNOWN` rows are discarded.

```sql
SELECT COUNT(*) FROM ref.Priorities WHERE SlaHours =  NULL;  -- 0
SELECT COUNT(*) FROM ref.Priorities WHERE SlaHours IS NULL;  -- 1
SELECT COUNT(*) AS Rows, COUNT(SlaHours) AS NonNull FROM ref.Priorities;  -- 5, 4
```

`NOT IN` expands to a chain of `<>` joined by `AND`:

```sql
-- Intent: "users who manage nobody". Returns ZERO rows.
-- app.Users.ManagerId contains NULL (users 1 and 20), so the expansion is
--   UserId <> 1 AND UserId <> 2 AND ... AND UserId <> NULL
-- and the final term is UNKNOWN, making the whole AND-chain UNKNOWN.
SELECT u.Email
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);

-- NULL-safe: NOT EXISTS tests row existence, never equality.
SELECT u.Email
FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.Users AS m WHERE m.ManagerId = u.UserId);
```

Add the asymmetry that separates a mid-level answer from a senior one: `WHERE` keeps only `TRUE`, but a `CHECK` constraint rejects only `FALSE`. That is why `CK_Users_HourlyRate` accepts `NULL` even though `NULL >= 0` is `UNKNOWN`.

---

## Q12. Why does a `UNIQUE` constraint in SQL Server allow only one `NULL`?
**Answer:**
Because SQL Server's uniqueness comparison treats `NULL`s as **equal to each other**, the same way `GROUP BY`, `DISTINCT`, `UNION` and `ORDER BY` do. Two `NULL`s therefore look like a duplicate.

```sql
-- GROUP BY collapses the NULLs into a single group, despite NULL <> NULL.
SELECT SlaHours, COUNT(*) AS Cnt
FROM ref.Priorities
GROUP BY SlaHours;
```

The ISO standard says a `UNIQUE` constraint should permit **many** `NULL`s, and PostgreSQL and Oracle follow the standard. SQL Server's workaround is a filtered unique index:

```sql
-- Standard-compliant uniqueness: enforced only over non-NULL values.
CREATE UNIQUE INDEX UX_Teams_LeadUserId
    ON app.Teams (LeadUserId)
    WHERE LeadUserId IS NOT NULL;

DROP INDEX UX_Teams_LeadUserId ON app.Teams;
```

---

## Q13. What is a page? What is an extent? Why should an application developer care?
**Answer:**
- **Page** — 8 KB, the smallest unit SQL Server reads or writes. Roughly 8,060 bytes are usable for row data.
- **Extent** — 8 contiguous pages, 64 KB, the allocation and read-ahead unit.

A row cannot span pages (LOB and row-overflow data are the exception, and they cost an extra pointer chase). So row width directly determines rows-per-page, which determines pages-per-table, which determines I/O and buffer-pool pressure.

```sql
SET STATISTICS IO ON;
SELECT COUNT(*) FROM app.Tasks AS t;
SET STATISTICS IO OFF;
-- "logical reads" is a count of 8 KB pages touched, not rows.

SELECT  OBJECT_NAME(p.object_id)      AS TableName,
        SUM(p.rows)                   AS RowCounts,
        SUM(au.total_pages)           AS Pages,
        SUM(au.total_pages) * 8 / 1024.0 AS MB
FROM sys.partitions       AS p
JOIN sys.allocation_units AS au ON au.container_id = p.partition_id
WHERE p.index_id IN (0, 1)
  AND OBJECT_SCHEMA_NAME(p.object_id) IN (N'app', N'ref', N'audit')
GROUP BY p.object_id
ORDER BY Pages DESC;
```

The practical consequence: choosing `NVARCHAR(4000)` where `NVARCHAR(100)` would do does not just waste declared length — it wrecks the optimizer's memory-grant estimate, and if the data is actually wide it halves your rows per page and doubles your I/O.

---

## Q14. What are `master`, `model`, `msdb` and `tempdb`?
**Answer:**

| Database | Holds | Consequence of loss |
|---|---|---|
| `master` | Logins, endpoints, linked servers, the catalog of all databases | Instance will not start |
| `model` | The template for every new database | New databases lose defaults; edits here affect all future databases |
| `msdb` | SQL Agent jobs and schedules, backup history, Database Mail | Jobs and backup history gone |
| `tempdb` | `#temp` tables, table variables, sort and hash spills, the row-version store | Recreated from `model` on every restart |

```sql
SELECT database_id, name, state_desc, recovery_model_desc
FROM sys.databases
ORDER BY database_id;   -- 1 master, 2 tempdb, 3 model, 4 msdb
```

`tempdb` is the one that shows up in production incidents. It is shared by every database on the instance, it is where snapshot isolation stores row versions, and a single runaway query spilling a hash join can fill it and stall everything else.

---

## Q15. What is `GO`? Is it a T-SQL keyword?
**Answer:**
No. `GO` is a **batch separator** understood by client tools — `sqlcmd`, SSMS, Azure Data Studio, the VS Code `mssql` extension. It is never sent to the server. Send `GO` through `SqlCommand` in ADO.NET and you get a syntax error.

```sql
DECLARE @Cutoff DATE = '2025-09-01';
SELECT COUNT(*) FROM app.Tasks WHERE DueDate < @Cutoff;
GO
-- SELECT @Cutoff;   -- Msg 137: Must declare the scalar variable "@Cutoff".
```

Points that separate a strong answer:
- Variables and `SET` options are **batch**-scoped; `#temp` tables are **session**-scoped and survive `GO`.
- `CREATE PROCEDURE` / `VIEW` / `FUNCTION` / `TRIGGER` / `SCHEMA` must be the first statement in a batch. That is why `00-create-taskflow-db.sql` writes `EXEC (N'CREATE SCHEMA app')` — it makes the `CREATE SCHEMA` a nested batch and sidesteps `Msg 111`.
- `GO 5` repeats the batch five times; useful for generating load, and not a T-SQL loop.

---

## Q16. What is a collation, and how can one break a query's performance?
**Answer:**
A collation defines the code page for non-Unicode types, the sort order, and the comparison sensitivity rules. Read `SQL_Latin1_General_CP1_CI_AS` as: legacy SQL sort rules, code page 1252, **C**ase **I**nsensitive, **A**ccent **S**ensitive.

Collation applies at server, database, column and expression level; the most specific wins.

```sql
SELECT SERVERPROPERTY('Collation')                    AS ServerCollation,
       DATABASEPROPERTYEX(N'TaskFlowDb', 'Collation') AS DbCollation;

-- Matches 'TF-CORE' under a CI collation.
SELECT ProjectId FROM app.Projects WHERE ProjectCode = 'tf-core';

-- Zero rows -- and non-SARGable: COLLATE on the column side forces a scan
-- plus a per-row conversion, so no index seek is possible.
SELECT ProjectId
FROM app.Projects
WHERE ProjectCode COLLATE Latin1_General_100_CS_AS = 'tf-core';
```

The performance answer is the important half: any function or collation applied to the **column** side of a predicate destroys SARGability. The correct fixes are to change the column's collation, or to store a pre-normalised persisted computed column and index that.

Also worth naming: `_SC` enables supplementary characters (needed for emoji and rare CJK), and `_UTF8` (SQL Server 2019+) lets `VARCHAR` store UTF-8, which can halve storage for Latin-dominant text versus `NVARCHAR`.

---

## Q17. *(Senior)* Explain the plan cache. What destroys plan reuse, and what is parameter sniffing?
**Answer:**
The optimizer is expensive, so SQL Server caches compiled plans keyed by a hash of the query text plus a set of SET options. Reuse requires **byte-identical** text (whitespace and case included) and identical SET options.

What destroys reuse:
- **String-concatenated SQL.** `'... WHERE ProjectId = ' + CAST(@id AS VARCHAR)` produces a distinct plan per value, bloating the cache and forcing a compile every time. It is also an injection vector (Topic 19).
- Differing `SET` options between connections — the classic reason a query is fast in SSMS and slow from .NET (`ARITHABORT` defaults differ).
- Unqualified object names, which produce one cache entry per calling user's default schema. This is a concrete reason to always write `app.Tasks`.

**Parameter sniffing** is the optimizer using the *first* parameter value it sees to estimate cardinality, then caching that plan. It is normally a benefit. It becomes a production incident when the data is skewed:

```sql
-- Compiled for @ProjectId = 7 (TF-LAB, 3 tasks) the optimizer picks a nested
-- loop with key lookups. That same cached plan applied to @ProjectId = 1
-- (TF-CORE, 9 tasks today, 900k in production) becomes pathological.
CREATE OR ALTER PROCEDURE app.usp_GetProjectTasks @ProjectId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.TaskId, t.Title, t.StatusId
    FROM app.Tasks AS t
    WHERE t.ProjectId = @ProjectId;
END;
GO

EXEC app.usp_GetProjectTasks @ProjectId = 7;
EXEC app.usp_GetProjectTasks @ProjectId = 1;
GO
DROP PROCEDURE IF EXISTS app.usp_GetProjectTasks;
```

Mitigations, in ascending order of bluntness: fix the statistics; `OPTIMIZE FOR UNKNOWN`; local-variable assignment to defeat sniffing; `RECOMPILE` (per-execution compile cost); a Query Store forced plan; or splitting the procedure by cardinality class. Name the trade-off for whichever you pick — that is what the question is really testing.

---

## Q18. *(Senior)* SQL is declarative. Walk me through how you diagnose a query that suddenly got slow.
**Answer:**
Declarative means you specify *what*; the optimizer chooses *how*. "Suddenly slow" therefore almost always means the *how* changed, not the *what*.

The order I work in:

1. **Confirm the change.** Query Store (`sys.query_store_runtime_stats`) or `sys.dm_exec_query_stats` — did duration, CPU, or logical reads move? Which one moved tells you the class of problem.
2. **Compare plans.** Query Store keeps plan history per query. A plan regression is the single most common cause.
3. **Check cardinality estimates versus actuals** in the actual plan. A 1000x divergence on one operator points at stale statistics, a non-SARGable predicate, or a table-variable estimate of 1 row.
4. **Check SARGability.** Functions on columns (`WHERE YEAR(t.DueDate) = 2025`), implicit conversions (`NVARCHAR` parameter against a `VARCHAR` column), leading wildcards, and `COLLATE` on the column side all turn seeks into scans.
5. **Check for blocking, not slowness.** `sys.dm_exec_requests` with `wait_type` and `blocking_session_id`. A query waiting on `LCK_M_S` is not slow; it is queued.
6. **Only then consider the query text.**

```sql
-- Non-SARGable: YEAR() on the column forces a scan of every row.
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE YEAR(t.DueDate) = 2025;

-- SARGable rewrite: a half-open range the engine can seek.
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE t.DueDate >= '2025-01-01'
  AND t.DueDate <  '2026-01-01';
```

The counterpart trap is the imperative reflex — reaching for a cursor because the set-based version is hard to write. That gives up the optimizer entirely and typically costs one to three orders of magnitude.

---

## Q19. *(Architect)* When do you split TaskFlow's OLTP and OLAP workloads, and how?
**Answer:**
Not on principle — on a **measured trigger**. Something falsifiable, such as: *p95 board-load latency exceeds 300 ms while the nightly reporting window is active, and the correlation holds across three consecutive days.*

The characteristics genuinely conflict:

| | OLTP | OLAP |
|---|---|---|
| Query | Few rows, indexed seeks | Millions of rows, scans |
| Schema | Normalised (3NF) | Denormalised star/snowflake |
| Indexes | Many narrow rowstore | Columnstore |
| Contention | Short locks, high concurrency | Long scans, buffer-pool eviction |

The escalation ladder, cheapest first:

1. **Fix the queries.** Most "we need a warehouse" claims are one missing index and one non-SARGable predicate.
2. **Read-scale-out.** An Azure SQL geo-replica or an Always On readable secondary with `ApplicationIntent=ReadOnly`. Zero schema change; you accept replica lag.
3. **Nonclustered columnstore on the OLTP tables.** Real-time operational analytics: scans use the columnstore, transactions use the rowstore. Costs write throughput.
4. **A separate analytical store** — Synapse or Microsoft Fabric — fed by an ETL/ELT pipeline. Only now do you take on pipeline latency, a second schema, and reconciliation work.

For TaskFlow the fact table for the cycle-time question would be `FactTaskCompletion`, grain **one row per completed task**, measures `CycleTimeHours` and `LoggedHours`, dimensions `DimDate`, `DimTeam`, `DimProject`, `DimPriority`. State the grain first; every modelling error downstream traces back to a fuzzy grain.

The organisational point matters as much as the technical one: the moment you split, you own a reconciliation problem. Someone will ask why the dashboard and the app disagree, and the answer will be "the pipeline ran at 02:00".

---

## Q20. *(Architect)* How do you decide between a relational database and a NoSQL store?
**Answer:**
"NoSQL" is four families with different trade-offs, so the first move is refusing the binary framing.

| Question | Relational | NoSQL |
|---|---|---|
| Does one business operation change several entities atomically? | Yes | No |
| Do you need queries you have not designed for yet? | Yes | No |
| Are relationships many-to-many, queried from both directions? | Yes | No |
| Must you exceed one machine's *write* throughput? | No | Yes |
| Is every access "fetch one aggregate by id"? | No | Yes |
| Do regulators require enforced referential integrity? | Yes | No |

Applied per TaskFlow subsystem:

- **Core task graph** — relational, unambiguously. Tasks to projects to teams to users, many-to-many labels and assignments, queried from every direction, with a compliance-driven audit trail.
- **Presence ("who is viewing this task")** — key-value (Redis). Ephemeral, TTL-based, sub-millisecond, and losing it costs nothing.
- **Activity feed** — append-only, read by recency, never joined. A document store or a partitioned relational table both work; choose relational unless write volume forces otherwise, because you already operate one.

Frame the trade-off as **ACID versus BASE**, and be precise about CAP: it applies only to a *partitioned* system, and the choice it forces is between consistency and availability *during a partition*, not in general. A single-node SQL Server is not making a CAP trade-off at all.

Finally, name the hybrid you already have: `app.Tasks.MetadataJson` is a document inside a relational row. It is pragmatic while the JSON is write-mostly and read whole. It becomes debt the moment someone needs "all tasks in epic `foundation`" filtered and sorted, because that is a scan with a `JSON_VALUE` call per row unless you promote the path to a persisted computed column and index it.

```sql
-- The query that turns the JSON escape hatch into technical debt.
SELECT t.TaskId, t.Title
FROM app.Tasks AS t
WHERE JSON_VALUE(t.MetadataJson, '$.epic') = N'foundation';
```

---
