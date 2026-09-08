# Topic 13 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-seek-scan-lookup.sql` | P1 — Reading Seek vs Scan vs Key Lookup | T-SQL script |
| `P2-covering-index.sql` | P2 — Eliminating a Key Lookup with a covering index | T-SQL script |
| `P3-composite-column-order.sql` | P3 — Composite index column order | T-SQL script |
| `P4-selectivity-and-statistics.sql` | P4 — Selectivity and statistics | T-SQL script |
| `P5-filtered-index.sql` | P5 — Filtered index for a hot subset | T-SQL script |
| `P6-missing-index-dmv.sql` | P6 — Missing index DMVs on a larger synthetic table | T-SQL script |
| `P7-diagnose-and-fix.sql` | P7 — Diagnose and fix: a slow reporting query | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every index created for an experiment is dropped at the end of its own file, unless a later problem in the same file still needs it.
- Every plan/DMV claim is backed by output actually captured in the file, not assumed.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
