# Topic 21 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-ado-net-parameters.cs` | P1 — Raw ADO.NET: parameters done right and wrong | C# snippet |
| `P2-connection-pooling.cs` | P2 — Connection pooling behavior | C# snippet |
| `P3-dapper-patterns.cs` | P3 — Dapper: query, multi-mapping, stored procedures | C# snippet |
| `P4-n-plus-one.cs` | P4 — Reproducing and fixing N+1 in EF Core | C# snippet |
| `P5-asnotracking.cs` | P5 — `AsNoTracking()` and its effect | C# snippet |
| `P6-raw-sql-recursive-cte.cs` | P6 — Safe raw SQL in EF Core for a recursive CTE | C# snippet |
| `P7-three-layers-comparison.cs` | P7 — Same requirement, three layers (code) | C# snippet |
| `P7-comparison-table.md` | P7 — Same requirement, three layers (write-up) | Markdown |

## Conventions

- Every SQL-reaching value in every snippet is parameterised — no string concatenation of variable/user data into a SQL string anywhere.
- Every data-access call uses the async APIs (`OpenAsync`, `ExecuteReaderAsync`, `QueryAsync`, `ToListAsync`, etc.).
- These are focused code **snippets** demonstrating the pattern under discussion, matching the style of Phase 5's EF Core topic — not full runnable console/API projects. Assume a `TaskFlowDbContext`/connection string wired up elsewhere.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
