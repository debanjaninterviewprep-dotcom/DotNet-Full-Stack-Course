# Topic 21: SQL with .NET — Practice Problems

> Seven exercises spanning all three data-access layers. Where a problem's deliverable is C# code, provide a `.cs` snippet demonstrating the pattern (a full runnable console/API project is not required — focus on the data-access code itself, matching the style of Phase 5's EF Core topic). Where a problem is about comparing generated SQL, capture the actual SQL text (via EF Core logging or SQL Server Profiler/Extended Events) as evidence.

**Concept tags:** `ado-net` `sqlparameter` `connection-pooling` `dapper` `ef-core` `linq-translation` `n-plus-one` `asnotracking` `fromsqlinterpolated`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```
```
-- .NET side: reference Microsoft.Data.SqlClient, Dapper, and Microsoft.EntityFrameworkCore.SqlServer
-- from a console project or the Phase 5/6 API project, pointed at the TaskFlowDb connection string.
```

---

## P1 — Raw ADO.NET: Parameters Done Right and Wrong  *(Easy)*

**Tags:** `ado-net` `sqlparameter` `addwithvalue`

### Requirements

1. Write a C# method using `SqlConnection`/`SqlCommand`/`SqlDataReader` that fetches tasks for a given `ProjectId`, using an explicitly-typed `SqlParameter` (`SqlDbType.Int`).
2. Write a second version using `Parameters.AddWithValue` for a `Title` search filter (`NVARCHAR(200)` column), and explain in a comment the specific type-inference risk this introduces.
3. Capture (via SQL Server Profiler, Extended Events, or `SET STATISTICS XML ON` against the equivalent hand-run query) whether the `AddWithValue` version's parameter type matches the column's declared type exactly, and state the consequence if it doesn't.
4. Rewrite the `AddWithValue` version using an explicitly-sized `SqlDbType.NVarChar, 200` parameter instead, and confirm the type now matches.

### Deliverable

`P1-ado-net-parameters.cs` (the C# methods) and a short comment block with your captured evidence.

### Hints

- `SqlDbType.NVarChar` defaults to a very large/unspecified length via `AddWithValue`'s inference — this is the crux of the exercise.

### Look-fors (rubric)

- [ ] Both versions correctly parameterise (no string concatenation of the filter value anywhere).
- [ ] The `AddWithValue` risk is correctly and specifically explained (type/size mismatch, not just "it's less safe").
- [ ] Evidence of the actual parameter type sent is captured, not assumed.
- [ ] The fixed, explicitly-typed version is shown correcting the mismatch.

---

## P2 — Connection Pooling Behavior  *(Easy)*

**Tags:** `connection-pooling` `using-disposal`

### Requirements

1. Write a C# snippet that opens and disposes a `SqlConnection` in a tight loop (e.g. 50 iterations), each iteration doing one simple query, using proper `await using` disposal each time.
2. Write a second, deliberately bad version that opens 50 connections and holds them all open simultaneously without disposing until the very end (simulate/describe this if actually exhausting a pool isn't practical in your environment — reason through the consequence).
3. Explain, in a comment, why the first version is expected to reuse a small number of pooled physical connections while the second risks pool exhaustion.
4. Look up (or reason through) what happens to a request when the pool has no available connection and `Connection Timeout` is exceeded — name the resulting exception type.

### Deliverable

`P2-connection-pooling.cs` plus your written explanation.

### Hints

- `Max Pool Size` in the connection string caps how many physical connections a given connection-string pool will create.

### Look-fors (rubric)

- [ ] The proper-disposal version is correctly structured with `await using` per operation.
- [ ] The pool-exhaustion scenario is correctly reasoned through, even if not literally exhausted in a test run.
- [ ] The resulting exception type (a `SqlException`/timeout-related error) is correctly named.

---

## P3 — Dapper: Query, Multi-Mapping, and Stored Procedure Calls  *(Medium)*

**Tags:** `dapper` `queryasync` `multi-mapping` `stored-procedures`

### Requirements

1. Write a Dapper `QueryAsync<TaskDto>` call fetching open tasks for a project, using an anonymous object for the parameter.
2. Write a Dapper multi-mapping query joining `app.Tasks` to `app.Projects`, populating a `TaskDto.Project` navigation property from one query, with the correct `splitOn` parameter.
3. Call a stored procedure (use `app.usp_CreateTask` from Topic 15 if present, or write a minimal stand-in) via Dapper with an output parameter, using `DynamicParameters`, and retrieve the output value afterward.
4. Explain, in a comment, exactly why Dapper's `new { ProjectId = projectId }` parameter pattern is injection-safe by default, connecting back to Topic 19's parameterisation principle.

### Deliverable

`P3-dapper-patterns.cs`.

### Hints

- `splitOn` tells Dapper which column marks the boundary between the first and second mapped type in the result set's column order.

### Look-fors (rubric)

- [ ] The basic query and multi-mapping query are both correctly structured and would compile against the shape of `TaskDto`/`ProjectDto`.
- [ ] The stored procedure call correctly retrieves the output parameter's value after execution.
- [ ] The injection-safety explanation correctly ties Dapper's default parameter binding back to Topic 19.

---

## P4 — Reproducing and Fixing N+1 in EF Core  *(Medium)*

**Tags:** `ef-core` `n-plus-one` `include` `select-projection`

### Requirements

1. Write an EF Core LINQ snippet that loads all projects, then (inside a loop) accesses each project's `Tasks.Count` via a lazy-loaded navigation property — the N+1 bug.
2. Using EF Core logging (`.LogTo(...)` or equivalent), capture (or carefully reason through, citing the documented behavior) the actual number of SQL statements this generates for an 8-project database.
3. Fix it two ways: first with `.Include(p => p.Tasks)` (eager loading), then with a direct `.Select()` projection computing the count in SQL. Capture the SQL/statement-count for both fixes.
4. Explain, in a comment, which fix is preferable for this specific requirement ("just show me a count") and why.

### Deliverable

`P4-n-plus-one.cs`.

### Hints

- 8 projects → the buggy version should show 1 (projects) + 8 (one per project's lazy-loaded tasks) = 9 statements.

### Look-fors (rubric)

- [ ] The N+1 bug is correctly reproduced/reasoned through with the right statement count (9, not some other number).
- [ ] Both fixes are correctly implemented and shown to reduce the statement count to 1.
- [ ] The "which fix is preferable" reasoning correctly favors the projection for a count-only requirement (no need to materialise full `Task` entities at all).

---

## P5 — `AsNoTracking()` and Its Effect  *(Medium)*

**Tags:** `ef-core` `asnotracking` `change-tracking`

### Requirements

1. Write an EF Core query fetching tasks for a project **without** `AsNoTracking()`, and explain, in a comment, exactly what the change tracker does with each returned entity.
2. Rewrite with `.AsNoTracking()` and explain what's skipped.
3. Describe (in prose — an actual benchmark is a stretch goal) the specific scenario where tracking is genuinely needed (you intend to modify and `SaveChanges()` the same entities) versus where it's pure overhead (a read-only API GET endpoint).
4. Identify, from Topic 5/6 course content if available or from general ASP.NET Core knowledge, one place in a typical TaskFlow API controller where `AsNoTracking()` should almost always be used.

### Deliverable

`P5-asnotracking.cs`.

### Hints

- The distinguishing question is always: "will I call `SaveChanges()` against entities from *this specific* query, in *this specific* `DbContext` instance?"

### Look-fors (rubric)

- [ ] The tracked-vs-untracked behavior is correctly and specifically explained (snapshot comparison for change detection).
- [ ] The "when tracking is needed" vs "when it's overhead" distinction is correctly drawn.
- [ ] A concrete, correct example (e.g. a GET endpoint) is identified for `AsNoTracking()`.

---

## P6 — Safe Raw SQL in EF Core: `FromSqlInterpolated` for a Recursive CTE  *(Hard)*

**Tags:** `fromsqlinterpolated` `raw-sql` `recursive-cte`

### Requirements

1. LINQ cannot express a recursive CTE (Topic 07). Write a C# method using `FromSqlInterpolated` to run the org-chart recursive CTE from Topic 07 against `app.Users`, parameterising a starting `@ManagerId` value safely via string interpolation.
2. Write a **deliberately vulnerable** version using `FromSqlRaw` with manual string concatenation of the same parameter, and explain in a comment exactly how an attacker-controlled `managerId`-equivalent string (if this were, hypothetically, a raw string rather than an `int`) could exploit it.
3. Explain why `FromSqlInterpolated`'s `$"..."` syntax is safe despite looking identical to ordinary (unsafe) C# string interpolation.
4. State one limitation of using `FromSqlInterpolated`/`FromSqlRaw` results — specifically, what you lose compared to a normal LINQ-composed query (e.g. further `.Where()` composability on non-mapped shapes, or requiring the result type to be a mapped entity/keyless entity type).

### Deliverable

`P6-raw-sql-recursive-cte.cs`.

### Hints

- Even though `@ManagerId` here is typed as `int` in practice (limiting real exploitability), reason through the general vulnerability class as if it were a less-constrained type, since the pattern is what matters for the exercise.

### Look-fors (rubric)

- [ ] The `FromSqlInterpolated` version is correctly parameterised and would return the expected org-chart shape.
- [ ] The vulnerable version's risk is correctly and specifically explained.
- [ ] The "why interpolated syntax is actually safe" explanation correctly describes EF Core's interception mechanism.
- [ ] At least one genuine limitation of raw-SQL query results is correctly identified.

---

## P7 — Design and Compare: Same Requirement, Three Layers  *(Hard)*

**Tags:** `end-to-end` `ado-net` `dapper` `ef-core` `design-comparison`

### Requirements

Implement the exact same requirement three times — "given a `ProjectId`, return every open task's `TaskId`, `Title`, `DueDate`, and its primary assignee's `FullName`, ordered by `DueDate` ascending with NULLs last" — once each in raw ADO.NET, Dapper, and EF Core (LINQ, not raw SQL).

1. Implement all three, each correctly parameterised and each producing the same logical result.
2. For the EF Core version, capture the generated SQL (via logging) and compare its shape to what you'd write by hand in Dapper/ADO.NET — note any differences (e.g. how EF Core handles the "NULLs last" ordering, which requires a specific LINQ idiom since C# has no direct equivalent to T-SQL's default NULL-sort behavior discussed in Topic 03).
3. Write a comparison table (lines of code, readability, control over the exact SQL, suitability for a simple CRUD API vs a complex reporting endpoint) and give a recommendation for which layer you'd choose for **this specific requirement**, and a different scenario where you'd choose differently.
4. Ensure all three implementations are免 injection-safe and use async methods throughout.

### Deliverable

`P7-three-layers-comparison.cs` (all three implementations) and `P7-comparison-table.md` (the write-up).

### Hints

- "NULLs last" ascending in LINQ/EF Core typically needs `.OrderBy(t => t.DueDate == null).ThenBy(t => t.DueDate)` or similar, since there's no direct `NULLS LAST` LINQ keyword — compare this against T-SQL's native behavior from Topic 03.

### Look-fors (rubric)

- [ ] All three implementations are correct, parameterised, and async.
- [ ] The EF Core generated SQL is actually captured and compared, not assumed.
- [ ] The NULL-ordering difference between native T-SQL and the LINQ workaround is correctly identified.
- [ ] The comparison table and final recommendations are specific and justified, not generic.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven deliverables exist in `PracticeProblemsSolutions/`.
- [ ] Every SQL-reaching value in every C# snippet is parameterised — no string concatenation of user-supplied or variable data into a SQL string anywhere.
- [ ] Every async data-access method uses the `Async` suffix APIs (`OpenAsync`, `ExecuteReaderAsync`, `QueryAsync`, `ToListAsync`, etc.), not their synchronous counterparts.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Build a small `BenchmarkDotNet` (or simple `Stopwatch`-based) comparison of ADO.NET vs Dapper vs EF Core for the same simple query, and report the overhead each layer adds beyond raw ADO.NET.
- Investigate EF Core's **compiled queries** (`EF.CompileAsyncQuery`) as a further optimization for a hot, frequently-executed LINQ query, and measure the difference.
- Read about EF Core's `IQueryable` deferred execution and write a short example of a subtle bug caused by executing a query outside the `using` scope of its `DbContext` (a `DbContext` disposed before the deferred query actually runs).
