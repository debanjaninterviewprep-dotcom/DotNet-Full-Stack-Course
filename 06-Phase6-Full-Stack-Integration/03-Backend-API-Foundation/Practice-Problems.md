# Topic 3 — Practice Problems

> Build the **TaskFlow.Api** foundation. Solutions live in `PracticeProblemsSolutions/` (an actual ASP.NET Core 9 project — not a console app).

**Concept tags:** `clean-architecture` `di` `options-pattern` `serilog` `swagger` `health-checks` `mediatr` `problem-details`

**Setup**

```powershell
cd 06-Phase6-Full-Stack-Integration\03-Backend-API-Foundation\PracticeProblemsSolutions
dotnet run
```

Browse `https://localhost:7100/swagger` once the foundation pieces are wired.

---

## P1 — Scaffold the Clean Architecture Solution  *(Easy)*

**Tags:** `solution-layout` `dotnet-cli`

### Requirements

Inside `PracticeProblemsSolutions/` build a multi-project layout:

```
PracticeProblemsSolutions/
  PracticeProblems.sln
  src/
    TaskFlow.Domain/
    TaskFlow.Application/
    TaskFlow.Infrastructure/
    TaskFlow.Api/
  tests/
    TaskFlow.UnitTests/
```

Commands to use:

```powershell
dotnet new sln -n PracticeProblems
dotnet new classlib -n TaskFlow.Domain -o src/TaskFlow.Domain
dotnet new classlib -n TaskFlow.Application -o src/TaskFlow.Application
dotnet new classlib -n TaskFlow.Infrastructure -o src/TaskFlow.Infrastructure
dotnet new webapi -n TaskFlow.Api -o src/TaskFlow.Api --use-controllers
dotnet new xunit -n TaskFlow.UnitTests -o tests/TaskFlow.UnitTests
# add references per the dependency rule
dotnet add src/TaskFlow.Application reference src/TaskFlow.Domain
dotnet add src/TaskFlow.Infrastructure reference src/TaskFlow.Application
dotnet add src/TaskFlow.Api reference src/TaskFlow.Application src/TaskFlow.Infrastructure
dotnet sln add (Get-ChildItem -r -Filter *.csproj).FullName
```

### Look-fors

- [ ] `dotnet build` succeeds.
- [ ] Domain has **zero** package references.
- [ ] Api can resolve `Application` and `Infrastructure` types but Domain cannot reference any of them.

---

## P2 — Strongly-typed `JwtOptions` with Validation  *(Easy)*

**Tags:** `options-pattern` `validation` `validateonstart`

### Requirements

In `TaskFlow.Api`:

- Create `JwtOptions` (Issuer, Audience, AccessTokenMinutes, RefreshTokenDays, SigningKey).
- Decorate with DataAnnotations (`Required`, `Range`, `MinLength(32)`).
- Bind from configuration with `ValidateDataAnnotations().ValidateOnStart()`.
- Inject `IOptions<JwtOptions>` into a sample `JwtDebugController` that returns the issuer + audience (mask the key).
- Provide a sample `appsettings.Development.json` snippet.
- Demonstrate failing startup when `SigningKey` is < 32 chars.

### Look-fors

- [ ] App refuses to start with bad config (screenshot of the boot error).
- [ ] No reading of raw `IConfiguration["Jwt:Issuer"]` anywhere.
- [ ] Signing key is read from User Secrets, not committed.

---

## P3 — `AddApplication` and `AddInfrastructure` Extensions  *(Medium)*

**Tags:** `di` `extension-methods` `mediatr` `automapper` `fluentvalidation`

### Requirements

Move all service registrations out of `Program.cs` into:

- `TaskFlow.Application/DependencyInjection.cs::AddTaskFlowApplication`
  - Registers MediatR, FluentValidation, AutoMapper from the assembly.
  - Registers a `ValidationBehavior<,>` pipeline behavior.
- `TaskFlow.Infrastructure/DependencyInjection.cs::AddTaskFlowInfrastructure`
  - Registers `DbContext` (SQLite default), email sender (console in Dev, SendGrid in Prod), file storage abstraction.
- `TaskFlow.Api/DependencyInjection.cs::AddTaskFlowApi`
  - Registers controllers, swagger, CORS, problem details, JWT bearer, options validation.

`Program.cs` after this should be **≤ 25 lines**.

### Look-fors

- [ ] Each extension method takes `IServiceCollection` (and `IConfiguration` if needed) and returns `IServiceCollection` for chaining.
- [ ] No layer reaches across — Application has no `using TaskFlow.Infrastructure`.
- [ ] `Program.cs` reads naturally top-to-bottom.

---

## P4 — Serilog + Correlation ID Middleware  *(Medium)*

**Tags:** `serilog` `structured-logging` `correlation-id`

### Requirements

- Configure Serilog from `appsettings.json` (`Serilog` section): JSON console sink + an enriched property `Service: TaskFlow.Api`.
- Replace `app.UseSerilogRequestLogging()` defaults so log entries include `RequestPath`, `StatusCode`, `Elapsed`, `TraceId`.
- Write a custom middleware that:
  - Reads `X-Correlation-Id` header or generates a UUID.
  - Pushes `TraceId` to `Serilog.Context.LogContext`.
  - Sets the response header to the same id.
- Verify by hitting two endpoints with the same id and seeing both logs share `TraceId`.

### Look-fors

- [ ] Logs are valid JSON lines.
- [ ] `TraceId` propagates through controller → handler → repository logs.
- [ ] PII (e.g. password) is **not** in any log line.

---

## P5 — Swagger with JWT Bearer + XML Comments  *(Medium)*

**Tags:** `swagger` `openapi` `jwt`

### Requirements

- Enable XML doc generation in `TaskFlow.Api.csproj`.
- Configure `AddSwaggerGen` to:
  - Include the generated XML file.
  - Define a `Bearer` security scheme (`http`, `bearer`, `JWT`).
  - Apply it as a global security requirement.
  - Group endpoints by API version.
- Add **at least one** controller with XML doc comments on the controller and on every action method, including a `<response>` for each documented status.
- Visually verify the "Authorize" button works (paste a JWT, gets attached as `Authorization: Bearer ...`).

### Look-fors

- [ ] No `CS1591` warnings (or explicitly suppressed in csproj).
- [ ] Swagger UI shows lock icons on protected endpoints.
- [ ] Response codes 200/400/401/403/404 documented for each action.

---

## P6 — Health Checks: DB + Self + Custom Redis Ping  *(Hard)*

**Tags:** `health-checks` `redis` `liveness` `readiness`

### Requirements

- Register `AddHealthChecks` with three checks:
  - `db` — `AddDbContextCheck<TaskFlowDbContext>` tagged `ready`.
  - `self` — always healthy, tagged `live`.
  - `redis` — implement a custom `IHealthCheck` that PINGs Redis with a 1 s timeout, tagged `ready`.
- Map three endpoints:
  - `/health/live` — only `live`-tagged checks.
  - `/health/ready` — only `ready`-tagged checks.
  - `/health` — everything, response in JSON with each check's name + status + duration.
- Demonstrate readiness flips to **Unhealthy** when Redis is stopped.

### Look-fors

- [ ] Custom Redis check times out cleanly (no hung 30 s requests).
- [ ] JSON response is structured and parsable.
- [ ] Liveness stays Healthy even if dependencies are down — that's the contract.

---

## Self-Review Checklist

- [ ] Every package version matches across projects (no version drift).
- [ ] Solution builds with **zero** warnings.
- [ ] You can draw the dependency rule diagram from memory.
- [ ] You can list the 7 default middlewares in pipeline order.
- [ ] You wrote at least one custom middleware and one custom health check.
- [ ] Swagger is browseable, JWT-aware, and XML-commented.
