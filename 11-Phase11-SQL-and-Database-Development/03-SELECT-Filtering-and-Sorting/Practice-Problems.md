# Topic 03: SELECT, Filtering & Sorting — Practice Problems

> Seven exercises that turn the Notes into muscle memory. Every problem runs against the shared **TaskFlowDb** sample database and every deliverable is a `.sql` file you commit alongside your solution. The first two are warm-ups; P6 and P7 are the ones an interviewer will actually ask you to whiteboard.

**Concept tags:** `select` `projection` `aliases` `where` `predicates` `three-valued-logic` `between` `in` `like` `distinct` `order-by` `top` `pagination` `keyset` `sargability` `execution-plans`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Starter files live in [PracticeProblemsSolutions](./PracticeProblemsSolutions). Each one restates the problem and contains a `-- TODO`. Fill them in; do not rename them.

---

## P1 — The Task Board Projection  *(Easy)*

**Tags:** `select` `projection` `aliases` `table-aliases` `select-star`

The TaskFlow web client calls `GET /api/board`. The front-end DTO is:

```ts
interface BoardCard {
  taskId: number;
  title: string;
  projectCode: string;
  statusName: string;
  priorityName: string;
  dueDate: string | null;
}
```

### Requirements

1. Write one `SELECT` that returns **exactly** those six columns, in that order, aliased to match the DTO property names (`TaskId`, `Title`, `ProjectCode`, `StatusName`, `PriorityName`, `DueDate`).
2. Source the data from `app.Tasks`, `app.Projects`, `ref.TaskStatuses` and `ref.Priorities`.
3. Alias every table with a short alias and **qualify every column**.
4. Write the same query twice: once using `expr AS alias`, once using the T-SQL `alias = expr` form. Add a comment explaining which you would put in the repository and why.
5. Add a final commented-out `SELECT *` version and, in a comment block, list **three** concrete failures that would occur if it shipped.

### Deliverable

`P1-board-projection.sql`

### Hints

- `ref.TaskStatuses` joins on `StatusId`; `ref.Priorities` joins on `PriorityId`.
- `app.Tasks.DueDate` is already `DATE` — no conversion needed.
- The DTO has no `Description`; `app.Tasks.Description` is `NVARCHAR(MAX)`. That is one of your three failures.

### Look-fors (rubric)

- [ ] Exactly six columns, named exactly as the DTO expects.
- [ ] Every table schema-qualified (`app.`, `ref.`) and aliased.
- [ ] Every column prefixed with its table alias — zero bare column names.
- [ ] Both alias forms present, with a stated preference and a reason.
- [ ] Three distinct `SELECT *` failure modes named (payload size, ordinal binding, covering index, view staleness, data leakage — any three).

---

## P2 — The Overdue Filter  *(Easy)*

**Tags:** `where` `comparison-operators` `precedence` `bit` `parentheses`

Product wants an "Attention Required" list: tasks that are **not finished** and are **either overdue or critical**.

### Requirements

1. Define "not finished" using `ref.TaskStatuses.IsTerminal`, not a hard-coded list of status IDs.
2. Define "overdue" as `DueDate` strictly before today (`CAST(SYSUTCDATETIME() AS DATE)`).
3. Define "critical" as `PriorityId = 1`.
4. Write the predicate **wrong first**: `IsTerminal = 0 AND DueDate < @today OR PriorityId = 1`. Run it, record the row count in a comment, and explain what it actually means.
5. Write the corrected, parenthesised version. Record its row count.
6. Explain in a comment why tasks with a `NULL` `DueDate` do not appear in the "overdue" half, and show a variant that treats undated tasks as *also* needing attention.

### Deliverable

`P2-overdue-filter.sql`

### Hints

- `AND` binds tighter than `OR`. The wrong version returns every critical task in the database, including completed ones.
- `t.DueDate < @today` is `UNKNOWN` when `DueDate IS NULL`, and `UNKNOWN` is not `TRUE`.
- `IsTerminal` is a `BIT`. Compare it to `0`, not to `FALSE`.

### Look-fors (rubric)

- [ ] Uses `ref.TaskStatuses.IsTerminal = 0` rather than `StatusId NOT IN (6,7)`.
- [ ] Both the wrong and right versions present, with actual row counts recorded.
- [ ] Correct explanation of `AND`/`OR` precedence in plain English.
- [ ] Correct explanation of why `NULL` `DueDate` rows are excluded, referencing three-valued logic.
- [ ] The "undated counts as attention" variant uses `OR t.DueDate IS NULL`, not `ISNULL(t.DueDate, '1900-01-01')`.

---

## P3 — Ranges, Sets and the NULL Traps  *(Medium)*

**Tags:** `between` `date-ranges` `in` `not-in` `null` `not-exists` `anti-join`

Two bugs from the TaskFlow issue tracker. Reproduce both, then fix both.

### Requirements

**Bug 1 — "The February report is missing a task."**

1. Run `WHERE t.CompletedAtUtc BETWEEN '2024-02-01' AND '2024-02-28'` against `app.Tasks`. Record the rows returned.
2. Identify by `TaskId` the row that *should* be there and is not, and explain exactly why in a comment.
3. Rewrite using a half-open interval so the result is correct. Prove it returns the missing row.
4. Show — and explain the downside of — the `CAST(t.CompletedAtUtc AS DATE)` "fix".

**Bug 2 — "The 'users who never led a team' report returns nothing."**

5. Run `WHERE u.UserId NOT IN (SELECT tm.LeadUserId FROM app.Teams AS tm)` against `app.Users`. Record the row count.
6. Explain the expansion of `NOT IN` for a single candidate row, showing where `UNKNOWN` enters.
7. Fix it **three** ways: `NOT EXISTS`, an `IS NOT NULL` filter on the inner query, and a `LEFT JOIN … IS NULL` anti-join. All three must return the same rows.
8. State which one you would ship and why.

### Deliverable

`P3-range-and-null-traps.sql`

### Hints

- `app.Tasks.CompletedAtUtc` is `DATETIME2(3)`; a bare date literal means midnight.
- `app.Teams` has one row (`Design System`) with a `NULL` `LeadUserId`.
- Five distinct users lead a team, so the correct answer set for Bug 2 has 15 users.

### Look-fors (rubric)

- [ ] The specific missing `TaskId` is identified and the midnight explanation is correct.
- [ ] Half-open interval used (`>= @start AND < @endExclusive`), not `23:59:59.997`.
- [ ] The `CAST(... AS DATE)` alternative is called out as non-SARGable.
- [ ] The `NOT IN` expansion is written out with `UNKNOWN` shown explicitly.
- [ ] All three fixes return an identical result set (verify with `EXCEPT` in both directions).
- [ ] `NOT EXISTS` chosen as the ship-it answer, with a reason beyond "it's faster".

---

## P4 — Pattern Search Across Titles and Metadata  *(Medium)*

**Tags:** `like` `wildcards` `escape` `character-classes` `collation` `sargability`

Build the search predicates behind TaskFlow's quick-search box.

### Requirements

Write one query per bullet, each labelled with a comment:

1. Tasks whose `Title` **starts with** `Fix`.
2. Tasks whose `Title` **contains** any digit, using a character class.
3. Tasks whose `Title` contains **no** digit, using a negated character class. Explain why the naive negated pattern does not mean what most people think.
4. Comments in `app.Comments` whose `Body` contains a **literal percent sign**. Write it twice — once with `ESCAPE`, once with a character class.
5. Tasks whose `MetadataJson` contains a snake_case key (a literal underscore).
6. A case-**sensitive** search for `fix` at the start of `Title` using an explicit `COLLATE`. Explain, in a comment, what this costs.
7. For each of the six predicates, mark in a comment whether it is **seekable** or **scan-only**, and why.

### Deliverable

`P4-pattern-search.sql`

### Hints

- The comment on task 25 contains the text `above 5% flake rate`.
- `%[_]%` and `%!_%' ESCAPE '!'` are equivalent.
- `LIKE N'%[^0-9]%'` means "contains at least one non-digit" — not "contains no digits". You need `NOT LIKE N'%[0-9]%'`.
- `COLLATE` on the left-hand side of a predicate makes it non-SARGable.

### Look-fors (rubric)

- [ ] All six predicates run and return sensible rows.
- [ ] The negated-class misconception is explained correctly.
- [ ] Both the `ESCAPE` and character-class forms of the literal `%` search are present and return the same row.
- [ ] Seek-vs-scan classification is correct for all six (only #1 and #6-minus-the-collate are prefix-seekable).
- [ ] A comment names at least one real alternative for `%contains%` search at scale (full-text index, reversed computed column, external search).

---

## P5 — Deterministic Sorting and Top-N  *(Medium)*

**Tags:** `order-by` `null-ordering` `collation` `top` `with-ties` `percent` `distinct` `determinism`

### Requirements

1. Return `TaskId`, `Title`, `DueDate` from `app.Tasks` ordered by `DueDate` ascending. Record where the `NULL` due dates land.
2. Rewrite it so undated tasks sort **last** while dated tasks stay ascending. Do not use `ISNULL` with a sentinel date — explain in a comment why a sentinel is a bad idea.
3. Sort `app.Users` by `LastName` twice: once with the database default collation and once with `Latin1_General_BIN2`. Identify by `UserId` the row that moves, and explain why.
4. Return the top 2 tasks by `EstimatedHours` descending, then the same query with `WITH TIES`. Record both row counts and explain the difference.
5. Return `TOP (10) PERCENT` of tasks by `CreatedAtUtc` descending. State the exact row count returned and the rounding rule.
6. Write a `SELECT TOP (5)` with **no** `ORDER BY`, and explain in a comment why the result is not a bug but is also not usable.
7. Produce the distinct list of `(ProjectId, StatusId)` pairs present in `app.Tasks`. Then attempt `SELECT DISTINCT t.ProjectId … ORDER BY t.CreatedAtUtc`, capture the error number and message, and explain it.
8. Add a `CASE`-based `ORDER BY` that puts `BLOCKED` tasks first, then `IN_PROGRESS`, then everything else by `ref.TaskStatuses.SortOrder`. In a comment, argue why the sample database's `SortOrder` column is a better long-term design than the `CASE`.

### Deliverable

`P5-sorting-and-topn.sql`

### Hints

- SQL Server sorts `NULL` first in `ASC` and offers no `NULLS LAST` clause — emulate with a leading `CASE WHEN … IS NULL THEN 1 ELSE 0 END`.
- The user who moves under a binary collation has a lowercase surname prefix.
- 10 percent of 35 rows is not 3.
- The `DISTINCT` + `ORDER BY` failure is `Msg 145`.

### Look-fors (rubric)

- [ ] `NULLS LAST` emulated with `CASE`, and the sentinel-date approach explicitly rejected with a reason.
- [ ] The collation-sensitive user is correctly identified, with a code-point-level explanation.
- [ ] `WITH TIES` row count is correct and the tie values are named.
- [ ] `PERCENT` rounding-up rule stated correctly.
- [ ] The `TOP` without `ORDER BY` explanation mentions plan changes / parallelism, not just "random".
- [ ] `Msg 145` captured verbatim with a correct explanation of why the ordering would be ambiguous.

---

## P6 — Two Pagination Engines  *(Hard)*

**Tags:** `offset-fetch` `keyset-pagination` `determinism` `indexes` `api-design`

`GET /api/tasks?page=…&pageSize=…` currently uses `OFFSET … FETCH`. It is fine at 35 rows and unusable at 5 million. Build and compare both engines.

### Requirements

1. **Offset engine.** Parameterise `@PageNumber` and `@PageSize`. Order by `CreatedAtUtc DESC` with a unique tiebreaker. Return page 1 and page 2.
2. Demonstrate the **non-determinism** of a missing tiebreaker: order only by `PriorityId` with `@PageSize = 5`, fetch page 1 and page 2, and explain why a row could legitimately appear on both.
3. **Keyset engine.** Same ordering, but driven by `@LastCreatedAtUtc` / `@LastTaskId`. Return page 1 (no parameters) and the next page (parameters set from page 1's last row).
4. Write the keyset predicate **both** ways — the plain `OR` form and the `>=` + parenthesised-`OR` rewrite — and comment on why the second usually seeks better.
5. Note in a comment that T-SQL has no row-value comparison `(a, b) > (@a, @b)`, and show what the PostgreSQL/MySQL version would look like.
6. Create a supporting index on the exact sort key, capture `SET STATISTICS IO` logical reads for both engines, then drop the index. Record the numbers in a comment block.
7. Build a comparison table in comments covering: cost of page N, ability to jump to an arbitrary page, total-count availability, stability under concurrent inserts, and index requirements.
8. Recommend which engine TaskFlow should use for (a) the admin grid with page numbers and (b) the mobile infinite-scroll feed. Justify each.

### Deliverable

`P6-pagination.sql`

### Hints

- `OFFSET` requires `ORDER BY`; `FETCH` requires `OFFSET`; you cannot mix `TOP` with `OFFSET…FETCH` in the same query expression.
- The index you want is `ON app.Tasks (CreatedAtUtc, TaskId)` — or `(CreatedAtUtc DESC, TaskId DESC)` to match a descending sort exactly.
- Cursor tokens sent to a client should be opaque (base64) so callers cannot forge them into a data-leak vector.
- 35 rows will not show a performance difference. Reason about the *plan shape* and the *asymptotics*, not the milliseconds.

### Look-fors (rubric)

- [ ] Both engines run, are parameterised, and return identical rows for the same logical page.
- [ ] The missing-tiebreaker demonstration actually shows a repeated or skipped row (or explains precisely why it can).
- [ ] Both keyset predicate forms present, with a correct seek explanation.
- [ ] Logical reads captured for both engines with the index in place.
- [ ] Comparison table covers all five listed dimensions.
- [ ] Recommendation distinguishes random access (offset) from sequential access (keyset), and mentions result drift.
- [ ] The index is dropped at the end of the script so the shared database is left clean.

---

## P7 — SARGability Audit and Plan Report  *(Hard)*

**Tags:** `sargability` `execution-plans` `implicit-conversion` `computed-columns` `statistics-io`

You have inherited the seven `WHERE` clauses below from the TaskFlow reporting service. Audit and repair them.

| # | Predicate |
|---|---|
| 1 | `WHERE YEAR(t.CreatedAtUtc) = 2025` |
| 2 | `WHERE CAST(t.CompletedAtUtc AS DATE) = '2024-02-28'` |
| 3 | `WHERE t.EstimatedHours * 2 > 40` |
| 4 | `WHERE LEFT(p.ProjectCode, 3) = 'TF-'` |
| 5 | `WHERE ISNULL(t.StoryPoints, 0) > 5` |
| 6 | `WHERE DATEDIFF(DAY, t.DueDate, '2025-09-01') > 30` |
| 7 | `WHERE p.ProjectCode = N'TF-CORE'` |

### Requirements

1. For each predicate: state **why** it is non-SARGable (or, for #7, what the hidden conversion is), then write a SARGable rewrite.
2. Prove each rewrite is **semantically identical** to the original using `EXCEPT` in both directions — a pair of empty result sets is your proof.
3. For #7, identify which side of the comparison SQL Server converts and why, using data type precedence. State what `app.Projects.ProjectCode`'s declared type is.
4. For #7, explain how this bug typically arrives from a .NET application and name the concrete fix in both Dapper and EF Core.
5. Create `IX_Tasks_Created ON app.Tasks (CreatedAtUtc) INCLUDE (Title)`. Capture the actual plan operator (`Index Seek` / `Index Scan` / `Key Lookup`) and the `SET STATISTICS IO` logical reads for the original and rewritten versions of #1. Drop the index afterwards.
6. Write a short comment block explaining **Seek Predicate vs Predicate (residual)** using one of your rewrites as the example.
7. For predicate #4's original form, describe the one situation in which you would keep an expression-based filter and index the expression instead — and name the two mechanisms SQL Server offers for that.
8. Note in a comment why 35 rows may still produce a scan for every query, and what that tells you about reading plans on toy data.

### Deliverable

`P7-sargability-audit.sql`

### Hints

- `EXCEPT` returns rows in the first set not present in the second. Run it both directions to prove set equality.
- For #5, `NULL > 5` is already `UNKNOWN`, so the `ISNULL` wrapper changes nothing about which rows match.
- For #6, move the arithmetic to the literal: `t.DueDate < DATEADD(DAY, -30, '2025-09-01')`.
- The two expression-indexing mechanisms are **persisted computed columns** (see `app.Users.FullName`) and **indexed views**.
- Data type precedence: `NVARCHAR` outranks `VARCHAR`, so the `VARCHAR` side gets converted.

### Look-fors (rubric)

- [ ] All seven rewrites present and each proven equivalent with a two-way `EXCEPT`.
- [ ] The #7 explanation names `VARCHAR(10)`, names `NVARCHAR` precedence, and says the **column** is converted.
- [ ] Both the Dapper (`DbType.AnsiString`) and EF Core (`IsUnicode(false)` / `HasColumnType("varchar(10)")`) fixes named.
- [ ] Plan operators and logical reads captured for #1 in both forms.
- [ ] Seek Predicate vs residual Predicate explained correctly.
- [ ] Persisted computed column **and** indexed view both named as expression-indexing options.
- [ ] Index dropped at the end; the shared database is left exactly as found.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files in `PracticeProblemsSolutions/` are filled in — no remaining `-- TODO` markers.
- [ ] Every script runs top-to-bottom against a freshly created `TaskFlowDb` with zero errors.
- [ ] Every script that creates an index also drops it. The shared database is left unmodified.
- [ ] Zero `SELECT *` in any shipped query (commented-out demonstrations excepted).
- [ ] Every table is schema-qualified and aliased; every column is alias-prefixed.
- [ ] Every `ORDER BY` used for pagination ends with a unique column.
- [ ] Row counts and error messages are recorded as comments where the problem asked for them.
- [ ] `PracticeProblemsSolutions/README.md` accurately lists what each file contains.

---

## Stretch Goals

- Re-run P6 against a **1-million-row** table. Generate it with a `SELECT INTO` from `sys.all_objects` cross-joined to itself, then measure `OFFSET 999980` versus the keyset equivalent. Delete the table afterwards.
- Implement the keyset cursor as an opaque **base64 token** (`CAST(… AS VARBINARY)` + `BASE64_ENCODE`, or `FOR JSON` + `CONVERT(VARCHAR(MAX), …, 2)`), and explain the security reason for making it opaque.
- Rewrite P1's query for PostgreSQL and note every syntactic difference you hit (quoting, `LIMIT`, `NULLS LAST`, case folding of unquoted identifiers).
- Read the actual XML plan (`SET SHOWPLAN_XML ON`) for P7 #1 and find the `<SeekPredicates>` node. Compare it with the `<Predicate>` node in the non-SARGable version.
- Investigate `OPTION (RECOMPILE)` on the offset query and explain what parameter sniffing has to do with pagination performance.
