# Topic 02: Data Types & DDL — Interview Questions

---

## Q1. `CHAR` vs `VARCHAR` — when would you actually choose `CHAR`?
**Answer:**
`CHAR(n)` is fixed width: it always occupies exactly `n` bytes and pads with trailing spaces. `VARCHAR(n)` stores the actual length plus a 2-byte offset.

Choose `CHAR` only when **every** value is the same length and the column is `NOT NULL`. Below about 3–4 characters, `CHAR` also wins outright because `VARCHAR`'s 2-byte overhead exceeds the padding you were trying to avoid.

```sql
-- Both TaskFlow CHAR columns are genuinely fixed-width.
-- app.Users.CountryCode CHAR(2)  -- ISO 3166-1 alpha-2
-- app.Labels.ColorHex   CHAR(7)  -- '#RRGGBB'

SELECT u.CountryCode,
       LEN(u.CountryCode)        AS Chars,
       DATALENGTH(u.CountryCode) AS Bytes
FROM app.Users AS u
WHERE u.UserId = 1;
```

Watch the gotcha: `LEN()` ignores trailing spaces, `DATALENGTH()` does not. A `CHAR(20)` holding `'bug'` reports `LEN = 3` and `DATALENGTH = 20`.

---

## Q2. `VARCHAR` vs `NVARCHAR`, and what changed in SQL Server 2019?
**Answer:**
`VARCHAR` stores one byte per character using the collation's code page — so it can only represent that code page's characters. `NVARCHAR` stores UTF-16, two bytes per character (four for supplementary characters), and can represent all of Unicode.

SQL Server 2019 added **UTF-8 collations** (`_UTF8`). Under one, `CHAR`/`VARCHAR` store UTF-8: 1 byte for ASCII, 2–4 for everything else. For Latin-dominant text that roughly halves storage versus `NVARCHAR` while remaining fully Unicode-capable.

| Value | `NVARCHAR` | `VARCHAR` under `_UTF8` |
|---|---|---|
| `'ada.lovelace@taskflow.io'` (24 ASCII chars) | 50 bytes | 26 bytes |
| A 24-character CJK string | 50 bytes | 74 bytes |

The `_SC` suffix matters separately: it makes `NVARCHAR` handle surrogate pairs correctly, so `LEN()` and `SUBSTRING()` do not split an emoji in half.

> Do not migrate an existing `NVARCHAR` column to UTF-8 `VARCHAR` casually. It is a full table rewrite, and it re-opens the implicit-conversion problem in Q8 for every .NET parameter.

---

## Q3. What is wrong with using `NVARCHAR(MAX)` everywhere?
**Answer:**
Four concrete costs:

1. **It cannot be an index key.** The limits are 900 bytes for a clustered index key and 1,700 for nonclustered, and `MAX` types are excluded regardless.
2. **LOB handling.** Values over ~8,000 bytes go off-row, so reading one becomes a pointer chase to a separate allocation unit.
3. **Memory grants.** The optimizer estimates the average row size from the declared maximum. Over-declaring inflates the grant, or causes the sort/hash to spill to `tempdb`.
4. **It documents nothing.** `NVARCHAR(200)` tells the next developer what the domain is; `NVARCHAR(MAX)` tells them nobody thought about it.

```sql
-- Msg 1919: Column 'Body' in table 'app.Comments' is of a type that is invalid
-- for use as a key column in an index.
-- CREATE INDEX IX_Comments_Body ON app.Comments (Body);
```

TaskFlow uses `NVARCHAR(MAX)` in exactly three places — `app.Tasks.Description`, `app.Comments.Body` and `app.Tasks.MetadataJson` — all genuinely unbounded and never index keys. `app.Tasks.Title` is `NVARCHAR(200)` because it is displayed, sorted and searched.

---

## Q4. Which type do you use for money, and why not `MONEY` or `FLOAT`?
**Answer:**
`DECIMAL(p,s)`. Always.

**`FLOAT`** is IEEE 754 binary floating point. It cannot represent 0.1 exactly, so equality comparisons and accumulated sums drift:

```sql
DECLARE @float FLOAT        = 0.1;
DECLARE @dec   DECIMAL(5,2) = 0.1;

SELECT IIF(@float * 3 = 0.3, 'equal', 'NOT equal') AS FloatCompare,     -- NOT equal
       IIF(@dec   * 3 = 0.3, 'equal', 'NOT equal') AS DecimalCompare;   -- equal
```

**`MONEY`** truncates every *intermediate* result to 4 decimal places, so error compounds through an expression:

```sql
DECLARE @rate MONEY         = 0.0001;
DECLARE @dec  DECIMAL(19,4) = 0.0001;

SELECT @rate / 3 AS MoneyDiv,     -- 0.0000  -- all precision gone
       @dec  / 3 AS DecimalDiv;   -- 0.000033333...
```

`MONEY` also stores no currency code, is not in the SQL standard, and maps awkwardly through ORMs. `DECIMAL(19,4)` is a drop-in replacement with correct arithmetic.

TaskFlow uses `DECIMAL(9,2)` for `HourlyRate`, `DECIMAL(12,2)` for `Budget`, `DECIMAL(6,2)` for `EstimatedHours` and `DECIMAL(5,2)` for `TimeEntries.Hours`.

---

## Q5. What do `p` and `s` mean in `DECIMAL(p,s)`, and how much does it cost?
**Answer:**
`p` is the total number of significant digits (1–38); `s` is how many of them fall after the decimal point. `DECIMAL(9,2)` holds up to `9999999.99`.

Storage depends on **precision only**:

| Precision `p` | Bytes |
|---|---|
| 1–9 | 5 |
| 10–19 | 9 |
| 20–28 | 13 |
| 29–38 | 17 |

`DECIMAL` and `NUMERIC` are synonyms in SQL Server. Pick one and stay consistent.

The follow-up they are looking for: arithmetic **changes** the precision and scale. Multiplication gives `p1 + p2 + 1` precision and `s1 + s2` scale, capped at 38 — and when the cap bites, SQL Server sacrifices **scale**, silently losing decimal places in a long expression chain.

---

## Q6. Why is `DATETIME2` preferred over `DATETIME`?
**Answer:**
`DATETIME2(3)` gives true millisecond precision in **7 bytes**. `DATETIME` gives 3.33 ms precision in **8 bytes** and rounds every value to the nearest .000, .003 or .007 second. It is strictly worse on both axes.

```sql
SELECT CAST('2025-09-08T23:59:59.999' AS DATETIME)     AS LegacyRounded;
-- 2025-09-09 00:00:00.000   <-- the DATE changed

SELECT CAST('2025-09-08T23:59:59.999' AS DATETIME2(3)) AS Exact;
-- 2025-09-08 23:59:59.999
```

That rounding is why so much legacy code contains `BETWEEN @start AND '...23:59:59.997'`. With `DATETIME2` you write a half-open range instead, which is correct **and** SARGable:

```sql
SELECT t.TaskId, t.Title, t.CompletedAtUtc
FROM app.Tasks AS t
WHERE t.CompletedAtUtc >= '2024-06-01'
  AND t.CompletedAtUtc <  '2024-07-01';
```

`DATETIME2` also has a wider range (from year 0001 rather than 1753) and configurable precision from 0 to 7. `SMALLDATETIME` is worse again — one-minute accuracy and a hard stop in 2079.

---

## Q7. `DATETIME2` or `DATETIMEOFFSET`? How do you handle time zones?
**Answer:**
Default to **UTC in `DATETIME2(3)`**, name the column `...AtUtc`, and convert at the presentation edge. That is exactly what TaskFlow does: `CreatedAtUtc`, `CompletedAtUtc`, `PostedAtUtc`, `ChangedAtUtc`.

Use `DATETIMEOFFSET` only when the **originating offset is itself business data** — a legal timestamp, a meeting invite, an audit record that must prove local wall-clock time.

```sql
SELECT SYSUTCDATETIME()    AS UtcNow,               -- DATETIME2(7)
       SYSDATETIMEOFFSET() AS NowWithOffset;        -- DATETIMEOFFSET(7)

-- Convert a stored UTC instant to a named zone (SQL Server 2016+).
SELECT t.TaskId,
       t.CompletedAtUtc,
       t.CompletedAtUtc AT TIME ZONE 'UTC'
                        AT TIME ZONE 'Eastern Standard Time' AS CompletedLocal
FROM app.Tasks AS t
WHERE t.CompletedAtUtc IS NOT NULL;
```

The precision that separates a strong answer: a **UTC offset is not a time zone**. `-05:00` does not know whether the region observes DST. If you need to reason about future local times, store the IANA/Windows zone **name** in its own column alongside the UTC instant.

---

## Q8. What is data type precedence, and how does it break a query?
**Answer:**
When two operands differ in type, SQL Server converts the **lower-precedence** operand to the higher one. The order, abbreviated, is:

```
sql_variant > xml > datetimeoffset > datetime2 > datetime > date > time
           > float > real > decimal > money
           > bigint > int > smallint > tinyint > bit
           > uniqueidentifier
           > nvarchar > nchar > varchar > char > varbinary > binary
```

The line that causes real incidents is `nvarchar > varchar`. Compare a `VARCHAR` column to an `NVARCHAR` parameter and the engine converts **the column**, once per row.

```sql
-- app.Projects.ProjectCode is VARCHAR(10).
-- NON-SARGABLE: CONVERT_IMPLICIT is applied to the column, so no index seek.
SELECT p.ProjectId FROM app.Projects AS p WHERE p.ProjectCode = N'TF-CORE';

-- SARGABLE: types match, seek on UQ_Projects_Code.
SELECT p.ProjectId FROM app.Projects AS p WHERE p.ProjectCode = 'TF-CORE';
```

This arrives from .NET by default: `SqlParameter` infers `SqlDbType.NVarChar` for a `string`, and EF Core maps `string` to `nvarchar` unless you configure `.IsUnicode(false)` or `.HasColumnType("varchar(10)")`. One unconfigured property turns a seek into a scan on every request.

The second everyday case is integer division:

```sql
SELECT 5 / 2   AS IntegerDivision;   -- 2
SELECT 5 / 2.0 AS DecimalDivision;   -- 2.500000
```

---

## Q9. What does SARGable mean?
**Answer:**
"Search ARGument-able" — a predicate the engine can satisfy with an index **seek** because the indexed column appears bare on one side of the comparison. Wrap the column in anything and the index becomes unusable for seeking.

| Non-SARGable | SARGable rewrite |
|---|---|
| `WHERE YEAR(t.DueDate) = 2025` | `WHERE t.DueDate >= '2025-01-01' AND t.DueDate < '2026-01-01'` |
| `WHERE t.EstimatedHours * 2 > 40` | `WHERE t.EstimatedHours > 20` |
| `WHERE p.ProjectCode = N'TF-CORE'` (type mismatch) | `WHERE p.ProjectCode = 'TF-CORE'` |
| `WHERE p.ProjectCode COLLATE Latin1_General_CS_AS = 'TF-CORE'` | Fix the column collation instead |
| `WHERE t.Title LIKE N'%pagination%'` | No B-tree can help — use full-text search |
| `WHERE ISNULL(t.DueDate, '9999-12-31') < @d` | `WHERE t.DueDate < @d` plus explicit `OR t.DueDate IS NULL` handling |

```sql
-- Non-SARGable: a function on the column forces a scan of every row.
SELECT t.TaskId FROM app.Tasks AS t WHERE YEAR(t.DueDate) = 2025;

-- SARGable: a half-open range the engine can seek.
SELECT t.TaskId FROM app.Tasks AS t
WHERE t.DueDate >= '2025-01-01' AND t.DueDate < '2026-01-01';
```

Note the leading-wildcard row honestly: the correct answer is "no index rewrite exists", not a clever trick.

---

## Q10. `IDENTITY` or `SEQUENCE`?
**Answer:**

| | `IDENTITY` | `SEQUENCE` |
|---|---|---|
| Scope | One column of one table | A database object, shareable |
| Get the value | Only as a side effect of `INSERT` | `NEXT VALUE FOR` — **before** the insert |
| Reset | `DBCC CHECKIDENT (..., RESEED, n)` | `ALTER SEQUENCE ... RESTART WITH n` |
| Caching | Always cached, not configurable | `CACHE n` or `NO CACHE` |
| Cycle | No | `CYCLE` supported |
| Explicit value | `SET IDENTITY_INSERT ON` | Just insert the number |
| SQL standard | No | Yes (SQL:2003) |

Use `IDENTITY` for ordinary surrogate keys — it is simpler and it is what `app.Users`, `app.Tasks` and `app.Projects` use. Reach for `SEQUENCE` when you need the value **before** the row exists, when several tables must share one number space, or when you need `CYCLE` or explicit cache control.

```sql
DROP SEQUENCE IF EXISTS app.TaskNumberSeq;
GO
CREATE SEQUENCE app.TaskNumberSeq AS INT START WITH 1000 INCREMENT BY 1 CACHE 50;
GO
SELECT NEXT VALUE FOR app.TaskNumberSeq AS ReservedNumber;   -- no row required
GO
DROP SEQUENCE IF EXISTS app.TaskNumberSeq;
GO
```

---

## Q11. Why do `IDENTITY` values have gaps, and how do you get a gapless sequence?
**Answer:**
Because identity allocation is deliberately **not transactional**. If it were, every insert would serialise on the counter. Three sources of gaps:

1. A rolled-back `INSERT` consumes its value permanently.
2. `SET IDENTITY_INSERT` combined with a manual reseed.
3. Cache loss on an unclean shutdown — the counter can jump by up to 1,000 for `INT` or 10,000 for `BIGINT`. Mitigated with trace flag 272, or by using a `SEQUENCE` with `NO CACHE`.

```sql
-- Demonstrate the gap.
BEGIN TRANSACTION;
    INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'gap-demo', '#111111');
ROLLBACK TRANSACTION;

INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'after-gap', '#222222');
SELECT LabelId, LabelName FROM app.Labels WHERE LabelName = N'after-gap';
-- The rolled-back value was consumed and never reused.

DELETE FROM app.Labels WHERE LabelName = N'after-gap';
DBCC CHECKIDENT ('app.Labels', NORESEED);
```

For a genuinely **gapless** sequence — invoice numbers, statutory audit numbers — you need a dedicated generator: a single-row counter table updated with `UPDATE ... SET @next = Value += 1` inside the same transaction as the insert. Say the cost out loud: that serialises every insert on one row. Gaplessness *is* a throughput ceiling; only pay it when a regulator requires it.

---

## Q12. How do you retrieve the key a database just generated?
**Answer:**

| Method | Correct? | Why |
|---|---|---|
| `SCOPE_IDENTITY()` | Yes, for one row in the current scope | Scope-limited and session-limited |
| `@@IDENTITY` | **No** | Returns a value generated by a **trigger** on a different table |
| `IDENT_CURRENT('tbl')` | **No** | Reads across sessions — a race condition |
| `OUTPUT INSERTED.<col>` | **Best** | Works for multi-row inserts, `MERGE`, and sequences |

```sql
-- The only correct approach for a multi-row insert.
DECLARE @NewLabels TABLE (LabelId INT NOT NULL);

INSERT INTO app.Labels (LabelName, ColorHex)
OUTPUT INSERTED.LabelId INTO @NewLabels (LabelId)
VALUES (N'triage', '#AABBCC'), (N'spike', '#CCBBAA');

SELECT LabelId FROM @NewLabels;
DELETE FROM app.Labels WHERE LabelName IN (N'triage', N'spike');
```

The `@@IDENTITY` trap is the one they are testing. If `app.Labels` ever gains an audit trigger that inserts into a table with its own identity, `@@IDENTITY` starts returning that table's key — and nothing errors.

---

## Q13. What is a computed column? When is `PERSISTED` required, and when can you index one?
**Answer:**
An expression stored in the table definition rather than a value.

| | Non-persisted | `PERSISTED` |
|---|---|---|
| Storage | None | Materialised on the page |
| Evaluated | Every read | Once per write |
| Indexable | Only if deterministic **and** precise | Yes, including imprecise expressions |
| Usable in `PRIMARY KEY` / `FOREIGN KEY` | No | Yes |

`app.Users.FullName AS (FirstName + N' ' + LastName) PERSISTED` trades bytes per row for zero recomputation on read and guaranteed indexability.

`PERSISTED` requires **determinism**:

```sql
-- Msg 4936: SYSUTCDATETIME() is non-deterministic, so this cannot be PERSISTED.
-- ALTER TABLE app.Tasks ADD DaysOpen AS (DATEDIFF(DAY, CreatedAtUtc, SYSUTCDATETIME())) PERSISTED;

-- Works, but recomputed per row on every read and cannot be indexed.
ALTER TABLE app.Tasks ADD DaysOpen AS (DATEDIFF(DAY, CreatedAtUtc, SYSUTCDATETIME()));
ALTER TABLE app.Tasks DROP COLUMN DaysOpen;
```

The senior application: promoting a JSON path so it becomes indexable.

```sql
ALTER TABLE app.Tasks
    ADD Epic AS (CAST(JSON_VALUE(MetadataJson, '$.epic') AS NVARCHAR(50))) PERSISTED;

CREATE NONCLUSTERED INDEX IX_Tasks_Epic ON app.Tasks (Epic) WHERE Epic IS NOT NULL;

SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.Epic = N'performance';

DROP INDEX IX_Tasks_Epic ON app.Tasks;
ALTER TABLE app.Tasks DROP COLUMN Epic;
```

---

## Q14. Temp table or table variable?
**Answer:**
The deciding factor is **statistics**, not syntax. Both live in `tempdb`.

| | `#temp` | `@tablevar` |
|---|---|---|
| Scope | Session, including nested procs | **Batch** — dies at `GO` |
| Statistics | Yes | No |
| Indexes | Any, added after creation | Inline `PRIMARY KEY` / `UNIQUE` / `INDEX` only |
| Rolled back by `ROLLBACK` | Yes | **No** |
| Triggers recompiles | Yes | No |
| Passable to a procedure | No | As a `READONLY` TVP |

Without statistics the optimizer estimates **one row** for a table variable and picks a nested loop. At 20 rows that is fine; at 200,000 it is catastrophic. SQL Server 2019 deferred compilation improves the estimate but still creates no statistics.

> Rule of thumb: table variable for tens of rows, `#temp` for thousands. Use a table variable deliberately when you need data to **survive a `ROLLBACK`** — for example, accumulating error rows inside a loop.

`##global` temp tables are visible to every session until their creator disconnects. That is a concurrency bug with a syntax; there is essentially no correct production use.

---

## Q15. `SELECT INTO` or `INSERT INTO ... SELECT`?
**Answer:**

| | `SELECT ... INTO` | `INSERT INTO ... SELECT` |
|---|---|---|
| Target | Created by the statement; must not exist | Must already exist |
| Column types | **Inferred** from the source expressions | Declared by you |
| Copies constraints / defaults / indexes | No (nullability and `IDENTITY` only) | N/A |
| Minimal logging | Yes, under `SIMPLE` / `BULK_LOGGED` | Only with `TABLOCK` and conditions |
| Right for | Ad-hoc snapshots, staging, throwaway analysis | Anything repeatable or deployed |

```sql
-- Quick snapshot before a risky change -- the legitimate use.
DROP TABLE IF EXISTS app.Tasks_Backup;
SELECT * INTO app.Tasks_Backup FROM app.Tasks;
DROP TABLE IF EXISTS app.Tasks_Backup;
```

Never put `SELECT INTO` in deployed code. The types drift as the source changes, no constraints come along, and it holds a schema lock on the destination for the whole statement.

---

## Q16. Why is `UNIQUEIDENTIFIER` a poor clustered primary key, and what are the alternatives?
**Answer:**
Two separate costs:

1. **Width.** 16 bytes versus 4 for `INT`. The clustered key is duplicated into **every** nonclustered index, so the penalty multiplies.
2. **Randomness.** `NEWID()` produces values with no ordering, so every insert lands on a random page. That means continuous page splits, low page density, and index fragmentation that no maintenance window keeps up with.

| Generator | Ordering | Effect |
|---|---|---|
| `NEWID()` | Random | Constant page splits and fragmentation |
| `NEWSEQUENTIALID()` | Increasing within one boot cycle | Much less fragmentation, but predictable and derived from the MAC address |
| App-side UUIDv7 (`Guid.CreateVersion7()`, .NET 9) | Time-ordered | Sequential inserts, no round trip, no MAC leak |

The pattern that gets both properties:

```sql
DROP TABLE IF EXISTS app.TaskShareLinks;

CREATE TABLE app.TaskShareLinks
(
    ShareLinkId  INT              NOT NULL IDENTITY(1,1)
        CONSTRAINT PK_TaskShareLinks PRIMARY KEY CLUSTERED,      -- narrow, sequential
    PublicToken  UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_TaskShareLinks_Token DEFAULT (NEWID())
        CONSTRAINT UQ_TaskShareLinks_Token UNIQUE NONCLUSTERED,  -- random, unguessable
    TaskId       INT              NOT NULL
        CONSTRAINT FK_TaskShareLinks_Task REFERENCES app.Tasks (TaskId),
    ExpiresAtUtc DATETIME2(3)     NOT NULL
);

DROP TABLE IF EXISTS app.TaskShareLinks;
```

`NEWSEQUENTIALID()` is also worth flagging as a security consideration: sequential public identifiers are enumerable, which is precisely what you were trying to avoid by using a GUID.

---

## Q17. What is `ROWVERSION` for, and why not a `LastModifiedUtc` column?
**Answer:**
`ROWVERSION` is 8 bytes of database-scoped, monotonically increasing binary that SQL Server updates automatically on **every** modification of the row. It is not a datetime, despite the deprecated synonym `TIMESTAMP`. Its only job is optimistic concurrency.

```sql
ALTER TABLE app.Tasks ADD RowVer ROWVERSION;

DECLARE @Original BINARY(8) = (SELECT RowVer FROM app.Tasks WHERE TaskId = 5);

UPDATE app.Tasks
   SET StatusId = 4, ModifiedAtUtc = SYSUTCDATETIME()
 WHERE TaskId = 5
   AND RowVer  = @Original;

SELECT @@ROWCOUNT AS RowsUpdated;   -- 0 means someone else won the race

ALTER TABLE app.Tasks DROP COLUMN RowVer;
```

A `LastModifiedUtc` datetime fails as a concurrency token for three reasons: resolution (two updates in the same millisecond are indistinguishable), clock skew across nodes, and the fact that nothing prevents application code from writing a stale or forged value. `ROWVERSION` cannot be written by anyone.

EF Core maps it with `[Timestamp]` or `.IsRowVersion()`, and turns a zero-row update into a `DbUpdateConcurrencyException` automatically.

---

## Q18. *(Senior)* Which `ALTER` operations are metadata-only? How would you change `app.Tasks.TaskId` from `INT` to `BIGINT` on a 40-million-row live table?
**Answer:**

| Change | Metadata-only? |
|---|---|
| Add a nullable column | Yes |
| Add a `NOT NULL` column **with** a `DEFAULT` (2012+ Ent / 2016 SP1+ all editions) | Yes, for most fixed-length types |
| Widen `VARCHAR(50)` -> `VARCHAR(100)` | Yes |
| `VARCHAR(50)` -> `VARCHAR(MAX)` | **No** — full rewrite to LOB |
| Narrow `VARCHAR(100)` -> `VARCHAR(50)` | **No** — validates then rewrites |
| `INT` -> `BIGINT` | **No** — every row rewritten |
| `VARCHAR(n)` -> `NVARCHAR(n)` | **No** — every row rewritten, storage doubles |
| `NULL` -> `NOT NULL` | **No** — full scan to validate |
| `NOT NULL` -> `NULL` | Yes |
| `DROP COLUMN` | Yes (metadata); space reclaimed only on index rebuild |

There is also a trap worth volunteering: `ALTER COLUMN` does **not** preserve nullability. Omit `NULL`/`NOT NULL` and it falls back to `ANSI_NULL_DFLT_ON`, silently making a `NOT NULL` column nullable. Always restate it.

For the `INT` -> `BIGINT` migration on a live 40-million-row table, an in-place `ALTER` is not an option — it rewrites every row and every index while holding a `Sch-M` lock. The approach is **expand / migrate / contract**:

```sql
-- Deploy 1 (EXPAND): add the wide column, nullable. Metadata-only.
ALTER TABLE app.Tasks ADD TaskIdBig BIGINT NULL;

-- Deploy 2a: the application begins dual-writing both columns.
-- Deploy 2b (MIGRATE): backfill in bounded batches so the log stays small and
-- lock escalation (around 5,000 locks per statement) never triggers.
WHILE 1 = 1
BEGIN
    UPDATE TOP (5000) app.Tasks
       SET TaskIdBig = CAST(TaskId AS BIGINT)
     WHERE TaskIdBig IS NULL;

    IF @@ROWCOUNT = 0 BREAK;
    -- In production: CHECKPOINT / log backup between batches.
END;

-- Deploy 3 (CONTRACT): only once nothing reads or writes the old column.
ALTER TABLE app.Tasks DROP COLUMN TaskIdBig;
```

In reality, because `TaskId` is the clustered primary key referenced by six foreign keys, the shadow-table approach is safer still: build `app.Tasks_New` with the target schema, backfill in batches, keep it current with triggers or Change Tracking, then swap with `sp_rename` inside a short maintenance window — or use a partition switch if the table is partitioned. Name the trade-off: the shadow table needs double the storage and a cutover window; the in-place `ALTER` needs a much longer one.

Mention `WITH (ONLINE = ON)` accurately: available for `ALTER COLUMN` on Enterprise and Azure SQL from SQL Server 2016, it still takes a brief `Sch-M` lock at the end, so you still set `LOCK_TIMEOUT` and still deploy in a low-traffic window.

---

## Q19. *(Senior)* What are sparse columns, when are they worth it, and what would you do instead?
**Answer:**
A `SPARSE` column stores `NULL` in **zero** bytes, at the cost of **4 extra bytes** for every non-`NULL` value. The break-even `NULL` percentage varies by type — roughly 98% for `BIT`, 64% for `INT`, 52% for `DATETIME`, 43% for `UNIQUEIDENTIFIER`.

Restrictions: cannot be `NOT NULL`, cannot have a `DEFAULT`, cannot be `IDENTITY` or `ROWGUIDCOL`, cannot be a computed column, cannot be `TEXT`/`NTEXT`/`IMAGE`/`TIMESTAMP`, and cannot be part of a clustered index key. They pair with filtered indexes (`WHERE col IS NOT NULL`) and with `COLUMN_SET FOR ALL_SPARSE_COLUMNS`.

```sql
DROP TABLE IF EXISTS app.TaskCustomFields;

CREATE TABLE app.TaskCustomFields
(
    TaskId       INT          NOT NULL CONSTRAINT PK_TaskCustomFields PRIMARY KEY,
    CustomerRef  NVARCHAR(50) SPARSE NULL,
    RegulatoryId VARCHAR(30)  SPARSE NULL,
    RiskScore    TINYINT      SPARSE NULL,
    CONSTRAINT FK_TaskCustomFields_Task FOREIGN KEY (TaskId) REFERENCES app.Tasks (TaskId)
);

DROP TABLE IF EXISTS app.TaskCustomFields;
```

The senior half of the answer is what you do **instead**. If TaskFlow needs per-tenant custom fields, sparse columns solve storage but not modelling — you still need a DDL deploy per new field, and the 1,024-column limit (30,000 with a column set) becomes a ceiling. The real options are:

| Approach | Good when | Cost |
|---|---|---|
| Sparse columns | A fixed, known set of mostly-empty attributes | DDL per field; column limit |
| Child table (EAV) | Truly open-ended attributes | Every read becomes a pivot; typing is lost |
| `NVARCHAR(MAX)` + `ISJSON` `CHECK` | Per-tenant shapes, write-mostly | Filtering needs persisted computed columns to be indexable |
| A separate document store | Shapes diverge wildly per tenant | A second store to operate and reconcile |

For TaskFlow the JSON column plus persisted computed columns for the two or three paths that are actually filtered is the right balance — which is exactly why `app.Tasks.MetadataJson` exists.

---

## Q20. *(Architect)* Why is putting everything in `dbo` an anti-pattern? Design a schema strategy.
**Answer:**
A schema is three things at once: a **namespace**, a **security boundary**, and an **ownership boundary**. Collapsing everything into `dbo` throws all three away.

Concrete costs:

1. **No coarse-grained permissions.** You cannot say "reporting may read reference data but not user data" without enumerating every table and re-granting on every deploy. With schemas, `GRANT SELECT ON SCHEMA::ref` covers current and future objects.
2. **Name collisions.** Two subsystems both want `Settings`. One of them ends up `BillingSettings`, encoding the namespace into the name instead of using the namespace feature.
3. **Unpredictable resolution.** An unqualified `SELECT * FROM Tasks` resolves against each user's default schema first, then `dbo`. Different users can hit different tables with identical SQL.
4. **Plan cache duplication.** Unqualified names produce one cache entry per default schema for the same query text.
5. **No structural signal.** New engineers cannot tell reference data from transactional data from audit data.

TaskFlow's strategy:

| Schema | Contains | Permission posture |
|---|---|---|
| `app` | Transactional business tables | App role: `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| `ref` | Small lookup tables | App role: `SELECT` only; changes are deployments |
| `audit` | Append-only history | App role: `INSERT` only. Nobody gets `UPDATE` or `DELETE` |

```sql
CREATE ROLE TaskFlowApp;
CREATE ROLE TaskFlowReporting;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::app   TO TaskFlowApp;
GRANT SELECT                          ON SCHEMA::ref   TO TaskFlowApp;
GRANT INSERT                          ON SCHEMA::audit TO TaskFlowApp;

GRANT SELECT ON SCHEMA::app TO TaskFlowReporting;
GRANT SELECT ON SCHEMA::ref TO TaskFlowReporting;
DENY  SELECT ON app.Users (HourlyRate) TO TaskFlowReporting;   -- column-level DENY wins
```

The `audit` schema is the clearest illustration. Because `UPDATE` and `DELETE` are never granted on it, the append-only guarantee is enforced by the **database**, not by discipline. That is the difference between a convention and a control, and it is what an auditor will ask you to demonstrate.

Round it out with the rules that keep it working: schema-qualify every reference so resolution is deterministic and the plan cache stays clean; grant to **roles**, never to users; name every constraint explicitly so rollback scripts are portable across environments; and treat `dbo` as reserved for almost nothing.

---
