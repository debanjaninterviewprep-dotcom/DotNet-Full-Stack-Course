# Topic 14: Views & Synonyms — Interview Questions

---

## Q1. What is a view, physically? Does querying it copy data?
**Answer:**
A view is a **named, stored `SELECT` statement** — no data is copied or stored (unless it's an indexed view). Querying a view causes the optimizer to expand its definition and fold it into the surrounding query before optimizing, typically producing the same plan as if you had written the underlying join by hand.

---

## Q2. What makes a view updatable, and when does an `UPDATE` against a multi-table view fail?
**Answer:**
A view is updatable when SQL Server can trace the write back to exactly one base table with no ambiguity — no aggregation, `DISTINCT`, `GROUP BY`, or `UNION` in the way. A view joining two tables is still updatable **per statement**, as long as that specific statement's changed columns all belong to one of the underlying tables:

```sql
UPDATE app.vw_TaskWithProject SET Title = N'X' WHERE TaskId = 1;                 -- OK, Tasks only
UPDATE app.vw_TaskWithProject SET Title = N'X', ProjectName = N'Y' WHERE TaskId = 1;
-- Msg 4405: not updatable because the modification affects multiple base tables.
```

---

## Q3. What does `WITH CHECK OPTION` do on an updatable view?
**Answer:**
It rejects an `INSERT`/`UPDATE` through the view that would produce a row the view's own `WHERE` clause wouldn't return if you queried it back. Without it, you can silently write a row "through" a filtered view and then have it vanish from that same view on the next read — `WITH CHECK OPTION` converts that silent surprise into an immediate, explicit error.

---

## Q4. What is an indexed view, and how is it different from an ordinary view?
**Answer:**
An indexed view physically **materialises** its result set by creating a unique clustered index on it — the data is actually stored and kept automatically, transactionally in sync with the base tables on every relevant write. An ordinary view stores nothing; it is re-executed (expanded/inlined) on every reference. Indexed views trade write cost (every base-table write that affects the view must also maintain the materialised result) for read speed (the aggregate/join is pre-computed).

---

## Q5. What are the key restrictions SQL Server enforces on an indexed view?
**Answer:**
- Must be created `WITH SCHEMABINDING`.
- Must use two-part (schema-qualified) table names.
- Must use `COUNT_BIG(*)` rather than `COUNT(*)` if counting.
- Cannot contain `OUTER JOIN`, `UNION`, subqueries, `TOP`, `DISTINCT`, or non-deterministic functions.
- The first index created on it must be a `UNIQUE CLUSTERED` index — that is what actually materialises the data; further nonclustered indexes may follow.

---

## Q6. Why does `WITH SCHEMABINDING` matter for a view, even one without an index?
**Answer:**
It locks the referenced tables' schema so that a column the view depends on cannot be dropped or have its type changed without first dropping (or altering) the view — preventing a silent, unnoticed break of the view's definition. It is mandatory for indexed views (the engine must guarantee the underlying schema won't shift under a materialised structure) and is good practice on any view whose stability matters.

---

## Q7. How does `SELECT *` inside a view definition behave when the base table gains a new column later?
**Answer:**
The view's column list is **fixed at creation time** — `SELECT *` is expanded into the actual column list when the view is created, not re-evaluated on every query. Adding a column to the base table afterward does **not** automatically appear in the view's output until you run `sp_refreshview` (or `DROP`/`CREATE` the view again).

---

## Q8. What is a synonym, and how is it different from a view?
**Answer:**
A synonym is a lightweight alias for exactly one other object (table, view, procedure, function) — potentially in another schema, database, or server. It adds no query logic and cannot restrict columns/rows or join multiple objects; it purely renames/relocates. A view can restrict, reshape, and join, but always refers to the objects named in its own definition — it cannot itself be "redirected" elsewhere without redefining the view.

```sql
CREATE SYNONYM app.CurrentTasks FOR app.Tasks;
SELECT * FROM app.CurrentTasks;  -- identical to querying app.Tasks directly
```

---

## Q9. Describe a real scenario where a synonym enables a zero-downtime cutover.
**Answer:**
Migrating from `app.Tasks` to a redesigned `app.Tasks_v2`: application code is written against `app.CurrentTasks` (a synonym), never against the real table name directly. Once `app.Tasks_v2` is populated and verified, cutover is:

```sql
DROP SYNONYM app.CurrentTasks;
CREATE SYNONYM app.CurrentTasks FOR app.Tasks_v2;
```

Every caller's SQL text is unchanged; the next query they run transparently hits the new table. Note this is two separate DDL statements, not a single atomic rename — a brief window exists where the synonym doesn't resolve, which matters for genuinely zero-downtime requirements.

---

## Q10. Can a synonym point at an object on a different server?
**Answer:**
Yes — a synonym can target a four-part name through a linked server (`CREATE SYNONYM app.AuditLog FOR [AuditServer].[AuditDb].[dbo].[Log];`), hiding that complexity behind a simple two-part local name. Callers write `SELECT * FROM app.AuditLog` without needing to know or repeat the linked-server reference anywhere else in the codebase.

---

## Q11. When would you use a view for security, and what's the limitation of that approach?
**Answer:**
A view can restrict which columns (or, via a `WHERE` clause, which rows) a caller sees — e.g. hiding `HourlyRate` from a general "user directory" view. The limitation: it is only real security if the caller's permissions are granted **on the view, not on the base table**. If the caller also has direct `SELECT` permission on the underlying table, the view provides zero protection, since they can simply query the table directly. For row-level restrictions that must hold even for callers with base-table access, SQL Server's dedicated **Row-Level Security** feature (a security policy with a predicate function) is the correct tool, not a view.

---

## Q12. Why might a deeply nested chain of views (a view referencing a view referencing a view) cause performance problems even though a single view adds no cost?
**Answer:**
A single view is inlined/expanded with no inherent cost. But at sufficient nesting depth, the optimizer's ability to fully simplify the resulting expanded tree of joins/filters degrades — what should compile down to a simple index seek can instead produce an unnecessarily complex plan, because the optimizer has a practical limit on how deeply it re-derives an equivalent, simpler query. The fix is to flatten deeply nested view chains rather than assume "views are always free."

---

## Q13. Design question: your application currently connects to `app.Tasks` directly everywhere, and you need to migrate to a partitioned/re-architected table without a "big bang" cutover or downtime. How would you use the concepts in this topic?
**Answer:**
1. Introduce a synonym layer first, if not already present: `CREATE SYNONYM app.CurrentTasks FOR app.Tasks;`, and migrate application code to query through the synonym (a one-time, low-risk change, since it behaves identically to the real table).
2. Build the new architecture (e.g. `app.Tasks_Partitioned`) alongside the existing table, dual-writing or backfilling as needed, and validate it thoroughly against the old shape.
3. Cut over with `DROP SYNONYM` / `CREATE SYNONYM app.CurrentTasks FOR app.Tasks_Partitioned;` — every caller's SQL is unchanged.
4. If the new table's **shape** also differs (renamed/restructured columns, not just physical layout), add a view between the synonym and the callers so shape changes are absorbed separately from location changes — synonym for "where," view for "what it looks like."
5. Keep the old table available, unreferenced by the synonym, for a bake-in/rollback window before finally dropping it.

The key interview point: synonym and view solve **different** halves of "decouple the application from the physical schema" — location versus shape — and combining them gives independent control over each.
