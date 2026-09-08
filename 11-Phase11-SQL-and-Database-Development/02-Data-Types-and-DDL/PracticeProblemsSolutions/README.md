# Topic 02 — Practice Solutions

Your answers to the eight exercises in [Practice-Problems.md](../Practice-Problems.md).

## Prerequisite: the shared database

Topic 02 uses the **same** `TaskFlowDb` created in Topic 01. The script lives at
[../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql](../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql).

```bash
sqlcmd -S localhost -U sa -P "<pwd>" -C \
  -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
```

It is idempotent — re-run it any time an exercise leaves the database in a state you do not like.

## Files

| File | Problem | Difficulty |
|---|---|---|
| `P1-type-audit.sql` | P1 — Type Audit of TaskFlowDb | Easy |
| `P2-numeric-precision-lab.sql` | P2 — Numeric Precision Lab | Easy |
| `P3-character-and-storage-math.sql` | P3 — Character Types & Storage Math | Medium |
| `P4-date-and-time.sql` | P4 — Date, Time and the Timezone Contract | Medium |
| `P5-implicit-conversion-sargability.sql` | P5 — Implicit Conversion & SARGability Hunt | Medium |
| `P6-ddl-build-sprints.sql` | P6 — Design and Build `app.Sprints` | Medium |
| `P7-temp-tables-and-table-types.sql` | P7 — Temp Tables, Table Variables, Table Types & `SELECT INTO` | Hard |
| `P8-schema-migration.sql` | P8 — Schema Migration Under Load | Hard |

## Types already in the sample schema

Use these as your reference points — every exercise refers back to them.

| Column | Type | Why |
|---|---|---|
| `ref.TaskStatuses.StatusId` | `TINYINT` | 1 byte; a closed enum of 7 values |
| `ref.Priorities.SlaHours` | `SMALLINT NULL` | 168 fits in 2 bytes; `NULL` means "no SLA" |
| `app.Users.Email` | `NVARCHAR(256)` | Unicode, unique, bounded |
| `app.Users.FullName` | computed `PERSISTED` | Materialised on write so it is indexable |
| `app.Users.CountryCode` | `CHAR(2)` | Genuinely fixed width (ISO 3166-1 alpha-2) |
| `app.Users.HourlyRate` | `DECIMAL(9,2) NULL` | Currency — never `FLOAT`, never `MONEY` |
| `app.Projects.ProjectCode` | `VARCHAR(10)` | Non-Unicode by design — the P5 conversion trap |
| `app.Projects.Budget` | `DECIMAL(12,2) NULL` | Currency up to 10 digits |
| `app.Projects.StartDate` | `DATE` | 3 bytes; no time component to get wrong |
| `app.Labels.ColorHex` | `CHAR(7)` | `'#RRGGBB'`, plus a `CHECK` on the format |
| `app.Tasks.Title` | `NVARCHAR(200)` | Displayed, sorted, searched — bounded on purpose |
| `app.Tasks.Description` | `NVARCHAR(MAX)` | Unbounded prose, never an index key |
| `app.Tasks.StoryPoints` | `TINYINT NULL` | Fibonacci scale never exceeds 255 |
| `app.Tasks.EstimatedHours` | `DECIMAL(6,2) NULL` | Max 9,999.99 hours in 5 bytes |
| `app.Tasks.CreatedAtUtc` | `DATETIME2(3)` | 7 bytes, true millisecond precision, UTC |
| `app.Tasks.MetadataJson` | `NVARCHAR(MAX)` + `ISJSON` `CHECK` | Semi-structured escape hatch |
| `app.TimeEntries.Hours` | `DECIMAL(5,2)` | Capped at 24 by `CK_TimeEntries_Hours` |
| `audit.TaskHistory.TaskHistoryId` | `BIGINT IDENTITY` | Append-only, high volume |
| `audit.TaskHistory.ChangedBy` | `SYSNAME` | Alias for `NVARCHAR(128) NOT NULL` |

## Conventions

- Every script starts with `USE TaskFlowDb;` then `GO`.
- Every object reference is **schema-qualified** and every table gets an alias.
- Every constraint you create is **explicitly named**: `PK_` / `FK_` / `UQ_` / `CK_` / `DF_` / `IX_`.
- Every scratch object is dropped in the **same** script with `DROP ... IF EXISTS`.
- Never modify a seeded table in place — copy it first (`SELECT * INTO app.Tasks_Copy FROM app.Tasks;`) and drop the copy at the end.
- Paste query results and error messages as comment blocks so the file is reviewable without a live server.
- Capture error **numbers** verbatim (`Msg 4901`, `Msg 4936`, `Msg 1919`, `Msg 1087`, `Msg 5074`), not paraphrases.

## Cleanup

```sql
USE TaskFlowDb;
GO

-- Scratch objects the exercises may create.
DROP TABLE    IF EXISTS app.SprintTasks;
DROP TABLE    IF EXISTS app.Sprints;
DROP TABLE    IF EXISTS app.TaskCustomFields;
DROP TABLE    IF EXISTS app.TaskShareLinks;
DROP TABLE    IF EXISTS app.TaskArchive;
DROP TABLE    IF EXISTS app.Tasks_Copy;
DROP TABLE    IF EXISTS app.Tasks_Backup;
DROP TABLE    IF EXISTS app.Projects_Copy;
DROP SEQUENCE IF EXISTS app.SprintNumberSeq;
DROP SEQUENCE IF EXISTS app.TaskNumberSeq;
DROP PROCEDURE IF EXISTS app.usp_GetTasksByIds;
DROP TYPE     IF EXISTS app.TaskIdList;

-- Rows the exercises may leave behind.
DELETE FROM app.Labels WHERE LabelName IN (N'needs-triage', N'needs-info', N'gap-demo',
                                           N'after-gap', N'triage', N'spike', N'temp-label');
GO

-- Or start completely fresh.
--   sqlcmd -S localhost -U sa -P "<pwd>" -C -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
```
