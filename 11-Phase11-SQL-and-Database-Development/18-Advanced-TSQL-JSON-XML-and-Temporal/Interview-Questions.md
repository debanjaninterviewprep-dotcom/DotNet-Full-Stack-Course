# Topic 18: Advanced T-SQL — JSON, XML & Temporal Tables — Interview Questions

---

## Q1. Does SQL Server have a native JSON data type?
**Answer:**
No — JSON is stored as ordinary `NVARCHAR(MAX)` text. SQL Server provides a family of functions (`ISJSON`, `JSON_VALUE`, `JSON_QUERY`, `JSON_MODIFY`, `OPENJSON`, `FOR JSON`) to validate, query, modify, and produce JSON text, but there is no dedicated storage type with built-in validation the way `XML` has. This is why a `CHECK (ISJSON(col) = 1)` constraint (Topic 11) is the standard way to enforce that a column actually contains valid JSON.

---

## Q2. What's the difference between `JSON_VALUE` and `JSON_QUERY`?
**Answer:**
`JSON_VALUE` extracts a **scalar** (string, number, boolean) at a given path and returns `NULL` if the path resolves to an object or array. `JSON_QUERY` extracts an **object or array** as a JSON fragment (still text) and returns `NULL` if the path resolves to a scalar. They are complementary, not interchangeable:

```sql
SELECT JSON_VALUE(MetadataJson, '$.epic') FROM app.Tasks;       -- scalar: 'foundation'
SELECT JSON_QUERY(MetadataJson, '$.reviewers') FROM app.Tasks;  -- array as text: '["grace","alan"]'
SELECT JSON_VALUE(MetadataJson, '$.reviewers') FROM app.Tasks;  -- NULL -- wrong function for an array
```

---

## Q3. What does `OPENJSON` do, and why is it typically used with `CROSS APPLY`?
**Answer:**
`OPENJSON` is a table-valued function that shreds a JSON document into a relational rowset — either the default `Key`/`Value`/`Type` schema, or a custom typed projection via a `WITH` clause. It's used with `CROSS APPLY` because shredding one JSON document *per row* of an outer table is exactly the correlated table-valued-function-per-row pattern `APPLY` exists for (Topic 06):

```sql
SELECT t.TaskId, j.Epic
FROM app.Tasks AS t
CROSS APPLY OPENJSON(t.MetadataJson) WITH (Epic NVARCHAR(50) '$.epic') AS j;
```

`OUTER APPLY` instead of `CROSS APPLY` is needed if rows with `NULL`/non-matching JSON should still appear in the result with `NULL`s.

---

## Q4. How do you update one field inside a JSON column without overwriting the whole document from application code?
**Answer:**
`JSON_MODIFY(expr, path, newValue)` — it returns the whole JSON string with just the one path changed, added, or (if `newValue` is `NULL`) removed:

```sql
UPDATE app.Tasks
SET MetadataJson = JSON_MODIFY(MetadataJson, '$.risk_reviewed', CAST(1 AS BIT))
WHERE TaskId = 4;
```

---

## Q5. Can you create an index directly on a JSON path?
**Answer:**
Not directly. The standard workaround is a **persisted computed column** that extracts the value via `JSON_VALUE`, then an ordinary index on that computed column:

```sql
ALTER TABLE app.Tasks ADD EpicComputed AS JSON_VALUE(MetadataJson, '$.epic') PERSISTED;
CREATE INDEX IX_Tasks_EpicComputed ON app.Tasks (EpicComputed);
```

If you find yourself doing this often for a given path, it's also a signal that value might have deserved to be a real column from the start rather than living inside JSON.

---

## Q6. What's the difference between `FOR JSON AUTO` and `FOR JSON PATH`?
**Answer:**
`FOR JSON AUTO` infers the JSON nesting structure automatically from the query's table/join structure — convenient, but its inference rules can produce a shape you didn't intend once joins get more complex. `FOR JSON PATH` gives explicit control over nesting via dotted column aliases (`'Assignee.Name'` becomes `{"Assignee":{"Name":...}}`), which is the safer choice whenever the output shape is a real API contract another system depends on.

---

## Q7. What are the XML equivalents of `JSON_VALUE`, `JSON_QUERY`, and `OPENJSON`?
**Answer:**

| JSON | XML equivalent | Returns |
|---|---|---|
| `JSON_VALUE` | `.value(xpath, sqltype)` | A single scalar |
| `JSON_QUERY` | `.query(xpath)` | An XML fragment |
| `OPENJSON` | `.nodes(xpath)` (used with `CROSS APPLY`) | A rowset |

XML additionally has `.exist(xpath)` (a direct boolean existence test, with no equivalent JSON function — emulated via `JSON_VALUE(...) IS NOT NULL`) and `.modify('XML DML')` (the `JSON_MODIFY` equivalent, using XML DML syntax rather than a simple path/value pair).

---

## Q8. When would you choose XML over JSON for new development?
**Answer:**
Almost never by default — JSON has smaller payloads, simpler syntax, and native support in virtually every modern API/client stack. XML remains the right choice specifically when integrating with a system that already speaks it (legacy SOAP services, some government/enterprise data-exchange formats), or when you need **XML Schema Collection** validation — a genuinely stronger structural guarantee than JSON's `ISJSON`, which only confirms well-formedness, not a specific shape.

---

## Q9. What problem do system-versioned temporal tables solve, and how is it different from a hand-rolled `EffectiveFrom`/`EffectiveTo` pattern?
**Answer:**
Both let you query "what did this data look like at a point in time," but a hand-rolled pattern requires every write path (application code, a trigger, an ETL job) to remember to insert the history row correctly — miss one, and history silently has a gap. A system-versioned temporal table makes versioning a **property of the table itself**: `ALTER TABLE ... SET (SYSTEM_VERSIONING = ON ...)` means the engine automatically copies the pre-change row into a history table on every `UPDATE`/`DELETE`, with no trigger to write and no write path that can bypass it.

---

## Q10. How do you query a temporal table "as of" a specific point in the past?
**Answer:**
```sql
SELECT * FROM app.Projects FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' WHERE ProjectId = 6;
```

This transparently combines the current table and its history table, returning whichever version of each row was actually in effect at that timestamp — no manual `UNION` or `EffectiveFrom`/`EffectiveTo` filtering required.

---

## Q11. Can an application directly write to a temporal table's `ValidFrom`/`ValidTo` (period) columns?
**Answer:**
No — they are `GENERATED ALWAYS AS ROW START/END` columns, exclusively maintained by the engine. Any direct `INSERT`/`UPDATE` attempt targeting them is rejected. This is a deliberate design choice: if applications could set these values, the "guaranteed, un-bypassable history" property that makes temporal tables valuable would be lost.

---

## Q12. Design question: your team is deciding whether a new piece of per-task data belongs in the existing `MetadataJson` column or as a new real column. What factors drive that decision?
**Answer:**
Key factors, drawn from Topic 12's EAV/denormalization framing as well as this topic:
- **Filter/query frequency** — data frequently used in `WHERE`/`JOIN`/`ORDER BY` belongs in a real, indexable column; data that's just displayed belongs in JSON.
- **Selectivity/cardinality** — a small, closed set of possible values that's heavily filtered on (e.g. a compliance flag) benefits from a real column and an index; free-form, per-customer-varying data does not.
- **Prevalence** — data present on nearly every row favors a real column (less wasted JSON parsing overhead per read); data present on a small minority of rows is a reasonable case for JSON, avoiding a mostly-NULL column.
- **Need for constraints** — if the value needs a `CHECK`/`FOREIGN KEY` or must be `NOT NULL`, it must be a real column; JSON content can only be validated at the whole-document level (`ISJSON`), not per-key.
- **Schema volatility** — genuinely dynamic, per-customer/per-integration fields that would require frequent `ALTER TABLE` if modeled as columns are a legitimate case for JSON.

The rule of thumb from Notes.md: if you ever find yourself adding a computed column and an index for a specific JSON path, that's a strong signal the value should have been a real column from the beginning.

---

## Q13. A teammate proposes using a temporal table's automatic history purely as an "audit log" of who changed what and why. Is this a good fit?
**Answer:**
Partially, with an important gap: system-versioned temporal tables automatically capture **what the row looked like before and after** each change and **when** it changed — but they do not capture **who** made the change or **why**, since there's no built-in column for a user identity or change reason. For "audit log" requirements that need those specifics, you'd either add your own `ModifiedByUserId` column to the base table (which then *is* captured by temporal versioning as part of the row) or pair temporal tables with a separate mechanism (a trigger populating a purpose-built audit table with user/reason context, as in Topic 16). Temporal tables solve "guarantee complete point-in-time history with zero maintenance risk" — a related but distinct problem from "who did this and why."
