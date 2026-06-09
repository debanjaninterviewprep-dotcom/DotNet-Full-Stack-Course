# Topic 13 — Phase 6 Capstone: Submission & Revision

> **Goal**: Tie everything together. Ship a demoable, reviewable TaskFlow that exercises every topic from 1–12, plus stretch-goal challenges to push past the baseline. This topic is **docs-only** — your "code" is the integrated TaskFlow built across the previous 12 topics.

---

## 1. What "done" looks like

Phase 6 is complete when:

1. A reviewer can clone the repo and run **`docker compose up`** to get a working stack (Topic 12).
2. The 5-minute demo (Section 4) runs end-to-end without manual fix-ups.
3. CI is green on `main` — unit + integration + E2E + size-limit + k6 smoke (Topics 10–12).
4. You can answer the viva questions in Section 5 cold, without notes.
5. You've completed at least **two** of the B1–B5 stretch challenges (Section 6).

If any of those is shaky, go back and stiffen it — don't paper over with docs.

---

## 2. Acceptance checklist (functional)

| Area | Check |
|---|---|
| **Auth (T5)** | Sign up → confirm email → log in → access token rotates silently after 15 min → refresh-token reuse is detected and revokes the family |
| **Projects (T4)** | Create / list / get / patch / delete with optimistic concurrency (ETag/If-Match → 412 on stale write) |
| **Tasks (T4)** | Pagination (offset + keyset), sort whitelist enforced, JSON Patch with idempotency-key |
| **Realtime (T8)** | Two browser windows: creating a task in window A appears in window B within 500 ms; presence updates on connect/disconnect |
| **Uploads (T9)** | Attach a file ≤50 MB → it streams to disk/blob → background scan + thumbnail jobs run → user gets a "ready" notification via SignalR |
| **Email (T9)** | Welcome email on signup; daily digest at 08:00 (Cron) — visible in Mailpit locally |
| **Cache (T11)** | `/projects/{id}/stats` second hit served from HybridCache; cache-bust on task write only invalidates the affected project |
| **Observability (T11)** | Every request has a `CorrelationId`; trace visible in Jaeger spanning HTTP → EF → Redis; `/metrics` shows custom counters |

## 3. Acceptance checklist (non-functional)

| Area | Target |
|---|---|
| API p95 latency on `/projects` | < 200 ms (k6 smoke) |
| API p99 latency | < 500 ms |
| Frontend LCP | < 2.5 s on 4G |
| Initial JS bundle | < 200 KB gz |
| Per-route chunk | < 80 KB gz |
| Test coverage (API) | ≥ 70% line, ≥ 60% branch |
| Test coverage (Web) | ≥ 60% lines |
| CI duration (PR) | < 10 min |
| Image size (API) | < 200 MB |
| Image size (Web) | < 30 MB |
| Vulnerabilities | 0 critical / high in CI scan (Trivy or `dotnet list package --vulnerable`) |

---

## 4. The 5-minute demo script

Memorize this. It's what you'll show in the viva.

| Time | Action | What it proves |
|---|---|---|
| 0:00 | Open two browser tabs at `http://localhost:5173` | Web app served by nginx (T2/T12) |
| 0:15 | Sign up in Tab A — receive welcome email in Mailpit | Auth + email + Hangfire (T5/T9) |
| 0:45 | Log in; show DevTools → no `localStorage` token; refresh-cookie at `Path=/auth` HttpOnly | Token security model (T5/T7) |
| 1:15 | Create a project "Demo Sprint" → appears in list | EF + DTO + Validator (T2/T4) |
| 1:35 | Open `/projects/demo-sprint` in Tab B as a different invited user | RBAC + multi-tenancy hooks (T5/B1) |
| 2:00 | In Tab A, create a task "Wire deployment" → it appears live in Tab B | SignalR + Redis backplane (T8) |
| 2:30 | Drag-attach a 1 MB PDF — notice "scanning..." → "ready" toast | Streaming upload + Hangfire jobs (T9) |
| 3:00 | DevTools Network tab: identical 401 from access-token expiry triggers ONE silent refresh, then retry | Axios interceptor (T7) |
| 3:30 | Show `/metrics` Prometheus output, then a Jaeger trace for the upload request | Observability (T11) |
| 4:00 | Drop k6 result chart from CI: p95=180 ms, 0 errors | Perf budget (T11/T12) |
| 4:20 | Open GitHub Actions: a CI run shows 3 jobs green, 8-min total | Pipeline (T12) |
| 4:40 | `az webapp deployment slot swap` runbook + last successful deploy in production | CD + rollback (T12) |
| 5:00 | Wrap | — |

If anything in this script fails locally, fix it before the viva. The reviewer will run it on their machine.

---

## 5. Viva questions per topic

### Architecture (T1)
1. Why Clean Architecture for TaskFlow? What is in `Domain` vs `Application` vs `Infrastructure`?
2. Walk me through ADR-0001. What were the alternatives, and why did you reject them?
3. What does your STRIDE threat model say about token theft?

### Database & EF (T2)
4. How are project–task relationships modeled? Cascade or restrict on delete?
5. Why do you use `AsSplitQuery()` on the project-with-tasks load?
6. Show me a migration that's safe to run while the app is live (expand/contract).

### API Foundation (T3)
7. How is API versioning configured? What happens when a v1 client calls v2?
8. What's the difference between `ProblemDetails` and a custom error envelope?
9. How is health probing split into live/ready/startup?

### CRUD & Validation (T4)
10. Walk through the optimistic concurrency story. Which header? What status codes?
11. Why both offset and keyset pagination? When do you use each?
12. Difference between JSON Patch and Merge Patch? Which did you implement and why?

### Auth (T5)
13. Why HS256 vs RS256? How are signing keys rotated?
14. What's a refresh-token family? What happens when reuse is detected?
15. Why is the refresh cookie `Path=/auth` and not `/`?

### Frontend bootstrap (T6)
16. Why `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`? Cite a bug they prevent.
17. How is the design-token CSS layered with FOUC-free theme switching?

### Frontend integration (T7)
18. Two API requests get 401 simultaneously. How many `/auth/refresh` calls fire? Why?
19. What does `staleTime: 30s` buy you? When is it the wrong default?
20. How does MSW behave differently in tests vs the browser dev mode?

### SignalR (T8)
21. Why a Redis backplane? What breaks without it once you have 2+ pods?
22. How does the JWT bearer auth handler accept the token from `?access_token=` for hubs but not for HTTP?
23. How do you scope a broadcast to "people viewing this project" vs "everyone"?

### Uploads/Jobs/Email (T9)
24. Why `MultipartReader` instead of `IFormFile`? When does the difference matter?
25. Why is Hangfire's dashboard behind an admin-only filter? What if you exposed it?
26. How does the daily-digest job survive a pod restart?

### Testing (T10)
27. Why SQLite-in-memory for unit tests but Testcontainers MsSql for integration?
28. What's the SignalR test pattern that avoids flaky timing?
29. Why does `WebApplicationFactory<Program>` need `public partial class Program {}`?

### Observability (T11)
30. Where is `CorrelationId` born and where does it go? Trace through one request.
31. Why is `IMemoryCache` the wrong choice for project stats? What did HybridCache change?
32. What's a perf budget? What CI step enforces it?

### CI/CD (T12)
33. Why is `db.Database.MigrateAsync()` on app start dangerous? What replaced it?
34. Walk through the slot swap. What happens if the smoke test fails after the swap?
35. Where do production secrets live? Show me how the app reads `Jwt:SigningKey`.

---

## 6. Stretch challenges (B1–B5) — pick at least two

### B1 — Multi-tenancy (data isolation)

**Brief.** Add a `TenantId` to every aggregate. Resolve tenant from JWT claim or subdomain. Apply a global query filter on `DbContext.OnModelCreating` so every read is auto-scoped. Add an integration test proving cross-tenant access is impossible (returns 404, not 403, to avoid leaking existence).

**Sub-tasks**
- Tenant resolver (subdomain → claim fallback).
- `ITenantContext` injected into `DbContext`.
- Migration adding non-nullable `TenantId` with backfill in expand/contract style.
- Cypress/Playwright test: Tenant A user requests Tenant B's resource → 404.

**Acceptance.** All existing tests still pass. New cross-tenant test passes. Audit log includes `TenantId` on every entry.

---

### B2 — Full-text search

**Brief.** Add full-text search on tasks (title + description + tag list). Use SQL Server's `CONTAINS` / `FREETEXT` or Elastic. Surface a `/api/v1/search?q=...` endpoint with relevance ranking, snippets, and hit highlighting on the SPA.

**Sub-tasks**
- Decision doc: SQL FTS vs Elastic. Pick one with tradeoffs.
- Migration creating the catalog/index (or container).
- Search service with debounced UI (300 ms).
- Tests: relevance ordering, special-character escaping, empty-query handling.

**Acceptance.** Searching "deploy" returns the most relevant tasks first; UI highlights matches; p95 < 100 ms with 100k tasks indexed.

---

### B3 — Export to CSV/PDF as a background job

**Brief.** "Export tasks" produces a CSV (always) and an optional PDF report. Long-running, so it runs in Hangfire and emails a signed download link when ready.

**Sub-tasks**
- Job accepts a filter spec (same shape as the list endpoint's query).
- CSV writer that streams (not buffers) to the file storage from T9.
- PDF via QuestPDF — pageable, with project header + summary + task table.
- Email template "Your export is ready" with a 24-hour SAS URL.

**Acceptance.** Export of 100k tasks completes; memory peak < 200 MB on the worker; download link is single-use OR time-bound.

---

### B4 — Audit log viewer with diff

**Brief.** Every write produces an audit entry (who, what, before, after). Build a UI page that lists entries with filters (entity, user, date range) and renders a side-by-side JSON diff for any entry.

**Sub-tasks**
- `IAuditWriter` invoked from EF `SavingChanges` interceptor — capture only changed properties.
- API endpoint `/api/v1/audit?entityType=&entityId=&from=&to=` (admin-only policy from T5).
- React page with virtualized list + diff component (`react-diff-viewer-continued` or a custom JSON-diff).
- Redact sensitive fields (`Password`, `Token`) at write time, not render time.

**Acceptance.** Editing a project surfaces an audit entry within 1 s. Sensitive fields never appear in audit. Reviewer can answer "who changed the project description on May 12?" in under 30 s using the UI.

---

### B5 — i18n end-to-end

**Brief.** Make the app translatable. SPA via `react-i18next`, API error messages via `IStringLocalizer` with `.resx`. Detect locale from `Accept-Language`; let the user override via a profile setting.

**Sub-tasks**
- Resource files for `en`, plus one of `es` / `de` / `hi`.
- Translate UI strings, validation messages, and email templates (Topic 9 templater).
- Currency / date formatting via `Intl` API on the client.
- Pseudo-locale toggle in dev mode (`__pseudo__`) that wraps strings with markers — surfaces missing translations during review.

**Acceptance.** Switching the locale flips all UI + emails + error messages. CI step warns when a key is missing in any locale. RTL-friendly CSS (logical properties, `:dir(rtl)` rules) verified on Arabic locale if attempted.

---

## 7. Rubric

| Pillar | Weight | What earns full marks |
|---|---:|---|
| **Functional completeness** | 25% | All Section 2 items work in the demo script |
| **Non-functional targets** | 15% | All Section 3 budgets met; CI enforces them |
| **Code quality** | 20% | Clean Architecture respected; no leaky abstractions; consistent style |
| **Tests** | 15% | Pyramid balance; flake-free; meaningful assertions; coverage targets met |
| **Observability** | 10% | Logs structured + correlated; traces meaningful; dashboards exist |
| **Security** | 10% | OWASP top 10 considered; secrets in Key Vault; auth flows hardened |
| **Documentation & ADRs** | 5% | Up-to-date ADRs, runbook, demo script, viva-ready answers |

---

## 8. Submission checklist

Before you call Phase 6 done:

- [ ] `dotnet build` succeeds at the solution root.
- [ ] `dotnet test` is green; no `[Skip]` without a tracking issue.
- [ ] `npm test` and `npm run test:e2e` are green.
- [ ] `docker compose up -d` brings up a working stack within 90 s.
- [ ] CI on `main` is green; no required check is missing.
- [ ] At least one tagged release (`v1.0.0`) exists with images in GHCR.
- [ ] At least two of B1–B5 are merged into `main`.
- [ ] `README.md` at the repo root has: quick start, architecture diagram, demo script link, runbook link, ADR index.
- [ ] `CHANGELOG.md` is up to date.
- [ ] Threat model (`docs/threat-model.md`) reviewed within the last month.
- [ ] You can present the demo end-to-end without checking notes.

---

## 9. Where to revise next

After Phase 6 ships, the natural follow-ups are:

- **Phase 7 (suggested)**: Microservices — split TaskFlow into Auth, Projects, Notifications. Use Dapr or MassTransit. Adds: service discovery, distributed transactions (saga), API gateway, eventual consistency patterns.
- **Phase 8 (suggested)**: Production SRE — SLOs, error budgets, chaos engineering (Chaos Mesh / Simmy), advanced k8s deployments (HPA/VPA, PodDisruptionBudgets), cost optimization.
- **Phase 9 (suggested)**: ML/AI features — semantic search (vector DB), task auto-prioritization (small model), RAG for help system.

But finish Phase 6 first. A working production-grade monolith is more valuable than three half-built microservices.

---

## 10. Final words

You've now built a system that:
- a real team could ship to real customers,
- a real interviewer would respect,
- and a real on-call rotation could operate.

That's the bar. Defend it in the viva, then go build something bigger.
