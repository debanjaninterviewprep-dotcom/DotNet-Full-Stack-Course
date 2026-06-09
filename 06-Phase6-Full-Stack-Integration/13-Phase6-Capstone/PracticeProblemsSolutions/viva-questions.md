# Viva Questions — Model Answers

Concise answers. Practice saying these aloud, not reading them.

## Architecture (T1)

**1. Why Clean Architecture?** Domain has zero dependencies; Application orchestrates use cases via MediatR; Infrastructure plugs in EF/SignalR/Storage; Api is thin. Rule: dependencies point inward. Lets us swap SQL→Postgres, Redis→Memcached, MailKit→SendGrid without touching Domain.

**2. Walk through ADR-0001.** Chose modular monolith over microservices for v1 — same DDD boundaries, deferred operational cost. Alternatives: microservices (premature, no team for it), N-tier (couples layers).

**3. STRIDE on token theft?** Spoofing risk on access token → mitigated by HS256 sig + 15-min TTL + audience claim. Refresh token kept HttpOnly Secure SameSite=Strict at `/auth`, rotated on every use, family revoked on reuse detection.

## Database & EF (T2)

**4. Project–task delete?** Cascade. Deleting a project should remove its tasks; configured in `OnModelCreating` via `OnDelete(DeleteBehavior.Cascade)`.

**5. Why `AsSplitQuery()` on project-with-tasks?** A single LEFT JOIN exploded rows by `task_count`. SplitQuery issues two queries → linear time, smaller payload.

**6. Live-safe migration?** Expand: add nullable column, deploy code that writes it. Backfill: job populates existing rows. Contract: deploy code that reads it; later migration sets NOT NULL + drops old.

## API Foundation (T3)

**7. API versioning?** Url-segment via `Asp.Versioning.Mvc`: `/api/v1/...`. v1 client to v2 endpoint → `405` if route doesn't match v1; `415` only if media-type-versioning is used.

**8. ProblemDetails vs custom envelope?** RFC 7807 `application/problem+json` is standard, queryable, machine-readable; custom envelopes diverge per team. We use ProblemDetails everywhere except 200/201/204.

**9. Health probes split?** `/health/live` → process up only. `/health/ready` → DB + Redis reachable. `/health/startup` → migrations applied. K8s uses live to restart, ready to drain traffic, startup to extend grace period.

## CRUD & Validation (T4)

**10. Optimistic concurrency?** Server returns `ETag: W/"<rowversion>"`. Client sends `If-Match` on update. Mismatch → `412 Precondition Failed`. Missing `If-Match` on update → `428 Precondition Required`.

**11. Offset vs keyset?** Offset for "page 5" UI; cheap to implement, slow at deep offsets. Keyset (`cursor=<id>+<created>`) for infinite scroll and feeds; constant-time regardless of position. Both supported.

**12. Patch?** JSON Patch (RFC 6902). It's an ordered op list (`add/remove/replace`) — surgical, idempotent with `Idempotency-Key`. Merge Patch loses history of intent and can't express array element removal.

## Auth (T5)

**13. HS256 vs RS256?** HS256 (shared secret) for monolith — one issuer, simpler ops. RS256 needed when third parties verify without owning the secret. Rotation: dual-key window (`kid` claim) so both old and new validate during rollout.

**14. Refresh-token family?** Each refresh chains to a parent; reuse of an already-rotated token reveals theft → revoke entire family + force re-login. SHA-256 hashed at rest.

**15. Cookie at `Path=/auth`?** Limits where the cookie is sent — XSS on a non-`/auth` page can't exfiltrate it via fetch to elsewhere. CSRF mitigated by `SameSite=Strict` + double-submit on the refresh endpoint.

## Frontend bootstrap (T6)

**16. `noUncheckedIndexedAccess`?** Forces `arr[0]` to be `T | undefined`. Catches "boom on empty list" bugs at compile time. `exactOptionalPropertyTypes` distinguishes `{ x?: T }` from `{ x: T | undefined }` — prevents accidentally writing `undefined` where the property must be omitted.

**17. FOUC-free theme?** Inline `<script>` in `index.html` reads `localStorage.theme` and sets `data-theme` on `<html>` BEFORE React mounts. CSS variables resolve immediately — no flash.

## Frontend integration (T7)

**18. Two parallel 401s?** ONE refresh fires. Interceptor stores the in-flight `Promise<refresh>` in a module-level `refreshing` variable; concurrent 401s `await refreshing` instead of starting their own. After it resolves, all retry with the new token.

**19. `staleTime: 30s`?** Prevents needless refetch on remount within 30s — fast tab switching feels instant. Wrong default for highly volatile data (live counters); use `staleTime: 0` there.

**20. MSW tests vs dev?** Tests: `setupServer()` in Node, `onUnhandledRequest: 'error'` so missing handlers fail loudly. Dev: `setupWorker()` in browser, `onUnhandledRequest: 'bypass'` so real backend still works for endpoints not mocked.

## SignalR (T8)

**21. Why Redis backplane?** Without it, hub instance A doesn't see messages from instance B → broadcasts only reach connections on the same pod. Backplane forwards via Redis pub/sub.

**22. JWT for hubs via query string?** WebSocket clients can't set headers on the upgrade request. Bearer handler's `OnMessageReceived` reads `?access_token=` only when path starts with `/hubs`.

**23. Scoped broadcast?** `Clients.Group($"project:{projectId}")` after the hub adds the user to that group on `JoinProject`. Avoids spamming everyone, cuts backplane traffic.

## Uploads/Jobs/Email (T9)

**24. MultipartReader vs IFormFile?** `IFormFile` buffers to memory or disk via model binding — fine ≤ a few MB. `MultipartReader` streams sections to your code; you decide where each part goes. Required for 50 MB+ uploads to avoid memory pressure.

**25. Hangfire dashboard guard?** It exposes job DDL, retry buttons, full job arguments. Wide open = remote code execution + PII leak. Filter requires `AdminOnly` policy.

**26. Daily digest survives restart?** Stored in Hangfire's persistent storage (SQL in prod). On startup, the scheduler picks up jobs whose next-fire time has passed and runs them. Cron expression is the source of truth.

## Testing (T10)

**27. SQLite-in-memory vs Testcontainers?** SQLite-in-memory: fast, zero-infra unit tests; same EF SQL providers as production for most queries. Testcontainers MsSql: real SQL Server for features SQLite can't fake — JSON columns, computed columns, full-text. Both, layered.

**28. SignalR test pattern?** Spin up `WebApplicationFactory.Server.CreateHandler()`. Connect a `HubConnection`. Register handler with `TaskCompletionSource<T>`; trigger event; `await tcs.Task.WaitAsync(timeout)`. Run `[Theory]` 50× to detect flakes.

**29. `public partial class Program {}`?** `Program.cs` with top-level statements compiles `Program` as `internal`. `WebApplicationFactory<Program>` needs it `public` to reference. The partial declaration in the test project widens visibility without touching production code.

## Observability (T11)

**30. CorrelationId lifecycle?** Born in middleware: read from `X-Correlation-Id` header or generate. Pushed into `LogContext` so every Serilog event carries it. Echoed back in response. Forwarded into Hangfire jobs as a job arg → re-pushed there. Trace stitches everything end-to-end.

**31. IMemoryCache wrong for stats?** Per-pod state. With 3 pods, user A's write to pod 1 doesn't invalidate the cache on pods 2 and 3 → stale stats for ⅔ of requests. HybridCache uses Redis as the shared layer + a small per-pod L1 for speed.

**32. Perf budget?** Numeric upper bounds on latency / bundle size / coverage. CI fails when violated. Tools: k6 thresholds, size-limit, Lighthouse CI assertions. Catches regressions at PR time, not in production.

## CI/CD (T12)

**33. `MigrateAsync()` on app start?** Multi-pod race — N pods try to apply the same DDL simultaneously; deadlocks or duplicate migrations. Long-running DDL blocks readiness probe → all pods restart. Replaced by `dotnet ef migrations bundle` as a pre-deploy job.

**34. Slot swap?** Deploy to staging slot; smoke `/health/ready`; on success, `az webapp deployment slot swap` swaps DNS in ~30s. Failed post-swap smoke → swap back. Zero downtime if app handles in-flight requests gracefully.

**35. Jwt:SigningKey at runtime?** App Service config has `Jwt:SigningKey = @Microsoft.KeyVault(SecretUri=...)`. Managed identity authenticates to Key Vault. Standard `IConfiguration["Jwt:SigningKey"]` resolves it — no SDK in the app.
