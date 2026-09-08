# Topic 11: Constraints & Data Integrity — Interview Questions

---

## Q1. What are the four types of data integrity, and which mechanism enforces each?
**Answer:**

| Integrity type | Guarantees | Enforced by |
|---|---|---|
| **Entity** | Every row is uniquely identifiable | `PRIMARY KEY`, `UNIQUE`, unique index, `IDENTITY` |
| **Referential** | Every reference points at a row that exists | `FOREIGN KEY` + `ON DELETE`/`ON UPDATE` actions |
| **Domain** | Every value is legal for its column | Data type, `NOT NULL`, `CHECK`, `DEFAULT`, lookup table + FK |
| **User-defined** | Business rules spanning rows, tables or time | Filtered indexes, indexed views, triggers, procedures, application code |

Domain integrity has a design fork worth calling out: an allowed-values list can be a `CHECK (… IN (…))` or a **lookup table plus a foreign key**. TaskFlow uses `ref.TaskStatuses` and `ref.Priorities` because those lists carry attributes of their own (`IsTerminal`, `SortOrder`, `SlaHours`) and need to be joined for display. A `CHECK` is right only for a genuinely closed, attribute-free set.

---

## Q2. What does `PRIMARY KEY` actually give you? Is it the same thing as a clustered index?
**Answer:**
A `PRIMARY KEY` is three guarantees in one declaration: **unique**, **not null**, and *this is the identifying key of the row*. Physically SQL Server implements it as a unique index, and that index is **clustered by default** — but only if the table does not already have one. They are not the same thing: you can declare `PRIMARY KEY NONCLUSTERED` and cluster on something else entirely.

Two consequences people miss:

1. Declaring a column as part of a primary key **silently makes it `NOT NULL`**, and dropping the primary key later does not undo that.
2. Because the primary key is usually the clustered index, its column order and width propagate into every nonclustered index on the table (the clustering key is the row locator). A wide or randomly-ordered primary key is expensive everywhere, not just on that one index.

```sql
SELECT i.name, i.type_desc, i.is_primary_key, i.is_unique_constraint
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'app.Users') AND i.index_id > 0;
-- PK_Users        CLUSTERED     1  0
-- UQ_Users_Email  NONCLUSTERED  0  1
```

---

## Q3. `UNIQUE` constraint or unique index — which do you use?
**Answer:**
They enforce the same rule through the same physical structure. Pick on capability and intent.

| | `UNIQUE` constraint | `CREATE UNIQUE INDEX` |
|---|---|---|
| Can be filtered (`WHERE`) | No | **Yes** |
| Can have `INCLUDE` columns | No | **Yes** |
| Can be a foreign key target | Yes | Yes |
| Appears in `sys.key_constraints` | Yes | No |
| Duplicate-key error | **2627** | **2601** |
| ANSI-portable | Yes | No |

Use a `UNIQUE` **constraint** when you are stating a business rule that happens to need an index. Use a unique **index** when you need the extra capability — which in practice means whenever the rule is "unique among *some* of the rows". The error-number difference is genuinely useful in production: 2627 means somebody hit a declared business rule, 2601 means they hit an index you added.

---

## Q4. How many NULLs does SQL Server allow in a `UNIQUE` column?
**Answer:**
**Exactly one.** SQL Server treats NULLs as equal to each other for uniqueness, which contradicts the ANSI standard. PostgreSQL, MySQL and Oracle all follow the standard and allow unlimited NULLs.

```sql
CREATE TABLE app.ProjectExternalRefs
(
    ProjectId INT         NOT NULL CONSTRAINT PK_ProjectExternalRefs PRIMARY KEY,
    JiraKey   VARCHAR(20) NULL     CONSTRAINT UQ_ProjectExternalRefs_JiraKey UNIQUE
);
INSERT INTO app.ProjectExternalRefs VALUES (1, 'TFC-1');
INSERT INTO app.ProjectExternalRefs VALUES (2, NULL);   -- OK
INSERT INTO app.ProjectExternalRefs VALUES (3, NULL);   -- Msg 2627, duplicate key value is (<NULL>)
```

This bites on the most ordinary column shape there is: **optional but unique**. If more than one row can legitimately have no value, a plain `UNIQUE` constraint is the wrong tool.

It also breaks migrations in both directions. A PostgreSQL table with three NULL rows in a unique column fails to load into SQL Server; a SQL Server design that *relies* on the one-NULL rule silently loses its guarantee when ported to PostgreSQL.

---

## Q5. So how do you enforce "unique among the rows that have a value", or "unique among non-deleted rows"?
**Answer:**
A **filtered unique index**. It applies uniqueness to a subset of rows and solves three common rules that no ANSI constraint can express.

```sql
-- 1. Unique among non-NULLs
CREATE UNIQUE INDEX UX_ProjectExternalRefs_JiraKey
    ON app.ProjectExternalRefs (JiraKey) WHERE JiraKey IS NOT NULL;

-- 2. At most one primary assignee per task.
--    Succeeds on the seeded data: 27 assigned tasks, 27 rows with IsPrimary = 1.
CREATE UNIQUE INDEX UX_TaskAssignments_OnePrimary
    ON app.TaskAssignments (TaskId) WHERE IsPrimary = 1;

-- 3. Soft-delete uniqueness: project codes unique among live projects only
CREATE UNIQUE INDEX UX_Projects_Code_Active
    ON app.Projects (ProjectCode) WHERE IsArchived = 0;
```

Two caveats. Sessions writing to the table need `ANSI_NULLS` and `QUOTED_IDENTIFIER` set `ON` or they fail with error 1934 — modern drivers do, some legacy ODBC paths do not. And query matching is literal: an index filtered `WHERE IsPrimary = 1` will not be used by a query written `WHERE IsPrimary <> 0`.

PostgreSQL has the identical feature. MySQL and Oracle do not, and need a generated-column or function-based-index workaround.

---

## Q6. Surrogate key or natural key?
**Answer:**
**Both.** Surrogate as the primary key, natural as a `UNIQUE` alternate key. That is exactly what TaskFlow does — `ProjectId INT IDENTITY` as `PK_Projects`, `ProjectCode` as `UQ_Projects_Code`; `UserId` as `PK_Users`, `Email` as `UQ_Users_Email`.

| Choice | Pros | Cons |
|---|---|---|
| `INT`/`BIGINT IDENTITY` | 4/8 bytes, sequential, narrow clustering key, no fragmentation | Single-node generation; leaks row counts; needs `SET IDENTITY_INSERT` for seeding |
| `UNIQUEIDENTIFIER` (`NEWID()`) | Client-generatable, merge-safe, opaque | 16 bytes in **every** nonclustered index; random inserts fragment the clustered index badly |
| `NEWSEQUENTIALID()` | Fixes the fragmentation | Still 16 bytes; predictable, so not a security token; server-side only |
| Composite natural key | No extra column; junction tables get uniqueness free | Wide FKs everywhere; changing any component breaks references |

The critical exception is **reference data**: `ref.TaskStatuses.StatusId` is a hand-assigned `TINYINT`, not `IDENTITY`. If dev, test and production seed their lookup tables independently, `IDENTITY` gives them different numbers and every hard-coded `StatusId = 6` becomes environment-specific.

---

## Q7. What referential actions are available and how do you choose?
**Answer:**

| Action | On parent `DELETE` | Requires |
|---|---|---|
| `NO ACTION` (default) | Error 547, statement rolls back | — |
| `CASCADE` | Deletes the child rows | No multiple cascade paths |
| `SET NULL` | Sets the child FK column to NULL | Child column nullable |
| `SET DEFAULT` | Sets it to the column's `DEFAULT` | A `DEFAULT` exists and its value exists in the parent |

Choose by **ownership**. Cascade down a *composition* edge — the child is meaningless without the parent and carries no independent audit value. Use `NO ACTION` for an *association* — the child is an independent record.

TaskFlow's six cascades are all composition: `app.Tasks` → assignments, label links, comments, time entries; `app.Teams` → team members. The 14 `NO ACTION` foreign keys are all associations — deleting a user must not silently destroy their billable time entries.

The hidden cost of `CASCADE`: `@@ROWCOUNT` reports only the rows the statement itself touched. Deleting task 35 reports `(1 row affected)` while silently removing four child rows. That is also why `audit.TaskHistory` deliberately has **no** foreign key — audit rows must outlive the row they describe.

`ON UPDATE CASCADE` is almost always a smell. It exists to propagate a changing key value, and a surrogate key never changes.

---

## Q8. What is error 1785 and how do you fix it?
**Answer:**
SQL Server statically analyses the cascade graph at DDL time and refuses any configuration where a table can be reached by **two cascade paths**, or where a cascade cycle exists. Other engines allow it and resolve at runtime.

```sql
-- Path 1: app.Tasks -> app.TaskAssignments (CASCADE) -> app.TaskReviews (CASCADE)
-- Path 2: app.Tasks -> app.TaskReviews (CASCADE)
CREATE TABLE app.TaskReviews
(
    TaskId INT NOT NULL, ReviewerUserId INT NOT NULL, ReviewedOn DATE NOT NULL,
    CONSTRAINT PK_TaskReviews PRIMARY KEY (TaskId, ReviewerUserId),
    CONSTRAINT FK_TaskReviews_Assignment FOREIGN KEY (TaskId, ReviewerUserId)
        REFERENCES app.TaskAssignments (TaskId, UserId) ON DELETE CASCADE,
    CONSTRAINT FK_TaskReviews_Task FOREIGN KEY (TaskId)
        REFERENCES app.Tasks (TaskId) ON DELETE CASCADE
);
/*
Msg 1785 ... Introducing FOREIGN KEY constraint 'FK_TaskReviews_Task' on table 'TaskReviews'
may cause cycles or multiple cascade paths. Specify ON DELETE NO ACTION or ON UPDATE NO ACTION,
or modify other FOREIGN KEY constraints.
Msg 1750 ... Could not create constraint or index. See previous errors.
*/
```

Resolutions, in the order you should consider them:

1. **Drop the redundant cascade to `NO ACTION`.** Nine times out of ten one path already deletes the row — as here, where the assignment cascade covers it. The redundancy was the bug.
2. **Application-side deletion in a transaction**, when deleting has business meaning (audit, notifications, quota release).
3. **`INSTEAD OF DELETE` trigger** on the parent, deleting children explicitly then the parent.
4. **`AFTER DELETE` trigger** on the intermediate table. Fragile: ordering and the 32-level nesting limit both bite.

Reaching straight for a trigger is the classic mistake — it reintroduces exactly the ordering and recursion problems `CASCADE` existed to remove.

---

## Q9. Why can a self-referencing foreign key never cascade in SQL Server?
**Answer:**
Because the cascade graph would contain a cycle of length one, which the 1785 check rejects unconditionally.

```sql
ALTER TABLE app.Tasks
    ADD CONSTRAINT FK_Tasks_Parent_Cascade FOREIGN KEY (ParentTaskId)
        REFERENCES app.Tasks (TaskId) ON DELETE CASCADE;
-- Msg 1785. Always.
```

That is why `FK_Users_Manager`, `FK_Tasks_Parent` and `FK_Comments_Parent` are all `NO ACTION`. The practical consequence is visible in the seed data: tasks 2 and 3 name task 1 as their parent, so deleting task 1 fails with a distinctively worded 547:

```
The DELETE statement conflicted with the SAME TABLE REFERENCE constraint "FK_Tasks_Parent".
```

To delete a subtree you must either walk it yourself (recursive CTE to collect ids, then delete leaves-first) or use an `INSTEAD OF DELETE` trigger. Note also that a self-referencing FK column **must** be nullable — otherwise no row could ever be inserted first.

---

## Q10. What happens when a `CHECK` constraint expression evaluates against a NULL?
**Answer:**
The row **passes**. A `CHECK` rejects a row only when the expression evaluates to `FALSE`; NULL comparisons produce `UNKNOWN`, and `UNKNOWN` is not `FALSE`.

```sql
-- These two are IDENTICAL in behaviour. Both allow NULL.
CHECK (EstimatedHours > 0)
CHECK (EstimatedHours IS NULL OR EstimatedHours > 0)   -- CK_Tasks_Estimate in TaskFlow

-- This one actually rejects NULL, because NULL IS NOT NULL is FALSE, not UNKNOWN.
CHECK (EstimatedHours IS NOT NULL AND EstimatedHours > 0)
```

TaskFlow writes the second form deliberately: it costs nothing and documents that NULL was *intended*, not forgotten. But the real lesson is that **"required" is always `NOT NULL`, never a `CHECK`**. If someone tells you a `CHECK` is enforcing a mandatory field, they have a bug.

The sibling trap is collation. `CHECK (CountryCode LIKE '[A-Z][A-Z]')` accepts `'gb'` under a case-insensitive collation. The fix is `CHECK (CountryCode COLLATE Latin1_General_BIN2 LIKE '[A-Z][A-Z]')`.

---

## Q11. What can a `CHECK` constraint *not* do, and where do those rules go instead?
**Answer:**
A `CHECK` expression can only see the **row being written**. Subqueries are rejected outright:

```sql
ALTER TABLE app.TaskAssignments ADD CONSTRAINT CK_TaskAssign_OnePrimary
    CHECK ((SELECT COUNT(*) FROM app.TaskAssignments AS x
            WHERE x.TaskId = TaskId AND x.IsPrimary = 1) <= 1);
-- Msg 1046, Level 15: Subqueries are not allowed in this context.
```

The infamous workaround — wrap the subquery in a scalar UDF — compiles and is **wrong** in three separate ways: the constraint is never evaluated for rows a `DELETE` removes, so a delete can break the invariant while the constraint stays happy; under `READ COMMITTED` two concurrent sessions can both pass the check and both commit; and it turns every write into a per-row scalar function call.

| Rule shape | Correct mechanism |
|---|---|
| Uniqueness over a subset of rows | Filtered unique index |
| "At most one child per parent" | Filtered unique index |
| An aggregate over a group must satisfy a predicate | Indexed view, or an `AFTER` trigger |
| Two date ranges in a group must not overlap | Trigger (PostgreSQL: `EXCLUDE USING gist`) |
| Legal status transitions | Trigger (needs `deleted` **and** `inserted`) or a stored procedure |
| A rule involving another table's rows | Trigger, or application logic in a transaction |

---

## Q12. What is an "untrusted" constraint, and why should I care? *(senior)*
**Answer:**
SQL Server records, per constraint, whether it has verified that **all existing rows** satisfy it. That is `is_not_trusted`. An untrusted constraint is still *enforced for new writes* — but the query optimizer **ignores it entirely** when simplifying plans.

| Statement | Enforced for new DML | Trusted |
|---|---|---|
| `ADD CONSTRAINT …` (default `WITH CHECK`) | Yes | **Yes** |
| `WITH NOCHECK ADD CONSTRAINT …` | Yes | **No** |
| `NOCHECK CONSTRAINT …` | **No** | No |
| `CHECK CONSTRAINT …` | Yes | **No** — still untrusted |
| `WITH CHECK CHECK CONSTRAINT …` | Yes | **Yes** |

The doubled `CHECK CHECK` is not a typo: the first is the validation option, the second is the verb.

What you lose is real. **Join elimination**: with a trusted foreign key and a `NOT NULL` child column, this query's plan touches only `app.Tasks`:

```sql
SELECT t.TaskId, t.Title
FROM app.Tasks AS t JOIN app.Projects AS p ON p.ProjectId = t.ProjectId;
```

Run `ALTER TABLE app.Tasks NOCHECK CONSTRAINT FK_Tasks_Project;` and the join comes back — same rows, more work, forever. You also lose constraint-based contradiction detection (a trusted `CHECK (Hours <= 24)` lets `WHERE Hours > 30` compile to a zero-page plan), partition elimination, and indexed-view matching.

Find them, and gate your pipeline on it:

```sql
SELECT 'FK' AS Kind, name, is_disabled, is_not_trusted FROM sys.foreign_keys
WHERE is_not_trusted = 1 OR is_disabled = 1
UNION ALL
SELECT 'CHECK', name, is_disabled, is_not_trusted FROM sys.check_constraints
WHERE is_not_trusted = 1 OR is_disabled = 1;
```

A freshly seeded `TaskFlowDb` returns 0 rows. A database that has survived three years of migrations typically returns dozens, and nobody knows.

---

## Q13. Walk me through disabling constraints for a bulk load and re-enabling them correctly. *(senior)*
**Answer:**

```sql
ALTER TABLE app.TimeEntries NOCHECK CONSTRAINT ALL;   -- 1. disable FK + CHECK
-- 2. load (BULK INSERT / bcp / SqlBulkCopy / INSERT ... SELECT)
ALTER TABLE app.TimeEntries WITH CHECK CHECK CONSTRAINT ALL;   -- 3. re-enable AND revalidate

SELECT fk.name, fk.is_disabled, fk.is_not_trusted           -- 4. prove it
FROM sys.foreign_keys AS fk
WHERE fk.parent_object_id = OBJECT_ID(N'app.TimeEntries');
```

Step 3 is where teams fail. `ALTER TABLE … CHECK CONSTRAINT ALL` re-enables enforcement without validating what you just loaded, leaving `is_not_trusted = 1` permanently. Step 4 is not optional.

If the data is genuinely bad, `WITH CHECK` tells you at once — with wording distinct from the DML forms:

```
Msg 547 ... The ALTER TABLE statement conflicted with the FOREIGN KEY constraint
"FK_TimeEntries_Task". The conflict occurred in database "TaskFlowDb", table "app.Tasks",
column 'TaskId'.
```

Only one constraint's failure is reported per attempt, so a real pipeline validates in staging first — one targeted anti-join per constraint — and quarantines rejects rather than looping fix-and-retry.

Two limits: you **cannot** `NOCHECK` a `PRIMARY KEY` or `UNIQUE` constraint, because uniqueness is a property of the index; the only lever is `ALTER INDEX … DISABLE`, and disabling a *clustered* index makes the whole table inaccessible until it is rebuilt. And `NOCHECK` takes a schema-modification lock, so it is not free on a busy table.

Honestly: on modern hardware the constraint-check cost is usually smaller than the risk. Prefer "validate in staging, insert only clean rows, never disable anything".

---

## Q14. A write fails. What do 515, 547, 2601, 2627 and 1785 tell you?
**Answer:**

| Error | Raised by | Message begins |
|---|---|---|
| **515** | `NOT NULL` | `Cannot insert the value NULL into column …` |
| **2627** | `PRIMARY KEY` or `UNIQUE` **constraint** | `Violation of PRIMARY KEY constraint …` / `Violation of UNIQUE KEY constraint …` |
| **2601** | Unique **index**, including filtered | `Cannot insert duplicate key row in object … with unique index …` |
| **547** | `FOREIGN KEY` **or** `CHECK` | `The <statement> statement conflicted with the …` |
| **1785** | DDL: multiple cascade paths | `Introducing FOREIGN KEY constraint … may cause cycles …` |
| **1046** | DDL: subquery in a `CHECK` | `Subqueries are not allowed in this context.` |

547 is the one that trips people: foreign key and check violations share a number, so you must read the message text. The wording also tells you the direction — `The INSERT statement conflicted with the FOREIGN KEY constraint` (child side) versus `The DELETE statement conflicted with the REFERENCE constraint` (parent side) versus `SAME TABLE REFERENCE constraint` (self-referencing).

Two behaviours to know: **the statement stops at the first violation and rolls back entirely** — a 1000-row `INSERT … SELECT` with one bad row inserts nothing — and **only the first error is reported**, so a row violating three constraints produces one message and three round trips.

---

## Q15. Should validation live in the application or the database? *(architect)*
**Answer:**
Both, doing different jobs. **Validate in the application for the user; validate in the database for the truth.**

The application layer owns user experience: field-level messages, i18n, "email already registered" returned in 20ms without a round trip, and rules that need context the database does not have (authorisation, rate limits, password policy on a value that is never stored in the clear).

The database layer owns the invariant. It is the only layer that is inside the transaction, under the same locks, for every session. `Email` unique is a good example of why the split matters: the application's pre-check is a *race* — two requests can both pass it — and the `UNIQUE` constraint is what makes the claim actually true. The correct pattern is pre-check for the message, catch 2627 for correctness.

Three principles I would defend in a design review:

1. **Every application-only rule is eventually violated** — not by the application, but by the import job, the hotfix script, the reporting ETL, or the second service written eighteen months later by a different team.
2. **A constraint is documentation that cannot go stale.** `CK_Projects_Dates` tells the next developer something no wiki page reliably will.
3. **Constraints are not user-facing copy.** Never surface 2627 to a user; map it.

The counter-arguments are worth engaging with honestly: constraints make zero-downtime schema changes harder, they can block a legitimate data fix at 3am, and multi-tenant or sharded systems eventually hit rules that cannot be expressed within one database. None of those justify removing the constraints you *can* express — they justify knowing which ones you cannot.

---

## Q16. Why does it matter whether constraints are named?
**Answer:**
An unnamed constraint gets a system-generated name with a random hex suffix, `CK__Tasks__Estimated__3E52440B`, and that name is **different in every environment**. Consequences: schema-comparison tools report false differences forever, `DROP CONSTRAINT` cannot be scripted into a migration, idempotent deployment scripts become impossible, and the error message in a support ticket is unreadable.

TaskFlow names everything with a type prefix:

| Prefix | Type | Example |
|---|---|---|
| `PK_` | Primary key | `PK_TaskAssignments` |
| `FK_` | Foreign key, `FK_<child>_<role>` | `FK_Tasks_Parent`, `FK_Comments_Author` |
| `UQ_` | Unique constraint | `UQ_Users_Email` |
| `CK_` | Check | `CK_Projects_Dates` |
| `DF_` | Default | `DF_TimeEntries_Billable` |
| `UX_` / `IX_` | Unique / non-unique index | `UX_TaskAssignments_OnePrimary` |

Note that the foreign key suffix names the **role**, not the column — necessary because `app.Projects` references `app.Users` as owner while `app.Tasks` references it as creator and `app.Comments` as author.

---

## Q17. How do you inventory every constraint in a database?
**Answer:**

```sql
SELECT OBJECT_NAME(kc.parent_object_id) AS TableName, kc.name, kc.type_desc
FROM sys.key_constraints AS kc;                                    -- 13 PK + 6 UQ

SELECT fk.name, fk.delete_referential_action_desc, fk.is_not_trusted
FROM sys.foreign_keys AS fk;                                       -- 20, six CASCADE

SELECT cc.name, cc.definition, cc.is_not_trusted
FROM sys.check_constraints AS cc;                                  -- 6

SELECT dc.name, COL_NAME(dc.parent_object_id, dc.parent_column_id), dc.definition
FROM sys.default_constraints AS dc;                                -- 16

-- Should always be empty:
SELECT s.name + N'.' + t.name
FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE NOT EXISTS (SELECT 1 FROM sys.key_constraints AS kc
                  WHERE kc.parent_object_id = t.object_id AND kc.type = 'PK');
```

`INFORMATION_SCHEMA.TABLE_CONSTRAINTS`, `.REFERENTIAL_CONSTRAINTS` and `.CHECK_CONSTRAINTS` are the ANSI-portable equivalents and are the right choice only when the same script must also run on PostgreSQL or MySQL. They cannot tell you three things that matter: **trust state**, **disabled state**, and **filtered indexes**. Since trust is the thing you most need to audit, use `sys.` for SQL Server work.

---

## Q18. How do constraint semantics differ across SQL Server, PostgreSQL, MySQL and Oracle? *(senior)*
**Answer:**

| Behaviour | SQL Server | PostgreSQL | MySQL (InnoDB) | Oracle |
|---|---|---|---|---|
| NULLs in a single-column `UNIQUE` | **Exactly one** | Unlimited (`NULLS NOT DISTINCT` in 15+) | Unlimited | Unlimited |
| Partial/filtered unique index | Yes | Yes | **No** | **No** |
| PK clustered by default | **Yes** | No | Yes | No |
| `ON DELETE SET DEFAULT` | Yes | Yes | **No** | **No** |
| Deferrable constraints | **No** | Yes | No | Yes |
| Multiple cascade paths | **Rejected (1785)** | Allowed | Allowed | Allowed |
| `CHECK` enforced | Yes | Yes | 8.0.16+ only | Yes |
| Trust metadata | `is_not_trusted` | `pg_constraint.convalidated` | n/a | `VALIDATED` / `RELY` |
| Add without validating | `WITH NOCHECK` | `NOT VALID` + `VALIDATE CONSTRAINT` | `SET FOREIGN_KEY_CHECKS=0` | `ENABLE NOVALIDATE` |
| Range-overlap rule | Trigger | `EXCLUDE USING gist` | Trigger | Trigger |

The two that break real migrations are the first and the fifth. And the MySQL `CHECK` row is a genuine production hazard: before 8.0.16, MySQL **parsed and silently ignored** `CHECK` constraints, so a schema that looks correct enforces nothing.

---

## Q19. "Foreign keys are slow, we removed them for performance." Respond. *(senior)*
**Answer:**
Interrogate the claim before accepting it.

An FK check on `INSERT` is a **single seek** into an index that must already exist — the parent's primary key. That is not where the time goes. What foreign keys actually cost is: a shared lock on the parent row for the duration of the transaction (a real concurrency consideration on a hot parent), and a **scan of the child table on every parent delete or key update if you did not index the child column**. SQL Server indexes the parent side automatically; it creates nothing on the child. That missing index is nearly always the real problem, and it is a one-line fix.

What removing them costs you: **join elimination**, constraint-based plan simplification, correct navigation-property mapping in EF Core, correct schema inference for reporting tools, and — eventually — a data-repair project, because orphan rows accumulate silently and are discovered by a customer.

The legitimate cases are narrow and specific: sharded tables where the parent lives on another node, an append-only audit table that must outlive its subject (`audit.TaskHistory` has no FK for exactly this reason), a staging table that is truncated every night, and cross-database references, which SQL Server cannot express at all. In every one of those, the absence should be a commented decision in the DDL, and the integrity check should move somewhere explicit — a nightly reconciliation job, at minimum.

---

## Q20. Design the integrity strategy for a system where a single database cannot hold all the invariants — microservices, sharding, or eventual consistency. *(architect)*
**Answer:**
The starting position: **enforce every invariant that fits inside one transactional boundary declaratively, and make every invariant that does not fit an explicit, monitored, compensating process.** The failure mode is not "we could not enforce it" — it is "we assumed it was enforced".

Concretely, for TaskFlow split into Identity, Work and Billing services:

1. **Draw the consistency boundary at the aggregate.** Within `Work`, `app.Tasks` → `app.TaskAssignments` → `app.TimeEntries` stay in one database with real foreign keys and real cascades. Nothing about the split justifies weakening those.
2. **Cross-service references become soft references plus a local replica.** `TimeEntries.UserId` cannot have an FK to a `Users` table in another service. Replicate the small, slow-changing subset you need (`UserId`, `DisplayName`, `IsActive`) into the `Work` database via events, and put a real foreign key against the *replica*. You get referential integrity, join elimination, and a bounded staleness window instead of a hope.
3. **Make the staleness window explicit and monitored.** Write a reconciliation job that anti-joins the replica against the source and alerts on drift. This is the compensating control that replaces the constraint; without it you have simply deleted the constraint.
4. **Idempotency and uniqueness at the edge.** Cross-service uniqueness (one email across the estate) needs a single owner. Give it to one service, expose a claim operation, and enforce it there with a `UNIQUE` constraint. Do not attempt distributed uniqueness by convention.
5. **Sharding: put the shard key in every key.** If `TenantId` shards the data, every primary key and every unique index becomes `(TenantId, …)`, and every foreign key is composite. This must be decided on day one; retrofitting it is a rewrite. Combine with row-level security so the tenant predicate is not merely a `WHERE` clause developers must remember.
6. **Prefer append-only for anything that must survive.** `audit.TaskHistory` intentionally has no FK. Extend the pattern: financial and audit records are immutable, carry the denormalised context they need to be interpretable, and never depend on a row in another service.
7. **Design for repair, not just prevention.** Every soft reference needs a documented answer to "what do we do when it dangles" — quarantine, tombstone, or reprocess. Write that down next to the schema.

The trap to name explicitly: teams often relax constraints *inside* a service because the architecture is "eventually consistent". Eventual consistency is a property of the boundary **between** services, not a licence to drop `NOT NULL` inside one.
