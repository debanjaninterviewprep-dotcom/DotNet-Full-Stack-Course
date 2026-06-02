# Topic 11 — Practice Problems

> Project: `PracticeProblemsSolutions/` — ASP.NET Core webapi wired with Serilog, OpenTelemetry, HybridCache, and Polly. Run `docker compose up` (Seq + Jaeger + Redis) then `dotnet run`.

---

## P1 — Serilog with destructuring policies + correlation middleware

**Goal:** Structured JSON logs to Console + Seq with `CorrelationId`, `UserId`, and `TraceId` enriched on every event; passwords/tokens redacted.

**Tasks**
1. Install `Serilog.AspNetCore`, `Serilog.Sinks.Seq`, `Serilog.Formatting.Compact`.
2. Bootstrap logger before host build; use `RenderedCompactJsonFormatter` on Console + Seq sink reading `Seq:Url` from config.
3. Destructuring: configure transforms that drop `Password`, `Token`, `Cookie`, `Authorization` from any logged object.
4. Correlation middleware: read `X-Correlation-Id`, generate one if absent, push to `LogContext`, echo back in response.
5. `UseSerilogRequestLogging` with level escalation: 5xx → Error, p99 (>1500 ms) → Warning.

**Acceptance**
- Logging an object with a `Password` field shows `*REDACTED*` (or omits the property) in Seq.
- Every request has a single log line including `CorrelationId`, `UserId`, `Elapsed`, `StatusCode`.
- Correlation id from the request header propagates into Hangfire jobs you enqueue from the request (Topic 9 integration).

---

## P2 — OpenTelemetry traces + custom `ActivitySource`

**Goal:** End-to-end distributed traces from request → DB → outbound HTTP → SignalR push, exported via OTLP to Jaeger.

**Tasks**
1. Install OpenTelemetry hosting + AspNetCore + Http + EFCore + Redis + OTLP exporter packages.
2. Configure `AddOpenTelemetry().WithTracing(...)` with all instrumentations, OTLP exporter pointing at `http://localhost:4317`.
3. Filter health checks out of traces.
4. Add a custom `ActivitySource("TaskFlow.Application")` with two manual spans: `CreateProject`, `LoadProjectStats`. Tag with `project.id`, `user.id`.
5. Configure tail-based sampling: keep 100% of error traces, 10% of success traces.

**Acceptance**
- Jaeger UI at `http://localhost:16686` shows a single trace spanning HTTP → EF → Redis.
- Custom spans appear with the right tags.
- A 500 response is always retained in traces; successful requests are sampled.

---

## P3 — Custom metrics + dashboard query

**Goal:** Three custom metrics — counter, gauge, histogram — surfaced via Prometheus endpoint.

**Tasks**
1. Define a `Meter("TaskFlow.Application")` with:
   - Counter `taskflow.projects.created.total` (tags: `result`).
   - Histogram `taskflow.handler.duration_ms` (tags: `handler.name`).
   - Observable gauge `taskflow.outbox.pending` driven by an EF query.
2. Wire `AddPrometheusExporter()` and map `/metrics`.
3. In each MediatR handler, record duration via `Activity.Current?.SetTag` AND the histogram.
4. Document a PromQL query: p95 by handler over the last 5 minutes — `histogram_quantile(0.95, sum(rate(taskflow_handler_duration_ms_bucket[5m])) by (handler_name, le))`.
5. Avoid high-cardinality tags — assert in unit test that a label set never includes a Guid.

**Acceptance**
- `curl /metrics` shows the three series with non-zero values after exercising the API.
- The unit test for "no high-cardinality tags" passes when handler name is constant; fails when a Guid leaks in.
- The PromQL query renders a sensible chart in Grafana / Prometheus UI.

---

## P4 — HybridCache for project stats + tag invalidation

**Goal:** Cache `GET /api/v1/projects/{id}/stats` in HybridCache (memory + Redis) and invalidate on task writes.

**Tasks**
1. Install `Microsoft.Extensions.Caching.Hybrid` and `Microsoft.Extensions.Caching.StackExchangeRedis`.
2. Configure HybridCache with `LocalCacheExpiration: 2 min`, `Expiration: 15 min`.
3. Wrap stats query in `cache.GetOrCreateAsync(...)` keyed by project id; tag with `project-stats` and `project:{id}`.
4. After any task create/update/delete, call `cache.RemoveByTagAsync($"project:{projectId}")`.
5. Load test: 100 concurrent first-hit requests must result in **one** DB query (stampede protection).

**Acceptance**
- Cache hit ratio after warm-up is >95% for read-heavy traffic.
- Updating a task invalidates ONLY that project's stats — other projects' caches survive.
- Load test verifies single DB hit on cold start.

---

## P5 — Output caching + response compression

**Goal:** Cache anonymous `/health/dashboard` for 30 s and compress JSON responses with Brotli + Gzip.

**Tasks**
1. Wire `AddOutputCache` with a base policy (30 s) and a named policy `Stats` (5 min, varies by query string).
2. Apply `[OutputCache(PolicyName = "Stats")]` to the stats endpoint.
3. Wire `AddResponseCompression` with Brotli + Gzip, `EnableForHttps: true`, plus SVG mime type.
4. Confirm via `curl --compressed -I` that responses come back with `Content-Encoding: br`.
5. Skip compression for already-compressed mime types (`image/jpeg`, `application/octet-stream` if blob, etc.).

**Acceptance**
- Stats response size drops by ~70% with compression enabled.
- 30-second cache window verified via second-hit timing in headers (`X-Cache-Status` if you add one).
- Brotli is preferred when the client offers both encodings.

---

## P6 — Performance budget enforced in CI (k6 + size-limit)

**Goal:** Define a perf budget and fail CI when violated.

**Tasks**
1. Add a k6 smoke script that hits `/api/v1/projects` with 50 VUs for 1 minute and asserts:
   - `http_req_duration{p(95)} < 250`
   - `http_req_failed < 0.01`
2. Run k6 in a GitHub Actions step (Topic 12 wires the workflow); fail the pipeline on threshold breach.
3. Add `size-limit` config to the frontend (Topic 7 scaffold): initial chunk < 200 KB gz, per-route < 80 KB gz.
4. Add Lighthouse CI step with `assertions: recommended` and a custom assertion `largest-contentful-paint: ["error", { maxNumericValue: 2500 }]`.
5. Output budget results to the PR as a comment via `actions/github-script` (preview only — full CI in Topic 12).

**Acceptance**
- Locally: `k6 run smoke.js` reports green thresholds.
- A deliberate regression (add `Thread.Sleep(500)` in the controller) fails the k6 step.
- A 50 KB image dropped into `src/assets` exceeds the size-limit and fails the build.
