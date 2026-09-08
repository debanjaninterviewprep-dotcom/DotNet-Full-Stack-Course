# Topic 16: Triggers — Practice Problems

> Six exercises covering `AFTER` triggers, `INSTEAD OF` triggers, the set-based discipline every trigger requires, and — just as important — recognising when a trigger is the wrong tool. All against the seeded `TaskFlowDb`.

**Concept tags:** `after-triggers` `instead-of-triggers` `inserted-deleted` `set-based` `soft-delete` `cross-row-rules` `recursive-triggers`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — A Basic Audit Trigger  *(Easy)*

**Tags:** `after-triggers` `inserted-deleted` `audit`

### Requirements

1. Create `audit.trg_Tasks_StatusChange` on `app.Tasks AFTER UPDATE`, writing to `audit.TaskHistory` only when `StatusId` actually changes value (not just when it was targeted by the `SET` list).
2. Update one task's `StatusId` to a genuinely different value and confirm a row landed in `audit.TaskHistory`.
3. Update one task's `StatusId` to its **existing** value (a no-op change) and confirm **no** row was added — explain why `UPDATE(StatusId)` alone would have been insufficient here.
4. Roll back all data changes; drop the trigger.

### Deliverable

`P1-basic-audit-trigger.sql`. Wrap data changes in a transaction you roll back.

### Hints

- `UPDATE(StatusId)` only tells you the column was in the `SET` list — compare `deleted.StatusId <> inserted.StatusId` for an actual value change.

### Look-fors (rubric)

- [ ] The genuine status change produces exactly one audit row with correct old/new values.
- [ ] The no-op update produces zero audit rows.
- [ ] The `UPDATE(col)` vs value-comparison distinction is correctly explained.
- [ ] Data rolled back; trigger dropped.

---

## P2 — Proving the Set-Based Requirement  *(Easy)*

**Tags:** `set-based` `multi-row-update` `broken-trigger`

### Requirements

1. Create the deliberately broken, single-row-assuming trigger from Notes.md §3 (`trg_Tasks_Bad`-style) on a **scratch** copy of the relevant tables (not the real `app.Tasks`/`app.Projects`) so you can safely break it.
2. Fire it with a multi-row `UPDATE` (at least 3 rows in one statement) and demonstrate the incorrect behavior — either an error or silently wrong results affecting only one row.
3. Rewrite it as the correct, set-based version and demonstrate it handles the same multi-row `UPDATE` correctly.
4. Explain, in a comment, exactly which part of the broken version assumed a single row.

### Deliverable

`P2-set-based-proof.sql`. Use scratch tables only; drop everything at the end.

### Hints

- `SELECT @var = col FROM inserted` with more than one row in `inserted` picks a value from an arbitrary row, not an error — that's what makes this bug dangerous (silent, not loud).

### Look-fors (rubric)

- [ ] The broken version's failure is demonstrated on a genuine multi-row statement, not just described.
- [ ] The fixed version correctly processes every row of the multi-row statement.
- [ ] The explanation correctly identifies the singular-variable-assignment pattern as the root cause.
- [ ] All scratch objects are dropped.

---

## P3 — Cross-Row Enforcement: the Hours Cap Trigger  *(Medium)*

**Tags:** `after-triggers` `cross-row-rules` `rollback` `throw`

### Requirements

1. Create the hours-cap trigger from Notes.md §4 on `app.TimeEntries`, enforcing "total logged hours ≤ 2× estimate."
2. Using task 1 (estimate 24.00, currently 18.75 logged), insert a time entry that would push the total past 48.00 and confirm the whole `INSERT` is rolled back with your custom error.
3. Insert a smaller entry that stays under the cap and confirm it succeeds.
4. Test the trigger against a **multi-row** `INSERT` where one row would violate the cap and others wouldn't — confirm the entire statement rolls back (not just the offending row).
5. Roll back all data changes; drop the trigger.

### Deliverable

`P3-hours-cap-trigger.sql`.

### Hints

- A single `THROW`/`ROLLBACK` inside an `AFTER` trigger undoes the **entire** firing statement, not just the row(s) that violated the rule.

### Look-fors (rubric)

- [ ] The over-cap single insert is correctly rejected with the custom error.
- [ ] The under-cap insert succeeds.
- [ ] The multi-row test correctly shows the whole statement rolling back, including the otherwise-valid rows.
- [ ] Data rolled back; trigger dropped.

---

## P4 — `INSTEAD OF` Trigger: Soft Delete  *(Medium)*

**Tags:** `instead-of-triggers` `soft-delete`

### Requirements

1. Create `app.trg_Projects_SoftDelete` as an `INSTEAD OF DELETE` trigger on `app.Projects` that sets `IsArchived = 1` instead of physically deleting the row.
2. Run `DELETE FROM app.Projects WHERE ProjectId = 8;` and confirm the row **still exists** but is now archived.
3. Confirm `@@ROWCOUNT` after the `DELETE` statement, and explain what it's actually counting given the trigger intercepted the real operation.
4. Attempt the same `DELETE` against a project that has open child tasks (e.g. project 1) and explain, in a comment, whether your trigger's `UPDATE` succeeds or fails given the existing foreign keys — and why that's different from what a real `DELETE` would have done.
5. Roll back all data changes; drop the trigger.

### Deliverable

`P4-instead-of-soft-delete.sql`.

### Hints

- An `INSTEAD OF DELETE` trigger means the real `DELETE` (and its FK checks against child tables) **never runs** — your `UPDATE` inside the trigger has entirely different constraint implications.

### Look-fors (rubric)

- [ ] The project row survives the `DELETE` statement and is correctly marked archived.
- [ ] `@@ROWCOUNT`'s meaning under `INSTEAD OF` is correctly explained.
- [ ] The project-1 case correctly identifies that the `UPDATE` (not a `DELETE`) is what actually runs, and reasons about whether that succeeds despite child tasks existing.
- [ ] Data rolled back; trigger dropped.

---

## P5 — `INSTEAD OF` Trigger: Making a Multi-Table View Writable  *(Hard)*

**Tags:** `instead-of-triggers` `updatable-views` `view-write-through`

### Requirements

1. Create `app.vw_TaskWithProjectName` joining `app.Tasks` and `app.Projects`.
2. Attempt a two-table `UPDATE` through it directly (no trigger yet) and confirm it fails with Msg 4405 (Topic 14).
3. Add `app.trg_vw_TaskWithProjectName_Update` as an `INSTEAD OF UPDATE` trigger that writes `Title`/`StatusId` changes back to `app.Tasks` only, deliberately **not** propagating `ProjectName` changes to `app.Projects`.
4. Demonstrate the same two-table `UPDATE` statement that failed in step 2 now "succeeds" through the trigger — then prove, with a follow-up `SELECT`, that `app.Projects.ProjectName` was **not** actually changed, even though the `UPDATE` statement's `SET` clause mentioned it.
5. Explain, in a comment, why this silent-partial-write behavior is a design decision that must be documented, not a bug — and sketch (in prose) how you would change the trigger if the requirement were instead "reject the whole statement if it touches `ProjectName`."
6. Roll back all data changes; drop the trigger and the view.

### Deliverable

`P5-instead-of-view-write.sql`.

### Hints

- The rejection-instead-of-silent-partial-write version would check `inserted`/`deleted` for a `ProjectName` difference and `THROW` if found, before doing anything else.

### Look-fors (rubric)

- [ ] Step 2's Msg 4405 is captured verbatim.
- [ ] The `INSTEAD OF` trigger correctly updates `app.Tasks` and correctly leaves `app.Projects` untouched.
- [ ] The silent-partial-write behavior is proven with a follow-up `SELECT`, not just asserted.
- [ ] The "reject instead" alternative is correctly sketched.
- [ ] Data rolled back; trigger and view dropped.

---

## P6 — When *Not* to Use a Trigger  *(Hard)*

**Tags:** `trigger-vs-application-logic` `design-judgment` `external-calls`

### Requirements

TaskFlow's product team proposes four new rules. For each, decide whether a trigger is the right mechanism, and justify your answer using the decision table in Notes.md §8:

1. "When a task's `StatusId` changes to Done, send the assignee an email notification."
2. "When a task is created, default its `PriorityId` to Medium if the caller didn't specify one."
3. "When a comment is deleted, also delete any of its direct replies (cascade one level, not the whole subtree)."
4. "When a user's `HourlyRate` changes, recompute and cache a `TotalLoggedCost` rollup column on every task they've logged time against."

For each, write: your recommendation (trigger / constraint / application logic / other), the specific reason from the decision table, and — for any you'd implement as a trigger — the actual `CREATE TRIGGER` statement, tested.

### Deliverable

`P6-trigger-judgment.md` for the four recommendations and reasoning, `P6-trigger-implementations.sql` for any triggers you chose to actually write and test (roll back all data changes; drop everything at the end).

### Hints

- Rule 1 involves an external system (email) — re-read Notes.md §8's specific line about this.
- Rule 3 is a legitimate cross-row cascade a `FOREIGN KEY ON DELETE CASCADE` cannot express (it only cascades one level based on the schema, but "direct replies only, not the whole subtree" needs care — compare against just using `ON DELETE CASCADE` on `FK_Comments_Parent` and explain why that alone would (or wouldn't) already satisfy this).
- Rule 4 is a denormalization-maintenance question from Topic 12 §8 as much as a trigger question.

### Look-fors (rubric)

- [ ] Rule 1 is correctly identified as **not** a trigger's job, specifically because of the external-call/transaction-blocking reasoning.
- [ ] Rule 2 is correctly identified as a `DEFAULT` constraint, not a trigger (no cross-row logic needed).
- [ ] Rule 3's answer correctly reasons about what `ON DELETE CASCADE` on the existing self-referencing FK already does or doesn't cover, before reaching for a trigger.
- [ ] Rule 4's answer correctly connects back to Topic 12's denormalization-maintenance-mechanism framing.
- [ ] Any triggers actually implemented are tested and correctly set-based.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All deliverables exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every trigger is tested against a **multi-row** DML statement, not just a single-row one.
- [ ] Every trigger created for an experiment is dropped at the end of its own file.
- [ ] Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Investigate `sp_settriggerorder` and demonstrate controlling the firing order of two `AFTER INSERT` triggers on the same table.
- Research `CREATE TRIGGER ... ON DATABASE` / `ON ALL SERVER` (DDL triggers) and sketch one that would prevent any table in `TaskFlowDb` from being dropped without a specific extended property being set first.
- Read about `CONTEXT_INFO`/`SESSION_CONTEXT` as a way to let application code signal "skip this trigger's rule for this one statement" (e.g. for a verified data-repair script), and write two sentences on the security implications of that escape hatch.
