# Topic 14: Views & Synonyms

> TaskFlow's API layer should never have to know that "a user's workload" requires joining five tables, or that the production database server is called `sql-prod-01.internal`. Views give a query a stable name and hide the joins behind it; synonyms give an object a stable name and hide *where it actually lives* behind that. This topic covers both — ordinary views, updatable views and their limits, indexed (materialised) views and their strict requirements, security via view-based column/row restriction, and synonyms as the abstraction layer between logical and physical object names.

---

## 1. What a View Actually Is

A view is a **named, stored `SELECT` statement** — not a copy of data. Querying a view re-runs (a version of) its definition every time, folded into the outer query's plan.

```sql
USE TaskFlowDb;
GO

CREATE VIEW app.vw_OpenTasks AS
SELECT t.TaskId, t.Title, t.ProjectId, t.StatusId, t.PriorityId, t.DueDate
FROM app.Tasks AS t
WHERE t.StatusId NOT IN (6, 7);
GO

SELECT v.TaskId, v.Title FROM app.vw_OpenTasks AS v WHERE v.ProjectId = 1;
-- The optimizer expands the view and typically produces the same plan as writing
-- the join/filter by hand -- a view is a name, not a materialisation, unless indexed (§5).
```

| Reason to use a view | What it buys you |
|---|---|
| **Encapsulation** | Callers write `SELECT * FROM app.vw_OpenTasks`, not a five-table join they must get right every time |
| **Security** | Grant access to the view, not the base tables — restrict columns or rows without touching table permissions |
| **Abstraction over change** | Underlying tables can be refactored (Topic 12) while the view's contract stays stable |
| **Simplifying repeated logic** | The `StatusId NOT IN (6, 7)` definition of "open" lives in exactly one place |

> **Anti-pattern:** "View-per-report" sprawl — dozens of near-duplicate views, each with a slightly different `WHERE` clause, that nobody can confidently delete. A view is a stable **contract**; if nothing depends on the contract, it's dead code with a `SELECT` statement's syntax.

---

## 2. `CREATE VIEW` Rules and Options

```sql
CREATE VIEW app.vw_ProjectSummary
WITH SCHEMABINDING          -- see §5; also usable without an index, to lock the schema
AS
SELECT
    p.ProjectId, p.ProjectCode, p.ProjectName,
    COUNT_BIG(*) AS TaskCount
FROM app.Projects AS p
JOIN app.Tasks AS t ON t.ProjectId = p.ProjectId
GROUP BY p.ProjectId, p.ProjectCode, p.ProjectName;
GO
```

Restrictions worth knowing:

| Rule | Detail |
|---|---|
| `ORDER BY` | Not allowed at the top level of a view definition, **unless** paired with `TOP`/`OFFSET-FETCH` — a view has no inherent order (Topic 03) |
| `SELECT *` | Expands to the **column list at creation time**; adding a column to the base table later does **not** appear in the view until you `sp_refreshview` or re-create it |
| Nesting | Views may reference other views; deeply nested view-on-view-on-view chains are hard to tune (the optimizer must unravel every layer) and hard to read |
| `WITH CHECK OPTION` | For an updatable view (§3): rejects an `INSERT`/`UPDATE` that would produce a row the view's own `WHERE` clause wouldn't show |
| `WITH ENCRYPTION` | Obscures the definition in `sys.sql_modules` — not real security (trivially bypassed via a `DAC` connection or by reading the plan), mostly used to discourage casual viewing |

```sql
CREATE VIEW app.vw_HighPriorityOpenTasks
WITH SCHEMABINDING
AS
SELECT t.TaskId, t.Title, t.PriorityId, t.StatusId
FROM app.Tasks AS t
WHERE t.PriorityId IN (1, 2) AND t.StatusId NOT IN (6, 7)
WITH CHECK OPTION;
GO

-- Fails: PriorityId = 4 wouldn't appear if you re-queried the view -- CHECK OPTION blocks it.
UPDATE app.vw_HighPriorityOpenTasks SET PriorityId = 4 WHERE TaskId = 5;
```

---

## 3. Updatable Views and Their Limits

A view over a **single table**, with no aggregation, `DISTINCT`, `GROUP BY`, `UNION`, or computed column in the path of the write, is updatable — SQL Server translates the `INSERT`/`UPDATE`/`DELETE` against the view straight through to the base table.

```sql
CREATE VIEW app.vw_ActiveUsers AS
SELECT u.UserId, u.Email, u.FirstName, u.LastName, u.JobTitle
FROM app.Users AS u
WHERE u.IsActive = 1;
GO

UPDATE app.vw_ActiveUsers SET JobTitle = N'Staff Engineer' WHERE UserId = 7;  -- Works: single table.
```

A view joining two or more tables is updatable **only if the write touches columns from exactly one underlying table per statement** — SQL Server cannot decide which table an ambiguous multi-table write belongs to.

```sql
CREATE VIEW app.vw_TaskWithProject AS
SELECT t.TaskId, t.Title, p.ProjectName
FROM app.Tasks AS t JOIN app.Projects AS p ON p.ProjectId = t.ProjectId;
GO

UPDATE app.vw_TaskWithProject SET Title = N'Renamed' WHERE TaskId = 1;      -- OK: touches Tasks only.
UPDATE app.vw_TaskWithProject SET ProjectName = N'X' WHERE TaskId = 1;     -- OK: touches Projects only.
UPDATE app.vw_TaskWithProject SET Title = N'X', ProjectName = N'Y' WHERE TaskId = 1;
-- Msg 4405: View or function 'app.vw_TaskWithProject' is not updatable because the
-- modification affects multiple base tables.
```

Aggregated, `DISTINCT`, or `UNION`-based views are never updatable — there is no way to map a change in an aggregated result back to a specific source row. `INSTEAD OF` triggers (Topic 16) are the standard escape hatch when a business process genuinely needs to "write through" a complex view.

---

## 4. Views for Security: Column and Row Restriction

```sql
-- Column restriction: hide HourlyRate from anyone without direct table access.
CREATE VIEW app.vw_UserDirectory AS
SELECT u.UserId, u.FullName, u.Email, u.JobTitle, u.CountryCode
FROM app.Users AS u;
GO
-- GRANT SELECT ON app.vw_UserDirectory TO role_directory_reader;
-- (No permission granted on app.Users itself -- HourlyRate is structurally unreachable.)

-- Row restriction: a manager only ever sees their own direct reports through this view.
CREATE VIEW app.vw_MyDirectReports AS
SELECT u.UserId, u.FullName, u.JobTitle
FROM app.Users AS u
WHERE u.ManagerId = CAST(SESSION_CONTEXT(N'CurrentUserId') AS INT);
GO
```

This is genuine security **as long as callers only ever have permission on the view, never on the base table** — a view grants no protection to a caller who also holds direct `SELECT` on `app.Users`. For row-level security that must hold even for users with base-table access, SQL Server's dedicated **Row-Level Security** feature (a security policy backed by a predicate function) is the correct tool, not a view.

---

## 5. Indexed (Materialised) Views

An ordinary view is re-executed on every reference. An **indexed view** creates a unique clustered index on the view's result set, which physically **stores** the data and keeps it automatically, transactionally in sync with the base tables — the closest thing SQL Server has to a materialised view.

```sql
CREATE VIEW app.vw_ProjectTaskCounts
WITH SCHEMABINDING
AS
SELECT
    t.ProjectId,
    COUNT_BIG(*) AS TaskCount,
    SUM(ISNULL(t.EstimatedHours, 0)) AS TotalEstimate
FROM app.Tasks AS t
GROUP BY t.ProjectId;
GO

CREATE UNIQUE CLUSTERED INDEX IX_vw_ProjectTaskCounts
    ON app.vw_ProjectTaskCounts (ProjectId);
GO
```

Strict requirements, all enforced at creation time:

| Requirement | Why |
|---|---|
| `WITH SCHEMABINDING` | Prevents underlying tables/columns from being altered or dropped out from under the materialised structure |
| Two-part table names (`app.Tasks`, not just `Tasks`) | Removes ambiguity about which schema owns the referenced object |
| `COUNT_BIG(*)`, not `COUNT(*)` | The larger integer avoids an overflow the engine cannot rule out at very large row counts |
| No `OUTER JOIN`, `UNION`, subquery, `TOP`, `DISTINCT`, or non-deterministic function | The engine must be able to incrementally and deterministically update the stored result on every base-table write |
| First index must be **`UNIQUE CLUSTERED`** | This is what actually materialises the data — additional nonclustered indexes may follow it |

```sql
INSERT INTO app.Tasks (ProjectId, Title, StatusId, PriorityId, CreatedByUserId)
VALUES (1, N'New task for materialised view test', 1, 3, 4);
-- app.vw_ProjectTaskCounts's stored row for ProjectId = 1 updates AUTOMATICALLY,
-- inside the same transaction, as part of this INSERT's cost -- not on a schedule.
```

### The trade-off

| | Ordinary view | Indexed view |
|---|---|---|
| Storage | None | Physically stored |
| Read cost | Recomputed every reference | Pre-computed — often dramatically faster for aggregates over large tables |
| Write cost | None | **Every** write to a referenced base table also maintains the view's index |
| Restrictions | Almost none | Extensive (above) |
| Enterprise-only automatic use by the optimizer for *unmodified* queries against the base table | n/a | Historically an Enterprise Edition optimizer feature (`NOEXPAND` hint required on Standard Edition to force its use) — check your SQL Server edition/version |

> **Rule of thumb:** Indexed views are the right tool for one specific shape of problem — an aggregate or join computed identically, extremely frequently, over a large and relatively write-light table. They are the wrong tool for a table with heavy write volume, because every one of those writes now also pays to maintain the materialised aggregate.

---

## 6. Synonyms

A synonym is a lightweight alias for another object — table, view, stored procedure, or scalar function — potentially in another schema, database, or even server (via a linked server).

```sql
CREATE SYNONYM app.CurrentTasks FOR app.Tasks;

SELECT s.TaskId FROM app.CurrentTasks AS s WHERE s.ProjectId = 1;  -- identical to querying app.Tasks
```

| Use case | Example |
|---|---|
| **Environment abstraction** | `app.ReportingDb` synonym points at `TaskFlowReportingDev` in dev, `TaskFlowReportingProd` in prod — application code never changes |
| **Blue-green cutover** | Point a synonym at `app.Tasks_v2` once a migration is verified, then drop the old table — callers using the synonym never noticed |
| **Cross-database/server abstraction** | `CREATE SYNONYM app.AuditLog FOR [AuditServer].[AuditDb].[dbo].[Log];` hides a linked-server four-part name behind a simple local name |
| **Legacy rename cushion** | Renaming `app.Users` to `app.Members` — leave a `CREATE SYNONYM app.Users FOR app.Members;` temporarily so old code keeps working during a phased migration |

```sql
-- Cutover example: swap what "the current tasks table" means with one statement.
DROP SYNONYM app.CurrentTasks;
CREATE SYNONYM app.CurrentTasks FOR app.Tasks_v2;
-- Every caller using app.CurrentTasks now transparently hits the new table.
```

### Synonyms vs Views vs Linked Servers

| | Synonym | View | Linked Server |
|---|---|---|---|
| Can rename/relocate a single object | **Yes** — that's its only job | Indirectly, by redefining the view | n/a (connects to a whole remote server) |
| Can restrict columns/rows | No | **Yes** | n/a |
| Can join multiple objects | No — one-to-one alias only | **Yes** | n/a |
| Adds query logic | No | Yes | No |
| Cost | None — pure alias, no plan overhead beyond name resolution | None (folds into the outer query) unless indexed | Network + remote server overhead |
| Points at | Any single object, same or different server | A `SELECT` statement | An entire remote server/instance |

> **Rule of thumb:** Reach for a synonym when you need to **rename or relocate**, and a view when you need to **restrict or reshape**. Confusing the two — building a one-column "view" purely to rename a table — adds needless plan-folding overhead for zero benefit over a synonym.

---

## 7. Views and Synonyms Together

A common production pattern: a stable, security-scoped view sitting on top of a synonym, so the *table's location* and the *table's exposed shape* can each change independently.

```sql
CREATE SYNONYM app.SourceTasks FOR app.Tasks;   -- location abstraction

CREATE VIEW app.vw_TaskBoard AS                 -- shape/security abstraction
SELECT s.TaskId, s.Title, s.StatusId, s.PriorityId, s.DueDate
FROM app.SourceTasks AS s
WHERE s.StatusId NOT IN (7);                    -- hide cancelled tasks from the board
GO
```

If `app.Tasks` is later split, archived, or migrated to a different database, only the synonym's target changes — `app.vw_TaskBoard`'s definition, and every report built on it, is untouched.

---

## 8. Performance Considerations

- **An ordinary view adds no execution cost by itself** — the optimizer expands (inlines) its definition into the surrounding query before optimizing, exactly as if you had written the join yourself. Measured performance differences almost always come from the query *around* the view, not the view.
- **Deeply nested views** (a view referencing a view referencing a view) can defeat this — at some depth, the optimizer's ability to simplify the fully-expanded tree degrades, and what should be a simple seek becomes a needlessly complex plan. Flatten nested views if you find this in a plan.
- **`SELECT *` against a view** inherits every column of the *view's* definition — including ones you don't need — which can silently drag a Key Lookup or a wider sort into an otherwise clean plan. Select only the columns you need, from a view exactly as you would from a table.
- **Indexed views trade read speed for write speed** — measure both sides, not just the report that got faster.

---

## Mental Model

> A view is a name for a query, not a copy of data — it costs nothing extra to read (the optimizer inlines it) and buys you encapsulation, a stable security boundary, and one place to change a shared definition; the moment you need genuine pre-computed storage instead of a name, that's a different, much more restrictive tool (an indexed view), not a stronger view. Updatability follows directly from whether SQL Server can trace a write back to exactly one base table without ambiguity — one table, no aggregation, and it just works; more than that, and you need `INSTEAD OF` triggers or you don't allow writes through it at all. A synonym solves an entirely different problem: it doesn't reshape anything, it just lets you rename or relocate a single object without every caller needing to know — the tool for environment abstraction and zero-downtime cutovers, not for restricting what a caller can see. Reach for a view to control *shape and access*; reach for a synonym to control *location and name*; and reach for both together when a schema needs to keep changing underneath a contract that must not.

Move to [Practice Problems](./Practice-Problems.md).
