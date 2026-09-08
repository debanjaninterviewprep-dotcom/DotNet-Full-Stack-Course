# Topic 11 — Practice Solutions

This folder is your scratchpad for the eight exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-constraint-inventory.sql` | P1 — Constraint inventory | T-SQL script |
| `P2-unique-and-nulls.sql` | P2 — The one-NULL rule | T-SQL script |
| `P3-check-constraints.sql` | P3 — Domain integrity with `CHECK` | T-SQL script |
| `P4-referential-actions.sql` | P4 — Referential actions & cascade paths | T-SQL script |
| `P5-untrusted-constraints.sql` | P5 — Untrusted constraints & the optimizer | T-SQL script |
| `P6-bulk-load-constraints.sql` | P6 — Bulk load with constraints disabled | T-SQL script |
| `P7-cross-row-rules.sql` | P7 — Rules a `CHECK` cannot express | T-SQL script |
| `P8-integrity-review.md` | P8 — Integrity design review (write-up) | Markdown |
| `P8-sprints-ddl.sql` | P8 — Integrity design review (runnable DDL) | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every deliberately-triggered error is captured verbatim, with its `Msg` number, as a comment.
- Every object you create (scratch tables, indexes, triggers, functions) is dropped at the end of its own file.
- Every destructive statement against a **real** TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- Every constraint you add is named with the TaskFlow prefix convention (`PK_`, `FK_`, `UQ_`, `CK_`, `DF_`, `UX_` for filtered unique indexes).

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

## Final-state check

The database should always end each file matching the seed: 13 primary keys, 6 unique constraints, 20 foreign keys, 6 check constraints, 16 default constraints, 0 disabled/untrusted.

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
