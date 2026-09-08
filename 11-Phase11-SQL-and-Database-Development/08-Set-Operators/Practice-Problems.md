# Topic 08: Set Operators — Practice Problems

> Six exercises that use `UNION`, `INTERSECT` and `EXCEPT` for exactly what they're good at: comparing whole result sets, not correlating rows by key. All against the seeded `TaskFlowDb`.

**Concept tags:** `union` `union-all` `intersect` `except` `null-semantics` `reconciliation` `values-constructor`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — `UNION` vs `UNION ALL`  *(Easy)*

**Tags:** `union` `union-all` `dedup-cost`

### Requirements

1. Build a single "contacts" report by stacking `app.Users.Email` and a synthetic `NULL` placeholder for every `app.Teams.TeamName` that has no lead, using `UNION ALL`.
2. Rewrite the same query with plain `UNION` and explain in a comment whether the row count changed and why.
3. Find a genuine case in the schema where `UNION` (not `UNION ALL`) changes the row count — i.e., where the two legs can produce an identical row. Show both versions side by side with their row counts.
4. State the rule for when `UNION ALL` is safe to default to.

### Deliverable

`P1-union-vs-union-all.sql`.

### Hints

- Column names in the final result come from the **first** `SELECT` only — say what happens if you alias differently on each leg.
- A genuine duplicate is easiest to manufacture between two columns that share the same domain, e.g. two different filters over the same table's same column.

### Look-fors (rubric)

- [ ] Both forms compile and return rows.
- [ ] The genuine-duplicate case actually demonstrates a different row count between `UNION` and `UNION ALL`.
- [ ] The "default to `UNION ALL`" rule is stated with a reason, not just asserted.

---

## P2 — Column Rules: Count, Type, Naming, `ORDER BY`  *(Easy)*

**Tags:** `set-operator-rules` `type-precedence`

### Requirements

1. Deliberately violate the "same column count" rule and capture the exact error.
2. Union `app.Users.UserId` (`INT`) with `app.Projects.Budget` (`DECIMAL(12,2)`) and state, from the result's data type, which type won under data type precedence.
3. Alias columns differently on each leg of a `UNION ALL` and confirm which alias appears in the final result set.
4. Deliberately put an `ORDER BY` inside the first leg of a `UNION ALL` (not at the very end) and capture the exact error. Then fix it.

### Deliverable

`P2-set-operator-rules.sql` with all captured errors kept as comments.

### Hints

- Errors to expect: "unequal number of columns", an implicit-conversion result type, Msg 156.

### Look-fors (rubric)

- [ ] All three deliberate errors are reproduced and pasted verbatim.
- [ ] The winning data type after precedence is stated correctly.
- [ ] The fixed `ORDER BY` version is included and runs.

---

## P3 — The Set-Operator NULL Rule  *(Medium)*

**Tags:** `null` `is-not-distinct-from` `intersect`

### Requirements

1. Prove, with a minimal query (`SELECT NULL INTERSECT SELECT NULL`), that two NULLs are treated as equal by `INTERSECT`.
2. Prove, with `WHERE NULL = NULL`, that ordinary equality does **not** consider two NULLs equal.
3. Using `app.Tasks.EstimatedHours`, find a pair of `TaskId`s that both have a NULL estimate and show that `INTERSECT` matches them on that column while a `JOIN … ON a.EstimatedHours = b.EstimatedHours` would not.
4. Summarize the rule in one sentence, referencing "distinctness" rather than "equality".

### Deliverable

`P3-null-semantics.sql`.

### Hints

- Tasks 8, 18, 25 and 29 all have a NULL `EstimatedHours`.

### Look-fors (rubric)

- [ ] Both minimal proofs run and return the stated results.
- [ ] The task-level demonstration correctly contrasts `INTERSECT` against a literal `JOIN ON =`.
- [ ] The one-sentence summary correctly uses "distinct from", not "equal to".

---

## P4 — `EXCEPT` as an Anti-Join, and Direction Sensitivity  *(Medium)*

**Tags:** `except` `anti-join` `not-exists`

### Requirements

1. Find every user who has never been assigned a task, using `EXCEPT` between `app.Users.UserId` and `app.TaskAssignments.UserId`. Confirm 6 rows.
2. Rewrite the same question using `NOT EXISTS`, confirm identical `UserId`s, and add `FullName`/`Email` columns that the `EXCEPT` version cannot express.
3. Run `EXCEPT` in **both directions** between `app.TaskAssignments.UserId` and `app.Users.UserId`, and explain in a comment why one direction is always guaranteed empty by the schema (name the constraint).
4. State, in a comment table, when you'd choose `EXCEPT` over `NOT EXISTS` and vice versa.

### Deliverable

`P4-except-anti-join.sql`.

### Hints

- The guaranteed-empty direction relies on `FK_TaskAssign_User`.

### Look-fors (rubric)

- [ ] Both approaches agree on exactly 6 users.
- [ ] The `NOT EXISTS` version projects extra columns that `EXCEPT` cannot.
- [ ] The FK-backed reasoning for the guaranteed-empty direction is explicit and correctly named.

---

## P5 — Regression-Testing a Query Rewrite with `EXCEPT`  *(Medium)*

**Tags:** `except` `regression-testing` `reconciliation`

### Requirements

1. Write an "old" query that returns `TaskId`, `ProjectId`, `Title` for every task with `PriorityId IN (1, 2)`, using a subquery-based filter.
2. Write a "new" query that returns the same three columns using a `JOIN` to `ref.Priorities` filtered on `PriorityName IN (N'Critical', N'High')`.
3. Run `EXCEPT` in both directions between old and new. If either direction returns rows, the rewrite is **not** equivalent — fix it until both directions are empty.
4. Explain, in a comment, one limitation of this technique (what kind of bug would it miss).

### Deliverable

`P5-regression-diff.sql`.

### Hints

- Both queries must select the exact same column list, in the same order, with the same types, for `EXCEPT` to compare them meaningfully.
- A limitation to consider: column-level diffing, or rows that match on the selected columns but differ on an unselected one.

### Look-fors (rubric)

- [ ] Old and new queries are genuinely different SQL that (after any needed fix) produce the same rows.
- [ ] Both `EXCEPT` directions are shown returning zero rows once the rewrite is correct.
- [ ] The stated limitation is specific and correct (not generic "it might be slow").

---

## P6 — `VALUES` Constructor vs `UNION ALL` of Literals  *(Medium)*

**Tags:** `values-constructor` `union-all` `inline-lookup`

### Requirements

1. Build an inline priority-to-SLA lookup using `UNION ALL` of five single-row `SELECT`s (mirroring `ref.Priorities`, but as a literal, disconnected table).
2. Rewrite the identical lookup as a single `VALUES` table constructor with a column alias list.
3. Join each version to `app.Tasks` (on priority code, faked via a `CASE` translating `PriorityId` to a code, or by joining `ref.Priorities` first) and confirm both produce identical output.
4. Compare the two versions' plans and state which plan operator disappears in the `VALUES` version.

### Deliverable

`P6-values-vs-union-all.sql`.

### Hints

- `(VALUES (1,'a'), (2,'b')) AS v (Id, Code)` is the syntax.

### Look-fors (rubric)

- [ ] Both lookup constructions return the same 5 rows in the same shape.
- [ ] The join results (against real task data) are identical between versions.
- [ ] The plan comparison correctly identifies the extra concatenation/union operator in the `UNION ALL` version.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All six `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every deliberately-triggered error (P2) is captured verbatim as a comment, not paraphrased.
- [ ] Row counts you assert are actually verified by running the query, not assumed.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Read about PostgreSQL's `EXCEPT ALL`/`INTERSECT ALL` (which SQL Server lacks) and write the T-SQL workaround using `ROW_NUMBER()` to simulate multiset (duplicate-preserving) set difference.
- Build a small stored procedure that takes two table names and a column list, and returns a reconciliation report (`EXCEPT` both directions) as a single result set with a `Source` column indicating which side each row came from.
- Investigate `GROUPING SETS` (Topic 05) as an alternative to `UNION ALL`-ing several differently-grouped aggregate queries together.
