# Topic 18: Advanced T-SQL — JSON, XML & Temporal Tables

> `app.Tasks.MetadataJson` has been sitting in the seeded schema since Topic 01, deliberately unused until now. TaskFlow's real needs — flexible per-task metadata that doesn't warrant a new column for every customer's custom field, an XML export format some legacy integration still requires, and an audit requirement that says "show me this task exactly as it was three months ago" — are exactly the three features this topic covers. Each is a case where the relational model alone isn't the right fit, and SQL Server has a dedicated, mature feature for it.

---

## 1. JSON Functions

SQL Server has no native `JSON` data type — JSON is stored as `NVARCHAR(MAX)` text, and a family of functions parses, queries, and produces it.

```sql
USE TaskFlowDb;
GO

SELECT t.TaskId, t.MetadataJson FROM app.Tasks AS t WHERE t.MetadataJson IS NOT NULL;
-- Task 1: {"epic":"foundation","reviewers":["grace","alan"]}
-- Task 6: {"epic":"performance","detected_by":"apm"}
```

### `ISJSON`, `JSON_VALUE`, `JSON_QUERY`

```sql
-- ISJSON is what CK_Tasks_Json (Topic 11) already enforces on every write.
SELECT t.TaskId, ISJSON(t.MetadataJson) AS IsValidJson FROM app.Tasks AS t;

-- JSON_VALUE: extract a SCALAR (string/number/bool) at a path.
SELECT t.TaskId, JSON_VALUE(t.MetadataJson, '$.epic') AS Epic FROM app.Tasks AS t;
-- Task 1: 'foundation'   Task 6: 'performance'

-- JSON_QUERY: extract an OBJECT or ARRAY (JSON_VALUE returns NULL for these -- different tools).
SELECT t.TaskId, JSON_QUERY(t.MetadataJson, '$.reviewers') AS ReviewersJson FROM app.Tasks AS t;
-- Task 1: '["grace","alan"]' (still JSON text, not shredded into rows)
```

| Function | Returns | Use for |
|---|---|---|
| `ISJSON(expr)` | `1`/`0` | Validating text really is JSON (Topic 02's `CHECK` constraint pattern) |
| `JSON_VALUE(expr, path)` | Scalar (`NVARCHAR`), or `NULL` if the path is an object/array | Pulling out one leaf value |
| `JSON_QUERY(expr, path)` | JSON fragment (object/array as text), or `NULL` if the path is a scalar | Pulling out a nested object/array to pass along or shred separately |
| `JSON_MODIFY(expr, path, newValue)` | The whole JSON string, with one value changed/added/removed | Updating one field without rewriting the entire document client-side |

```sql
-- JSON_MODIFY: add a field to an existing document, non-destructively.
UPDATE app.Tasks
SET MetadataJson = JSON_MODIFY(MetadataJson, '$.risk_reviewed', CAST(1 AS BIT))
WHERE TaskId = 4;
-- {"epic":"identity","risk":"high"} -> {"epic":"identity","risk":"high","risk_reviewed":true}

-- Remove a key by setting it to NULL.
UPDATE app.Tasks SET MetadataJson = JSON_MODIFY(MetadataJson, '$.risk_reviewed', NULL) WHERE TaskId = 4;
```

### `OPENJSON`: Shredding JSON into Rows

The workhorse for turning a JSON array/object into a relational result set.

```sql
-- Default schema: Key, Value, Type columns -- one row per top-level member.
SELECT * FROM OPENJSON('{"epic":"foundation","reviewers":["grace","alan"]}');
-- key            value          type
-- epic           foundation     1 (string)
-- reviewers      ["grace","alan"] 4 (array)

-- WITH clause: project directly into typed columns -- the version you actually use in queries.
SELECT t.TaskId, j.Epic, j.Risk
FROM app.Tasks AS t
CROSS APPLY OPENJSON(t.MetadataJson)
    WITH (Epic NVARCHAR(50) '$.epic', Risk NVARCHAR(20) '$.risk') AS j
WHERE t.MetadataJson IS NOT NULL;

-- Shredding a NESTED ARRAY into one row per element -- reviewers becomes 2 rows for task 1.
SELECT t.TaskId, r.[value] AS Reviewer
FROM app.Tasks AS t
CROSS APPLY OPENJSON(t.MetadataJson, '$.reviewers') AS r
WHERE t.TaskId = 1;
-- TaskId  Reviewer
-- 1       grace
-- 1       alan
```

`CROSS APPLY` (Topic 06) is not a coincidence here — `OPENJSON` is a table-valued function, and shredding one JSON document per outer row is exactly the correlated-table-per-row shape `APPLY` exists for.

### `FOR JSON`: Producing JSON from Relational Rows

```sql
-- FOR JSON AUTO: infers nesting from the query's joins.
SELECT t.TaskId, t.Title, u.FullName AS AssigneeName
FROM app.Tasks AS t
JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId AND ta.IsPrimary = 1
JOIN app.Users AS u ON u.UserId = ta.UserId
WHERE t.TaskId = 4
FOR JSON AUTO;
-- [{"TaskId":4,"Title":"Implement auth endpoints","u":{"FullName":"Ken Thompson"}}]

-- FOR JSON PATH: explicit control over nesting via dotted aliases.
SELECT
    t.TaskId, t.Title,
    u.FullName AS 'Assignee.Name', u.Email AS 'Assignee.Email'
FROM app.Tasks AS t
JOIN app.TaskAssignments AS ta ON ta.TaskId = t.TaskId AND ta.IsPrimary = 1
JOIN app.Users AS u ON u.UserId = ta.UserId
WHERE t.TaskId = 4
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
-- {"TaskId":4,"Title":"Implement auth endpoints","Assignee":{"Name":"Ken Thompson","Email":"ken.thompson@taskflow.io"}}
```

> **Rule of thumb:** `FOR JSON PATH` is almost always the better choice over `AUTO` the moment nesting matters — `AUTO`'s inference rules are convenient for a quick export and unpredictable for anything structurally specific an API contract depends on.

### Indexing JSON: Computed Columns

There is no direct index on a JSON path — the standard workaround is a **persisted computed column** (Topic 02) extracting the value, then an ordinary index on that column.

```sql
ALTER TABLE app.Tasks ADD EpicComputed AS JSON_VALUE(MetadataJson, '$.epic') PERSISTED;
CREATE INDEX IX_Tasks_EpicComputed ON app.Tasks (EpicComputed) WHERE EpicComputed IS NOT NULL;

-- Now seekable, instead of scanning every row's JSON text.
SELECT t.TaskId, t.Title FROM app.Tasks AS t WHERE t.EpicComputed = 'performance';
```

> **Anti-pattern:** Storing genuinely structured, frequently-filtered data as JSON "for flexibility." If you find yourself adding a computed column and an index for a JSON path, seriously reconsider whether that value should have just been a real column from the start (Topic 12 §17's EAV-adjacent warning applies here too).

---

## 2. XML: `FOR XML`, `.query()`, `.value()`, `.nodes()`, `.exist()`

XML predates JSON in SQL Server and has a genuine `xml` data type (unlike JSON's plain-text storage) with schema validation and richer query support via XQuery — still relevant for legacy integrations, SOAP-era systems, and some enterprise/government data exchange formats.

```sql
-- FOR XML AUTO / PATH: same nesting-inference concept as FOR JSON.
SELECT t.TaskId, t.Title, t.StatusId
FROM app.Tasks AS t
WHERE t.ProjectId = 4
FOR XML PATH('Task'), ROOT('Tasks');
-- <Tasks><Task><TaskId>19</TaskId><Title>Threat model the API</Title><StatusId>6</StatusId></Task>...</Tasks>
```

```sql
DECLARE @x XML = N'
<Tasks>
    <Task id="19"><Title>Threat model the API</Title><Priority>Critical</Priority></Task>
    <Task id="20"><Title>Remove dynamic SQL from reports</Title><Priority>Critical</Priority></Task>
</Tasks>';

-- .value(): extract ONE scalar via an XPath expression + explicit SQL type.
SELECT @x.value('(/Tasks/Task[1]/Title)[1]', 'NVARCHAR(200)');   -- 'Threat model the API'

-- .exist(): boolean existence test -- 1 or 0, ideal for a WHERE clause.
SELECT @x.exist('/Tasks/Task[@id="20"]');                         -- 1

-- .nodes(): SHRED xml into a rowset -- the .query()/CROSS APPLY equivalent of OPENJSON.
SELECT
    t.x.value('@id', 'INT')            AS TaskId,
    t.x.value('(Title)[1]', 'NVARCHAR(200)')    AS Title,
    t.x.value('(Priority)[1]', 'NVARCHAR(20)')  AS Priority
FROM @x.nodes('/Tasks/Task') AS t(x);

-- .query(): extract an XML FRAGMENT (like JSON_QUERY, but for XML).
SELECT @x.query('/Tasks/Task[@id="19"]');
```

| Method | Returns | JSON equivalent |
|---|---|---|
| `.value(xpath, sqltype)` | A single scalar | `JSON_VALUE` |
| `.query(xpath)` | An XML fragment | `JSON_QUERY` |
| `.exist(xpath)` | `1`/`0` | Not directly available for JSON — emulate with `JSON_VALUE(...) IS NOT NULL` |
| `.nodes(xpath)` | A rowset (used with `CROSS APPLY`) | `OPENJSON` |
| `.modify('XML DML')` | Mutates the XML in place | `JSON_MODIFY` |

`XML` columns can also be validated against an **XML Schema Collection** (`CREATE XML SCHEMA COLLECTION`) — a stronger guarantee than JSON's `ISJSON`, since it validates structure and types, not just well-formedness. This is one of the few remaining reasons to choose XML over JSON for new work.

> **Rule of thumb:** For new development, JSON is almost always the right default — smaller payloads, native support in virtually every modern client/API stack, and simpler syntax. Reach for XML specifically when you're integrating with a system that already speaks it, or when XML Schema validation's stronger guarantees genuinely matter.

---

## 3. System-Versioned Temporal Tables

Topic 12 §13 introduced the *concept* of Type 2 slowly-changing history (`EffectiveFrom`/`EffectiveTo`, hand-rolled). **Temporal tables** automate that entire pattern.

```sql
-- Retrofit app.Projects with system versioning (illustrative -- would need PERIOD columns added first).
ALTER TABLE app.Projects ADD
    ValidFrom DATETIME2(3) GENERATED ALWAYS AS ROW START NOT NULL DEFAULT SYSUTCDATETIME(),
    ValidTo   DATETIME2(3) GENERATED ALWAYS AS ROW END   NOT NULL DEFAULT '9999-12-31 23:59:59.997',
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

ALTER TABLE app.Projects SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = audit.ProjectsHistory));
```

Once enabled:

- Every `UPDATE`/`DELETE` against `app.Projects` **automatically** copies the pre-change row into `audit.ProjectsHistory` — no trigger to write, no maintenance job to schedule.
- `ValidFrom`/`ValidTo` are maintained entirely by the engine; you cannot write to them directly.
- The history table is a completely ordinary table — indexable, queryable directly if needed — but normally accessed through the temporal query syntax on the main table.

```sql
-- "As of" a point in time -- the single most common temporal query.
SELECT * FROM app.Projects FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' WHERE ProjectId = 6;
-- Shows TF-MOB as it existed on that date, even though it's since been archived/changed.

-- Every version that was EVER active during a range.
SELECT * FROM app.Projects FOR SYSTEM_TIME FROM '2025-01-01' TO '2025-12-31' WHERE ProjectId = 1;

-- The full history of one row, oldest first.
SELECT * FROM app.Projects FOR SYSTEM_TIME ALL WHERE ProjectId = 1 ORDER BY ValidFrom;
```

| Requirement | Hand-rolled SCD (Topic 12) | System-versioned temporal table |
|---|---|---|
| History capture | Application/trigger writes it | **Automatic**, engine-enforced, cannot be bypassed |
| Query "as of" a date | Hand-written `WHERE EffectiveFrom <= @d AND EffectiveTo > @d` | `FOR SYSTEM_TIME AS OF @d` |
| Risk of a missed write path | Real — any write path that forgets the history-insert logic breaks it | **None** — it's not optional, it's a table property |
| Storage | Same table, or a manually-maintained history table | Automatically-maintained separate history table |
| Point-in-time restore-adjacent use cases | Manual | Built-in — genuinely useful for audit/compliance requirements |

> **Rule of thumb:** Any time you catch yourself designing a hand-rolled `EffectiveFrom`/`EffectiveTo` pattern (Topic 12 §13) for a table where SQL Server itself can own the versioning, prefer the built-in feature — it removes an entire category of "someone forgot to update the history" bugs by construction.

---

## 4. Combining the Three: A Realistic TaskFlow Scenario

A single reporting requirement can touch all three features:

```sql
-- "For every task with a 'risk' tag in its metadata, show its status as of the start
--  of this quarter, exported as JSON for the compliance team's legacy XML-based intake
--  system (which itself expects an XML wrapper around the JSON payload -- a real, if
--  awkward, integration shape that does happen)."
DECLARE @QuarterStart DATETIME2(3) = '2025-07-01';

SELECT
    (SELECT t.TaskId, t.Title, t.StatusId, JSON_VALUE(t.MetadataJson, '$.risk') AS RiskLevel
     FROM app.Tasks AS t                                    -- FOR SYSTEM_TIME AS OF @QuarterStart, if versioned
     WHERE JSON_VALUE(t.MetadataJson, '$.risk') IS NOT NULL
     FOR JSON PATH) AS TasksJsonPayload
FOR XML PATH('ComplianceExport'), TYPE;
```

This is a deliberately awkward, uncommon shape — most real systems settle on one interchange format — but it illustrates that these are composable T-SQL features, not mutually exclusive modes.

---

## Mental Model

> JSON and XML both solve the same underlying problem from opposite directions: JSON functions let semi-structured **text** be queried and shredded as if it were relational (`JSON_VALUE`/`JSON_QUERY`/`OPENJSON`), and `FOR JSON`/`FOR XML` let relational rows be exported as structured **text** for an API or an integration partner — neither replaces the relational model, both extend it at the edges where a real column would be premature or where an external format is mandated. Index a JSON path the same way you'd index anything else you actually filter on: not directly, but via a persisted computed column, which is also the tell that maybe this value should have been a real column all along. Temporal tables solve a completely different problem — not "how do I query flexible data" but "how do I guarantee history is captured, with zero risk of a forgotten write path" — by making versioning a property of the table itself rather than a pattern you have to remember to implement correctly every time. All three are the right tool exactly when the relational model's rigidity (JSON/XML) or the risk of a missed trigger/application write (temporal) would otherwise be the actual problem — reach for them for that reason, not because they're available.

Move to [Practice Problems](./Practice-Problems.md).
