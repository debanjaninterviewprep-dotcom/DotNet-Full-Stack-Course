# Topic 04: Built-In Functions & Expressions — Practice Problems

> Seven exercises covering the string, numeric, date, conversion, `NULL`, logical and system function families — plus the two performance traps that make this topic matter: non-SARGable expressions and scalar UDFs. Everything runs against the shared **TaskFlowDb** sample database.

**Concept tags:** `string-functions` `numeric-functions` `date-functions` `time-zones` `datefirst` `cast-convert` `try-convert` `implicit-conversion` `isnull-coalesce` `nullif` `case` `iif` `choose` `greatest-least` `system-functions` `identity` `determinism` `computed-columns` `scalar-udf` `sargability`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Starter files live in [PracticeProblemsSolutions](./PracticeProblemsSolutions). Each one restates the problem and contains a `-- TODO`. Fill them in; do not rename them.

---

## P1 — The String Toolkit  *(Easy)*

**Tags:** `string-functions` `len-datalength` `charindex` `stuff` `concat` `concat-ws`

The TaskFlow audit export needs an anonymised user roster.

### Requirements

1. Show `LEN` vs `DATALENGTH` for `app.Users.Email`. Explain the exact ratio and why it is what it is. Then show a literal with trailing spaces where the two disagree for a different reason.
2. Split each email into `LocalPart` and `Domain` using `LEFT`, `RIGHT` and `CHARINDEX`.
3. Produce a `MaskedEmail` that keeps the first and last character of the local part and replaces the middle with exactly five asterisks, using `STUFF` and `REPLICATE`.
4. Build an `Initials` column (e.g. `AL` for Ada Lovelace) from `FirstName` and `LastName`.
5. Build a display string for each user in three ways — `+`, `CONCAT`, and `CONCAT_WS` — combining `FullName`, `JobTitle` and `CountryCode`. Run all three, then explain by `UserId` exactly where they differ and why.
6. Use `TRANSLATE` to strip `{`, `}` and `"` from `app.Tasks.MetadataJson`, and write the equivalent nested `REPLACE`. State one thing `TRANSLATE` cannot do that `REPLACE` can.

### Deliverable

`P1-string-toolkit.sql`

### Hints

- `app.Users.Email` is `NVARCHAR(256)`; `app.Users.FullName` is a `PERSISTED` computed column.
- `CHARINDEX` returns `0` when the needle is absent — every email here has an `@`, but note the risk.
- `UserId` 19 (Sophie Wilson) has a `NULL` `JobTitle`. That is the row where `+`, `CONCAT` and `CONCAT_WS` diverge.
- `TRANSLATE` requires both character lists to be the same length.

### Look-fors (rubric)

- [ ] The `DATALENGTH = 2 × LEN` relationship is stated **and** explained (`NVARCHAR` = 2 bytes per character).
- [ ] A separate example shows `LEN` ignoring trailing spaces while `DATALENGTH` counts them.
- [ ] The masking expression produces `a*****e@taskflow.io` for Ada and does not error on the shortest local part in the table.
- [ ] All three concatenation forms present, with `UserId` 19 named as the divergence point.
- [ ] `+` returning `NULL` is correctly attributed to `NULL` propagation, not to a "bug".
- [ ] The `TRANSLATE` limitation is stated correctly (character-to-character only; cannot replace a multi-character substring).

---

## P2 — Numbers That Do Not Lie  *(Easy)*

**Tags:** `numeric-functions` `rounding` `integer-division` `modulo` `nullif` `rand`

### Requirements

1. For each task with a non-`NULL` `EstimatedHours`, show `ROUND` to 0 decimals, `ROUND` with the truncate flag, `CEILING`, `FLOOR` and `ABS`. Explain the difference between `ROUND(x, 0)` and `ROUND(x, 0, 1)`.
2. Show that `ROUND` does **not** change the scale, and give the expression that returns a true `INT`.
3. State how SQL Server's `ROUND(2.5, 0)` differs from .NET's `Math.Round(2.5)`, and why that matters for a report that must reconcile with C#.
4. Compute "percent of tasks complete" per project using `ref.TaskStatuses.IsTerminal`. Write it **wrong first** (integer division) and record the result, then write it correctly. Explain why `100.0 * a / b` works and `a / b * 100.0` does not.
5. Use `%` to bucket `EstimatedHours` into whole working days plus a remainder.
6. Compute `EstimatedHours / StoryPoints` safely so that a zero or `NULL` `StoryPoints` returns `NULL` rather than raising `Msg 8134`.
7. Show that `RAND()` returns the same value for every row of a query, then produce a genuinely random sample of 5 tasks. Explain the mechanism behind your fix.

### Deliverable

`P2-numeric-expressions.sql`

### Hints

- `app.Tasks.EstimatedHours` is `DECIMAL(6,2)`; `StoryPoints` is `TINYINT` and nullable.
- `NULLIF(x, 0)` is the divide-by-zero guard.
- `RAND()` is folded to a single runtime constant; `NEWID()` is evaluated per row.

### Look-fors (rubric)

- [ ] `ROUND(x, 0, 1)` correctly identified as truncation, not rounding.
- [ ] `CAST(ROUND(x, 0) AS INT)` given as the way to actually change the type.
- [ ] Away-from-zero vs banker's rounding stated correctly.
- [ ] Both the wrong and right percentage expressions present with actual results.
- [ ] The promotion explanation is about **operand types at the moment of division**, not about precedence in general.
- [ ] `NULLIF` used for the divide-by-zero guard — not a `CASE WHEN StoryPoints = 0`.
- [ ] The random-sample fix uses `ABS(CHECKSUM(NEWID()))` or equivalent, with the per-row evaluation explained.

---

## P3 — Date Arithmetic Done Right  *(Medium)*

**Tags:** `dateadd` `datediff` `datediff-big` `eomonth` `datepart` `datename` `age`

### Requirements

1. Demonstrate that `DATEDIFF` counts **boundary crossings**, not elapsed units, with three separate one-line proofs (`YEAR`, `MONTH`, `HOUR`).
2. Trigger `Msg 535` with `DATEDIFF(MILLISECOND, …)` over the span from the earliest `app.Tasks.CreatedAtUtc` to now. Record the error verbatim, then fix it with `DATEDIFF_BIG`.
3. Build a table in comments listing the approximate overflow threshold for `SECOND`, `MILLISECOND`, `MICROSECOND` and `NANOSECOND`.
4. Compute, for each project, the number of **whole months** it has been running, correctly — not `DATEDIFF(MONTH, …)`.
5. Compute a correct "age in whole years" for an arbitrary `@Dob` / `@Today` pair. Prove it with a case where the naive `DATEDIFF(YEAR, …)` is off by one.
6. For each task with a due date, show `DATEPART(QUARTER)`, `DATEPART(ISO_WEEK)`, `DATENAME(MONTH)` and `DATENAME(WEEKDAY)`. Then run `SET LANGUAGE French;` and re-run. Explain what changed and what that means for storing or filtering on `DATENAME` output.
7. Show three ways to truncate `CreatedAtUtc` to the first of its month: `DATEFROMPARTS`, the `DATEADD`/`DATEDIFF` anchor idiom, and `DATETRUNC`. Note the version requirement for the third.
8. Use `EOMONTH` to produce, per task, the month end and the previous month end of the due date.

### Deliverable

`P3-date-arithmetic.sql`

### Hints

- The earliest `CreatedAtUtc` in the sample data is in February 2024 — far past the ~24.8-day millisecond limit.
- The correct age idiom is `DATEDIFF(YEAR, dob, today) - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, dob, today), dob) > today THEN 1 ELSE 0 END`.
- `SET LANGUAGE` also changes `@@DATEFIRST` — reset it with `SET LANGUAGE us_english;` when you are done.
- `DATETRUNC` requires SQL Server 2022 or Azure SQL. Guard it or comment it out if your instance is older.

### Look-fors (rubric)

- [ ] All three boundary-crossing proofs present and each returns the counter-intuitive value.
- [ ] `Msg 535` captured verbatim and fixed with `DATEDIFF_BIG`.
- [ ] The overflow threshold table is approximately correct (68 years / 24.8 days / 35.8 minutes / 2.1 seconds).
- [ ] The whole-months and age calculations both use the `DATEADD`-back-and-compare correction.
- [ ] A concrete off-by-one case is demonstrated, not just described.
- [ ] `DATENAME` output changes under `SET LANGUAGE`, and the conclusion is "never persist or filter on it".
- [ ] Session language reset at the end of the script.

---

## P4 — Time Zones and Week Boundaries  *(Medium)*

**Tags:** `at-time-zone` `switchoffset` `todatetimeoffset` `datefirst` `iso-week` `sargability`

A TaskFlow bug report: *"Due dates are one day off for our India team, and the weekly burndown starts on a different day depending on who runs it."*

### Requirements

1. Query `sys.time_zone_info` for `UTC`, `GMT Standard Time` and `India Standard Time`. Record the current offsets and DST flags.
2. Show the **wrong** conversion — a single `AT TIME ZONE 'India Standard Time'` applied directly to `app.Tasks.CreatedAtUtc` — and explain precisely what it did.
3. Show the correct two-step `AT TIME ZONE 'UTC' AT TIME ZONE '<target>'` for both London and India, for at least three tasks.
4. Demonstrate `SWITCHOFFSET` and `TODATETIMEOFFSET` and state, in one sentence each, how they differ from `AT TIME ZONE`.
5. Explain in a comment why `WHERE t.CreatedAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time' >= @local` is a performance bug, and write the SARGable alternative.
6. Show that `DATEPART(WEEKDAY, '2025-08-30')` returns different values under `SET DATEFIRST 1` and `SET DATEFIRST 7`.
7. Write a `DATEFIRST`-independent "start of the Monday week" expression **twice** — once with the 1900-01-01 anchor, once by neutralising `@@DATEFIRST` arithmetically — and prove both agree under at least two different `DATEFIRST` settings.
8. Show `DATEPART(WEEK, …)` vs `DATEPART(ISO_WEEK, …)` for the same date under two `DATEFIRST` settings, and state which one you would put in a report.
9. Reset `DATEFIRST` at the end of the script.

### Deliverable

`P4-timezones-and-weeks.sql`

### Hints

- `AT TIME ZONE` on a value with no offset **attaches**; on a value with an offset it **converts**. That is the whole bug in requirement 2.
- 1900-01-01 was a Monday, which is what makes `DATEDIFF(DAY, '19000101', d) % 7` stable.
- The arithmetic neutraliser is `-((DATEPART(WEEKDAY, d) + @@DATEFIRST - 2) % 7)`.
- `ISO_WEEK` is defined by ISO-8601 and ignores `DATEFIRST` entirely.

### Look-fors (rubric)

- [ ] The single-`AT TIME ZONE` bug is described as "attached an offset without converting", not "converted wrongly".
- [ ] Both London and India conversions are correct and DST-aware.
- [ ] `SWITCHOFFSET` / `TODATETIMEOFFSET` correctly described as **not** DST-aware.
- [ ] The SARGable alternative converts the **parameter**, not the column.
- [ ] Both `DATEFIRST`-independent week-start expressions agree under at least two settings.
- [ ] `ISO_WEEK` recommended over `WEEK`, with a reason.
- [ ] A calendar/dimension table is mentioned at least once as the production-grade answer.
- [ ] `SET DATEFIRST` restored before the script ends.

---

## P5 — NULL Handling and Safe Conversion  *(Medium)*

**Tags:** `isnull` `coalesce` `nullif` `try-convert` `try-parse` `implicit-conversion` `ansi-nulls`

### Requirements

1. Reproduce the `ISNULL` truncation trap: `ISNULL(CAST(NULL AS VARCHAR(2)), 'abcdef')` vs the `COALESCE` equivalent. Explain the return-type rule for each.
2. Show that `SELECT COALESCE(NULL, NULL)` errors while `SELECT ISNULL(NULL, NULL)` does not. Record the error message.
3. Write the `CASE` expansion of `COALESCE(a, b)` and explain the double-evaluation consequence. Give a concrete TaskFlow example where the repeated expression is a scalar subquery.
4. Explain the **nullability** difference and why it matters for a `PERSISTED` computed column.
5. Build a display projection over `ref.Priorities` where a `NULL` `SlaHours` renders as an em dash, and over `app.Users` where a `NULL` `HourlyRate` renders as `Not set`. Get the types right — no implicit-conversion errors.
6. Use `NULLIF` three ways: divide-by-zero protection on `EstimatedHours / StoryPoints`, turning `CHARINDEX`'s `0` into a real `NULL`, and normalising an empty string in `audit.TaskHistory.NewValue` to `NULL`.
7. Use `TRY_CONVERT` to parse `audit.TaskHistory.NewValue` as an `INT`, and explain what `TRY_CAST` still errors on.
8. Demonstrate the implicit-conversion bug: `WHERE p.ProjectCode = N'TF-CORE'` vs `= 'TF-CORE'` on `app.Projects`. State `ProjectCode`'s declared type, which side gets converted and why, and name the fix in ADO.NET, Dapper and EF Core.
9. In a comment, explain what `SET ANSI_NULLS OFF` does, why it is deprecated, and how a legacy stored procedure can behave differently from the same SQL run ad-hoc.

### Deliverable

`P5-null-and-conversion.sql`

### Hints

- `ref.Priorities.SlaHours` is `SMALLINT` and is `NULL` for `PriorityId = 5`.
- `app.Users.HourlyRate` is `DECIMAL(9,2)` and is `NULL` for `UserId` 19.
- `audit.TaskHistory` is empty in a fresh database — insert a couple of rows yourself for requirements 6 and 7, then delete them.
- `ISNULL` result nullability is inferred as `NOT NULL` when the second argument is non-nullable; `COALESCE` generally is not.
- Data type precedence: `NVARCHAR` outranks `VARCHAR`.

### Look-fors (rubric)

- [ ] Truncation reproduced, with the "return type of the **first** argument" rule stated for `ISNULL` and "highest precedence among all arguments" for `COALESCE`.
- [ ] The `COALESCE(NULL, NULL)` error message captured.
- [ ] The `CASE` expansion is written out and the double-evaluation risk tied to a concrete subquery example.
- [ ] Nullability difference correctly linked to `PERSISTED` computed columns / `NOT NULL` constraints.
- [ ] All three `NULLIF` uses present and working.
- [ ] Implicit-conversion explanation names `VARCHAR(10)`, names `NVARCHAR` precedence, and says the **column** is converted.
- [ ] All three application-layer fixes named concretely.
- [ ] Any rows inserted into `audit.TaskHistory` are deleted at the end.

---

## P6 — The SLA Dashboard Expression Engine  *(Hard)*

**Tags:** `case` `iif` `choose` `greatest-least` `concat-ws` `string-agg` `format` `determinism`

Build the single query behind TaskFlow's SLA dashboard.

### Requirements

Produce one row per non-terminal task with these computed columns:

| Column | Definition |
|---|---|
| `TaskRef` | `ProjectCode` + `-` + zero-padded `TaskId` (6 digits) |
| `Headline` | `FullName` of the primary assignee, job title and country, joined so a missing component leaves no orphan separator |
| `SlaDeadlineUtc` | `CreatedAtUtc` plus `ref.Priorities.SlaHours`; `NULL` when there is no SLA |
| `SlaState` | `No SLA` / `Breached` / `At risk` (< 25% of the SLA window left) / `On track` |
| `LastTouchedUtc` | The latest non-`NULL` of `CreatedAtUtc`, `ModifiedAtUtc`, `CompletedAtUtc` |
| `Labels` | Comma-separated `LabelName` list, ordered by `LabelId`; `(none)` when the task has no labels |

Then:

1. Write `SlaState` twice — once with a searched `CASE`, once with nested `IIF`. State which you would ship and why.
2. Write `LastTouchedUtc` twice — once with `GREATEST` (2022+), once with the `CROSS APPLY (VALUES …) + MAX` fallback. Confirm both agree.
3. Add a `PriorityLabel` column using `CHOOSE`, then argue in a comment why `ref.Priorities.PriorityName` is the better source.
4. Demonstrate that a **simple** `CASE` cannot match `NULL`, using `ModifiedAtUtc`.
5. Add a `DueDateDisplay` column with `FORMAT`, then the `CONVERT`-with-style-code equivalent. State the performance and determinism consequences of each.
6. In a comment, list every non-deterministic function used anywhere in your query and state which of them would prevent this query being turned into an indexed view.

### Deliverable

`P6-sla-dashboard.sql`

### Hints

- Primary assignee: `app.TaskAssignments` where `IsPrimary = 1`. Not every task has one — your join must not drop rows.
- `ref.Priorities.SlaHours` is `NULL` for `PriorityCode = 'NONE'`.
- `STRING_AGG` needs `CAST(… AS NVARCHAR(MAX))` on the input or you risk `Msg 9829`, and it needs `WITHIN GROUP (ORDER BY …)` for a deterministic order.
- `CHOOSE` is 1-based and returns `NULL` out of range.
- `app.Tasks.ModifiedAtUtc` is `NULL` for every seeded row — perfect for requirement 4.

### Look-fors (rubric)

- [ ] Every column matches its definition and the query runs with zero errors.
- [ ] `CONCAT_WS` used for `Headline`; no orphan separators for `UserId` 19.
- [ ] Tasks with no primary assignee and tasks with no labels still appear (correct outer join / correlated subquery).
- [ ] `SlaState` written both ways with a stated preference and a real reason (readability, nesting limit, portability).
- [ ] `GREATEST` and the `CROSS APPLY` fallback produce identical output.
- [ ] The simple-`CASE`-cannot-match-`NULL` demonstration is present and correct.
- [ ] `FORMAT` correctly identified as CLR-based, non-deterministic and materially slower than `CONVERT`.
- [ ] The non-determinism inventory is complete and correctly blocks the indexed view.

---

## P7 — Determinism and the Scalar-Function Tax  *(Hard)*

**Tags:** `determinism` `computed-columns` `persisted` `scalar-udf` `inline-tvf` `udf-inlining` `sargability` `execution-plans`

### Requirements

1. Query `COLUMNPROPERTY(OBJECT_ID('app.Users'), 'FullName', 'IsDeterministic')`. Explain why `app.Users.FullName` qualifies for `PERSISTED` and what would happen to the schema if its definition used `FORMAT` instead.
2. Add a **deterministic** persisted computed column `CreatedYear` to `app.Tasks`, index it, and show that `WHERE YEAR(t.CreatedAtUtc) = 2025` — written exactly like that, unchanged — can now use the index. Explain why the optimiser matches the expression.
3. Attempt to add a **non-deterministic** persisted computed column (for example one involving `SYSUTCDATETIME()` or `FORMAT`). Capture the error message verbatim and explain it.
4. Explain the difference between **deterministic** and **precise**, and why a `FLOAT`-based computed column cannot be indexed even when deterministic.
5. Create a scalar UDF `dbo.fn_TaskAgeDays(@CreatedAtUtc)`. Run a query using it and capture the plan and elapsed time. Then rewrite the same query with (a) the expression inline and (b) `CROSS APPLY (VALUES (…))`, and compare.
6. Query `sys.sql_modules.is_inlineable` for your function. State your database's compatibility level (`sys.databases.compatibility_level`) and what it means for scalar UDF inlining.
7. Force the un-inlined behaviour with `OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'))` and compare the plan with the inlined version. Note whether the plan is serial.
8. Convert the scalar UDF into an **inline table-valued function** returning the same value, call it with `CROSS APPLY`, and explain why an iTVF is structurally cheaper than a scalar UDF.
9. Write a comment block listing the four independent reasons scalar UDFs are slow, and the four replacements from the Notes.
10. Drop every object you created. Verify `app.Tasks` has no extra columns or indexes.

### Deliverable

`P7-determinism-and-udfs.sql`

### Hints

- `ALTER TABLE app.Tasks ADD CreatedYear AS (YEAR(CreatedAtUtc)) PERSISTED;` then `CREATE NONCLUSTERED INDEX …`.
- Dropping a computed column that has an index on it requires dropping the index first.
- `SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME();` — inlining needs 150 or higher.
- `sys.sql_modules.is_inlineable` is `NULL` for anything that is not a scalar UDF.
- On 35 rows the timings will be noise. Reason about **plan shape** and about what happens at 35 million rows.

### Look-fors (rubric)

- [ ] The `FullName` determinism result is correct and the `FORMAT` counterfactual is explained (the `PERSISTED` keyword would become illegal).
- [ ] The computed column is created, indexed, and the **unchanged** `YEAR(...)` predicate demonstrably matches it.
- [ ] The non-deterministic computed column error is captured verbatim.
- [ ] Deterministic vs precise correctly distinguished, with the `FLOAT` consequence.
- [ ] Scalar UDF, inline expression and `CROSS APPLY` versions all present with plans compared.
- [ ] `is_inlineable` and `compatibility_level` both queried and interpreted.
- [ ] The `USE HINT` comparison notes the serial-plan consequence.
- [ ] The iTVF version works and the "expanded into the calling plan" explanation is correct.
- [ ] All four slowness reasons and all four replacements listed.
- [ ] Full cleanup: index dropped, computed column dropped, both functions dropped, `app.Tasks` verified unchanged.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files in `PracticeProblemsSolutions/` are filled in — no remaining `-- TODO` markers.
- [ ] Every script runs top-to-bottom against a freshly created `TaskFlowDb` with zero unintended errors.
- [ ] Deliberately triggered errors (`Msg 535`, the `COALESCE(NULL, NULL)` error, the non-deterministic computed column) are **captured as comments**, not left to abort the script.
- [ ] Every script that creates an object (index, column, function, audit rows) drops or deletes it. The shared database is left exactly as found.
- [ ] Every session setting changed (`SET LANGUAGE`, `SET DATEFIRST`) is restored.
- [ ] Every table is schema-qualified and aliased; every column is alias-prefixed.
- [ ] No function is wrapped around a column inside a `WHERE` clause in any shipped query.
- [ ] `PracticeProblemsSolutions/README.md` accurately lists what each file contains.

---

## Stretch Goals

- Build a **calendar dimension table** (`ref.Calendar`) covering 2024–2026 with `DateKey`, `IsoWeek`, `WeekStartMonday`, `MonthStart`, `QuarterStart`, `IsWeekend` and `IsWorkingDay`. Rewrite P4's week logic as a join and explain what that does for SARGability.
- Benchmark `FORMAT` against `CONVERT` over 1,000,000 rows generated from `sys.all_objects` cross-joined to itself. Record the ratio.
- Benchmark the scalar UDF from P7 at compatibility level 140 versus 150 (`ALTER DATABASE … SET COMPATIBILITY_LEVEL`) on a copy of the database. Never do this on the shared one.
- Write a `dbo.fn_MaskEmail` **inline table-valued function** and use it across three different queries with `CROSS APPLY`. Confirm from the plan that the function body was expanded rather than called.
- Investigate `CRYPT_GEN_RANDOM` and explain why `RAND()` and `NEWID()` are both unsuitable for generating a password reset token.
- Read the SQL Server 2025 `REGEXP_LIKE` / `REGEXP_REPLACE` documentation and rewrite P1's masking expression with it. Note what portability you gain and lose.
