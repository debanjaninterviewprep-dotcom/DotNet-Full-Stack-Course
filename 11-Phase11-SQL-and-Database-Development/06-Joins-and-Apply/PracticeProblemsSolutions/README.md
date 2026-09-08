# Topic 06 — Practice Solutions

This folder is your workspace for the eight exercises in [Practice-Problems.md](../Practice-Problems.md). Each `Pn-*.sql` file already contains the problem restated as a comment header and a `-- TODO: your solution here` marker. Fill them in.

| File | Problem | Difficulty | Core skill |
|---|---|---|---|
| `P1-task-roster.sql` | P1 — Task Roster | Easy | `INNER` vs `LEFT`, grain |
| `P2-missing-rows.sql` | P2 — The Missing-Rows Report | Easy | Anti-joins, `NOT IN` NULL trap |
| `P3-on-vs-where.sql` | P3 — `ON` vs `WHERE`, Proven | Medium | Outer-join semantics |
| `P4-org-chart-self-join.sql` | P4 — Org Chart Self-Join | Medium | Self joins on `ManagerId` |
| `P5-many-to-many.sql` | P5 — Many-to-Many and Row Multiplication | Medium | Junction tables, `STRING_AGG` |
| `P6-sla-bands.sql` | P6 — Non-Equi Join: SLA Bands | Medium | Range joins, `CROSS JOIN` grids |
| `P7-apply.sql` | P7 — `CROSS APPLY` and `OUTER APPLY` | Hard | Correlated joins, TVFs, JSON |
| `P8-join-operators.sql` | P8 — Physical Join Operators | Hard | Plan reading, hints |

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
- `JOIN … ON` only. No comma joins, ever.
- `NOT IN` only over `NOT NULL` columns, with a comment justifying each use.
- Predicates on the null-supplying side of an outer join go in `ON`, unless the demotion to inner is deliberate and commented.
- Every `TOP (n)` inside an `APPLY` needs a deterministic `ORDER BY` with a unique tie-breaker.
- No `SELECT *`; no `SELECT DISTINCT` used to suppress join duplicates.
- Anything you create (index, function) is dropped at the end of the same file.

## Reference numbers for self-checking

These come straight from the seed data and are the fastest way to know a join went wrong:

| Join / question | Rows |
|---|---|
| `app.Tasks` / `app.TaskAssignments` / `app.TaskLabels` / `app.TimeEntries` | 35 / 31 / 28 / 29 |
| `app.Users` / `app.Teams` / `app.TeamMembers` / `app.Projects` / `app.Labels` | 20 / 7 / 19 / 8 / 8 |
| `Tasks INNER JOIN TaskAssignments` | 31 |
| `Tasks LEFT JOIN TaskAssignments` | 39 |
| `Users LEFT JOIN TaskAssignments` | 37 |
| `Tasks LEFT JOIN TaskLabels` | 38 |
| `Tasks CROSS JOIN TaskAssignments` | 1085 |
| Unassigned tasks | 8 — ids 8, 18, 22, 26, 27, 29, 30, 33 |
| Users with no assignment | 6 — ids 1, 2, 3, 5, 17, 18 |
| Tasks with no label | 10 |
| Labels never used | 1 — `good-first-issue` |
| Users who manage nobody | 13 |
| Users with no manager | 2 — Ada Lovelace, Guido van Rossum |
| Teams with no members | 1 — `Design System` |
| Users in more than one team | 1 — Ken Thompson (`Platform`, `Security`) |
| Tasks with more than one label | 3 — ids 4, 6, 20 |
| Tasks with a `MetadataJson` `epic` key | 10 |
| Tasks with at least one time entry | 16 |

## Running a file

```bash
sqlcmd -S localhost -U sa -P "<pwd>" -d TaskFlowDb -i P3-on-vs-where.sql
```

Or open it in Azure Data Studio / SSMS and press F5.

## Cleanup

Two files create objects and must remove them:

```sql
-- P7
DROP FUNCTION IF EXISTS app.fn_TaskEffort;

-- P8
DROP INDEX IF EXISTS IX_TaskAssignments_UserId ON app.TaskAssignments;
```

Nothing else in this topic modifies the database. To reset completely, re-run `00-create-taskflow-db.sql`.
