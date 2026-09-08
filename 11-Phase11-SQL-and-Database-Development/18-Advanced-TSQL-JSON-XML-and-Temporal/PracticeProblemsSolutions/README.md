# Topic 18 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-json-value-query-modify.sql` | P1 — Reading/modifying JSON with `JSON_VALUE`/`JSON_QUERY`/`JSON_MODIFY` | T-SQL script |
| `P2-openjson-shredding.sql` | P2 — Shredding JSON with `OPENJSON` | T-SQL script |
| `P3-for-json-production.sql` | P3 — Producing JSON with `FOR JSON` | T-SQL script |
| `P4-xml-basics.sql` | P4 — XML basics: `.value()`/`.exist()`/`.nodes()` | T-SQL script |
| `P5-temporal-tables.sql` | P5 — Retrofit a table with system-versioned history | T-SQL script |
| `P6-json-vs-columns-vs-temporal.md` | P6 — Design decision: JSON vs columns vs temporal | Markdown |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every scratch table (including temporal ones) is dropped at the end of its own file — system versioning disabled first where applicable.
- Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
