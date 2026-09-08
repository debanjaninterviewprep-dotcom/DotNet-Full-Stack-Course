# Topic 20 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-wait-statistics.sql` | P1 — Reading wait statistics | T-SQL script |
| `P2-plan-cache-culprit.sql` | P2 — Finding the culprit query via the plan cache | T-SQL script |
| `P3-query-store-regression.sql` | P3 — Query Store: detecting a plan regression | T-SQL script |
| `P4-live-session-investigation.sql` | P4 — Live session investigation | T-SQL script (2 sessions) |
| `P5-statistics-staleness.sql` | P5 — Statistics staleness and its consequences | T-SQL script |
| `P6-full-diagnostic-narrative.sql` | P6 — Full diagnostic narrative: reproduce & resolve | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every diagnostic claim is backed by captured output in the file, not asserted.
- Query Store, if enabled, is left in a documented state (forced plans unforced, disabled if not needed further).
- All scratch/synthetic tables are dropped at the end of their own files.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
