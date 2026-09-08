# Topic 03 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

Each starter file already contains the problem restated as a comment header plus a `-- TODO: your solution here` marker. Fill them in — do not rename the files.

| File | Problem | Difficulty | Focus |
|---|---|---|---|
| `P1-board-projection.sql` | P1 — The Task Board Projection | Easy | Projection, aliases, `SELECT *` |
| `P2-overdue-filter.sql` | P2 — The Overdue Filter | Easy | `WHERE`, `AND`/`OR` precedence, `NULL` |
| `P3-range-and-null-traps.sql` | P3 — Ranges, Sets and the NULL Traps | Medium | `BETWEEN`, `NOT IN`, `NOT EXISTS` |
| `P4-pattern-search.sql` | P4 — Pattern Search Across Titles and Metadata | Medium | `LIKE`, `ESCAPE`, collation, SARGability |
| `P5-sorting-and-topn.sql` | P5 — Deterministic Sorting and Top-N | Medium | `ORDER BY`, `NULL` ordering, `TOP`, `DISTINCT` |
| `P6-pagination.sql` | P6 — Two Pagination Engines | Hard | `OFFSET…FETCH` vs keyset |
| `P7-sargability-audit.sql` | P7 — SARGability Audit and Plan Report | Hard | Predicate rewrites, plans, implicit conversion |

## Prerequisites

The shared sample database must exist. Run it once:

```bash
sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
```

Then start every script with:

```sql
USE TaskFlowDb;
GO
```

## Conventions

- **Schema-qualify everything**: `app.Tasks`, `ref.Priorities`, `audit.TaskHistory`. Never a bare `Tasks`.
- **Alias every table**, prefix every column with its alias.
- **No `SELECT *`** in a final answer. Commented-out demonstrations are fine and are explicitly asked for in P1.
- **Half-open date ranges**: `>= @start AND < @endExclusive`. Never `BETWEEN` on a `DATETIME2` column.
- **Every paged `ORDER BY` ends with a unique column.**
- Record row counts, error numbers, and logical reads **as comments** where the problem asks for them. The comment is part of the deliverable.

## Leave the database as you found it

P6 and P7 ask you to create indexes. Every script that creates one must drop it:

```sql
DROP INDEX IF EXISTS IX_Tasks_Created ON app.Tasks;
DROP INDEX IF EXISTS IX_Tasks_Created_TaskId ON app.Tasks;
DROP INDEX IF EXISTS IX_Tasks_Status_Due ON app.Tasks;
```

If you lose track, the shared script is idempotent — re-running `00-create-taskflow-db.sql` rebuilds `TaskFlowDb` from scratch.

## Measuring

```sql
SET STATISTICS IO, TIME ON;   -- logical reads are the number that matters
-- Ctrl+M in SSMS, or "Explain" in Azure Data Studio, for the actual plan
SET STATISTICS IO, TIME OFF;
```

On 35 rows SQL Server will often choose a scan no matter what you write. Read the plans for **shape** (Seek vs Scan vs Key Lookup, Seek Predicate vs residual Predicate), not for cost. Topic 13 revisits all of this at realistic data volumes.
