# Topic 04: Built-in Functions & Expressions

> **TaskFlow** does not just store rows, it *presents* them: initials for an avatar, a due date rendered in the user's timezone, an SLA breach computed from `ref.Priorities.SlaHours`, a masked email in an audit export, a `NULL` hourly rate that must display as `—` and not crash the report. All of that is built-in functions. This topic is where SQL stops being a query language and becomes an expression language — and where two of the most expensive mistakes in the entire phase live: wrapping a column in a function, and shipping a scalar UDF.

---

## 1. The Function Landscape

| Category | Returns | Evaluated per | Examples | Covered in |
|---|---|---|---|---|
| **Scalar** | One value | Row | `LEN`, `DATEADD`, `ISNULL`, `CAST`, `CASE` | **This topic** |
| **Aggregate** | One value | Group | `COUNT`, `SUM`, `AVG`, `STRING_AGG` | Topic 05 |
| **Window / analytic** | One value per row over a frame | Row | `ROW_NUMBER`, `LAG`, `SUM() OVER (…)` | Topic 09 |
| **Rowset / table-valued** | A table | Query | `STRING_SPLIT`, `OPENJSON`, `OPENROWSET` | This topic + 18 |
| **System / metadata** | Server or session state | Statement | `@@ROWCOUNT`, `DB_NAME()`, `SUSER_SNAME()` | **This topic** |

Two structural facts to carry through the whole topic: **scalar functions run once per row**, and **a scalar function wrapped around a column in `WHERE` destroys the index seek** (the SARGability rule from Topic 03).

---

## 2. Strings: Length, Trimming, Extraction and Search

| Function | Returns | Notes |
|---|---|---|
| `LEN(s)` | Character count | **Ignores trailing spaces** |
| `DATALENGTH(s)` | **Byte** count | Counts everything; `NVARCHAR` = 2 bytes/char |
| `LTRIM` / `RTRIM` / `TRIM` | String | `TRIM` is 2017+; `TRIM(chars FROM s)` is 2022+ |
| `LEFT(s, n)` / `RIGHT(s, n)` | Slice from an end | |
| `SUBSTRING(s, start, len)` | Slice | **1-based** start |
| `CHARINDEX(needle, hay [, start])` | 1-based position | Returns **0** if not found |
| `PATINDEX('%pattern%', hay)` | 1-based position | Takes a `LIKE` pattern; **0** if not found |

```sql
SELECT LEN('abc   ')         AS LenIgnoresTrailing,   -- 3
       DATALENGTH('abc   ')  AS BytesVarchar,         -- 6
       DATALENGTH(N'abc   ') AS BytesNvarchar,        -- 12
       LEN('   abc')         AS LenCountsLeading;     -- 6

-- Split an email; find the first digit in a title
SELECT u.Email,
       LEFT(u.Email, CHARINDEX(N'@', u.Email) - 1)             AS LocalPart,
       RIGHT(u.Email, LEN(u.Email) - CHARINDEX(N'@', u.Email)) AS Domain,
       DATALENGTH(u.Email) / LEN(u.Email)                      AS BytesPerChar   -- 2
FROM   app.Users AS u;

SELECT t.TaskId, t.Title, PATINDEX(N'%[0-9]%', t.Title) AS FirstDigitPos
FROM   app.Tasks AS t WHERE PATINDEX(N'%[0-9]%', t.Title) > 0;
```

> **Rule of thumb:** `LEN` for "what the user sees". `DATALENGTH` for "will this fit / how much storage" — and whenever you are hunting a whitespace bug, because it is the only one that can see trailing spaces. It is also how you size `app.Tasks.MetadataJson`.

> **Anti-pattern:** `SUBSTRING(s, CHARINDEX('@', s) + 1, LEN(s))` when `@` may be absent. `CHARINDEX` returns `0`, the start becomes `1`, and you silently get the whole string instead of `NULL`. Guard with `NULLIF(CHARINDEX(…), 0)` — Section 17.

---

## 3. Strings: Building, Replacing and Case Folding

| Function | Purpose |
|---|---|
| `REPLACE(input, find, replaceWith)` | Replace every occurrence of a substring |
| `REPLICATE(s, n)` | Repeat a string `n` times |
| `STUFF(s, start, length, insert)` | Delete `length` chars at `start`, insert new text |
| `REVERSE(s)` | Reverse the character order |
| `TRANSLATE(s, chars, replacements)` | Per-character mapping (2017+) |
| `UPPER(s)` / `LOWER(s)` | Case folding (collation-driven) |

```sql
-- Mask an email for an audit export: keep the first and last character of the local part
SELECT u.Email, STUFF(u.Email, 2, CHARINDEX(N'@', u.Email) - 3, REPLICATE(N'*', 5)) AS MaskedEmail
FROM   app.Users AS u;
-- ada.lovelace@taskflow.io  ->  a*****e@taskflow.io

-- These are equivalent; TRANSLATE does N single-character swaps in one call
SELECT REPLACE(REPLACE(REPLACE(t.MetadataJson, N'{', N' '), N'}', N' '), N'"', N' ') AS ViaReplace,
       TRANSLATE(t.MetadataJson, N'{}"', N'   ')                                     AS ViaTranslate
FROM   app.Tasks AS t WHERE t.MetadataJson IS NOT NULL;
```

`TRANSLATE` requires the two character lists to be the same length and maps **character to character** — it cannot replace a multi-character substring. `REPLACE` can, but only one pair per call.

Two collation traps: `REPLACE` is **collation-sensitive**, so under the usual `_CI_` collation `REPLACE(N'Bug Fix', N'bug', N'defect')` returns `defect Fix`; and `UPPER`/`LOWER` are collation-driven too — Turkish collations map `i` to `İ`, not `I`. Never use case folding as a security or equality mechanism.

---

## 4. Concatenation and `NULL`: `+` vs `CONCAT` vs `CONCAT_WS`

This is the single most common `NULL` bug in reporting SQL.

| | `NULL` behaviour | Type coercion | Min args |
|---|---|---|---|
| `+` | **Propagates** — one `NULL` makes the whole result `NULL` | None; you must `CAST` numbers | 2 |
| `CONCAT` | Treats `NULL` as `''` | Implicit for every argument | 2 (max 254) |
| `CONCAT_WS` | **Skips** `NULL` args — no doubled separator (2017+) | Implicit | 3 |

```sql
SELECT u.UserId,
       u.FirstName + N' ' + u.JobTitle                          AS WithPlus,      -- NULL
       CONCAT(u.FirstName, N' ', u.JobTitle)                    AS WithConcat,    -- 'Sophie '
       CONCAT_WS(N' — ', u.FullName, u.JobTitle, u.CountryCode) AS WithConcatWs,
       N'Task ' + CAST(u.UserId AS NVARCHAR(10))                AS PlusNeedsCast,
       CONCAT(N'Task ', u.UserId)                               AS ConcatDoesNot
FROM   app.Users AS u WHERE u.UserId IN (4, 19);
-- UserId 19 (Sophie Wilson) has a NULL JobTitle. That is the divergence row.
```

`CONCAT_WS` is right for label and address output because it leaves no orphan separator: `CONCAT_WS(', ', 'Ada Lovelace', NULL, 'GB')` is `'Ada Lovelace, GB'`, while the `+` equivalent is `NULL`.

> **Rule of thumb:** Use `CONCAT`/`CONCAT_WS` when a missing component should be skipped. Use `+` when a missing component means the whole value is meaningless — the `NULL` propagation is then a *feature* that stops you shipping a string with a hole in it.

`app.Users.FullName` is `FirstName + N' ' + LastName` deliberately: both columns are `NOT NULL` and `+` is deterministic, which is what makes the column `PERSISTED` and indexable (Section 21).

---

## 5. Splitting and Aggregating Strings

```sql
-- The API receives ?codes=TF-CORE,TF-WEB,TF-SEC
DECLARE @Codes VARCHAR(200) = 'TF-CORE,TF-WEB,TF-SEC';

SELECT p.ProjectId, p.ProjectCode, p.ProjectName
FROM   app.Projects AS p
JOIN   STRING_SPLIT(@Codes, ',') AS s ON s.value = p.ProjectCode;

-- Ordinal requires SQL Server 2022 / Azure SQL
SELECT s.ordinal, s.value FROM STRING_SPLIT(@Codes, ',', 1) AS s ORDER BY s.ordinal;
```

`STRING_SPLIT` takes a **single-character** separator, always outputs a column named `value`, and does not guarantee order without `enable_ordinal`.

> **Anti-pattern:** Passing a comma-separated list from the application at all. A **table-valued parameter** or `OPENJSON` gives typed values, real cardinality estimates and no parsing. `STRING_SPLIT` is the pragmatic fallback, not the design goal.

```sql
-- STRING_AGG (2017+) is the inverse
SELECT t.ProjectId,
       STRING_AGG(CAST(t.Title AS NVARCHAR(MAX)), N'; ') WITHIN GROUP (ORDER BY t.TaskId) AS TaskTitles
FROM   app.Tasks AS t GROUP BY t.ProjectId;
```

Note `CAST(… AS NVARCHAR(MAX))` on the **input**. Without it the result type is derived from `NVARCHAR(200)`, the aggregate is capped at 8000 bytes, and you get `Msg 9829`. Casting the result is too late. Always supply `WITHIN GROUP (ORDER BY …)` — without it the concatenation order is undefined, which makes the output non-deterministic and uncacheable.

---

## 6. `FORMAT` — Convenient and Slow

```sql
SELECT FORMAT(t.DueDate, 'dd MMM yyyy', 'en-GB')  AS UkDate,     -- 30 Aug 2025
       FORMAT(t.DueDate, 'dd MMMM yyyy', 'de-DE') AS GermanDate,
       FORMAT(t.TaskId, 'D6')                     AS PaddedId,   -- 000005
       CONVERT(CHAR(10), t.DueDate, 120)          AS Iso,        -- 2025-08-30, ~1/40th the cost
       CONVERT(CHAR(10), t.DueDate, 103)          AS British     -- 30/08/2025
FROM   app.Tasks AS t WHERE t.TaskId = 5;
```

`FORMAT` is routinely **30–50x slower than `CONVERT`** for three reasons: it is implemented in the **CLR**, so every row crosses the SQLCLR boundary; it is **non-deterministic** (culture-dependent), so it cannot appear in a persisted computed column or an indexed view; and it forces **row-by-row** evaluation, blocking batch mode.

> **Rule of thumb:** Format in the presentation layer, not in SQL. If you must format in SQL, use `CONVERT` with a style code. Reserve `FORMAT` for one-off, low-row-count, genuinely culture-sensitive output.

---

## 7. Numeric Functions and the Integer Division Gotcha

| Function | Notes |
|---|---|
| `ROUND(n, length [, function])` | A non-zero third argument **truncates** instead of rounding |
| `CEILING(n)` / `FLOOR(n)` | Nearest integer up / down; returns the input's type |
| `ABS(n)` / `SIGN(n)` | Absolute value / `-1`, `0`, `1` |
| `POWER(base, exp)` / `SQRT(n)` | `SQRT` returns `FLOAT` |
| `LOG(n [, base])` / `LOG10` / `EXP` / `PI()` | Natural log by default |
| `a % b` | Modulo; integer, money and decimal types |

```sql
SELECT t.TaskId, t.EstimatedHours,
       ROUND(t.EstimatedHours, 0)    AS Rounded,     -- 12.50 -> 13.00
       ROUND(t.EstimatedHours, 0, 1) AS Truncated,   -- 12.50 -> 12.00
       CEILING(t.EstimatedHours)     AS Ceil,
       FLOOR(t.EstimatedHours)       AS Flr,
       t.EstimatedHours % 8          AS RemainderOfADay
FROM   app.Tasks AS t WHERE t.EstimatedHours IS NOT NULL;
```

Two surprises for .NET developers: **`ROUND` rounds half away from zero** (`ROUND(2.5, 0)` is `3`; .NET's `Math.Round(2.5)` is `2`), and **`ROUND` does not change the scale** (`ROUND(12.50, 0)` returns `13.00` — use `CAST(ROUND(x, 0) AS INT)` for a real integer).

### Integer division

`/` between two integers truncates toward zero, with no warning. In TaskFlow this shows up as "every project is 0% complete":

```sql
SELECT t.ProjectId, COUNT(*) AS TotalTasks,
       SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100   AS PctWrong,  -- 0
       100.0 * SUM(CASE WHEN s.IsTerminal = 1 THEN 1 ELSE 0 END) / COUNT(*) AS PctRight
FROM   app.Tasks AS t JOIN ref.TaskStatuses AS s ON s.StatusId = t.StatusId
GROUP  BY t.ProjectId;
```

> **Rule of thumb:** Put the decimal literal **first**. `100.0 * a / b` promotes the expression before the division; `a / b * 100.0` promotes after the damage is done.

### `RAND` is not per-row

`SELECT t.TaskId, RAND() FROM app.Tasks AS t` returns the *same* value on every row — `RAND()` is folded to a single runtime constant per query. For per-row randomness use `ORDER BY ABS(CHECKSUM(NEWID()))`, because `NEWID()` *is* evaluated per row. `RAND(seed)` is deterministic; neither is cryptographically secure — use `CRYPT_GEN_RANDOM` for that.

---

## 8. Date & Time: Getting "Now"

| Function | Return type | Clock | Precision |
|---|---|---|---|
| `GETDATE()` / `GETUTCDATE()` | `DATETIME` | Server local / **UTC** | ~3.33 ms |
| `SYSDATETIME()` / `SYSUTCDATETIME()` | `DATETIME2(7)` | Server local / **UTC** | OS clock (~1 ms) |
| `SYSDATETIMEOFFSET()` | `DATETIMEOFFSET(7)` | Local **+ offset** | OS clock |
| `CURRENT_TIMESTAMP` | `DATETIME` | Server local | ANSI synonym for `GETDATE()` |

Declared precision is not accuracy: `DATETIME2(7)` can *represent* 100 ns, but the value comes from the OS clock, which ticks roughly every millisecond. Never use `SYSDATETIME()` as a uniqueness generator.

> **Rule of thumb:** Store UTC, convert at the edge. Every timestamp column in the sample schema — `app.Tasks.CreatedAtUtc`, `CompletedAtUtc`, `app.Comments.PostedAtUtc`, `audit.TaskHistory.ChangedAtUtc` — is `DATETIME2(3)` in UTC, defaulted with `SYSUTCDATETIME()`. `GETDATE()` on a server whose timezone changes (a regional failover, a DST shift) silently corrupts data that is already written.

---

## 9. `DATEADD`, `DATEDIFF` and the Overflow Trap

```sql
SELECT t.DueDate,
       DATEADD(DAY,   -7, t.DueDate) AS OneWeekBefore,
       DATEADD(MONTH,  1, t.DueDate) AS OneMonthAfter
FROM   app.Tasks AS t WHERE t.DueDate IS NOT NULL;
```

`DATEADD` clamps overflowing month-ends — `DATEADD(MONTH, 1, '2025-01-31')` is `2025-02-28`, not an error — which also makes it **not reversible**.

### `DATEDIFF` counts boundary crossings, not elapsed units

```sql
SELECT DATEDIFF(YEAR,  '2024-12-31', '2025-01-01')             AS YearsApart,  -- 1 (one DAY apart)
       DATEDIFF(MONTH, '2025-01-31', '2025-02-01')             AS MonthsApart, -- 1
       DATEDIFF(HOUR,  '2025-01-01T09:59', '2025-01-01T10:00') AS HoursApart;  -- 1
```

`DATEDIFF(YEAR, a, b)` answers "how many 1 January boundaries lie between these instants", not "how many full years elapsed". Section 13 shows the correction.

### Overflow: `DATEDIFF` returns `INT`

| `datepart` | Overflows after roughly |
|---|---|
| `SECOND` | 68 years |
| `MILLISECOND` | 24.8 days |
| `MICROSECOND` | 35.8 minutes |
| `NANOSECOND` | 2.1 seconds |

```sql
-- Msg 535: The datediff function resulted in an overflow.
SELECT DATEDIFF(MILLISECOND, '2024-02-05T09:00:00', SYSUTCDATETIME());

-- DATEDIFF_BIG (2016+) returns BIGINT
SELECT DATEDIFF_BIG(MILLISECOND, '2024-02-05T09:00:00', SYSUTCDATETIME()) AS MsSinceFirstTask;
```

> **Rule of thumb:** Any `DATEDIFF` finer than `SECOND` over more than a few minutes must be `DATEDIFF_BIG`. This is the classic "worked in dev, blew up in prod after six months of data" bug.

---

## 10. Extracting and Constructing Dates

| Function | Returns | Notes |
|---|---|---|
| `DATEPART(part, d)` | `INT` | `YEAR`, `QUARTER`, `MONTH`, `DAYOFYEAR`, `DAY`, `WEEK`, `ISO_WEEK`, `WEEKDAY`, `HOUR`, … |
| `DATENAME(part, d)` | `NVARCHAR` | **Language-dependent** — respects `SET LANGUAGE` |
| `YEAR` / `MONTH` / `DAY` | `INT` | Shorthand for `DATEPART` |
| `EOMONTH(d [, n])` | `DATE` | End of month, optionally `n` months away |
| `DATEFROMPARTS(y, m, d)` | `DATE` | Errors on invalid dates |
| `DATETIME2FROMPARTS(…)` | `DATETIME2` | Also `TIMEFROMPARTS`, `DATETIMEOFFSETFROMPARTS` |

```sql
SELECT t.DueDate,
       DATEPART(QUARTER,  t.DueDate) AS Qtr,
       DATEPART(ISO_WEEK, t.DueDate) AS IsoWeek,
       DATENAME(MONTH,    t.DueDate) AS MonthName,     -- 'August' under us_english
       EOMONTH(t.DueDate)            AS MonthEnd,
       EOMONTH(t.DueDate, -1)        AS PriorMonthEnd
FROM   app.Tasks AS t WHERE t.DueDate IS NOT NULL;
```

`DATENAME` output changes with the session language. Never persist it, never compare against it, never let it into a `WHERE` clause. Use `DATEPART` (an `INT`) for logic and translate in the UI.

```sql
-- Truncating to a day or a month
SELECT CAST(t.CreatedAtUtc AS DATE)                                            AS DayStart,
       DATEFROMPARTS(YEAR(t.CreatedAtUtc), MONTH(t.CreatedAtUtc), 1)           AS MonthStart,
       DATEADD(MONTH, DATEDIFF(MONTH, '19000101', t.CreatedAtUtc), '19000101') AS MonthStartClassic
FROM   app.Tasks AS t WHERE t.TaskId = 5;

SELECT DATETRUNC(MONTH, t.CreatedAtUtc) AS MonthStart   -- SQL Server 2022 / Azure SQL only
FROM   app.Tasks AS t WHERE t.TaskId = 5;
```

The `DATEADD(… DATEDIFF(… '19000101' …))` idiom is the portable-across-versions classic and works for any part. All of these are **non-SARGable** applied to a column in `WHERE` — filter with a half-open range and use these only for grouping and display.

---

## 11. Time Zones: `AT TIME ZONE`, `SWITCHOFFSET`, `TODATETIMEOFFSET`

| Construct | What it does | DST-aware |
|---|---|---|
| `d AT TIME ZONE 'X'` | If `d` has no offset: **attach** zone `X`. If it has one: **convert** to `X`. | Yes |
| `SWITCHOFFSET(dto, '+05:30')` | Same instant, re-expressed at a fixed offset | No |
| `TODATETIMEOFFSET(dt, '-05:00')` | **Assert** a naive value was in that offset; no conversion | No |

```sql
-- The canonical two-step: attach UTC, then convert.
SELECT t.CreatedAtUtc                                                       AS RawUtc,
       t.CreatedAtUtc AT TIME ZONE 'UTC'                                    AS AsUtcOffset,
       t.CreatedAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time'   AS LondonTime,
       t.CreatedAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time' AS IndiaTime
FROM   app.Tasks AS t WHERE t.TaskId = 5;

SELECT tzi.name, tzi.current_utc_offset, tzi.is_currently_dst
FROM   sys.time_zone_info AS tzi
WHERE  tzi.name IN ('UTC', 'GMT Standard Time', 'India Standard Time');
```

The single `AT TIME ZONE` is the classic bug: `t.CreatedAtUtc AT TIME ZONE 'India Standard Time'` does **not** convert — it *asserts* the stored value was already IST and attaches `+05:30`. You must attach `'UTC'` first. Zone names come from `sys.time_zone_info` (Windows names, on both Windows and Linux).

> **Anti-pattern:** Storing local times, or storing an offset instead of a zone. `+01:00` does not tell you whether that was London in summer or Berlin in winter, and it cannot survive a DST rule change. Store UTC plus a zone **name**.

`AT TIME ZONE` in a `WHERE` clause is non-SARGable. Convert the *parameter* to UTC in the application, then filter on the raw UTC column.

---

## 12. Week Boundaries and `SET DATEFIRST`

`DATEPART(WEEKDAY, d)` and `DATEPART(WEEK, d)` depend on the session's `DATEFIRST`, which defaults from the session `LANGUAGE` (`us_english` gives 7, British gives 1). That makes them **non-deterministic across sessions** — a report can return different numbers for two users.

```sql
SELECT @@DATEFIRST AS CurrentSetting;

SET DATEFIRST 1;  SELECT DATEPART(WEEKDAY, '2025-08-30') AS SaturdayIs6;   -- 6
SET DATEFIRST 7;  SELECT DATEPART(WEEKDAY, '2025-08-30') AS SaturdayIs7;   -- 7
```

Two `DATEFIRST`-independent ways to get the start of the Monday week:

```sql
-- A. Anchor on 1900-01-01, which was a Monday
SELECT DATEADD(DAY, -(DATEDIFF(DAY, '19000101', t.DueDate) % 7), t.DueDate) AS WeekStartMonday
FROM   app.Tasks AS t WHERE t.DueDate IS NOT NULL;

-- B. Neutralise @@DATEFIRST arithmetically (works with any setting)
SELECT DATEADD(DAY, -((DATEPART(WEEKDAY, t.DueDate) + @@DATEFIRST - 2) % 7), t.DueDate) AS WeekStartMonday
FROM   app.Tasks AS t WHERE t.DueDate IS NOT NULL;
```

`DATEPART(ISO_WEEK, d)` is also independent — it always follows ISO-8601 (weeks start Monday, week 1 contains the first Thursday). Prefer it over `DATEPART(WEEK, d)` in anything read across regions.

> **Rule of thumb:** Never let `SET DATEFIRST` or `SET LANGUAGE` leak into results. Use `ISO_WEEK`, or an anchor-date calculation, or — best of all — a **calendar dimension table** with pre-computed `WeekStart`, `FiscalQuarter` and `IsWorkingDay`. A calendar table also restores SARGability, because you join instead of compute.

---

## 13. Age, Calculated Correctly

`DATEDIFF(YEAR, dob, today)` is wrong for the reason in Section 9: it counts January boundaries. Count them, then subtract one if this year's anniversary has not happened yet.

```sql
DECLARE @Dob DATE = '2000-08-15', @Today DATE = '2025-08-14';

SELECT DATEDIFF(YEAR, @Dob, @Today) AS NaiveWrong,                              -- 25
       DATEDIFF(YEAR, @Dob, @Today)
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @Dob, @Today), @Dob) > @Today
                THEN 1 ELSE 0 END AS CorrectAge;                                -- 24

-- Same pattern: whole months a project has been running
SELECT p.ProjectCode, p.StartDate,
       DATEDIFF(MONTH, p.StartDate, CAST(SYSUTCDATETIME() AS DATE))
         - CASE WHEN DATEADD(MONTH, DATEDIFF(MONTH, p.StartDate, CAST(SYSUTCDATETIME() AS DATE)), p.StartDate)
                     > CAST(SYSUTCDATETIME() AS DATE) THEN 1 ELSE 0 END AS FullMonthsRunning
FROM   app.Projects AS p;
```

Leap-day caveat: `DATEADD(YEAR, 1, '2024-02-29')` is `2025-02-28`, so a 29 February birthday reaches its anniversary on 28 February. That is a policy decision to document, not a bug to fix.

---

## 14. Conversion: `CAST` vs `CONVERT`

| | `CAST(expr AS type)` | `CONVERT(type, expr [, style])` |
|---|---|---|
| Standard | ANSI SQL | T-SQL only |
| Style codes | No | **Yes** — the only reason to use it |
| Portability | High | None |

| Style | Output | Name |
|---|---|---|
| `112` | `yyyymmdd` | Unambiguous, sortable, language-independent |
| `120` / `121` | `yyyy-mm-dd hh:mi:ss[.mmm]` | ODBC canonical, 24-hour |
| `126` | `yyyy-mm-ddThh:mi:ss.mmm` | ISO-8601 — the interop choice |
| `23` | `yyyy-mm-dd` | Date only |
| `101` / `103` | `mm/dd/yyyy` / `dd/mm/yyyy` | US / British — display only |
| `1` / `2` (binary) | hex with / without `0x` | For `VARBINARY` |

```sql
SELECT CAST(t.EstimatedHours AS INT)             AS HoursAsInt,
       CONVERT(CHAR(8),      t.DueDate,     112) AS Compact,   -- 20250830
       CONVERT(CHAR(10),     t.DueDate,     120) AS Iso,       -- 2025-08-30
       CONVERT(VARCHAR(30),  t.CreatedAtUtc, 126) AS Iso8601   -- 2025-07-01T13:00:00.000
FROM   app.Tasks AS t WHERE t.TaskId = 5;
```

**Safe date literals.** Only two input formats are unambiguous regardless of `SET LANGUAGE` and `SET DATEFORMAT`: `'20250830'` and `'2025-08-30T13:45:00'`. `'2025-08-30'` (dashes, no `T`) is safe for `DATE` and `DATETIME2` but is interpreted using `DATEFORMAT` for the legacy `DATETIME` type. `'08/30/2025'` is a bug waiting for a British user.

---

## 15. Safe Conversion: `TRY_CAST`, `TRY_CONVERT`, `PARSE`

| Function | On failure | Cost | Since |
|---|---|---|---|
| `CAST` / `CONVERT` | **Error**, statement aborts | Cheap | Always |
| `TRY_CAST` / `TRY_CONVERT` | Returns `NULL` | Cheap | 2012 |
| `PARSE` / `TRY_PARSE` | Error / `NULL` | **Very** expensive (CLR) | 2012 |

```sql
SELECT TRY_CAST('123' AS INT)                     AS Ok,       -- 123
       TRY_CAST('abc' AS INT)                     AS Bad,      -- NULL, no error
       TRY_CONVERT(DATE, '2025-13-45')            AS BadDate,  -- NULL
       TRY_PARSE('30/08/2025' AS DATE USING 'en-GB') AS ParsedUk;

-- Validating the free-text values in the audit table
SELECT th.TaskHistoryId, th.NewValue, TRY_CONVERT(INT, th.NewValue) AS NewValueAsInt
FROM   audit.TaskHistory AS th WHERE th.ColumnName = N'StatusId';
```

`TRY_CAST` still raises an error if the conversion is **not permitted at all** (for example `TRY_CAST(GETDATE() AS XML)`); it only suppresses *data* conversion failures. `PARSE`/`TRY_PARSE` are CLR-based and culture-aware — the only built-ins that read `'30/08/2025'` as British — but roughly an order of magnitude slower. Use them for one-off imports, never in a hot path.

---

## 16. Implicit Conversion — the Index Killer

When two operands differ in type, SQL Server converts the **lower-precedence** side. Precedence (partial, highest first): `DATETIME2` > `DATETIME` > `DATE` > `FLOAT` > `DECIMAL` > `BIGINT` > `INT` > `NVARCHAR` > `VARCHAR` > `CHAR`. Two rules matter: **`NVARCHAR` outranks `VARCHAR`**, and **any numeric type outranks any string type**.

```sql
-- app.Projects.ProjectCode is VARCHAR(10)
SELECT p.ProjectId FROM app.Projects AS p WHERE p.ProjectCode = N'TF-CORE';  -- column converted
SELECT p.ProjectId FROM app.Projects AS p WHERE p.ProjectCode =  'TF-CORE';  -- clean seek
```

The plan shows `CONVERT_IMPLICIT(nvarchar(10), [p].[ProjectCode], 0)`. Once the column is wrapped, its index is not directly seekable. With a **Windows** collation the optimiser can often still seek via an internal `GetRangeThroughConvert`; with a legacy `SQL_*` collation it cannot. Do not rely on the rescue.

| Layer | Fix |
|---|---|
| ADO.NET | `SqlDbType.VarChar`, not `NVarChar`; always set `Size` |
| Dapper | `new DbString { Value = code, IsAnsi = true, Length = 10 }` |
| EF Core | `.IsUnicode(false).HasMaxLength(10)` or `.HasColumnType("varchar(10)")` |

> **Rule of thumb:** Grep your plans for `CONVERT_IMPLICIT` and watch for "Type conversion in expression may affect CardinalityEstimate". Every hit is a missing type declaration in the app or a column typed inconsistently across tables.

---

## 17. NULL Handling: `ISNULL`, `COALESCE`, `NULLIF`

| | `ISNULL(a, b)` | `COALESCE(a, b, c, …)` |
|---|---|---|
| Standard | T-SQL only | **ANSI SQL** |
| Arguments | Exactly 2 | 2 or more |
| Return type | Type of the **first** argument | **Highest-precedence** type among all |
| Truncation | Silently truncates | Never |
| Result nullability | `NOT NULL` if the 2nd argument is non-nullable | Nullable unless an argument is a non-null literal |
| Implementation | Single intrinsic, one evaluation | Expands to `CASE` — the first input may run **twice** |
| All-`NULL` literals | `ISNULL(NULL, NULL)` returns `NULL` | `COALESCE(NULL, NULL)` is an **error** |

```sql
SELECT ISNULL(CAST(NULL AS VARCHAR(2)), 'abcdef')   AS Truncated,  -- 'ab'
       COALESCE(CAST(NULL AS VARCHAR(2)), 'abcdef') AS Intact;     -- 'abcdef'

-- ref.Priorities.SlaHours is NULL for PriorityCode = 'NONE'
SELECT p.PriorityCode, ISNULL(p.SlaHours, 0) AS SlaHoursOrZero,
       COALESCE(CAST(p.SlaHours AS NVARCHAR(10)), N'—') AS SlaDisplay
FROM   ref.Priorities AS p;
```

`COALESCE(a, b)` is defined as `CASE WHEN a IS NOT NULL THEN a ELSE b END` — `a` appears **twice**, so a scalar subquery or a non-deterministic function can be evaluated twice. Nullability matters for schema design: `ISNULL(x, 0)` is inferred `NOT NULL`, so it can be used in a `PERSISTED` computed column that participates in a primary key; the `COALESCE` form generally cannot.

> **Rule of thumb:** Use `COALESCE` by default — ANSI, N arguments, no truncation. Reach for `ISNULL` when you specifically need the `NOT NULL` inference or single evaluation.

### `NULLIF`

`NULLIF(a, b)` returns `NULL` when `a = b`, otherwise `a`. It is also a `CASE`, so `b` is evaluated twice.

```sql
-- Divide-by-zero protection (the canonical use): NULL instead of Msg 8134
SELECT t.EstimatedHours / NULLIF(t.StoryPoints, 0) AS HoursPerPoint FROM app.Tasks AS t;

-- Turn CHARINDEX's "not found" 0 into a real NULL
SELECT SUBSTRING(u.Email, NULLIF(CHARINDEX(N'@', u.Email), 0) + 1, 100) AS Domain FROM app.Users AS u;

-- Treat empty string as missing when importing external data
SELECT NULLIF(TRIM(th.NewValue), N'') AS Normalised FROM audit.TaskHistory AS th;
```

### `SET ANSI_NULLS`

`SET ANSI_NULLS OFF` makes `= NULL` behave like `IS NULL`. It is **deprecated**, announced for removal, and must be `ON` for indexed views, indexes on computed columns and filtered indexes. The only place you will meet it is a legacy stored procedure that captured `OFF` at creation time — a module remembers the setting it was created with, regardless of the caller's session. Check `sys.sql_modules.uses_ansi_nulls`.

---

## 18. Logical Functions: `CASE`, `IIF`, `CHOOSE`, `GREATEST`/`LEAST`

```sql
-- Simple CASE: compares one expression with = . CANNOT match NULL.
SELECT t.TaskId, CASE t.PriorityId WHEN 1 THEN N'Critical' WHEN 2 THEN N'High' ELSE N'Normal' END AS Bucket,
-- Searched CASE: arbitrary predicates, including IS NULL
       CASE WHEN t.DueDate IS NULL                          THEN N'Undated'
            WHEN t.DueDate < CAST(SYSUTCDATETIME() AS DATE) THEN N'Overdue'
            ELSE                                                 N'Scheduled' END AS DueBucket,
       IIF(t.DueDate IS NULL, N'Undated', N'Dated')                               AS DateFlag,
       CHOOSE(t.PriorityId, N'P1', N'P2', N'P3', N'P4', N'P5')                    AS PriorityLabel
FROM   app.Tasks AS t;
```

Four `CASE` rules: **simple `CASE` can never match `NULL`** because it uses `=`; **first match wins**, top to bottom; **no `ELSE` means `NULL`**, silently; and **the result type is the highest-precedence branch type**, so `CASE WHEN … THEN 1 ELSE 'none' END` fails while `… ELSE 2.5 END` silently returns `DECIMAL`. `CASE` is *generally* left-to-right but the documentation does **not** guarantee short-circuiting — never use it as a guard against a conversion error or a divide-by-zero; use `TRY_CONVERT` and `NULLIF`.

`IIF` is sugar rewritten to a searched `CASE`, capped at 10 nesting levels. `CHOOSE` is **1-based** and returns `NULL` out of range. Both are T-SQL only; `CASE` is portable.

> **Anti-pattern:** `CHOOSE` as a substitute for a lookup table. `ref.Priorities` already stores `PriorityName` — hard-coding labels in a `CHOOSE` means a new priority needs a code deployment.

```sql
-- GREATEST/LEAST (2022+) work ACROSS COLUMNS in a row and ignore NULLs,
-- returning NULL only if every argument is NULL.
SELECT t.TaskId, GREATEST(t.CreatedAtUtc, t.ModifiedAtUtc, t.CompletedAtUtc) AS LastTouchedUtc
FROM   app.Tasks AS t;

-- Pre-2022 fallback, valid on every version
SELECT t.TaskId, x.LastTouchedUtc
FROM   app.Tasks AS t
CROSS APPLY (SELECT MAX(v) FROM (VALUES (t.CreatedAtUtc), (t.ModifiedAtUtc), (t.CompletedAtUtc)) AS d(v)) AS x(LastTouchedUtc);
```

---

## 19. System & Metadata Functions

| Function | Returns | Notes |
|---|---|---|
| `@@VERSION` | Version banner | Human-readable; do not parse it |
| `SERVERPROPERTY('ProductVersion' / 'EngineEdition')` | Version / edition | **Parse these instead**; `EngineEdition = 5` is Azure SQL DB |
| `@@ROWCOUNT` / `ROWCOUNT_BIG()` | Rows affected by the **last** statement | Reset by every statement, including `IF` |
| `DB_NAME()` / `SCHEMA_NAME()` / `OBJECT_NAME(id)` / `OBJECT_ID('app.Tasks')` | Names and ids | The bridge into the `sys.*` catalog views |
| `SUSER_SNAME()` / `SYSTEM_USER` / `ORIGINAL_LOGIN()` | Login | `ORIGINAL_LOGIN` survives `EXECUTE AS` |
| `USER_NAME()` / `CURRENT_USER` | Database user | |
| `HOST_NAME()` / `APP_NAME()` | Client-supplied strings | **Spoofable** — never authorise on them |
| `NEWID()` / `NEWSEQUENTIALID()` | GUID | `NEWSEQUENTIALID` is valid **only** as a column `DEFAULT` |

```sql
SELECT SERVERPROPERTY('ProductVersion')    AS ProductVersion,
       DB_NAME()                           AS CurrentDatabase,
       SUSER_SNAME()                       AS LoginName,
       ORIGINAL_LOGIN()                    AS OriginalLogin,
       OBJECT_NAME(OBJECT_ID('app.Tasks')) AS ResolvedObject,
       @@SPID                              AS SessionId;
```

`audit.TaskHistory.ChangedBy` defaults to `SUSER_SNAME()` — that is this family in production use. `@@ROWCOUNT` must be captured **immediately**, because the very next statement overwrites it, including the `IF` that tests it:

```sql
UPDATE app.Tasks SET ModifiedAtUtc = SYSUTCDATETIME() WHERE TaskId = 5;
DECLARE @Rows INT = @@ROWCOUNT;                      -- capture on the very next line
IF @Rows = 0 THROW 50001, 'Task not found.', 1;
```

`NEWID()` is a poor **clustered index** key — random values cause page splits and fragmentation on every insert. `NEWSEQUENTIALID()` fixes that but leaks the MAC address and creation order, so never expose it externally.

---

## 20. Identity Retrieval

| Function | Scope | Session | Failure mode |
|---|---|---|---|
| `SCOPE_IDENTITY()` | **Current scope** | Current | Returns `NUMERIC(38,0)` — cast it |
| `@@IDENTITY` | Any scope | Current | A trigger inserting elsewhere returns **that** table's identity |
| `IDENT_CURRENT('app.Tasks')` | Any scope | **Any session** | Race condition — another user's value |
| `OUTPUT` clause | Exact | Exact | None; also handles multi-row inserts |

```sql
BEGIN TRANSACTION;
DECLARE @Inserted TABLE (TaskId INT);

INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
OUTPUT inserted.TaskId INTO @Inserted (TaskId)
VALUES (1, N'Outbox worker', 1, 3, 4), (1, N'Outbox dispatcher', 1, 3, 4);

SELECT i.TaskId AS FromOutput, CAST(SCOPE_IDENTITY() AS INT) AS FromScopeIdentity FROM @Inserted AS i;
ROLLBACK TRANSACTION;
```

`@@IDENTITY` is the classic production bug: add an audit trigger on `app.Tasks` that inserts into `audit.TaskHistory` and every `INSERT` suddenly returns a `TaskHistoryId`. Note also that identity values are consumed even by a rolled-back transaction — identity is **not** transactional, gaps are normal, and you must never present an identity value to a user as a gapless sequence.

---

## 21. Determinism

A function is **deterministic** if it always returns the same result for the same inputs and database state.

| Deterministic | Non-deterministic |
|---|---|
| `LEN`, `LEFT`, `SUBSTRING`, `REPLACE`, `ABS`, `POWER` | `GETDATE`, `SYSDATETIME`, `SYSUTCDATETIME`, `CURRENT_TIMESTAMP` |
| `DATEADD`, `DATEDIFF`, `YEAR`, `MONTH`, `DAY` | `NEWID`, `RAND()` without a seed |
| `ISNULL`, `COALESCE`, `NULLIF`, `CASE` | `@@IDENTITY`, `@@ROWCOUNT`, `SUSER_SNAME` |
| `CAST`/`CONVERT` with a deterministic style | `FORMAT`, `PARSE`, `DATENAME`, `DATEPART(WEEKDAY, …)` |

Determinism is not trivia — it **gates real features**: `PERSISTED` computed columns, indexes on computed columns, indexed views, and columns participating in `CHECK`, `PRIMARY KEY`, `UNIQUE` and `FOREIGN KEY` constraints.

```sql
SELECT COLUMNPROPERTY(OBJECT_ID('app.Users'), 'FullName', 'IsDeterministic') AS IsDeterministic;  -- 1
```

`app.Users.FullName` is `FirstName + N' ' + LastName` — concatenation of two deterministic column references, which is exactly why the schema can declare it `PERSISTED` and index it. Redefine it with `FORMAT` or `GETDATE()` and the `PERSISTED` keyword becomes illegal.

**Precise** is a separate property: an expression involving `FLOAT`/`REAL` is imprecise and cannot be indexed even when deterministic. Use `DECIMAL` in computed columns you intend to index. This also yields a powerful optimisation — add `CreatedYear AS (YEAR(CreatedAtUtc)) PERSISTED` plus an index and SQL Server will **automatically match** an unchanged `WHERE YEAR(t.CreatedAtUtc) = 2025` to it. That is how you fix a non-SARGable predicate in code you do not control.

---

## 22. Scalar Functions Kill Performance

Two distinct problems. The first is built-in scalar functions on a column in `WHERE` — covered in Topic 03: the function is cheap, the lost index is not. The second is **T-SQL scalar UDFs**:

```sql
CREATE FUNCTION dbo.fn_TaskAgeDays (@CreatedAtUtc DATETIME2(3)) RETURNS INT
AS BEGIN RETURN DATEDIFF(DAY, @CreatedAtUtc, SYSUTCDATETIME()); END;
GO
SELECT t.TaskId, dbo.fn_TaskAgeDays(t.CreatedAtUtc) AS AgeDays FROM app.Tasks AS t;
GO
DROP FUNCTION IF EXISTS dbo.fn_TaskAgeDays;
```

| Problem | Effect |
|---|---|
| **Row-by-row invocation** | Runs once per row with its own mini-plan. No set-based execution. |
| **No parallelism (pre-2019)** | A scalar UDF *anywhere* forces the **entire plan serial**. |
| **Costed as ~zero** | The optimiser picks plans based on a fiction. |
| **Invisible in the plan** | Pre-2019 its work shows no operators — the plan looks cheap while the query takes minutes. |

SQL Server 2019 under compatibility level 150 added **Scalar UDF Inlining** (FROID), which rewrites a qualifying UDF into a relational expression, restoring costing and parallelism:

```sql
SELECT OBJECT_NAME(sm.object_id) AS FunctionName, sm.is_inlineable
FROM   sys.sql_modules AS sm WHERE sm.is_inlineable IS NOT NULL;
```

Not every UDF qualifies — common disqualifiers are `EXECUTE`, table variables, recursion, aggregates in the return expression and side effects. Inlining can also regress a query, so disable it per function with `WITH INLINE = OFF` or per query with `OPTION (USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'))`.

| Instead of | Use |
|---|---|
| A scalar UDF in the select list | The expression inline, or `CROSS APPLY (VALUES (expr))` |
| A scalar UDF encapsulating a lookup | An **inline table-valued function** + `CROSS APPLY` — expanded into the calling plan, not called per row |
| A scalar UDF reused across queries | A **persisted computed column**, if deterministic |
| A scalar UDF in `WHERE` | A SARGable predicate over an indexed column |

> **Rule of thumb:** T-SQL has no cheap abstraction for "a function returning one value". If you are about to write `CREATE FUNCTION … RETURNS INT`, write `RETURNS TABLE` instead.

---

## 23. Portability Summary

| Need | SQL Server | PostgreSQL | MySQL | Oracle |
|---|---|---|---|---|
| Character length | `LEN` (ignores trailing spaces) | `length()` | `CHAR_LENGTH()` | `LENGTH()` |
| Byte length | `DATALENGTH` | `octet_length()` | `LENGTH()` | `LENGTHB()` |
| Concatenate | `+`, `CONCAT` | `\|\|`, `concat()` | `CONCAT()` only | `\|\|`, `CONCAT()` |
| Substring | `SUBSTRING(s, i, n)` | `substring(s from i for n)` | `SUBSTRING(s, i, n)` | `SUBSTR(s, i, n)` |
| Now (UTC) | `SYSUTCDATETIME()` | `now() AT TIME ZONE 'utc'` | `UTC_TIMESTAMP()` | `SYS_EXTRACT_UTC(SYSTIMESTAMP)` |
| Add an interval | `DATEADD(DAY, n, d)` | `d + n * interval '1 day'` | `DATE_ADD(d, INTERVAL n DAY)` | `d + n` |
| Difference | `DATEDIFF(DAY, a, b)` | `b - a` | `DATEDIFF(b, a)` | `b - a` |
| Coalesce | `ISNULL`, `COALESCE` | `COALESCE` | `IFNULL`, `COALESCE` | `NVL`, `COALESCE` |
| Conditional | `CASE`, `IIF` | `CASE` | `CASE`, `IF()` | `CASE`, `DECODE` |
| Convert | `CAST`, `CONVERT(…, style)` | `CAST`, `::`, `to_char()` | `CAST`, `CONVERT` | `CAST`, `TO_CHAR`, `TO_DATE` |
| Safe convert | `TRY_CAST` | `pg_input_is_valid()` (16+) | none | `CAST(… DEFAULT NULL ON CONVERSION ERROR)` |
| String aggregate | `STRING_AGG` | `string_agg` | `GROUP_CONCAT` | `LISTAGG` |
| Split a string | `STRING_SPLIT` | `regexp_split_to_table` | `JSON_TABLE` workaround | `APEX_STRING.SPLIT` |
| Greatest across columns | `GREATEST` (2022+) | `greatest()` | `GREATEST()` | `GREATEST()` |
| Regex | `LIKE`/`PATINDEX` (`REGEXP_LIKE` in 2025) | `~`, `regexp_*` | `REGEXP_LIKE` | `REGEXP_LIKE` |

The two biggest hazards: `ISNULL` and `IIF` do not exist outside T-SQL, and `CONVERT` style codes have no equivalent anywhere. Prefer `COALESCE`, `CASE` and `CAST` if the code may ever move.

---

## Mental Model

> A built-in function is a value transformer, and every one has three properties you must know before you use it: **what it does to `NULL`**, **what type it returns**, and **whether it is deterministic**. Miss the first and your report shows blanks. Miss the second and your percentage is `0` or your string is truncated. Miss the third and you cannot persist, index, or cache the result.
>
> Layer on the cost model. Scalar functions run **once per row**, so a function in the select list is a per-row tax on every result — and a function wrapped around a **column in `WHERE`** is a per-row tax on every row in the table, because you have just traded an index seek for a scan. A T-SQL scalar UDF is that tax with interest: row-by-row invocation, zero-cost mis-estimation, and (before 2019) a serial plan for the entire query.
>
> So the decision procedure is short. Transform the **literal**, never the **column**. Store UTC and convert at the edge. Format in the presentation layer, not in `FORMAT`. Prefer `COALESCE` and `CASE` because they are ANSI, and reach for `ISNULL` only when you need the `NOT NULL` inference. And when you feel the urge to write `CREATE FUNCTION … RETURNS INT`, write `RETURNS TABLE` instead.

Move to [Practice Problems](./Practice-Problems.md).
