# Topic 22: Phase 11 Revision Test — SQL & Database Development

> Closed-book where you can — the point is retrieval, not lookup speed. Use the seeded `TaskFlowDb` for every hands-on section. **Total 100. Pass 70.**
> Time-box: 4–6 hours across a day or two. Save answers under `PracticeProblemsSolutions/`.

---

## Section A — Quick-fire (15 × 2 = 30 pts)

Answer in **one or two sentences** each.

1. Why does `NOT IN` silently return zero rows when the subquery's column contains a NULL, and why doesn't `NOT EXISTS` have the same problem?
2. What is the default window frame when `ORDER BY` is present but no frame clause is given, and why is that dangerous for a running total?
3. Explain the difference between a `UNIQUE` constraint and a filtered unique index, specifically regarding NULLs.
4. What does "join elimination" require, and why does disabling a foreign key with `NOCHECK` break it?
5. Why is a scalar function that queries a table dangerous for performance, and what's the fix?
6. What three things does 4NF forbid that 3NF allows, using TaskFlow's `TaskAssignments`/`TaskLabels` as the example?
7. What's the difference between `RANK()` and `DENSE_RANK()` on tied values?
8. Why does `SELECT *` inside a view definition not automatically pick up a newly-added base-table column?
9. What is parameter sniffing, and name two ways to mitigate it.
10. Why must every trigger be written "set-based," and what does a broken example look like?
11. What's the difference between `READ COMMITTED` and `READ COMMITTED SNAPSHOT` (RCSI)?
12. Why is `sp_executesql` with bound parameters immune to the injection payload that breaks string concatenation?
13. Name the three things a POC index orders its columns by, in order.
14. What's the key difference between a CTE and a `#temp` table regarding materialisation and repeated reference?
15. Why does `AsNoTracking()` in EF Core matter for a read-only API endpoint?

---

## Section B — Diagrams (2 × 5 = 10 pts)

Provide each as a Mermaid diagram in `B-diagrams.md`.

**B1.** An `erDiagram` of the **full seeded TaskFlowDb schema** (all 12 tables, correct crow's-foot cardinality), with the three weak entities (junction tables) visually distinguishable from the strong entities in your accompanying notes.

**B2.** A flowchart of the **diagnostic methodology** from Topic 20 — from "symptom reported" through wait-stats classification, culprit-query identification, hypothesis, fix, and verification under load — showing the decision points (e.g. "is it CPU/I/O/lock-bound?") as diamonds.

---

## Section C — Bug Hunts (5 × 4 = 20 pts)

For each snippet, identify **what's wrong** and **how to fix it**. 2 pts identification + 2 pts fix.

**C1.**
```sql
SELECT u.UserId, u.FullName
FROM app.Users AS u
WHERE u.UserId NOT IN (SELECT m.ManagerId FROM app.Users AS m);
```

**C2.**
```sql
CREATE VIEW app.vw_TaskCounts WITH SCHEMABINDING AS
SELECT t.ProjectId, COUNT(*) AS TaskCount
FROM app.Tasks AS t
GROUP BY t.ProjectId;
GO
CREATE UNIQUE CLUSTERED INDEX IX_vw_TaskCounts ON app.vw_TaskCounts (ProjectId);
```

**C3.**
```csharp
var projects = await db.Projects.ToListAsync();
foreach (var project in projects)
{
    Console.WriteLine($"{project.ProjectName}: {project.Tasks.Count} tasks");
}
```

**C4.**
```sql
CREATE TRIGGER app.trg_Tasks_Touch ON app.Tasks AFTER UPDATE AS
BEGIN
    DECLARE @TaskId INT;
    SELECT @TaskId = TaskId FROM inserted;
    UPDATE app.Tasks SET ModifiedAtUtc = SYSUTCDATETIME() WHERE TaskId = @TaskId;
END;
```

**C5.**
```sql
DECLARE @sql NVARCHAR(MAX) = N'SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE ''%' + @search + N'%''';
EXEC (@sql);
```

---

## Section D — Hands-On (choose 2 of 3, 12 pts each = 24 pts)

Each is a runnable `.sql` deliverable under `PracticeProblemsSolutions/D-handson/`.

**D1 — Recursive rollup.** Write a single query returning every root task's `TaskId`, `Title`, total node count, and total `EstimatedHours` across itself and all descendants (Topic 07), using `app.Tasks.ParentTaskId`.

**D2 — Windowed leaderboard.** For every user with at least one time entry, compute their total logged hours, their `RANK()` among all users by that total, and their percentage of the grand total — one query, using window functions (Topic 05/09), no `GROUP BY` self-join.

**D3 — Safe upsert.** Write a stored procedure that upserts a row into `app.Labels` by `LabelName` (update `ColorHex` if it differs, insert if missing), race-safe under concurrency, using either a guarded `MERGE` or the two-statement pattern with the correct locking hints (Topic 10/17). Include a comment explaining the specific race it prevents.

### Look-fors (rubric, all three)

- [ ] Correct schema-qualification throughout (`app.`, `ref.`, `audit.`).
- [ ] Deterministic tie-breaking wherever `ORDER BY`/`ROW_NUMBER` is used on a non-unique column.
- [ ] No NULL-trap regressions (`NOT IN` over a nullable column, unguarded `ALL`, etc.).
- [ ] Runs end-to-end against a freshly seeded `TaskFlowDb` with no unhandled errors.

---

## Section E — Design & Trade-offs (2 × 5 = 10 pts)

Answer each in `E-design.md`, 4–8 sentences.

**E1.** TaskFlow wants to add "task dependencies" (a task can depend on several others, not a simple tree). Explain why `ParentTaskId` can't model this, sketch the junction table you'd add, and explain — referencing Topic 07's cycle-detection technique — why a `CHECK` constraint can prevent a *direct* self-dependency but not an *indirect* cycle.

**E2.** A reporting query joins a 200,000-row time-entry table to `Tasks`/`Users`, groups by user and month, and takes 8 seconds. Walk through your diagnostic process in order (Topic 13/20), naming the specific DMVs/tools at each step, before proposing any fix.

---

## Section F — Security & Integrity Audit (6 pts)

You're handed a connection string for a fresh copy of `TaskFlowDb` and told "a junior developer built the app layer; review it." In `F-audit.md`, write the **eight checks** you'd run first, spanning both **T-SQL** (constraint trust state, disabled/untrusted objects, permission grants on base tables vs views) and **application code review** (parameterisation, `AsNoTracking` usage, connection disposal) — and what "good" looks like for each.

---

## Submission Layout

```
PracticeProblemsSolutions/
├── A-quickfire.md
├── B-diagrams.md
├── C-bug-hunts.md
├── D-handson/
│   ├── D1-recursive-rollup.sql       (if chosen)
│   ├── D2-windowed-leaderboard.sql   (if chosen)
│   └── D3-safe-upsert.sql            (if chosen)
├── E-design.md
└── F-audit.md
```

When done, say **"check"** and I'll mark against the rubric in [Practice-Problems.md](./Practice-Problems.md).
