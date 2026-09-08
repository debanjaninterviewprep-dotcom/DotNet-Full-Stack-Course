# Topic 04 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

Each starter file already contains the problem restated as a comment header plus a `-- TODO: your solution here` marker. Fill them in — do not rename the files.

| File | Problem | Difficulty | Focus |
|---|---|---|---|
| `P1-string-toolkit.sql` | P1 — The String Toolkit | Easy | `LEN`/`DATALENGTH`, `CHARINDEX`, `STUFF`, `CONCAT_WS` |
| `P2-numeric-expressions.sql` | P2 — Numbers That Do Not Lie | Easy | `ROUND`, integer division, `%`, `NULLIF`, `RAND` |
| `P3-date-arithmetic.sql` | P3 — Date Arithmetic Done Right | Medium | `DATEDIFF` boundaries, `DATEDIFF_BIG`, age, `EOMONTH` |
| `P4-timezones-and-weeks.sql` | P4 — Time Zones and Week Boundaries | Medium | `AT TIME ZONE`, `DATEFIRST`, `ISO_WEEK` |
| `P5-null-and-conversion.sql` | P5 — NULL Handling and Safe Conversion | Medium | `ISNULL`/`COALESCE`, `NULLIF`, `TRY_CONVERT` |
| `P6-sla-dashboard.sql` | P6 — The SLA Dashboard Expression Engine | Hard | `CASE`, `IIF`, `GREATEST`, `STRING_AGG`, determinism |
| `P7-determinism-and-udfs.sql` | P7 — Determinism and the Scalar-Function Tax | Hard | Computed columns, scalar UDF vs iTVF, inlining |

## Prerequisites

The shared sample database must exist. Run it once:

```bash
sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
```

Then start every script with:

```sql
USE TaskFlowDb;
GO
```

## Version requirements

Some functions in this topic are version-gated. Check first and comment out what your instance cannot run:

```sql
SELECT SERVERPROPERTY('ProductVersion')  AS ProductVersion,
       SERVERPROPERTY('EngineEdition')   AS EngineEdition,   -- 5 = Azure SQL Database
       compatibility_level                AS CompatLevel
FROM   sys.databases WHERE name = DB_NAME();
```

| Feature | Minimum |
|---|---|
| `TRY_CAST`, `TRY_CONVERT`, `PARSE`, `IIF`, `CHOOSE`, `CONCAT` | SQL Server 2012 |
| `AT TIME ZONE`, `DATEDIFF_BIG`, `sys.time_zone_info` | SQL Server 2016 |
| `TRIM`, `STRING_AGG`, `CONCAT_WS`, `TRANSLATE`, `STRING_SPLIT` | SQL Server 2017 |
| Scalar UDF inlining | SQL Server 2019, compatibility level 150 |
| `GREATEST`, `LEAST`, `DATETRUNC`, `STRING_SPLIT` ordinal, `TRIM(chars FROM s)` | SQL Server 2022 / Azure SQL |

## Conventions

- **Schema-qualify everything**: `app.Tasks`, `ref.Priorities`, `audit.TaskHistory`. Never a bare `Tasks`.
- **Alias every table**, prefix every column with its alias.
- **Never wrap a column in a function inside a `WHERE` clause** in a shipped query. Transform the literal, not the column.
- **Store UTC, convert at the edge.** `SYSUTCDATETIME()`, not `GETDATE()`.
- Capture deliberately triggered errors (`Msg 535`, `COALESCE(NULL, NULL)`, non-deterministic computed columns) **as comments** so the script still runs top to bottom.

## Leave the database as you found it

P5 and P7 ask you to create objects and change session settings. Every script must clean up after itself:

```sql
-- P5: remove any audit rows you inserted
DELETE FROM audit.TaskHistory WHERE ChangedBy = SUSER_SNAME() AND ColumnName = N'StatusId';

-- P7: index first, then the computed column, then the functions
DROP INDEX IF EXISTS IX_Tasks_CreatedYear ON app.Tasks;
ALTER TABLE app.Tasks DROP COLUMN IF EXISTS CreatedYear;
DROP FUNCTION IF EXISTS dbo.fn_TaskAgeDays;
DROP FUNCTION IF EXISTS dbo.itvf_TaskAgeDays;

-- P3 / P4: restore session settings
SET LANGUAGE us_english;
SET DATEFIRST 7;
```

If you lose track, the shared script is idempotent — re-running `00-create-taskflow-db.sql` rebuilds `TaskFlowDb` from scratch.

## Measuring

```sql
SET STATISTICS IO, TIME ON;
-- Ctrl+M in SSMS, or "Explain" in Azure Data Studio, for the actual plan
SET STATISTICS IO, TIME OFF;
```

On 35 rows the timings are noise. Read the plans for **shape** — Seek vs Scan, `CONVERT_IMPLICIT` on a column, whether the plan went serial because of a scalar UDF — and reason about what happens at 35 million rows.
