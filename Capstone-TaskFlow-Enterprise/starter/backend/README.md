# backend/

This is where the .NET 8 solution lives.

## Expected layout

```
backend/
├── TaskFlow.sln
├── Directory.Build.props          (nullable enable, treat warnings as errors)
├── src/
│   ├── TaskFlow.Api/              (Minimal API or Controllers; HTTP only)
│   ├── TaskFlow.Application/      (use cases, validators, services)
│   ├── TaskFlow.Domain/           (aggregates, value objects, domain events)
│   └── TaskFlow.Infrastructure/   (EF Core, external clients, MI auth)
└── tests/
    ├── TaskFlow.Tests.Unit/
    └── TaskFlow.Tests.Integration/   (TestContainers SQL)
```

## Rules
- Domain layer has **zero** dependencies on Microsoft.* (other than BCL).
- Application returns Results / Errors; controllers translate to ProblemDetails.
- EF Core lives in Infrastructure; expose only repositories or use `IDbContext` abstraction.
- Multi-tenancy enforced via EF query filters on every aggregate root.
- Logging: `ILogger<T>` with structured properties; correlation ID via middleware.

See [Phase 5](../../../05-Phase5-DotNet-Core/) for the techniques; see [Build Plan M1](../../02-Build-Plan.md#m1--backend-skeleton) for the milestone.
