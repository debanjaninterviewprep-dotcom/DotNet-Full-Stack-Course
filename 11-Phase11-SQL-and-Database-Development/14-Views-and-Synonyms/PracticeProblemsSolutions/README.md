# Topic 14 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-basic-view.sql` | P1 — A basic encapsulating view | T-SQL script |
| `P2-updatable-view-boundary.sql` | P2 — The updatable view boundary | T-SQL script |
| `P3-check-option.sql` | P3 — `WITH CHECK OPTION` | T-SQL script |
| `P4-indexed-view.sql` | P4 — Building and measuring an indexed view | T-SQL script |
| `P5-security-views.sql` | P5 — Views for column and row security | T-SQL script |
| `P6-synonyms-cutover.sql` | P6 — Synonyms for location abstraction & cutover | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every view, synonym, index, and scratch table created for an experiment is dropped at the end of its own file.
- Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
