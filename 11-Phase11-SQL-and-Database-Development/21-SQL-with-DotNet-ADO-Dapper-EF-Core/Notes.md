# Topic 21: SQL with .NET — ADO.NET, Dapper & EF Core

> Every topic so far has assumed a query window. TaskFlow's actual API is a .NET application, and everything from Topic 07's CTEs to Topic 17's concurrency guarantees only matters if the C# code calling into SQL Server preserves them — a parameterised query written carelessly in ADO.NET is exactly as vulnerable as the raw concatenation from Topic 19. This topic covers the three ways .NET talks to SQL Server, connection lifecycle and pooling, async patterns, and the EF Core-specific translation and N+1 pitfalls that turn correct LINQ into a slow query — the last link between this phase and Phase 5's ASP.NET Core work.

---

## 1. The Three Layers

| Layer | What it is | Control vs convenience |
|---|---|---|
| **ADO.NET** (`Microsoft.Data.SqlClient`) | The low-level, direct API — `SqlConnection`, `SqlCommand`, `SqlDataReader` | Maximum control, most boilerplate |
| **Dapper** | A thin "micro-ORM" — maps query results to objects, still writes SQL by hand | A thin layer over ADO.NET; SQL stays explicit |
| **EF Core** | A full ORM — LINQ translated to SQL, change tracking, migrations | Maximum convenience, SQL is generated, not written |

All three ultimately execute through the same underlying ADO.NET connection/command machinery — Dapper is literally an extension-method library over `IDbConnection`, and EF Core's SQL Server provider is a very sophisticated ADO.NET consumer.

---

## 2. ADO.NET: Connections, Commands, and Parameters

```csharp
using Microsoft.Data.SqlClient;

// using: guarantees Dispose() runs, returning the connection to the POOL (never truly "closing" the socket).
await using var conn = new SqlConnection(connectionString);
await conn.OpenAsync();

await using var cmd = new SqlCommand(
    "SELECT TaskId, Title, StatusId FROM app.Tasks WHERE ProjectId = @ProjectId", conn);
cmd.Parameters.Add("@ProjectId", SqlDbType.Int).Value = projectId;   // ALWAYS parameterise (Topic 19)

await using SqlDataReader reader = await cmd.ExecuteReaderAsync();
var tasks = new List<TaskDto>();
while (await reader.ReadAsync())
{
    tasks.Add(new TaskDto
    {
        TaskId = reader.GetInt32(0),
        Title = reader.GetString(1),
        StatusId = reader.GetByte(2)
    });
}
```

| Method | Use for |
|---|---|
| `ExecuteReaderAsync` | A result set (`SELECT`) |
| `ExecuteNonQueryAsync` | Rows affected (`INSERT`/`UPDATE`/`DELETE`), no result set |
| `ExecuteScalarAsync` | A single value (e.g. `COUNT(*)`, `SCOPE_IDENTITY()`) |

```csharp
// SqlParameter with explicit SqlDbType/size -- do this, don't rely on AddWithValue's type inference.
cmd.Parameters.Add("@Title", SqlDbType.NVarChar, 200).Value = title;

// AddWithValue infers the parameter's SQL type from the CLR value's runtime type --
// a string always infers NVARCHAR(4000)/NVARCHAR(MAX)-ish regardless of the actual
// column's declared width, which can produce an implicit conversion (Topic 02/13)
// and defeat an index seek on that column, or silently truncate on the write side.
cmd.Parameters.AddWithValue("@Title", title);   // works, but avoid in performance-sensitive code
```

> **Anti-pattern:** `SqlParameter` type/size mismatches. `AddWithValue` is convenient but infers a generic type from the CLR value — a parameter compared against an `NVARCHAR(200)` column that doesn't match precisely can produce an implicit conversion the optimizer can't seek through, exactly the SARGability problem from Topics 02 and 03, now introduced entirely from the application layer with no visible T-SQL change.

### Async all the way down

```csharp
// WRONG: blocks a thread-pool thread waiting on I/O that's already async underneath.
var result = cmd.ExecuteReader();          // sync-over-async risk if called from an async context incorrectly
// RIGHT:
var result = await cmd.ExecuteReaderAsync();
```

Under real concurrent load (many simultaneous requests), synchronous ADO.NET calls tie up a thread-pool thread for the entire duration of a network round trip to SQL Server — async calls release that thread back to the pool while waiting, letting far more concurrent requests be served with the same thread pool size. This is a direct connection back to Phase 5's ASP.NET Core async/await coverage.

---

## 3. Connection Pooling

`SqlConnection.Open()`/`OpenAsync()` does not necessarily open a new physical TCP connection — ADO.NET maintains a **pool** of physical connections per unique connection string, and `Open`/`Dispose` typically borrow/return a pooled connection rather than truly connecting/disconnecting each time.

```csharp
// Idiomatic: open, use, dispose (return to pool) -- do this PER operation, not held for the app's lifetime.
await using var conn = new SqlConnection(connectionString);
await conn.OpenAsync();
// ... one or a few related operations ...
```   // conn.Dispose() here returns the connection to the pool -- it usually does NOT close the socket.

| Anti-pattern | Consequence |
|---|---|
| A single, long-lived static `SqlConnection` held for the app's entire lifetime | Defeats pooling's purpose; a dropped/reset connection breaks every subsequent call with no automatic recovery |
| Opening a connection per **row** in a loop instead of once per **operation** | Pool exhaustion under load — connections are requested and returned far more often than necessary |
| Never disposing connections (`ExecuteReader` without `using`) | Pool exhaustion — connections are never returned, and the pool eventually has none available, causing new requests to time out waiting |
| Different connection strings for logically-identical connections (e.g. inconsistent casing/whitespace) | Each distinct string gets its **own** separate pool — accidentally fragmenting what should be one shared pool |

```
Max Pool Size=100;Min Pool Size=5;Connection Timeout=15;
```

Pool size tuning matters under real load — too small, and requests queue waiting for a pooled connection; too large, and SQL Server itself may be overwhelmed by concurrent connections (each with its own memory/session overhead) beyond what it can efficiently serve.

---

## 4. Dapper: SQL You Write, Objects You Get Back

```csharp
using Dapper;
using Microsoft.Data.SqlClient;

await using var conn = new SqlConnection(connectionString);

// Query<T>: maps each row to a TaskDto by column-name-to-property matching.
var tasks = await conn.QueryAsync<TaskDto>(
    "SELECT TaskId, Title, StatusId FROM app.Tasks WHERE ProjectId = @ProjectId",
    new { ProjectId = projectId });                     // parameterised automatically -- safe by default

// QuerySingleOrDefaultAsync: exactly 0 or 1 row expected; throws if MORE than one comes back.
var task = await conn.QuerySingleOrDefaultAsync<TaskDto>(
    "SELECT TaskId, Title FROM app.Tasks WHERE TaskId = @TaskId", new { TaskId = taskId });

// ExecuteAsync: for INSERT/UPDATE/DELETE, returns rows affected.
int rowsAffected = await conn.ExecuteAsync(
    "UPDATE app.Tasks SET StatusId = @StatusId WHERE TaskId = @TaskId",
    new { StatusId = (byte)6, TaskId = taskId });

// Multi-mapping: one JOIN query, two related objects.
var taskWithProject = await conn.QueryAsync<TaskDto, ProjectDto, TaskDto>(
    @"SELECT t.TaskId, t.Title, p.ProjectId, p.ProjectName
      FROM app.Tasks AS t JOIN app.Projects AS p ON p.ProjectId = t.ProjectId
      WHERE t.TaskId = @TaskId",
    (task, project) => { task.Project = project; return task; },
    new { TaskId = taskId },
    splitOn: "ProjectId");                              // where the second object's columns begin

// Calling a stored procedure (Topic 15) -- output parameters map back into a DynamicParameters bag.
var p = new DynamicParameters();
p.Add("@ProjectId", projectId);
p.Add("@Title", title);
p.Add("@NewTaskId", dbType: DbType.Int32, direction: ParameterDirection.Output);
await conn.ExecuteAsync("app.usp_CreateTask", p, commandType: CommandType.StoredProcedure);
int newTaskId = p.Get<int>("@NewTaskId");
```

Dapper parameterises every value passed via its anonymous-object/`DynamicParameters` API automatically — the injection risk in Dapper appears only when raw string interpolation is used to build the SQL text itself (Topic 19 §2), never from the ordinary `new { ... }` parameter pattern.

| | Dapper | Raw ADO.NET |
|---|---|---|
| Result mapping | Automatic (reflection-based, column name → property) | Manual (`reader.GetInt32(0)`, etc.) |
| SQL control | Full — you write every statement | Full |
| Boilerplate | Much less | Significant |
| Change tracking / migrations | None — not its job | None |

---

## 5. EF Core: LINQ to SQL Translation

```csharp
public class TaskFlowDbContext : DbContext
{
    public DbSet<Task> Tasks => Set<Task>();
    public DbSet<Project> Projects => Set<Project>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Task>(e =>
        {
            e.ToTable("Tasks", schema: "app");                 // maps to app.Tasks (Topic 12 schema convention)
            e.HasKey(t => t.TaskId);
            e.Property(t => t.Title).HasMaxLength(200).IsRequired();
            e.HasOne(t => t.Project).WithMany(p => p.Tasks).HasForeignKey(t => t.ProjectId);
        });
    }
}

// LINQ query -- EF Core translates this to a single parameterised SQL statement.
var openTasks = await db.Tasks
    .Where(t => t.ProjectId == projectId && t.StatusId != 6 && t.StatusId != 7)
    .OrderByDescending(t => t.DueDate)
    .Select(t => new { t.TaskId, t.Title, t.DueDate })
    .ToListAsync();
-- Generated SQL (conceptually): SELECT TaskId, Title, DueDate FROM app.Tasks
--   WHERE ProjectId = @p0 AND StatusId NOT IN (6, 7) ORDER BY DueDate DESC
```

`.Select()` **projecting to only needed columns** is the EF Core equivalent of Topic 13's covering-index discipline — pulling back whole entities when only three columns are needed wastes network/memory and can prevent an otherwise-possible covering index from actually covering the query.

---

## 6. The N+1 Query Problem

The single most common EF Core performance bug — a loop that triggers one query per iteration instead of one query total.

```csharp
// N+1 BUG: one query to get projects, then ONE MORE QUERY PER PROJECT to lazy-load its tasks.
var projects = await db.Projects.ToListAsync();               // 1 query
foreach (var project in projects)
{
    var taskCount = project.Tasks.Count;                        // lazy-loaded -- N additional queries!
    Console.WriteLine($"{project.ProjectName}: {taskCount} tasks");
}
// 8 projects -> 1 + 8 = 9 round trips, when 1 or 2 would do.
```

```csharp
// FIX 1: Eager loading with Include -- ONE query with a JOIN, all data fetched upfront.
var projects = await db.Projects.Include(p => p.Tasks).ToListAsync();

// FIX 2 (usually better for this specific need): project directly to the shape you want.
// No entities loaded at all, no tracking overhead, exactly the columns needed --
// this is the EF Core equivalent of Topic 05's aggregation-in-the-database principle.
var projectSummaries = await db.Projects
    .Select(p => new { p.ProjectName, TaskCount = p.Tasks.Count() })
    .ToListAsync();
-- Generates ONE query with a GROUP BY/subquery -- the count happens in SQL Server, not in a C# loop.
```

| Symptom | Cause | Fix |
|---|---|---|
| One query per loop iteration | Lazy loading (navigation property accessed inside a loop, triggering a query per access) | `.Include()` for eager loading, or project directly (`.Select()`) to avoid loading entities at all |
| Query count grows with result size | Same root cause, different trigger | Same fixes |
| `DbContext` warns/logs "possible unintended lazy loading" | Lazy loading proxies enabled without realising it | Disable lazy loading by default; opt in per-query with `.Include()` |

> **Rule of thumb:** If a query's cost seems to scale with the **number of rows returned** rather than the query's own complexity, suspect N+1 first. Enable EF Core's logging (`.LogTo(Console.WriteLine)` in development) and count the actual SQL statements executed for a single logical operation — the fix is almost always `.Include()` or a `.Select()` projection, never "make the loop faster."

---

## 7. `AsNoTracking()` for Read-Only Queries

EF Core's **change tracker** compares an entity's current values against its originally-loaded snapshot to detect what needs saving on `SaveChanges()` — real, necessary overhead for entities you intend to modify, pure waste for ones you're only ever going to read and display.

```csharp
// Tracked (default): EF Core snapshots every returned entity for change detection. Unnecessary here --
-- this data is only ever displayed, never modified and saved back through this DbContext instance.
var tasks = await db.Tasks.Where(t => t.ProjectId == projectId).ToListAsync();

// AsNoTracking(): skips the snapshot/tracking machinery entirely -- faster, less memory, for read-only paths.
var tasks = await db.Tasks.AsNoTracking().Where(t => t.ProjectId == projectId).ToListAsync();
```

> **Rule of thumb:** Any query whose results won't be modified and saved back via the **same** `DbContext` instance should use `AsNoTracking()`. For a typical read-heavy API endpoint (a GET request that only displays data), this is nearly every query.

---

## 8. Raw SQL Escape Hatches — and Doing Them Safely

Sometimes LINQ genuinely can't express what's needed (a specific hint, a recursive CTE from Topic 07, a call to a stored procedure with complex output).

```csharp
// SAFE: FromSqlInterpolated parameterises the interpolated value automatically.
var tasks = await db.Tasks
    .FromSqlInterpolated($"SELECT * FROM app.Tasks WHERE ProjectId = {projectId}")
    .ToListAsync();

// SAFE: ExecuteSqlInterpolatedAsync for non-query DML, same automatic parameterisation.
await db.Database.ExecuteSqlInterpolatedAsync(
    $"UPDATE app.Tasks SET StatusId = 6 WHERE TaskId = {taskId}");

// DANGEROUS (Topic 19): FromSqlRaw with a manually-built, concatenated string.
var tasks = await db.Tasks
    .FromSqlRaw("SELECT * FROM app.Tasks WHERE ProjectId = " + projectId)     // NEVER do this
    .ToListAsync();

// SAFE use of FromSqlRaw: with an explicit, separate SqlParameter -- the pattern
// FromSqlRaw supports for cases where interpolation syntax doesn't fit.
var tasks = await db.Tasks
    .FromSqlRaw("SELECT * FROM app.Tasks WHERE ProjectId = {0}", projectId)
    .ToListAsync();
```

`FromSqlInterpolated`'s `$"..."` syntax looks exactly like the dangerous raw string interpolation from Topic 19, but EF Core intercepts the interpolation **before** building the final string, converting each `{expression}` into a bound parameter — the syntax is deliberately similar so developers reach for the safe version by habit, but the mechanism underneath is completely different from plain C# string interpolation.

---

## 9. Migrations as Schema-Change Discipline

EF Core Migrations generate versioned, incremental schema-change scripts from model changes — the application-code-first counterpart to the DDL discipline from Topic 02/11.

```csharp
// After changing the C# model (e.g. adding a property):
// dotnet ef migrations add AddTaskEstimateColumn
// dotnet ef database update
```

Every migration should be reviewed as real DDL before applying it to production — an auto-generated migration can produce a working-but-suboptimal change (e.g. an `ALTER COLUMN` that the model diff computed as "safe" but that actually rewrites the whole table, echoing Topic 02 §12's `ALTER COLUMN` pitfalls) that only a human reviewing the generated SQL would catch.

---

## Mental Model

> ADO.NET, Dapper, and EF Core are three different trade-offs between control and convenience over the exact same wire protocol and the exact same SQL Server underneath — none of them changes what makes a query fast, safe, or correct; they only change how much of that responsibility the framework takes on for you. Parameterisation is not optional in any of the three: ADO.NET's `SqlParameter`, Dapper's anonymous-object binding, and EF Core's LINQ translation (and its `FromSqlInterpolated` escape hatch) all bind values as data rather than text — the Topic 19 injection discipline doesn't change, only the syntax for satisfying it does. Connection pooling means "open and dispose per operation" is the correct pattern, not "hold one connection forever" or "open one per row" — both extremes defeat the pool for opposite reasons. And EF Core's specific convenience — LINQ that looks like it's just querying in-memory objects — is exactly what makes the N+1 problem so easy to write by accident: a navigation property accessed inside a loop is a database round trip wearing the costume of a property access, and the fix is always the same, load everything you need in one shaped query (`Include` or a projecting `Select`) instead of letting the framework fetch it one row at a time. Every principle from Topics 1–20 is still true here; this topic is just where it finally meets the C# code that calls it.

Move to [Practice Problems](./Practice-Problems.md).
