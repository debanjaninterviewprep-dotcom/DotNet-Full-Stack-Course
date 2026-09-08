# Topic 19 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-cause-and-fix-injection.sql` | P1 — Cause and fix a real injection | T-SQL script |
| `P2-second-order-injection.sql` | P2 — Second-order injection | T-SQL script |
| `P3-safe-dynamic-order-by.sql` | P3 — Safe dynamic `ORDER BY` with an allow-list | T-SQL script |
| `P4-least-privilege.sql` | P4 — Least privilege: logins, users, roles | T-SQL script |
| `P5-dynamic-data-masking.sql` | P5 — Dynamic data masking | T-SQL script |
| `P6-defense-in-depth-review.md` | P6 — Defense in depth: design review | Markdown |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- No deliberately vulnerable procedure persists beyond its own demonstration script — drop it before the file ends.
- Every test login/user/role created for an experiment is dropped at the end of its own file.
- Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`; masking/permission changes to the real schema are reverted.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
