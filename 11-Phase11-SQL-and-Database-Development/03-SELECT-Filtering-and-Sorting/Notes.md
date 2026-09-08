# Topic 03: SELECT, Filtering & Sorting

> Every screen in **TaskFlow** is a `SELECT`. The board, the backlog, the "my overdue tasks" badge, the CSV export, `GET /api/tasks?status=in_progress&page=4` — all of it is projection, filtering and ordering. This is also where most production incidents start: a `SELECT *` that breaks when a column is added, a `NOT IN` that silently returns zero rows because of one `NULL`, a `BETWEEN` that drops the last day of the month, an `OFFSET 500000` that takes eight seconds. Get this topic right and everything downstream — joins, aggregates, window functions — is just more of the same shape.

---

## 1. Anatomy of a `SELECT`

```sql
SELECT   [DISTINCT] [TOP (n) [PERCENT] [WITH TIES]] <select_list>
FROM     <table_source>
WHERE    <predicate>
GROUP BY <grouping_columns>
HAVING   <group_predicate>
ORDER BY <sort_list>
OFFSET   n ROWS FETCH NEXT m ROWS ONLY;
```

Only `SELECT` is mandatory, but the **written order is fixed** — you cannot put `WHERE` before `FROM`. Topic 05 owns `GROUP BY`/`HAVING`; this topic owns `SELECT`, `FROM`, `WHERE`, `DISTINCT`, `ORDER BY`, `TOP` and `OFFSET/FETCH`.

---

## 2. Logical Query Processing Order

The order you *write* clauses is not the order the engine *reasons* about them. This one table explains more T-SQL error messages than any other fact in the phase.

| Step | Clause | What exists after it |
|---|---|---|
| 1 | `FROM` / `JOIN` / `APPLY` | Table aliases are in scope |
| 2 | `WHERE` | Filtered rows; **still only base columns** |
| 3 | `GROUP BY` | Groups |
| 4 | `HAVING` | Filtered groups |
| 5 | `SELECT` | **Column aliases are born here** |
| 6 | `DISTINCT` | De-duplicated rows |
| 7 | `ORDER BY` | Ordered rows; aliases visible |
| 8 | `TOP` / `OFFSET…FETCH` | The final slice |

Anything created at step *n* is invisible to every step before *n*.

### You cannot reference a `SELECT` alias in `WHERE`

```sql
-- FAILS: Msg 207, Invalid column name 'DaysLate'.
SELECT t.TaskId, DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)) AS DaysLate
FROM   app.Tasks AS t
WHERE  DaysLate > 30;
```

`WHERE` runs at step 2; `DaysLate` does not exist until step 5. Three legal fixes:

```sql
-- A: repeat the expression (works, duplicates logic)
WHERE DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)) > 30;

-- B: CTE or derived table
WITH Late AS (SELECT t.TaskId, DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)) AS DaysLate
              FROM app.Tasks AS t)
SELECT * FROM Late WHERE DaysLate > 30;

-- C: CROSS APPLY (VALUES ...) — define once, use in WHERE, GROUP BY, SELECT and ORDER BY
SELECT t.TaskId, v.DaysLate
FROM   app.Tasks AS t
CROSS APPLY (VALUES (DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)))) AS v(DaysLate)
WHERE  v.DaysLate > 30;
```

> **Rule of thumb:** Fix C is the T-SQL idiom for a reusable inline expression. Learn it now — you will use it in every topic from 06 onwards.

`ORDER BY` runs at step 7, so it *can* use an alias: `ORDER BY DaysLate DESC` is legal. And remember this is **logical**, not physical, order — the optimiser may push a predicate into an index seek or evaluate `TOP` early, as long as the result matches the logical model.

---

## 3. Projection and Column Aliases

`SELECT` is **projection**: choosing and computing the columns that leave the query. Expressions, literals, function calls and `CASE` are all legal in the select list. Projection is not free — every column is bytes on the wire, memory grant for sorts, and a reason the optimiser may reject a covering index.

Three alias syntaxes, all valid in T-SQL:

```sql
SELECT t.TaskId  AS TaskIdentifier,   -- 1. ANSI standard. Default choice.
       t.Title      TaskTitle,        -- 2. Space-only. Legal, dangerous.
       DueDateUtc = t.DueDate         -- 3. T-SQL "alias = expression".
FROM app.Tasks AS t;
```

| Form | Portable | Verdict |
|---|---|---|
| `expr AS alias` | Yes (ANSI) | **Default choice** |
| `expr alias` | Yes | Avoid — silent bugs |
| `alias = expr` | No (T-SQL only) | Excellent for long lists in T-SQL codebases |

### Why the `alias = expr` form exists

Because the space-only form creates a bug that compiles cleanly. Miss a comma and the next column name becomes an alias:

```sql
-- Intended THREE columns. Returns TWO. No error.
SELECT Title,
       DueDate        -- <-- missing comma
       PriorityId
FROM app.Tasks;
-- Output columns: Title, PriorityId  (PriorityId is now an ALIAS for DueDate)
```

With `alias = expr` the same typo is a syntax error, and the aliases form a clean left-hand column you can scan and diff. For aliases containing spaces or reserved words, use brackets — `AS [Task Title]` — or double quotes if `QUOTED_IDENTIFIER` is `ON`.

> **Rule of thumb:** Alias for the consumer. If the DTO property is `dueDateUtc`, alias the column `DueDateUtc` — do not make Dapper or EF Core guess.

---

## 4. `SELECT *` Is an Anti-Pattern

| Problem | Why it bites |
|---|---|
| **Schema drift** | Adding `app.Tasks.Description` (`NVARCHAR(MAX)`) silently multiplies payload size |
| **Ordinal binding** | `reader.GetString(3)` breaks when a column is inserted |
| **Breaks covering indexes** | An index on `(StatusId, DueDate) INCLUDE (Title)` covers a 3-column query, never `*` |
| **Stale views** | `CREATE VIEW … SELECT *` freezes the column list at creation time |
| **Leaks data** | `SELECT *` on `app.Users` exposes `HourlyRate` to an endpoint that never needed it |
| **`INSERT … SELECT *`** | Silently misaligns when column order changes |

Acceptable uses: ad-hoc exploration, `EXISTS (SELECT * FROM …)` where the list is never evaluated, and `COUNT(*)`.

> **Anti-pattern:** `SELECT *` anywhere that ships. Name your columns.

---

## 5. `FROM` and Table Aliases

```sql
SELECT t.TaskId, t.Title, p.ProjectName
FROM   app.Tasks    AS t
JOIN   app.Projects AS p ON p.ProjectId = t.ProjectId;
```

- **Always schema-qualify.** `app.Tasks`, not `Tasks`. Unqualified names force a name-resolution probe against the caller's default schema and produce different cached plans per user.
- **Alias every table, qualify every column.** In a four-table join an unqualified `UserId` is a landmine: the day a second table gains that column the query becomes ambiguous — or worse, silently resolves to the wrong table inside a subquery.
- **Once aliased, the original name is out of scope.** `SELECT app.Tasks.Title FROM app.Tasks AS t;` fails with Msg 4104.
- Four-part naming (`server.database.schema.object`) couples code to a topology — avoid it outside one-off migrations.

---

## 6. `WHERE` and Comparison Operators

| Operator | Meaning | Note |
|---|---|---|
| `=` | Equal | Never matches `NULL` |
| `<>` / `!=` | Not equal | `<>` is ANSI; prefer it |
| `<`, `>`, `<=`, `>=` | Ordering | Collation-driven for strings |
| `IS [NOT] NULL` | NULL test | The **only** way to test `NULL` |
| `BETWEEN` | Inclusive range | Sugar for `>= AND <=` |
| `IN` | Set membership | Sugar for chained `OR` |
| `LIKE` | Pattern match | Wildcards + collation |
| `EXISTS` | Row existence | Topic 07 |

```sql
-- Open, high-or-critical, already past due
SELECT t.TaskId, t.Title, t.DueDate, t.PriorityId
FROM   app.Tasks AS t
JOIN   ref.TaskStatuses AS s ON s.StatusId = t.StatusId
WHERE  s.IsTerminal = 0
  AND  t.PriorityId <= 2
  AND  t.DueDate < CAST(SYSUTCDATETIME() AS DATE);
```

Note `s.IsTerminal = 0` — `BIT` compares to `0`/`1`. T-SQL has no boolean data type.

---

## 7. `AND`, `OR`, `NOT` and Operator Precedence

| Rank | Operators |
|---|---|
| 1 | `~` (bitwise NOT) |
| 2 | `*`, `/`, `%` |
| 3 | `+`, `-`, `&`, `^`, `\|` |
| 4 | `=`, `>`, `<`, `>=`, `<=`, `<>`, `!=` |
| 5 | `NOT` |
| 6 | `AND` |
| 7 | `ALL`, `ANY`, `BETWEEN`, `IN`, `LIKE`, `OR`, `SOME` |

**`AND` binds tighter than `OR`.** This is the most common logic bug in production SQL:

```sql
-- WRONG: reads as  StatusId = 3  OR  (StatusId = 4 AND PriorityId = 1)
WHERE t.StatusId = 3 OR t.StatusId = 4 AND t.PriorityId = 1;

-- RIGHT
WHERE (t.StatusId = 3 OR t.StatusId = 4) AND t.PriorityId = 1;
```

> **Rule of thumb:** If a `WHERE` clause mixes `AND` and `OR`, parenthesise **every** `OR` group — even when precedence already agrees with you. The parentheses are documentation for the next reader.

`NOT` distributes by De Morgan's laws (`NOT (a AND b) == NOT a OR NOT b`), and that is where `NULL` breaks your intuition — see Section 11.

---

## 8. `BETWEEN` — Inclusive, and the Date-Range Trap

`x BETWEEN lo AND hi` is exactly `x >= lo AND x <= hi`. **Both endpoints are inclusive**, and `lo` must be `<= hi` or you get zero rows.

```sql
SELECT t.TaskId, t.Title, t.EstimatedHours
FROM   app.Tasks AS t
WHERE  t.EstimatedHours BETWEEN 8 AND 16;   -- both 8 and 16 included
```

### The trap: a column with a time component

`app.Tasks.CompletedAtUtc` is `DATETIME2(3)`. A date literal means **midnight**:

```sql
-- BUG: misses everything completed after midnight on the 28th.
WHERE t.CompletedAtUtc BETWEEN '2024-02-01' AND '2024-02-28';
-- TaskId 1 completed at 2024-02-28T16:40:00 -> EXCLUDED. Silently.
```

| Attempted fix | Why it is wrong |
|---|---|
| `AND '2024-02-28 23:59:59'` | Loses rows in the last second |
| `AND '2024-02-28 23:59:59.997'` | `DATETIME`-specific magic number; wrong for `DATETIME2` |
| `WHERE CAST(t.CompletedAtUtc AS DATE) BETWEEN …` | Correct results, but non-SARGable |

The correct, universal pattern is a **half-open interval**:

```sql
DECLARE @Start DATE = '2024-02-01', @EndExclusive DATE = '2024-03-01';

SELECT t.TaskId, t.Title, t.CompletedAtUtc
FROM   app.Tasks AS t
WHERE  t.CompletedAtUtc >= @Start
  AND  t.CompletedAtUtc <  @EndExclusive;
```

> **Rule of thumb:** `>= @start AND < @endPlusOne`. Never `BETWEEN` on a datetime column. It is correct for every precision (`DATETIME`, `DATETIME2(0..7)`, `DATETIMEOFFSET`) and it stays SARGable. `BETWEEN` on a pure `DATE` column such as `app.Tasks.DueDate` is safe — there is no time to lose.

---

## 9. `IN` / `NOT IN` — and the `NULL` Trap

```sql
SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.StatusId IN (3, 4, 5);

SELECT t.TaskId, t.Title
FROM   app.Tasks AS t
WHERE  t.ProjectId IN (SELECT p.ProjectId FROM app.Projects AS p WHERE p.IsArchived = 0);
```

`NOT IN` expands to chained `<>` joined by `AND`. If **any** value in the list is `NULL`, that comparison yields `UNKNOWN`, and `TRUE AND UNKNOWN` can never be `TRUE`. Result: **zero rows, no error.**

```sql
-- Returns ZERO rows. app.Teams.LeadUserId is NULL for the 'Design System' team.
SELECT u.UserId, u.FullName
FROM   app.Users AS u
WHERE  u.UserId NOT IN (SELECT tm.LeadUserId FROM app.Teams AS tm);
```

Expansion for `UserId = 9`:

```
9 <> 4 AND 9 <> 5 AND 9 <> 5 AND 9 <> 6 AND 9 <> 15 AND 9 <> 3 AND 9 <> NULL
TRUE   AND TRUE   AND TRUE   AND TRUE   AND TRUE    AND TRUE   AND UNKNOWN    = UNKNOWN
```

Plain `IN` is not affected the same way: it expands to `OR`, and `TRUE OR UNKNOWN = TRUE`. Three correct fixes:

```sql
-- A: NOT EXISTS (preferred — correct by construction, usually the best plan)
SELECT u.UserId, u.FullName FROM app.Users AS u
WHERE  NOT EXISTS (SELECT 1 FROM app.Teams AS tm WHERE tm.LeadUserId = u.UserId);

-- B: filter the NULLs out of the inner set
WHERE u.UserId NOT IN (SELECT tm.LeadUserId FROM app.Teams AS tm WHERE tm.LeadUserId IS NOT NULL);

-- C: LEFT JOIN + IS NULL (a hand-written anti-join)
SELECT u.UserId, u.FullName FROM app.Users AS u
LEFT   JOIN app.Teams AS tm ON tm.LeadUserId = u.UserId
WHERE  tm.TeamId IS NULL;
```

> **Rule of thumb:** Never write `NOT IN (<subquery>)`. Write `NOT EXISTS`. It is `NULL`-safe, it expresses an anti-join directly, and it does not silently change meaning when the inner column becomes nullable next sprint.

A literal list is fine — until a `NULL` gets in: `WHERE p.SlaHours NOT IN (4, 24, NULL)` against `ref.Priorities` returns zero rows.

---

## 10. `LIKE` and the SARGability Problem

| Wildcard | Matches | Example |
|---|---|---|
| `%` | Zero or more characters | `N'Fix%'` |
| `_` | Exactly one character | `N'_ug'` matches `bug`, `mug` |
| `[]` | One character from a set or range | `N'[0-9]'`, `N'[a-f]'` |
| `[^]` | One character **not** in the set | `N'[^0-9]'` |

```sql
SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.Title LIKE N'Fix%';        -- prefix
SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.Title LIKE N'%[0-9]%';     -- any digit
SELECT t.TaskId, t.MetadataJson FROM app.Tasks AS t WHERE t.MetadataJson LIKE N'%[_]%'; -- snake_case key
```

### Escaping literal wildcards

`%`, `_` and `[` are metacharacters. Use `ESCAPE` or a character class:

```sql
-- Comments mentioning a literal percent sign, e.g. "above 5% flake rate"
SELECT c.CommentId, c.Body FROM app.Comments AS c WHERE c.Body LIKE N'%!%%' ESCAPE '!';
SELECT c.CommentId, c.Body FROM app.Comments AS c WHERE c.Body LIKE N'%[%]%';   -- equivalent
```

A common misconception: `LIKE N'%[^0-9]%'` means "contains at least one non-digit", **not** "contains no digits". The negation you want is `NOT LIKE N'%[0-9]%'`.

Case sensitivity comes from the **collation**, not from `LIKE`. `t.Title COLLATE Latin1_General_CS_AS LIKE N'fix%'` is case-sensitive — and non-SARGable, because the column is now wrapped. Fix the column's collation, not the query.

### Leading wildcards

A B-tree index on a string is sorted left to right, so a known prefix becomes a range seek and an unknown prefix cannot.

| Pattern | Seekable? | Why |
|---|---|---|
| `N'Fix%'` | Yes | Known prefix -> range seek |
| `N'Fix%bug'` | Partially | Seeks `Fix%`, filters the rest as a residual predicate |
| `N'%bug'` / `N'%bug%'` | No | Unknown prefix |
| `N'_ix%'` | No | First character unknown |
| `LIKE @pattern` | Yes, at runtime | Optimiser adds `LikeRangeStart`/`End` operators |

Fixes for genuine "contains" search: a **full-text index** (`CONTAINS`, `FREETEXT`), a **reversed-string computed column** for suffix search, or an external search engine. Do not solve it with `%…%` at scale.

---

## 11. `NULL` and Three-Valued Logic

`NULL` is not a value; it is a marker for *unknown*. Every comparison with it returns **UNKNOWN**, and `WHERE` returns only rows where the predicate is **TRUE**.

```
NULL = NULL  -> UNKNOWN     NULL <> NULL -> UNKNOWN
NULL = 5     -> UNKNOWN     NULL + 5     -> NULL
NULL IS NULL -> TRUE        <-- the only reliable test
```

| `AND` | TRUE | FALSE | UNKNOWN |     | `OR` | TRUE | FALSE | UNKNOWN |
|---|---|---|---|---|---|---|---|---|
| **TRUE** | TRUE | FALSE | UNKNOWN | | **TRUE** | TRUE | TRUE | TRUE |
| **FALSE** | FALSE | FALSE | FALSE | | **FALSE** | TRUE | FALSE | UNKNOWN |
| **UNKNOWN** | UNKNOWN | FALSE | UNKNOWN | | **UNKNOWN** | TRUE | UNKNOWN | UNKNOWN |

`NOT TRUE = FALSE`, `NOT FALSE = TRUE`, and critically **`NOT UNKNOWN = UNKNOWN`** — which is why a filter and its complement do not partition a table:

```sql
-- app.Users has 20 rows. These two counts sum to 19, not 20.
SELECT COUNT(*) FROM app.Users AS u WHERE u.HourlyRate >  100;
SELECT COUNT(*) FROM app.Users AS u WHERE u.HourlyRate <= 100;
-- UserId 19 (Sophie Wilson) has a NULL HourlyRate and matches NEITHER.
-- Partition properly:  WHERE u.HourlyRate <= 100 OR u.HourlyRate IS NULL
```

| Context | `NULL` behaviour |
|---|---|
| `WHERE` | Row excluded (UNKNOWN is not TRUE) |
| `CHECK` constraint | Row **allowed** (UNKNOWN is not FALSE) |
| `GROUP BY` / `DISTINCT` | All `NULL`s collapse into **one** group/value |
| `ORDER BY` | Sorted together; position is engine-defined |
| `UNIQUE` constraint | SQL Server allows exactly **one** `NULL` |
| `COUNT(col)` | `NULL`s ignored; `COUNT(*)` counts the rows |
| `SUM` / `AVG` | `NULL`s ignored (`AVG` divides by the non-null count) |

Note the deliberate inconsistency in the standard: `WHERE` treats `NULL = NULL` as unknown, but `GROUP BY` and `DISTINCT` treat two `NULL`s as the *same*. That is exam material.

---

## 12. `DISTINCT`

`DISTINCT` de-duplicates the **entire emitted row**, after `SELECT` and before `ORDER BY`. There is no "distinct on one column" — `SELECT DISTINCT a, b` always means distinct `(a, b)` pairs.

```sql
SELECT DISTINCT t.ProjectId FROM app.Tasks AS t;              -- 8 rows
SELECT DISTINCT t.ProjectId, t.StatusId FROM app.Tasks AS t;  -- distinct PAIRS
```

| | `DISTINCT` | `GROUP BY` |
|---|---|---|
| Intent | "Remove duplicate output rows" | "Collapse rows into buckets" |
| Aggregates | Cannot add them | `COUNT`, `SUM`, … |
| `HAVING` | Not available | Available |
| Runs at | Step 6 (after `SELECT`) | Step 3 (before `SELECT`) |
| Plan | Usually identical (`Hash Match (Aggregate)` / `Stream Aggregate`) | Usually identical |

```sql
-- FAILS: Msg 145. ORDER BY items must appear in the select list with DISTINCT.
SELECT DISTINCT t.ProjectId FROM app.Tasks AS t ORDER BY t.CreatedAtUtc;
```

After de-duplication `CreatedAtUtc` no longer has a single value per output row, so the ordering would be ambiguous. The engine is protecting you.

> **Anti-pattern:** Sprinkling `DISTINCT` to make duplicate rows disappear after a join. Duplicates mean the **join grain is wrong** (`app.TaskAssignments` has two rows for task 4). `DISTINCT` hides the bug, adds a sort or hash, and will eventually return a wrong aggregate. Fix the join, usually with `EXISTS` or a pre-aggregated derived table.

---

## 13. `ORDER BY`

`ORDER BY` is the **only** way to guarantee row order. Without it a result set is a *set* — and the arbitrary order you observe today changes with a new index, a parallel plan, or a service pack.

| Form | Example | Verdict |
|---|---|---|
| Column | `ORDER BY t.DueDate` | Best |
| Column alias | `ORDER BY AgeDays` | Good |
| Expression | `ORDER BY LEN(t.Title)` | Fine, but forces a sort |
| Non-projected column | `ORDER BY t.CreatedAtUtc` | Legal (without `DISTINCT`) |
| Ordinal position | `ORDER BY 2, 3` | **Anti-pattern** |

> **Anti-pattern:** `ORDER BY 2`. Ordinals bind to *position*. Insert a column at the front and the query silently sorts by something else — no error, wrong report. Ordinals are also invisible to a text search for the column name. They still appear with `UNION`, where alias resolution is awkward; even there, prefer naming the first branch's aliases.

```sql
-- Custom business order: Blocked first, then In Progress, then by SortOrder
SELECT t.TaskId, t.Title, s.StatusCode
FROM   app.Tasks AS t
JOIN   ref.TaskStatuses AS s ON s.StatusId = t.StatusId
ORDER  BY CASE s.StatusCode WHEN 'BLOCKED' THEN 0 WHEN 'IN_PROGRESS' THEN 1 ELSE 2 END,
          s.SortOrder, t.TaskId;
```

The sample database already models this properly: `ref.TaskStatuses.SortOrder` exists so presentation order is **data**, not a hard-coded `CASE`. Prefer the lookup column.

### `NULL` sort position

SQL Server treats `NULL` as lower than any value — **first** under `ASC`, last under `DESC` — and has no `NULLS FIRST`/`NULLS LAST` clause.

```sql
-- Force undated tasks LAST while dates stay ascending
SELECT t.TaskId, t.Title, t.DueDate
FROM   app.Tasks AS t
ORDER  BY CASE WHEN t.DueDate IS NULL THEN 1 ELSE 0 END, t.DueDate ASC;
```

Do **not** substitute a sentinel (`ISNULL(t.DueDate, '9999-12-31')`): it is non-SARGable and breaks the moment a real row uses that value.

| Engine | Default in `ASC` | Explicit control |
|---|---|---|
| SQL Server | NULLs first | None — emulate with `CASE` |
| PostgreSQL / Oracle | NULLs **last** | `NULLS FIRST` / `NULLS LAST` |
| MySQL | NULLs first | None — emulate with `col IS NULL` |

> **Portability:** A query that sorts a nullable column produces a *different row order* on PostgreSQL than on SQL Server. If order matters to your API contract, make it explicit.

### Collation drives string ordering

```sql
SELECT u.UserId, u.LastName FROM app.Users AS u ORDER BY u.LastName;
SELECT u.UserId, u.LastName FROM app.Users AS u ORDER BY u.LastName COLLATE Latin1_General_BIN2;
```

`Latin1_General_CI_AS` treats `van Rossum` as starting with `V`, placing it between `Turing` and `Wilson`. A binary collation compares code points, so lowercase `v` (U+0076) sorts after uppercase `W` (U+0057) and `van Rossum` moves to the end. Same data, same query, different order. **Collation is part of your API contract.**

---

## 14. `TOP`

Always parenthesise — `TOP (5)`. The unparenthesised form is legacy and does not accept variables.

```sql
SELECT TOP (5) t.TaskId, t.Title, t.EstimatedHours
FROM   app.Tasks AS t ORDER BY t.EstimatedHours DESC;
```

**`TOP` without `ORDER BY` is non-deterministic.** `SELECT TOP (5) … FROM app.Tasks` is not "the first 5 rows" — there is no first. It is whichever 5 rows the chosen plan happened to produce. Add an index, go parallel, or upgrade the engine and the answer changes. Only defensible for `TOP (1)` existence checks and `TOP (0)` metadata tricks.

```sql
-- WITH TIES: keeps every row that ties on the ORDER BY key
SELECT TOP (2) WITH TIES t.TaskId, t.Title, t.EstimatedHours
FROM   app.Tasks AS t WHERE t.EstimatedHours IS NOT NULL
ORDER  BY t.EstimatedHours DESC;
-- Returns THREE rows: 60.00, then 40.00 and 40.00 (tasks 7 and 10 tie).

-- PERCENT: always rounds UP. 10% of 35 tasks = 3.5 -> 4 rows.
SELECT TOP (10) PERCENT t.TaskId, t.Title FROM app.Tasks AS t ORDER BY t.CreatedAtUtc DESC;
```

`WITH TIES` requires `ORDER BY`, considers only the `ORDER BY` columns, and can return far more rows than `n` — never use it for a fixed-size page buffer. `TOP` in `INSERT`/`UPDATE`/`DELETE` **ignores `ORDER BY`** unless you wrap the target in a derived table (Topic 10); it is still useful for batched deletes such as `DELETE TOP (1000) FROM audit.TaskHistory WHERE ChangedAtUtc < '2024-01-01';`.

---

## 15. Pagination: `OFFSET … FETCH` vs Keyset

```sql
DECLARE @PageNumber INT = 4, @PageSize INT = 20;

SELECT t.TaskId, t.Title, t.CreatedAtUtc
FROM   app.Tasks AS t
ORDER  BY t.CreatedAtUtc DESC, t.TaskId DESC        -- tiebreaker is mandatory in practice
OFFSET (@PageNumber - 1) * @PageSize ROWS
FETCH  NEXT @PageSize ROWS ONLY;
```

`OFFSET` requires `ORDER BY`; `FETCH` requires `OFFSET`; neither may be combined with `TOP` in the same query expression.

### Why `OFFSET` is O(n)

`OFFSET 500000` does not jump — the engine **produces and discards 500,000 rows** first. Page 1 is instant; page 25,000 reads half the table.

| Page | Rows produced | Rows returned |
|---|---|---|
| 1 | 20 | 20 |
| 100 | 2,000 | 20 |
| 25,000 | 500,020 | 20 |

There is a second, subtler defect: **result drift**. Insert a row between page 3 and page 4 and everything shifts by one — the user sees one row twice and never sees another.

### Keyset (seek) pagination

Instead of "skip N rows", say "give me the rows *after this key*". Cost is constant per page.

```sql
-- Page 1
SELECT TOP (20) t.TaskId, t.Title, t.CreatedAtUtc
FROM   app.Tasks AS t ORDER BY t.CreatedAtUtc, t.TaskId;

-- Page N+1: the client passes back the last row's key
DECLARE @LastCreatedAtUtc DATETIME2(3) = '2025-06-20T11:00:00', @LastTaskId INT = 7;

SELECT TOP (20) t.TaskId, t.Title, t.CreatedAtUtc
FROM   app.Tasks AS t
WHERE  t.CreatedAtUtc >  @LastCreatedAtUtc
   OR (t.CreatedAtUtc =  @LastCreatedAtUtc AND t.TaskId > @LastTaskId)
ORDER  BY t.CreatedAtUtc, t.TaskId;
```

With an index on `(CreatedAtUtc, TaskId)` this is one **Index Seek** plus a 20-row range scan — identical cost for page 1 and page 25,000.

| | `OFFSET … FETCH` | Keyset / seek |
|---|---|---|
| Cost of page N | O(N × pageSize) | O(pageSize) |
| Jump to an arbitrary page | Yes | No — next/prev only |
| Total page count | Easy (`COUNT(*)`) | Needs a separate count |
| Stable under concurrent inserts | No | Yes |
| Index requirement | Helpful | **Mandatory**, on the exact sort key |
| Good for | Admin grids, small tables | Infinite scroll, public APIs, large tables |

> **Portability:** PostgreSQL and MySQL support the row-constructor form `WHERE (created_at, id) > (@a, @b)`, which is shorter and easier for the optimiser. **T-SQL has no row-value comparison** — you must expand it as above.

The plain `OR` form can produce a poor plan. This rewrite gives the optimiser a clean seek predicate plus a residual:

```sql
WHERE t.CreatedAtUtc >= @LastCreatedAtUtc
  AND (t.CreatedAtUtc >  @LastCreatedAtUtc OR t.TaskId > @LastTaskId)
```

> **Rule of thumb:** Any paged query must end its `ORDER BY` with a **unique** column. `ORDER BY t.PriorityId OFFSET 20 ROWS …` lets ties resolve differently on each call, so a row can appear on two consecutive pages. Without a tiebreaker, pagination is a lottery.

Also match the index to the sort **direction** — `(CreatedAtUtc DESC, TaskId DESC)` for a descending feed — and make the cursor token you hand to clients **opaque** (base64, ideally signed), so callers cannot forge it into an enumeration vector.

---

## 16. `SELECT` Without `FROM`

A `FROM`-less `SELECT` returns exactly one row and is the fastest way to test an expression:

```sql
SELECT 7 / 2            AS IntegerDivision,   -- 3
       7.0 / 2          AS DecimalDivision,   -- 3.500000
       SYSUTCDATETIME() AS NowUtc,
       DB_NAME()        AS CurrentDatabase,
       CASE WHEN NULL = NULL THEN 'equal' ELSE 'not equal (UNKNOWN)' END AS NullComparison;
```

> **Portability:** Oracle requires `FROM DUAL`. PostgreSQL, MySQL, SQLite and SQL Server all allow a bare `SELECT`.

---

## 17. SARGability — Filtering on Computed Expressions

**SARGable** = *Search ARGument able* = the predicate can become an index seek. The rule:

> Wrap the **column** in a function or expression and you lose the seek. Wrap the **literal** and you keep it.

| Non-SARGable | SARGable rewrite |
|---|---|
| `WHERE YEAR(t.CreatedAtUtc) = 2025` | `WHERE t.CreatedAtUtc >= '2025-01-01' AND t.CreatedAtUtc < '2026-01-01'` |
| `WHERE CAST(t.CompletedAtUtc AS DATE) = '2024-02-28'` | `>= '2024-02-28' AND < '2024-02-29'` |
| `WHERE t.EstimatedHours * 2 > 40` | `WHERE t.EstimatedHours > 20` |
| `WHERE LEFT(p.ProjectCode, 3) = 'TF-'` | `WHERE p.ProjectCode LIKE 'TF-%'` |
| `WHERE ISNULL(t.StoryPoints, 0) > 5` | `WHERE t.StoryPoints > 5` (`NULL` is excluded anyway) |
| `WHERE DATEDIFF(DAY, t.DueDate, @today) > 30` | `WHERE t.DueDate < DATEADD(DAY, -30, @today)` |
| `WHERE u.Email LIKE N'%@taskflow.io'` | Reversed computed column, or a full-text index |

Both forms of the first row return the same 21 rows. On 35 rows the difference is invisible; on 35 million it is 4 ms versus 40 seconds.

When the expression is genuinely needed, index the expression: a **persisted computed column** plus an index on it, or an **indexed view**. `app.Users.FullName` is exactly that pattern, and it is indexable precisely because `FirstName + N' ' + LastName` is deterministic.

Related trap — **implicit conversion**. `app.Projects.ProjectCode` is `VARCHAR(10)`:

```sql
WHERE p.ProjectCode = N'TF-CORE'   -- NVARCHAR literal: the COLUMN is converted
WHERE p.ProjectCode =  'TF-CORE'   -- matching type: clean seek
```

Data type precedence puts `NVARCHAR` above `VARCHAR`, so SQL Server converts the *column*. With a Windows collation the optimiser can often still seek (internal `GetRangeThroughConvert`); with a legacy `SQL_*` collation it cannot. This bites hardest from ORMs — .NET strings default to `NVARCHAR` unless you tell Dapper or EF Core otherwise.

---

## 18. Reading an Execution Plan for a Filter

```sql
SET STATISTICS IO, TIME ON;
CREATE NONCLUSTERED INDEX IX_Tasks_Status_Due ON app.Tasks (StatusId, DueDate) INCLUDE (Title);

SELECT t.TaskId, t.Title, t.DueDate FROM app.Tasks AS t WHERE t.StatusId = 3;               -- A: seek, covered
SELECT t.TaskId, t.Title, t.DueDate, t.PriorityId FROM app.Tasks AS t WHERE t.StatusId = 3; -- B: seek + key lookup
SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.DueDate < '2025-09-01';                -- C: scan

DROP INDEX IX_Tasks_Status_Due ON app.Tasks;
SET STATISTICS IO, TIME OFF;
```

> On 35 rows SQL Server will often scan regardless — a scan of one page beats a seek plus lookups. Read the plans for **shape**, not cost. Topic 13 revisits this at realistic volumes.

| Operator | Meaning | When it is fine |
|---|---|---|
| **Index Seek** | Navigated the B-tree to a range | Almost always what you want |
| **Index Scan** | Read every row of the index | Small tables, or returning most rows |
| **Clustered Index Scan / Table Scan** | Read the whole table / heap | Suspicious with a selective filter |
| **Key Lookup / RID Lookup** | Seek found the row but needed more columns | Fine for few rows; deadly in a loop over thousands |
| **Sort** | An explicit sort was required | Expensive; could an index supply the order? |
| **Filter** | A predicate applied *after* reading | Often a residual that could not be seeked |

Four things to read every time:

- **Seek Predicate vs Predicate.** A *Seek Predicate* narrows the B-tree range; a *Predicate* (residual) is applied to every row the seek returned. Seeking 4 million rows and residual-filtering to 12 looks like a seek and performs like a scan. `LIKE N'Fix%bug'` produces both.
- **Estimated vs Actual rows.** A large gap means stale statistics, a non-SARGable predicate the optimiser could not estimate, or parameter sniffing.
- **Arrow thickness** is row count. A thick arrow feeding a thin one means you read a lot to return a little.
- **`SET STATISTICS IO` logical reads.** This is the number to optimise — it is deterministic, unlike elapsed time. The green **Missing Index** hint is a starting point, never a design: it ignores existing indexes and write cost, and over-suggests `INCLUDE` columns.

---

## 19. Portability Summary

| Concern | SQL Server | PostgreSQL | MySQL | Oracle |
|---|---|---|---|---|
| Row limiting | `TOP (n)`, `OFFSET…FETCH` | `LIMIT n OFFSET m` | `LIMIT m, n` | `FETCH FIRST n ROWS ONLY` (12c+) |
| Alias in `WHERE` | No | No | No | No |
| Alias in `GROUP BY` | No | Yes | Yes | No |
| Alias in `ORDER BY` | Yes | Yes | Yes | Yes |
| NULLs in `ORDER BY ASC` | First | Last | First | Last |
| `NULLS FIRST/LAST` clause | No | Yes | No | Yes |
| `LIKE` case sensitivity | Collation (usually CI) | Case-sensitive; `ILIKE` for CI | Collation (usually CI) | Case-sensitive |
| `[a-z]` in `LIKE` | Yes | No (use `~` regex) | No (use `REGEXP`) | No (use `REGEXP_LIKE`) |
| Row-value comparison `(a,b) > (c,d)` | **No** | Yes | Yes | Yes |
| `SELECT` without `FROM` | Yes | Yes | Yes | `FROM DUAL` |
| Empty string | A real value | A real value | A real value | `''` **is** `NULL` |

---

## Mental Model

> A `SELECT` is a pipeline, not a sentence. Rows enter at `FROM`, are thinned by `WHERE`, reshaped by `SELECT`, de-duplicated by `DISTINCT`, sequenced by `ORDER BY`, and sliced by `TOP`/`OFFSET`. Names created late in the pipeline cannot be seen early in it — that one fact explains the alias rules, the `DISTINCT`/`ORDER BY` restriction, and half of T-SQL's error messages.
>
> Layered on top are two invariants. First, **`NULL` is unknown, not empty**: it makes `=` return neither true nor false, it poisons `NOT IN`, and it splits a filter and its complement so they no longer cover the whole table. Second, **a predicate is only fast if the column is left alone**: touch the column with a function, a cast, or a leading `%` and you have traded a seek for a scan.
>
> Everything else is a corollary. `>= @start AND < @endPlusOne` because datetimes carry time. `NOT EXISTS` because `NOT IN` lies. A unique tiebreaker in every paged `ORDER BY` because ties make pagination non-deterministic. Keyset instead of `OFFSET` because skipping rows still costs you reading them.

Move to [Practice Problems](./Practice-Problems.md).
