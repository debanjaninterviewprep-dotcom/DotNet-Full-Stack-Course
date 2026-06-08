# Practice Problems — Management Groups & Azure Policy

> Tell me **"check"** after finishing.

---

## P1 — Design the Management Group Hierarchy

**Goal:** Produce an MG design for TaskFlow that aligns with CAF landing-zone patterns.

**Tasks:** In `mg-design.md`:
1. Hierarchy diagram (Mermaid).
2. Which subscription goes where, and why.
3. Naming conventions.
4. Move policy (who can move subs between MGs and how).
5. RBAC model at MG levels (who's `Management Group Contributor` and why it's narrow).

**Deliverable:** `mg-design.md`.

**Look-fors:** Hierarchy matches CAF; reasoning explicit per level; not over-engineered.

---

## P2 — Custom Policy: Allowed Locations + Required Tags

**Goal:** Author two custom policies as Terraform.

**Tasks:**
1. Policy A: allowed locations (`northeurope`, `westeurope`) — Deny effect, exclude `global` and Entra B2C.
2. Policy B: enforce tags `owner`, `costCenter`, `environment` on RGs — Modify effect that adds defaults.
3. Bundle in an initiative `taskflow-foundation`.
4. Assign at the **Workloads** MG.
5. Demonstrate: try to create an RG without `costCenter` — see `tagged automatically`. Try to deploy a resource in `eastus` — see deny.

**Deliverable:** Terraform module + screenshots/logs of both demonstrations.

**Look-fors:** Modify uses correct role for assignment; Deny scope excludes resources that should be exempt; idempotent across re-applies.

---

## P3 — Audit-then-Deny Promotion

**Goal:** Roll out a "no public network access on Storage" policy safely.

**Tasks:**
1. Author the policy as **Audit** assigned at Workloads MG.
2. Wait 24 h (or simulate by creating resources). Capture the compliance report.
3. Triage non-compliant resources: triage spreadsheet (`triage.csv`) classifying each as **remediate / exempt / accept**.
4. Apply remediations / exemptions.
5. Re-assign as **Deny**. Demonstrate a new public storage account is blocked.

**Deliverable:** Policy definition (both versions) + triage CSV + screenshots.

**Look-fors:** Triage is honest; exemptions are time-bound with owners; promotion is logged.

---

## P4 — DeployIfNotExists for Diagnostic Settings

**Goal:** Auto-enable Diagnostic Settings forwarding to a Log Analytics workspace on every new App Service.

**Tasks:**
1. Author DINE policy as Terraform.
2. Identity: pick a managed identity for the policy assignment with the right roles (`Log Analytics Contributor` on the LAW, `Monitoring Contributor` at scope).
3. Assign at Workloads MG.
4. Create a new App Service — verify diag settings appear within a few minutes.
5. Run remediation for existing non-compliant App Services and confirm.

**Deliverable:** Terraform + verification screenshots + remediation task ID.

**Look-fors:** MI assigned with least-privilege; remediation actually runs; settings include all required log categories.

---

## P5 — Resource Locks via IaC

**Goal:** Lock prod RGs and the LAW.

**Tasks:**
1. Add `CanNotDelete` locks to: `rg-taskflow-prod`, `rg-platform-monitoring`, and the LAW resource itself.
2. Document the **removal process**: who can remove, what ticket is required.
3. Demonstrate: attempt to delete the prod RG as `Owner` — show it fails.

**Deliverable:** Terraform + `lock-removal-runbook.md` + screenshot.

**Look-fors:** Locks at right scope; runbook lists exact `az` command sequence and the ticket workflow.

---

## P6 — Policy-as-Code CI

**Goal:** A CI workflow that plans, tests, and applies policy changes.

**Tasks:**
1. GitHub Actions workflow:
   - `terraform fmt -check`, `terraform validate`.
   - `terraform plan` against the Workloads MG; comment plan on PR.
   - On merge: apply.
   - Post-apply: query `PolicyInsights` and post a 24-h delta summary as an issue.
2. Pre-commit hook (`pre-commit-config.yaml`) running `tflint` + `checkov`.

**Deliverable:** Workflow YAML + pre-commit config + screenshot of PR comment.

**Look-fors:** OIDC login (no secrets); plan comment formatted; post-apply summary actionable.

---

## P7 — Exemption Lifecycle

**Goal:** Build the process for safe, time-bound exemptions.

**Tasks:**
1. Add an exemption to one assignment with `expires_on` = today + 60 days, with full description (owner, ticket, reason).
2. Author a KQL query that lists exemptions expiring in the next 30 days.
3. Wire a scheduled workflow (or Logic App) that runs the query daily and posts to a Teams channel.
4. Author the renewal/PR workflow (template PR pre-filled).

**Deliverable:** Exemption Terraform + KQL + scheduled workflow + PR template.

**Look-fors:** No open-ended exemptions; alerting actionable; renewal path frictionless.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 10 | CAF-aligned; reasoning explicit |
| P2 | 15 | Both effects work; idempotent |
| P3 | 20 | Triage rigorous; promotion safe |
| P4 | 15 | MI least-privilege; remediation works |
| P5 | 10 | Lock applied; removal documented |
| P6 | 15 | OIDC, PR comments, post-apply summary |
| P7 | 15 | Time-bound; alerting wired |

Total: 100. Pass: 70.
