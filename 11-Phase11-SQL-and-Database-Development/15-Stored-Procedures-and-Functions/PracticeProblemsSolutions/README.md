# Topic 15 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-basic-procedure.sql` | P1 — A parameterised procedure with defaults & output | T-SQL script |
| `P2-table-valued-parameters.sql` | P2 — Table-valued parameters for bulk operations | T-SQL script |
| `P3-dynamic-sql.sql` | P3 — Safe dynamic SQL with `sp_executesql` | T-SQL script |
| `P4-try-catch-throw.sql` | P4 — `TRY/CATCH`, `THROW`, and transaction state | T-SQL script |
| `P5-scalar-udf-trap.sql` | P5 — The scalar UDF performance trap | T-SQL script |
| `P6-parameter-sniffing.sql` | P6 — Observing parameter sniffing | T-SQL script |
| `P7-assign-and-notify-workflow.sql` | P7 — Design and build: assign-and-notify workflow | T-SQL script |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every procedure/function/type created for an experiment is dropped at the end of its own file.
- Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- P3's deliberately vulnerable procedure never persists beyond its own demonstration — drop it in the same script.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
