# Topic 07 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-scalar-subqueries.sql` | P1 — Scalar subqueries & Msg 512 | T-SQL script |
| `P2-in-any-all.sql` | P2 — `IN`/`ANY`/`ALL` & empty-set rules | T-SQL script |
| `P3-not-in-null-trap.sql` | P3 — The `NOT IN` NULL trap | T-SQL script |
| `P4-correlated-vs-apply.sql` | P4 — Correlated subqueries vs `APPLY` | T-SQL script |
| `P5-derived-vs-cte.sql` | P5 — Derived tables vs CTE chains | T-SQL script |
| `P6-org-chart-recursive.sql` | P6 — Recursive org chart | T-SQL script |
| `P7-cycle-detection-and-rollup.sql` | P7 — Cycle detection & task rollup | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Keep deliberately-broken queries as commented-out blocks — do not delete evidence of the trap you diagnosed.
- Where a problem asks you to compare two approaches, keep both in the file, one after another, not just the final answer.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
