# Topic 09 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-ranking-functions.sql` | P1 — Ranking functions side by side | T-SQL script |
| `P2-percent-of-total.sql` | P2 — Percent of total & integer-division trap | T-SQL script |
| `P3-frames-and-running-totals.sql` | P3 — Running totals & the default-frame trap | T-SQL script |
| `P4-lag-lead-first-last.sql` | P4 — `LAG`/`LEAD` & the `LAST_VALUE` trap | T-SQL script |
| `P5-topn-and-dedup.sql` | P5 — Top-N per group & deduplication | T-SQL script |
| `P6-gaps-and-islands.sql` | P6 — Gaps and islands: work-day streaks | T-SQL script |
| `P7-sessionisation-and-poc-index.sql` | P7 — Sessionisation & a POC index | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Keep "broken" versions (missing frame, missing tie-breaker) as commented-out blocks next to the fix — the contrast is the point.
- Always `SELECT` before you `DELETE` when deduplicating (P5).

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
