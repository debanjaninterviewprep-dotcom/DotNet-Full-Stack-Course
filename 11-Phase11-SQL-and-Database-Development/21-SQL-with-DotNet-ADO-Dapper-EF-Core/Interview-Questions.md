# Topic 21: SQL with .NET — Interview Questions

---

## Q1. What are the three main ways .NET code talks to SQL Server, and how do they relate to each other?
**Answer:**
**ADO.NET** (`Microsoft.Data.SqlClient`) is the low-level API — `SqlConnection`, `SqlCommand`, `SqlDataReader` — giving maximum control at the cost of boilerplate. **Dapper** is a thin "micro-ORM" layered directly over ADO.NET via extension methods on `IDbConnection`: you still write the SQL, but result mapping to objects is automatic. **EF Core** is a full ORM that translates LINQ into SQL and adds change tracking and migrations. All three ultimately execute through the same underlying ADO.NET connection/command machinery — Dapper and EF Core are both, at their core, sophisticated ADO.NET consumers.

---

## Q2. Why is `SqlParameter.Value` assignment always required, never string concatenation, regardless of which of the three layers you use?
**Answer:**
This is the same SQL injection principle from Topic 19 applied at the application layer — a parameter is bound as data, never interpreted as part of the SQL text, regardless of its contents. ADO.NET's `SqlParameter`, Dapper's anonymous-object binding, and EF Core's LINQ translation (and its `FromSqlInterpolated` escape hatch) all achieve this the same way, just with different syntax. Any code path that instead builds a SQL string by concatenating a variable's value is vulnerable, no matter which of the three libraries surrounds it.

---

## Q3. What's the risk with `SqlParameter.AddWithValue`, specifically?
**Answer:**
`AddWithValue` infers the parameter's SQL type from the CLR value's runtime type rather than the actual target column's declared type/size. A C# `string` always infers a generic `NVARCHAR`-shaped parameter regardless of whether the target column is `NVARCHAR(50)` or `NVARCHAR(200)` — if the inferred type doesn't precisely match the column, SQL Server may need an implicit conversion to compare them, which can prevent an index seek on that column (the same SARGability problem from Topics 02/03/13), now introduced silently from application code with no visible change to the T-SQL itself.

---

## Q4. What is connection pooling, and what's the correct usage pattern?
**Answer:**
ADO.NET maintains a pool of physical connections per unique connection string; calling `Open()`/`OpenAsync()` typically borrows a connection from that pool rather than opening a new physical connection each time, and `Dispose()` returns it to the pool rather than truly closing the socket. The correct pattern is `using`/`await using` scoped to **one operation** (or a few closely related ones) — never a single static connection held for the application's entire lifetime (which defeats the pool and has no automatic recovery from a dropped connection), and never opening/disposing per individual row in a loop (which causes unnecessary pool churn under load).

---

## Q5. What happens if application code requests a connection from an already-exhausted pool?
**Answer:**
The request waits up to the connection string's `Connection Timeout` setting for a connection to become available (e.g. another operation finishing and returning its connection to the pool). If no connection becomes available within that time, a timeout exception is thrown. This is a strong argument for always disposing connections promptly (via `using`/`await using`) rather than holding them open longer than a single operation requires.

---

## Q6. How does Dapper protect against SQL injection by default?
**Answer:**
Dapper's `Query<T>`/`Execute` methods take an anonymous object (or `DynamicParameters`) whose properties become bound SQL parameters automatically — `new { ProjectId = projectId }` becomes a properly parameterised `@ProjectId`, never concatenated text. The injection risk with Dapper appears only if a developer manually builds the SQL string via string interpolation/concatenation before passing it to Dapper — the library's standard parameter-binding pattern is safe by construction.

---

## Q7. What is the N+1 query problem, and how does it typically arise in EF Core?
**Answer:**
It's a pattern where one query fetches a set of parent rows, and then a **separate query fires for each parent row** to fetch related data — turning what should be 1 (or 2) database round trips into N+1. In EF Core, it typically arises from **lazy loading**: accessing a navigation property (like `project.Tasks`) inside a loop triggers a new query per iteration, because the related data wasn't loaded upfront.

```csharp
var projects = await db.Projects.ToListAsync();               // 1 query
foreach (var p in projects) { var n = p.Tasks.Count; }         // N additional queries (lazy-loaded)
```

---

## Q8. What are the two main fixes for N+1 in EF Core, and when would you choose each?
**Answer:**
**Eager loading** via `.Include()` loads the related entities up front in the same (or a second, batched) query — appropriate when you actually need the full related entities themselves. **Projection** via `.Select()` computes exactly what's needed (e.g. a count) directly in the generated SQL, without materialising full related entities at all — usually preferable when you only need a derived value, since it avoids loading and tracking data you don't actually need:

```csharp
// Include: loads full Task entities.
var projects = await db.Projects.Include(p => p.Tasks).ToListAsync();

// Projection: computes the count in SQL, no Task entities loaded at all.
var summaries = await db.Projects.Select(p => new { p.ProjectName, TaskCount = p.Tasks.Count() }).ToListAsync();
```

---

## Q9. What does `AsNoTracking()` do, and when should you use it?
**Answer:**
By default, EF Core's change tracker keeps a snapshot of every entity it returns, so it can detect what changed when `SaveChanges()` is later called. `AsNoTracking()` skips this snapshot/comparison machinery entirely, which is pure savings (less memory, less CPU) for any query whose results will only ever be **read**, never modified and saved back through that same `DbContext` instance — which describes the vast majority of typical read-only API GET endpoints.

---

## Q10. Is `FromSqlInterpolated`'s string-interpolation syntax actually safe from SQL injection, despite looking identical to unsafe raw string interpolation?
**Answer:**
Yes — EF Core intercepts the `FormattableString` produced by `$"..."` **before** it becomes a plain string, converting each `{expression}` placeholder into a properly bound SQL parameter rather than substituting the value directly into the text. The syntax is deliberately similar to ordinary (unsafe) interpolation specifically so developers reach for the safe pattern by habit — but the underlying mechanism is fundamentally different from `string.Format`/plain `$"..."` used to build a query string manually, which `FromSqlRaw` with concatenated values does not protect against.

---

## Q11. When would LINQ/EF Core genuinely be unable to express a requirement, forcing a raw-SQL escape hatch?
**Answer:**
Recursive CTEs (Topic 07's hierarchy-walking pattern) have no LINQ equivalent — EF Core cannot translate a self-referencing recursive query into LINQ syntax. Other cases include specific query hints, certain window-function shapes not covered by EF Core's LINQ translation, and calling a stored procedure that returns a complex or dynamic shape. In these cases, `FromSqlInterpolated`/`ExecuteSqlInterpolatedAsync` are the correct, still-parameterised escape hatches — never manually concatenated `FromSqlRaw`.

---

## Q12. Why is `await` (async) preferred over synchronous calls for database access in a web application?
**Answer:**
A synchronous database call (`ExecuteReader`, `ToList()`) blocks the calling thread for the entire duration of the network round trip to SQL Server, even though that thread is doing nothing but waiting. Under concurrent load (many simultaneous requests), this ties up thread-pool threads unnecessarily, limiting how many requests the application can serve concurrently with a given thread pool size. The async equivalents (`ExecuteReaderAsync`, `ToListAsync()`) release the thread back to the pool while waiting for the I/O to complete, allowing far more concurrent requests to be served — the same underlying async/await benefit covered for ASP.NET Core generally in Phase 5.

---

## Q13. Design question: you're building a reporting endpoint that needs a genuinely complex query (multiple CTEs, window functions) with full control over the exact execution plan, versus a simple CRUD endpoint for creating/editing a single task. Which data-access layer would you choose for each, and why?
**Answer:**
For the **complex reporting endpoint**: raw ADO.NET or Dapper, writing the T-SQL by hand — the whole value of Topics 07/09/13's techniques (CTEs, window functions, precise index-supporting predicates) is undermined if a LINQ-to-SQL translation layer decides on a different, less-optimal shape, or simply can't express the query at all (recursive CTEs). Full control over the exact SQL text matters most when performance and correctness for one specific, expensive query are the primary concern.

For the **simple CRUD endpoint**: EF Core — the LINQ query is simple enough that translation quality isn't a concern, and EF Core's change tracking, validation integration, and migration-driven schema management pay for themselves on straightforward create/update/delete operations against a small number of entities. The productivity and consistency benefits (matching how the rest of a typical ASP.NET Core + EF Core codebase already works) outweigh the marginal control lost versus hand-written SQL for this shape of operation.

The general principle: match the tool's trade-off (control vs. convenience) to the actual complexity and performance-criticality of the specific query, rather than picking one data-access layer for the entire application uniformly.
