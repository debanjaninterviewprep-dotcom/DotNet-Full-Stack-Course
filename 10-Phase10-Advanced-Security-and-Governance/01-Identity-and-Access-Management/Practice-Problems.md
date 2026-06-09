# Practice Problems — Identity & Access Management

> Tell me **"check"** after finishing.

---

## P1 — IAM Design for TaskFlow Production

**Goal:** Produce an end-to-end IAM design document for the TaskFlow prod environment.

**Tasks:** In `iam-design.md` cover:
1. Group taxonomy (name, purpose, members, standing roles).
2. Workload identities (MI per workload, scopes).
3. PIM policy table (role → cap → MFA → justification → approver).
4. Conditional Access policies (≥ 5 baseline + ≥ 2 TaskFlow-specific).
5. Break-glass account procedure.
6. Audit + alerting plan.
7. Quarterly review schedule.

**Deliverable:** `iam-design.md` (≥ 2 pages).

**Look-fors:** Standing access kept minimal; PIM has approvers for Owner-class; break-glass procedure realistic.

---

## P2 — Convert from Secrets to Managed Identity

**Goal:** Take a TaskFlow API that uses SQL with a username/password connection string and migrate it to managed identity.

**Tasks:**
1. Show the **before** `appsettings.json` and Program.cs.
2. Produce the Terraform / Bicep diff that:
   - Enables system-assigned MI on the App Service.
   - Grants the MI access on the SQL DB (T-SQL `CREATE USER FROM EXTERNAL PROVIDER`).
3. Show the **after** appsettings.json (no password) and Program.cs (passwordless connection).
4. Verify locally and in dev — capture a successful connection log line.

**Deliverable:** before/after files + IaC diff + verification log.

**Look-fors:** No connection password anywhere; MI displayName matches App Service name; least-privilege role on DB.

---

## P3 — Workload Identity Federation Setup

**Goal:** Eliminate all `AZURE_CREDENTIALS` JSON secrets from a GH Actions pipeline.

**Tasks:**
1. Bash/PowerShell script that creates: App Registration, SP, and **3 federated credentials** (one per env: dev / staging / prod) pinned to subject `repo:<org>/<repo>:environment:<env>`.
2. Update a workflow to use `azure/login@<SHA>` with OIDC (client-id, tenant-id, subscription-id as **variables**, not secrets).
3. Verify deploy to dev runs.
4. Try to deploy to prod from a PR branch — show it's rejected.

**Deliverable:** Setup script, updated workflow, screenshots of both the success and rejection.

**Look-fors:** No client secret; each env's federation subject is exact; PR → prod fails.

---

## P4 — PIM Configuration

**Goal:** Configure PIM for two roles using IaC or PowerShell.

**Tasks:**
1. `Owner` on a subscription: eligible group `g-taskflow-platform-admins`, max 4h activation, MFA required, ticket-reference required, second-approver required, notifications to security distribution list.
2. `Contributor` on a prod RG: eligible group `g-taskflow-devs`, max 8h, MFA, justification only.
3. Trigger an activation; capture the resulting audit log entry.
4. Configure a quarterly access review on the eligible groups.

**Deliverable:** PowerShell / Microsoft.Graph SDK script(s) + audit-log screenshot + access-review config screenshot.

**Look-fors:** Policy matches stated rules; activation actually requires approval; reviewer is named.

---

## P5 — Conditional Access Baseline

**Goal:** Define and (where possible, in report-only) deploy a CA baseline for TaskFlow.

**Tasks:** Build at least these 5 policies and provide JSON or Graph PowerShell:
1. Require MFA for all users (excluding break-glass accounts).
2. Block legacy authentication.
3. Require compliant device for admin portals.
4. Sign-in frequency 12h for privileged roles.
5. Block sign-ins from `Blocked Countries` named location.

**Deliverable:** Policy definitions + `rollout-plan.md` describing pilot → report-only → enforce.

**Look-fors:** Break-glass excluded; rollout is staged; you say how you'll detect false positives.

---

## P6 — Detection / Alerting with KQL

**Goal:** Author 5 KQL alerts that matter.

**Tasks:** Write the queries + alert rule sketches for:
1. Any new role assignment outside PIM.
2. Owner activation outside business hours (07:00–20:00 local).
3. Federated-credential addition or modification (supply-chain risk).
4. Service principal credential added (especially if you've gone full-MI).
5. Successful sign-in from a country never seen before for this UPN in the last 90 days.

**Deliverable:** `alerts.kql` plus a brief description of action group and runbook stub for each.

**Look-fors:** Queries actually parse against AAD audit/sign-in tables; thresholds defensible; runbooks named.

---

## P7 — App-to-App Auth Implementation

**Goal:** Service A calls Service B using OAuth client_credentials with managed identity, validated server-side.

**Tasks:**
1. Service B: an ASP.NET Core API that validates: issuer = your tenant, audience = its `api://` URI, `roles` claim contains `TaskFlow.Tasks.Read`.
2. App Registration for Service B with an exposed App Role `TaskFlow.Tasks.Read` (application permission).
3. Service A: requests a token using `DefaultAzureCredential` for scope `api://<bId>/.default`, calls B with `Bearer`.
4. Demonstrate: A → B succeeds; A's MI without the role → B returns 403.

**Deliverable:** Source for both services + screenshot of success and forbidden cases.

**Look-fors:** Token validation strict; role check enforced; no shared secret used.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 15 | Comprehensive, realistic |
| P2 | 15 | No passwords anywhere; verified |
| P3 | 15 | Federation subject precise; PR rejection demonstrated |
| P4 | 15 | Policy enforced; access review configured |
| P5 | 10 | Break-glass excluded; rollout staged |
| P6 | 15 | All 5 queries valid; runbooks named |
| P7 | 15 | Role check enforced server-side |

Total: 100. Pass: 70.
