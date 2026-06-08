# Capstone — TaskFlow Enterprise Edition

> The single project that proves you can do the whole stack. Backend (.NET 8), frontend (**Angular 18**), Azure platform (Terraform + APIM + Service Bus + Redis + Front Door), CI/CD with OIDC, full security/governance baseline from Phase 10, and AI-assisted development from Phase 9.

---

## 1. Vision

Build TaskFlow as a **real product** — multi-tenant, observable, secure, deployable from PR-to-prod in under 10 minutes, runnable for under £150/month at idle, demoable to a stakeholder in 8 minutes.

You're not just shipping code; you're shipping a **platform** with the operating model, runbooks, and FinOps that go with it.

---

## 2. Scope (in)

### Product features
- **Multi-tenant**: each tenant is an isolated workspace; users belong to a tenant.
- **Auth**: Microsoft Entra ID (work/school + B2C optional); BFF pattern for the SPA.
- **Tasks**: CRUD, assignment, due dates, tags, attachments, comments.
- **Projects / boards**: kanban-style.
- **Notifications**: email + in-app via Service Bus → Function → SignalR fan-out.
- **Search**: full-text (Postgres `tsvector` or Azure AI Search; pick one).
- **Reporting**: per-tenant dashboard (counts, throughput, age distribution).
- **API**: REST + OpenAPI; rate limited; APIM front door for partners.

### Platform features
- **Hub-and-spoke** networking, central LAW, Defender enabled.
- **CI/CD**: PR validation → ephemeral preview env → staging → prod, with manual approval gate.
- **IaC**: Terraform modules; all infra reproducible; remote state in Azure Storage with state locking.
- **Observability**: Application Insights, structured logs, KQL dashboards, SLO burn alerts.
- **Cost guardrails**: budgets per env, daily export, anomaly alerts.
- **Security**: Key Vault, managed identities everywhere, Defender plans, policy compliance > 95%.

## 3. Scope (out)

- No payment processing.
- No mobile app (responsive web only).
- No on-prem connectivity (skip ExpressRoute / VPN).
- No multi-region active-active (single-region with DR plan documented).

---

## 4. Definition of Done

A checkbox for each — the capstone is **done** when every box is ticked.

### Code
- [ ] Backend: .NET 8 Minimal API or Controllers, layered (API / Application / Domain / Infrastructure).
- [ ] EF Core with migrations checked in; idempotent migration script for prod.
- [ ] Repository / Unit-of-Work pattern OR explicit DbContext usage with justification ADR.
- [ ] Validation via FluentValidation; problem-details (RFC 7807) error responses.
- [ ] Frontend: Angular 18, standalone components, signals, lazy-loaded feature modules.
- [ ] NgRx (or Signal Store) for non-trivial state; reactive forms for input.
- [ ] HTTP interceptors for auth + correlation ID + retry-with-jitter.
- [ ] Unit tests: backend ≥ 60% coverage on Application layer; frontend ≥ 50% on services.
- [ ] One end-to-end test (Playwright) covering "create task → see it in board".

### Infrastructure
- [ ] Terraform modules: network (hub-spoke), data (SQL/Postgres + Redis), app (App Service or Container Apps), APIM, observability (LAW + AI), security (KV + MI + RBAC).
- [ ] Remote state with state locking; per-env workspaces or directories.
- [ ] `terraform plan` clean on `main` (no drift).
- [ ] Cost estimate per env documented; budget alerts wired.

### CI/CD
- [ ] PR validation: lint + build + test + Terraform plan + Trivy/Checkov scan.
- [ ] Preview env deployed per PR (App Service slot or Container App revision); torn down on close.
- [ ] Staging deploy on `main` push; smoke tests run.
- [ ] Prod deploy on tag or manual dispatch with approval gate.
- [ ] OIDC federation; **zero client secrets** in pipelines.
- [ ] All Actions SHA-pinned.

### Security & governance
- [ ] Resources placed under correct MG; required tags present.
- [ ] At least 5 Azure Policy assignments enforcing baseline (locations, tags, public-IP, KV firewall, diag settings).
- [ ] Defender for Cloud plans enabled where the workload runs.
- [ ] KQL workbook covering: security alerts, top costs, request latency, SLO burn.
- [ ] One incident dry-run documented (e.g., key rotation, dependency outage).

### AI & DX
- [ ] `copilot-instructions.md` at repo root + one specialised `.instructions.md`.
- [ ] One Copilot **prompt** file used for a real chore (e.g., bumping API version).
- [ ] Optional: one Copilot **chat mode** or **agent** for repo-specific workflow.

### Documentation
- [ ] Repo `README.md` with quickstart, architecture diagram, link to runbook.
- [ ] `docs/architecture.md` with C4 (System Context + Container + Component for one service).
- [ ] `docs/adr/` with ≥ 8 Architecture Decision Records.
- [ ] `docs/runbook.md` covering: deploy, rollback, common alerts, on-call playbook.
- [ ] `docs/cost.md` with current monthly estimate + optimisation backlog.
- [ ] 8-minute demo video script (`docs/demo-script.md`).

---

## 5. Success Criteria (objective)

| Metric | Target |
|---|---|
| `main`-to-prod time (manual approval included) | < 30 min |
| Test pass rate on `main` | 100% (last 30 days) |
| P95 API latency (read endpoints) | < 300 ms |
| Cold start of preview env | < 10 min |
| Idle cost per env (dev) | < £40 / month |
| Defender Secure Score (workload sub) | ≥ 70% |
| Policy compliance (workload sub) | ≥ 95% |
| Bundle size (initial Angular load, gzipped) | < 250 KB |
| Lighthouse Performance / A11y / Best Practices / SEO | each ≥ 90 |

---

## 6. How the Capstone Maps to Phases

| Phase | Where it shows up |
|---|---|
| 1 C# fundamentals | Backend code quality, immutability, pattern matching |
| 2 DSA | Search ranking; pagination cursors; throttling algorithms |
| 3 Angular | Whole frontend |
| 4 React | Skipped (Angular chosen) — could be done as alt track |
| 5 .NET Core | Whole backend |
| 6 Full-stack integration | Auth flow, OpenAPI, contract testing, BFF |
| 7 Azure | All resources |
| 8 DevOps / CI/CD / IaC | Pipelines, Terraform, preview envs |
| 9 AI tooling | Copilot instructions, prompts, chat modes |
| 10 Security & governance | Identity, policy, secrets, multi-sub posture |

---

## 7. Folder Index

- [01-Requirements-and-Architecture.md](./01-Requirements-and-Architecture.md) — user stories, NFRs, C4, ADR template.
- [02-Build-Plan.md](./02-Build-Plan.md) — M1–M8 milestones with task lists.
- [03-Rubric.md](./03-Rubric.md) — 200-point grading rubric.
- [04-Submission-Checklist.md](./04-Submission-Checklist.md) — what you must hand in.
- [starter/](./starter/) — empty repo layout to fork from.

Start with [01-Requirements-and-Architecture.md](./01-Requirements-and-Architecture.md).
