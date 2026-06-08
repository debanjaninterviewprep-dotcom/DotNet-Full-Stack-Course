# Topic 8: Secure Governance — Practice Problems

> Five exercises focused on **policy as the enforcement plane**. You author Azure Policy initiatives, set up a small management-group hierarchy, and produce an SCP equivalent for AWS for cross-cloud literacy.

**Concept tags:** `mg-hierarchy` `policy-initiative` `dine` `scp` `conditional-access` `pim` `defender`

**Prereqs:**
- A real Entra tenant where you have Owner on at least one MG (or `Tenant Root`).
- Two subscriptions ideal; one is acceptable (treat sandbox / dev as "two").

---

## P1 — Build a Mini MG Hierarchy + Naming Initiative  *(Easy)*

**Tags:** `management-groups` `policy-initiative`

### Requirements

1. Create MGs:
   - `taskflow-root`
   - `taskflow-platform`
   - `taskflow-workloads`
   - `taskflow-sandbox`
2. Move your existing subscription under `taskflow-workloads`.
3. Create an **Initiative** "TaskFlow Naming & Tagging" with:
   - Require tag `environment` (Deny)
   - Require tag `costCenter` (Deny)
   - Require tag `owner` (Deny)
   - Append tag `workload=taskflow` if missing (Modify)
4. Assign the initiative to `taskflow-workloads` MG.

### Deliverable

`P1-mg-policy.sh` + `P1-results.md` showing `az policy state list` with current compliance.

### Look-fors

- [ ] MGs exist; subscription correctly placed.
- [ ] Initiative shows ≥ 4 policies.
- [ ] At least one resource (existing) flagged as non-compliant; one (newly created) succeeds.

---

## P2 — Storage Hardening Initiative  *(Medium)*

**Tags:** `policy` `storage` `deny`

### Requirements

Build a custom initiative "TaskFlow Storage Baseline" with these built-in policies:

| Policy | Effect |
|---|---|
| Storage accounts should disable public network access | Deny |
| Secure transfer to storage accounts should be enabled | Deny |
| Storage account TLS minimum | Deny < 1.2 |
| Storage accounts should have shared key access disabled | Deny |
| Allowed storage account SKUs | Audit (Standard_LRS / Standard_ZRS / Standard_GRS) |

Assign at `taskflow-workloads` MG. Then attempt to create a violating storage account from CLI; capture the deny message.

### Deliverable

`P2-storage-initiative.sh` + `P2-violation.md`.

### Look-fors

- [ ] Each policy assigned with explicit parameters.
- [ ] Violation message clearly identifies the offending policy.
- [ ] Compliance dashboard updated within 30 minutes.

---

## P3 — DINE: Auto-Enable Diagnostics  *(Medium)*

**Tags:** `dine` `remediation` `log-analytics`

### Requirements

1. Create a Log Analytics workspace `log-taskflow-shared`.
2. Use the built-in DINE policy *"Configure diagnostic settings for storage account to Log Analytics workspace"* (or App Service equivalent).
3. Assign with the workspace ID.
4. **Trigger remediation** for existing non-compliant resources: `az policy remediation create`.
5. After remediation runs, verify diag settings appear on each storage account.

### Deliverable

`P3-dine.sh` + `P3-remediation.md`.

### Look-fors

- [ ] Policy assignment includes a system-assigned MI with Log Analytics Contributor on the workspace.
- [ ] Remediation task completed on existing resources.
- [ ] New storage account auto-gets diag settings.

---

## P4 — AWS SCP Equivalent (Document Only)  *(Medium)*

**Tags:** `scp` `aws-organizations` `cross-cloud`

### Requirements

Author **three AWS SCPs** that mirror the Azure controls from P1 + P2:

1. `deny-region.json` — deny everything outside `us-east-1` / `eu-west-1`.
2. `require-tags.json` — deny `RunInstances` / `CreateBucket` without tags `environment` and `costCenter`.
3. `deny-public-s3.json` — deny `PutBucketPublicAccessBlock` that disables block-public-access.

For each: 2-paragraph commentary on what's harder/easier than its Azure twin.

### Deliverable

`P4-scps/` with the three JSON files + `commentary.md`.

### Look-fors

- [ ] SCPs use `Deny` (SCPs only deny — that's the model).
- [ ] Commentary mentions key differences (Azure has Modify/Append, SCPs don't).
- [ ] Tags on `RunInstances` / `CreateBucket` use proper condition keys.

---

## P5 — Identity Governance: Conditional Access + PIM Plan  *(Hard)*

**Tags:** `conditional-access` `pim` `mfa`

### Requirements

Document a Conditional Access + PIM design for TaskFlow:

1. **CA Policy 1**: Require MFA for all admins (`User Administrator`, `Global Administrator`, `Owner` at sub).
2. **CA Policy 2**: Block legacy authentication.
3. **CA Policy 3**: Require compliant device for production resource access (App Service prod, Key Vault).
4. **PIM**: Mark `Owner` and `User Access Administrator` at subscription scope as *eligible* (not active). Activation requires MFA + 1-hour cap + justification.

Build a **runbook** for: "I need to make a config change in prod."

### Deliverable

`P5-ca-pim.md` (policies + runbook).

### Look-fors

- [ ] Each CA policy includes Users, Cloud apps, Conditions, Grant.
- [ ] PIM activation has approver + max duration.
- [ ] Runbook is < 8 steps and includes how to revert if the change is bad.

---

## Submission Checklist

- [ ] All scripts run idempotently against your tenant.
- [ ] Policy IDs documented (built-in vs custom).
- [ ] No tenant ID, sub IDs, or user UPNs in commits — placeholders.
- [ ] `README.md` indexes everything.

---

## Stretch Goals

- Implement an **Azure Blueprint replacement using Bicep modules** — one module per landing zone.
- Wire **Microsoft Sentinel** to ingest Activity Logs and write a KQL hunting query for "owner role assigned outside business hours".
- Compare your initiative to the **CIS Microsoft Azure Foundations Benchmark** built-in initiative — what's missing?
