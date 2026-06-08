# 02 — Build Plan

Eight milestones. Each ends with a **demo-able** outcome and a **review checkpoint** (you tell me "check M3 done" and I'll grade against the rubric).

> Plan a realistic calendar before you start. Time-box milestones, not tasks.

---

## M1 — Backend Skeleton

**Demo:** `curl /healthz` and `/api/tasks` (empty list) against a locally-running API.

- [ ] Solution: `TaskFlow.sln` with projects `Api`, `Application`, `Domain`, `Infrastructure`, `Tests.Unit`, `Tests.Integration`.
- [ ] .NET 8 Minimal API or Controllers — your call; document in ADR.
- [ ] DI wired; settings via `IOptions<T>`; secrets via user-secrets locally.
- [ ] EF Core with SQL Server / SQLite for local; first migration: `Tenant`, `User`, `Project`, `Card`.
- [ ] `/healthz` (liveness) and `/readyz` (DB ping) endpoints.
- [ ] Structured logging via `Microsoft.Extensions.Logging` + Serilog console sink.
- [ ] `ProblemDetails` for errors; global exception handler.
- [ ] Unit tests for one Application service.

**Checkpoint:** ADR-0001..0004 written.

---

## M2 — Frontend Skeleton

**Demo:** Angular SPA loads, calls the local backend, shows an empty board.

- [ ] Angular 18 with standalone components; routing with lazy feature modules.
- [ ] Signal-based state for trivial state; NgRx or Signal Store for board state.
- [ ] HTTP service with interceptor: correlation ID, retry-with-jitter (max 3 on 5xx/429).
- [ ] Auth scaffolded (no real login yet) — placeholder user from localStorage.
- [ ] Tailwind (or Angular Material) for the design system; theme + light/dark.
- [ ] Unit tests for at least one service.
- [ ] Playwright test: opens app, sees title.

**Checkpoint:** ADR-0002 written. Lighthouse local run captured.

---

## M3 — Infrastructure-as-Code Baseline

**Demo:** `terraform apply` stands up a dev environment in your subscription.

- [ ] Remote backend (Storage account + state container) created once via bootstrap script.
- [ ] `envs/dev` invokes shared modules:
  - `modules/network` (small spoke VNet + private DNS).
  - `modules/data` (SQL or Postgres flexible server + Redis).
  - `modules/app` (Container Apps env + Core API app + revision suffix).
  - `modules/observability` (LAW + App Insights workspace-based).
  - `modules/security` (Key Vault, user-assigned MI, RBAC).
- [ ] Tags enforced via locals (`owner`, `costCenter`, `application`, `env`, `dataClassification`).
- [ ] Cost estimate snapshot (`infracost` or manual) committed to `docs/cost.md`.
- [ ] Budget + alert wired.

**Checkpoint:** ADR-0007, ADR-0008. `terraform plan` clean.

---

## M4 — Platform Services (APIM + Service Bus + Redis)

**Demo:** A partner can call `/api/tasks` via APIM (subscription key + JWT) and a `TaskCreated` event lands on Service Bus and gets logged by a worker.

- [ ] **APIM** standalone (Developer SKU) or consumption for cost.
- [ ] Product + subscription + rate-limit policy + JWT validation policy for partner endpoints.
- [ ] Diff between user-facing API (via BFF) and partner API (via APIM) documented.
- [ ] **Service Bus** namespace, queue `tasks-events`, topic `notifications` with subscriptions.
- [ ] Core API publishes events via `Azure.Messaging.ServiceBus` (no connection string — MI).
- [ ] **Container Apps Job** or **Function** worker that consumes events; idempotent.
- [ ] **Redis** as cache for hot tenant config; cache-aside pattern; per-tenant key prefix.

**Checkpoint:** ADR-0005. Hot path benchmark captured.

---

## M5 — CI/CD with OIDC

**Demo:** Open a PR → preview env spins up → reviewer clicks the URL → merge → staging deploys → tag → prod approval gate → prod deploys.

- [ ] OIDC federation: GitHub OIDC trust for `dev`, `staging`, `prod` subjects.
- [ ] Workflows:
  - `pr.yml` — lint + build + test + Terraform plan + Checkov + Trivy on container.
  - `preview.yml` — deploy to a Container App **revision** scoped to PR; comment URL on PR; tear down on close.
  - `staging.yml` — on `main` push.
  - `prod.yml` — on tag `v*.*.*`; environment-protected with manual approval.
- [ ] **All Actions SHA-pinned**.
- [ ] Smoke tests on every env: `/readyz` + one auth'd `/api/tasks` call.
- [ ] Deploy time < 20 min end-to-end.

**Checkpoint:** ADR-0009. Demo a green run on each workflow.

---

## M6 — Security & Governance

**Demo:** Show Secure Score, policy compliance %, and a runbook executed for a simulated incident.

- [ ] Entra app registration with App Roles; user assignment via groups.
- [ ] BFF using `Microsoft.Identity.Web` with **OBO** to Core API.
- [ ] Strict JWT validation on Core API (full Phase 10 Topic 3 checklist).
- [ ] Key Vault: all secrets there; MI-only access; rotation runbook for the SQL password.
- [ ] Azure Policy assignments at MG/sub: allowed locations, required tags, KV firewall on, deny public storage, DINE diag settings.
- [ ] Defender for Cloud plans on for App Service / Container Apps / SQL / KV / Storage.
- [ ] One **incident dry-run** documented (e.g., compromised partner key → rotate + audit).

**Checkpoint:** Secure Score ≥ 70%, Policy compliance ≥ 95%.

---

## M7 — AI-Assisted DX

**Demo:** A 3-minute walk-through of how Copilot saves you time on a real chore in this repo.

- [ ] `copilot-instructions.md` at repo root tuned to TaskFlow conventions.
- [ ] At least one path-scoped `.instructions.md` (e.g., `infra/**/*.tf` Terraform style).
- [ ] One `.prompt.md` for a real chore — e.g., "scaffold a new aggregate" or "bump API contract version".
- [ ] (Optional but recommended) A `.chatmode.md` for `/refactor-aggregate` or `/add-policy`.
- [ ] If you went deep into Phase 9: one **agent** that consumes the repo and produces a release note draft from merged PRs.

**Checkpoint:** Recording uploaded to `docs/demo/`.

---

## M8 — Polish, Docs, and Demo

**Demo:** The 8-minute stakeholder walk-through.

- [ ] All NFR targets met or gaps explicitly listed in `docs/known-gaps.md`.
- [ ] `docs/architecture.md` updated with final C4.
- [ ] `docs/adr/` ≥ 8 ADRs.
- [ ] `docs/runbook.md` covers deploy / rollback / common alerts / on-call playbook.
- [ ] `docs/cost.md` with current monthly figure + 3 optimisation ideas.
- [ ] `docs/demo-script.md` — exact 8-minute path with timings.
- [ ] Record the demo (Loom / OBS) and link from the root README.
- [ ] Tag `v1.0.0` and write release notes.

**Checkpoint:** Self-mark with [03-Rubric.md](./03-Rubric.md). Then ask me to grade.

---

## Suggested Sequencing

```
Week  1   2   3   4   5   6   7   8
M1    ███
M2        ███
M3            ███
M4                ███
M5                    ███
M6                        ███
M7                            ██
M8                                ██
```

(Compress if you have more focused time; don't skip checkpoints.)

Move on to [03-Rubric.md](./03-Rubric.md) for the grading bar.
