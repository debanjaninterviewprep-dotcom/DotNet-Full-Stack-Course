# 03 — Rubric (200 points)

> Pass: **140 / 200**. Distinction: **170 / 200**.

Self-mark first; then ask me to grade. I'll be strict on security, OIDC, observability, and docs.

---

## A. Backend (40)

| # | Criterion | Pts |
|---|---|---|
| A1 | Project layering correct (API / Application / Domain / Infrastructure); no leaks (e.g., EF types in API) | 6 |
| A2 | Domain modelled with aggregates; invariants enforced inside the aggregate | 6 |
| A3 | EF Core migrations; idempotent prod migration script | 4 |
| A4 | Validation (FluentValidation) + RFC 7807 errors | 4 |
| A5 | OpenAPI spec accurate; examples present; versioned | 4 |
| A6 | Health checks (`/healthz` liveness + `/readyz` readiness with dependency checks) | 3 |
| A7 | Structured logging with correlation IDs end-to-end | 4 |
| A8 | Unit tests ≥ 60% on Application; one integration test against a real DB (TestContainers) | 5 |
| A9 | Performance: P95 read < 300 ms on representative load | 4 |

## B. Frontend (30)

| # | Criterion | Pts |
|---|---|---|
| B1 | Angular 18, standalone, signals where appropriate | 4 |
| B2 | State: NgRx / Signal Store for non-trivial; reactive forms for input | 5 |
| B3 | HTTP interceptors: auth, correlation, retry-with-jitter, error normalisation | 4 |
| B4 | Lazy-loaded feature modules; bundle < 250 KB gz initial | 4 |
| B5 | Accessibility: WCAG 2.2 AA; Lighthouse a11y ≥ 90 | 4 |
| B6 | i18n scaffolded (even if only `en-GB`) | 2 |
| B7 | Unit tests ≥ 50% on services; one Playwright e2e | 4 |
| B8 | Tailwind/Material design system consistent; light/dark | 3 |

## C. Platform / IaC (30)

| # | Criterion | Pts |
|---|---|---|
| C1 | Terraform modules: network / data / app / observability / security | 6 |
| C2 | Remote state with state locking; per-env isolation | 4 |
| C3 | Tags enforced via locals + Azure Policy (cross-check) | 3 |
| C4 | Networking: spoke + private endpoints for SQL / KV / Storage | 5 |
| C5 | Container Apps revisions used; one preview deploy demonstrated | 4 |
| C6 | KV: MI access; rotation runbook for one secret | 4 |
| C7 | Cost estimate + budget alert per env | 4 |

## D. Integration Services (20)

| # | Criterion | Pts |
|---|---|---|
| D1 | APIM exposes partner endpoints; subscription key + JWT + rate-limit policies | 5 |
| D2 | Service Bus: domain events; consumer idempotent; DLQ alerted | 5 |
| D3 | Redis: cache-aside pattern with per-tenant key prefix; TTL strategy documented | 4 |
| D4 | Search: full-text query with relevance tuning; demo across ≥ 100 cards | 4 |
| D5 | Email + in-app notifications via worker; one e2e demonstrated | 2 |

## E. CI/CD (25)

| # | Criterion | Pts |
|---|---|---|
| E1 | OIDC federation; zero client secrets in pipelines | 5 |
| E2 | All Actions SHA-pinned | 3 |
| E3 | PR validation: lint + build + test + Terraform plan + Trivy + Checkov | 5 |
| E4 | Preview env per PR with auto-teardown | 5 |
| E5 | Staging + prod with environment-protected manual approval | 4 |
| E6 | Smoke tests run on every env; failure rolls back / blocks | 3 |

## F. Security & Governance (25)

| # | Criterion | Pts |
|---|---|---|
| F1 | Entra: app roles + group-based assignment + PIM on Owners | 5 |
| F2 | BFF + OBO + strict JWT validation (Phase 10 checklist) | 6 |
| F3 | Policy compliance ≥ 95% on workload sub | 4 |
| F4 | Defender plans on; Secure Score ≥ 70% | 4 |
| F5 | Incident dry-run documented | 3 |
| F6 | Tenant isolation: integration test proves cross-tenant read returns 404 | 3 |

## G. AI Tooling (15)

| # | Criterion | Pts |
|---|---|---|
| G1 | `copilot-instructions.md` tuned, scoped, and actually used | 4 |
| G2 | One scoped `.instructions.md` (e.g., `infra/**`) | 3 |
| G3 | One `.prompt.md` used in a real chore | 3 |
| G4 | One `.chatmode.md` **or** one agent (Phase 9 deep dive) | 5 |

## H. Documentation & Demo (15)

| # | Criterion | Pts |
|---|---|---|
| H1 | README quickstart works on a clean machine | 3 |
| H2 | C4 (Context + Container + Component for one service + Deployment) | 4 |
| H3 | ≥ 8 ADRs in Nygard format | 3 |
| H4 | Runbook with deploy, rollback, alerts, on-call | 3 |
| H5 | 8-minute demo video + script | 2 |

---

## Totals

| Section | Pts |
|---|---|
| A Backend | 40 |
| B Frontend | 30 |
| C Platform / IaC | 30 |
| D Integration | 20 |
| E CI/CD | 25 |
| F Security & Governance | 25 |
| G AI Tooling | 15 |
| H Docs & Demo | 15 |
| **Total** | **200** |

**Pass: 140 (70%)**. **Distinction: 170 (85%)**.

Move on to [04-Submission-Checklist.md](./04-Submission-Checklist.md).
