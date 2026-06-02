# Topic 11 — Practice Problems Solutions

ASP.NET Core webapi wired with Serilog + Seq, OpenTelemetry + Jaeger + Prometheus, HybridCache + Redis, response compression, and a k6 smoke test.

## Setup

```bash
docker compose up -d        # Seq, Jaeger, Redis, Prometheus
dotnet run
```

URLs:
- API:        https://localhost:7111 / http://localhost:5111
- Swagger:    https://localhost:7111/swagger
- Prometheus scrape: http://localhost:5111/metrics
- Seq:        http://localhost:5341
- Jaeger:     http://localhost:16686
- Prometheus: http://localhost:9090

## Where to start (P1–P6)

| Problem | Files |
|---|---|
| P1 Serilog + correlation | `Program.cs` (logger bootstrap, middleware) |
| P2 OpenTelemetry traces  | `Program.cs` (`AddOpenTelemetry().WithTracing(...)`), `Telemetry/AppDiagnostics.cs` |
| P3 Custom metrics        | `Telemetry/AppDiagnostics.cs` (Counter + Histogram); add observable gauge for outbox |
| P4 HybridCache + tags    | `Controllers/ProjectStatsController.cs` |
| P5 Output cache + compression | `Program.cs` (AddOutputCache, AddResponseCompression) |
| P6 k6 perf budget        | `perf/smoke.js` — `k6 run perf/smoke.js` |

## Running k6

```bash
choco install k6                # or scoop / winget / docker
k6 run perf/smoke.js
```

A breach of `p(95)<250` or `failed<1%` exits non-zero — wired into CI in Topic 12.
