# Topic 18: Advanced T-SQL — JSON, XML & Temporal Tables — Practice Problems

> Six exercises spanning JSON shredding/production, XML basics, and system-versioned temporal tables. All against the seeded `TaskFlowDb` — the JSON problems use the existing `app.Tasks.MetadataJson` column directly.

**Concept tags:** `json` `openjson` `for-json` `json-modify` `xml` `for-xml` `xquery` `temporal-tables` `system-versioning`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Reading and Modifying JSON with `JSON_VALUE`/`JSON_QUERY`/`JSON_MODIFY`  *(Easy)*

**Tags:** `json-value` `json-query` `json-modify`

### Requirements

1. List every task with a non-NULL `MetadataJson`, along with `JSON_VALUE(..., '$.epic')` where present.
2. For task 1 specifically, extract the `reviewers` array using `JSON_QUERY` and show that `JSON_VALUE` on the same path returns `NULL` — explain why.
3. Use `JSON_MODIFY` to add a new key `"risk_reviewed": true` to task 4's `MetadataJson` without destroying its existing keys, then verify.
4. Use `JSON_MODIFY` again to remove that key (set to `NULL`) and confirm the document is back to its original shape.
5. Roll back the data change.

### Deliverable

`P1-json-value-query-modify.sql`. Wrap the data change in a transaction you roll back.

### Hints

- `ISJSON` on every row should already be `1` — it's enforced by `CK_Tasks_Json`.

### Look-fors (rubric)

- [ ] The epic extraction correctly handles tasks with and without the key.
- [ ] The `JSON_QUERY` vs `JSON_VALUE` distinction on an array path is correctly demonstrated and explained.
- [ ] `JSON_MODIFY` add/remove round-trip correctly restores the original document.
- [ ] Data rolled back.

---

## P2 — Shredding JSON with `OPENJSON`  *(Medium)*

**Tags:** `openjson` `cross-apply` `nested-array`

### Requirements

1. Using `OPENJSON ... WITH`, project every task's `epic` and `risk` fields (where present) into typed columns in one query across all of `app.Tasks`.
2. Using `OPENJSON(..., '$.reviewers')` with `CROSS APPLY`, shred task 1's `reviewers` array into one row per reviewer name.
3. Extend the query to shred **every** task's `reviewers` array (most have none — use `OUTER APPLY` so tasks without reviewers still appear with a NULL).
4. Explain, in a comment, why `CROSS APPLY` was the correct join type for step 2 but `OUTER APPLY` is required for step 3.

### Deliverable

`P2-openjson-shredding.sql`.

### Hints

- Only task 1 has a `reviewers` array in the seeded data.

### Look-fors (rubric)

- [ ] The typed `WITH` projection correctly returns NULL (not an error) for tasks missing a given key.
- [ ] Task 1's reviewers correctly shred into exactly 2 rows (`grace`, `alan`).
- [ ] The full-table `OUTER APPLY` version correctly includes tasks with no reviewers, with NULL in the reviewer column.
- [ ] The `CROSS APPLY` vs `OUTER APPLY` reasoning is correct.

---

## P3 — Producing JSON with `FOR JSON`  *(Medium)*

**Tags:** `for-json` `path-vs-auto` `without-array-wrapper`

### Requirements

1. Write a query returning a project and its tasks (joined) using `FOR JSON AUTO`, and observe the nesting structure it infers.
2. Rewrite the identical requirement using `FOR JSON PATH` with dotted aliases, producing a deliberately **different**, more API-appropriate nesting shape (e.g. tasks nested as an array under the project, not the other way `AUTO` might infer it).
3. Produce a single-object (not array-wrapped) JSON payload for exactly one task, using `WITHOUT_ARRAY_WRAPPER`, including its primary assignee's name and email nested under an `Assignee` key.
4. Explain, in a comment, one concrete scenario where `AUTO`'s inferred nesting would silently produce the wrong shape for an API contract, motivating the switch to `PATH`.

### Deliverable

`P3-for-json-production.sql`.

### Hints

- `'Assignee.Name'`/`'Assignee.Email'` as column aliases is the `FOR JSON PATH` nesting syntax.

### Look-fors (rubric)

- [ ] Both `AUTO` and `PATH` versions run and their nesting structures are correctly described.
- [ ] The single-task payload correctly nests assignee info under `Assignee` with no array wrapper.
- [ ] The `AUTO`-goes-wrong scenario is concrete and plausible, not hand-wavy.

---

## P4 — XML Basics: `.value()`, `.exist()`, `.nodes()`  *(Medium)*

**Tags:** `xml` `xquery` `nodes` `value` `exist`

### Requirements

1. Build an `XML` variable containing at least 3 `<Task>` elements (mirroring the shape in Notes.md §2), each with an `id` attribute and `Title`/`Priority` child elements.
2. Use `.value()` to extract the `Title` of the second task by position.
3. Use `.exist()` to check whether a task with a specific `id` is present, for both a present and an absent id.
4. Use `.nodes()` with `CROSS APPLY` to shred the whole XML variable into a rowset with `TaskId`, `Title`, `Priority` typed columns.
5. Use `.modify()` to change one task's `Priority` value in place, and verify with a follow-up `.value()` call.

### Deliverable

`P4-xml-basics.sql`.

### Hints

- `.modify()` uses XML DML syntax: `replace value of (...)`.

### Look-fors (rubric)

- [ ] `.value()` correctly extracts the second task's title by position.
- [ ] `.exist()` correctly returns 1 for a present id and 0 for an absent one.
- [ ] `.nodes()` shredding correctly produces one row per task with all three columns populated.
- [ ] `.modify()` is shown actually changing the value, verified afterward.

---

## P5 — Retrofit a Table with System-Versioned Temporal History  *(Hard)*

**Tags:** `temporal-tables` `system-versioning` `for-system-time`

### Requirements

1. Create a **scratch** table `app.ProjectsTemporal` (a structural copy of `app.Projects`, not the real table) with `PERIOD FOR SYSTEM_TIME` columns, and enable `SYSTEM_VERSIONING` with a named history table.
2. Insert a handful of rows, then perform two rounds of `UPDATE`s on the same row(s) with a deliberate pause (or manually adjust — document how you simulated time passing, since a real test would need actual elapsed time) between rounds.
3. Query `FOR SYSTEM_TIME ALL` and confirm the history table captured the prior versions automatically — with no trigger or manual insert on your part.
4. Query `FOR SYSTEM_TIME AS OF` a timestamp between your two update rounds and confirm it shows the mid-history state.
5. Attempt to directly `UPDATE` the system-maintained `ValidFrom`/`ValidTo` columns and capture the error confirming the engine owns them exclusively.
6. Disable system versioning and drop both the main and history tables.

### Deliverable

`P5-temporal-tables.sql`.

### Hints

- `SYSTEM_VERSIONING` must be turned `OFF` before you can drop either the main or history table.
- Real wall-clock time must actually pass between your update rounds for `FOR SYSTEM_TIME AS OF` between them to be meaningful — a few seconds of other work between statements is enough; note the actual timestamps you observe rather than assuming exact values.

### Look-fors (rubric)

- [ ] System versioning is correctly enabled with a named history table.
- [ ] `FOR SYSTEM_TIME ALL` correctly shows multiple versions per updated row with no manual history-writing code anywhere in the script.
- [ ] `FOR SYSTEM_TIME AS OF` correctly returns the mid-history state for a timestamp between the two update rounds.
- [ ] The direct write to `ValidFrom`/`ValidTo` is correctly rejected with the engine's error.
- [ ] Both tables are cleanly dropped at the end (versioning disabled first).

---

## P6 — Design Decision: JSON Column vs Real Columns vs Temporal History  *(Hard)*

**Tags:** `design-judgment` `eav-warning` `denormalization`

### Requirements

TaskFlow's product team proposes storing three new pieces of information. For each, decide whether it belongs in `MetadataJson` (as-is), as a new real column, or requires temporal/history tracking — and justify using concepts from this topic and Topic 12:

1. A per-task `"customer_escalation_ticket_id"` that only ~2% of tasks will ever have, varies in format by customer, and is never filtered or joined on — just displayed.
2. A per-task `"story_points"` value that **is** already a real column (`StoryPoints`) — but the product team wants to also track **every value it was ever changed to**, for velocity-estimation accuracy audits.
3. A per-task `"compliance_flags"` array that is small, closed-vocabulary (at most 5 possible flag values, ever), and is filtered on in almost every compliance dashboard query.

For each, write your recommendation and a two-to-three-sentence justification, including — for #2 — which specific mechanism (trigger-based audit, `OUTPUT`-based audit, or temporal table) you'd choose and why, referencing the trade-offs from Topic 16 §8 as well as this topic.

### Deliverable

`P6-json-vs-columns-vs-temporal.md`.

### Hints

- #1 is a textbook case for staying in JSON.
- #3's "small, closed vocabulary, frequently filtered" profile is the opposite of #1's — say why that flips the recommendation.
- #2 is genuinely a temporal-table candidate, since it's asking for automatic, complete history of a specific column, not just point-in-time snapshots of a whole row — note that temporal tables version the *whole row*, so consider whether that's actually the most efficient fit versus a narrower trigger-based history table for just that one column.

### Look-fors (rubric)

- [ ] #1 correctly recommends staying in JSON, citing low query/filter frequency and format variability.
- [ ] #2 correctly identifies this as a history/audit requirement and reasons explicitly about whole-row temporal versioning versus a column-specific audit trigger.
- [ ] #3 correctly recommends a real column (with an index), citing selectivity and filter frequency, explicitly contrasting with #1.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All six deliverables exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every scratch table (temporal or otherwise) is dropped at the end of its own file, with system versioning disabled first where applicable.
- [ ] Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Add a persisted computed column extracting `$.epic` from `app.Tasks.MetadataJson` and an index on it (Notes.md §1), then compare a plan filtering on the computed column against one using `JSON_VALUE` directly in the `WHERE` clause.
- Investigate `OPENJSON`'s default (no `WITH` clause) output shape more deeply, including its handling of deeply nested objects, and write a query that recursively flattens an arbitrarily-nested JSON document using a recursive CTE (Topic 07) over the default `OPENJSON` rowset.
- Research `CREATE XML SCHEMA COLLECTION` and sketch (not necessarily run) the DDL you'd use to enforce that any XML stored in a hypothetical `app.LegacyExports` table conforms to a specific element structure.
