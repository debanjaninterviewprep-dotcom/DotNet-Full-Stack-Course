# Topic 02: Data Types & DDL — Practice Problems

> Eight exercises that force you to justify every type you pick and every `ALTER` you write. You will audit the sample schema, reproduce the `MONEY` and `FLOAT` rounding failures, hunt an implicit conversion that silently kills an index seek, design and build a new TaskFlow table from scratch, and rehearse a schema migration the way you would run it against production.

**Concept tags:** `exact-numerics` `approximate-numerics` `decimal-precision-scale` `character-types` `utf8-collations` `date-time-types` `binary-types` `uniqueidentifier` `rowversion` `deprecated-types` `type-precedence` `implicit-conversion` `sargability` `create-table` `schemas` `identity-vs-sequence` `computed-columns` `default-constraints` `sparse-columns` `select-into` `temp-tables` `table-types` `naming-conventions` `alter-column` `online-ddl`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Write each answer in the matching starter file inside `PracticeProblemsSolutions/`. Every object you create must be dropped again in the same script, and every object reference must be schema-qualified.

---

## P1 — Type Audit of TaskFlowDb  *(Easy)*

**Tags:** `catalog-views` `choosing-types` `deprecated-types` `storage-math`

### Requirements

1. Write **one** query returning every column in the `app`, `ref` and `audit` schemas with: schema, table, column, type name, `max_length`, `precision`, `scale`, `is_nullable`, `is_identity`, `is_computed`, and the collation.
2. Produce a **deprecated-type scan** for `TEXT`, `NTEXT` and `IMAGE`. State the result and the modern replacement for each.
3. Compute the **theoretical maximum row width in bytes** for `app.Tasks`, ignoring the `NVARCHAR(MAX)` columns. Show your arithmetic. Then state how many such rows fit in one 8 KB page.
4. For each of these columns, write one line justifying the chosen type — or arguing it is wrong:
   `ref.TaskStatuses.StatusId`, `app.Users.HourlyRate`, `app.Users.CountryCode`, `app.Labels.ColorHex`, `app.Tasks.StoryPoints`, `app.Tasks.CreatedAtUtc`, `app.Projects.StartDate`, `audit.TaskHistory.TaskHistoryId`, `audit.TaskHistory.ChangedBy`.
5. Find every column whose declared length is **more than four times** the longest value actually stored, using the shipped data. Report the wasted declared width.
6. `audit.TaskHistory.ChangedBy` is `SYSNAME`. State what `SYSNAME` actually is and why SQL Server uses it for identifiers.

### Deliverable

`P1-type-audit.sql`.

### Hints

- `sys.columns` joined to `sys.types` on `user_type_id`, or just `TYPE_NAME(c.user_type_id)`.
- `max_length` is in **bytes**, so `NVARCHAR(200)` reports 400 and `MAX` reports -1.
- Row-width arithmetic: `TINYINT` 1, `INT` 4, `BIGINT` 8, `DATE` 3, `DATETIME2(3)` 7, `DECIMAL(6,2)` 5, plus 2 bytes of offset per variable-length column.
- Roughly 8,060 bytes per page are usable for rows.
- For question 5, `MAX(DATALENGTH(col))` gives the real bytes used; `MAX(LEN(col))` gives characters.

### Look-fors (rubric)

- [ ] One set-based catalog query, not one query per table.
- [ ] Correctly explains that `max_length` of `-1` means `MAX`, and that `NVARCHAR` reports double the character count.
- [ ] Row-width arithmetic shown, not asserted, with the per-page figure derived from it.
- [ ] At least one type justification actually **disagrees** with the shipped schema and defends the disagreement.
- [ ] `SYSNAME` correctly identified as an alias for `NVARCHAR(128) NOT NULL`.
- [ ] Deprecated-type scan returns zero rows and the candidate says so explicitly.

---

## P2 — Numeric Precision Lab  *(Easy)*

**Tags:** `decimal-precision-scale` `money` `float` `rounding`

### Requirements

1. Build a table of `TINYINT` / `SMALLINT` / `INT` / `BIGINT` showing range and storage bytes. Verify **two** of the boundaries by attempting an out-of-range insert into a scratch table and capturing the error number.
2. Demonstrate the `MONEY` truncation problem: show a division where `MONEY` loses all precision and `DECIMAL(19,4)` does not. Explain in comments *why*, in terms of intermediate results.
3. Demonstrate that `FLOAT` breaks equality: show an expression where `FLOAT` arithmetic is not equal to the literal it should equal, and the `DECIMAL` equivalent that is.
4. Show the `DECIMAL` storage tiers. Create a scratch table with `DECIMAL(9,2)`, `DECIMAL(19,4)`, `DECIMAL(28,6)` and `DECIMAL(38,10)` columns and confirm the byte cost of each from `sys.columns`.
5. Compute total billable value per project from `app.TimeEntries.Hours` and `app.Users.HourlyRate`. Report the result type of the multiplication and explain how SQL Server derived its precision and scale.
6. Repeat question 5 with both operands cast to `FLOAT` and show that the two results differ. Quantify the difference.
7. `app.Tasks.StoryPoints` is `TINYINT`. Write the query that would fail if a team adopted a scale reaching 300, and state the error.

### Deliverable

`P2-numeric-precision-lab.sql`.

### Hints

- Out-of-range integer insert is `Msg 220` (arithmetic overflow) or `Msg 8115` depending on the path.
- `DECLARE @m MONEY = 0.0001; SELECT @m / 3;`
- Multiplication result scale is `s1 + s2`; precision is `p1 + p2 + 1`, capped at 38.
- `sys.columns.precision`, `.scale` and `.max_length` together tell you the storage tier.
- Join `app.TimeEntries` to `app.Users` on `UserId`, then to `app.Tasks` and `app.Projects`.

### Look-fors (rubric)

- [ ] Both boundary violations reproduced with the actual error number.
- [ ] `MONEY` explanation names **intermediate-result truncation at 4 decimal places**, not just "less precise".
- [ ] `FLOAT` demonstration is a genuine comparison, not a rounded display difference.
- [ ] All four `DECIMAL` storage tiers confirmed from the catalog (5 / 9 / 13 / 17 bytes).
- [ ] Multiplication precision/scale derivation shown, not guessed.
- [ ] The `FLOAT` vs `DECIMAL` billable-value difference is quantified in currency.

---

## P3 — Character Types & Storage Math  *(Medium)*

**Tags:** `char-varchar` `nchar-nvarchar` `utf8-collations` `storage-math` `lob`

### Requirements

1. For `'ada.lovelace@taskflow.io'`, compute the on-page byte cost under `CHAR(256)`, `VARCHAR(256)`, `NCHAR(256)`, `NVARCHAR(256)`, and `VARCHAR(256)` under a `_UTF8` collation. Verify at least three with `DATALENGTH`.
2. Prove `CHAR` padding: insert a short value into a `CHAR(20)` column on a scratch table and show `DATALENGTH` vs `LEN`. Explain why `LEN` and `DATALENGTH` disagree.
3. Create a scratch table with one `VARCHAR(50)` column under the database default collation and one under `Latin1_General_100_CI_AS_SC_UTF8`. Insert an ASCII string and a string containing at least one non-Latin character. Compare `DATALENGTH` for each and explain the results.
4. Explain, with a demonstration, why `app.Labels.ColorHex` is `CHAR(7)` and `app.Users.Email` is `NVARCHAR(256)`. Would `VARCHAR(320)` under a UTF-8 collation be better for `Email`? Argue both ways.
5. Attempt to create a nonclustered index on `app.Comments.Body` (`NVARCHAR(MAX)`). Capture the error number and explain the index key size limits for clustered and nonclustered indexes.
6. Show the practical difference between `LEN`, `DATALENGTH` and `LTRIM(RTRIM())` on a padded `CHAR` value, and state which one you would use to detect over-declared columns.
7. Write the `ALTER TABLE` that would change `app.Projects.ProjectCode` from `VARCHAR(10)` to `NVARCHAR(10)`. Do **not** run it against `app.Projects` — run it against a copy. Explain what it costs and what it breaks.

### Deliverable

`P3-character-and-storage-math.sql`.

### Hints

- `DATALENGTH` returns bytes; `LEN` returns characters and **ignores trailing spaces**.
- The index key size limits are 900 bytes for a clustered index key and 1,700 for a nonclustered index key (SQL Server 2016+).
- The index-creation failure on an `NVARCHAR(MAX)` column is `Msg 1919`.
- Make the copy with `SELECT * INTO app.Projects_Copy FROM app.Projects;` and drop it afterwards.
- A UTF-8 collation makes ASCII cost 1 byte per character but non-Latin characters cost 2–4.

### Look-fors (rubric)

- [ ] All five storage figures computed and at least three verified against the engine.
- [ ] `LEN` vs `DATALENGTH` divergence correctly attributed to trailing-space handling.
- [ ] UTF-8 demonstration shows both the win (ASCII) and the loss (non-Latin).
- [ ] `Msg 1919` reproduced and the 900 / 1,700 byte limits stated correctly.
- [ ] The `VARCHAR(320)` UTF-8 email argument acknowledges the `ALTER` cost and the `NVARCHAR` parameter mismatch risk from P5.
- [ ] `app.Projects` itself is unmodified; the copy is dropped.

---

## P4 — Date, Time and the Timezone Contract  *(Medium)*

**Tags:** `date-time-types` `datetime2` `datetimeoffset` `at-time-zone` `sargability`

### Requirements

1. Build the comparison table for `DATE`, `TIME(7)`, `SMALLDATETIME`, `DATETIME`, `DATETIME2(3)`, `DATETIME2(7)` and `DATETIMEOFFSET(3)`: range, accuracy, storage bytes. Verify the storage bytes from `sys.columns` on a scratch table.
2. Reproduce the `DATETIME` rounding bug: cast `'2025-09-08T23:59:59.999'` to `DATETIME` and to `DATETIME2(3)` and show that one of them changes the **date**. Explain the 3.33 ms rounding rule.
3. Show the `SMALLDATETIME` failure mode: store a value with seconds and show what comes back. State its range limit and why 2079 is a real problem for anything with a retention policy.
4. Write the "tasks completed in June 2024" query **three** ways: with `BETWEEN` and a `'...23:59:59.997'` upper bound, with `YEAR()`/`MONTH()`, and with a half-open range. Rank them for correctness and SARGability, and justify the ranking.
5. Convert `app.Tasks.CompletedAtUtc` to two named time zones using `AT TIME ZONE`, for all completed tasks. Show a row where the local **date** differs from the UTC date.
6. Demonstrate `SWITCHOFFSET` and `TODATETIMEOFFSET`, and explain the difference between them in one line each.
7. Argue in 6–10 lines whether `app.Tasks.DueDate` should become `DATETIMEOFFSET`. Consider a distributed team, "due end of day", and what breaks in the reporting queries.
8. `app.Tasks.CreatedAtUtc` is `DATETIME2(3)`. Show the storage saving versus `DATETIME2(7)` across the whole table, and state whether the extra precision would ever be observable.

### Deliverable

`P4-date-and-time.sql`.

### Hints

- `DATETIME` rounds to increments of .000, .003 and .007 seconds.
- `AT TIME ZONE` needs the value to be zone-aware first: `col AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time'`.
- `SWITCHOFFSET` changes the presented offset of an existing `DATETIMEOFFSET`; `TODATETIMEOFFSET` attaches an offset to a naive `DATETIME2`.
- `SELECT name FROM sys.time_zone_info;` lists every zone the server knows.
- `DATETIME2(3)` is 7 bytes; `DATETIME2(7)` is 8.

### Look-fors (rubric)

- [ ] The date change under `DATETIME` rounding is actually reproduced, not just described.
- [ ] Half-open range ranked first, with SARGability given as the reason alongside correctness.
- [ ] At least one `AT TIME ZONE` row where the local date differs from the UTC date.
- [ ] `SWITCHOFFSET` vs `TODATETIMEOFFSET` distinction is correct.
- [ ] The `DueDate` argument reaches a decision, not a list of considerations.
- [ ] Storage saving computed for the real row count, not asserted.

---

## P5 — Implicit Conversion & SARGability Hunt  *(Medium)*

**Tags:** `type-precedence` `implicit-conversion` `sargability` `execution-plans` `ado-net`

### Requirements

1. Write out the data type precedence order from `sql_variant` down to `binary` as a comment. Verify **three** adjacent pairs with a `SELECT` that shows which type the result takes (use `SQL_VARIANT_PROPERTY(..., 'BaseType')`).
2. Reproduce the `VARCHAR` / `NVARCHAR` trap on `app.Projects.ProjectCode`. Run the query both ways with the actual execution plan on. Find `CONVERT_IMPLICIT` in the plan and state which side of the predicate it is applied to.
3. Do the same for `ref.TaskStatuses.StatusCode` (`VARCHAR(20)`) and explain why the effect is more damaging on a large table than on a 7-row lookup.
4. Show three more non-SARGable patterns against `app.Tasks` and rewrite each SARGably:
   - a function on the column (`YEAR(t.DueDate) = 2025`),
   - arithmetic on the column (`t.EstimatedHours * 2 > 40`),
   - a leading wildcard (`t.Title LIKE N'%pagination%'`).
   For the third, state what you would need in order to make it fast.
5. Show integer division surprising you: `SELECT 5 / 2;` versus `SELECT 5 / 2.0;`. Then find a real TaskFlow ratio where the same mistake would produce a wrong business number, and fix it.
6. Explain how this bug reaches SQL Server from .NET. Write the two lines of EF Core Fluent API configuration and the one `SqlParameter` property that prevent it.
7. Write a catalog query that lists every `VARCHAR` / `CHAR` column in `app` and `ref` — the columns most at risk from an `NVARCHAR` parameter.

### Deliverable

`P5-implicit-conversion-sargability.sql`.

### Hints

- `SELECT SQL_VARIANT_PROPERTY(CAST(1 AS TINYINT) + CAST(1 AS INT), 'BaseType');`
- Turn on the actual plan with `SET STATISTICS XML ON` if you are in `sqlcmd`, or Ctrl+M in SSMS / Azure Data Studio.
- The at-risk columns are `ProjectCode`, `StatusCode`, `PriorityCode`, `CountryCode`, `ColorHex` and `RegulatoryId`-style codes.
- EF Core: `.IsUnicode(false)` or `.HasColumnType("varchar(10)")`. ADO.NET: `SqlDbType.VarChar`.
- A leading wildcard needs full-text search or a trigram/n-gram index — no B-tree can seek it.

### Look-fors (rubric)

- [ ] `CONVERT_IMPLICIT` located in the plan and correctly attributed to the **column** side.
- [ ] Explanation of *why* the column is converted (precedence: `nvarchar` outranks `varchar`), not just that it is.
- [ ] All three non-SARGable rewrites are semantically identical to the originals, including edge cases at range boundaries.
- [ ] The leading-wildcard answer admits a B-tree cannot help and names an alternative.
- [ ] Both the EF Core and the ADO.NET fix are given precisely.
- [ ] The at-risk-column query covers `CHAR` as well as `VARCHAR`.

---

## P6 — Design and Build `app.Sprints`  *(Medium)*

**Tags:** `create-table` `schemas` `defaults` `identity-vs-sequence` `computed-columns` `naming-conventions` `sparse-columns`

### Requirements

TaskFlow is adding sprints. Design and build the schema.

1. Create `app.Sprints` with, at minimum: a surrogate key, a foreign key to `app.Projects`, a name, start and end dates, an optional capacity in hours, a closed flag, and a UTC creation timestamp. Justify **every** type choice in a comment.
2. Every constraint must be **explicitly named** following the `PK_` / `FK_` / `UQ_` / `CK_` / `DF_` convention. Add:
   - a unique constraint preventing two sprints with the same name in the same project,
   - a check constraint that the end date is not before the start date,
   - defaults for the closed flag and the creation timestamp.
3. Add a **`PERSISTED` computed column** `DurationDays`. Then attempt to add a **non-deterministic** computed column (`DaysRemaining` based on `SYSUTCDATETIME()`) as `PERSISTED`, capture the error number, and add the working non-persisted version instead.
4. Create `app.SprintTasks` as a junction table between `app.Sprints` and `app.Tasks` with a composite primary key and appropriate cascade behaviour. Justify the cascade choice.
5. Add an optional `ExternalSprintRef NVARCHAR(64)` as a **`SPARSE`** column. State the break-even `NULL` percentage for that type and whether the choice is justified here.
6. Demonstrate **`IDENTITY` vs `SEQUENCE`**: populate three sprints using `IDENTITY`, then create `app.SprintNumberSeq` and show `NEXT VALUE FOR` producing a number **before** any row exists. State one scenario where only the sequence works.
7. Prove that identity values leak: insert a row inside a transaction, roll it back, insert again, and show the gap. Then run `DBCC CHECKIDENT (..., NORESEED)`.
8. Use `SET IDENTITY_INSERT` to insert a sprint with a specific id, then turn it off. Explain the one-table-per-session rule.
9. Capture generated keys correctly for a **multi-row** insert using `OUTPUT INSERTED.SprintId`. Explain why `SCOPE_IDENTITY()` cannot do this and why `@@IDENTITY` is wrong even for one row.
10. Drop everything you created.

### Deliverable

`P6-ddl-build-sprints.sql`.

### Hints

- The non-deterministic `PERSISTED` failure is `Msg 4936`.
- `DATEDIFF(DAY, StartDate, EndDate) + 1` is deterministic, so it can be persisted.
- Sparse columns cannot be `NOT NULL` and cannot have a `DEFAULT`.
- `sys.sequences` exposes `current_value`, `increment` and `cache_size`.
- Only **one** table per session may have `IDENTITY_INSERT` set to `ON`.
- Drop child tables before parents, and drop `DEFAULT` constraints before their columns.

### Look-fors (rubric)

- [ ] Every constraint explicitly named; no auto-generated `DF__` names anywhere.
- [ ] Type justifications reference storage bytes or domain, not preference.
- [ ] `Msg 4936` reproduced, and the determinism requirement explained correctly.
- [ ] Cascade choice on `app.SprintTasks` is argued, including what happens to history.
- [ ] The `SEQUENCE`-only scenario is real (reserving a number before the row exists, or sharing one number space across tables).
- [ ] The identity gap is actually demonstrated with a rollback, not asserted.
- [ ] `OUTPUT INSERTED` used for the multi-row case, with the `@@IDENTITY` trigger hazard named.
- [ ] Script is fully idempotent and leaves `TaskFlowDb` exactly as it found it.

---

## P7 — Temp Tables, Table Variables, Table Types and `SELECT INTO`  *(Hard)*

**Tags:** `temp-tables` `table-variables` `table-types` `tvp` `select-into` `statistics`

### Requirements

1. Build the same overdue-task result set **four** ways: a `#temp` table, a `##global` temp table, a `@table` variable, and a CTE. For each, record: where it lives, its scope, whether it has statistics, and whether `ROLLBACK` undoes it.
2. Prove the **scope** differences:
   - a `#temp` table survives `GO` but not a new session,
   - a `@table` variable does **not** survive `GO` (capture the message number),
   - a `##global` temp table is visible from a second connection.
3. Prove that a `@table` variable is **not** rolled back: insert into both a `#temp` and a `@table` inside an explicit transaction, roll back, and show the row counts.
4. Show the **statistics** difference. Load ~35 rows into a `#temp` and a `@table`, join each to `app.Tasks`, and compare the estimated versus actual row counts in the plans. Explain the one-row estimate.
5. Add a clustered index to the `#temp` table **after** creation, then show that the equivalent must be declared **inline** for a table variable. Write both.
6. Create `app.TaskIdList` as a table type, write a procedure that takes it as a `READONLY` TVP, and call it with three task ids. Explain why TVPs are always read-only and what that means for a .NET caller.
7. Contrast `SELECT INTO` and `INSERT INTO ... SELECT`:
   - use `SELECT INTO` to snapshot `app.Tasks`, then query `sys.columns` to show which constraints, defaults and indexes did **not** come along,
   - build the same snapshot with an explicit `CREATE TABLE` plus `INSERT INTO ... SELECT`,
   - show that `SELECT INTO` **infers** the type of an expression column, and find one inference you would not have chosen.
8. State which of the four structures you would use for: 20 rows, 20,000 rows, passing a set from .NET, and data that must survive a `ROLLBACK`. Justify each.
9. Drop everything.

### Deliverable

`P7-temp-tables-and-table-types.sql`.

### Hints

- The table-variable-after-`GO` failure is `Msg 1087` (must declare the table variable).
- `tempdb.sys.columns` with `OBJECT_ID(N'tempdb..#YourTable')` inspects a temp table's inferred types.
- Table variables get a one-row estimate before SQL Server 2019; 2019+ deferred compilation improves it but still has no statistics.
- Inline index syntax: `INDEX IX_Name NONCLUSTERED (Col)` inside the `DECLARE @t TABLE (...)`.
- A `##global` temp table needs a second connection to demonstrate — open a second query window.

### Look-fors (rubric)

- [ ] All four structures actually built and compared on the recorded axes.
- [ ] `Msg 1087` reproduced for the table variable across `GO`.
- [ ] Rollback asymmetry demonstrated with real row counts.
- [ ] Estimated-versus-actual divergence captured from a plan, with the one-row estimate explained.
- [ ] The `SELECT INTO` inference the candidate "would not have chosen" is identified with the type it produced.
- [ ] Explicitly notes that `SELECT INTO` copies nullability and `IDENTITY` but not constraints, defaults or indexes.
- [ ] The four recommendations in question 8 differ from one another and each has a reason.

---

## P8 — Schema Migration Under Load  *(Hard)*

**Tags:** `alter-column` `online-ddl` `expand-migrate-contract` `locking` `rollback` `safety-checklist`

### Requirements

You are migrating `app.Tasks.DueDate` from `DATE` to a UTC instant, on a table that in production holds 40 million rows and is written to continuously.

1. Classify each of the following as **metadata-only** or **full rewrite**, and verify at least four against a copy of `app.Tasks`:
   - `NVARCHAR(200)` -> `NVARCHAR(400)`
   - `NVARCHAR(400)` -> `NVARCHAR(200)`
   - `NVARCHAR(200)` -> `NVARCHAR(MAX)`
   - `INT` -> `BIGINT`
   - `VARCHAR(10)` -> `NVARCHAR(10)`
   - `NULL` -> `NOT NULL`
   - `NOT NULL` -> `NULL`
   - add a nullable column
   - add a `NOT NULL` column with a `DEFAULT`
   - drop a column
2. Prove the **nullability trap**: on a copy, run `ALTER COLUMN` on a `NOT NULL` column without restating `NOT NULL`, then show from `sys.columns` that it became nullable. State the SET option responsible.
3. Reproduce `Msg 4901` by adding a `NOT NULL` column with no `DEFAULT` to a non-empty copy. Then do it correctly.
4. Show that a column cannot be dropped while its `DEFAULT` constraint exists, capture the error, and write the correct two-statement sequence.
5. Show that a column cannot be altered while an index references it. Create an index on a copy, attempt the alter, capture the error number, and write the drop-alter-recreate sequence.
6. Write the full **expand / migrate / contract** migration for `DueDate` -> `DueAtUtc DATETIME2(3)`, on a copy of `app.Tasks`:
   - Deploy 1: add the nullable column.
   - Deploy 2: backfill in batches of 1,000 with a bounded loop, reporting `@@ROWCOUNT` each pass. Explain why batching matters for the transaction log and for lock escalation.
   - Deploy 3: the contract step, plus exactly what must be true about the application before you run it.
   Write the **rollback script** for each deploy.
7. Explain what `WITH (ONLINE = ON)` does and does not do, which editions support it for `ALTER COLUMN`, and why you would still set `LOCK_TIMEOUT`.
8. Write a query that finds every **untrusted** foreign key and check constraint in the database, and explain what the optimizer stops doing when a constraint is untrusted.
9. Produce your own **schema-change safety checklist** as a comment block — at least 10 items — and mark which ones this specific migration would have failed without.
10. Drop the copy and confirm `app.Tasks` is untouched.

### Deliverable

`P8-schema-migration.sql`.

### Hints

- Make the copy with `SELECT * INTO app.Tasks_Copy FROM app.Tasks;` — note that this deliberately does not bring the constraints, which is convenient here and a lesson in itself.
- `Msg 4901` is the missing-`DEFAULT` error; `Msg 5074` is the "object is dependent on column" error for indexes and constraints.
- `ANSI_NULL_DFLT_ON` governs the nullability fallback in `ALTER COLUMN`.
- Batch loop shape: `WHILE 1 = 1 BEGIN UPDATE TOP (1000) ... ; IF @@ROWCOUNT = 0 BREAK; END`.
- Untrusted constraints: `sys.foreign_keys.is_not_trusted` and `sys.check_constraints.is_not_trusted`.
- `ONLINE = ON` still takes a brief `Sch-M` lock at the end of the operation.

### Look-fors (rubric)

- [ ] All ten classifications correct, with at least four verified empirically rather than asserted.
- [ ] Nullability trap reproduced and `ANSI_NULL_DFLT_ON` named.
- [ ] `Msg 4901` and the index-dependency error both reproduced with numbers.
- [ ] The batched backfill has a real exit condition and explains log growth **and** lock escalation (the ~5,000-lock threshold).
- [ ] Contract step names the application precondition explicitly (no code reads or writes the old column).
- [ ] A rollback script exists for every deploy, and each is genuinely reversible.
- [ ] `ONLINE = ON` limitations stated accurately, including the brief `Sch-M` lock and edition availability.
- [ ] Checklist has 10+ items and the candidate identifies which ones this migration would have tripped.
- [ ] `app.Tasks` is provably unmodified at the end.

---

## Submission Checklist

- [ ] All eight `.sql` files exist in `PracticeProblemsSolutions/` and each replaces its `-- TODO` marker.
- [ ] Every script begins with `USE TaskFlowDb;` and `GO`.
- [ ] Every object reference is schema-qualified and every table has an alias.
- [ ] Every scratch table, type, sequence and procedure you created is dropped in the same script.
- [ ] `app.Tasks`, `app.Projects`, `app.Users` and `app.Labels` are byte-for-byte as seeded when you finish.
- [ ] No auto-generated constraint names anywhere in your DDL.
- [ ] Every type choice you made is justified in a comment, in terms of domain or storage.
- [ ] Error numbers are captured verbatim, not paraphrased.
- [ ] Re-running `00-create-taskflow-db.sql` still produces the expected row counts.

---

## Stretch Goals

- Convert `TaskFlowDb` to a UTF-8 collation on a **copy** and measure the storage change for `app.Users`, `app.Tasks` and `app.Comments`. Report the win and everything that broke.
- Add a `ROWVERSION` column to a copy of `app.Tasks` and implement optimistic concurrency end to end: read, modify from a second session, and show the first update affecting zero rows.
- Rebuild `app.Sprints` from P6 in **PostgreSQL** and in **MySQL 8**. Produce a three-column type-mapping table and note every construct with no direct equivalent.
- Script `app.Tasks` with a `UNIQUEIDENTIFIER DEFAULT NEWID()` clustered primary key, insert 100,000 rows, and measure fragmentation with `sys.dm_db_index_physical_stats`. Repeat with `NEWSEQUENTIALID()` and with an `INT IDENTITY`. Chart the three.
- Implement the P8 migration as an **EF Core migration** and compare the generated SQL to what you wrote by hand. Identify at least two things EF Core does that you would not ship as-is.
