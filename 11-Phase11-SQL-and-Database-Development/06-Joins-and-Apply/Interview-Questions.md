# Topic 06: Joins & APPLY — Interview Questions

---

## Q1. What join types does SQL Server support, and what does each return?
**Answer:**

| Join | Returns |
|---|---|
| `CROSS JOIN` | Cartesian product — every left row paired with every right row. No `ON`. |
| `INNER JOIN` (`JOIN`) | Only pairs where the `ON` predicate is `TRUE`. |
| `LEFT OUTER JOIN` | All inner-join rows, **plus** unmatched left rows with NULLs on the right. |
| `RIGHT OUTER JOIN` | Mirror image of `LEFT`. |
| `FULL OUTER JOIN` | All inner-join rows, plus unmatched rows from **both** sides. |
| `CROSS APPLY` | Correlated join — right side evaluated per left row; keeps left rows that produced ≥ 1 row. |
| `OUTER APPLY` | Same, but keeps left rows that produced nothing, NULL-filled. |

A `SELF JOIN` is not a separate type — it is any of the above with a table joined to itself under two aliases.

Row counts on the seeded TaskFlow database make the difference concrete:

```sql
USE TaskFlowDb;
GO
-- 31 rows: only assigned tasks
SELECT COUNT(*) FROM app.Tasks AS t JOIN      app.TaskAssignments AS ta ON ta.TaskId = t.TaskId;
-- 39 rows: 31 + the 8 deliberately unassigned tasks
SELECT COUNT(*) FROM app.Tasks AS t LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId;
```

---

## Q2. Conceptually, how does a join work?
**Answer:**
Logically, every join produces the **Cartesian product** of its inputs and then filters it by the `ON` predicate. Outer joins add a third step: any preserved-side row that survived no pair is re-added with NULLs on the other side.

```
FROM A LEFT JOIN B ON p
  1. A x B
  2. keep pairs where p is TRUE   (UNKNOWN is not TRUE — NULL keys never match)
  3. re-add rows of A that appear in no surviving pair, with B's columns NULL
```

The engine never materialises the product — it picks Nested Loops, Merge, or Hash instead — but this model is what explains the two things people get wrong: why a NULL key matches nothing (step 2 needs `TRUE`, and `NULL = NULL` is `UNKNOWN`) and why `ON` and `WHERE` differ for outer joins (`ON` acts at step 2, `WHERE` acts after step 3).

---

## Q3. What is the difference between putting a predicate in `ON` versus `WHERE` on a `LEFT JOIN`?
**Answer:**
`ON` decides **what counts as a match**; `WHERE` filters the result **after** unmatched rows have been re-added. A predicate on the null-supplying table placed in `WHERE` therefore eliminates every NULL-filled row and silently converts the `LEFT JOIN` into an `INNER JOIN`.

```sql
-- (a) In ON: task 33 (unassigned) survives.  3 rows.
SELECT t.TaskId, u.FullName
FROM app.Tasks AS t
LEFT JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
LEFT JOIN app.Users           AS u  ON u.UserId  = ta.UserId
                                   AND u.CountryCode = 'GB'
WHERE t.ProjectId = 8;

-- (b) In WHERE: task 33 disappears.  2 rows.
--     NULL <> 'GB' is UNKNOWN, so the outer row is filtered out.
... WHERE t.ProjectId = 8 AND u.CountryCode = 'GB';
```

The same trap appears without moving anything into `WHERE`: if you `LEFT JOIN app.TaskAssignments` and then `INNER JOIN app.Users` on `ta.UserId`, the inner join downstream kills the NULL rows just as effectively. **Once you go outer, stay outer down the whole chain.**

The one legitimate `WHERE` predicate on the null-supplying side is the anti-join test `WHERE ta.TaskId IS NULL`.

---

## Q4. When is a `CROSS JOIN` the right answer, and when is it a bug?
**Answer:**
**Deliberate:** when you need a dense grid — every combination must appear in the output even where no data exists.

```sql
-- 8 projects x 7 statuses = 56 rows, no holes in the UI grid
SELECT p.ProjectCode, s.StatusCode, COUNT(t.TaskId) AS Tasks
FROM app.Projects          AS p
CROSS JOIN ref.TaskStatuses AS s
LEFT JOIN app.Tasks         AS t ON t.ProjectId = p.ProjectId
                                AND t.StatusId  = s.StatusId
GROUP BY p.ProjectCode, s.StatusCode;
```

Other legitimate uses: date spines from a numbers table, test-data generation, configuration matrices.

**Accidental:** an omitted join predicate. `FROM app.Tasks t, app.TaskAssignments ta` with no `WHERE` returns 35 × 31 = 1085 rows. This is the strongest argument against ANSI-89 comma syntax: with `JOIN … ON`, forgetting the predicate is a **compile error**; with commas it is a silent Cartesian product.

---

## Q5. Give a real use case for `FULL OUTER JOIN`.
**Answer:**
Reconciliation — comparing two sets where either side may have orphans, and you need all three buckets in one pass.

```sql
SELECT
    CASE WHEN ta.TaskId IS NULL THEN 'TimeWithoutAssignment'
         WHEN te.TaskId IS NULL THEN 'AssignedNoTimeLogged'
         ELSE 'Both' END AS Bucket,
    COUNT(*) AS Pairs
FROM (SELECT DISTINCT TaskId, UserId FROM app.TaskAssignments) AS ta
FULL OUTER JOIN (SELECT DISTINCT TaskId, UserId FROM app.TimeEntries) AS te
       ON te.TaskId = ta.TaskId AND te.UserId = ta.UserId
GROUP BY CASE WHEN ta.TaskId IS NULL THEN 'TimeWithoutAssignment'
              WHEN te.TaskId IS NULL THEN 'AssignedNoTimeLogged'
              ELSE 'Both' END;
```

Typical production uses: comparing a source system against a target after an ETL run, diffing two snapshots of the same table, and matching payments against invoices.

Note the classification pattern: test the *key* column for NULL, never a nullable data column — otherwise a genuine NULL in the data is indistinguishable from a non-match.

Portability: MySQL has no `FULL OUTER JOIN`; emulate with `LEFT JOIN … UNION … RIGHT JOIN`.

---

## Q6. What is a self join and when do you need one?
**Answer:**
A table joined to itself under two aliases. It is required whenever a row relates to another row in the same table.

`app.Users.ManagerId` is a self-reference, so the org chart is a self-join:

```sql
SELECT e.FullName AS Employee, m.FullName AS Manager
FROM app.Users AS e
LEFT JOIN app.Users AS m ON m.UserId = e.ManagerId;
-- 20 rows. INNER JOIN would return 18 — Ada Lovelace and Guido van Rossum have no manager.
```

The other use is comparing rows within a table, and there the inequality is mandatory:

```sql
-- Pairs of tasks in the same project sharing a due date.
-- Without 'b.TaskId > a.TaskId' you get self-pairs plus every pair twice.
FROM app.Tasks AS a
JOIN app.Tasks AS b ON b.ProjectId = a.ProjectId
                   AND b.DueDate   = a.DueDate
                   AND b.TaskId    > a.TaskId
```

Limitation to state up front: a self join walks a **fixed** number of levels — one alias per level. For arbitrary depth (full reporting chain, sub-task tree via `app.Tasks.ParentTaskId`) you need a recursive CTE.

---

## Q7. `NOT IN` vs `NOT EXISTS` vs `LEFT JOIN … IS NULL` — which do you use?
**Answer:**
All three express an anti-join, but they are **not** equivalent when the subquery column is nullable.

`x NOT IN (a, b, NULL)` expands to `x <> a AND x <> b AND x <> NULL`. The last term is `UNKNOWN`, so the conjunction can never be `TRUE`. **A single NULL makes `NOT IN` return zero rows.**

```sql
-- Individual contributors: users nobody reports to.
-- ManagerId is NULL for Ada and Guido -> this returns 0 ROWS. Silently.
SELECT u.UserId FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);

-- Correct: 13 rows.
SELECT u.UserId FROM app.Users AS u
WHERE NOT EXISTS (SELECT 1 FROM app.Users AS m WHERE m.ManagerId = u.UserId);
```

| Approach | NULL-safe | Plan | Verdict |
|---|---|---|---|
| `NOT EXISTS` | Yes | Anti-semi-join, short-circuits | **Default choice** |
| `LEFT JOIN … IS NULL` | Yes | Usually the identical anti-semi-join | Fine, slightly noisier to read |
| `NOT IN` | **No** over a nullable column | Adds a null-handling branch | Only over `NOT NULL` columns |
| `EXCEPT` | Yes | Distinct + anti-join | For whole-result-set comparison |

On modern SQL Server, `NOT EXISTS` and `LEFT JOIN … IS NULL` normally compile to the same plan, so the choice is about readability. `NOT IN` over a nullable column is both incorrect *and* slower, because the engine has to implement the three-valued logic.

---

## Q8. What are semi-joins and anti-joins?
**Answer:**
A **semi-join** returns rows of the left input for which *at least one* match exists on the right — without duplicating them and without returning any right-side columns. An **anti-join** returns left rows for which *no* match exists.

T-SQL has no dedicated syntax; you write `EXISTS` / `NOT EXISTS` and the optimizer produces a physical `Left Semi Join` / `Left Anti Semi Join` operator.

```sql
-- Semi-join: users with at least one Critical task. 5 rows, no duplicates.
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE EXISTS (
    SELECT 1 FROM app.TaskAssignments AS ta
    JOIN app.Tasks AS t ON t.TaskId = ta.TaskId
    WHERE ta.UserId = u.UserId AND t.PriorityId = 1);
```

The equivalent `INNER JOIN` returns 6 rows, because Shafi Goldwasser is assigned to two Critical tasks — and then needs `DISTINCT` to repair. That is the argument for `EXISTS`: it expresses *existence*, cannot change the grain, and stops at the first match instead of enumerating all of them.

Use a join when you need **columns** from the other table; use `EXISTS` when you only need to know it is there.

---

## Q9. My join returns more rows than I expected. How do you diagnose it?
**Answer:**
Mechanically, in this order:

1. **State the intended grain.** "One row per task." Everything else tests that claim.
2. **Count rows per key** and find the offenders:
   ```sql
   SELECT t.TaskId, COUNT(*) AS Rows_
   FROM app.Tasks AS t
   JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId
   JOIN app.TimeEntries     AS te ON te.TaskId = t.TaskId
   GROUP BY t.TaskId HAVING COUNT(*) > 1;
   ```
3. **Remove joins one at a time** until the count is right. The last one removed is the culprit.
4. **Check each join's right-hand side.** Is the join column the *whole* primary key or a unique constraint? If yes, it is many-to-one and preserves the grain. If no, it is one-to-many and multiplies.
5. **Look for two independent one-to-many joins.** They multiply against each other — task 4 has 2 assignments and 3 time entries, so the join emits 6 rows and every `SUM(Hours)` doubles.
6. **Check for a missing column on a composite key.** Joining `app.TeamMembers` on `TeamId` alone, forgetting `UserId`, multiplies by team size.
7. **Check the source data** for duplicates, especially in staging tables with no unique constraint.
8. **Fix the cause:** pre-aggregate the child, use `OUTER APPLY` with `STRING_AGG`, or switch to `EXISTS` if you only needed existence.

The wrong fix is `SELECT DISTINCT`. It hides the duplication in the projected columns, leaves every aggregate in the query wrong, and adds a sort or hash to every future execution.

---

## Q10. What is `APPLY` and how does it differ from a `JOIN`?
**Answer:**
`APPLY` is a **correlated join**: the right-hand expression is evaluated once per left row and may reference that row's columns. A `JOIN`'s right-hand subquery cannot see the left row at all.

| | `CROSS APPLY` | `OUTER APPLY` |
|---|---|---|
| Left rows kept | Only those whose right side returned ≥ 1 row | All, NULL-filled when the right side returned nothing |
| Analogue | `INNER JOIN` | `LEFT JOIN` |

```sql
-- Latest time entry per task. Impossible as a plain JOIN without a window function.
SELECT t.TaskId, le.WorkDate, le.Hours
FROM app.Tasks AS t
OUTER APPLY (
    SELECT TOP (1) te.WorkDate, te.Hours
    FROM app.TimeEntries AS te
    WHERE te.TaskId = t.TaskId
    ORDER BY te.WorkDate DESC, te.TimeEntryId DESC   -- tie-breaker is mandatory
) AS le;
```

Four situations where `APPLY` is the right tool: top-N per group, calling a table-valued function per row (the only way), expanding JSON/XML/delimited strings with `OPENJSON`/`STRING_SPLIT`, and naming a computed expression once via `CROSS APPLY (VALUES (…))` so it can be reused in `SELECT`, `WHERE` and `ORDER BY`.

`APPLY` is executed as Nested Loops, so it is excellent with a small left input and an indexed right side, and poor with a large left input and an unindexed one. For simple correlated subqueries the optimizer often decorrelates into a hash join anyway — read the plan rather than assuming.

Portability: `CROSS APPLY` = `CROSS JOIN LATERAL`, `OUTER APPLY` = `LEFT JOIN LATERAL … ON TRUE`, in PostgreSQL 9.3+, Oracle 12c+ and MySQL 8.0.14+.

---

## Q11. How do you get the top N rows per group? Compare the approaches.
**Answer:**
Two idiomatic options.

```sql
-- (1) CROSS APPLY
SELECT p.ProjectCode, x.TaskId, x.Title
FROM app.Projects AS p
CROSS APPLY (
    SELECT TOP (2) t.TaskId, t.Title
    FROM app.Tasks AS t
    WHERE t.ProjectId = p.ProjectId
    ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC
) AS x;

-- (2) ROW_NUMBER in a CTE
WITH Ranked AS (
    SELECT t.ProjectId, t.TaskId, t.Title,
           ROW_NUMBER() OVER (PARTITION BY t.ProjectId
                              ORDER BY t.CreatedAtUtc DESC, t.TaskId DESC) AS rn
    FROM app.Tasks AS t
)
SELECT p.ProjectCode, r.TaskId, r.Title
FROM Ranked AS r
JOIN app.Projects AS p ON p.ProjectId = r.ProjectId
WHERE r.rn <= 2;
```

| | `CROSS APPLY` | `ROW_NUMBER()` |
|---|---|---|
| Plan shape | Nested Loops; one seek per group | One pass over the child, sort/segment, then filter |
| Wins when | Few groups, good index on `(ProjectId, CreatedAtUtc)` | Many groups, or you are scanning the child anyway |
| Ties | `TOP (2)` cuts arbitrarily — use `WITH TIES` if you want all ties | `RANK()`/`DENSE_RANK()` instead of `ROW_NUMBER()` keeps ties |
| Readability | States the intent directly | Requires understanding window frames |

Either way, **the `ORDER BY` must be deterministic**. `ORDER BY CreatedAtUtc DESC` alone is non-deterministic when two rows share a timestamp — add a unique tie-breaker.

---

## Q12. What is a non-equi join and what should you watch out for?
**Answer:**
Any join whose `ON` predicate is not a simple equality. The common case is a **range join** mapping a value onto bands:

```sql
SELECT p.PriorityCode, p.SlaHours, b.BandName
FROM ref.Priorities AS p
LEFT JOIN (VALUES (N'Same day',0,8), (N'Next day',8,24),
                  (N'This week',24,168), (N'Backlog',168,8760)
          ) AS b (BandName, MinHours, MaxHours)
    ON p.SlaHours >= b.MinHours
   AND p.SlaHours <  b.MaxHours;
```

Three things to watch:

1. **Use half-open intervals.** `BETWEEN MinHours AND MaxHours` is inclusive on both ends, so `HIGH` (`SlaHours = 24`) matches both `Next day` and `This week` and the row silently duplicates. `>= min AND < max` is the only safe form.
2. **NULL never satisfies a range predicate.** The `NONE` priority has `SlaHours = NULL` and matches no band. `INNER JOIN` drops it; `LEFT JOIN` keeps it with a NULL band. Choosing between those is a business decision, not a technicality.
3. **A hash join is impossible.** Hashing requires equality, so range joins compile to Nested Loops (or occasionally Merge). That is fine against a four-row band table and catastrophic against a large one. Keep band tables tiny and index the lower bound.

---

## Q13. Does the order in which I write joins matter?
**Answer:**
For **inner** joins, no — they are commutative and associative, and the optimizer reorders them freely based on statistics. "Put the small table first" is folklore.

For **outer** joins, yes. `A LEFT JOIN B LEFT JOIN C` is not interchangeable with `A LEFT JOIN C LEFT JOIN B` when the `ON` predicates reference each other, and an inner join placed after an outer join constrains what the optimizer may reorder — and can nullify the outer join entirely (Q3).

Two related points worth raising:

- **Join elimination.** If a join exists only to validate a foreign key and no columns are selected from that table, SQL Server can remove it entirely — but only when the FK is **trusted** (created or re-enabled `WITH CHECK`). An untrusted FK, common after a bulk load with `NOCHECK`, silently disables the optimisation. Audit with `sys.foreign_keys.is_not_trusted`.
- **Search-space limits.** With enough tables the optimizer stops exploring and takes the best plan it has. The plan's `StatementOptmEarlyAbortReason` property tells you whether it found a *Good Enough Plan* or hit a *Time Out* — the latter is a hint that the query is too complex and should be decomposed.

`OPTION (FORCE ORDER)` makes the written order binding. Use it to test a hypothesis, not to ship one.

---

## Q14. *(Senior)* Explain the three physical join operators and what each implies.
**Answer:**

| | **Nested Loops** | **Merge Join** | **Hash Match** |
|---|---|---|---|
| Algorithm | For each outer row, probe the inner input | Walk two sorted inputs in lockstep | Build a hash table from the smaller input, probe with the larger |
| Best when | Small outer input **and** an index on the inner join key | Both inputs already sorted on the join key | Large inputs, no useful index or order |
| Join types | All, including non-equi | Equi-joins (`FULL OUTER` supported with sorted inputs) | **Equi-joins only** |
| Memory grant | Negligible | Small (large if a `Sort` is injected) | Significant; **spills to tempdb** when underestimated |
| Blocking | No | No; the feeding `Sort` blocks | Build phase blocks |
| Complexity | O(N × inner probe cost) | O(N + M) once sorted | O(N + M) |

How to read them in a plan:

- **Nested Loops with a large outer row count** → missing index on the inner join column, or a cardinality underestimate. This is the classic "the query was fast in dev" plan.
- **Hash Match where you expected Nested Loops** → the optimizer believes the input is large. Check statistics *before* reaching for a hint.
- **Merge Join preceded by a `Sort`** → the ordering you were counting on does not exist. An index in join-key order removes both the sort and its memory grant.
- **Adaptive Join** (SQL Server 2017+ batch mode, 2019 rowstore batch mode) defers the Hash/Loops decision to runtime. Seeing one means the optimizer knows its estimate is unreliable.

The habit that matters more than memorising the table: compare **estimated versus actual** rows on each operator. Nearly every bad join plan is a cardinality-estimation failure, not an algorithm failure.

---

## Q15. *(Senior)* When would you use a join hint?
**Answer:**
Almost never, and only with a documented expiry.

Three reasons:

1. A hint is a **permanent** answer to a **temporary** question — correct for the data distribution on the day you wrote it, and silently wrong two years later.
2. A join hint in the `FROM` clause **implicitly enables `FORCE ORDER` for the entire query**, freezing every other join too. Very few people expect this, and it is the usual cause of "I added one hint and three other queries got slower".
3. It masks the real defect: a stale statistic, a missing index, a non-sargable predicate, parameter sniffing, or a multi-statement TVF with a fixed row estimate.

Escalation order: update statistics → fix or add the index → make predicates sargable → simplify/decompose the query → `OPTIMIZE FOR` / `OPTION (RECOMPILE)` → Query Store plan forcing → *then* a hint.

If you do ship one, put a comment beside it recording the date, the symptom, the measurement that justified it, and a review trigger. `OPTION (RECOMPILE)` and Query Store forcing are both strictly better than a hard hint because they are reversible without a code deployment.

---

## Q16. *(Senior)* What is wrong with `FROM a, b WHERE …` and with `*=` / `=*`?
**Answer:**
**Comma joins (ANSI-89)** produce the same plan as `JOIN … ON` for inner joins, so the objection is not performance — it is failure mode. The join predicate lives in `WHERE` alongside the row filters, so deleting or forgetting one yields a silent Cartesian product instead of a syntax error. With `JOIN … ON`, an omitted `ON` is a compile error. Convert comma joins whenever you touch the file.

**`*=` and `=*`** were Sybase-inherited outer join operators:

```sql
-- FROM app.Tasks t, app.TaskAssignments ta WHERE t.TaskId *= ta.TaskId
```

They are ambiguous when mixed with `WHERE` predicates — there is no way to say "this predicate is part of the join" versus "this one filters the result" — which is exactly the distinction ANSI `ON`/`WHERE` was invented to make explicit. They required database compatibility level 80 and **do not work on SQL Server 2012 or later**. Oracle's `(+)` is the equivalent legacy syntax and is likewise superseded.

When migrating legacy code, rewrite them as `LEFT JOIN`/`RIGHT JOIN` and **re-test the results** — because of the ambiguity, the naive translation is not always equivalent.

---

## Q17. Someone says "I need to MERGE these two result sets." What do you clarify?
**Answer:**
Three unrelated concepts share the word, and the answer differs completely:

| They might mean | The actual construct |
|---|---|
| Combine rows from two queries vertically (more rows) | `UNION` / `UNION ALL` / `INTERSECT` / `EXCEPT` — set operators, Topic 08 |
| Combine columns from two tables horizontally (more columns) | A join |
| Upsert a target table from a source | The `MERGE` **statement**, Topic 10 |
| A physical operator they saw in a plan | **Merge Join** — an algorithm, unrelated to the statement |

The distinguishing question: *"do you want more rows or more columns?"* More rows → set operator. More columns → join.

Worth adding: the `MERGE` statement has a long history of documented correctness and concurrency defects (race conditions without `HOLDLOCK`, incorrect trigger and constraint interactions). Many teams ban it in favour of explicit `UPDATE` + `INSERT` inside a transaction.

---

## Q18. *(Senior)* Inline versus multi-statement table-valued functions with `APPLY` — why does it matter?
**Answer:**

```sql
-- INLINE (RETURNS TABLE): a parameterised view. Expanded into the outer query,
-- so the optimizer sees through it and costs it with real statistics.
CREATE OR ALTER FUNCTION app.fn_TaskEffort (@TaskId INT)
RETURNS TABLE
AS
RETURN
    SELECT SUM(te.Hours) AS LoggedHours, COUNT(*) AS EntryCount
    FROM app.TimeEntries AS te
    WHERE te.TaskId = @TaskId;
```

A **multi-statement** TVF (`RETURNS @t TABLE (…) AS BEGIN … END`) is opaque. The optimizer cannot see inside, so it assumes a fixed cardinality — 1 row before SQL Server 2014, 100 rows after — regardless of reality. Called with `CROSS APPLY` over a large driving table, that underestimate produces a Nested Loops plan sized for a hundred rows and executed for a million. It is one of the most reliable ways to destroy a query's performance.

SQL Server 2017 added **interleaved execution** for multi-statement TVFs (the optimizer pauses, materialises the TVF, and uses the real count), and 2019 added **table-variable deferred compilation** — both mitigations, not cures, and both dependent on compatibility level.

A related subtlety with `CROSS APPLY`: the inline function above is a **scalar aggregate** with no `GROUP BY`, so it always returns exactly one row — even for a task with no time entries, where `LoggedHours` is NULL and `EntryCount` is 0. `CROSS APPLY` therefore keeps every left row. Add `GROUP BY te.TaskId` inside and childless tasks start disappearing. The `CROSS`/`OUTER` keyword is not the only thing controlling row survival.

Rule: write inline TVFs. If you think you need procedural logic in a function, you probably need a stored procedure or a rewrite.

---

## Q19. *(Senior)* A `LEFT JOIN` report has been silently dropping rows in production for months. How did that happen and how do you prevent it?
**Answer:**
The mechanism is almost always one of four:

1. A predicate on the null-supplying table drifted into `WHERE` — often added later by someone fixing a different bug.
2. An `INNER JOIN` was appended downstream of the `LEFT JOIN`, breaking the chain.
3. `NOT IN` over a column that became nullable in a later migration.
4. An aggregate switched from `COUNT(*)` to `COUNT(col)` — or the reverse — changing whether NULL-filled rows count.

None of these produce an error, a warning, or a plan change large enough to notice. Code review does not catch them because the SQL looks correct.

Prevention is engineering, not vigilance:

- **Assert cardinality in tests.** Every report query gets a test that pins the row count and one or two totals against a known fixture. A `LEFT JOIN` demoted to `INNER` changes the row count immediately.
- **Reconcile totals.** `SUM(LoggedHours)` across the report must equal `SELECT SUM(Hours) FROM app.TimeEntries`. One assertion catches fan-outs and dropped rows in the same test.
- **Encapsulate the join** in a view or inline TVF with the correct outer-join semantics, so callers cannot re-add a `WHERE` predicate on the wrong table.
- **Enforce NOT NULL** where the domain allows it, so `NOT IN` cannot break later. Where NULL is genuine, ban `NOT IN` by convention and lint for it.
- **Alert on row-count deltas.** A daily report that returns 8 % fewer rows than yesterday is worth a notification, whatever the cause.

---

## Q20. *(Architect)* When should joining happen in the database versus in application code?
**Answer:**
Default to the database. Joins are what a relational engine is optimised for: it has statistics, three physical algorithms, indexes, and parallelism. The application has none of those, and every row it joins in memory crossed the network first.

Join in the database when: the result is significantly smaller than its inputs (filtering or aggregating); the join keys are indexed; the data lives in one database; you need transactional consistency across the joined sets.

Join outside the database when: the sources are genuinely separate systems (SQL Server plus a search index plus a third-party API); one side is small, static and cacheable (reference data such as `ref.Priorities` and `ref.TaskStatuses`); the join would fan out a large result that you would immediately collapse in code anyway; or the "join" is really an enrichment against a service you do not own.

Specific to .NET and EF Core:

- **`Include` generates a join and therefore fans out.** Including two collections on one root duplicates the root's columns across the Cartesian product of both children. EF Core's `AsSplitQuery()` issues separate queries instead — correct row counts, more round trips, and no cross-query consistency unless you wrap it in a transaction.
- **Lazy loading is the N+1 problem** — one query for the list, one per item. It is the application-side fan-out, and it is worse than a database join in every dimension.
- **Projection beats materialisation.** `Select` into a DTO lets EF emit exactly the columns needed; loading full entities to read two fields ships whole rows across the wire.
- Push filtering and aggregation into SQL; do formatting, localisation and business rules in C#.

The failure mode to name explicitly: "we'll join in the service layer for flexibility" almost always becomes an N+1 loop under load. If the join must live outside the database, it needs a batch-fetch strategy (a dataloader keyed by id, or a single `WHERE id IN (…)` round trip) designed in from the start.
