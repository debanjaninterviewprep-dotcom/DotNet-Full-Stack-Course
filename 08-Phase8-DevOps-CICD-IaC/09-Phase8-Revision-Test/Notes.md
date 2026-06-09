# Topic 9: Phase 8 Revision Test

## About This Test

A **comprehensive revision test** covering all 8 topics of Phase 8: DevOps, CI/CD & Infrastructure as Code. Designed to confirm you can design a repo, ship code through a pipeline, provision infra with Terraform, deploy safely, and operate the result.

**Rules:**
- Solve every problem without re-reading earlier notes.
- Target time: 4–5 hours.
- Production-quality code. OIDC, not secrets. Pinned versions.
- After finishing, tell me **"check"** for a graded review.

---

## Section A: Quick-Fire Concepts (12 questions)

Answer each in 1–3 sentences. Write into `Section-A.md`.

1. Difference between **CI**, **Continuous Delivery**, and **Continuous Deployment**.
2. Why pin GitHub Actions by **SHA** rather than tag?
3. What does the **`permissions:`** block at workflow root do? What's the minimum for OIDC?
4. **OIDC federation** — explain in one sentence why it's safer than a service principal secret.
5. Why prefer **`for_each`** over **`count`** in Terraform?
6. What does a `moved {}` block do?
7. Difference between **blue-green** and **canary** deployments.
8. Define **liveness** vs **readiness** probes; which one App Service uses for slot warm-up.
9. Why is **expand/contract** the right pattern for backwards-compatible schema changes?
10. What's a **structured log message** and why does it matter for KQL?
11. Define **SLO**, **SLI**, **error budget** in one sentence each.
12. What does **`terraform state mv`** do, and when would you use it?

---

## Section B: Architecture & Diagrams (3 questions)

Use Mermaid. Write into `Section-B.md`.

### B1 — End-to-end DevOps flow
Draw the complete flow for a code change reaching production: developer → repo → CI → artifact → CD → environments → monitoring → alert → rollback. Annotate every arrow with the **identity used** and **gate**.

### B2 — Module / state topology
Draw the recommended Terraform layout for TaskFlow across `dev`, `staging`, `prod`:
- Module structure under `modules/`.
- Per-environment root configs under `envs/`.
- Remote state backend (storage account, container, key paths).
Highlight the **blast radius** of each state file.

### B3 — Deploy strategy decision tree (200 words)
A change request comes in: "Add a new `/api/recommendations` endpoint that calls a new ML service." Walk through your decision:
- Strategy chosen (blue-green / canary / rolling / flag) and why.
- Schema impact.
- Observability you'll add **before** deploying.
- Rollback procedure.

---

## Section C: Code Reading (4 questions)

For each snippet, identify the bug(s) and write a corrected version. Save as `Section-C.md`.

### C1.
```yaml
on:
  push: { branches: [main] }
  pull_request: {}

permissions: write-all

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@main
        with: { dotnet-version: '8.0.x' }
      - run: dotnet test
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZ_CREDS }}
      - run: az webapp restart -g rg-taskflow-prod -n app-taskflow-prod
```

### C2.
```hcl
resource "azurerm_storage_account" "sa" {
  name                     = "tfstateprod"
  resource_group_name      = "rg-tfstate"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  allow_blob_public_access = true
}

terraform {
  backend "azurerm" {
    storage_account_name = "tfstateprod"
    container_name       = "tfstate"
    key                  = "${var.environment}.tfstate"
  }
}
```

### C3.
```csharp
_logger.LogError("Charge failed: customer=" + customerId + " amount=$" + amount + " err=" + ex.Message);
throw ex;
```

### C4. (KQL alert)
```kql
requests
| where timestamp > ago(5m)
| summarize cnt = count()
| where cnt < 10
```
(The intent was: alert if request count drops below 10/min. Does the query do that? If not, fix it.)

---

## Section D: Hands-On Build (Pick 2 of 3)

Build two of these end-to-end. Code in `Section-D/`.

### D1 — Full CI/CD for a .NET API

Build:
- A GitHub repo containing a small .NET 8 API.
- CI workflow: build, test, coverage gate (≥ 70%), code scan.
- CD workflow: dev → staging → prod (slot swap), gated by GH environment.
- OIDC federation, no secrets.
- Branch protection JSON checked into `branch-protection.json`.

Demonstrate one full deploy, then a one-command rollback.

### D2 — Terraform Module + Per-Env State

Build:
- A `web-app` module taking RG, plan SKU, app settings.
- `envs/dev` and `envs/prod` root configs using it.
- Bootstrap script for remote state in Azure Storage.
- A `tasks.ps1` with `plan`/`apply` per env.
- A GH Actions pipeline that PR-comments the `terraform plan` diff and applies on merge.

Demonstrate: PR with plan comment; merge → apply.

### D3 — Observability Stack with Alerts

Build:
- App Insights wired via OpenTelemetry to an ASP.NET Core API.
- 3 KQL alerts (5xx rate, p95 latency, dependency failures).
- Action Group → Teams webhook.
- One Workbook for deploy investigation (parameterised on environment + time).
- One runbook per alert.

Demonstrate: force a 5xx spike (e.g., return 500 from one endpoint under load) and capture the alert + on-call response.

---

## Section E: Cost, Performance, Risk (3 questions)

Save as `Section-E.md`.

### E1 — Cost
A team runs 2,000 GH Actions CI runs / month, average 12 min on `ubuntu-latest`. Compute the monthly **billable minutes** and the bill at $0.008/min. Then propose a path to cut to ≤ $50/month with concrete changes (cache, parallelism, runner choice, path filters).

### E2 — Pipeline performance
A test stage takes 7 min. After analysis: 60% spent on Selenium UI tests, 30% on integration tests against real Postgres, 10% on unit tests. Propose three targeted optimisations with the estimated wall-time saving for each.

### E3 — Risk
You're about to ship a change that adds a column to a high-traffic table, used by the API and by a background worker. Walk through the **deploy order**, the **rollback plan**, and the **monitoring** you'd watch.

---

## Section F: Security & Governance Audit (2 questions)

### F1 — Mark Pass / Fail / Needs work + 1-sentence reason

Save as `Section-F.md`.

- [ ] All GH Actions pinned by SHA.
- [ ] Workflow-level `permissions: contents: read` default; jobs add what they need.
- [ ] Branch protection on `main`: required PR, 2 approvals, signed commits, dismiss stale reviews, applied to admins.
- [ ] OIDC federation; no `AZURE_CREDENTIALS` JSON secret.
- [ ] Federation subject pinned to environment / branch, not `pull_request`.
- [ ] Terraform state in private Azure Storage with `allow_shared_key_access = false`.
- [ ] State file backed up by versioning + soft delete.
- [ ] Production deploy requires manual approval via GH Environment.
- [ ] App Insights connection string in Key Vault, not in source.
- [ ] Diagnostic Settings on every Azure resource forward to a Log Analytics workspace.
- [ ] Daily LA cap configured per environment.

### F2 — Pick the **three most dangerous** failures from F1 and write a remediation plan (steps + commands).

---

## Submission

Tell me **"check"** when finished. I will:
- Score each section 0–10 with detailed feedback.
- Identify weakest areas to revisit before Phase 9.

Total: **100**. Passing: **70**.
