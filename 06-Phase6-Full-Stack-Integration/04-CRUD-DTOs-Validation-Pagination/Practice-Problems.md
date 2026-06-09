# Topic 4 — Practice Problems

> Build TaskFlow's resource APIs end-to-end. Solutions go in `PracticeProblemsSolutions/` (an ASP.NET Core 9 webapi project).

**Concept tags:** `rest` `dtos` `automapper` `fluent-validation` `problem-details` `pagination` `etag` `json-patch` `idempotency`

**Setup**

```powershell
cd 06-Phase6-Full-Stack-Integration\04-CRUD-DTOs-Validation-Pagination\PracticeProblemsSolutions
dotnet run
```

---

## P1 — Project CRUD with DTOs + AutoMapper  *(Easy)*

**Tags:** `crud` `dtos` `automapper` `created-at-route`

### Requirements

- Add `Project` entity (Id, OwnerId, Name, Summary, CreatedAt, UpdatedAt, RowVersion).
- Add `ProjectDto`, `CreateProjectRequest`, `UpdateProjectRequest`.
- Implement `ProjectsController` with:
  - `POST /api/v1/projects` → 201 + Location header.
  - `GET /api/v1/projects/{id}` → 200 / 404.
  - `DELETE /api/v1/projects/{id}` → 204 / 404.
- AutoMapper `ProjectMappings : Profile` covers all conversions.
- Wire SQLite in-memory for the practice run (`Data Source=topic04.db`).

### Look-fors

- [ ] No entity types appear in the Swagger response schema.
- [ ] `CreatedAtRoute` builds the right URL (proves named route hookup).
- [ ] `delete` returns 204 with empty body, not 200.

---

## P2 — Listing Endpoint with Offset Pagination + Sort Whitelist  *(Medium)*

**Tags:** `pagination` `sort` `query-params`

### Requirements

- Implement `GET /api/v1/tasks` with query params:
  - `projectId` (Guid, optional)
  - `status` (enum, optional, multi-value via comma)
  - `page` (default 1, max 1000)
  - `pageSize` (default 25, max 100)
  - `sort` (default `-createdAt`)
- Whitelist sort fields: `title`, `dueDate`, `createdAt`, `priority`. Prefix `-` reverses.
- Reject unknown sort fields with **400** + ProblemDetails.
- Response envelope: `{ items, page, pageSize, total, next? }`.

### Look-fors

- [ ] Ascending and descending verified for each whitelisted column.
- [ ] `pageSize > 100` clamps or 400s — your choice, document it.
- [ ] Total count is accurate even with filters applied.

---

## P3 — FluentValidation with Async Uniqueness Rule  *(Medium)*

**Tags:** `fluent-validation` `pipeline-behavior` `async-rule`

### Requirements

- `CreateTaskRequest` with `Title`, `Priority`, `DueDate?`, `AssigneeIds?`, `Tags?`.
- `CreateTaskValidator`:
  - Title required, 1–200 chars.
  - DueDate ≥ today (when present).
  - Title unique within project (async DB lookup via `ITaskUniqueness`).
  - Priority must be a valid enum.
- Register `ValidationBehavior<,>` as a MediatR pipeline behavior so validation runs *before* the handler.
- Verify failures produce **422** with field-keyed errors.

### Look-fors

- [ ] Async rule does **not** run for cancelled requests.
- [ ] Validator unit-tested without DB (mock `ITaskUniqueness`).
- [ ] Field paths in error response match the request shape (camelCase).

---

## P4 — Global RFC 7807 Exception Handler  *(Medium)*

**Tags:** `problem-details` `iexceptionhandler` `traceid`

### Requirements

- Define exceptions: `ValidationException`, `NotFoundException`, `ForbiddenException`, `ConflictException`.
- Implement `GlobalExceptionHandler : IExceptionHandler` mapping each to a status + ProblemDetails.
- Always include `traceId` from `Activity.Current?.TraceId` or `HttpContext.TraceIdentifier`.
- Wire `AddExceptionHandler<>()` and `AddProblemDetails()`.
- Add a deliberately failing endpoint per exception type to demo the responses in Swagger / curl.

### Look-fors

- [ ] Unhandled exceptions in dev still return ProblemDetails (no leaking stack to client).
- [ ] Validation errors come through as `ValidationProblemDetails` with `errors`.
- [ ] `Content-Type: application/problem+json`.

---

## P5 — ETag Concurrency on PUT `/tasks/{id}`  *(Hard)*

**Tags:** `etag` `if-match` `rowversion` `412`

### Requirements

- Add `RowVersion byte[]` to `TaskItem` (`IsRowVersion()`).
- `GET /api/v1/tasks/{id}` returns `ETag: "<base64-rowversion>"`.
- `PUT /api/v1/tasks/{id}`:
  - Requires `If-Match` header → 428 Precondition Required if missing.
  - Compares to DB; mismatch → 412 Precondition Failed.
  - Success → 200 + new ETag header.
- Demonstrate the conflict path with two parallel `curl` calls.

### Look-fors

- [ ] EF translates the row version into the UPDATE WHERE clause.
- [ ] Conflict response body is ProblemDetails with hint "GET the latest version and retry".
- [ ] Idempotent — repeated identical PUTs with the same If-Match succeed.

---

## P6 — Keyset Pagination for Activity Log  *(Hard)*

**Tags:** `keyset` `cursor` `infinite-scroll`

### Requirements

- Activity entity with `Id Guid`, `ProjectId`, `OccurredAt DateTime`, `Type`, `Payload jsonb-ish`.
- `GET /api/v1/projects/{id}/activity?cursor=<base64>&limit=50`.
- Keyset by `(OccurredAt DESC, Id DESC)` with composite cursor — base64 of `{"o":"<iso>","i":"<guid>"}`.
- Response: `{ items, nextCursor? }`.
- Index hint: `IX_Activity_ProjectId_OccurredAt_Id DESC`.

### Look-fors

- [ ] No `OFFSET` anywhere in the generated SQL.
- [ ] Cursor is opaque to clients (base64 of JSON, not raw IDs).
- [ ] Stable across inserts during pagination (verified with a script).

---

## Self-Review Checklist

- [ ] You can list at least 4 layers where validation happens.
- [ ] You can explain when 400 vs 422 is appropriate.
- [ ] You implemented offset and keyset pagination.
- [ ] You produced a 412 from real concurrent updates.
- [ ] Every error response is `application/problem+json` with `traceId`.
- [ ] Sort fields are explicitly whitelisted.
