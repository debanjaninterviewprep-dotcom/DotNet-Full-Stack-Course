# Topic 12: Normalization & Database Design — Practice Problems

> Seven exercises moving from spotting anomalies in a bad schema through to designing a genuinely new piece of TaskFlow. Several deliverables are markdown/diagrams rather than runnable SQL — mirroring how a real design review works.

**Concept tags:** `normalization` `1nf` `2nf` `3nf` `bcnf` `4nf` `denormalization` `er-modelling` `surrogate-keys` `hierarchies` `scd` `multi-tenancy` `star-schema` `anti-patterns`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Denormalize, Then Renormalize  *(Easy)*

**Tags:** `1nf` `2nf` `3nf` `anomalies`

### Requirements

1. Write a single flat query joining `app.Tasks`, `app.Projects`, `app.TaskAssignments`, `app.Users` and `app.TaskLabels`/`app.Labels` into one denormalized result shaped like the `TaskReport` example in Notes.md §2, materializing it into a `#TaskReportDenormalized` temp table.
2. For task 4 (which has 2 assignees and 2 labels), show how many rows it now occupies in the flat table, and explain why.
3. Identify, in a markdown comment, one concrete insert anomaly, one update anomaly, and one delete anomaly this flat shape would suffer in production — using real TaskFlow values, not generic placeholders.
4. Name which normal form violation each anomaly maps back to (1NF, 2NF, or 3NF) and which real TaskFlow table already fixes it.

### Deliverable

`P1-denormalize-renormalize.sql`.

### Hints

- Task 4 belongs to project 1, has assignees Ken Thompson and Dennis Ritchie, and labels `feature`/`security`.

### Look-fors (rubric)

- [ ] The row-multiplication count for task 4 is correct and explained (2 assignees × 2 labels).
- [ ] All three anomalies use real, specific TaskFlow values (not "some project" — name the project).
- [ ] Each anomaly is correctly mapped to a normal form and the seeded table that already prevents it.

---

## P2 — Functional Dependency Analysis  *(Easy)*

**Tags:** `functional-dependency` `candidate-key` `partial-dependency` `transitive-dependency`

### Requirements

1. For `app.TaskAssignments (TaskId, UserId, AssignedOn, IsPrimary)`, list every functional dependency you can identify and state the candidate key.
2. For the hypothetical flat `TaskReport` table from P1, identify at least one **partial** dependency and at least one **transitive** dependency, writing each as `X → Y`.
3. For `app.Users`, explain why `Email` is a **candidate key** even though `UserId` is the chosen **primary key**, and name the constraint that enforces `Email`'s candidacy.
4. Define, in your own words, "prime attribute" and "non-prime attribute," then classify every column of `app.TeamMembers` as one or the other.

### Deliverable

`P2-functional-dependencies.md`.

### Hints

- `app.Users.Email` is backed by `UQ_Users_Email`.
- `app.TeamMembers`'s primary key is `(TeamId, UserId)`.

### Look-fors (rubric)

- [ ] `app.TaskAssignments`'s dependencies correctly show `(TaskId, UserId) → AssignedOn, IsPrimary` as a full (not partial) dependency.
- [ ] At least one correctly identified partial dependency and one transitive dependency from the flat table.
- [ ] The `Email` candidate-key explanation names `UQ_Users_Email` specifically.
- [ ] `TeamMembers` columns are correctly classified (both key columns are prime; `RoleName`/`JoinedOn` are non-prime).

---

## P3 — 4NF: Splitting an Independent Multi-Valued Table  *(Medium)*

**Tags:** `4nf` `multi-valued-dependency` `junction-table`

### Requirements

1. Build a `#TaskFactsBad (TaskId, UserId, LabelId)` temp table by cross-joining each task's assignees with that task's labels (i.e., the deliberately-wrong combined shape from Notes.md §7). Populate it for task 4 only.
2. Count the rows and confirm it matches assignee-count × label-count for task 4.
3. Explain in a comment why "who's assigned" and "what's labelled" are independent facts, and what a query for "is Ken Thompson assigned to task 4" would have to do differently against `#TaskFactsBad` versus against the real `app.TaskAssignments`.
4. Show the correct 4NF decomposition using the real `app.TaskAssignments` and `app.TaskLabels` tables, and confirm neither suffers the combinatorial row explosion.

### Deliverable

`P3-fourth-normal-form.sql`.

### Hints

- Task 4 has assignees Ken Thompson (7) and Dennis Ritchie (8), and labels `feature`(2)/`security`(4) — so 2×2 = 4 rows in the bad shape.

### Look-fors (rubric)

- [ ] The bad shape's row count is correctly derived and matches the cross-product.
- [ ] The explanation correctly identifies the two facts as independent multi-valued dependencies.
- [ ] The real-table decomposition is shown to have 2 + 2 = 4 rows total (not 4 × 2), correctly demonstrating the fix.

---

## P4 — ER Diagram and Weak Entities  *(Medium)*

**Tags:** `er-modelling` `mermaid` `weak-entity` `identifying-relationship`

### Requirements

1. Reproduce (by hand, not copy-paste) a Mermaid `erDiagram` of the full seeded TaskFlow schema, including every table and every relationship with correct crow's-foot cardinality.
2. Identify every **weak entity** in the schema and, for each, name its identifying relationship(s) and confirm its primary key is fully composed of foreign key(s).
3. Identify every entity that has a *mandatory* relationship to another entity but is **not** weak (i.e., it has its own surrogate key), and explain the distinction using one specific example.
4. Add one new entity, `app.Attachments` (a task can have many file attachments; an attachment belongs to exactly one task), to the diagram with correct cardinality, and decide — with justification — whether it should be a weak or strong entity.

### Deliverable

`P4-er-diagram.md`.

### Hints

- Weak entities in the seeded schema: `app.TeamMembers`, `app.TaskAssignments`, `app.TaskLabels`.
- `app.Comments` is a good example of "mandatory but strong."

### Look-fors (rubric)

- [ ] The diagram includes all 12 tables and every foreign key relationship with correct cardinality notation.
- [ ] All three junction-style weak entities are correctly identified with their identifying relationships named.
- [ ] The strong-but-mandatory distinction is explained with a specific, correct example (not a restatement of the definition).
- [ ] `app.Attachments`'s weak/strong decision is justified, not just asserted.

---

## P5 — Surrogate vs Natural Key Decision Table  *(Medium)*

**Tags:** `surrogate-key` `natural-key` `guid-fragmentation` `alternate-key`

### Requirements

1. For each of `app.Users`, `app.Projects`, and `ref.TaskStatuses`, identify the natural key(s), the chosen surrogate key, and the constraint that preserves the natural key as an alternate key (if any).
2. Explain, referencing index fragmentation, why `app.Tasks.TaskId` being a sequential `IDENTITY` is preferable to a random `UNIQUEIDENTIFIER` as the clustering key, and name the SQL Server feature that mitigates this if a GUID primary key is unavoidable.
3. Design (as DDL, not just prose) a hypothetical `app.ApiKeys` table where a globally-unique, non-sequential identifier is actually the **right** choice, and justify why this case is different from `app.Tasks`.
4. Build a decision table (at least 5 rows) that a new-hire developer could use to decide between `IDENTITY INT`, `IDENTITY BIGINT`, `UNIQUEIDENTIFIER`, and a composite natural key for a new table's primary key.

### Deliverable

`P5-surrogate-vs-natural.sql` (DDL) and `P5-key-decision-table.md` (the decision table and explanations).

### Hints

- `ref.TaskStatuses` and `ref.Priorities` intentionally use a small natural-ish surrogate (`TINYINT`), not `IDENTITY` — notice and explain why.
- The GUID mitigation is `NEWSEQUENTIALID()`.

### Look-fors (rubric)

- [ ] All three tables' natural/surrogate/alternate keys are correctly identified, including `ref.TaskStatuses`'s deliberately-assigned `TINYINT` (not `IDENTITY`).
- [ ] The fragmentation explanation correctly connects random GUID insertion order to page splits, and correctly names `NEWSEQUENTIALID()`.
- [ ] The `ApiKeys` design is genuinely justified by a real requirement (e.g. must be unguessable/non-sequential for security), not just "GUIDs are modern."
- [ ] The decision table covers at least: high-write-volume child table, distributed/merge scenario, small closed reference list, security-sensitive external identifier, and a general OLTP case.

---

## P6 — Design a Hierarchy: Task Dependencies  *(Hard)*

**Tags:** `hierarchy` `adjacency-list` `closure-table` `cycle-prevention`

### Requirements

TaskFlow wants to add **task dependencies** ("Task B cannot start until Task A is done") — a different relationship from the existing `ParentTaskId` sub-task hierarchy, and one where a task can depend on **multiple** other tasks (not a simple tree).

1. Explain why `ParentTaskId` (adjacency list, single parent) cannot represent this new requirement, and design a new junction table `app.TaskDependencies` that can.
2. Write the complete DDL, including a `CHECK` or other mechanism that prevents a task from depending on itself, named per the TaskFlow convention.
3. Explain, in a comment, why a simple `CHECK` constraint **cannot** prevent an indirect cycle (A depends on B, B depends on C, C depends on A), and design (in prose, referencing Topic 07's cycle-detection technique) how you would detect one.
4. Compare an adjacency-list-style dependency table against a closure-table representation for this specific use case, and justify which you would ship, considering that dependency chains in practice are short (rarely more than 3–4 deep).

### Deliverable

`P6-task-dependencies.sql` (DDL) with the design discussion as extended comments.

### Hints

- The self-dependency case (`DependsOnTaskId = TaskId`) **is** a simple row-local `CHECK`; the transitive cycle is not.
- A recursive CTE walking `app.TaskDependencies`, carrying a visited-path, is the right tool for cycle detection at write time (called from application code or a trigger before commit).

### Look-fors (rubric)

- [ ] The explanation of why `ParentTaskId` can't model this is correct (a task needs multiple predecessors; a tree only allows one parent).
- [ ] The DDL includes a working self-dependency `CHECK`, correctly named.
- [ ] The indirect-cycle explanation correctly distinguishes what a `CHECK` can see (one row) from what the rule requires (the whole graph).
- [ ] The adjacency-vs-closure-table comparison reaches a justified conclusion given the stated shallow-depth assumption.

---

## P7 — Full Design Review: Adding "Sprints" to TaskFlow  *(Hard)*

**Tags:** `design-review` `normalization` `star-schema` `multi-tenancy`

### Requirements

Design a `Sprints` feature for TaskFlow from scratch (a lighter-weight version of the same feature explored in Topic 11's P8, focused here on *normalization and modelling* rather than constraint mechanics):

1. Propose a normalized table design (`app.Sprints`, `app.SprintTasks`) and justify, form by form (1NF through 3NF), why your design does not violate any of them. Use real column lists, not just table names.
2. Identify one column you would deliberately **denormalize** for read performance (e.g. a cached "committed points total" on `app.Sprints`), and specify exactly which mechanism (trigger, indexed view, or scheduled job) keeps it correct, per Notes.md §8.
3. Sketch (Mermaid `erDiagram`) how `Sprints` fits into the existing ER diagram from P4.
4. If TaskFlow were sold as a multi-tenant SaaS product tomorrow, describe which multi-tenancy model (§14) you would retrofit onto this new feature and the existing schema, and name the single highest-risk mistake in your chosen model.
5. Describe, in 3–4 sentences, how you would shape a `FactSprintProgress` row (grain, key dimensions) if TaskFlow needed a burndown-chart reporting warehouse built on top of this feature.

### Deliverable

`P7-sprints-design-review.md`.

### Hints

- This is the modelling half of the same feature Topic 11's P8 hardens with constraints — the two make a natural pair if you complete both.

### Look-fors (rubric)

- [ ] The 1NF/2NF/3NF justification references actual proposed columns, not generic statements.
- [ ] The denormalization choice names a specific, correct maintenance mechanism (not "just update it periodically" with no detail).
- [ ] The ER sketch correctly shows `Sprints`'s cardinality to `Teams` and the M:N to `Tasks` via `SprintTasks`.
- [ ] The multi-tenancy answer names a specific highest-risk failure mode for the chosen model (e.g. shared-schema's missing-filter data leak).
- [ ] The fact-table sketch names a specific, sensible grain (e.g. "one row per task per sprint per day") rather than leaving it vague.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven deliverables exist in `PracticeProblemsSolutions/`.
- [ ] Every SQL script that creates scratch objects (`#temp` tables, `#TaskFactsBad`, etc.) is self-contained and re-runnable against a freshly seeded `TaskFlowDb`.
- [ ] Every anomaly, dependency, or design claim references specific TaskFlow tables/columns/values — no generic placeholders.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Take P6's task-dependency design and actually implement the write-time cycle check as a trigger, using the recursive-CTE cycle-detection technique from Topic 07.
- Research PostgreSQL's `EXCLUDE` constraint and rewrite one denormalization safeguard from P7 to use it, contrasting with the SQL Server trigger-based equivalent.
- Read about Data Vault modelling (hubs, links, satellites) as a third alternative to 3NF-OLTP and star-schema-OLAP, and write a paragraph on which TaskFlow tables would become which Data Vault construct.
