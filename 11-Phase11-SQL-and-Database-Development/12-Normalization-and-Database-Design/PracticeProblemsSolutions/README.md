# Topic 12 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-denormalize-renormalize.sql` | P1 — Denormalize, then renormalize | T-SQL script |
| `P2-functional-dependencies.md` | P2 — Functional dependency analysis | Markdown |
| `P3-fourth-normal-form.sql` | P3 — 4NF: splitting an independent multi-valued table | T-SQL script |
| `P4-er-diagram.md` | P4 — ER diagram and weak entities | Markdown (Mermaid) |
| `P5-surrogate-vs-natural.sql` | P5 — Surrogate vs natural key DDL | T-SQL script |
| `P5-key-decision-table.md` | P5 — Surrogate vs natural key decision table | Markdown |
| `P6-task-dependencies.sql` | P6 — Design a hierarchy: task dependencies | T-SQL script |
| `P7-sprints-design-review.md` | P7 — Full design review: adding Sprints | Markdown |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Scratch objects (`#temp` tables) must be self-contained and re-runnable against a freshly seeded database.
- Every claim about an anomaly, dependency, or design decision must reference specific TaskFlow tables/columns/values — no generic placeholders.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
