# Topic 10 — Practice Problems

> Project: `PracticeProblemsSolutions/` — xUnit test project covering unit, integration, and a Playwright E2E plan. Run `dotnet test` after `docker info` confirms Docker is up.

---

## P1 — Unit-test a handler with SQLite-in-memory

**Goal:** Test `CreateProjectHandler` against EF SQLite-in-memory (not `UseInMemoryDatabase`).

**Tasks**
1. Build `InMemoryDbFactory.Create()` returning a fresh `TaskFlowDbContext` backed by `SqliteConnection("Filename=:memory:")` with `Database.EnsureCreated()`.
2. Write `CreateProjectHandlerTests`:
   - Returns the created project's id and seeds an `ActivityLog` row.
   - Throws `ValidationException` on blank name.
   - Two projects with the same name in the same workspace → throws `ConflictException`.
3. Use FluentAssertions and the AAA layout. Each test owns its own connection (no shared state).
4. Add `[Trait("Category", "Unit")]` and a CI filter so unit tests run separately.

**Acceptance**
- All three tests pass with `dotnet test --filter Category=Unit`.
- Tests run in <500 ms total — no Docker required.
- Removing FK enforcement in the handler causes a test failure (proving SQLite catches it).

---

## P2 — `WebApplicationFactory<Program>` + Testcontainers (MS SQL)

**Goal:** Boot the API in-process against a real SQL Server container.

**Tasks**
1. Create `TaskFlowApiFactory : WebApplicationFactory<Program>, IAsyncLifetime` that starts an `MsSqlContainer` and overrides `ConnectionStrings:TaskFlow`.
2. Add `public partial class Program {}` at the end of the API's `Program.cs` if not already.
3. Override `ConfigureTestServices` to swap real `IEmailSender` and `IAvScanner` for fakes.
4. Define `[CollectionDefinition("api")] public class ApiCollection : ICollectionFixture<TaskFlowApiFactory>`.
5. Apply migrations (`db.Database.MigrateAsync()`) once at factory startup.

**Acceptance**
- The first test in the run takes ~2–5 s (container startup); subsequent tests reuse it.
- `factory.CreateClient().GetAsync("/health/ready")` returns 200.
- Killing the host machine's Docker daemon results in a clear "Docker not running" error, not a hang.

---

## P3 — End-to-end CRUD integration test for `/projects`

**Goal:** Test the happy and unhappy paths of the projects endpoint with a real DB.

**Tasks**
1. POST `/api/v1/projects` with a valid body → 201, `Location` header, body matches input.
2. POST with empty `name` → 422 ProblemDetails with one validation error on `name`.
3. POST without bearer token → 401.
4. GET `/api/v1/projects` → returns a paged list including the created project.
5. After each test, run `Respawner` to clear all tables except migration history.

**Acceptance**
- Tests run in any order without sharing state (parallelism within the collection is OK with respawn).
- Adding a required column in a migration breaks the test until seed data is updated — proving the test exercises the real schema.
- Failing a validation rule in the handler propagates a 422 with field names.

---

## P4 — JWT helper + authorized integration test

**Goal:** A reusable helper that logs in (or mints a JWT) and returns an `Authorization` header.

**Tasks**
1. Implement `AuthHelpers.BearerAsync(client, email)` that POSTs `/auth/login` with the seeded password and returns `AuthenticationHeaderValue`.
2. Implement `AuthHelpers.MintBearer(string sub, params string[] roles)` that signs a token with the same `Jwt:SigningKey` the factory configured — useful when you don't want to exercise login.
3. Test: a non-member of a project receives 403 from `GET /projects/{id}/members`.
4. Test: an admin receives 200 from the same endpoint.
5. Test: the bearer expires (use a 1-second `AccessTokenMinutes` override) and a follow-up request is rejected 401.

**Acceptance**
- Both helpers are pure and don't share state across tests.
- The expiry test is deterministic (no `Thread.Sleep` over 2 s — use a clock service).
- All assertions use FluentAssertions for readable failures.

---

## P5 — SignalR hub integration test

**Goal:** Verify that updating a task pushes `TaskUpdated` to clients in the project group.

**Tasks**
1. Connect a `HubConnection` to `factory.Server.BaseAddress + "hubs/taskflow"` using `factory.Server.CreateHandler()`.
2. Authenticate via `AccessTokenProvider` returning the bearer from P4.
3. Subscribe to `TaskUpdated`, capture the payload into a `TaskCompletionSource<TaskDetailDto>`.
4. PATCH a task via the HTTP client; assert the SignalR client receives the update within 5 s.
5. Bonus: a non-member who calls `JoinProject` receives a `HubException("Forbidden")`.

**Acceptance**
- Test passes deterministically without sleeping.
- Two clients in the same group both receive the message; a third client outside the group does **not**.
- Cleaning up: stop the hub connection in `DisposeAsync` to avoid socket leaks.

---

## P6 — Playwright E2E plan + `auth.setup.ts`

**Goal:** A Playwright config that boots both servers and a single setup project that produces a `storageState`.

**Tasks**
1. `npm init playwright@latest` in the frontend project (Topic 7 scaffold).
2. `playwright.config.ts` with two `webServer` entries (API + Vite) and a `setup` project that produces `e2e/.auth/user.json`.
3. `auth.setup.ts` logs in once and saves storage state.
4. `e2e/projects.spec.ts` covers: create project → see it in list → open detail → delete → confirm gone.
5. `trace: 'retain-on-failure'`, `video: 'retain-on-failure'`, `retries: 2 in CI`.

**Acceptance**
- `npx playwright test` boots both servers locally, runs the spec, and produces a passing report.
- Failing the test produces a `trace.zip` viewable with `npx playwright show-trace`.
- The setup project runs exactly once per worker; subsequent tests start logged-in.
