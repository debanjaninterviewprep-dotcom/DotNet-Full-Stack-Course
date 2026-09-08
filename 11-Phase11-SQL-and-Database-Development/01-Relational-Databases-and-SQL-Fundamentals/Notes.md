# Topic 01: Relational Databases & SQL Fundamentals

> Every feature in **TaskFlow** — the board, the burndown chart, the "who is over-allocated this sprint" report, the audit trail your compliance team demands — eventually becomes a query against a relational database. Phase 5 let Entity Framework Core hide that database from you. Phase 11 removes the blindfold. This topic builds the mental model: what a *relation* actually is, how SQL is evaluated (which is **not** the order you write it), what `NULL` really means, and what the engine is doing underneath. Get this right and every later topic — joins, windows, indexes, isolation levels — is a small addition rather than a new mystery.

---

## 1. The Relational Model

Edgar F. Codd published *A Relational Model of Data for Large Shared Data Banks* in 1970. The model is mathematical, and the vocabulary matters because interviewers use it and because it explains why SQL behaves the way it does.

| Formal term | SQL term | In TaskFlow |
|---|---|---|
| **Relation** | Table | `app.Tasks` |
| **Tuple** | Row | One task |
| **Attribute** | Column | `app.Tasks.DueDate` |
| **Domain** | Data type + constraints | `DATE`, or `TINYINT` constrained by `FK_Tasks_Status` |
| **Degree** | Number of columns | `ref.Priorities` has degree 4 |
| **Cardinality** | Number of rows | `ref.Priorities` has cardinality 5 |
| **Relation variable (relvar)** | The named, mutable table | `app.Tasks` today vs `app.Tasks` tomorrow |

### The properties Codd insisted on

1. **No duplicate tuples.** A true relation is a *set*. SQL violates this: a table without a key can hold identical rows, and `SELECT` returns a *multiset* (bag) unless you add `DISTINCT`.
2. **No ordering of tuples.** There is no "first row" in a table. Without `ORDER BY`, the order you see is an accident of the execution plan and may change when an index is added.
3. **No ordering of attributes.** Columns are addressed by name. This is why `SELECT *` is fragile and `INSERT` without a column list is a production incident waiting for a schema change.
4. **Atomic values.** Each cell holds one value from its domain. A comma-separated `"7,12,19"` column is not relational — that is what `app.TaskLabels` exists to prevent.

> **Anti-pattern:** Relying on "natural order". `SELECT TOP (10) * FROM app.Tasks;` without `ORDER BY` is non-deterministic. SQL Server is free to return a different ten rows after an index rebuild, a statistics update, or a parallelism change.

---

## 2. Keys

A key is a *constraint*, not an index — although SQL Server enforces both `PRIMARY KEY` and `UNIQUE` with an index, which is why people conflate them.

| Key type | Definition | TaskFlow example |
|---|---|---|
| **Superkey** | Any attribute set that uniquely identifies a tuple | `{UserId, Email}` in `app.Users` |
| **Candidate key** | A *minimal* superkey (remove any column and uniqueness breaks) | `{UserId}` and `{Email}` |
| **Primary key** | The candidate key you nominated; implies `NOT NULL` | `PK_Users` on `UserId` |
| **Alternate key** | Every candidate key you did *not* nominate | `UQ_Users_Email` on `Email` |
| **Composite key** | A key spanning two or more columns | `PK_TeamMembers (TeamId, UserId)` |
| **Foreign key** | Values must exist in the referenced candidate key (or be `NULL`) | `FK_Tasks_Project` |
| **Surrogate key** | System-generated, meaningless outside the DB | `TaskId INT IDENTITY(1,1)` |
| **Natural key** | Carries business meaning | `ProjectCode = 'TF-CORE'` |

### Surrogate vs natural: the decision

| Factor | Surrogate (`ProjectId`) | Natural (`ProjectCode`) |
|---|---|---|
| Stability | Never changes | Business *will* ask to rename `TF-MOB` |
| Width | 4 bytes (`INT`) | 10 bytes (`VARCHAR(10)`) — multiplied across every FK and index |
| Readability in raw data | Poor | Excellent |
| Cascade cost on update | None | Rewrites every child row |
| Accidental exposure | Leaks row counts if used in URLs | Safe |

> **Rule of thumb:** Use a **narrow surrogate primary key** for every transactional table, and enforce the natural key as a `UNIQUE` constraint alongside it. That is exactly what `app.Projects` does: `ProjectId` is the PK, `UQ_Projects_Code` guarantees `ProjectCode` is still trustworthy.

Pure join tables are the exception: `app.TaskLabels` needs no surrogate because `(TaskId, LabelId)` *is* the row.

```sql
-- Composite key columns, in key order.
SELECT kc.name AS ConstraintName, kc.type_desc, c.name AS ColumnName, ic.key_ordinal
FROM sys.key_constraints AS kc
JOIN sys.index_columns   AS ic ON ic.object_id = kc.parent_object_id
                              AND ic.index_id  = kc.unique_index_id
JOIN sys.columns         AS c  ON c.object_id  = ic.object_id
                              AND c.column_id  = ic.column_id
WHERE kc.parent_object_id = OBJECT_ID(N'app.TeamMembers')
ORDER BY ic.key_ordinal;

-- Every foreign key, with its delete behaviour and whether it is trusted.
SELECT fk.name AS ForeignKeyName,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + N'.' + OBJECT_NAME(fk.parent_object_id) AS ChildTable,
       fk.delete_referential_action_desc AS OnDelete,
       fk.is_not_trusted                 AS IsNotTrusted
FROM sys.foreign_keys AS fk
ORDER BY ChildTable, ForeignKeyName;
```

Note `audit.TaskHistory` has **no** foreign key to `app.Tasks`. That is deliberate: audit rows must outlive the row they describe. Foreign keys are a design decision, not a reflex.

---

## 3. Relational Algebra Mapped to SQL

Relational algebra is the theory the optimizer actually manipulates. Every operator has a SQL surface.

| Operator | Symbol | SQL | TaskFlow example |
|---|---|---|---|
| Selection | σ | `WHERE` | `WHERE PriorityId = 1` |
| Projection | π | `SELECT` column list | `SELECT TaskId, Title` |
| Rename | ρ | `AS` | `app.Users AS mgr` |
| Union | ∪ | `UNION` / `UNION ALL` | Open tasks plus blocked tasks |
| Intersection | ∩ | `INTERSECT` | Users who are both leads and assignees |
| Difference | − | `EXCEPT` | Labels never applied to a task |
| Cartesian product | × | `CROSS JOIN` | Every status paired with every priority |
| Theta / equi join | ⋈θ | `INNER JOIN ... ON` | Tasks to projects |
| Natural join | ⋈ | *(no T-SQL equivalent)* | Must write the `ON` clause explicitly |
| Outer join | ⟕ ⟖ ⟗ | `LEFT` / `RIGHT` / `FULL JOIN` | Projects with zero tasks |
| Division | ÷ | Double `NOT EXISTS` | Users assigned to *every* security task |
| Aggregation | γ | `GROUP BY` | Hours per project |

```sql
-- Projection + selection: pi(TaskId, Title)(sigma(PriorityId = 1)(Tasks))
SELECT TaskId, Title FROM app.Tasks WHERE PriorityId = 1;

-- Cartesian product: 7 statuses x 5 priorities = 35 combinations.
SELECT s.StatusCode, p.PriorityCode
FROM ref.TaskStatuses AS s CROSS JOIN ref.Priorities AS p;

-- Difference: labels that were defined but never used.
SELECT LabelId FROM app.Labels
EXCEPT
SELECT LabelId FROM app.TaskLabels;

-- Division: users assigned to EVERY task in project TF-SEC.
SELECT u.Email
FROM app.Users AS u
WHERE NOT EXISTS (
    SELECT 1
    FROM app.Tasks    AS t
    JOIN app.Projects AS p ON p.ProjectId = t.ProjectId
    WHERE p.ProjectCode = 'TF-SEC'
      AND NOT EXISTS (SELECT 1 FROM app.TaskAssignments AS ta
                      WHERE ta.TaskId = t.TaskId AND ta.UserId = u.UserId)
);
```

T-SQL deliberately omits `NATURAL JOIN` (PostgreSQL, MySQL and Oracle have it). That omission is a feature: a natural join silently changes meaning when someone adds a column with a matching name.

---

## 4. SQL: History, Standards and Dialects

SQL began as **SEQUEL** (Structured English Query Language) at IBM San Jose in 1974, renamed for trademark reasons. It is now both an ANSI and ISO standard, revised roughly every three to five years.

| Standard | Year | Headline additions |
|---|---|---|
| SQL-86 / SQL-89 | 1986 / 1989 | First ANSI ratification; referential constraints |
| **SQL-92** | 1992 | Explicit `JOIN` syntax, `CAST`, `INFORMATION_SCHEMA`. The baseline every dialect implements. |
| SQL:1999 | 1999 | Recursive CTEs, triggers, user-defined types, `BOOLEAN`, OLAP amendment |
| **SQL:2003** | 2003 | Window functions, `MERGE`, `SEQUENCE`, `IDENTITY`, SQL/XML |
| SQL:2006 / SQL:2008 | 2006 / 2008 | XQuery integration; `TRUNCATE`, `INSTEAD OF` triggers, `FETCH FIRST` |
| SQL:2011 | 2011 | System-versioned temporal tables, `FETCH ... WITH TIES` |
| **SQL:2016** | 2016 | JSON functions, `MATCH_RECOGNIZE` (row pattern matching) |
| SQL:2019 / SQL:2023 | 2019 / 2023 | Multi-dimensional arrays; property graph queries (SQL/PGQ), native `JSON` type |

No engine implements the whole standard, and every engine adds proprietary extensions. Those extensions are the **dialect**.

| Dialect | Engine | Procedural language | Distinctive syntax |
|---|---|---|---|
| **T-SQL** | SQL Server, Azure SQL, Synapse | T-SQL itself | `TOP`, `[brackets]`, `ISNULL`, `GETDATE()`, `OUTPUT` clause, `MERGE` |
| **PL/pgSQL** | PostgreSQL | PL/pgSQL (plus PL/Python, PL/v8) | `LIMIT`/`OFFSET`, `::` cast, `RETURNING`, `COALESCE`, arrays, `DISTINCT ON` |
| **MySQL SQL** | MySQL, MariaDB | SQL/PSM-flavoured | `LIMIT`, backtick quoting, `IFNULL`, `AUTO_INCREMENT`, `ON DUPLICATE KEY UPDATE` |
| **PL/SQL** | Oracle | PL/SQL | `ROWNUM`/`FETCH FIRST`, `DUAL`, `NVL`, `CONNECT BY`, packages |

> **Portability:** Roughly 80% of everyday `SELECT` is portable if you stay inside SQL-92 plus window functions. The remaining 20% — pagination, string concatenation, date arithmetic, identity generation, upsert, error handling — is dialect-specific and is where migrations actually break.

| Task | T-SQL | PostgreSQL | MySQL | Oracle |
|---|---|---|---|---|
| Top N rows | `SELECT TOP (10)` | `LIMIT 10` | `LIMIT 10` | `FETCH FIRST 10 ROWS ONLY` |
| Null substitution | `ISNULL(a, b)` | `COALESCE(a, b)` | `IFNULL(a, b)` | `NVL(a, b)` |
| Current UTC time | `SYSUTCDATETIME()` | `NOW() AT TIME ZONE 'UTC'` | `UTC_TIMESTAMP()` | `SYS_EXTRACT_UTC(SYSTIMESTAMP)` |
| String concat | `+` or `CONCAT()` | `\|\|` | `CONCAT()` | `\|\|` |
| Identifier quoting | `[Name]` or `"Name"` | `"Name"` | `` `Name` `` | `"NAME"` |
| Dummy table | *(not needed)* | *(not needed)* | *(not needed)* | `DUAL` |

`COALESCE` is standard and works everywhere. Prefer it over `ISNULL` unless you specifically need `ISNULL`'s different data-type-precedence behaviour.

---

## 5. The Five Sublanguages

SQL is usually split into five functional groups. Interviewers ask for these by acronym.

| Sublanguage | Name | Statements | Transactional in SQL Server? |
|---|---|---|---|
| **DDL** | Data Definition Language | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` | Yes — can be rolled back |
| **DML** | Data Manipulation Language | `INSERT`, `UPDATE`, `DELETE`, `MERGE` | Yes |
| **DQL** | Data Query Language | `SELECT` | Read-only (still takes locks) |
| **DCL** | Data Control Language | `GRANT`, `REVOKE`, `DENY` | Yes |
| **TCL** | Transaction Control Language | `BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`, `SAVE TRANSACTION` | — |

> **Portability:** In Oracle and MySQL, DDL performs an **implicit commit** — you cannot roll back a `CREATE TABLE`. In SQL Server and PostgreSQL, DDL is fully transactional, which is why you can wrap a migration in `BEGIN TRAN ... ROLLBACK` and rehearse it safely.

```sql
-- DDL
CREATE TABLE app.TaskWatchers
(
    TaskId INT NOT NULL,
    UserId INT NOT NULL,
    CONSTRAINT PK_TaskWatchers PRIMARY KEY (TaskId, UserId)
);
DROP TABLE IF EXISTS app.TaskWatchers;

-- DML / DQL
INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'blocked', '#C5DEF5');
UPDATE app.Labels SET ColorHex = '#D4C5F9' WHERE LabelName = N'blocked';
DELETE FROM app.Labels WHERE LabelName = N'blocked';
SELECT TaskId, Title, DueDate FROM app.Tasks WHERE StatusId = 3;

-- DCL
CREATE ROLE TaskFlowReporting;
GRANT SELECT ON SCHEMA::app TO TaskFlowReporting;
DENY  SELECT ON app.Users (HourlyRate) TO TaskFlowReporting;   -- column-level DENY wins

-- TCL: rehearsal only -- ROLLBACK persists nothing.
BEGIN TRANSACTION;
    UPDATE app.Tasks
       SET StatusId = 6, CompletedAtUtc = SYSUTCDATETIME(), ModifiedAtUtc = SYSUTCDATETIME()
     WHERE TaskId = 5;
    INSERT INTO audit.TaskHistory (TaskId, ColumnName, OldValue, NewValue)
    VALUES (5, N'StatusId', N'3', N'6');
ROLLBACK TRANSACTION;
```

---

## 6. Declarative vs Imperative Thinking

C# is imperative: you specify *how*. SQL is declarative: you specify *what*, and the optimizer chooses how.

| | Imperative (C#) | Declarative (SQL) |
|---|---|---|
| You control | Loop order, data structures, algorithm | Result shape only |
| Engine controls | Nothing | Join order, join algorithm, index choice, parallelism |
| Performance lever | Rewrite the algorithm | Rewrite the query, add indexes, fix statistics |
| Debug tool | Breakpoints and the call stack | The execution plan |

```csharp
// Imperative: you wrote the nested loop. The algorithm is yours to fix.
foreach (var t in tasks)
    foreach (var p in projects)
        if (t.ProjectId == p.ProjectId && t.StatusId == 3)
            result.Add(p.ProjectName + ": " + t.Title);
```

```sql
-- Declarative: same intent. The optimizer may pick a nested loop, a hash join
-- or a merge join -- and may switch between them as the data grows.
SELECT p.ProjectName, t.Title
FROM app.Tasks    AS t
JOIN app.Projects AS p ON p.ProjectId = t.ProjectId
WHERE t.StatusId = 3;
```

> **Anti-pattern:** Writing a `CURSOR` or a `WHILE` loop because the set-based version "feels hard". Row-by-row processing (RBAR — row by agonising row) is typically one to three orders of magnitude slower and defeats every optimization the engine offers.

---

## 7. Logical Query Processing Order

This is the single most valuable idea in the topic. **The order you write a query is not the order it is evaluated.**

```
FROM -> ON -> JOIN (outer rows re-added) -> WHERE -> GROUP BY -> HAVING
     -> SELECT -> DISTINCT -> ORDER BY -> TOP / OFFSET-FETCH
```

| Written order | Evaluated | What happens |
|---|---|---|
| 1. `SELECT` | 6 | Expressions evaluated, aliases created |
| 2. `FROM` | 1 | First table materialised |
| 3. `JOIN ... ON` | 2 / 3 | Cartesian product, filtered by `ON`; outer rows re-added |
| 4. `WHERE` | 4 | Rows filtered |
| 5. `GROUP BY` | 5a | Collapsed into groups; aggregates computed |
| 6. `HAVING` | 5b | Groups filtered |
| 7. `ORDER BY` | 8 | Result sorted — the first step that can see a `SELECT` alias |
| 8. `TOP` / `OFFSET-FETCH` | 9 | Sorted result sliced |

### Why this explains alias-scope errors

```sql
-- FAILS. Msg 207: Invalid column name 'TaskCount'.
-- WHERE runs at step 4; the SELECT alias is not created until step 6.
SELECT p.ProjectName, COUNT(*) AS TaskCount
FROM app.Projects AS p
JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
WHERE TaskCount > 3
GROUP BY p.ProjectName;

-- WORKS. Group-level filters belong in HAVING (step 5b), and ORDER BY (step 8)
-- runs AFTER SELECT, so it CAN see the alias.
SELECT p.ProjectName, COUNT(*) AS TaskCount
FROM app.Projects AS p
JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
GROUP BY p.ProjectName
HAVING COUNT(*) > 3
ORDER BY TaskCount DESC;
```

### Why `ON` and `WHERE` are not interchangeable on outer joins

```sql
-- ON: the predicate runs at step 2, BEFORE outer rows are re-added.
-- All 8 projects survive; non-Done tasks appear as NULL.
SELECT p.ProjectCode, t.Title
FROM app.Projects AS p
LEFT JOIN app.Tasks AS t
       ON t.ProjectId = p.ProjectId
      AND t.StatusId  = 6;

-- WHERE: the predicate runs at step 4, AFTER the NULL rows were added.
-- NULL = 6 is UNKNOWN, so those rows are discarded and the LEFT JOIN
-- silently degrades to an INNER JOIN.
SELECT p.ProjectCode, t.Title
FROM app.Projects AS p
LEFT JOIN app.Tasks AS t ON t.ProjectId = p.ProjectId
WHERE t.StatusId = 6;
```

### Why `TOP` without `ORDER BY` is meaningless

`TOP` runs at step 9, after `ORDER BY`. With no `ORDER BY` there is no defined ordering to take the top of, so the engine returns whichever rows it happened to produce first. Deterministic pagination needs a unique `ORDER BY`, or a tiebreaker:

```sql
SELECT TaskId, Title, DueDate
FROM app.Tasks
ORDER BY DueDate DESC, TaskId DESC     -- TaskId breaks DueDate ties
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
```

> **Rule of thumb:** *Logical* processing order is a contract about **meaning**. *Physical* execution order is whatever the optimizer chooses, and it will happily evaluate `WHERE` before the join if that produces the same answer faster. Never confuse the two.

---

## 8. NULL and Three-Valued Logic

`NULL` is not a value. It is a marker meaning *"a value exists in the real world but is unknown here"* or *"no value is applicable"*. Any comparison involving `NULL` yields **UNKNOWN**, not true and not false.

| `p` | `q` | `p AND q` | `p OR q` | `NOT p` |
|---|---|---|---|---|
| TRUE | UNKNOWN | UNKNOWN | TRUE | FALSE |
| FALSE | UNKNOWN | FALSE | UNKNOWN | TRUE |
| UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |

`WHERE` and `ON` keep only rows evaluating to **TRUE**. `CHECK` constraints are the mirror image: they reject only **FALSE**, so `CHECK (HourlyRate >= 0)` accepts `NULL`.

```sql
-- ref.Priorities holds 5 rows; PriorityId 5 ('NONE') has SlaHours = NULL.
SELECT COUNT(*) AS WithEquals FROM ref.Priorities WHERE SlaHours = NULL;   -- 0
SELECT COUNT(*) AS WithIsNull FROM ref.Priorities WHERE SlaHours IS NULL;  -- 1

-- COUNT(*) counts rows; COUNT(<column>) skips NULLs.
SELECT COUNT(*) AS Rows, COUNT(SlaHours) AS NonNullSlas FROM ref.Priorities;  -- 5, 4

-- "Everything except the 24-hour SLA" quietly drops the NULL row too.
SELECT PriorityCode FROM ref.Priorities WHERE SlaHours <> 24;                      -- 3 rows
SELECT PriorityCode FROM ref.Priorities WHERE SlaHours <> 24 OR SlaHours IS NULL;  -- 4 rows
```

### The classic `NOT IN` trap

```sql
-- Intent: "users who manage nobody". Returns ZERO rows, because ManagerId
-- contains NULL (users 1 and 20), and UserId <> NULL is UNKNOWN for every row.
SELECT u.Email
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);

-- Correct: NOT EXISTS is NULL-safe because it tests row existence, not equality.
SELECT u.Email
FROM app.Users AS u
WHERE NOT EXISTS (
    SELECT 1 FROM app.Users AS m WHERE m.ManagerId = u.UserId
);
```

### Where `NULL`s *are* treated as equal

Grouping, `DISTINCT`, `UNION`, `INTERSECT`, `EXCEPT`, `ORDER BY` and `UNIQUE` constraints all treat `NULL`s as duplicates of each other — the opposite of `=`. So `SELECT SlaHours, COUNT(*) FROM ref.Priorities GROUP BY SlaHours;` returns one row for the `NULL` group, and a SQL Server `UNIQUE` constraint permits only **one** `NULL`. The standard says otherwise, and PostgreSQL and Oracle allow many; use a filtered unique index (`WHERE col IS NOT NULL`) when you need standard behaviour.

> **Rule of thumb:** Declare `NOT NULL` unless you can articulate what `NULL` *means* for that column. In TaskFlow, `Projects.EndDate IS NULL` means "still running" and `Priorities.SlaHours IS NULL` means "no SLA applies" — both are real, documented meanings.

---

## 9. Engine Architecture

You cannot tune what you cannot picture.

```
Client (ADO.NET / Dapper / EF Core)
   |  TDS protocol over TCP 1433
   v
Relational Engine
   Parser  ->  Algebrizer/Binder  ->  Query Optimizer  ->  Plan Cache
                                                 |
                                                 v
                                        Query Executor
   |
   v
Storage Engine
   Buffer Pool (in-memory 8 KB pages)  <-> Data files (.mdf/.ndf)
   Log Manager (write-ahead log)       <-> Log file (.ldf)
   Lock Manager, Transaction Manager, Checkpoint, Lazy Writer
```

| Structure | Size / role | Why you care |
|---|---|---|
| **Page** | 8 KB — the smallest I/O unit. ~8,060 bytes usable for row data. | A row can never span pages (except LOB and row-overflow). Wide rows waste space. |
| **Extent** | 8 contiguous pages = 64 KB | The allocation unit; read-ahead works in extents |
| **Buffer pool** | In-memory cache of pages | Reads hit RAM, not disk. `SET STATISTICS IO ON` shows logical vs physical reads. |
| **Transaction log** | Write-ahead log (WAL) | A commit is durable when the *log record* is flushed, not the data page |
| **Query optimizer** | Cost-based, uses statistics + cardinality estimation | Bad statistics produce bad plans; this is most "sudden slowness" |
| **Plan cache** | Reusable compiled plans keyed by query text/handle | Parameterisation enables reuse; string-concatenated SQL destroys it |
| **Checkpoint / lazy writer** | Flush dirty pages to disk | Explains why a commit is fast but disk I/O happens later |

```sql
-- Rows, pages and megabytes for every TaskFlow table.
SELECT OBJECT_SCHEMA_NAME(p.object_id) + N'.' + OBJECT_NAME(p.object_id) AS TableName,
       SUM(p.rows)                      AS RowCounts,
       SUM(au.total_pages)              AS TotalPages,
       SUM(au.total_pages) * 8 / 1024.0 AS TotalMB
FROM sys.partitions       AS p
JOIN sys.allocation_units AS au ON au.container_id = p.partition_id
WHERE p.index_id IN (0, 1)
  AND OBJECT_SCHEMA_NAME(p.object_id) IN (N'app', N'ref', N'audit')
GROUP BY p.object_id
ORDER BY TotalPages DESC;

-- Recovery model, files, and what the plan cache is holding right now.
SELECT name, recovery_model_desc, state_desc, collation_name
FROM sys.databases WHERE name = N'TaskFlowDb';

SELECT TOP (5) cp.objtype, cp.usecounts, cp.size_in_bytes, st.text
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
ORDER BY cp.usecounts DESC;
```

---

## 10. System Databases

Every SQL Server instance ships with four visible system databases plus a hidden one.

| Database | Contains | If you lose it |
|---|---|---|
| **master** | Logins, linked servers, endpoints, the list of all databases | The instance will not start. Back it up. |
| **model** | The template every new database is cloned from | New databases lose their defaults; changing `model` changes every future DB |
| **msdb** | SQL Agent jobs, schedules, backup history, Database Mail, SSIS packages | Jobs and backup history are gone |
| **tempdb** | `#temp` tables, table variables, sorts, hashes, version store (RCSI/snapshot) | Recreated from `model` on every restart — never store anything you need |
| **Resource** (hidden) | All system objects (`sys.*`), read-only | Replaced by patching, not by you |

```sql
SELECT database_id, name, state_desc, recovery_model_desc, is_read_only
FROM sys.databases
ORDER BY database_id;   -- 1=master, 2=tempdb, 3=model, 4=msdb
```

> **Anti-pattern:** Creating application tables in `master`, or leaving your session defaulted to `master` and running DDL there by accident. Always start a script with `USE TaskFlowDb; GO` — or better, connect with the database in the connection string.
---

## 11. Editions and Tooling

| Edition | Cost | Limits | Use for |
|---|---|---|---|
| **Developer** | Free | None (Enterprise features) — **non-production only** | Local learning. Use this. |
| **Express** | Free | 10 GB per DB, 1 GB RAM buffer pool, 4 cores, no SQL Agent | Tiny apps, embedded |
| **Standard** | Paid | 128 GB RAM, 24 cores | Most production workloads |
| **Enterprise** | Paid | Unlimited; online index rebuilds, partitioning at scale, resource governor | Large production |
| **Azure SQL Database** | PaaS | No `USE`, no cross-database queries, no SQL Agent, no filesystem | Cloud-native apps (TaskFlow's target) |
| **Azure SQL Managed Instance** | PaaS | Near-full instance surface, including SQL Agent and cross-DB queries | Lift-and-shift |

| Tool | Platform | Best at |
|---|---|---|
| **SSMS** | Windows only | Full admin surface: Agent, profiler, maintenance plans, deep plan analysis |
| **Azure Data Studio** | Cross-platform | Notebooks, source-controlled queries, lightweight editing |
| **VS Code + `ms-mssql.mssql`** | Cross-platform | Staying in your editor; IntelliSense over the live schema |
| **`sqlcmd`** | Cross-platform | Scripting, CI/CD, running `.sql` files headlessly |
| **`sqlpackage` / DacFx** | Cross-platform | Deploying `.dacpac` schema snapshots |

### Running SQL Server 2022 in Docker

The fastest path to a disposable local instance, and the one this phase assumes.

```bash
# The named volume keeps your data across container restarts.
docker run \
  -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Str0ng!Passw0rd" -e "MSSQL_PID=Developer" \
  -p 1433:1433 --name taskflow-sql --hostname taskflow-sql \
  -v taskflow-sqldata:/var/opt/mssql \
  -d mcr.microsoft.com/mssql/server:2022-latest

docker ps --filter name=taskflow-sql     # STATUS should say "Up"
docker logs taskflow-sql                 # if it exited, the password policy is the usual culprit

# Smoke test. Note -C: the 2022 image ships mssql-tools18, which requires TLS
# and rejects the container's self-signed certificate without it.
docker exec -it taskflow-sql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "Str0ng!Passw0rd" -C -Q "SELECT @@VERSION;"
```

The SA password needs at least 8 characters and three of: uppercase, lowercase, digits, symbols. On Apple Silicon add `--platform linux/amd64`.

### Creating the shared TaskFlow database

Every example in Phase 11 runs against `TaskFlowDb`, built by [00-create-taskflow-db.sql](./PracticeProblemsSolutions/00-create-taskflow-db.sql). Run it once; it is idempotent.

```bash
sqlcmd -S localhost -U sa -P "Str0ng!Passw0rd" -C -i 00-create-taskflow-db.sql

# Or copy it into the container and run it there:
docker cp 00-create-taskflow-db.sql taskflow-sql:/tmp/
docker exec -it taskflow-sql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "Str0ng!Passw0rd" -C -i /tmp/00-create-taskflow-db.sql
```

```sql
-- Verify. Expect 20 users, 8 projects, 35 tasks.
USE TaskFlowDb;
GO
SELECT (SELECT COUNT(*) FROM app.Users)    AS Users,
       (SELECT COUNT(*) FROM app.Projects) AS Projects,
       (SELECT COUNT(*) FROM app.Tasks)    AS Tasks;
```

The .NET connection string (Topic 21 uses this) is `Server=localhost,1433;Database=TaskFlowDb;User Id=sa;Password=Str0ng!Passw0rd;Encrypt=True;TrustServerCertificate=True`.

> **Anti-pattern:** `TrustServerCertificate=True` in production. It disables certificate validation and re-opens the machine-in-the-middle hole that TLS closes. It is acceptable *only* against a local dev container.

---

## 12. Batches, `GO`, and Comments

A **batch** is the unit of text sent to the server for parsing and compilation. `GO` is **not** T-SQL — it is a separator recognised by sqlcmd, SSMS, Azure Data Studio and the VS Code extension, which use it to split your file into batches.

```sql
USE TaskFlowDb;
GO                                    -- batch 1 ends here

DECLARE @Cutoff DATE = '2025-09-01';
SELECT COUNT(*) FROM app.Tasks WHERE DueDate < @Cutoff;
GO                                    -- batch 2: @Cutoff dies here
-- SELECT @Cutoff;                    -- Msg 137: Must declare the scalar variable "@Cutoff".

-- GO takes an optional repeat count -- useful for generating test load.
INSERT INTO audit.TaskHistory (TaskId, ColumnName, OldValue, NewValue)
VALUES (1, N'SmokeTest', NULL, N'x');
GO 3                                  -- runs the batch 3 times

DELETE FROM audit.TaskHistory WHERE ColumnName = N'SmokeTest';
GO
```

Rules that trip people up:

- `CREATE PROCEDURE`, `CREATE VIEW`, `CREATE FUNCTION`, `CREATE TRIGGER` and `CREATE SCHEMA` must be the **first statement in their batch**. That is why `00-create-taskflow-db.sql` wraps `CREATE SCHEMA` in `EXEC (N'CREATE SCHEMA app')`.
- Variables (`@x`) and `SET` options are scoped to the batch; temporary tables (`#t`) are scoped to the **session** and survive `GO`.
- A compile error kills the whole batch; a runtime error may kill only the statement.

Comments are `--` to end of line and `/* ... */` in blocks, and blocks **nest** in T-SQL unlike in some dialects.

---

## 13. Identifiers, Delimited Identifiers, Reserved Words

A **regular identifier** must start with a letter, `_`, `@` or `#`, and may then contain letters, digits, `_`, `@`, `#`, `$`. It cannot be a reserved word, and it cannot contain spaces.

| Prefix | Meaning |
|---|---|
| `@name` / `@@name` | Local variable or parameter / system function (`@@VERSION`, `@@ROWCOUNT`) |
| `#name` / `##name` | Local temporary table (session-scoped) / global temporary table (instance-scoped) |

Anything that breaks those rules must be a **delimited identifier**: `[Order Date]` (T-SQL) or `"Order Date"` (ANSI, requires `SET QUOTED_IDENTIFIER ON`).

```sql
-- 'Order' and 'User' are reserved words. Delimiters make them legal -- but do
-- not make them a good idea.
CREATE TABLE app.[Order] ([User] NVARCHAR(50), [Group] INT);
DROP TABLE app.[Order];

-- QUOTED_IDENTIFIER changes what double quotes MEAN.
SET QUOTED_IDENTIFIER ON;
SELECT "Title" FROM app.Tasks WHERE TaskId = 1;              -- a column reference
SET QUOTED_IDENTIFIER OFF;
SELECT "Title" AS Literal FROM app.Tasks WHERE TaskId = 1;   -- the string 'Title'
SET QUOTED_IDENTIFIER ON;
```

It must be `ON` for indexed views, indexes on computed columns, filtered indexes and XML methods — which is why it is the default everywhere except a few legacy drivers.

### Object naming: the four-part name

```
[server].[database].[schema].[object]
        TaskFlowDb  .   app  .  Tasks
```

Only the object is mandatory, but **always write at least two parts**.

> **Rule of thumb:** Schema-qualify every object reference (`app.Tasks`, not `Tasks`). Unqualified names force a name-resolution step, produce one plan-cache entry *per default schema*, and silently resolve to a different table if two schemas both define `Tasks`.

`SYSNAME` — used by `audit.TaskHistory.ChangedBy` and `ColumnName` — is a built-in alias for `NVARCHAR(128) NOT NULL`, the exact size of a SQL Server identifier.

---

## 14. Collation and Case Sensitivity

A **collation** defines three things: the character encoding for non-Unicode types, the sort order, and the comparison rules (case, accent, kana, width sensitivity).

Read `SQL_Latin1_General_CP1_CI_AS` as: legacy SQL sort rules, Latin1 code page 1252 for `CHAR`/`VARCHAR`, **C**ase **I**nsensitive, **A**ccent **S**ensitive.

| Suffix | Meaning |
|---|---|
| `_CI` / `_CS` | Case insensitive / sensitive |
| `_AI` / `_AS` | Accent insensitive / sensitive |
| `_BIN` / `_BIN2` | Binary comparison (`_BIN2` is the correct modern one) |
| `_SC` | Supplementary characters (full UTF-16, needed for emoji and rare CJK) |
| `_UTF8` | Stores `CHAR`/`VARCHAR` as UTF-8 (SQL Server 2019+) |

Collation applies at four levels: server, database, column, and expression. The most specific wins.

```sql
SELECT SERVERPROPERTY('Collation')                    AS ServerCollation,
       DATABASEPROPERTYEX(N'TaskFlowDb', 'Collation') AS DatabaseCollation;

-- Under the default case-insensitive collation this MATCHES 'TF-CORE'.
SELECT ProjectId, ProjectCode FROM app.Projects WHERE ProjectCode = 'tf-core';

-- Force case sensitivity for one comparison: 0 rows.
SELECT ProjectId, ProjectCode
FROM app.Projects
WHERE ProjectCode COLLATE Latin1_General_100_CS_AS = 'tf-core';
```

> **Anti-pattern:** Applying `COLLATE` to a column inside `WHERE` as a routine habit. It makes the predicate non-SARGable — the engine can no longer seek the index and must scan and convert every row. Fix the column's collation instead, or store a normalised copy.

Case sensitivity also affects **identifiers** when the *database* collation is case sensitive: under `Latin1_General_CS_AS`, `SELECT * FROM app.tasks` fails while `app.Tasks` succeeds.

> **Portability:** PostgreSQL is case sensitive for data by default and *folds unquoted identifiers to lowercase*. MySQL's table-name case sensitivity depends on the host filesystem. Never rely on the server's default; be explicit.

---

## 15. OLTP vs OLAP

The same data serves two workloads with opposite characteristics. Trying to serve both from one schema is the most common architectural mistake in a growing product.

| Dimension | OLTP (transactional) | OLAP (analytical) |
|---|---|---|
| Purpose | Run the business | Understand the business |
| TaskFlow example | "Move task 5 to In Review" | "Average cycle time per team per quarter" |
| Typical query | Reads/writes a handful of rows | Scans millions, aggregates |
| Write pattern | Constant, small, concurrent | Bulk load on a schedule |
| Schema | Highly normalised (3NF) | Denormalised: star/snowflake schema |
| Indexing | Many narrow B-tree (rowstore) indexes | Columnstore, few or no rowstore indexes |
| Key metric | Transactions/sec, p99 latency | Rows scanned/sec, query throughput |
| Concurrency | Hundreds to thousands of users | Tens of analysts |
| Azure product | Azure SQL Database | Azure Synapse / Microsoft Fabric |

TaskFlow starts OLTP-only. Project `TF-RPT` ("Reporting & Analytics") exists in the sample data precisely because at some point the reporting queries start hurting the transactional workload. Topic 12 covers the star schema; Topic 20 covers detecting the moment you need one.

---

## 16. SQL vs NoSQL

"NoSQL" is not one thing. It is four families with different trade-offs.

| Family | Examples | Data model | Wins at | Loses at |
|---|---|---|---|---|
| **Relational** | SQL Server, PostgreSQL | Tables + constraints | Multi-entity ACID, ad-hoc joins, integrity | Horizontal write scale-out, schema churn |
| **Document** | MongoDB, Cosmos DB | JSON documents | Denormalised aggregates, flexible shape | Cross-document joins, multi-doc transactions |
| **Key-value** | Redis, DynamoDB | Opaque value by key | Sub-millisecond reads, caching, sessions | Any query that is not by key |
| **Column-family** | Cassandra, HBase | Wide rows by partition key | Massive write throughput, time series | Ad-hoc queries, joins |
| **Graph** | Neo4j, Cosmos DB (Gremlin) | Nodes + edges | Deep traversals, recommendations | Aggregate reporting |

### Decision table

| Question | Points to relational | Points to NoSQL |
|---|---|---|
| Does a single business operation touch multiple entities atomically? | Yes | No |
| Do you need ad-hoc queries you have not designed for yet? | Yes | No |
| Is the schema stable and shared across many consumers? | Yes | No (per-tenant or per-document shapes) |
| Are relationships many-to-many and queried from both directions? | Yes | No |
| Do you need to exceed one machine's *write* throughput? | No | Yes |
| Is the access pattern always "fetch one aggregate by id"? | No | Yes |
| Do auditors/regulators require referential integrity guarantees? | Yes | No |
| Is sub-millisecond p99 read latency the hard requirement? | No | Yes (cache/KV) |

TaskFlow scores relational on almost every line: a task belongs to a project, has many assignees, many labels, many time entries, and every one of those relationships is queried from both directions. `MetadataJson` on `app.Tasks` is the pragmatic middle ground — a schemaless escape hatch inside a relational table, covered in Topic 18.

> **Rule of thumb:** Start relational. Add a specialised store when you have a *measured* access pattern the relational engine handles badly — not because a conference talk said joins do not scale.

---

## Mental Model

> A relational database is a set of **typed, constrained sets** and a **cost-based engine** that rewrites your declared intent into a physical plan.
>
> When a query surprises you, walk these five questions in order:
>
> 1. **What is the shape?** Which relations, what degree and cardinality, which keys join them?
> 2. **What is the logical order?** `FROM -> ON -> JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> TOP/OFFSET`. Almost every "invalid column name" and "my LEFT JOIN became an INNER JOIN" is answered here.
> 3. **Where can `NULL` be?** Every nullable column on either side of a comparison, an aggregate, a `NOT IN`, or an outer join is a three-valued-logic hazard.
> 4. **What did I declare vs what did the engine choose?** You wrote *what*; the plan shows *how*. They diverge, and only the plan tells the truth.
> 5. **What does the storage engine have to move?** Pages, not rows. Fewer, narrower pages in the buffer pool beats every clever rewrite.

Move to [Practice Problems](./Practice-Problems.md).
