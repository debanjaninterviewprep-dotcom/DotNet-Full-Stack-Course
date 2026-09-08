# Topic 01: Relational Databases & SQL Fundamentals — Practice Problems

> Eight exercises that turn the Notes into reflexes. You will stand up a SQL Server instance, interrogate the system catalog, translate relational algebra into T-SQL, and deliberately walk into the three classic traps — alias scope, `ON` vs `WHERE`, and `NOT IN` with `NULL`s — so that you recognise them instantly in a code review.

**Concept tags:** `relational-model` `keys` `relational-algebra` `sql-standards` `ddl-dml-dql-dcl-tcl` `logical-query-processing` `null-three-valued-logic` `engine-architecture` `system-databases` `collation` `batches` `oltp-olap`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i 00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Write each answer in the matching starter file inside `PracticeProblemsSolutions/`. Every query must be schema-qualified (`app.Tasks`, never `Tasks`).

---

## P1 — Environment Bootstrap & Instance Reconnaissance  *(Easy)*

**Tags:** `docker` `tooling` `system-databases` `engine-architecture`

### Requirements

1. Start a **SQL Server 2022** container named `taskflow-sql` on port `1433`, with a **named volume** so data survives `docker restart`. Use the Developer edition PID.
2. Connect with at least **two** different tools (`sqlcmd` plus one of SSMS / Azure Data Studio / VS Code `ms-mssql.mssql`).
3. Run `00-create-taskflow-db.sql` and confirm the row counts match the expected block at the bottom of that script.
4. Capture, as a single result set where possible:
   - `@@VERSION`, the product edition, and the product level.
   - The **server collation** and the **`TaskFlowDb` collation**.
   - All **system databases** with their `database_id`, `state_desc` and `recovery_model_desc`.
   - The physical file names and sizes (MB) of `TaskFlowDb`.
5. Explain in a comment why the 2022 container image needs `-C` on `sqlcmd` and what that flag actually disables.

### Deliverable

`P1-environment-bootstrap.sql` containing the container command (as a comment block), all reconnaissance queries, and the captured output pasted under each query as a comment.

### Hints

- `SERVERPROPERTY('Edition')`, `SERVERPROPERTY('ProductLevel')`, `SERVERPROPERTY('Collation')`.
- `DATABASEPROPERTYEX(N'TaskFlowDb', 'Collation')`.
- `sys.databases` — `database_id` 1–4 are the system databases.
- `sys.database_files` gives `size` in 8 KB pages, so `size * 8 / 1024` is MB.
- If the container exits immediately, `docker logs taskflow-sql` almost always says the SA password failed policy.

### Look-fors (rubric)

- [ ] Container uses a named volume, not an anonymous one, and the command is reproducible verbatim.
- [ ] Row counts verified against the script's expected block (20 users, 8 projects, 35 tasks).
- [ ] All four system databases identified **by name and purpose**, not just listed.
- [ ] Correct explanation of `-C` (trust server certificate — skips validation, dev-only).
- [ ] `tempdb` correctly described as recreated from `model` on restart.

---

## P2 — Anatomy of a Relation  *(Easy)*

**Tags:** `relational-model` `degree-cardinality` `catalog-views` `atomicity`

### Requirements

1. Write **one** query that returns, for every table in the `app`, `ref` and `audit` schemas: schema name, table name, **degree** (column count) and **cardinality** (row count). Order by cardinality descending.
2. Prove the "no guaranteed order" property: run `SELECT TOP (5) TaskId FROM app.Tasks;` twice — once as written, once with `ORDER BY NEWID()` — and explain in a comment why neither result is a contract.
3. Identify the **domain** of `app.Tasks.StatusId`: name the base type, its storage size, and the two mechanisms that narrow the domain beyond the type.
4. `app.Tasks.MetadataJson` stores JSON in a single column. Argue in 4–6 lines whether this violates **first normal form**, and state the condition under which it does.
5. Show that `SELECT` returns a multiset: produce a query over `app.TeamMembers` that returns duplicate rows, then the `DISTINCT` version.

### Deliverable

`P2-anatomy-of-a-relation.sql`.

### Hints

- Cardinality without a scan: `sys.partitions` where `index_id IN (0, 1)`, summing `rows`.
- Degree: `sys.columns` grouped by `object_id`.
- `TINYINT` is 1 byte, range 0–255. The two narrowing mechanisms are `NOT NULL` and a constraint.
- For duplicates, project only `Department` from a join of `app.TeamMembers` to `app.Teams`.

### Look-fors (rubric)

- [ ] A single set-based query for degree + cardinality, not one query per table.
- [ ] Cardinality sourced from `sys.partitions` or `COUNT(*)`, with `index_id` filtered so heaps and clustered indexes are not double-counted.
- [ ] Domain answer names `TINYINT`, 1 byte, `NOT NULL` and `FK_Tasks_Status`.
- [ ] 1NF argument distinguishes "atomic to the database" from "atomic to the application".
- [ ] Multiset demonstration actually produces duplicates.

---

## P3 — Key Inventory & Surrogate/Natural Audit  *(Easy)*

**Tags:** `keys` `primary-key` `foreign-key` `composite-key` `surrogate-vs-natural`

### Requirements

1. Produce a **key inventory** table (as a query result or a commented markdown table) listing, for every `app`/`ref`/`audit` table: the primary key columns in key order, and every alternate (`UNIQUE`) key.
2. Write a query listing **all foreign keys** with child table, parent table, `ON DELETE` action, and whether the FK is **trusted**.
3. For `app.Users`, list **every candidate key** you can justify from the data. Prove or disprove each with a `GROUP BY ... HAVING COUNT(*) > 1` uniqueness test.
4. `app.Projects` has both a surrogate PK (`ProjectId`) and a natural unique key (`ProjectCode`). Write the two `ALTER TABLE` statements that would migrate `app.Tasks` to reference `ProjectCode` instead, then argue in comments why you would not.
5. Explain why `audit.TaskHistory` has **no** foreign key to `app.Tasks`, and name one integrity risk you accept as a result.

### Deliverable

`P3-key-inventory.sql`.

### Hints

- PK/UQ columns: join `sys.key_constraints` -> `sys.index_columns` -> `sys.columns` on `unique_index_id`.
- FKs: `sys.foreign_keys` has `delete_referential_action_desc` and `is_not_trusted`.
- A candidate key must be *minimal*: `{UserId, Email}` is a superkey, not a candidate key.
- Test uniqueness of `{FirstName, LastName}` — the data will tell you whether it holds today and whether it holds *by design*.

### Look-fors (rubric)

- [ ] Composite PK on `app.TeamMembers`, `app.TaskAssignments` and `app.TaskLabels` reported with correct `key_ordinal`.
- [ ] Cascade behaviour correctly identified on the four `ON DELETE CASCADE` foreign keys.
- [ ] Candidate-key list is minimal and distinguishes "unique in the current data" from "unique by constraint".
- [ ] Natural-key argument cites at least three costs: width in child indexes, cascade-on-update, and PII/renaming exposure.
- [ ] Audit answer states the accepted risk explicitly (orphaned `TaskId` values).

---

## P4 — Relational Algebra to T-SQL  *(Medium)*

**Tags:** `relational-algebra` `set-operators` `joins` `division`

### Requirements

Implement each operator against TaskFlow. One query per operator, each preceded by a comment naming the algebraic form.

1. **Selection + Projection** — task id and title of all `CRITICAL` priority tasks, without hard-coding `PriorityId = 1`.
2. **Cartesian product** — every status/priority pair. State the expected row count before you run it.
3. **Union** — all task titles that are either `BLOCKED` or `IN_REVIEW`, using a set operator (not `OR`). Then show the `UNION` vs `UNION ALL` difference and explain which is correct here.
4. **Intersection** — users who are both a team lead (`app.Teams.LeadUserId`) *and* a project owner (`app.Projects.OwnerUserId`).
5. **Difference** — labels defined in `app.Labels` but never applied in `app.TaskLabels`. Then write the same result with `NOT EXISTS` and compare the two execution plans.
6. **Outer join** — every project with its task count, **including projects with zero tasks**. Explain why `COUNT(*)` is wrong here and what to use instead.
7. **Division** — every user assigned to **every** task in project `TF-SEC`. Use the double-`NOT EXISTS` pattern.
8. **Aggregation (γ)** — total billable hours per project, projects with no time entries showing `0.00` rather than `NULL`.

### Deliverable

`P4-relational-algebra.sql`.

### Hints

- For 1, join `ref.Priorities` and filter on `PriorityCode = 'CRITICAL'`.
- For 2, `CROSS JOIN`; 7 statuses times 5 priorities.
- For 6, `COUNT(*)` counts the outer-join placeholder row and returns 1 instead of 0. Count a column from the *inner* side.
- For 8, `SUM` over an empty set is `NULL`; wrap with `COALESCE(..., 0)` and remember `IsBillable = 1`.
- Division is "there is no task in TF-SEC for which this user has no assignment".

### Look-fors (rubric)

- [ ] Cartesian product row count predicted correctly (35) before execution.
- [ ] `UNION ALL` vs `UNION` choice justified by whether duplicates are possible.
- [ ] `COUNT(<inner column>)` used in the outer-join count, not `COUNT(*)`.
- [ ] Division query returns the correct result and does **not** use `HAVING COUNT(*) = (SELECT COUNT(*) ...)` as its only form.
- [ ] `COALESCE`/`ISNULL` applied for the empty-aggregate case.
- [ ] Every query schema-qualifies its tables and aliases them.

---

## P5 — Logical Query Processing Detective  *(Medium)*

**Tags:** `logical-query-processing` `alias-scope` `on-vs-where` `having` `top-order-by`

### Requirements

Four queries below are broken or misleading. For each: state the **error number or wrong behaviour**, name the **logical processing step** that explains it, and write the corrected query.

```sql
-- BUG 1
SELECT p.ProjectName, COUNT(*) AS TaskCount
FROM app.Projects AS p
JOIN app.Tasks    AS t ON t.ProjectId = p.ProjectId
WHERE TaskCount > 3
GROUP BY p.ProjectName;

-- BUG 2  (intent: every project, plus its Done tasks)
SELECT p.ProjectCode, t.Title
FROM app.Projects AS p
LEFT JOIN app.Tasks AS t ON t.ProjectId = p.ProjectId
WHERE t.StatusId = 6;

-- BUG 3  (intent: the 5 most overdue open tasks)
SELECT TOP (5) t.TaskId, t.Title, t.DueDate
FROM app.Tasks AS t
WHERE t.DueDate < '2025-09-01';

-- BUG 4  (intent: users and how many tasks they created, only prolific ones)
SELECT u.Email, COUNT(t.TaskId) AS Created
FROM app.Users AS u
LEFT JOIN app.Tasks AS t ON t.CreatedByUserId = u.UserId
GROUP BY u.Email
HAVING COUNT(t.TaskId) > 0
ORDER BY Created DESC;
-- Why does this return fewer rows than app.Users has, and is that correct?
```

Then:

5. Write the **full logical processing order** as a comment, and annotate a single query of your own with the step number at which each clause is evaluated.
6. Demonstrate that `ORDER BY` **can** see a `SELECT` alias while `WHERE` and `GROUP BY` cannot, using three short queries (two of which fail — capture the message numbers).

### Deliverable

`P5-logical-query-processing.sql`.

### Hints

- Bug 1 is `Msg 207`. Bug 2 is not an error at all — that is what makes it dangerous.
- Bug 3 has two problems: non-determinism, and it ignores whether the task is still open.
- For bug 4, `HAVING COUNT(t.TaskId) > 0` cancels the `LEFT JOIN`. Decide whether that is the intent.
- SQL Server also allows `GROUP BY` on an expression but not on its alias — worth demonstrating.

### Look-fors (rubric)

- [ ] Bug 1 attributed to `WHERE` (step 4) preceding `SELECT` (step 6), fixed with `HAVING`.
- [ ] Bug 2 correctly described as the `LEFT JOIN` degrading to `INNER JOIN`; fix moves the predicate into `ON`.
- [ ] Bug 3 fix adds a deterministic `ORDER BY` **with a tiebreaker** and a terminal-status exclusion.
- [ ] Bug 4 analysis identifies that the `LEFT JOIN` is pointless given the `HAVING`, and offers both readings.
- [ ] Alias-scope demonstration includes actual error message numbers.

---

## P6 — Three-Valued Logic Audit  *(Medium)*

**Tags:** `null` `three-valued-logic` `not-in` `aggregates` `constraints`

### Requirements

1. Write the complete **truth tables** for `AND`, `OR` and `NOT` over `{TRUE, FALSE, UNKNOWN}` as a comment block, then verify three of the rows with actual `SELECT` statements.
2. For `ref.Priorities`, show the difference between `= NULL` and `IS NULL`, and between `COUNT(*)` and `COUNT(SlaHours)`. Explain the numbers.
3. Write a query intended to return "all priorities whose SLA is not 24 hours". Show the naive version, state how many rows it silently loses, and write the correct version.
4. Reproduce the `NOT IN` trap: write a query for "users who manage nobody" using `NOT IN` over `app.Users.ManagerId` — it will return zero rows. Explain precisely why, then fix it with `NOT EXISTS`. Also show the `NOT IN` version made correct by filtering `NULL`s, and say which fix you prefer and why.
5. Show that `GROUP BY`, `DISTINCT` and `UNIQUE` treat `NULL`s as **equal** even though `=` does not. Use `ref.Priorities.SlaHours` and `app.Users.ManagerId`.
6. `CK_Users_HourlyRate` is `CHECK (HourlyRate IS NULL OR HourlyRate >= 0)`. Prove that the `IS NULL` half is redundant by attempting an insert of a `NULL` rate against a `CHECK (HourlyRate >= 0)` written on a scratch table. Explain the `WHERE`/`CHECK` asymmetry.
7. Produce a **nullability report**: every nullable column in the `app` and `ref` schemas, with its actual `NULL` count and the percentage of rows affected.

### Deliverable

`P6-null-and-three-valued-logic.sql`.

### Hints

- Users 1 and 20 have `ManagerId IS NULL`. That is what poisons `NOT IN`.
- `SELECT CASE WHEN NULL = NULL THEN 'T' WHEN NOT (NULL = NULL) THEN 'F' ELSE 'UNKNOWN' END;`
- For the nullability report, drive off `sys.columns` where `is_nullable = 1` and build the counts with dynamic SQL **or** hand-write the union — say which you chose and why dynamic SQL is a security consideration (Topic 19).
- Clean up any scratch table with `DROP TABLE IF EXISTS`.

### Look-fors (rubric)

- [ ] Truth tables correct, including `FALSE AND UNKNOWN = FALSE` and `TRUE OR UNKNOWN = TRUE`.
- [ ] Explains that `WHERE` keeps only `TRUE` while `CHECK` rejects only `FALSE`.
- [ ] `NOT IN` failure explained in terms of `UserId <> NULL` evaluating to `UNKNOWN` for every candidate row.
- [ ] States a preference between `NOT EXISTS` and `NOT IN + IS NOT NULL`, with a reason (readability, plan shape, or resilience to future `NULL`s).
- [ ] Notes SQL Server's one-`NULL`-per-`UNIQUE` behaviour and that the standard disagrees.
- [ ] Scratch objects dropped.

---

## P7 — Batches, Identifiers, Collation and Case Sensitivity  *(Hard)*

**Tags:** `batches` `go` `identifiers` `quoted-identifier` `collation` `sargability`

### Requirements

1. Demonstrate **batch scoping**: declare a variable, use it, then attempt to use it after a `GO`. Capture the message number. Then show that a `#temp` table *does* survive `GO` and explain the difference in scope.
2. Use `GO 3` to insert three rows into `audit.TaskHistory` with `ColumnName = N'BatchDemo'`, verify the count, then clean up.
3. Explain, with a working example, why `00-create-taskflow-db.sql` wraps `CREATE SCHEMA` in `EXEC (N'CREATE SCHEMA app')`. Reproduce the error you get without the wrapper.
4. Create a scratch table using **reserved words** as the table and column names (`[Order]`, `[User]`, `[Group]`), insert a row, select from it, and drop it. Then write 3 lines on why you would never ship this.
5. Toggle `SET QUOTED_IDENTIFIER OFF` and show that `"Title"` changes meaning from a column reference to a string literal. Restore `ON` afterwards and explain which features require it.
6. Report the server collation, the database collation, and any column-level collations in `app`. Then:
   - Show `ProjectCode = 'tf-core'` matching under the default collation.
   - Force a case-sensitive comparison with `COLLATE` and show zero rows.
   - Explain why the `COLLATE` version is **non-SARGable** and what you would do instead if this were a hot path.
7. Write a query proving whether the `TaskFlowDb` collation is accent sensitive, using a literal comparison such as `N'Turing' = N'Türing'`.

### Deliverable

`P7-batches-identifiers-collation.sql`.

### Hints

- Batch-scope failure is `Msg 137`. The `CREATE SCHEMA` failure is `Msg 111`.
- `sys.columns.collation_name` is `NULL` for non-character columns.
- SARGability: a function or `COLLATE` applied to the *column* side prevents an index seek; applied to the *literal* side it does not — but the comparison collation still has to match.
- The correct fix for a hot path is a persisted, normalised column or a column-level collation change — not per-query `COLLATE`.

### Look-fors (rubric)

- [ ] `Msg 137` and `Msg 111` both reproduced and named.
- [ ] Correct distinction between **batch** scope (variables) and **session** scope (`#temp`).
- [ ] `QUOTED_IDENTIFIER` explanation names at least one feature that requires it `ON` (indexed views, indexes on computed columns, filtered indexes, or XML methods).
- [ ] SARGability explained in terms of index seek vs scan, not just "it is slower".
- [ ] All scratch objects dropped; `audit.TaskHistory` returned to its original 0 rows.
- [ ] Accent-sensitivity conclusion matches the actual collation suffix reported in step 6.

---

## P8 — Workload Fit: OLTP, OLAP and the Storage Decision  *(Hard)*

**Tags:** `oltp-olap` `sql-vs-nosql` `architecture` `engine-architecture`

### Requirements

You are the engineer arguing TaskFlow's data architecture in a design review.

1. Classify **eight** real TaskFlow queries as OLTP or OLAP, with a one-line justification each. At least three must be genuinely ambiguous. Write and run all eight.
   Suggested set: move a task to `IN_REVIEW`; the Kanban board for project `TF-CORE`; average cycle time (`CreatedAtUtc` to `CompletedAtUtc`) per team per quarter; a user's assigned open tasks; total billable hours per project per month; label co-occurrence counts; the audit trail for one task; count of overdue tasks by priority across all projects.
2. Using `sys.dm_exec_query_stats` or `SET STATISTICS IO ON`, capture **logical reads** for your most OLTP-ish and most OLAP-ish query. Report the ratio and explain it in terms of **pages**, not rows.
3. Build a **decision memo** (in comments, 300–500 words) answering: at what point does TaskFlow need a separate analytical store? Define a concrete trigger metric, not a feeling.
4. Fill in a **SQL vs NoSQL decision table** for three TaskFlow subsystems: the core task graph, the real-time presence/"who is viewing this task" feature, and the activity feed. Recommend a store for each and state what you give up.
5. `app.Tasks.MetadataJson` is a document embedded in a relational table. Argue both sides: when this is pragmatic, and the specific point at which it becomes technical debt. Reference at least one concrete query that would be painful.
6. Sketch (as a comment block) the star schema you would build for question 1's cycle-time query: name the fact table, its grain, its measures, and three dimensions.

### Deliverable

`P8-workload-fit.sql`.

### Hints

- Cycle time: `DATEDIFF(HOUR, t.CreatedAtUtc, t.CompletedAtUtc)` over rows where `CompletedAtUtc IS NOT NULL`, joined through `app.Projects` to `app.Teams`.
- Label co-occurrence is a self-join of `app.TaskLabels` on `TaskId` with `l1.LabelId < l2.LabelId`.
- Logical reads are 8 KB pages. A query reading 4,000 pages touched 32 MB of buffer pool regardless of how many rows it returned.
- A good trigger metric looks like: "p95 board-load latency exceeds 300 ms while the reporting workload is running" — measurable, attributable, and falsifiable.
- Grain is the most important line in the star-schema sketch. State it as "one row per ___".

### Look-fors (rubric)

- [ ] All eight queries run correctly against `TaskFlowDb` and are schema-qualified.
- [ ] Ambiguous cases genuinely argued both ways, not hand-waved.
- [ ] Logical reads reported as numbers with the page-to-MB conversion shown.
- [ ] Trigger metric is quantitative and tied to a user-visible symptom.
- [ ] NoSQL recommendations name the family (document / key-value / graph), not just a product.
- [ ] The `MetadataJson` argument names a specific painful query (for example, "all tasks in epic X" with no index on the JSON path).
- [ ] Star-schema grain stated as a single sentence, with measures that are additive.

---

## Submission Checklist

- [ ] All eight `.sql` files exist in `PracticeProblemsSolutions/` and each replaces its `-- TODO` marker.
- [ ] Every script begins with `USE TaskFlowDb;` and `GO`.
- [ ] Every table reference is schema-qualified and every table has an alias.
- [ ] No script leaves scratch objects behind (`DROP TABLE IF EXISTS` at the end).
- [ ] `audit.TaskHistory` and `app.Labels` are back to their seeded state after P4–P7.
- [ ] Results are pasted as comments under each query so the file is reviewable without a server.
- [ ] No real passwords committed — use `<pwd>` placeholders.
- [ ] Re-running `00-create-taskflow-db.sql` still produces the expected row counts.

---

## Stretch Goals

- Re-run P4 and P6 against **PostgreSQL** (`docker run postgres:16`) and log every syntax change you had to make. Pay attention to `TOP` vs `LIMIT`, `ISNULL` vs `COALESCE`, and identifier case folding.
- Restore `TaskFlowDb` into **Azure SQL Database** (free tier). Document every statement in `00-create-taskflow-db.sql` that had to change and why `USE` is unsupported there.
- Rebuild the `app.Tasks` key inventory using `INFORMATION_SCHEMA` views instead of `sys.*`, and write 5 lines on why `sys.*` is generally preferred in SQL Server.
- Use `SET SHOWPLAN_ALL ON` on the P4 division query and the equivalent `GROUP BY ... HAVING COUNT(*) = ...` rewrite. Compare estimated costs and explain which the optimizer prefers and why.
- Change the `TaskFlowDb` collation to `Latin1_General_100_CS_AS_SC_UTF8` on a **copy** of the database and enumerate everything that breaks.
