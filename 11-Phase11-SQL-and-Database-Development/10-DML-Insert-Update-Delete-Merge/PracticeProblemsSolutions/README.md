# Topic 10 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-insert-and-identity.sql` | P1 — Disciplined `INSERT` & identity capture | T-SQL script |
| `P2-update-from-trap.sql` | P2 — The `UPDATE ... FROM` multi-match trap | T-SQL script |
| `P3-output-audit-trail.sql` | P3 — `OUTPUT` for an audit trail | T-SQL script |
| `P4-delete-vs-truncate.sql` | P4 — `DELETE` vs `TRUNCATE TABLE` | T-SQL script |
| `P5-batched-purge.sql` | P5 — Batched purge loop | T-SQL script |
| `P6-merge-and-alternative.sql` | P6 — `MERGE` upsert & its concurrency caveat | T-SQL script |
| `P7-cursor-vs-set-based.sql` | P7 — Cursor (RBAR) vs set-based rewrite | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- This topic is destructive by nature. Wrap experiments in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`, or finish the file with a re-run of the create script.
- Never leave the shared seed data permanently modified unless a problem explicitly says to keep the change.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
