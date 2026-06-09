# Topic 1: Azure Fundamentals — Practice Problems

> Six exercises that turn the Notes into muscle memory. Most are **Azure CLI scripts** + a few markdown deliverables. You can run everything against a free Azure subscription.

**Concept tags:** `subscriptions` `resource-groups` `rbac` `tags` `policy` `naming` `cli` `entra-id`

**Setup:**
```bash
az --version           # Azure CLI 2.60+ recommended
az login
az account show -o table
```
Create a working folder `PracticeProblemsSolutions/` (already scaffolded). Commit each script as you go.

---

## P1 — Subscription Tour & Budget Alert  *(Easy)*

**Tags:** `subscriptions` `cost`

### Requirements

1. Run `az account list` and capture the output.
2. Identify the **subscription ID**, **tenant ID**, and your **default region** (`az config get`).
3. Create a **budget alert** of **$10/month** on the subscription with email at 50%, 90%, and 100%.
4. Document everything you found in `P1-subscription-overview.md`.

### Deliverable

`P1-subscription-overview.md` containing:
- Subscription name + ID + tenant ID (redact any sensitive parts)
- Default region you chose and why
- Screenshot or CLI output of the budget you created

### Hints

- Budget can be created via Portal *Cost Management → Budgets* or CLI: `az consumption budget create-with-rg`.
- Tenant ID: `az account show --query tenantId -o tsv`.

### Look-fors (rubric)

- [ ] All three IDs documented (subscription, tenant, default region).
- [ ] Budget exists and is verifiable via `az consumption budget list`.
- [ ] You explain *why* you picked the region (latency, data residency, free tier availability).

---

## P2 — Resource Group Naming & Tagging Strategy  *(Easy)*

**Tags:** `naming` `tags` `governance`

### Requirements

1. Author a **naming convention document** for TaskFlow that covers RGs, App Services, Storage Accounts, Key Vaults, and Function Apps.
2. Define **5 mandatory tags** with allowed values for each.
3. Provision **two resource groups** following your convention:
   - `taskflow-dev-<region>-rg`
   - `taskflow-shared-<region>-rg`
4. Apply the mandatory tags at creation time.

### Deliverable

`P2-naming-and-tags.md` (the spec) **and** `P2-create-rgs.sh` (Bash) or `P2-create-rgs.ps1` (PowerShell) that produces the two RGs.

### Hints

- Storage account names are **globally unique**, lowercase, ≤ 24 chars, no dashes — your convention must accommodate that.
- Key Vault names are **globally unique** too.
- Use `--tags k=v k=v` syntax.

### Look-fors

- [ ] Convention covers global-unique constraints (Storage, Key Vault, App Service hostname).
- [ ] All 5 tags are specified with type & enum where applicable.
- [ ] Script is **idempotent** (`az group create` is safe to re-run; document this).
- [ ] Tags visible: `az group show -n taskflow-dev-eus-rg --query tags`.

---

## P3 — RBAC Least-Privilege Assignment  *(Medium)*

**Tags:** `rbac` `entra` `least-privilege`

### Requirements

You will simulate three identities for TaskFlow and assign **least-privilege** roles:

| Identity | Persona | Scope | Required access |
|---|---|---|---|
| `taskflow-dev-team` (group) | Developers | `taskflow-dev-eus-rg` | Read/write resources but **cannot grant access** |
| `taskflow-cicd` (service principal) | CI/CD pipeline | Same RG | Deploy infra & app, manage secrets in Key Vault |
| `taskflow-readonly-auditor` (user) | Auditor | Subscription | Read everything, modify nothing |

Steps:

1. Create the group, the SP, and (if you have one) a guest user / second account for the auditor.
2. Pick the **most narrow built-in role** for each.
3. Apply the role assignments via CLI.
4. Verify by running `az role assignment list --assignee <id>`.

### Deliverable

`P3-rbac.md` with: the chosen role for each, *why* (link to the role definition), and the CLI commands. Plus `P3-assign-rbac.sh`.

### Hints

- Don't reach for `Contributor` reflexively. The **`Reader`** + a couple of data-plane roles is often correct.
- For CI/CD, consider `Contributor` on the RG **plus** `Key Vault Secrets Officer` on the Key Vault data plane.
- For the auditor, `Reader` at the subscription is acceptable; do **not** use `Security Reader` (that's a different scope).

### Look-fors

- [ ] No identity is granted `Owner`.
- [ ] CI/CD has *enough* but not *more*: can deploy infra, cannot escalate to Owner, no DB-data access.
- [ ] Auditor scope is `subscription`, not `tenant root`.
- [ ] Your write-up explains the "why not Contributor" decision for at least one identity.

---

## P4 — Managed Identity Setup for a Function App  *(Medium)*

**Tags:** `managed-identity` `key-vault` `passwordless`

### Requirements

You won't deploy a Function App yet (Topic 2), but you **will** prepare the supporting cast.

1. Create a **Key Vault** in `taskflow-shared-<region>-rg`.
2. Add a secret `Sample--ConnectionString` with value `Server=demo;` (placeholder).
3. Create a **User-Assigned Managed Identity** named `mi-taskflow-app-dev`.
4. Grant the MI the **`Key Vault Secrets User`** role on the Key Vault (data-plane RBAC, not access policy).
5. Document how the MI will be attached to the Function App in Topic 2.

### Deliverable

`P4-managed-identity.md` + `P4-create-mi.sh` script.

### Hints

- Key Vault must have **RBAC authorization model** enabled at create time (`--enable-rbac-authorization true`).
- Use the **data-plane** role `Key Vault Secrets User` — *not* `Key Vault Reader` (that's metadata only) and *not* `Key Vault Administrator` (too broad).
- Capture the MI's `principalId` and `clientId`; you'll need them in Topic 2.

### Look-fors

- [ ] Key Vault uses RBAC mode, not access policies.
- [ ] MI exists and the role assignment is at the **vault scope**, not the RG.
- [ ] Secret retrievable using the MI: `az keyvault secret show` *will fail* from your user account if you don't have the role yourself — that's the point. Document this.

---

## P5 — Idempotent Bootstrap Script  *(Medium)*

**Tags:** `cli` `idempotency` `automation`

### Requirements

Combine P2–P4 into a single, **idempotent** script (`P5-bootstrap.sh` or `.ps1`) that:

1. Creates both RGs (if not exist).
2. Creates the Key Vault (if not exist).
3. Creates the User-Assigned MI (if not exist).
4. Applies the role assignment (idempotent: `az role assignment create` returns 409 if exists — handle gracefully).
5. Echoes a final summary of what was created vs already existed.

### Deliverable

`P5-bootstrap.sh` (or `.ps1`) + a short `P5-runlog.md` showing one fresh run and one re-run, demonstrating idempotency.

### Hints

- Use `set -euo pipefail` (Bash) or `$ErrorActionPreference = 'Stop'` (PowerShell).
- For idempotency: check existence first (`az group exists`, `az keyvault show 2>/dev/null || ...`).
- Avoid hard-coded secrets — read sensitive values from environment variables.

### Look-fors

- [ ] Script runs cleanly on a brand-new subscription **and** re-runs without errors.
- [ ] No hard-coded secrets or subscription IDs (parameters or env vars).
- [ ] Script exits non-zero if any step actually fails.
- [ ] Final summary makes it obvious what was created vs reused.

---

## P6 — Azure Policy: Enforce Tags & Region  *(Hard)*

**Tags:** `azure-policy` `governance`

### Requirements

Author and assign **two policies** at the **resource group** scope `taskflow-dev-eus-rg`:

1. **Region restriction**: only allow resources in your chosen region (`eastus`, `westeurope`, etc.). Built-in policy.
2. **Required tag**: deny resources missing the `environment` tag. Built-in policy.

Then:

3. Try to violate each policy from the CLI (e.g. create a Storage Account in a forbidden region, or without the tag) and capture the **error message**.
4. Write a short post-mortem in `P6-policy.md` explaining the policy ID, parameters, and the error you saw.

### Deliverable

`P6-policy.md` + `P6-assign-policies.sh` + screenshots or pasted CLI errors of the rejected attempts.

### Hints

- Built-in policy IDs:
  - Allowed locations: `e56962a6-4747-49cd-b67b-bf8b01975c4c`
  - Require a tag: `871b6d14-10aa-478d-b590-94f262ecfa99`
- Policy assignment via CLI: `az policy assignment create --policy <id> --params @params.json --scope <rg-id>`.
- Tag policy with `effect=deny` is the strict version.

### Look-fors

- [ ] Both policies are visible: `az policy assignment list --resource-group taskflow-dev-eus-rg`.
- [ ] At least one violation captured with the actual deny message (proves enforcement).
- [ ] Write-up explains *Audit* vs *Deny* effects and when you'd use each.
- [ ] Cleanup section: how to remove the assignments without deleting the RG.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All six deliverables exist in `PracticeProblemsSolutions/`.
- [ ] Scripts run end-to-end on a clean RG.
- [ ] No real secrets or subscription IDs committed (use placeholders).
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Try the same exercises with **Bicep** instead of CLI (you'll appreciate IaC sooner).
- Configure **Cost Anomaly alerts** in addition to the budget.
- Read about **Microsoft Defender for Cloud** Free tier and enable it on the subscription.
