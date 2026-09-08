# Topic 01 — Practice Solutions

This folder holds the shared Phase 11 sample database plus your answers to the eight exercises in [Practice-Problems.md](../Practice-Problems.md).

## The shared database

`00-create-taskflow-db.sql` is **THE** sample database for every topic in Phase 11 (01 through 22). Run it once. Do not modify it — later topics assume these exact schemas, tables and columns.

```bash
# Local sqlcmd (add -C when the server uses a self-signed dev certificate)
sqlcmd -S localhost -U sa -P "<pwd>" -C -i 00-create-taskflow-db.sql

# Or inside the Docker container
docker cp 00-create-taskflow-db.sql taskflow-sql:/tmp/
docker exec -it taskflow-sql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "<pwd>" -C -i /tmp/00-create-taskflow-db.sql
```

The script is idempotent — it drops and recreates every object, so re-run it any time you need a clean slate.

## Files

| File | Problem | Difficulty |
|---|---|---|
| `00-create-taskflow-db.sql` | Shared sample database (provided) | — |
| `P1-environment-bootstrap.sql` | P1 — Environment Bootstrap & Instance Reconnaissance | Easy |
| `P2-anatomy-of-a-relation.sql` | P2 — Anatomy of a Relation | Easy |
| `P3-key-inventory.sql` | P3 — Key Inventory & Surrogate/Natural Audit | Easy |
| `P4-relational-algebra.sql` | P4 — Relational Algebra to T-SQL | Medium |
| `P5-logical-query-processing.sql` | P5 — Logical Query Processing Detective | Medium |
| `P6-null-and-three-valued-logic.sql` | P6 — Three-Valued Logic Audit | Medium |
| `P7-batches-identifiers-collation.sql` | P7 — Batches, Identifiers, Collation & Case Sensitivity | Hard |
| `P8-workload-fit.sql` | P8 — Workload Fit: OLTP, OLAP & the Storage Decision | Hard |

## The schema you are querying

| Schema | Purpose | Tables |
|---|---|---|
| `app` | Transactional business data | `Users`, `Teams`, `TeamMembers`, `Projects`, `Labels`, `Tasks`, `TaskAssignments`, `TaskLabels`, `Comments`, `TimeEntries` |
| `ref` | Small reference/lookup data | `TaskStatuses`, `Priorities` |
| `audit` | Append-only history | `TaskHistory` |

Seeded row counts: 20 users, 7 teams, 20 team memberships, 8 projects, 8 labels, 35 tasks, 31 assignments, 28 task-labels, 12 comments, 29 time entries, 7 statuses, 5 priorities.

Deliberate teaching traps baked into the data:

- `ref.Priorities.SlaHours` is `NULL` for `NONE` — drives the three-valued-logic exercises.
- `app.Users.ManagerId` is `NULL` for users 1 and 20 — breaks `NOT IN`.
- Tasks 8, 18, 22, 26, 27, 29, 30 and 33 have **no** assignee; users 1, 2, 3, 5, 17 and 18 have **no** assignments — outer joins produce visibly different results.
- Label 7 (`good-first-issue`) is never applied — powers `EXCEPT` / anti-join examples.
- Team 7 (`Design System`) has no lead — nullable foreign key.
- User 7 (Ken Thompson) belongs to two teams — creates row multiplication in joins.
- `audit.TaskHistory` has **no** foreign key — audit rows outlive their tasks.

## Conventions

- Every script starts with `USE TaskFlowDb;` then `GO`.
- Every object reference is **schema-qualified** (`app.Tasks`, never `Tasks`) and every table gets an alias.
- Paste query results as comment blocks beneath each query so the file is reviewable without a live server.
- Passwords are always `<pwd>` placeholders. Never commit a real one.
- Any scratch object you create must be dropped in the same script with `DROP TABLE IF EXISTS`.

## Cleanup

```sql
-- Undo any stray rows the exercises may have left behind.
USE TaskFlowDb;
GO
DELETE FROM audit.TaskHistory WHERE ColumnName IN (N'SmokeTest', N'BatchDemo');
DELETE FROM app.Labels        WHERE LabelName  = N'blocked';
DROP TABLE IF EXISTS app.TaskWatchers;
GO

-- Or start completely fresh.
--   sqlcmd -S localhost -U sa -P "<pwd>" -C -i 00-create-taskflow-db.sql
```

```bash
# Remove the whole environment.
docker rm -f taskflow-sql
docker volume rm taskflow-sqldata
```
