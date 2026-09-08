# Topic 03: SELECT, Filtering & Sorting — Interview Questions

---

## Q1. What is the logical query processing order of a `SELECT`, and why does it matter?
**Answer:**
The order you *write* clauses is not the order the engine *reasons* about them:

| Step | Clause |
|---|---|
| 1 | `FROM` / `JOIN` / `APPLY` |
| 2 | `WHERE` |
| 3 | `GROUP BY` |
| 4 | `HAVING` |
| 5 | `SELECT` (aliases are created here) |
| 6 | `DISTINCT` |
| 7 | `ORDER BY` |
| 8 | `TOP` / `OFFSET … FETCH` |

It matters because scope follows this order. Anything created at step *n* is invisible to steps *before* `n`. It explains why `WHERE` cannot see a `SELECT` alias, why `HAVING` can reference aggregates but `WHERE` cannot, and why `ORDER BY` is the last thing evaluated before the slice.

This is **logical**, not physical, order. The optimiser is free to push predicates into an index seek, evaluate `TOP` early with a `TOP N Sort`, or reorder joins — as long as the observable result matches the logical model.

---

## Q2. Why can you use a column alias in `ORDER BY` but not in `WHERE`?
**Answer:**
Aliases are born in the `SELECT` clause, which is step 5. `WHERE` runs at step 2, before the alias exists. `ORDER BY` runs at step 7, after it exists.

```sql
-- FAILS: Msg 207, Invalid column name 'DaysLate'.
SELECT t.TaskId, DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)) AS DaysLate
FROM   app.Tasks AS t
WHERE  DaysLate > 30;

-- WORKS: ORDER BY runs after SELECT
SELECT t.TaskId, DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)) AS DaysLate
FROM   app.Tasks AS t
ORDER  BY DaysLate DESC;
```

The idiomatic T-SQL fix is `CROSS APPLY (VALUES (...))`, which defines the expression once and makes it visible to `WHERE`, `GROUP BY`, `SELECT` and `ORDER BY`:

```sql
SELECT t.TaskId, v.DaysLate
FROM   app.Tasks AS t
CROSS APPLY (VALUES (DATEDIFF(DAY, t.DueDate, CAST(SYSUTCDATETIME() AS DATE)))) AS v(DaysLate)
WHERE  v.DaysLate > 30
ORDER  BY v.DaysLate DESC;
```

A CTE or derived table works equally well; `CROSS APPLY` composes better when you need several derived expressions.

---

## Q3. Why is `SELECT *` considered an anti-pattern in production code?
**Answer:**
Six concrete failure modes:

| Failure | Mechanism |
|---|---|
| Payload bloat | Adding `app.Tasks.Description` (`NVARCHAR(MAX)`) silently multiplies bytes on the wire |
| Ordinal binding breaks | `reader.GetString(3)` points at a different column after a schema change |
| Covering indexes stop covering | An index `(StatusId, DueDate) INCLUDE (Title)` covers a 3-column query, never `*` |
| Stale views | `CREATE VIEW … AS SELECT *` freezes the column list at creation time; new columns never appear until `sp_refreshview` |
| Data leakage | `SELECT * FROM app.Users` exposes `HourlyRate` to an endpoint that never asked for it |
| Silent `INSERT` misalignment | `INSERT INTO t SELECT * FROM s` breaks when column *order* changes |

Legitimate uses: ad-hoc exploration, `EXISTS (SELECT * FROM …)` where the list is never evaluated, and `COUNT(*)`.

---

## Q4. `WHERE a = 1 OR a = 2 AND b = 3` — what does this actually mean?
**Answer:**
`AND` binds tighter than `OR`, so it means `a = 1 OR (a = 2 AND b = 3)`. Full T-SQL precedence, highest first: arithmetic → comparison → `NOT` → `AND` → `OR`/`BETWEEN`/`IN`/`LIKE`.

```sql
-- Intent: "open or in-review tasks that are critical"
-- WRONG: returns every critical task, including completed ones
WHERE t.StatusId = 3 OR t.StatusId = 4 AND t.PriorityId = 1;

-- RIGHT
WHERE (t.StatusId = 3 OR t.StatusId = 4) AND t.PriorityId = 1;
```

Rule: if a predicate mixes `AND` and `OR`, parenthesise every `OR` group — even when precedence already agrees with you. The parentheses are documentation.

---

## Q5. Explain three-valued logic. Why does `WHERE HourlyRate = NULL` return nothing?
**Answer:**
`NULL` means *unknown*, so any comparison with it evaluates to **UNKNOWN**, not TRUE or FALSE. `WHERE` returns only rows where the predicate is **TRUE**, so UNKNOWN rows are dropped.

| `AND` | TRUE | FALSE | UNKNOWN |
|---|---|---|---|
| **TRUE** | TRUE | FALSE | UNKNOWN |
| **FALSE** | FALSE | FALSE | FALSE |
| **UNKNOWN** | UNKNOWN | FALSE | UNKNOWN |

| `OR` | TRUE | FALSE | UNKNOWN |
|---|---|---|---|
| **TRUE** | TRUE | TRUE | TRUE |
| **FALSE** | TRUE | FALSE | UNKNOWN |
| **UNKNOWN** | TRUE | UNKNOWN | UNKNOWN |

`NOT UNKNOWN` is still `UNKNOWN`, which is why a filter and its complement do not partition the table:

```sql
-- app.Users has 20 rows. These two counts sum to 19, not 20.
SELECT COUNT(*) FROM app.Users AS u WHERE u.HourlyRate > 100;
SELECT COUNT(*) FROM app.Users AS u WHERE u.HourlyRate <= 100;
-- Sophie Wilson (UserId 19) has a NULL HourlyRate and matches neither.
```

The only reliable test is `IS NULL` / `IS NOT NULL`. Note the deliberate inconsistency in the standard: `WHERE` treats `NULL = NULL` as unknown, but `GROUP BY`, `DISTINCT` and `UNION` treat two `NULL`s as the *same* value.

`SET ANSI_NULLS OFF` makes `= NULL` behave like `IS NULL`. It is deprecated, it breaks indexed views and computed-column indexes, and you should never rely on it.

---

## Q6. Is `BETWEEN` inclusive? What is the classic bug with it?
**Answer:**
Yes — `x BETWEEN lo AND hi` is exactly `x >= lo AND x <= hi`, both endpoints included. `lo` must be `<= hi` or you get zero rows.

The classic bug is using it on a column with a time component. `app.Tasks.CompletedAtUtc` is `DATETIME2(3)`, and a bare date literal means **midnight**:

```sql
-- BUG: silently drops anything completed after 00:00 on the 28th
WHERE t.CompletedAtUtc BETWEEN '2024-02-01' AND '2024-02-28';
-- TaskId 1 completed at 2024-02-28T16:40:00 is excluded.
```

The popular "fixes" are also wrong: `23:59:59` loses sub-second rows; `23:59:59.997` is a `DATETIME`-specific magic number that is wrong for `DATETIME2`; `CAST(col AS DATE)` gives correct results but destroys SARGability.

The correct pattern is a **half-open interval**, which is right for every precision and stays seekable:

```sql
WHERE t.CompletedAtUtc >= '2024-02-01'
  AND t.CompletedAtUtc <  '2024-03-01';
```

`BETWEEN` on a pure `DATE` column such as `app.Tasks.DueDate` is safe — there is no time component to lose.

---

## Q7. Why can `NOT IN` return zero rows when you know matching rows exist?
**Answer:**
Because `NOT IN` expands to a chain of `<>` joined by `AND`. A single `NULL` in the list makes one comparison `UNKNOWN`, and `TRUE AND UNKNOWN = UNKNOWN`, which is not `TRUE`. Every row is dropped.

```sql
-- Returns ZERO rows: app.Teams has one row with a NULL LeadUserId.
SELECT u.UserId, u.FullName
FROM   app.Users AS u
WHERE  u.UserId NOT IN (SELECT tm.LeadUserId FROM app.Teams AS tm);
```

For `UserId = 9` the expansion is:

```
9 <> 4 AND 9 <> 5 AND … AND 9 <> NULL
TRUE   AND TRUE   AND … AND UNKNOWN     ->  UNKNOWN  ->  row dropped
```

Plain `IN` is far less dangerous because it expands to `OR`, and `TRUE OR UNKNOWN = TRUE`.

The fix is `NOT EXISTS`, which is `NULL`-safe by construction and expresses an anti-join directly:

```sql
SELECT u.UserId, u.FullName
FROM   app.Users AS u
WHERE  NOT EXISTS (SELECT 1 FROM app.Teams AS tm WHERE tm.LeadUserId = u.UserId);
```

Never write `NOT IN (<subquery>)`. Even if the inner column is `NOT NULL` today, it may not be after the next migration — and the failure is silent.

---

## Q8. When would you choose `IN`, `EXISTS`, or a `JOIN` for the same semi-join?
**Answer:**
For a **semi-join** (rows in A that have a match in B), `IN` and `EXISTS` are semantically identical and SQL Server usually produces the same plan — a Left Semi Join. Choose on readability:

```sql
-- IN: clean when the inner query returns a single column
WHERE t.ProjectId IN (SELECT p.ProjectId FROM app.Projects AS p WHERE p.IsArchived = 0)

-- EXISTS: required when correlating on multiple columns, and mandatory for the NOT case
WHERE EXISTS (SELECT 1 FROM app.TaskAssignments AS ta
              WHERE ta.TaskId = t.TaskId AND ta.IsPrimary = 1)
```

A `JOIN` is **not** equivalent: it is an inner join, so it multiplies rows when the right side has duplicates. `app.TaskAssignments` has two rows for `TaskId = 4`, so joining to it duplicates task 4. People then paper over the fan-out with `DISTINCT`, which hides the grain bug and adds a sort.

Rule: use a `JOIN` when you need **columns** from the other table; use `EXISTS`/`IN` when you only need to test **existence**. Use `NOT EXISTS` for the anti-join, always.

---

## Q9. What are the `LIKE` wildcards, and how do you search for a literal `%`?
**Answer:**

| Wildcard | Matches |
|---|---|
| `%` | Zero or more characters |
| `_` | Exactly one character |
| `[abc]` / `[a-f]` | One character from a set or range |
| `[^abc]` | One character not in the set |

Two ways to search for a literal metacharacter:

```sql
-- ESCAPE clause
SELECT c.CommentId, c.Body FROM app.Comments AS c
WHERE  c.Body LIKE N'%!%%' ESCAPE '!';

-- Character class (no ESCAPE needed)
SELECT c.CommentId, c.Body FROM app.Comments AS c
WHERE  c.Body LIKE N'%[%]%';
```

Both return the comment containing `above 5% flake rate`.

A common misconception: `LIKE N'%[^0-9]%'` does **not** mean "contains no digits" — it means "contains at least one non-digit". The negation you want is `NOT LIKE N'%[0-9]%'`.

Case sensitivity comes from the **collation**, not from `LIKE`. Under the usual `_CI_` collation, `LIKE N'fix%'` matches `Fix N+1 query…`. Forcing `COLLATE Latin1_General_CS_AS` in the predicate makes it case-sensitive but also non-SARGable. Fix the column's collation, not the query.

---

## Q10. `DISTINCT` vs `GROUP BY` — same thing?
**Answer:**
For the "unique values" case they produce identical results and, in SQL Server, usually identical plans (`Hash Match (Aggregate)` or `Stream Aggregate`).

```sql
SELECT DISTINCT t.StatusId FROM app.Tasks AS t;
SELECT t.StatusId FROM app.Tasks AS t GROUP BY t.StatusId;
```

They differ in intent and capability: `GROUP BY` runs at step 3 and lets you add aggregates and a `HAVING` clause; `DISTINCT` runs at step 6 and can only de-duplicate what `SELECT` already emitted.

Two things people get wrong:

1. `SELECT DISTINCT a, b` gives distinct **pairs**. There is no "distinct on one column" in ANSI SQL. (PostgreSQL's `DISTINCT ON` is a vendor extension; the portable equivalent is `ROW_NUMBER()` — Topic 09.)
2. `SELECT DISTINCT col … ORDER BY otherCol` fails with **Msg 145**, because after de-duplication `otherCol` no longer has a single value per output row.

The real red flag is `DISTINCT` added to make duplicates from a join disappear. Duplicates mean the join grain is wrong. `DISTINCT` hides the bug, adds a sort or hash, and will eventually produce a wrong `SUM`.

---

## Q11. Where do `NULL`s sort in `ORDER BY`, and how do you get "nulls last" in SQL Server?
**Answer:**
SQL Server treats `NULL` as lower than any value: **first** under `ASC`, **last** under `DESC`. There is no `NULLS FIRST` / `NULLS LAST` clause. Emulate it with a leading `CASE`:

```sql
SELECT t.TaskId, t.Title, t.DueDate
FROM   app.Tasks AS t
ORDER  BY CASE WHEN t.DueDate IS NULL THEN 1 ELSE 0 END,   -- NULLS LAST
          t.DueDate ASC;
```

Do **not** substitute a sentinel (`ISNULL(t.DueDate, '9999-12-31')`): it is non-SARGable, it makes the sentinel visible if you ever project the expression, and it breaks the moment a real row uses that value.

| Engine | Default in `ASC` | `NULLS FIRST/LAST` |
|---|---|---|
| SQL Server | First | Not supported |
| PostgreSQL | **Last** | Supported |
| Oracle | **Last** | Supported |
| MySQL | First | Not supported |

This is a genuine portability hazard: the same query returns a different row order on PostgreSQL than on SQL Server. If ordering is part of your API contract, make it explicit.

---

## Q12. What is wrong with `ORDER BY 2, 3`?
**Answer:**
Ordinals bind to **position** in the select list, not to a name. Insert a column at the front of the list and the query silently sorts by something else — no error, wrong report. Ordinals are also invisible to a codebase-wide search for the column name, and they make code review useless because the reviewer has to count columns.

```sql
-- Fragile
SELECT t.TaskId, t.PriorityId, t.DueDate FROM app.Tasks AS t ORDER BY 2, 3;

-- Robust
SELECT t.TaskId, t.PriorityId, t.DueDate FROM app.Tasks AS t ORDER BY t.PriorityId, t.DueDate;
```

The one place ordinals still show up is `UNION`, where alias resolution across branches is awkward — and even there, naming the first branch's aliases is better.

---

## Q13. Explain `TOP (n)`, `WITH TIES`, and `PERCENT`. Why is `TOP` without `ORDER BY` dangerous?
**Answer:**
`TOP (n)` limits the result to `n` rows *after* `ORDER BY`. `WITH TIES` additionally keeps every row whose `ORDER BY` key matches the last returned row:

```sql
SELECT TOP (2) WITH TIES t.TaskId, t.Title, t.EstimatedHours
FROM   app.Tasks AS t
WHERE  t.EstimatedHours IS NOT NULL
ORDER  BY t.EstimatedHours DESC;
-- Returns THREE rows: 60.00, then 40.00 and 40.00 (tasks 7 and 10 tie).
```

`WITH TIES` requires `ORDER BY`, considers only the `ORDER BY` columns, and can return arbitrarily more than `n` rows — never use it to fill a fixed-size buffer.

`TOP (10) PERCENT` returns 10% of the rows, always **rounded up** (10% of 35 = 3.5 → 4), and forces the engine to determine the full row count first.

`TOP` without `ORDER BY` is not "the first n rows" — there is no first. It is whichever rows the chosen plan happened to emit. Add an index, go parallel, or patch the engine and the answer changes, with no error and no warning. It is only defensible for `TOP (1)` existence checks and `TOP (0)` metadata tricks.

---

## Q14. How does `OFFSET … FETCH` work, and what is its cost profile?
**Answer:**
```sql
SELECT t.TaskId, t.Title, t.CreatedAtUtc
FROM   app.Tasks AS t
ORDER  BY t.CreatedAtUtc DESC, t.TaskId DESC
OFFSET (@PageNumber - 1) * @PageSize ROWS
FETCH  NEXT @PageSize ROWS ONLY;
```

`OFFSET` requires `ORDER BY`; `FETCH` requires `OFFSET`; you cannot combine it with `TOP` in the same query expression.

Cost is **O(offset)**, not O(1). The engine produces and discards every skipped row:

| Page | Rows produced | Rows returned |
|---|---|---|
| 1 | 20 | 20 |
| 100 | 2,000 | 20 |
| 25,000 | 500,020 | 20 |

There is a second defect that has nothing to do with speed: **result drift**. If a row is inserted between the request for page 3 and page 4, every subsequent row shifts by one — the user sees one row twice and never sees another. Offset pagination is only stable against a snapshot that does not exist.

Finally, `OFFSET … FETCH` is non-deterministic unless the `ORDER BY` ends with a **unique** column. Ordering only by `PriorityId` means ties can be resolved differently on each call, so a row can appear on two consecutive pages.

---

## Q15. Implement keyset (seek) pagination in T-SQL. Why can't you use row-value comparison?  *(Senior)*
**Answer:**
Keyset pagination replaces "skip N rows" with "give me the rows after this key". Cost is constant per page.

```sql
-- Page 1
SELECT TOP (20) t.TaskId, t.Title, t.CreatedAtUtc
FROM   app.Tasks AS t
ORDER  BY t.CreatedAtUtc, t.TaskId;

-- Page N+1: the client returns the last row's key
DECLARE @LastCreatedAtUtc DATETIME2(3) = '2025-06-20T11:00:00',
        @LastTaskId       INT          = 7;

SELECT TOP (20) t.TaskId, t.Title, t.CreatedAtUtc
FROM   app.Tasks AS t
WHERE  t.CreatedAtUtc >  @LastCreatedAtUtc
   OR (t.CreatedAtUtc =  @LastCreatedAtUtc AND t.TaskId > @LastTaskId)
ORDER  BY t.CreatedAtUtc, t.TaskId;
```

PostgreSQL and MySQL support the row-constructor form, which is shorter and easier for the optimiser:

```sql
WHERE (created_at, id) > (:lastCreatedAt, :lastId)   -- not valid T-SQL
```

**T-SQL has no row-value comparison**, so you must expand it. The plain `OR` form sometimes produces a scan; the reliable rewrite gives the optimiser a clean seek predicate plus a residual:

```sql
WHERE t.CreatedAtUtc >= @LastCreatedAtUtc
  AND (t.CreatedAtUtc > @LastCreatedAtUtc OR t.TaskId > @LastTaskId)
```

| | `OFFSET … FETCH` | Keyset |
|---|---|---|
| Cost of page N | O(N × pageSize) | O(pageSize) |
| Jump to arbitrary page | Yes | No — next/prev only |
| Total page count | Easy | Needs a separate `COUNT(*)` |
| Stable under concurrent inserts | No | Yes |
| Index requirement | Helpful | **Mandatory**, on the exact sort key |
| Fits | Admin grids, small tables | Infinite scroll, public APIs, large tables |

Two design notes. The supporting index must match the sort *including direction* — `(CreatedAtUtc DESC, TaskId DESC)` for a descending feed — or the engine adds a sort. And the cursor token you hand to clients should be **opaque** (base64 of the key tuple, ideally signed), so callers cannot forge it into an enumeration or data-leak vector.

---

## Q16. A query filtering `WHERE p.ProjectCode = N'TF-CORE'` does a scan instead of a seek. Why?  *(Senior)*
**Answer:**
`app.Projects.ProjectCode` is `VARCHAR(10)`. The literal `N'TF-CORE'` is `NVARCHAR`. Data type precedence puts `NVARCHAR` **above** `VARCHAR`, so SQL Server converts the *column*, not the literal:

```
CONVERT_IMPLICIT(nvarchar(10), [p].[ProjectCode], 0) = N'TF-CORE'
```

Once a function wraps the column, the index on it is no longer directly seekable. With a **Windows** collation the optimiser can often rescue this with an internal `GetRangeThroughConvert` and still seek; with a legacy `SQL_*` collation it cannot, and you get a full scan of the table. Either way you should not rely on the rescue.

The fix is to match the types:

```sql
WHERE p.ProjectCode = 'TF-CORE';    -- VARCHAR literal, clean seek
```

This bug almost always arrives from application code, because .NET `string` maps to `NVARCHAR` by default:

- **Dapper:** `new { Code = new DbString { Value = code, IsAnsi = true, Length = 10 } }`, or `p.Add("@Code", code, DbType.AnsiString, size: 10)`.
- **EF Core:** `builder.Property(p => p.ProjectCode).HasColumnType("varchar(10)")` or `.IsUnicode(false).HasMaxLength(10)`.
- **ADO.NET:** `SqlDbType.VarChar`, not `SqlDbType.NVarChar`.

The general principle is broader than strings: any implicit conversion on the **column side** of a predicate — `INT` column vs `VARCHAR` parameter, `DATE` column vs `DATETIME` parameter — is a potential index killer. Look for `CONVERT_IMPLICIT` in the plan XML and for the "Type conversion in expression may affect CardinalityEstimate" warning.

---

## Q17. A report must filter on `YEAR(CreatedAtUtc)`. You cannot change the query. How do you make it fast?  *(Senior)*
**Answer:**
Four mechanisms, in the order I would consider them:

**1. Persisted computed column + index.** Materialise the expression and index it:

```sql
ALTER TABLE app.Tasks ADD CreatedYear AS (YEAR(CreatedAtUtc)) PERSISTED;
CREATE NONCLUSTERED INDEX IX_Tasks_CreatedYear ON app.Tasks (CreatedYear) INCLUDE (Title);
```

SQL Server will **match the expression automatically**: a query written as `WHERE YEAR(t.CreatedAtUtc) = 2025` can seek on `IX_Tasks_CreatedYear` without being rewritten. That is the key property — it fixes queries you do not control. It requires the expression to be deterministic and precise, and requires the standard `SET` options (`ANSI_NULLS`, `QUOTED_IDENTIFIER`, `ARITHABORT`, etc.) to be on. `app.Users.FullName` in the sample database is this pattern.

**2. Non-persisted computed column + index.** The index materialises the value even without `PERSISTED`; you only need `PERSISTED` when the expression is imprecise (floating point) or when you need it as a `CHECK`/FK/PK participant.

**3. Indexed view.** Use when the expression spans a join or an aggregate. Requires `WITH SCHEMABINDING`, deterministic expressions, a unique clustered index, and `COUNT_BIG(*)` if aggregating. Expensive on writes; auto-matching is Enterprise/Azure only (elsewhere you need `WITH (NOEXPAND)`).

**4. Filtered index.** If the report only ever wants one slice, index the slice:

```sql
CREATE NONCLUSTERED INDEX IX_Tasks_Open ON app.Tasks (DueDate)
    INCLUDE (Title) WHERE StatusId NOT IN (6, 7);
```

Filtered indexes are small and cheap, but the optimiser only uses one when it can prove the query predicate implies the filter — which usually means literals, not parameters, unless you add `OPTION (RECOMPILE)`.

The cost side must be stated too: every one of these adds write amplification and storage. The default answer remains "rewrite the predicate to be SARGable"; these are what you reach for when you genuinely cannot.

---

## Q18. Walk me through diagnosing a filtered query that suddenly got slow.  *(Architect)*
**Answer:**
A repeatable sequence, cheapest signal first:

**1. Get the actual plan and I/O.** `SET STATISTICS IO, TIME ON` plus the actual execution plan. Optimise **logical reads** — they are deterministic; elapsed time is not.

**2. Find the fat arrow.** Arrow thickness is row count. A thick arrow feeding a thin one means you read a lot to return a little: either the filter is not being applied at the storage engine, or the index is wrong.

**3. Classify the access operator.**

| Operator | Reading |
|---|---|
| Index Seek | Navigated the B-tree to a range — usually what you want |
| Index Scan | Read the whole index; fine if you return most rows |
| Clustered Index Scan / Table Scan | Read the whole table; suspicious with a selective filter |
| Key Lookup / RID Lookup | Seek found the row but needed more columns; deadly at scale |
| Sort | Could an index have provided this order? |
| Filter | A residual predicate applied after reading |

**4. Separate Seek Predicate from Predicate.** A *Seek Predicate* narrows the B-tree range. A *Predicate* (residual) is applied to every row the seek returned. Seeking 4 million rows and residual-filtering to 12 looks like a seek and performs like a scan.

**5. Compare estimated vs actual rows.** A large gap points to stale statistics, a non-SARGable predicate the optimiser cannot estimate, parameter sniffing, or a local variable (which forces density-vector guesses).

**6. Ask "what changed?"** Data volume crossing a tipping point, statistics going stale after a bulk load, a plan recompiled under an atypical parameter (sniffing), an index dropped, or a deployment that added `N'...'` literals against `VARCHAR` columns. Check Query Store: `sys.query_store_plan` will show you the regression and let you force the good plan.

**7. Only then change something.** In order of preference: fix the predicate (SARGability, half-open date ranges, `NOT EXISTS`), fix the projection (stop selecting columns that force lookups), fix the index (covering, correct key order, correct sort direction), and last, hint or force a plan. The Missing Index recommendation in the plan is a starting point, never a design — it ignores existing indexes, ignores write cost, and over-suggests `INCLUDE` columns.

---

## Q19. Design the SQL-side contract for a public "list tasks" API that must be stable, cacheable, and multi-tenant.  *(Architect)*
**Answer:**
Six decisions, each with a SQL consequence:

**1. Ordering is part of the contract.** Publish the sort key and always terminate it with a unique column (`ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC`). Without a tiebreaker the same request can return different rows on two calls, which makes the response uncacheable and makes pagination lossy.

**2. Collation is part of the contract.** `ORDER BY Title` returns a different sequence under `Latin1_General_CI_AS`, `Latin1_General_BIN2`, and a Japanese collation — and `van Rossum` sorts in a different place in each. Pin the collation explicitly in the schema, document it, and never let it be inherited from whatever the restore created.

**3. `NULL` ordering is part of the contract.** SQL Server puts `NULL`s first ascending; PostgreSQL puts them last. If you ever intend to run on both, emulate explicitly with `CASE WHEN col IS NULL THEN 1 ELSE 0 END` so the contract does not depend on the engine.

**4. Pagination style follows the access pattern.** Keyset for the public feed (constant cost, immune to result drift, cursor is a natural ETag component); offset only for internal admin grids that genuinely need "jump to page 40". If you must expose both, expose them as different endpoints, not a flag.

**5. Tenancy is a predicate, not a convention.** Filter by tenant in the *database*, not in the service layer: a `TenantId` leading column on every index, plus Row-Level Security as a defence-in-depth backstop so a forgotten `WHERE` clause cannot leak data cross-tenant. The leading column also makes every tenant's queries seek instead of scan.

**6. Projection is a versioned contract.** Explicit column lists, never `SELECT *`. Adding a column must be an additive, opt-in change; `SELECT *` makes every schema change a breaking API change and turns a covering index into a lookup storm.

Two supporting points. Cache keys should be derived from `(tenant, filter, sortKey, cursor, pageSize)` — which is only well-defined if ordering is deterministic, closing the loop with point 1. And filters exposed to callers must map to **parameterised**, SARGable predicates over indexed columns; a `search=%foo%` parameter that the caller controls is simultaneously a performance DoS and, if concatenated rather than parameterised, an injection vector (Topic 19).
