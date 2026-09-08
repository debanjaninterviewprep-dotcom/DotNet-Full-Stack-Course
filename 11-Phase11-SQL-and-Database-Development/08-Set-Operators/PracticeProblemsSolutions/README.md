# Topic 08 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-union-vs-union-all.sql` | P1 — `UNION` vs `UNION ALL` | T-SQL script |
| `P2-set-operator-rules.sql` | P2 — Column count/type/naming/`ORDER BY` rules | T-SQL script |
| `P3-null-semantics.sql` | P3 — The set-operator NULL rule | T-SQL script |
| `P4-except-anti-join.sql` | P4 — `EXCEPT` as an anti-join | T-SQL script |
| `P5-regression-diff.sql` | P5 — Regression-testing a rewrite with `EXCEPT` | T-SQL script |
| `P6-values-vs-union-all.sql` | P6 — `VALUES` constructor vs `UNION ALL` of literals | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Keep deliberately-triggered errors as commented-out blocks with the exact message pasted above them.
- When comparing two approaches, keep both queries in the file — do not delete the "before" version once you have the "after".

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
