# Topic 05 — Practice Solutions

This folder is your workspace for the eight exercises in [Practice-Problems.md](../Practice-Problems.md). Each `Pn-*.sql` file already contains the problem restated as a comment header and a `-- TODO: your solution here` marker. Fill them in.

| File | Problem | Difficulty | Core skill |
|---|---|---|---|
| `P1-aggregate-vital-signs.sql` | P1 — Aggregate Vital Signs | Easy | `COUNT(*)` vs `COUNT(col)` vs `COUNT(DISTINCT)` |
| `P2-project-scorecard.sql` | P2 — Project Scorecard | Easy | `GROUP BY`, integer-division trap, `ISNULL` |
| `P3-where-vs-having.sql` | P3 — `WHERE` vs `HAVING`, Proven | Medium | Logical processing order |
| `P4-status-pivot.sql` | P4 — Status Pivot Without `PIVOT` | Medium | Conditional aggregation |
| `P5-fan-out-trap.sql` | P5 — The Fan-Out Trap | Medium | Pre-aggregation in derived tables |
| `P6-rollup-cube-grouping-sets.sql` | P6 — Subtotals That Tell the Truth | Hard | `ROLLUP` / `CUBE` / `GROUPING()` |
| `P7-team-utilisation.sql` | P7 — Team Utilisation Report | Hard | Multi-level aggregation, `STRING_AGG` |
| `P8-grouping-performance.sql` | P8 — Grouping Performance Lab | Hard | Stream vs Hash aggregate, indexing |

## Prerequisites

The shared sample database must exist. Run it once:

```bash
sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
```

The script is idempotent — re-run it any time you want a clean slate.

## Conventions

- Every file starts with `USE TaskFlowDb;` and `GO`.
- Schema-qualify everything: `app.Tasks`, `ref.Priorities`, `audit.TaskHistory`.
- Alias every table; qualify every column with its alias.
- No `SELECT *`.
- No `SELECT DISTINCT` used to paper over a join fan-out.
- Cast integer columns to `DECIMAL` before averaging.
- Wrap UI-facing sums in `ISNULL(SUM(x), 0)` unless NULL is genuinely the right answer.
- Put non-aggregate predicates in `WHERE`, aggregate predicates in `HAVING`.
- If a problem asks for an explanation, write it as a `--` or `/* */` comment in the same file.

## Reference numbers for self-checking

These come straight from the seed data and are the fastest way to know your query is wrong:

| Fact | Value |
|---|---|
| `app.Tasks` rows | 35 |
| Tasks with a `DueDate` | 27 |
| Tasks with an `EstimatedHours` | 31 |
| Tasks with `StoryPoints` | 31 (`SUM` = 210) |
| Unassigned tasks | 8 |
| Tasks with no labels | 10 |
| Terminal-status tasks (`Done` + `Cancelled`) | 13 |
| Open (non-terminal) tasks | 22 |
| `app.TimeEntries` total `Hours` | 160.00 |
| Billable hours | 149.00 |
| `app.Projects` `SUM(Budget)` | 660000.00 over 6 of 8 projects |
| Distinct project/status combinations | 25 |
| `app.Users` rows / with `HourlyRate` | 20 / 19 |
| Users with no manager | 2 (Ada Lovelace, Guido van Rossum) |
| Users with no `JobTitle` | 1 (Sophie Wilson) |

## Running a file

```bash
sqlcmd -S localhost -U sa -P "<pwd>" -d TaskFlowDb -i P5-fan-out-trap.sql
```

Or open it in Azure Data Studio / SSMS and press F5.

## Cleanup

Only P8 creates a persistent object. Its final statement must drop it:

```sql
DROP INDEX IF EXISTS IX_Tasks_Project_Status_Incl ON app.Tasks;
```

Nothing else in this topic modifies the database. If you ever want to reset completely, re-run `00-create-taskflow-db.sql`.
