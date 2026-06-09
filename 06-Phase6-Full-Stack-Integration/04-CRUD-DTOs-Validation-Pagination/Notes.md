# Topic 4: CRUD, DTOs, Validation, Filtering & Pagination

> Build TaskFlow's resource APIs (`/projects`, `/tasks`, `/comments`) with **production ergonomics** — proper DTOs, layered validation, RFC 7807 errors, pagination, sorting, filtering, partial updates, idempotency, and ETags.

---

## 1. REST Refresher

| Method | Idempotent? | Safe? | Body | Use |
|---|---|---|---|---|
| GET | ✅ | ✅ | none | Read |
| POST | ❌ | ❌ | resource | Create / non-idempotent action |
| PUT | ✅ | ❌ | full resource | Replace |
| PATCH | ❌ (per RFC) but usually ✅ in practice | ❌ | partial | Partial update |
| DELETE | ✅ | ❌ | none | Remove |

> **Idempotent** = N identical calls = same effect as 1. Important for retries, network blips, and at-least-once delivery.

### Status codes you'll use most

- **2xx**: 200 OK, 201 Created (+ `Location`), 202 Accepted (async), 204 No Content (DELETE/PUT with empty body).
- **4xx**: 400 (malformed), 401 (unauthenticated), 403 (forbidden), 404 (not found), 409 (conflict), 412 (precondition failed — concurrency), 422 (validation), 429 (rate limit).
- **5xx**: 500 (unexpected), 503 (overloaded / dependency down).

---

## 2. URL Design — Nested vs Flat

| Style | Pros | Cons |
|---|---|---|
| **Nested** `/projects/{pid}/tasks` | Clear ownership; FK is implicit | Deep paths (`/orgs/{o}/projects/{p}/tasks/{t}/comments/{c}`) |
| **Flat** `/tasks?projectId=` | Short, easy to filter | Ownership less obvious in URL |

**TaskFlow rule:** Use **nested URLs for *creation* and *listing-by-parent***, **flat URLs for *get-by-id* and *partial updates***. Examples:

- `POST /projects/{projectId}/tasks` — create a task in this project
- `GET /projects/{projectId}/tasks?status=Todo&page=1` — list its tasks
- `GET /tasks/{taskId}` — flat resource lookup
- `PUT|PATCH|DELETE /tasks/{taskId}` — flat mutations

---

## 3. Controllers vs Minimal APIs

Both ship with .NET 8/9 and have feature parity (filters, model binding, OpenAPI). Pick by team preference.

| Controllers | Minimal APIs |
|---|---|
| Inheritance, attributes, action filters | Endpoint groups + endpoint filters |
| Familiar to MVC devs | Less ceremony, source-gen friendly |
| Slightly more allocation per request | A bit faster per request |

We'll show **both** for the create-task endpoint.

```csharp
// Controllers
[ApiController]
[Route("api/v{version:apiVersion}/projects/{projectId:guid}/tasks")]
[Authorize]
public sealed class TasksController(IMediator mediator) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType(typeof(TaskDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Create(Guid projectId, CreateTaskRequest body, CancellationToken ct)
    {
        var id = await mediator.Send(new CreateTaskCommand(projectId, body), ct);
        return CreatedAtRoute("GetTaskById", new { taskId = id }, body);
    }
}

// Minimal API equivalent
app.MapPost("/api/v1/projects/{projectId:guid}/tasks",
    async (Guid projectId, CreateTaskRequest body, IMediator m, CancellationToken ct) =>
        Results.CreatedAtRoute("GetTaskById",
            new { taskId = await m.Send(new CreateTaskCommand(projectId, body), ct) }, body))
    .RequireAuthorization()
    .WithName("CreateTask")
    .Produces<TaskDto>(201).ProducesValidationProblem();
```

---

## 4. DTO Patterns — Don't Expose Entities

| DTO | Direction | Notes |
|---|---|---|
| **Request DTO** | Inbound | Lean — only fields the client may set |
| **Response DTO** | Outbound | Includes computed fields, hides PII |
| **ViewModel** | API → UI shaping | Per-screen optimization; can flatten joins |

Why never expose entities:

- Over-fetching (lazy nav properties leak SQL).
- Over-posting (clients set `IsAdmin = true`).
- Coupling — entity changes break clients.
- Cycles in JSON serialization.

```csharp
// Request
public sealed record CreateTaskRequest(
    string Title, string? Description, TaskPriority Priority, DateOnly? DueDate,
    IReadOnlyList<Guid>? AssigneeIds, IReadOnlyList<string>? Tags);

// Response
public sealed record TaskDto(
    Guid Id, Guid ProjectId, string Title, string? Description, TaskStatus Status,
    TaskPriority Priority, DateOnly? DueDate, IReadOnlyList<Guid> Assignees,
    IReadOnlyList<string> Tags, DateTime CreatedAt, DateTime UpdatedAt, string ETag);
```

### Mapping options

| Tool | Style | Cost |
|---|---|---|
| Manual | Explicit, refactor-friendly | Verbose for 100+ DTOs |
| **AutoMapper** | Convention + profile | Reflection at runtime; ProjectTo helps |
| **Mapperly** | Source generator | Zero runtime overhead, compile-time errors |

For TaskFlow MVP we use AutoMapper for breadth + Mapperly for hot paths.

---

## 5. Validation Layers

```
HTTP request
  → Model binding   (formats, types)
  → DataAnnotations (Required, Range, MaxLength)
  → FluentValidation pipeline behavior
  → Domain invariants (in handler / aggregate)
```

Client never sees the next layer's rules — fail fast at the earliest one.

```csharp
public sealed class CreateTaskValidator : AbstractValidator<CreateTaskRequest>
{
    public CreateTaskValidator(ITaskUniqueness uniq)
    {
        RuleFor(x => x.Title).NotEmpty().Length(1, 200);
        RuleFor(x => x.Priority).IsInEnum();
        RuleFor(x => x.DueDate).GreaterThanOrEqualTo(DateOnly.FromDateTime(DateTime.UtcNow))
            .When(x => x.DueDate.HasValue);
        RuleFor(x => x).MustAsync(async (req, ct) =>
            !await uniq.ExistsAsync(req.Title, ct))
            .WithMessage("Task title already exists in this project.");
    }
}
```

> **Async rules** must run inside the pipeline behavior — controllers' attribute-driven validation is sync only.

---

## 6. RFC 7807 Problem Details

`application/problem+json` shape:

```json
{
  "type": "https://taskflow.app/errors/validation",
  "title": "One or more validation errors occurred.",
  "status": 422,
  "errors": { "title": ["Required"] },
  "traceId": "00-c3a..."
}
```

```csharp
builder.Services.AddProblemDetails(o =>
{
    o.CustomizeProblemDetails = ctx =>
    {
        ctx.ProblemDetails.Extensions["traceId"] = ctx.HttpContext.TraceIdentifier;
        ctx.ProblemDetails.Instance = ctx.HttpContext.Request.Path;
    };
});
```

### 422 vs 400 debate

- **400** — request was malformed (bad JSON, wrong types).
- **422** — request was syntactically valid but semantically wrong (validation failure).

Both are common; pick one and document it. Many teams use 400 universally.

---

## 7. Pagination Strategies

### Offset (page / pageSize)

```sql
SELECT ... FROM Tasks ORDER BY CreatedAt DESC
OFFSET (@page-1)*@pageSize ROWS FETCH NEXT @pageSize ROWS ONLY;
```

| Pros | Cons |
|---|---|
| Simple URL, "page X of Y" UX | Performance degrades on deep pages (`OFFSET 1_000_000`) |
| Total count available | Inconsistent if rows change between pages |

### Keyset (seek)

```sql
SELECT ... FROM Tasks
WHERE (CreatedAt, Id) < (@cursorCreatedAt, @cursorId)
ORDER BY CreatedAt DESC, Id DESC
FETCH NEXT @pageSize ROWS ONLY;
```

| Pros | Cons |
|---|---|
| O(log n) regardless of depth | No "jump to page 50" |
| Stable on inserts | Two-column cursor encoding |

**TaskFlow rule:** offset for human UI lists (≤ 100 pages), **keyset** for activity log / infinite scroll / bulk export.

### Pagination response envelope

```json
{
  "items": [ ... ],
  "page": 1, "pageSize": 25, "total": 137,
  "next": "/api/v1/projects/{id}/tasks?page=2&pageSize=25"
}
```

---

## 8. Sorting

Allow `?sort=field,-other` (leading `-` = DESC). **Whitelist** sortable columns or you're one fuzzer away from `ORDER BY (SELECT password ...)`.

```csharp
private static readonly IReadOnlyDictionary<string, Expression<Func<TaskItem, object>>> SortMap =
    new Dictionary<string, Expression<Func<TaskItem, object>>>(StringComparer.OrdinalIgnoreCase)
    {
        ["title"] = t => t.Title,
        ["dueDate"] = t => t.DueDate!,
        ["createdAt"] = t => t.CreatedAt,
    };
```

Provide a default sort. Reject unknown fields with **400**, not silently fall back.

---

## 9. Filtering

| Pattern | Example |
|---|---|
| Equality | `?status=InProgress` |
| Multi-value | `?tags=urgent,bug` |
| Range | `?dueAfter=2026-06-01&dueBefore=2026-07-01` |
| Boolean | `?onlyMine=true` |

For complex filters, consider:

- **OData** — rich query syntax, `$filter=Priority eq 'High'`. Powerful but heavy.
- **JSON:API** — opinionated standard with filter/sort/include conventions.

Start simple — query string params with explicit handlers. Adopt OData only if the consumer demands it.

---

## 10. Search

| Source | Tool |
|---|---|
| SQL Server | Full-Text Search catalogs, `CONTAINS`, `FREETEXT` |
| PostgreSQL | `tsvector` + `pg_trgm` |
| Anything bigger | Elasticsearch / Azure AI Search |

Avoid `LIKE '%term%'` on large tables — it's a full scan.

---

## 11. Projection in Queries

```csharp
var page = await db.Tasks.AsNoTracking()
    .Where(t => t.ProjectId == projectId)
    .OrderByDescending(t => t.CreatedAt)
    .Skip((p-1)*size).Take(size)
    .Select(t => new TaskListItemDto(
        t.Id, t.Title, t.Status, t.Priority, t.DueDate,
        t.Assignees.Count, t.Tags.Select(x => x.Name).ToList()))
    .ToListAsync(ct);
```

`AutoMapper.ProjectTo<TaskListItemDto>(_mapper.ConfigurationProvider)` does the same with mapping config. Either way, **never** materialize the entity then map in memory — that's an N+1 invitation.

---

## 12. Concurrency on Update — ETag / If-Match

```http
GET /api/v1/tasks/abc                  → 200, ETag: "8f4..." (RowVersion base64)
PUT /api/v1/tasks/abc                  → 200 OK
  If-Match: "8f4..."

PUT without/wrong If-Match            → 412 Precondition Failed
```

```csharp
[HttpPut("{taskId:guid}")]
public async Task<IActionResult> Update(Guid taskId, [FromHeader(Name = "If-Match")] string? ifMatch,
    UpdateTaskRequest body, CancellationToken ct)
{
    if (string.IsNullOrEmpty(ifMatch)) return Problem(statusCode: 428, title: "If-Match required");
    var dto = await mediator.Send(new UpdateTaskCommand(taskId, body, ParseRowVersion(ifMatch)), ct);
    Response.Headers.ETag = $"\"{Convert.ToBase64String(dto.RowVersion)}\"";
    return Ok(dto);
}
```

Two clients hitting the same task concurrently — the slower wins-or-fails-cleanly (not silently overwrites).

---

## 13. Partial Updates — PATCH

| Format | Content-Type | Power |
|---|---|---|
| **JSON Patch** (RFC 6902) | `application/json-patch+json` | Add / remove / replace / move / test |
| **JSON Merge Patch** (RFC 7396) | `application/merge-patch+json` | Send only changed fields |

```http
PATCH /api/v1/tasks/abc
Content-Type: application/json-patch+json

[
  { "op": "replace", "path": "/title", "value": "New Title" },
  { "op": "test",    "path": "/version", "value": 4 }
]
```

`Microsoft.AspNetCore.JsonPatch` package + `JsonPatchDocument<UpdateTaskRequest>`. Pair with FluentValidation on the *result* of applying the patch.

> **Pitfall:** Don't apply patch directly to the entity — apply to a **DTO**, validate, then map.

---

## 14. Bulk Operations

For dashboards and admin tools:

```http
POST /api/v1/tasks/bulk
[
  { "title": "Write tests", "projectId": "..." },
  { "title": "Update docs", "projectId": "..." }
]
```

Transaction boundary choice:

- **All-or-nothing** — single transaction; one row fails → 422 with per-item errors.
- **Best effort** — each row in its own UoW; response shape includes successes + failures.

Document which one your endpoint uses. Most TaskFlow bulk endpoints are all-or-nothing for predictability.

---

## 15. Idempotency Keys

```http
POST /api/v1/projects/{id}/tasks
Idempotency-Key: 4f3b-...
```

Server stores `(idempotencyKey, response)` for 24 h; subsequent calls with the same key + same body return the **cached** response without creating a duplicate.

Useful for:

- Mobile apps with flaky networks.
- Webhook retries.
- "Submit" buttons that double-fire.

---

## 16. Caching Responses

| Mechanism | When |
|---|---|
| `Cache-Control: max-age=60` | Public, short-lived |
| `ETag` + `If-None-Match` | Per-resource freshness check (returns 304) |
| Output caching (.NET 8) | Server-side cached response |
| `IMemoryCache` / Redis | App-level cache (see Topic 11) |

```csharp
[HttpGet("{taskId:guid}", Name = "GetTaskById")]
[ResponseCache(Duration = 30, Location = ResponseCacheLocation.Any, VaryByHeader = "Authorization")]
public async Task<ActionResult<TaskDto>> Get(Guid taskId, CancellationToken ct) { ... }
```

Authorization-bearing responses must `Vary: Authorization` to avoid cross-user cache poisoning.

---

## 17. Response Shaping

- **HATEOAS** — embed links so clients can navigate without hardcoding URLs. Heavy; usually overkill for a SPA.
- **Field selection** — `?fields=id,title,status` returns only those properties.
- **Envelopes vs flat** — single object for resources, paged envelope for lists. Don't mix.

---

## 18. Sample TasksController — End to End

```csharp
[ApiController]
[Route("api/v{version:apiVersion}/projects/{projectId:guid}/tasks")]
[ApiVersion("1.0")]
[Authorize]
public sealed class TasksController(IMediator mediator) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<TaskListItemDto>> List(Guid projectId, [FromQuery] ListTasksQuery q, CancellationToken ct)
        => mediator.Send(q with { ProjectId = projectId }, ct);

    [HttpGet("/api/v{version:apiVersion}/tasks/{taskId:guid}", Name = "GetTaskById")]
    public Task<TaskDto> Get(Guid taskId, CancellationToken ct) => mediator.Send(new GetTaskQuery(taskId), ct);

    [HttpPost]
    [ProducesResponseType(typeof(TaskDto), 201)]
    public async Task<IActionResult> Create(Guid projectId, CreateTaskRequest body,
        [FromHeader(Name = "Idempotency-Key")] string? key, CancellationToken ct)
    {
        var dto = await mediator.Send(new CreateTaskCommand(projectId, body, key), ct);
        return CreatedAtRoute("GetTaskById", new { taskId = dto.Id }, dto);
    }

    [HttpPut("/api/v{version:apiVersion}/tasks/{taskId:guid}")]
    public async Task<TaskDto> Update(Guid taskId, [FromHeader(Name = "If-Match")] string ifMatch,
        UpdateTaskRequest body, CancellationToken ct)
        => await mediator.Send(new UpdateTaskCommand(taskId, body, ifMatch), ct);

    [HttpPatch("/api/v{version:apiVersion}/tasks/{taskId:guid}")]
    [Consumes("application/json-patch+json")]
    public Task<TaskDto> Patch(Guid taskId, [FromBody] JsonPatchDocument<UpdateTaskRequest> patch, CancellationToken ct)
        => mediator.Send(new PatchTaskCommand(taskId, patch), ct);

    [HttpDelete("/api/v{version:apiVersion}/tasks/{taskId:guid}")]
    [ProducesResponseType(204)]
    public async Task<IActionResult> Delete(Guid taskId, CancellationToken ct)
    {
        await mediator.Send(new DeleteTaskCommand(taskId), ct);
        return NoContent();
    }
}
```

---

## 19. Common Mistakes

| Mistake | Cost | Fix |
|---|---|---|
| Returning entities instead of DTOs | Over-fetching, JSON cycles, security | Always project to DTO |
| `OFFSET` on million-row tables | Slow deep pages | Keyset for big lists |
| No sort whitelist | SQL injection-shaped fuzzing | Validated dictionary |
| Validating in controller only | Domain rules leak | Pipeline behavior |
| Throwing `Exception` for validation | 500 instead of 422 | Custom `ValidationException` mapped by handler |
| Forgetting `CancellationToken` | Wasted work after client disconnects | Pass it everywhere |
| Logging request bodies | PII leakage | Allow-list / redact |

---

## 20. Interview Q&A

**Q1. Why DTOs over entities in API responses?** Entities expose nav properties (cycles), allow over-posting, and couple your wire format to your storage model.

**Q2. 400 vs 422 for validation errors?** Both are common. 400 = "I can't even parse you"; 422 = "I parsed, but the semantics fail". Pick one and document.

**Q3. PUT vs PATCH?** PUT replaces the whole resource (idempotent); PATCH applies a delta (often non-idempotent unless designed otherwise).

**Q4. ETag use case?** Concurrency check on writes (`If-Match` → 412) and freshness on reads (`If-None-Match` → 304).

**Q5. Why keyset over offset pagination?** Constant-time deep pages, stable across inserts; trade-off is no jump-to-page.

**Q6. How do you implement Idempotency-Key?** Persist `(key, requestHash, response)` for a TTL; replay returns cached response without re-executing.

**Q7. JSON Patch vs JSON Merge Patch?** Patch (RFC 6902) is operation-list; Merge (RFC 7396) is "send what changed". Patch supports `test`, `move`; Merge is simpler.

**Q8. Why whitelist sortable columns?** Prevents accidental cost (sorting an unindexed huge column) and SQL surface area abuse.

**Q9. Where should async validation live?** In a MediatR pipeline behavior or before-handler step — controllers' attribute validation is sync only.

**Q10. Bulk endpoint: all-or-nothing or best-effort?** Document the contract. All-or-nothing is predictable; best-effort needs per-item error reporting in the response.

---

## 21. Further Reading

- Microsoft — *Web API design (best practices)*
- Mark Massé — *REST API Design Rulebook*
- Kevin Sookocheff — *On choosing pagination strategies*
- Vladimir Khorikov — *DDD validation* posts
