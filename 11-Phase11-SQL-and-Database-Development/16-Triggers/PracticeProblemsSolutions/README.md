# Topic 16 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-basic-audit-trigger.sql` | P1 — A basic audit trigger | T-SQL script |
| `P2-set-based-proof.sql` | P2 — Proving the set-based requirement | T-SQL script |
| `P3-hours-cap-trigger.sql` | P3 — Cross-row enforcement: the hours cap trigger | T-SQL script |
| `P4-instead-of-soft-delete.sql` | P4 — `INSTEAD OF` trigger: soft delete | T-SQL script |
| `P5-instead-of-view-write.sql` | P5 — `INSTEAD OF` trigger: writable multi-table view | T-SQL script |
| `P6-trigger-judgment.md` | P6 — When *not* to use a trigger (write-up) | Markdown |
| `P6-trigger-implementations.sql` | P6 — Any triggers actually implemented | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every trigger is tested against a **multi-row** DML statement, not just a single-row one.
- Every trigger created for an experiment is dropped at the end of its own file.
- Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
