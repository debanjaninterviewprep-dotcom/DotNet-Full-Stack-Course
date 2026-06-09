# Topic 10 — Practice Problems Solutions

Multi-project test scaffold. Replace the placeholders with references to your real TaskFlow API + Application projects.

## Layout

```
PracticeProblemsSolutions/
├─ TaskFlow.UnitTests/            # P1 — xUnit + FluentAssertions + NSubstitute
├─ TaskFlow.IntegrationTests/     # P2-P4 — WebApplicationFactory + Testcontainers + SignalR client
└─ frontend-tests/                # P5-P6 — Vitest + RTL + MSW + Playwright
```

## .NET tests

```bash
cd TaskFlow.UnitTests        && dotnet test
cd TaskFlow.IntegrationTests && dotnet test
```

The integration tests need Docker running — Testcontainers spins up SQL Server automatically.

## Frontend tests

```bash
cd frontend-tests
npm install
npm test                # Vitest watch
npm run test:ci         # single run + coverage
npm run e2e             # Playwright (auto-starts npm run dev)
npm run e2e:ui          # Playwright UI mode
```

`e2e/` tests assume the Topic 7 dev server is reachable at `http://localhost:5173`. Adjust `playwright.config.ts > webServer.command` to point at your real frontend project.

## Where to start (P1–P6)

| Problem | Files |
|---|---|
| P1 Validator + mapper unit tests | `TaskFlow.UnitTests/CreateProjectValidatorTests.cs` |
| P2 WebApplicationFactory + Testcontainers | `TaskFlow.IntegrationTests/TaskFlowApiFactory.cs` |
| P3 Respawn + TestAuthHandler | add `RespawnFixture.cs`; wire `TestAuthHandler.cs` in API's Testing env |
| P4 SignalR hub test | add `HubBroadcastTests.cs` using `_factory.Server.CreateHandler()` |
| P5 RTL + MSW component tests | `frontend-tests/src/...` (port from Topic 7's mock setup) |
| P6 Playwright critical journey | `frontend-tests/e2e/login.spec.ts` (extend with create-project + complete-task) |
