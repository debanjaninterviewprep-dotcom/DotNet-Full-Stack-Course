# Topic 12: Normalization & Database Design — Interview Questions

---

## Q1. What problem does normalization solve, in one sentence?
**Answer:**
It ensures every fact is stored in exactly one place, so that inserting, updating, or deleting a fact cannot accidentally corrupt or lose an unrelated fact — the insert, update, and delete anomalies that a denormalized "one big table" design suffers from.

---

## Q2. What is a functional dependency, and what does it mean for `A` to be a "determinant" of `B`?
**Answer:**
`A → B` means that for any given value of `A`, there is exactly one corresponding value of `B` — `A` determines `B`. In `app.Users`, `UserId → Email, FirstName, LastName, …` (every column), because a given `UserId` always has exactly one email, one first name, and so on. `Email` is also a determinant of the same columns, independently, which is why it qualifies as a candidate key.

---

## Q3. Explain 1NF, 2NF, and 3NF with a concrete example for each.
**Answer:**

| Form | Rule | Violation example | Fix |
|---|---|---|---|
| 1NF | Every column atomic, no repeating groups | `AssigneeEmails = 'a@x.com,b@x.com'` | One row per assignee — `app.TaskAssignments` |
| 2NF | No non-key column depends on only *part* of a composite key | `TaskLabels(TaskId, LabelId, LabelColor)` — `LabelColor` depends only on `LabelId` | Move `LabelColor` to `app.Labels` |
| 3NF | No non-key column depends transitively on the key through another non-key column | `Tasks(TaskId, ProjectId, ProjectName)` — `ProjectName` depends on `ProjectId`, not `TaskId` directly | Move `ProjectName` to `app.Projects` |

The common mnemonic: "the key, the whole key, and nothing but the key."

---

## Q4. What is the difference between 3NF and BCNF?
**Answer:**
Both forbid transitive dependencies through non-key columns, but BCNF is stricter: it requires that **every** determinant be a candidate key, even for prime (key-part) attributes, which 3NF explicitly exempts. They only differ in practice when a table has **multiple overlapping candidate keys** with a dependency between them — a table can be in 3NF and still violate BCNF, but never the reverse (every BCNF table is automatically in 3NF).

---

## Q5. What does 4NF address, and can you give a TaskFlow-shaped example?
**Answer:**
4NF forbids independent **multi-valued dependencies** from being combined in one table. If a task has multiple assignees and multiple labels, and these two facts are independent of each other, cramming both into one table (`TaskId, UserId, LabelId`) forces every assignee to be paired with every label — a spurious combinatorial explosion (2 assignees × 2 labels = 4 rows for one task, when only 2 + 2 = 4 independent facts actually exist). The fix is two separate junction tables — exactly why TaskFlow has both `app.TaskAssignments` and `app.TaskLabels` rather than one combined table.

---

## Q6. When would you deliberately denormalize a schema, and what must accompany that decision?
**Answer:**
When read performance matters more than write simplicity for a specific workload — dashboards, high-traffic reporting endpoints, expensive rollup aggregates recomputed on every page load. The decision must come with an explicit, documented **mechanism for keeping the redundant copy correct**: a trigger, an indexed view (which the engine maintains automatically), or a scheduled job with a stated staleness window. Denormalizing without naming the maintenance mechanism just recreates the update anomaly normalization was supposed to prevent, except now it's undocumented.

---

## Q7. What is a junction (associative) table, and why is it the only correct way to model a many-to-many relationship in a relational database?
**Answer:**
A junction table holds one row per pairing between two entities, with a composite key (often the two foreign keys together) and, optionally, extra attributes describing the pairing itself.

```sql
CREATE TABLE app.TaskLabels (
    TaskId  INT NOT NULL,
    LabelId INT NOT NULL,
    CONSTRAINT PK_TaskLabels PRIMARY KEY (TaskId, LabelId),
    CONSTRAINT FK_TaskLabels_Task  FOREIGN KEY (TaskId)  REFERENCES app.Tasks (TaskId),
    CONSTRAINT FK_TaskLabels_Label FOREIGN KEY (LabelId) REFERENCES app.Labels (LabelId)
);
```

Relational columns must hold single, atomic values (1NF) — there is no native column type that holds "a set of foreign keys," so a many-to-many relationship can only be represented by introducing a new table whose rows *are* the individual pairings.

---

## Q8. What is a weak entity, and how do you recognize one in a schema?
**Answer:**
A weak entity has no independent identity — it cannot exist without its owning (parent) entity, and its primary key is entirely composed of foreign key(s) to that parent, via an **identifying relationship**. `app.TeamMembers (TeamId, UserId, ...)` is a weak entity: a membership row is meaningless without both a team and a user, and there is no surrogate key of its own. Contrast with `app.Comments`, which has a mandatory foreign key to `app.Tasks` but is a **strong** entity, because it has its own independent `CommentId` — the relationship is mandatory, not identifying.

---

## Q9. Surrogate key or natural key — how do you decide?
**Answer:**
Default to a surrogate key (typically an `IDENTITY` integer) for the primary key, and preserve any genuine natural key as an **alternate key** via a `UNIQUE` constraint. Reasons: natural keys can change (an email, a code), which is dangerous for a primary key referenced by foreign keys everywhere; surrogates are narrow and sequential, which benefits clustering and index performance; and surrogates never leak business meaning into join columns. Exceptions exist — small, genuinely immutable reference lists (`ref.TaskStatuses`) can use a deliberately assigned small natural-ish key instead of an auto-incrementing one, since the values are stable and meaningful for readability in code.

---

## Q10. Why does a random `UNIQUEIDENTIFIER` primary key cause index fragmentation, and how do you mitigate it?
**Answer:**
A clustered index physically orders table rows by the key. `NEWID()` generates GUIDs in random order, so each insert lands in an arbitrary position in the middle of the existing pages rather than at the end — forcing frequent page splits and fragmenting the index over time. `NEWSEQUENTIALID()` generates GUIDs that increase monotonically (within the lifetime of a given machine), restoring the append-at-the-end insertion pattern of a sequential integer `IDENTITY`, while still being globally unique. It comes with its own trade-off: sequential GUIDs are more guessable/predictable, which matters if the GUID is ever exposed externally as a security-relevant identifier.

---

## Q11. Compare adjacency list, path enumeration, nested sets, and closure table for storing a hierarchy.
**Answer:**

| Model | Descendant query | Ancestor query | Moving a subtree | Storage |
|---|---|---|---|---|
| Adjacency list (`ParentId`) | Recursive CTE | Recursive CTE | O(1) | One extra column |
| Path enumeration (`/1/4/17/`) | `LIKE` prefix match | Split the path string | Rewrite every descendant's path | One string column |
| Nested sets (`Lft`/`Rgt`) | One range query | One range query | Expensive renumbering | Two integer columns |
| Closure table | One indexed join | One indexed join | O(subtree size) rows | A whole extra table |

TaskFlow uses adjacency list for both `app.Users.ManagerId` and `app.Tasks.ParentTaskId`, which matches how the business actually edits these hierarchies (reassign one manager, reparent one task) — the recommended default unless deep, read-heavy, rarely-mutated hierarchies prove it insufficient.

---

## Q12. What is a Slowly Changing Dimension (SCD), and what's the difference between Type 1 and Type 2?
**Answer:**
An SCD describes how a dimension's attribute value is handled when it changes over time. **Type 1** overwrites the value in place — history is lost, and any report re-run later sees only the current value (e.g. `app.Users.JobTitle` today). **Type 2** inserts a new row with effective-dating (`EffectiveFrom`/`EffectiveTo`) instead of overwriting, so historical reports remain accurate as of the time they describe — necessary when, for example, a cost report needs each time entry priced at the `HourlyRate` that was actually in effect on the day the work was logged, not today's rate.

---

## Q13. What is the difference between a star schema and a snowflake schema?
**Answer:**
Both organize an OLAP warehouse around a central **fact** table (the measurements, at a defined grain) surrounded by **dimension** tables (the descriptive context). A **star schema** keeps dimensions fully denormalized/flat — e.g. `DimProject` inlines the team's name directly rather than joining out to a separate `DimTeam`. A **snowflake schema** normalizes the dimensions further, so `DimProject` would reference `DimTeam` as its own table. Star schemas trade some redundancy for simpler, faster joins; snowflake schemas trade query simplicity for less duplicated dimension data. TaskFlow's OLTP schema is itself close to a normalized ("snowflaked") shape already — a reporting warehouse built from it would deliberately flatten reference tables into fact-adjacent dimensions for read performance.

---

## Q14. What's the main risk of the "shared schema plus `TenantId` column" multi-tenancy model, and how do you mitigate it?
**Answer:**
Every single query in the codebase must remember to filter on `WHERE TenantId = @Current`. A missing filter in even one query — a new report, a background job, an ad hoc admin script — leaks every tenant's data to whoever runs it, which is a security/data-breach incident, not merely a bug. The standard mitigation is SQL Server row-level security: a security policy backed by a predicate function that the engine applies automatically to every query against the table, so the filter cannot be forgotten even by code that doesn't know tenancy exists.

---

## Q15. What is the EAV (Entity-Attribute-Value) anti-pattern, and when, if ever, is a similar-looking design actually justified?
**Answer:**
EAV models every entity's properties as rows in a generic `(EntityId, AttributeName, AttributeValue)` table instead of real columns. It loses data types (everything is a string), loses constraints (no `CHECK`/`FOREIGN KEY` can target a specific attribute), and turns every simple filter into a self-join per attribute. TaskFlow's `app.Tasks.MetadataJson` column looks superficially similar but is justified: it holds **genuinely dynamic, sparse, rarely-queried** extra data (a JSON blob), while every attribute that is common, typed, and needs to be filtered/indexed/constrained (`StatusId`, `PriorityId`, `EstimatedHours`) is still a real column. The rule of thumb: real columns for anything you will `WHERE`, `JOIN`, `CHECK`, or index on; JSON/EAV-adjacent storage only for the long tail of attributes that genuinely varies per row and is never queried directly.

---

## Q16. Design question: a junior developer proposes storing `Comments(CommentableType, CommentableId, Body)` so comments can attach to either a `Task` or a `Project` via one shared table. What's your concern, and what would you propose instead?
**Answer:**
This is the **polymorphic foreign key** anti-pattern: `CommentableId` is supposed to reference either `app.Tasks.TaskId` or `app.Projects.ProjectId` depending on the string in `CommentableType`, but no single `FOREIGN KEY` constraint can express "references table A or table B depending on a sibling column's value" — the database can never verify the reference is valid, and a typo or a bug can silently create a comment pointing at a row that doesn't exist in either table. Two better options: (1) separate `TaskComments` and `ProjectComments` tables, each with a real, single-target foreign key (more tables, but every reference is verifiably valid); or (2) introduce a shared supertype table (e.g. `app.Commentables(CommentableId PK)`) that both `Tasks` and `Projects` also reference, and point `Comments` at that supertype — more upfront modelling, but restores a single, real, enforceable foreign key.

---

## Q17. How would you approach normalizing an existing, badly-designed production table without downtime?
**Answer:**
1. **Model the target schema first** — identify the anomalies (using the functional-dependency analysis from this topic), design the normalized tables, and get the design reviewed before touching production.
2. **Add the new, normalized tables alongside the old one** — do not drop or rename anything yet.
3. **Backfill** the new tables from the old one with a one-time `INSERT ... SELECT`, validating row counts and spot-checking data at each step.
4. **Dual-write** from the application (or via triggers, as an interim measure) so both the old and new shapes stay in sync while the migration is in flight.
5. **Migrate reads** to the new tables incrementally, feature by feature, verifying each against the old shape before fully cutting over.
6. **Retire the old table** only after every read and write path has moved, typically behind a feature flag with a rollback plan, and after a monitored bake-in period with both shapes still present.

The key interview point: normalization changes are schema changes on a live system, so the migration plan (dual-write, phased cutover, rollback capability) matters as much as the target design itself.
