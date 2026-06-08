# TaskFlow — Copilot Instructions

You are helping build **TaskFlow**, a multi-tenant task-management platform on .NET 8 + Angular 18 + Azure.

## Stack
- Backend: .NET 8, EF Core (SQL Server), FluentValidation, Serilog, xUnit.
- Frontend: Angular 18 standalone components, signals, NgRx or Signal Store for non-trivial state.
- Infra: Terraform (`hashicorp/azurerm ~> 4.0`), Container Apps, APIM, Service Bus, Redis, Key Vault, App Insights.
- CI/CD: GitHub Actions with OIDC federation (no client secrets, all Actions SHA-pinned).

## Conventions
- Backend: layered (API / Application / Domain / Infrastructure). Domain types never leak into API contracts; use DTOs.
- Errors via RFC 7807 `ProblemDetails`.
- All Azure access via Managed Identity. No connection strings in code or app settings.
- Multi-tenancy: every query is filtered by `TenantId`. EF global query filters enforced; tested.
- Logging: structured, with `correlationId` propagated from BFF → Core → worker.
- Frontend: reactive forms; HTTP interceptors for auth + correlation + retry-with-jitter.
- Tailwind for styling unless told otherwise.

## Hard rules
- Never write a secret to a file. Use Key Vault references or user-secrets locally.
- Never suggest `az login` with a username/password. OIDC or device code only.
- Never weaken JWT validation (`ValidateAudience = false`, `MapInboundClaims = true`, etc.).
- Always SHA-pin third-party GitHub Actions.
- Always include cost-of-running notes when proposing a new Azure resource.

## When asked to add a feature
1. Propose the slice (vertical: API → Domain → DB → UI).
2. Note tests to add (unit + integration; e2e if user-facing).
3. Note telemetry to add (logs, metrics, traces).
4. Note tags / policy / cost impact if infra is touched.
