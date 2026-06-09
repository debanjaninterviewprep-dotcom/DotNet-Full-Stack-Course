# 5-Minute Demo Script (with talking points)

| Time | Action | Talking point |
|---|---|---|
| 0:00 | Open two tabs at `http://localhost:5173` | "Web served by nginx in a 28 MB image" |
| 0:15 | Sign up Tab A; show welcome email in Mailpit | "Welcome email is a Hangfire job — survives restarts" |
| 0:45 | Log in; DevTools shows no token in storage; only refresh cookie at `/auth` HttpOnly | "Access token in memory, refresh in Path-scoped HttpOnly cookie — XSS resistant" |
| 1:15 | Create project "Demo Sprint" | "DTO + FluentValidation; ETag returned for next write" |
| 1:35 | Tab B — different invited user opens the project | "RBAC policy `ProjectMember` enforced server-side" |
| 2:00 | Tab A creates task "Wire deployment"; Tab B updates live | "SignalR with Redis backplane — works across pods" |
| 2:30 | Drag a 1 MB PDF; toast: scanning → ready | "MultipartReader streams to disk; Hangfire queues scan + thumbnail" |
| 3:00 | DevTools — two parallel 401s → ONE refresh, then retries | "Shared in-flight refresh promise; not retried for /auth/* paths" |
| 3:30 | Open `http://localhost:5111/metrics`, then a Jaeger trace | "Custom Meter + ActivitySource; OTLP exporter to Jaeger" |
| 4:00 | Show k6 result: p95 = 180 ms, 0 errors | "Budget enforced in CI; regressing 50 ms fails the build" |
| 4:20 | GitHub Actions: 3 jobs green, 8 min | "Concurrency cancels superseded runs; cache-mounted restore" |
| 4:40 | Show last slot swap in Azure portal + rollback command | "Bad swap reverses in 30 s with one CLI call" |
| 5:00 | Wrap | "Questions?" |

## Pre-flight (run 30 min before demo)

```powershell
cd <repo-root>
docker compose down -v
docker compose up -d
# wait until all containers healthy
Start-Process "http://localhost:5173"
Start-Process "http://localhost:8025"   # Mailpit
Start-Process "http://localhost:16686"  # Jaeger
Start-Process "http://localhost:5111/metrics"
```

If any URL doesn't respond, do not start the demo — fix first.
