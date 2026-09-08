# Topic 02: Data Types & DDL

> Every performance ceiling and every data-corruption bug in **TaskFlow** is set at `CREATE TABLE` time. A `FLOAT` for billable hours quietly loses cents. A `DATETIME` for `CompletedAtUtc` rounds `23:59:59.999` into the next day. An `NVARCHAR(MAX)` on a column that holds 40 characters wrecks memory grants and blocks indexing forever. Types are not annotations — they are the outermost integrity constraint, the storage contract, and the input to every cardinality estimate the optimizer makes. This topic covers what SQL Server offers, how to choose, and how to change a schema afterwards without taking production down.

---

## 1. Types Are Constraints, Not Annotations

A column's type does four jobs at once:

| Job | Consequence of getting it wrong |
|---|---|
| **Domain constraint** | `VARCHAR(20)` for a status lets `'DOEN'` in; `TINYINT` + FK to `ref.TaskStatuses` does not |
| **Storage contract** | Row width drives rows-per-page, which drives I/O and buffer-pool pressure |
| **Comparison semantics** | Precedence decides which side of a predicate is implicitly converted |
| **Optimizer input** | Declared length drives memory grants; wrong grants spill sorts to `tempdb` |

`ref.TaskStatuses.StatusId` is `TINYINT`: 1 byte, 0–255, `NOT NULL`, narrowed further by `FK_Tasks_Status`. Three mechanisms, one column, zero invalid statuses possible.

> **Rule of thumb:** Pick the **narrowest type that holds every legal value for the life of the system**. "Use `BIGINT`/`NVARCHAR(MAX)` to be safe" is not caution — it is a cost paid on every page, every index and every plan.

---

## 2. Exact Numerics

| Type | Range | Bytes |
|---|---|---|
| `BIT` | 0, 1, `NULL` | 1 bit (8 share a byte, 9–16 share two) |
| `TINYINT` | 0 to 255 | 1 |
| `SMALLINT` | -32,768 to 32,767 | 2 |
| `INT` | -2,147,483,648 to 2,147,483,647 | 4 |
| `BIGINT` | -9.22e18 to 9.22e18 | 8 |
| `DECIMAL(p,s)` / `NUMERIC(p,s)` | p = 1–38 total digits, s = digits after the point | 5 / 9 / 13 / 17 |
| `MONEY` / `SMALLMONEY` | ±922,337,203,685,477.5807 / ±214,748.3647 | 8 / 4 — avoid both |

`DECIMAL` storage depends on **precision only**: p 1–9 = 5 bytes, 10–19 = 9, 20–28 = 13, 29–38 = 17. `DECIMAL` and `NUMERIC` are synonyms in SQL Server; TaskFlow uses `DECIMAL` throughout — `DECIMAL(9,2)` for `HourlyRate`, `DECIMAL(12,2)` for `Budget`, `DECIMAL(6,2)` for `EstimatedHours`, `DECIMAL(5,2)` for `TimeEntries.Hours`.

Arithmetic **changes** precision and scale: multiplication yields precision `p1+p2+1` and scale `s1+s2`, capped at 38 — and when the cap bites, SQL Server sacrifices **scale**, silently losing decimal places in a long expression.

`MONEY` truncates every **intermediate** result to 4 decimal places, so error compounds:

```sql
DECLARE @rate MONEY = 0.0001, @dec DECIMAL(19,4) = 0.0001;
SELECT @rate / 3 AS MoneyDiv,    -- 0.0000  all precision gone
       @dec  / 3 AS DecimalDiv;  -- 0.000033333...
```

It also stores no currency code and is not in the standard. `DECIMAL(19,4)` is a drop-in replacement with correct arithmetic.

> **Anti-pattern:** `MONEY` for anything. Use `DECIMAL(p,s)` at the scale your domain requires, and keep the currency code in its own `CHAR(3)` column.

---

## 3. Approximate Numerics — and the Money Rule

| Type | Storage | Precision | Range |
|---|---|---|---|
| `REAL` (= `FLOAT(24)`) | 4 bytes | ~7 significant digits | ±3.40e38 |
| `FLOAT(n)`, n = 25–53 | 8 bytes | ~15 significant digits | ±1.79e308 |

IEEE 754 binary floating point cannot represent 0.1, 0.2 or 0.3 exactly, so equality fails in ways that look like ghosts: with `@float FLOAT = 0.1` and `@dec DECIMAL(5,2) = 0.1`, `@float * 3 = 0.3` is **false** while `@dec * 3 = 0.3` is **true**.

`FLOAT` is correct for **measurements with inherent error** — sensor readings, scientific quantities. It is never correct for money or billed hours.

> **Rule of thumb:** If someone can be sued over the value, it is `DECIMAL`. If it came from a physical instrument, `FLOAT` is fine.

---

## 4. Character Types

| Type | Max declared | Bytes stored | Notes |
|---|---|---|---|
| `CHAR(n)` | 8,000 | exactly `n` (space-padded) | Fixed-width codes only |
| `VARCHAR(n)` | 8,000 | actual + 2 bytes offset | Non-Unicode, code-page bound |
| `VARCHAR(MAX)` | 2 GB | LOB, off-row when large | Cannot be an index key |
| `NCHAR(n)` | 4,000 | exactly `2n` | Fixed-width Unicode |
| `NVARCHAR(n)` | 4,000 | 2 × actual + 2 bytes | Default for user text |
| `NVARCHAR(MAX)` | 2 GB | LOB | Cannot be an index key |

Two collation suffixes change the arithmetic. **`_UTF8`** (SQL Server 2019+) makes `CHAR`/`VARCHAR` store UTF-8 — 1 byte for ASCII, 2–4 otherwise. **`_SC`** makes `NVARCHAR` handle surrogate pairs, so `LEN()` and `SUBSTRING()` do not split an emoji in half.

Storage math for `'ada.lovelace@taskflow.io'` (24 characters):

| Declaration | Bytes on the page |
|---|---|
| `NVARCHAR(256)` (TaskFlow's choice) | 24 × 2 + 2 = **50** |
| `VARCHAR(256)` under a `_UTF8` collation | 24 + 2 = **26** |
| `NCHAR(256)` | 256 × 2 = **512** |
| `CHAR(256)` | **256** |

Declared length costs nothing on disk for `VAR*` types, but it costs plenty elsewhere: the optimizer estimates average row size at **50% of the declared maximum** and sizes the memory grant from that. Over-declare and you either over-reserve memory or spill to `tempdb`.

`CHAR` is right only when every value is the same width and the column is `NOT NULL` — `app.Users.CountryCode CHAR(2)` and `app.Labels.ColorHex CHAR(7)`. Note `LEN()` ignores trailing spaces while `DATALENGTH()` does not, so a `CHAR(20)` holding `'bug'` reports 3 and 20.

> **Anti-pattern:** `NVARCHAR(MAX)` as a default. It cannot be an index key (900 bytes clustered, 1,700 nonclustered), it forces LOB handling, and it tells the optimizer nothing. TaskFlow uses it in exactly three places — `app.Tasks.Description`, `app.Comments.Body`, `app.Tasks.MetadataJson` — all unbounded and never index keys. `app.Tasks.Title` is `NVARCHAR(200)` because it is displayed, sorted and searched.

---

## 5. Date and Time

| Type | Range | Accuracy | Bytes | Verdict |
|---|---|---|---|---|
| `DATE` | 0001 to 9999 | 1 day | 3 | Calendar dates |
| `TIME(n)` | 00:00:00 to 23:59:59.9999999 | 100 ns | 3–5 | Time of day only |
| `SMALLDATETIME` | 1900 to 2079-06-06 | **1 minute** (rounds) | 4 | Avoid |
| `DATETIME` | 1753 to 9999 | **3.33 ms** (rounds to .000/.003/.007) | 8 | Legacy — avoid |
| `DATETIME2(n)` | 0001 to 9999 | 100 ns | 6–8 | The default choice |
| `DATETIMEOFFSET(n)` | as `DATETIME2` + offset | 100 ns | 8–10 | When the offset is business data |

`DATETIME2(n)`: n = 0–2 costs 6 bytes, 3–4 costs 7, 5–7 costs 8. `DATETIMEOFFSET` adds 2.

`DATETIME2(3)` gives **true millisecond** precision in **7 bytes** — one byte *less* than `DATETIME`, which manages only 3.33 ms and rounds. `CAST('2025-09-08T23:59:59.999' AS DATETIME)` returns `2025-09-09 00:00:00.000`: the **date changed**. The same cast to `DATETIME2(3)` stores the value as written.

That rounding is why legacy code is littered with `BETWEEN @start AND '...23:59:59.997'`. With `DATETIME2` you write a **half-open range**, which is correct *and* SARGable:

```sql
SELECT t.TaskId, t.Title, t.CompletedAtUtc
FROM app.Tasks AS t
WHERE t.CompletedAtUtc >= '2024-06-01'
  AND t.CompletedAtUtc <  '2024-07-01';
```

`DATETIME2` has no zone. `DATETIMEOFFSET` carries a UTC offset — which is **not** a time zone, because an offset knows nothing about DST transitions.

```sql
-- SWITCHOFFSET re-presents an existing offset; TODATETIMEOFFSET attaches one
-- to a naive DATETIME2; AT TIME ZONE converts through a named zone.
SELECT t.TaskId, t.CompletedAtUtc,
       t.CompletedAtUtc AT TIME ZONE 'UTC'
                        AT TIME ZONE 'India Standard Time' AS CompletedLocal
FROM app.Tasks AS t
WHERE t.CompletedAtUtc IS NOT NULL;
```

> **Rule of thumb:** Store **UTC in `DATETIME2(3)`**, name the column `...AtUtc`, convert at the edge. TaskFlow does exactly this. Calendar-only values — `StartDate`, `EndDate`, `DueDate`, `JoinedOn`, `WorkDate` — are `DATE`: 3 bytes, no time to be wrong about, no timezone question to answer.

> **Portability:** PostgreSQL's `timestamptz` normalises to UTC on write and renders in the session zone — closer to `DATETIME2` UTC + `AT TIME ZONE` than to `DATETIMEOFFSET`. MySQL's `TIMESTAMP` uses the session zone and stops in 2038. Oracle has both `WITH TIME ZONE` and `WITH LOCAL TIME ZONE`.

---

## 6. Binary Types

| Type | Max | Notes |
|---|---|---|
| `BINARY(n)` | 8,000 | Fixed length, right-padded with zeros |
| `VARBINARY(n)` | 8,000 | Variable length |
| `VARBINARY(MAX)` | 2 GB | LOB; `FILESTREAM` / `FileTable` push it to the filesystem |

Correct uses: fixed-size hashes (`BINARY(32)` for SHA-256), encrypted payloads, `ROWVERSION` values. `HASHBYTES('SHA2_256', ...)` returns 32 bytes; storing that as `BINARY(32)` costs 32, while the hex string in `CHAR(64)` costs 64 for nothing.

> **Anti-pattern:** Uploaded files as `VARBINARY(MAX)` in the transactional database. It inflates backups, evicts hot pages from the buffer pool and slows every restore. Put the bytes in blob storage; store the URL plus a `BINARY(32)` content hash.

---

## 7. The Specialised Types

**`BIT`** — a nullable `BIT` is genuinely three-valued, which a flag almost never should be. Use `BIT NOT NULL` with an explicit `DEFAULT`, as TaskFlow's `IsActive`, `IsArchived`, `IsTerminal`, `IsPrimary` and `IsBillable` all do.

**`UNIQUEIDENTIFIER`** — 16 bytes. The problem is not the width; it is what `NEWID()` does to an index.

| Generator | Ordering | Index effect |
|---|---|---|
| `NEWID()` | Random | Every insert lands on a random page: splits, fragmentation, low density |
| `NEWSEQUENTIALID()` | Increasing within one boot cycle | Far less fragmentation, but predictable and derived from the MAC address |
| App-side UUIDv7 (`Guid.CreateVersion7()`, .NET 9) | Time-ordered | Sequential inserts, no round trip, no MAC leak |

```sql
-- Get both properties: narrow sequential clustered key for storage, random
-- GUID for the externally visible identifier.
CREATE TABLE app.TaskShareLinks
(
    ShareLinkId INT              NOT NULL IDENTITY(1,1)
        CONSTRAINT PK_TaskShareLinks PRIMARY KEY CLUSTERED,
    PublicToken UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_TaskShareLinks_Token DEFAULT (NEWID())
        CONSTRAINT UQ_TaskShareLinks_Token UNIQUE NONCLUSTERED,
    TaskId      INT              NOT NULL
        CONSTRAINT FK_TaskShareLinks_Task REFERENCES app.Tasks (TaskId)
);
DROP TABLE IF EXISTS app.TaskShareLinks;
```

> **Anti-pattern:** `UNIQUEIDENTIFIER DEFAULT NEWID()` as the **clustered** primary key of a high-insert table. Every nonclustered index carries that 16-byte key, and random inserts fragment the clustered index continuously.

**`ROWVERSION`** — 8 bytes of database-scoped, monotonically increasing binary, updated automatically on every modification. Not a datetime, despite the deprecated synonym `TIMESTAMP`. Its one job is optimistic concurrency.

```sql
ALTER TABLE app.Tasks ADD RowVer ROWVERSION;
DECLARE @Original BINARY(8) = (SELECT RowVer FROM app.Tasks WHERE TaskId = 5);
UPDATE app.Tasks SET StatusId = 4 WHERE TaskId = 5 AND RowVer = @Original;
SELECT @@ROWCOUNT AS RowsUpdated;   -- 0 means someone else won the race
ALTER TABLE app.Tasks DROP COLUMN RowVer;
```

> **Rule of thumb:** Use `ROWVERSION` for concurrency, not a `LastModifiedUtc` datetime. Datetimes have resolution limits and clock skew, and nothing stops application code writing a stale value. EF Core maps it with `[Timestamp]` / `IsRowVersion()`.

| Type | What it gives you | The cost |
|---|---|---|
| `XML` | Typed XML validation, XML indexes, `.value()` / `.nodes()` / `.query()` | Verbose and heavy; largely superseded by JSON in `NVARCHAR(MAX)` |
| `HIERARCHYID` | Materialised path: `GetAncestor()`, `IsDescendantOf()`, `GetLevel()` | Reparenting a subtree rewrites every descendant |
| `GEOMETRY` / `GEOGRAPHY` | Planar / ellipsoidal spatial queries and indexes | CLR types, awkward client mapping |
| `SQL_VARIANT` | Most base types in one column (max 8,016 bytes) | No LOB, no computed columns, poor client support, opaque sorting |

TaskFlow's `app.Tasks.ParentTaskId` is a plain self-referencing `INT` FK, not a `HIERARCHYID` — the tree is shallow and reparenting must stay cheap. `audit.TaskHistory.OldValue`/`NewValue` are `NVARCHAR(400)`, not `SQL_VARIANT`, because the audit trail is read by humans and a UI.

---

## 8. Deprecated Types: `TEXT`, `NTEXT`, `IMAGE`

Deprecated since SQL Server 2005 and still shipping. They cannot be local variables, break most string functions, and need the `READTEXT`/`WRITETEXT`/`UPDATETEXT` family.

| Deprecated | Replacement |
|---|---|
| `TEXT` | `VARCHAR(MAX)` |
| `NTEXT` | `NVARCHAR(MAX)` |
| `IMAGE` | `VARBINARY(MAX)` |
| `TIMESTAMP` (the type name) | `ROWVERSION` |

Scan a database you inherited with `SELECT ... FROM sys.columns WHERE TYPE_NAME(user_type_id) IN (N'text', N'ntext', N'image')`. `TaskFlowDb` returns zero rows.

---

## 9. Data Type Precedence and Implicit Conversion

When operands differ, SQL Server converts the **lower-precedence** operand to the higher one. It never asks.

```
sql_variant > xml > datetimeoffset > datetime2 > datetime > smalldatetime > date > time
           > float > real > decimal > money > smallmoney
           > bigint > int > smallint > tinyint > bit
           > uniqueidentifier
           > nvarchar > nchar > varchar > char > varbinary > binary
```

```sql
SELECT 5 / 2   AS IntegerDivision;   -- 2         both operands are INT
SELECT 5 / 2.0 AS DecimalDivision;   -- 2.500000  INT promoted to DECIMAL

-- TINYINT is promoted to DECIMAL, so this is decimal division, not integer.
SELECT t.TaskId, t.EstimatedHours / t.StoryPoints AS HoursPerPoint
FROM app.Tasks AS t
WHERE t.StoryPoints > 0 AND t.EstimatedHours IS NOT NULL;
```

### The SARGability trap

`NVARCHAR` outranks `VARCHAR`, so comparing a `VARCHAR` column to an `NVARCHAR` parameter converts **the column** — once per row — and a converted column cannot be seeked.

```sql
-- app.Projects.ProjectCode is VARCHAR(10).
SELECT p.ProjectId FROM app.Projects AS p WHERE p.ProjectCode = N'TF-CORE';  -- scan
SELECT p.ProjectId FROM app.Projects AS p WHERE p.ProjectCode =  'TF-CORE';  -- seek
```

This is not academic. `SqlParameter` infers `SqlDbType.NVarChar` for a .NET `string`, and EF Core maps `string` to `nvarchar` unless you call `.IsUnicode(false)` or `.HasColumnType("varchar(10)")`. One unconfigured property turns a seek into a scan on every request.

`CAST` is ANSI; `CONVERT` is T-SQL and takes style codes (`CONVERT(DATE, '08/09/2025', 103)`); `TRY_CAST` and `TRY_CONVERT` return `NULL` instead of raising.

> **Rule of thumb:** Match parameter types to column types exactly. When you cannot, convert the **literal** side, never the column side.

---

## 10. Choosing the Right Type

| If the value is... | Use | Not |
|---|---|---|
| A surrogate key, under ~2.1 billion rows | `INT IDENTITY(1,1)` | `BIGINT` "just in case", `UNIQUEIDENTIFIER` |
| A surrogate key that will exceed 2.1 billion | `BIGINT IDENTITY(1,1)` | `INT` plus a painful migration later |
| A small closed enum | `TINYINT` + FK to a `ref` table | `VARCHAR` status strings |
| Money, or hours that get billed | `DECIMAL(p,s)` | `FLOAT`, `REAL`, `MONEY` |
| A percentage | `DECIMAL(5,2)` | `FLOAT` |
| A physical measurement | `FLOAT` | `DECIMAL` |
| True/false | `BIT NOT NULL` + `DEFAULT` | `CHAR(1)` `'Y'`/`'N'`, `TINYINT` |
| A fixed-width code | `CHAR(n)` | `VARCHAR(n)` |
| User text with a known bound | `NVARCHAR(n)` with a real `n` | `NVARCHAR(MAX)` |
| Unbounded prose you never index | `NVARCHAR(MAX)` | `NTEXT` |
| A calendar date | `DATE` | `DATETIME` |
| A UTC instant | `DATETIME2(3)`, named `...AtUtc` | `DATETIME`, `SMALLDATETIME` |
| An instant whose offset is business data | `DATETIMEOFFSET(3)` | `DATETIME2` + a separate offset column |
| A duration | `INT` minutes or `DECIMAL` hours, unit in the name | `TIME` |
| A hash | `BINARY(32)` for SHA-256 | hex string in `CHAR(64)` |
| A concurrency token | `ROWVERSION` | a `LastModifiedUtc` datetime |
| A public, unguessable identifier | `UNIQUEIDENTIFIER`, **nonclustered** unique | `UNIQUEIDENTIFIER` clustered PK |
| Semi-structured metadata | `NVARCHAR(MAX)` + `CHECK (ISJSON(col) = 1)` | `XML`, `SQL_VARIANT` |

---

## 11. Schemas

A schema is three things at once: a **namespace**, a **security boundary** and an **ownership boundary**.

| Schema | Contains | Permission posture |
|---|---|---|
| `app` | Transactional business tables | App role: `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| `ref` | Small lookup tables | App role: `SELECT` only; changes are deployments |
| `audit` | Append-only history | App role: `INSERT` only — nobody gets `UPDATE`/`DELETE` |

```sql
-- One grant covers every current AND future object in the schema.
CREATE ROLE TaskFlowReporting;
GRANT SELECT ON SCHEMA::app TO TaskFlowReporting;
DENY  SELECT ON app.Users (HourlyRate) TO TaskFlowReporting;   -- column DENY wins
GO
CREATE SCHEMA reporting AUTHORIZATION dbo;   -- must be first in its batch
GO
ALTER SCHEMA reporting TRANSFER app.Labels;  -- move an object between schemas
ALTER SCHEMA app       TRANSFER reporting.Labels;
GO
DROP SCHEMA IF EXISTS reporting;
GO
```

The `audit` schema is the clearest illustration: because `UPDATE` and `DELETE` are never granted, the append-only guarantee is enforced by the **database**, not by discipline.

> **Anti-pattern:** Everything in `dbo`. You lose coarse-grained `GRANT ON SCHEMA::`, subsystems collide on names, unqualified references resolve against each user's default schema, and the plan cache gains one entry per default schema for identical query text.

---

## 12. `CREATE TABLE` and `DROP ... IF EXISTS`

```sql
DROP TABLE IF EXISTS app.Sprints;
GO
CREATE TABLE app.Sprints
(
    SprintId      INT           NOT NULL IDENTITY(1,1)
        CONSTRAINT PK_Sprints PRIMARY KEY CLUSTERED,
    ProjectId     INT           NOT NULL,
    SprintName    NVARCHAR(100) NOT NULL,
    StartDate     DATE          NOT NULL,
    EndDate       DATE          NOT NULL,
    CapacityHours DECIMAL(7,2)  NULL,
    IsClosed      BIT           NOT NULL CONSTRAINT DF_Sprints_IsClosed  DEFAULT (0),
    CreatedAtUtc  DATETIME2(3)  NOT NULL CONSTRAINT DF_Sprints_CreatedAt DEFAULT (SYSUTCDATETIME()),
    DurationDays  AS (DATEDIFF(DAY, StartDate, EndDate) + 1) PERSISTED,

    CONSTRAINT FK_Sprints_Project      FOREIGN KEY (ProjectId) REFERENCES app.Projects (ProjectId),
    CONSTRAINT UQ_Sprints_Project_Name UNIQUE (ProjectId, SprintName),
    CONSTRAINT CK_Sprints_Dates        CHECK (EndDate >= StartDate)
);
GO
DROP TABLE IF EXISTS app.Sprints;
GO
```

Every constraint is **explicitly named**. Auto-generated names look like `DF__Sprints__IsClose__3E52440B` and differ per environment, so a rollback script that drops them by name works on your laptop and fails in production.

`DROP ... IF EXISTS` (2016+) covers `TABLE`, `VIEW`, `PROCEDURE`, `FUNCTION`, `TRIGGER`, `INDEX`, `SEQUENCE`, `TYPE`, `SCHEMA`, plus `ALTER TABLE ... DROP COLUMN IF EXISTS` / `DROP CONSTRAINT IF EXISTS`. Before 2016: `IF OBJECT_ID(N'app.Sprints', N'U') IS NOT NULL DROP TABLE app.Sprints;` — where `N'U'` is the object type (`U` table, `V` view, `P` procedure, `TR` trigger), which prevents matching an object of the wrong kind.

---

## 13. `DEFAULT` Constraints

A `DEFAULT` fires when the column is **omitted from the `INSERT` column list**, or when you write the `DEFAULT` keyword. It does **not** fire on `UPDATE`, and it does **not** fire when you explicitly insert `NULL`.

```sql
INSERT INTO app.Labels (LabelName)           VALUES (N'needs-triage');        -- fires
INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'needs-info', DEFAULT); -- fires
-- INSERT INTO app.Labels (LabelName, ColorHex) VALUES (N'broken', NULL);     -- Msg 515
DELETE FROM app.Labels WHERE LabelName IN (N'needs-triage', N'needs-info');

-- Msg 4901: cannot add a NOT NULL column with no DEFAULT to a non-empty table.
-- ALTER TABLE app.Projects ADD RiskLevel TINYINT NOT NULL;
ALTER TABLE app.Projects ADD RiskLevel TINYINT NOT NULL
    CONSTRAINT DF_Projects_RiskLevel DEFAULT (3);
ALTER TABLE app.Projects DROP CONSTRAINT DF_Projects_RiskLevel;   -- must precede the drop
ALTER TABLE app.Projects DROP COLUMN RiskLevel;
```

Adding a `NOT NULL` column to an existing table requires a `DEFAULT` — and since SQL Server 2012 Enterprise / 2016 SP1 all editions, that is **metadata-only** for most fixed-length types, instant even on a billion-row table.

---

## 14. `IDENTITY` vs `SEQUENCE`

| | `IDENTITY` | `SEQUENCE` |
|---|---|---|
| Scope | One column of one table | A database object, shareable across tables |
| Get the value | Only as a side effect of `INSERT` | `NEXT VALUE FOR` — usable **before** the insert |
| Reset | `DBCC CHECKIDENT (..., RESEED, n)` | `ALTER SEQUENCE ... RESTART WITH n` |
| Caching | Always cached, not configurable | `CACHE n` or `NO CACHE` |
| Cycle | Not supported | `CYCLE` supported |
| Explicit value | `SET IDENTITY_INSERT ON` | Just insert the number |
| SQL standard | No | Yes (SQL:2003) |

Allocation in **both** is deliberately non-transactional, so gaps are guaranteed: a rolled-back `INSERT` consumes its value permanently, and an unclean shutdown can jump the cache by up to 1,000 for `INT` or 10,000 for `BIGINT` (mitigated by trace flag 272 or `SEQUENCE ... NO CACHE`).

```sql
SELECT IDENT_CURRENT(N'app.Tasks') AS CurrentValue, IDENT_SEED(N'app.Tasks') AS Seed;
DBCC CHECKIDENT ('app.Tasks', NORESEED);   -- report only; never guess before reseeding

-- SET IDENTITY_INSERT: exactly what 00-create-taskflow-db.sql uses to pin ids.
-- Only ONE table per session may have it ON.
SET IDENTITY_INSERT app.Labels ON;
INSERT INTO app.Labels (LabelId, LabelName, ColorHex) VALUES (99, N'temp-label', '#123456');
SET IDENTITY_INSERT app.Labels OFF;
DELETE FROM app.Labels WHERE LabelId = 99;
GO
CREATE SEQUENCE app.TaskNumberSeq AS INT START WITH 1000 INCREMENT BY 1 CACHE 50;
GO
SELECT NEXT VALUE FOR app.TaskNumberSeq AS ReservedNumber;   -- no row required
DROP SEQUENCE IF EXISTS app.TaskNumberSeq;
GO
```

> **Rule of thumb:** Never promise a **gapless** sequence from `IDENTITY` or `SEQUENCE`. Invoice numbers and anything a regulator counts need a dedicated generator with its own transaction semantics — and that generator serialises every insert. Gaplessness *is* a throughput ceiling.

### Retrieving generated keys

| Method | Correct? |
|---|---|
| `SCOPE_IDENTITY()` | Yes, for one row in the current scope |
| `@@IDENTITY` | **No** — returns a value generated by a **trigger** on another table |
| `IDENT_CURRENT('tbl')` | **No** — reads across sessions; a race condition |
| `OUTPUT INSERTED.<col>` | **Best** — multi-row inserts, `MERGE`, sequences |

```sql
DECLARE @NewLabels TABLE (LabelId INT NOT NULL);
INSERT INTO app.Labels (LabelName, ColorHex)
OUTPUT INSERTED.LabelId INTO @NewLabels (LabelId)
VALUES (N'triage', '#AABBCC'), (N'spike', '#CCBBAA');

SELECT LabelId FROM @NewLabels;
DELETE FROM app.Labels WHERE LabelName IN (N'triage', N'spike');
```

---

## 15. Computed Columns

| | Non-persisted | `PERSISTED` |
|---|---|---|
| Storage | None | Materialised on the page |
| Evaluated | Every read | Once per write |
| Indexable | Only if deterministic **and** precise | Yes, including imprecise expressions |
| Usable in `PRIMARY KEY` / `FOREIGN KEY` | No | Yes |

`app.Users.FullName AS (FirstName + N' ' + LastName) PERSISTED` trades bytes per row for zero recomputation on read, and guarantees indexability regardless of session SET options. `PERSISTED` requires determinism — `ALTER TABLE app.Tasks ADD DaysOpen AS (DATEDIFF(DAY, CreatedAtUtc, SYSUTCDATETIME())) PERSISTED` fails with `Msg 4936`, while the same expression without `PERSISTED` works but is recomputed per row and cannot be indexed.

The senior application is promoting a JSON path so it becomes indexable — the standard fix for the `MetadataJson` scan problem, previewed here and covered in Topic 18:

```sql
ALTER TABLE app.Tasks
    ADD Epic AS (CAST(JSON_VALUE(MetadataJson, '$.epic') AS NVARCHAR(50))) PERSISTED;
CREATE NONCLUSTERED INDEX IX_Tasks_Epic ON app.Tasks (Epic) WHERE Epic IS NOT NULL;

SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.Epic = N'performance';

DROP INDEX IX_Tasks_Epic ON app.Tasks;
ALTER TABLE app.Tasks DROP COLUMN Epic;
```

> **Anti-pattern:** A non-persisted computed column calling a scalar user-defined function. Pre-2019 it forces a serial plan for the entire query and executes once per row.

---

## 16. Sparse Columns

A `SPARSE` column stores `NULL` in **zero bytes**, at the cost of **4 extra bytes** per non-`NULL` value. Break-even depends on the type — roughly 98% `NULL` for `BIT`, 64% for `INT`, 52% for `DATETIME`, 43% for `UNIQUEIDENTIFIER`.

Restrictions: cannot be `NOT NULL`, cannot have a `DEFAULT`, cannot be `IDENTITY`/`ROWGUIDCOL`, cannot be computed, cannot be `TEXT`/`NTEXT`/`IMAGE`/`TIMESTAMP`, cannot be part of a clustered index key. They pair with filtered indexes (`WHERE col IS NOT NULL`) and with `COLUMN_SET FOR ALL_SPARSE_COLUMNS`.

```sql
CREATE TABLE app.TaskCustomFields
(
    TaskId       INT          NOT NULL CONSTRAINT PK_TaskCustomFields PRIMARY KEY,
    CustomerRef  NVARCHAR(50) SPARSE NULL,
    RegulatoryId VARCHAR(30)  SPARSE NULL,
    RiskScore    TINYINT      SPARSE NULL
);
DROP TABLE IF EXISTS app.TaskCustomFields;
```

> **Anti-pattern:** Sparse columns as a substitute for modelling. With 200 optional attributes you have a design problem — a child table or a JSON column — and sparse columns only make the storage of that problem cheaper. You still need a DDL deploy per new field.

---

## 17. `SELECT INTO` vs `INSERT INTO ... SELECT`

| | `SELECT ... INTO` | `INSERT INTO ... SELECT` |
|---|---|---|
| Target table | Created by the statement; must **not** exist | Must already exist |
| Column types | **Inferred** from the source expressions | Declared by you |
| Copies constraints / indexes / defaults | No (nullability and `IDENTITY` only) | N/A |
| Minimal logging | Yes, under `SIMPLE`/`BULK_LOGGED` | Only with `TABLOCK` and conditions |
| Right for | Ad-hoc snapshots, staging, throwaway analysis | Anything repeatable or deployed |

```sql
-- SELECT INTO: fast disposable snapshot. Types are INFERRED -- inspect them.
SELECT t.TaskId, t.EstimatedHours * 2 AS DoubledHours, CONCAT(t.Title, N' [copy]') AS TitleCopy
INTO #Inferred
FROM app.Tasks AS t;

SELECT c.name, TYPE_NAME(c.user_type_id) AS TypeName, c.max_length, c.precision, c.scale
FROM tempdb.sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'tempdb..#Inferred');
DROP TABLE IF EXISTS #Inferred;

-- INSERT INTO ... SELECT: explicit target, explicit columns, explicit types.
CREATE TABLE app.TaskArchive
(
    TaskId        INT           NOT NULL CONSTRAINT PK_TaskArchive PRIMARY KEY,
    Title         NVARCHAR(200) NOT NULL,
    ArchivedAtUtc DATETIME2(3)  NOT NULL
        CONSTRAINT DF_TaskArchive_ArchivedAt DEFAULT (SYSUTCDATETIME())
);
INSERT INTO app.TaskArchive (TaskId, Title)
SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.StatusId IN (6, 7);   -- DONE, CANCELLED
DROP TABLE IF EXISTS app.TaskArchive;
```

> **Anti-pattern:** `SELECT INTO` in deployed code. Inferred types drift as the source changes, no constraints come along, and it holds a schema lock on the destination for the whole statement.

---

## 18. Temp Tables, Table Variables and Table Types

All three live in `tempdb`. The differences are **statistics, scope and logging**.

| | `#temp` | `##global` | `@tablevar` | Table type / TVP |
|---|---|---|---|---|
| Scope | Session, incl. nested procs | All sessions until the creator disconnects | **Batch** | Parameter |
| Statistics | Yes | Yes | No (2019+ deferred compilation improves the estimate) | No |
| Indexes | Any, added after creation | Any | Inline `PRIMARY KEY`/`UNIQUE`/`INDEX` only | Inline only |
| Rolled back by `ROLLBACK` | Yes | Yes | **No** | n/a |
| Triggers recompiles | Yes | Yes | No | No |
| Passable to a procedure | No | Yes | As a read-only TVP | Yes, always `READONLY` |
| Best for | 1,000+ rows, or when you need stats and indexes | Almost never | Small sets, or data that must survive a rollback | Passing a set from .NET in one round trip |

```sql
-- #temp: session-scoped, has statistics, indexable AFTER creation.
SELECT t.TaskId, t.ProjectId, t.DueDate
INTO #OverdueTasks
FROM app.Tasks AS t
WHERE t.DueDate < CAST(SYSUTCDATETIME() AS DATE) AND t.StatusId NOT IN (6, 7);

CREATE CLUSTERED INDEX IX_OverdueTasks_Project ON #OverdueTasks (ProjectId);

SELECT p.ProjectCode, COUNT(*) AS Overdue
FROM #OverdueTasks AS o
JOIN app.Projects  AS p ON p.ProjectId = o.ProjectId
GROUP BY p.ProjectCode ORDER BY Overdue DESC;
DROP TABLE IF EXISTS #OverdueTasks;
GO

-- Table variable: batch-scoped, no statistics, INLINE indexes only (2014+).
DECLARE @Priorities TABLE
(
    PriorityId   TINYINT     NOT NULL PRIMARY KEY,
    PriorityCode VARCHAR(20) NOT NULL,
    INDEX IX_Code NONCLUSTERED (PriorityCode)
);
INSERT INTO @Priorities SELECT p.PriorityId, p.PriorityCode FROM ref.Priorities AS p;
SELECT PriorityId, PriorityCode FROM @Priorities ORDER BY PriorityId;
GO

-- Table type + TVP: how .NET sends a set of ids in ONE round trip.
CREATE TYPE app.TaskIdList AS TABLE (TaskId INT NOT NULL PRIMARY KEY);
GO
CREATE PROCEDURE app.usp_GetTasksByIds @TaskIds app.TaskIdList READONLY   -- always READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.TaskId, t.Title FROM app.Tasks AS t JOIN @TaskIds AS i ON i.TaskId = t.TaskId;
END;
GO
DECLARE @Ids app.TaskIdList;
INSERT INTO @Ids (TaskId) VALUES (1), (5), (20);
EXEC app.usp_GetTasksByIds @TaskIds = @Ids;
GO
DROP PROCEDURE IF EXISTS app.usp_GetTasksByIds;
DROP TYPE IF EXISTS app.TaskIdList;
GO
```

> **Rule of thumb:** Table variable for tens of rows, `#temp` for thousands. Without statistics the optimizer estimates **one row** and picks a nested loop — fine at 20 rows, catastrophic at 200,000. `##global` temp tables are a concurrency bug with a syntax.

---

## 19. Naming Conventions

| Object | Pattern | TaskFlow example |
|---|---|---|
| Schema | lowercase noun | `app`, `ref`, `audit` |
| Table | PascalCase, plural | `app.TaskAssignments` |
| Column | PascalCase, singular | `EstimatedHours` |
| Primary key | `PK_<Table>` | `PK_Tasks` |
| Foreign key | `FK_<Child>_<Parent>` | `FK_Tasks_Project` |
| Unique | `UQ_<Table>_<Cols>` | `UQ_Projects_Code` |
| Check | `CK_<Table>_<Rule>` | `CK_Tasks_Estimate` |
| Default | `DF_<Table>_<Column>` | `DF_Users_IsActive` |
| Index | `IX_<Table>_<Cols>` | `IX_Tasks_ProjectId_StatusId` |
| Procedure | `usp_<Verb><Noun>` | `app.usp_GetTasksByIds` |
| Sequence / table type | `<Noun>Seq` / `<Noun>List` | `app.TaskNumberSeq`, `app.TaskIdList` |

Suffixes carry meaning: `...Id` a key, `Is...`/`Has...` a `BIT NOT NULL`, `...AtUtc` a `DATETIME2` UTC instant, `...Date`/`...On` a `DATE`, `...Hours`/`...Days` a duration with its unit stated, `...Code` a short natural key, `...Json` JSON in `NVARCHAR(MAX)`.

> **Rule of thumb:** Put the unit in the name. `EstimatedHours` and `SlaHours` are self-documenting; `Duration` is a support ticket. Avoid `tbl_` and `sp_` prefixes (`sp_` makes SQL Server search `master` first), reserved words, spaces, columns called `Data`/`Value`/`Info`, and abbreviations that are not universal in your domain.

---

## 20. `ALTER TABLE` and `ALTER COLUMN` Pitfalls

The question that decides your deployment window: **metadata-only, or a full row rewrite?**

| Change | Metadata-only? | Blocking |
|---|---|---|
| Add a **nullable** column | Yes | Momentary `Sch-M` |
| Add `NOT NULL` **with** a `DEFAULT` (2012+ Ent / 2016 SP1+ all) | Yes, most fixed-length types | Momentary |
| `VARCHAR(50)` -> `VARCHAR(100)` (widen) | Yes | Momentary |
| `VARCHAR(50)` -> `VARCHAR(MAX)` | **No** — full rewrite to LOB | Long |
| `VARCHAR(100)` -> `VARCHAR(50)` (narrow) | **No** — validates then rewrites; fails if data does not fit | Long |
| `INT` -> `BIGINT` | **No** — every row rewritten | Long |
| `VARCHAR(n)` -> `NVARCHAR(n)` | **No** — every row rewritten, storage doubles | Long |
| `NULL` -> `NOT NULL` | **No** — full scan to validate | Long |
| `NOT NULL` -> `NULL` | Yes | Momentary |
| `DROP COLUMN` | Yes — space reclaimed only on index rebuild | Momentary |
| Change a column's collation | **No** — rewrite, may invalidate indexes | Long |

**The nullability trap:** `ALTER COLUMN` does **not** preserve existing nullability. Omit `NULL`/`NOT NULL` and it falls back to the session's `ANSI_NULL_DFLT_ON`, silently making a `NOT NULL` column nullable. Always restate it.

```sql
ALTER TABLE app.Users ALTER COLUMN JobTitle NVARCHAR(150) NULL;   -- widen: metadata-only
ALTER TABLE app.Users ALTER COLUMN JobTitle NVARCHAR(100) NULL;   -- narrow: full rewrite
-- Enterprise / Azure SQL: ... WITH (ONLINE = ON) keeps the Sch-M lock to the very end.
```

An `ALTER COLUMN` is blocked outright when the column is part of a `PRIMARY KEY` or referenced by a `FOREIGN KEY` (for type changes), referenced by a computed column, an index, or a `CHECK`/`UNIQUE` constraint (`Msg 5074` — drop and recreate them), has explicit `CREATE STATISTICS`, is published for replication, or is itself computed or a `ROWVERSION`.

### Expand — migrate — contract

Never rename or drop in the same deploy as the code change. Three deploys, each safe on its own:

```sql
-- Deploy 1 (EXPAND): add the new column, nullable. Metadata-only.
ALTER TABLE app.Tasks ADD DueAtUtc DATETIME2(3) NULL;

-- Deploy 2 (MIGRATE): the app dual-writes; backfill in bounded batches so the
-- log stays small and lock escalation (~5,000 locks per statement) never fires.
WHILE 1 = 1
BEGIN
    UPDATE TOP (1000) app.Tasks
       SET DueAtUtc = CAST(DueDate AS DATETIME2(3))
     WHERE DueDate IS NOT NULL AND DueAtUtc IS NULL;
    IF @@ROWCOUNT = 0 BREAK;
END;

-- Deploy 3 (CONTRACT): only once nothing reads or writes the old column.
ALTER TABLE app.Tasks DROP COLUMN DueAtUtc;
```

> **Anti-pattern:** `sp_rename` on a column in a live system. It updates nothing that referenced the old name — views, procedures, computed columns, constraints, application code — and leaves them broken until first execution.

---

## 21. Schema-Change Safety Checklist

- [ ] Is the change **purely additive** (new table, nullable column, new index)? If so, most of the rest is moot.
- [ ] Is it **expand / migrate / contract**? Nothing renamed or dropped in the same deploy as a code change.
- [ ] Does the schema work with **both** the current and next application version? Deploys are not atomic.
- [ ] Have you estimated the **rewrite cost** — row count times row width over realistic throughput?
- [ ] Which **locks**, for how long? A `Sch-M` lock blocks readers as well as writers.
- [ ] Is `WITH (ONLINE = ON)` available on this **edition**, and did you set `LOCK_TIMEOUT`?
- [ ] Are backfills **batched** with a bounded `TOP (n)`?
- [ ] Is every constraint **explicitly named** so the rollback script can find it?
- [ ] Do you have a **tested rollback script**, not just a rollback plan?
- [ ] Do you have a **backup or snapshot**, and do you know the restore time?
- [ ] Was it rehearsed on a **production-sized** copy, not a 35-row dev database?
- [ ] Will it invalidate large parts of the **plan cache** and cause a compile storm at peak?
- [ ] Did any constraint get re-enabled `WITH NOCHECK`, leaving it **untrusted**?

```sql
-- Untrusted constraints: the optimizer stops using them for join elimination
-- and predicate simplification. TaskFlowDb returns zero rows. Keep it that way.
SELECT OBJECT_NAME(fk.parent_object_id) AS TableName, fk.name AS ConstraintName
FROM sys.foreign_keys AS fk WHERE fk.is_not_trusted = 1
UNION ALL
SELECT OBJECT_NAME(cc.parent_object_id), cc.name
FROM sys.check_constraints AS cc WHERE cc.is_not_trusted = 1;
```

> **Portability:** the type mapping differs sharply across engines, and that is where migrations actually break.

| Concept | T-SQL | PostgreSQL | MySQL | Oracle |
|---|---|---|---|---|
| Auto-increment | `IDENTITY(1,1)` | `GENERATED ... AS IDENTITY` | `AUTO_INCREMENT` | `GENERATED ... AS IDENTITY` |
| Unicode text | `NVARCHAR(n)` | `varchar(n)` (DB is UTF-8) | `VARCHAR(n)` + `utf8mb4` | `NVARCHAR2(n)` |
| Instant with offset | `DATETIMEOFFSET` | `timestamptz` | `TIMESTAMP` (session zone, 2038) | `TIMESTAMP WITH TIME ZONE` |
| Boolean | `BIT` | `boolean` | `TINYINT(1)` | `NUMBER(1)` (23c adds `BOOLEAN`) |
| GUID | `UNIQUEIDENTIFIER` | `uuid` | `BINARY(16)` | `RAW(16)` |
| Temp table | `#t` (session) | `CREATE TEMP TABLE` | `CREATE TEMPORARY TABLE` | `GLOBAL TEMPORARY TABLE` |
| Drop if exists | `DROP TABLE IF EXISTS` | `DROP TABLE IF EXISTS` | `DROP TABLE IF EXISTS` | requires a PL/SQL block |

---

## Mental Model

> A table definition is a set of **promises**, and each promise has a price on every page, every index and every plan.
>
> Before you write `CREATE TABLE`, answer these six:
>
> 1. **What is the domain?** The narrowest type that holds every legal value forever, plus `NOT NULL` unless `NULL` has a documented meaning, plus a `CHECK` or an FK for the rest.
> 2. **Exact or approximate?** Money and hours are `DECIMAL`. Measurements are `FLOAT`. There is no third option, and `MONEY` is not it.
> 3. **What is the instant?** UTC in `DATETIME2(3)` named `...AtUtc`; calendar dates in `DATE`; `DATETIMEOFFSET` only when the offset is itself business data.
> 4. **How wide is the row?** Rows per 8 KB page decides your I/O. Over-declared `VARCHAR` also inflates memory grants and spills sorts to `tempdb`.
> 5. **Which side gets converted?** Precedence decides. `NVARCHAR` beats `VARCHAR`, so a mismatched parameter converts the *column* and kills the seek.
> 6. **How will I change this later?** Name every constraint, plan expand/migrate/contract, and know before you deploy whether the `ALTER` is metadata-only or a full rewrite.

Move to [Practice Problems](./Practice-Problems.md).
