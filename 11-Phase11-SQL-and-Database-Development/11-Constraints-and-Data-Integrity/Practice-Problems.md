# Topic 11: Constraints & Data Integrity — Practice Problems

> Eight exercises that move from reading constraint metadata to designing where a business rule belongs. Several problems deliberately ask you to make a write **fail** and record the exact error text — the error number is how you will diagnose a production incident, so learn to recognise 515, 547, 2601, 2627 and 1785 on sight. Every problem runs against the shared **TaskFlowDb** sample database, and every object you create must be dropped again.

**Concept tags:** `not-null` `primary-key` `unique-constraint` `filtered-unique-index` `foreign-key` `referential-actions` `cascade-paths` `error-1785` `check-constraints` `null-passes-check` `default-constraints` `untrusted-constraints` `with-nocheck` `join-elimination` `bulk-load` `catalog-views` `cross-row-rules`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

Put each answer in `PracticeProblemsSolutions/Pn-*.sql` (or `.md` where the deliverable is a design). Starter files with the problem statement are already there.

---

## P1 — Constraint Inventory  *(Easy)*

**Tags:** `catalog-views` `information-schema` `primary-key` `foreign-key` `check-constraints` `default-constraints`

### Requirements

Write a single script that produces a complete integrity inventory of `TaskFlowDb`:

1. Every primary key and unique constraint, with table, constraint name and `type_desc`. State the count of each.
2. Every foreign key with child table, parent table, `delete_referential_action_desc` and `update_referential_action_desc`. State the total, and how many use `CASCADE`.
3. Every foreign key **column pair** in key order, using `sys.foreign_key_columns`. Identify any composite foreign keys.
4. Every check constraint with its `definition` text.
5. Every default constraint with its column and `definition` text.
6. Every nullable column in the `app` schema, plus a comment naming the three nullable columns whose NULL carries a *documented business meaning* and saying what each means.
7. Two "should always be empty" audit queries: tables with no primary key, and constraints where `is_disabled = 1 OR is_not_trusted = 1`.
8. Re-run requirements 1 and 2 using `INFORMATION_SCHEMA` instead of `sys.`, and add a comment listing three things `INFORMATION_SCHEMA` cannot tell you.

### Deliverable

`P1-constraint-inventory.sql`

### Hints

- `sys.key_constraints.type` is `'PK'` or `'UQ'`.
- `OBJECT_SCHEMA_NAME()`, `OBJECT_NAME()` and `COL_NAME()` turn ids into names without extra joins.
- `INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS` joins to `TABLE_CONSTRAINTS` on `CONSTRAINT_NAME` — a reminder that constraint names are unique per schema, which is another argument for naming them.
- Requirement 7's second query needs a `UNION ALL` over `sys.foreign_keys` and `sys.check_constraints`.

### Look-fors (rubric)

- [ ] 13 primary keys, 6 unique constraints, 20 foreign keys, 6 check constraints, 16 default constraints.
- [ ] 6 foreign keys use `ON DELETE CASCADE`; the other 14 are `NO_ACTION`.
- [ ] Requirement 3 correctly reports that TaskFlow has **no** composite foreign keys, even though it has three composite primary keys.
- [ ] The three self-referencing foreign keys (`FK_Users_Manager`, `FK_Tasks_Parent`, `FK_Comments_Parent`) are identified.
- [ ] Both audit queries in requirement 7 return **0 rows** against a freshly seeded database.
- [ ] The `INFORMATION_SCHEMA` limitations comment names trust state, filtered indexes and disabled state.

---

## P2 — The One-NULL Rule  *(Easy)*

**Tags:** `unique-constraint` `nulls` `filtered-unique-index` `error-2627` `error-2601`

### Requirements

Prove, with running code, that SQL Server allows exactly one NULL in a `UNIQUE` constraint and that a filtered unique index is the fix.

1. Create `app.ProjectExternalRefs (ProjectId INT PK, JiraKey VARCHAR(20) NULL)` with a foreign key to `app.Projects` and a `UNIQUE` constraint on `JiraKey`.
2. Insert one row with a real key, one row with `NULL`, then a second row with `NULL`. Capture the error verbatim, including the reported duplicate key value.
3. Insert a duplicate non-NULL key. Capture that error too and note its number.
4. Drop the `UNIQUE` constraint and replace it with a filtered unique index `WHERE JiraKey IS NOT NULL`.
5. Repeat steps 2 and 3. Record which now succeed and which still fail, and note the **different error number**.
6. Query `sys.indexes` for the table and report `is_unique`, `is_unique_constraint`, `has_filter` and `filter_definition` before and after the swap.
7. Write a comment table comparing a `UNIQUE` constraint against a unique index across at least five dimensions.
8. Drop the table.

### Deliverable

`P2-unique-and-nulls.sql`

### Hints

- The duplicate-NULL error reports `The duplicate key value is (<NULL>).` — quote it exactly.
- A `UNIQUE` constraint violation is **2627**; a unique index violation is **2601**. That difference is the whole point of step 5.
- `is_unique_constraint = 1` only for indexes backing a `UNIQUE` constraint; a `CREATE UNIQUE INDEX` leaves it 0.
- Only eight `ProjectId` values exist (1–8), so keep your test rows inside that range or the foreign key fires first.

### Look-fors (rubric)

- [ ] The second NULL insert fails with 2627 and the message is quoted verbatim.
- [ ] After the swap, multiple NULLs insert successfully and the duplicate non-NULL fails with **2601**.
- [ ] `has_filter = 1` and `filter_definition` reads `([JiraKey] IS NOT NULL)` after step 4.
- [ ] The comparison table includes the filter/`INCLUDE` capability and the error-number difference.
- [ ] A portability note states that PostgreSQL, MySQL and Oracle all allow unlimited NULLs here.
- [ ] `DROP TABLE app.ProjectExternalRefs;` runs at the end.

---

## P3 — Domain Integrity with `CHECK`  *(Medium)*

**Tags:** `check-constraints` `null-passes-check` `collation` `error-547` `error-1046`

### Requirements

Work only on the real TaskFlow tables, adding constraints and removing them again.

1. Add `CK_Tasks_StoryPoints` restricting `StoryPoints` to the Fibonacci set `(1,2,3,5,8,13,21)`, allowing NULL. It must be created `WITH CHECK` and succeed against the seeded data. Verify `is_not_trusted = 0`.
2. Add `CK_Tasks_CompletionConsistency` asserting that `CompletedAtUtc` may only be non-NULL when `StatusId` is terminal (6 or 7). Verify it succeeds.
3. Attempt the **converse** constraint — every terminal task must have a `CompletedAtUtc`. It must fail. Capture the error verbatim, then write the query that finds the offending rows and explain the business situation they represent.
4. Demonstrate the NULL trap: write two constraints that differ only by an explicit `IS NULL OR`, prove they behave identically, and then write the version that genuinely rejects NULL.
5. Demonstrate the collation trap: show that `CHECK (CountryCode LIKE '[A-Z][A-Z]')` accepts `'gb'` under the default collation, and fix it with `COLLATE Latin1_General_BIN2`.
6. Attempt a `CHECK` containing a subquery. Capture the error number and message.
7. Explain, in a comment, why a scalar UDF that performs the same subquery is worse than no constraint at all. Name at least three specific failure modes.
8. Drop every constraint you added and confirm the check-constraint count is back to 6.

### Deliverable

`P3-check-constraints.sql`

### Hints

- Seeded `StoryPoints` values are exactly `1, 2, 3, 5, 8, 13, 21` and NULL — requirement 1 will pass.
- Requirement 3 fails on tasks 26 and 27: both are `CANCELLED` with no completion timestamp. That is a real business shape, not bad data.
- `ALTER TABLE … WITH CHECK ADD CONSTRAINT …` is the validating form; `WITH NOCHECK` would let requirement 3 "succeed" untrusted — try it and then undo it.
- The subquery error is **1046**, not 547.
- For requirement 7, think about `DELETE`, concurrency under `READ COMMITTED`, and multi-row `UPDATE`.

### Look-fors (rubric)

- [ ] Requirements 1 and 2 both create trusted constraints (`is_not_trusted = 0`).
- [ ] Requirement 3's error is a **547** naming `ALTER TABLE` and the constraint, and the offending rows are tasks 26 and 27.
- [ ] Requirement 4 proves `CHECK (col > 0)` and `CHECK (col IS NULL OR col > 0)` are equivalent, and gives `col IS NOT NULL AND col > 0` as the strict version.
- [ ] Requirement 5's fix is verified by an insert of `'gb'` that now fails.
- [ ] Requirement 6 quotes `Msg 1046 … Subqueries are not allowed in this context.`
- [ ] The UDF critique names non-evaluation on `DELETE`, concurrency, and per-row cost.
- [ ] The final count from `sys.check_constraints` is 6.

---

## P4 — Referential Actions and Cascade Paths  *(Medium)*

**Tags:** `foreign-key` `referential-actions` `cascade` `set-null` `error-1785` `error-547`

### Requirements

1. Build a comparison harness: create `app.TaskWatchers` three times — once with `ON DELETE NO ACTION`, once with `CASCADE`, once with `SET NULL` — and for each, attempt to delete the parent task and record what happens. State exactly which declaration `SET NULL` requires on the child column.
2. Explain why `ON DELETE SET DEFAULT` is almost unusable for a foreign key, using `app.Tasks.ProjectId` as the example.
3. Inside a transaction that you roll back, delete task 35 and prove that exactly four child rows were removed by cascade (one assignment, one label link, one comment, one time entry). Show that `@@ROWCOUNT` reports 1 and explain why.
4. Inside another rolled-back transaction, attempt to delete task 1 and capture the error. Identify which constraint blocked it and why the message wording differs from an ordinary foreign key conflict.
5. Reproduce error **1785** twice: once with a self-referencing `ON DELETE CASCADE` on `app.Tasks`, and once by creating a table with two cascade paths back to `app.Tasks`. Quote both errors.
6. For the two-path case, list four ways to resolve it and argue for one.
7. Produce a table of all 20 TaskFlow foreign keys classified as **composition** (child cannot exist alone) or **association** (child is independent), and check whether the declared `ON DELETE` action matches the classification. Flag any mismatch.
8. Drop everything you created.

### Deliverable

`P4-referential-actions.sql`

### Hints

- `SET NULL` requires the child foreign key column to be nullable — otherwise the `CREATE TABLE` itself fails.
- For requirement 5's two-path case, a composite foreign key to `app.TaskAssignments (TaskId, UserId)` plus a direct foreign key to `app.Tasks (TaskId)`, both cascading, is the shortest reproduction.
- Task 1 is the parent of tasks 2 and 3 via `ParentTaskId`; the error says `SAME TABLE REFERENCE constraint`.
- Task 35 is `Fix timezone bug on due dates`: assignment `(35, 11)`, label `(35, 1)`, one comment by Radia Perlman, one time entry of 2.00 hours.
- Wrap every destructive statement in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.

### Look-fors (rubric)

- [ ] Requirement 3 shows all four child counts at 0 inside the transaction and back to their original values after the rollback.
- [ ] `@@ROWCOUNT` is 1 and the explanation states that cascaded rows are not counted.
- [ ] Requirement 4 quotes the `SAME TABLE REFERENCE constraint "FK_Tasks_Parent"` wording.
- [ ] Both 1785 reproductions are shown, with the follow-on `Msg 1750` for the `CREATE TABLE` case.
- [ ] Requirement 6 lists dropping the redundant cascade, `INSTEAD OF` trigger, `AFTER` trigger and application-side deletion, and argues for the first.
- [ ] The requirement 7 table shows 6 cascading foreign keys and identifies `audit.TaskHistory` as deliberately having none.
- [ ] `app.TaskWatchers` does not exist at the end of the script.

---

## P5 — Untrusted Constraints and the Optimizer  *(Medium)*

**Tags:** `untrusted-constraints` `with-nocheck` `join-elimination` `execution-plans` `sys-foreign-keys`

### Requirements

1. Turn on the actual execution plan. Run `SELECT t.TaskId, t.Title FROM app.Tasks AS t JOIN app.Projects AS p ON p.ProjectId = t.ProjectId;` and record which tables the plan actually touches.
2. Run `ALTER TABLE app.Tasks NOCHECK CONSTRAINT FK_Tasks_Project;`, re-run the query, and record the plan change. Explain the mechanism by name.
3. Restore trust with `WITH CHECK CHECK CONSTRAINT` and confirm both `is_disabled` and `is_not_trusted` are 0.
4. Show that `ALTER TABLE … CHECK CONSTRAINT …` (without `WITH CHECK`) re-enables enforcement but leaves the constraint untrusted. Prove it from `sys.foreign_keys` and from the plan.
5. Repeat the experiment for a `CHECK` constraint: add `CK_TimeEntries_HoursTrusted` (or reuse `CK_TimeEntries_Hours`), run `SELECT COUNT(*) FROM app.TimeEntries AS te WHERE te.Hours > 30;`, and compare the plan when the constraint is trusted versus untrusted.
6. Add a foreign key `WITH NOCHECK` on a scratch table containing a row that violates it. Show that the constraint is created, that the bad row survives, and that a *new* violating insert is still rejected. Explain the three-state model: enforced/not, trusted/not, disabled/not.
7. Write the deployment health-check query that returns every untrusted or disabled constraint in the database, and state what a CI pipeline should do with a non-empty result.
8. Restore every constraint to trusted and prove the health-check query returns 0 rows.

### Deliverable

`P5-untrusted-constraints.sql`

### Hints

- Join elimination needs three things at once: a trusted foreign key, a `NOT NULL` child column, and no parent columns in the `SELECT` list.
- The `CHECK`-based simplification shows up as a plan that reads no pages at all — look for a constant scan or a zero-row estimate.
- The doubled keyword `WITH CHECK CHECK CONSTRAINT` is correct: the first is the option, the second is the verb.
- `sys.foreign_keys` and `sys.check_constraints` both expose `is_disabled` and `is_not_trusted`.

### Look-fors (rubric)

- [ ] Step 1's plan touches `app.Tasks` only; step 2's plan touches both tables.
- [ ] The mechanism is named **join elimination** (also called foreign-key join removal).
- [ ] Step 4 demonstrates `is_disabled = 0` with `is_not_trusted = 1` simultaneously.
- [ ] Step 5 shows the trusted case producing a plan with no table access and explains it as constraint-based contradiction detection.
- [ ] Step 6's write-up correctly separates the three states and maps each `ALTER TABLE` form onto them.
- [ ] The health-check query returns 0 rows at the end of the script.
- [ ] No constraint on a real TaskFlow table is left disabled or untrusted.

---

## P6 — Bulk Load with Constraints Disabled  *(Hard)*

**Tags:** `bulk-load` `nocheck-constraint` `with-check` `staging` `error-547` `data-repair`

### Requirements

Simulate a nightly import of time entries from a legacy system.

1. Create `app.TimeEntriesStaging` with the same shape as `app.TimeEntries` but **no** constraints at all — this is the landing zone.
2. Populate it with 40 rows: 35 valid rows derived from the existing data, plus 5 deliberately bad rows covering, at minimum, a non-existent `TaskId`, a non-existent `UserId`, `Hours = 0`, `Hours = 30`, and a NULL `WorkDate`.
3. Create `app.TimeEntriesBulk` as a full clone of `app.TimeEntries` **including** its primary key, both foreign keys and `CK_TimeEntriesBulk_Hours`.
4. Disable all foreign keys and check constraints on `app.TimeEntriesBulk`, load the staging rows, and confirm the bad rows landed.
5. Attempt `ALTER TABLE … WITH CHECK CHECK CONSTRAINT ALL`. Capture the error and note which constraint fired first.
6. Write one validation query per constraint that finds the offending rows **before** re-enabling — this is the pattern a real pipeline uses.
7. Quarantine the bad rows into `app.TimeEntriesRejects`, delete them from the target, then re-enable successfully. Prove every constraint is `is_disabled = 0` and `is_not_trusted = 0`.
8. Do the same load the *right* way: validate in staging first, insert only clean rows, and never disable a constraint. Compare the two approaches in a comment — rows loaded, statements run, and what happens if the job crashes halfway.
9. Explain in a comment why `NOCHECK` cannot be used on the primary key, what `ALTER INDEX … DISABLE` would do instead, and why disabling a *clustered* index is catastrophic.
10. Drop all three scratch tables.

### Deliverable

`P6-bulk-load-constraints.sql`

### Hints

- The valid rows can come straight from `SELECT TaskId, UserId, WorkDate, Hours, Notes, IsBillable FROM app.TimeEntries` — 29 rows — plus a handful you invent.
- Only one constraint's error is reported per `ALTER TABLE`; you must fix and retry, which is exactly why requirement 6 exists.
- The re-enable error reads `The ALTER TABLE statement conflicted with the …` — different wording from the `INSERT`/`DELETE` forms.
- The crash-halfway question is about the window in which the table is loaded but untrusted, and about whether the `ALTER` and the load share a transaction.

### Look-fors (rubric)

- [ ] Step 4 successfully inserts rows that violate the disabled constraints, including the NULL `WorkDate` — or the script explains why that one is rejected regardless.
- [ ] Step 5's error is quoted verbatim.
- [ ] Step 6 has one targeted `NOT EXISTS` / range query per constraint, not one giant query.
- [ ] After step 7, every constraint on `app.TimeEntriesBulk` reports `is_disabled = 0` and `is_not_trusted = 0`.
- [ ] Step 8's comparison quantifies the difference rather than describing it.
- [ ] The step 9 explanation is correct about clustered index disabling making the table inaccessible.
- [ ] All scratch tables are dropped and `sys.foreign_keys` is back to 20 rows.

---

## P7 — Rules a `CHECK` Cannot Express  *(Hard)*

**Tags:** `filtered-unique-index` `indexed-view` `triggers` `cross-row-rules` `concurrency`

### Requirements

Implement three real TaskFlow rules, each with the *correct* mechanism, and prove each one works.

1. **At most one primary assignee per task.** Implement with a filtered unique index on `app.TaskAssignments`. Prove it creates successfully against the seeded data, then prove it blocks promoting a second assignee on task 4. State the error number.
2. **Total logged hours on a task must not exceed twice its estimate.** `CK` cannot see sibling rows. Implement with an `AFTER INSERT, UPDATE` trigger on `app.TimeEntries` that rolls back with a clear `THROW`. Test it against task 1 (estimate 24.00, currently 18.75 logged) by inserting an entry that pushes the total past 48.00.
3. **A project's tasks must all belong to that project's team's members** — a cross-table rule. Decide whether this belongs in a trigger, application logic, or nowhere at all, and justify the decision in a comment. Implement whichever you chose, or explain why the rule itself is wrong.
4. For each of the three rules, complete a row of this table in a comment: *rule / mechanism / enforced on INSERT? / enforced on UPDATE? / enforced on DELETE? / concurrency-safe? / cost per write*.
5. Show the failure mode of doing rule 2 with a scalar UDF inside a `CHECK`: write it, then construct a `DELETE` that breaks the invariant while the constraint is happy.
6. Explain why an indexed view would also work for rule 2, what `WITH SCHEMABINDING` and `COUNT_BIG(*)` are for, and which of the two you would ship.
7. Drop the index, the trigger, the function and anything else you created, and confirm the database is back to its seeded state.

### Deliverable

`P7-cross-row-rules.sql`

### Hints

- Rule 1's index succeeds because the 27 assigned tasks have exactly one `IsPrimary = 1` row each; the error on violation is **2601**.
- Task 1 already has 18.75 logged hours across three entries and an estimate of 24.00, so the threshold is 48.00.
- A trigger must handle **multi-row** DML — write it set-based against `inserted`, never with a cursor or `SELECT @x = …`.
- Rule 3 is a trap: team membership changes over time, so enforcing it retroactively would make historical rows illegal. Say so.
- The UDF failure in requirement 5 works because the constraint is never evaluated for rows a `DELETE` removes.

### Look-fors (rubric)

- [ ] The filtered index is created and the violating `UPDATE` on task 4 fails with 2601.
- [ ] The trigger is set-based, uses `EXISTS` over `inserted`, and calls `THROW` (not `RAISERROR` with severity 16 and no rollback).
- [ ] The trigger is proven to work for a multi-row insert, not just a single row.
- [ ] Rule 3's answer argues from temporal validity, not just from implementation difficulty.
- [ ] The requirement 4 table is complete for all three rules and honest about the `DELETE` column.
- [ ] The UDF demonstration actually breaks the invariant, with the row counts shown before and after.
- [ ] Every created object is dropped; `sys.check_constraints` is back to 6 and `app.TaskAssignments` has only its primary key index.

---

## P8 — Integrity Design Review  *(Hard)*

**Tags:** `design-review` `decision-table` `naming-conventions` `portability` `defence-in-depth`

### Requirements

TaskFlow is adding sprints. The proposed tables are:

```
app.Sprints      (SprintId, TeamId, SprintName, StartDate, EndDate, IsClosed, Goal)
app.SprintTasks  (SprintId, TaskId, AddedOn, CommittedPoints)
```

The product team has supplied fourteen rules:

1. A sprint always belongs to exactly one team.
2. `SprintName` is unique within a team, but archived teams may reuse names.
3. `EndDate` must be on or after `StartDate`.
4. A sprint is between 7 and 28 days long.
5. `IsClosed` defaults to false.
6. Two open sprints for the same team must not overlap in date range.
7. A task may appear in at most one **open** sprint at a time, but may appear in many closed ones.
8. A task can only be added to a sprint belonging to the same team as the task's project.
9. `CommittedPoints`, when supplied, must be a Fibonacci number.
10. Deleting a task removes it from all sprints.
11. Deleting a team must not be possible while it has sprints.
12. Closing a sprint is irreversible.
13. Only a team lead may close a sprint.
14. `Goal` is optional and free text, at most 500 characters.

Produce a written design review that, for **each** rule, states: the mechanism (`NOT NULL`, `PK`, `UNIQUE`, filtered unique index, `FK` + action, `CHECK`, `DEFAULT`, trigger, indexed view, stored procedure, application, authorisation layer), the reason, and the failure mode if you got it wrong. Then:

15. Write the complete, runnable `CREATE TABLE` DDL for both tables with every declarative rule implemented and every constraint named per the TaskFlow convention.
16. Write the DDL for every non-declarative mechanism you chose (indexes, triggers).
17. Add a `PRINT`-based smoke test proving at least four rules actually fire.
18. Add a portability section: which of your choices would not survive a port to PostgreSQL, MySQL and Oracle, and what you would use instead.
19. Add a rollback script that drops everything.

### Deliverable

`P8-integrity-review.md` for the review, decision table and portability section; `P8-sprints-ddl.sql` for the runnable DDL, triggers, smoke tests and rollback.

### Hints

- Rules 2 and 7 are both "unique among a subset" — filtered unique index, twice.
- Rule 4 is row-local arithmetic on two columns: `DATEDIFF(DAY, StartDate, EndDate)`. That is a `CHECK`.
- Rule 6 is a range-overlap rule. SQL Server has no `EXCLUDE` constraint; name what PostgreSQL would use.
- Rule 8 is cross-table **and** temporal — think hard before enforcing it, and say what you decided.
- Rule 12 needs the old value, so it needs `deleted`.
- Rule 13 is authorisation, not integrity. Do not put it in a constraint.
- Rule 14 is a data type decision, not a `CHECK`.

### Look-fors (rubric)

- [ ] All fourteen rules are assigned a mechanism with a stated reason and failure mode.
- [ ] Rules 13 and 14 are correctly *not* implemented as constraints, with the reasoning given.
- [ ] Every constraint in the DDL is named with the correct `PK_`/`FK_`/`UQ_`/`CK_`/`DF_`/`UX_` prefix.
- [ ] The DDL runs against a seeded `TaskFlowDb` without a 1785 error — the cascade choices are checked.
- [ ] Rule 10 uses `ON DELETE CASCADE` and rule 11 uses `NO ACTION`, with the composition/association reasoning stated.
- [ ] The smoke test causes at least four distinct error numbers and each is captured.
- [ ] The portability section names the missing filtered index in MySQL/Oracle and PostgreSQL's `EXCLUDE` constraint.
- [ ] The rollback script leaves `TaskFlowDb` exactly as seeded.

---

## Submission Checklist

- [ ] Every file runs top-to-bottom against a freshly seeded `TaskFlowDb` with no unintended errors.
- [ ] Every deliberate error is captured verbatim with its `Msg` number, and every one is explained.
- [ ] Every table reference is schema-qualified: `app.`, `ref.`, `audit.`.
- [ ] Every constraint you create is **named** using the TaskFlow prefix convention.
- [ ] Every constraint you add to a real table is added `WITH CHECK` and verified `is_not_trusted = 0`.
- [ ] Every destructive statement against a real TaskFlow table is inside `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- [ ] No `CHECK` constraint relies on NULL being rejected.
- [ ] Every scratch table, index, trigger and function is dropped at the end of its own file.
- [ ] The final state of the database matches the seed: 13 PK, 6 UQ, 20 FK, 6 CHECK, 16 DEFAULT, 0 untrusted.
- [ ] `SELECT COUNT(*) FROM app.Tasks;` still returns 35.

## Stretch Goals

1. **Constraint cost measurement.** Insert 100,000 rows into a clone of `app.TimeEntries` with all constraints enabled, then with foreign keys disabled, then with the check constraint disabled too. Report elapsed time and logical writes for each. Then argue whether the numbers justify anything.
2. **Deferred constraints, emulated.** PostgreSQL can defer a foreign key to commit time, which makes circular inserts trivial. SQL Server cannot. Design a way to insert a mutually-referencing pair (`app.Teams.LeadUserId` and a hypothetical `app.Users.PrimaryTeamId`) and compare it against the PostgreSQL solution.
3. **Trust drift detector.** Write a stored procedure that snapshots every constraint's `is_disabled`/`is_not_trusted` into a table, and a second that diffs today's snapshot against yesterday's. This is the shape of a real production guardrail.
4. **Constraint-driven plan simplification.** Find three queries against TaskFlow whose plans change when a specific constraint is untrusted. Document each with the before/after plan shape and the constraint responsible.
5. **`MERGE` and constraints.** Write a `MERGE` into `app.TaskLabels` and determine, experimentally, whether the foreign keys are checked per action or once at the end. Then read up on why many teams ban `MERGE` anyway (Topic 10).
6. **Cross-database integrity.** Foreign keys cannot span databases. Design how you would enforce referential integrity between `TaskFlowDb.app.Tasks` and a separate `TaskFlowAuditDb`, and list the three ways it will eventually drift.
