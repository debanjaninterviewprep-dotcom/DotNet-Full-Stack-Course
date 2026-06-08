# Topic 2: Management Groups & Azure Policy (the Azure equivalent of SCPs)

> **Note on the topic title.** The roadmap entry was "Service Control Policies (SCPs)" — that term comes from AWS Organizations. The Microsoft-cloud equivalent is **Management Groups + Azure Policy + Initiatives**, layered with **Resource Locks** and **Custom Role Definitions**. This module covers the full Azure stack.

## What You'll Learn

How to enforce **tenant-wide guardrails** that no developer or admin can casually violate: management-group hierarchy, Azure Policy (audit, deny, modify, deployIfNotExists), Initiatives, Policy-as-Code through Terraform/Bicep with CI, Resource Locks, exemptions, and a compliance reporting loop.

---

## 1. The Azure Governance Stack

```
   Tenant root group  ◄──── policy assigned here flows down everywhere
      │
   ┌──┴──────────┐
   │  Landing    │     ┌──────────────┐
   │  Zones MG   │ ────► Connectivity │
   └──┬──────────┘     │  Identity    │
      │                │  Management  │
   ┌──┴──────────┐     │  Sandbox     │
   │ Workloads MG│     └──────────────┘
      │
   ┌──┴──────────┐
   │ Prod │ NonProd │
   └──────┴────────┘
       │       │
   Subscription(s)
       │
   Resource Group
       │
   Resource
```

A **policy** assigned at a management group flows to every subscription, RG, and resource beneath it — *unless* an exemption is created. The hierarchy is the lever; everything else is tactics.

---

## 2. Management Groups (MGs)

- **Tenant root group** is the topmost; every subscription is under it (visible to anyone with `Hierarchy Settings` access).
- You can nest up to **6 levels** below root (excluding root and subscription).
- A subscription belongs to **exactly one** management group at a time.
- Move operations are RBAC-controlled (`Management Group Contributor` + `Microsoft.Management/managementGroups/subscriptions/write`).

Recommended hierarchy (aligns with Microsoft's Cloud Adoption Framework "Landing Zone" pattern):

```
Tenant Root
├── Platform
│   ├── Identity         (Entra Connect, AAD Connect Sync VM, etc.)
│   ├── Management       (Log Analytics, Automation, Monitoring)
│   └── Connectivity     (Hub VNet, Firewall, ExpressRoute)
├── Landing Zones
│   ├── Corp             (Internal apps)
│   └── Online           (Internet-facing apps)
├── Sandbox              (Dev play; throwaway)
└── Decommissioned       (Subs flagged for delete; deny most actions)
```

Why this matters: policies, RBAC and budgets attach at the level that matches their scope. Don't push everything to the root — you'll never be able to vary.

---

## 3. Azure Policy — The Workhorse

### Concepts

| Concept | Definition |
|---|---|
| **Policy definition** | The rule itself (JSON). |
| **Initiative (policy set)** | Bundle of definitions assigned together. |
| **Assignment** | A definition or initiative applied at a scope (MG/sub/RG). |
| **Effect** | What the policy does when the rule matches. |
| **Parameter** | Value injected at assignment time (e.g., allowed SKUs list). |
| **Exemption** | Time-bound carve-out for a specific scope. |
| **Compliance state** | Result of evaluation: Compliant / NonCompliant / Conflict / Exempt / NotStarted. |

### Effects (the important ones)

| Effect | What it does | Use case |
|---|---|---|
| `Audit` | Log non-compliance; don't block | Pilot a policy in report-only |
| `Deny` | Block the resource operation | Hard guardrails (no public IPs in prod) |
| `Modify` | Add or change properties at create/update | Enforce tags, default TLS settings |
| `Append` | Add properties (legacy; prefer Modify) | — |
| `DeployIfNotExists` (DINE) | Deploy a related resource if missing | Auto-enable Diagnostic Settings |
| `AuditIfNotExists` (AINE) | Log if related resource is missing | Find resources missing Diag Settings |
| `Disabled` | Turn off the policy at this scope | Suppress without exemption |
| `Manual` (preview) | Attest manually | Compliance frameworks |

> Best practice: **start with `Audit`**, watch the compliance dashboard for a week, then promote to `Deny` for clear cases.

### Anatomy of a policy

```json
{
  "properties": {
    "displayName": "Allowed locations for resources",
    "policyType":  "Custom",
    "mode":        "Indexed",
    "description": "This policy enables you to restrict the locations your org can create resources in.",
    "parameters": {
      "allowedLocations": {
        "type":        "Array",
        "metadata":    { "displayName": "Allowed locations" },
        "defaultValue": ["northeurope","westeurope"]
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          { "field": "location",                                  "notIn": "[parameters('allowedLocations')]" },
          { "field": "location",                                  "notEquals": "global" },
          { "field": "type",                                      "notEquals": "Microsoft.AzureActiveDirectory/b2cDirectories" }
        ]
      },
      "then": { "effect": "deny" }
    }
  }
}
```

Key fields:
- `mode: Indexed` evaluates against resources that support tags and location (most). `All` includes RGs and subscriptions.
- `if` is a boolean expression over **aliases** (e.g., `Microsoft.Storage/storageAccounts/allowBlobPublicAccess`).
- `then.effect` is the action.

### Aliases — the secret weapon

An **alias** maps a policy field to a resource property:
```
Microsoft.Storage/storageAccounts/allowBlobPublicAccess
Microsoft.Network/virtualNetworks/subnets[*].privateEndpointNetworkPolicies
```

Find them via:
```bash
az provider show --namespace Microsoft.Storage --expand "resourceTypes/aliases" -o json
```

Without aliases, you can't write effective custom policies. Always check what's available before reinventing.

### Built-in initiatives you should know

| Initiative | What it covers |
|---|---|
| **Azure Security Benchmark** | Microsoft's security baseline; ~250 controls |
| **NIST SP 800-53 R5** | US Federal compliance |
| **ISO 27001:2013** | International security standard |
| **PCI DSS 4** | Payment card industry |
| **HIPAA HITRUST** | Healthcare |
| **CIS Microsoft Azure Foundations** | Industry-standard hardening |
| **Azure Landing Zones (ALZ) – Sovereignty / Confidential** | Microsoft's reference stacks |

Assign one of these at the right MG and you get hundreds of audits "for free". They feed Defender for Cloud's Secure Score (Topic 4).

---

## 4. Policy-as-Code with Terraform

Hand-authored portal policies don't survive. Treat policies as IaC.

```hcl
resource "azurerm_policy_definition" "deny_public_storage" {
  name         = "deny-storage-public-blob"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Storage accounts must disallow public blob access"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess", equals = true }
      ]
    }
    then = { effect = "deny" }
  })
}

resource "azurerm_policy_set_definition" "taskflow_baseline" {
  name         = "taskflow-baseline"
  policy_type  = "Custom"
  display_name = "TaskFlow Baseline"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_public_storage.id
    reference_id         = "denyPublicStorage"
  }
  # ... more references ...
}

resource "azurerm_management_group_policy_assignment" "baseline_workloads" {
  name                 = "taskflow-baseline-workloads"
  management_group_id  = data.azurerm_management_group.workloads.id
  policy_definition_id = azurerm_policy_set_definition.taskflow_baseline.id
  enforce              = true
  description          = "Enforce baseline at Workloads MG."
}
```

A policy CI workflow should:
1. `terraform plan` → comment on PR.
2. Run **`terraform validate`** and a **policy unit test** against synthetic resources (e.g., using OPA or `pester`-style harness).
3. On merge to main → `terraform apply` to a non-prod MG first, observe **compliance results for 24–48 h**, then promote.
4. Track compliance drift via `az policy state summarize`.

---

## 5. Resource Locks

Independent of Azure Policy. Two types:

| Lock | Effect | Use |
|---|---|---|
| `CanNotDelete` | Read/modify ok; delete blocked | Prevent accidental teardown of prod RG / shared resources |
| `ReadOnly` | No modifications, no delete | Frozen artefacts |

```hcl
resource "azurerm_management_lock" "prod_rg" {
  name       = "do-not-delete-prod"
  scope      = azurerm_resource_group.prod.id
  lock_level = "CanNotDelete"
  notes      = "Production resource group; deletion requires manual lock removal + ticket."
}
```

Locks **override** RBAC for delete operations — even an `Owner` must remove the lock first. Apply them on:
- Production resource groups.
- Resources that other systems reference by ID (Key Vault, Log Analytics).
- Backup vaults.

---

## 6. Exemptions

Sometimes a policy can't apply (legacy resource, deliberate exception). Use **exemptions** — never disable a policy at the assignment level.

```hcl
resource "azurerm_management_group_policy_exemption" "legacy_storage" {
  name                            = "exempt-legacy-storage-publicblob"
  management_group_id             = data.azurerm_management_group.workloads.id
  policy_assignment_id            = azurerm_management_group_policy_assignment.baseline_workloads.id
  policy_definition_reference_ids = ["denyPublicStorage"]
  exemption_category              = "Waiver"
  expires_on                      = "2026-12-31T23:59:59Z"
  description                     = "Legacy partner-required public container, sunset by EOY 2026. Owner: maya@taskflow.com. Ticket: SEC-1873."
}
```

Rules:
- **Time-bound**. No exemption should be open-ended.
- **Attributed**. Owner + ticket reference in the description.
- **Reviewed quarterly**. Run a script to surface those expiring in the next 30 days; require renewal or remediation.

---

## 7. Common Policy Patterns

### 7.1 Tag enforcement (Modify)
Enforce `costCenter`, `owner`, `environment` on every RG.

```jsonc
{
  "if": {
    "allOf": [
      { "field": "type", "equals": "Microsoft.Resources/subscriptions/resourceGroups" },
      { "field": "tags['costCenter']", "exists": "false" }
    ]
  },
  "then": {
    "effect": "modify",
    "details": {
      "roleDefinitionIds": ["/providers/microsoft.authorization/roleDefinitions/<Contributor-id>"],
      "operations": [
        { "operation": "add", "field": "tags['costCenter']", "value": "[parameters('defaultCostCenter')]" }
      ]
    }
  }
}
```

### 7.2 Deny public network access on PaaS (Deny)
Storage, SQL, Cosmos, Key Vault, App Config — block `publicNetworkAccess = Enabled` outside an allow-list.

### 7.3 Auto-enable Diagnostic Settings (DeployIfNotExists)
When a resource is created without diagnostic settings, DINE pushes a default forwarding to your Log Analytics workspace.

### 7.4 Restrict SKUs (Deny)
Block expensive SKUs in non-prod (deny anything outside `["F1","B1","B2","P1v3"]`).

### 7.5 Enforce HTTPS-only / TLS 1.2+ (Modify)
On App Service, Storage, SQL, etc.

### 7.6 Require Private Endpoint (Audit then Deny)
Phase 1: audit which PaaS lacks a private endpoint. Phase 2: deny new resources without one.

### 7.7 Enforce specific regions (Deny)
Aligns with data-residency requirements.

---

## 8. Compliance Reporting Loop

A policy that nobody reads is decoration. The loop:

1. **Daily compliance summary** (KQL on `PolicyResources`):

```kql
PolicyResources
| where type == "microsoft.policyinsights/policystates"
| where properties.complianceState == "NonCompliant"
| summarize NonCompliant=count() by tostring(properties.policyDefinitionName)
| order by NonCompliant desc
```

2. **Workbook** showing compliance by MG / subscription / definition.
3. **Alert** when overall compliance drops > 5% in 24 h.
4. **Weekly review**: SRE/Sec walks the top offenders.
5. **Remediation tasks**: for DINE policies, fire `az policy remediation create` to re-evaluate and apply.

---

## 9. Custom Role Definitions Recap (Cross-Topic)

Topic 1 covered roles in depth — quick reminder of the role/policy split:

| | Azure RBAC | Azure Policy |
|---|---|---|
| Answers | Who can do what | What's allowed to exist / how |
| Acts on | Operations (CRUD) | Resource properties |
| Example | "Bob can create VMs" | "VMs must be size B-series" |

Both layered together. RBAC says *can*; Policy says *should*. Bob may be Contributor, but Policy still denies him an RG in `eastus` if your geo-restriction policy is set.

---

## 10. Anti-Patterns

| Anti-pattern | Why it bites | Better |
|---|---|---|
| All policies at tenant root | Can't vary per workload | Use MG hierarchy |
| Going straight to `Deny` | Floor of broken deployments | Audit → Deny progression |
| Hand-edited policies in portal | Drift; no review trail | Policy-as-Code in TF/Bicep |
| Open-ended exemptions | Become forever | Time-bound + quarterly review |
| Disabling policy after first failure | Trust falls apart | Exemption with justification |
| No compliance reporting | Policy theater | KQL + workbook + alerts |
| Custom policy where built-in exists | Maintenance burden | Search built-ins first |
| Custom roles for everything | Drift between RBAC and built-ins | Compose built-in roles when possible |
| No resource lock on prod RG | One accidental delete = outage | `CanNotDelete` on prod RGs |
| DINE policies pointing at a single LAW | Cross-region traffic + cost | Per-region or geo-locality |

---

## 11. Designing the Stack for TaskFlow

**MG hierarchy:**
- Tenant root → Platform / Landing Zones / Sandbox
- Landing Zones → Workloads (Prod / NonProd) → TaskFlow Prod sub / TaskFlow NonProd sub

**Assignments at MG levels:**
- Tenant root: Tag enforcement (`owner`, `costCenter`), allowed locations (`northeurope`, `westeurope`), CIS baseline (Audit).
- Workloads MG: Deny public network access on PaaS, deny non-HTTPS, DINE diagnostic settings.
- Prod sub: stricter SKU restrictions, deny public IP on new VMs, require private endpoints.
- NonProd sub: audit-only equivalents to allow experimentation.

**Locks:**
- `CanNotDelete` on prod RGs and on the Log Analytics workspace.

**Exemptions process:**
- PR adds exemption to Terraform module with `expires_on`.
- Required reviewers: security + workload owner.
- Notification 30 days before expiry.

**Compliance loop:**
- Daily KQL summary → Teams.
- Weekly workbook review.
- Drift alert (5% in 24 h).

---

## 12. Mental Model

> Management Groups + Azure Policy form the **constitution** of your tenant: rules everyone in your cloud must follow, enforced at the deepest layer of the API. Build the hierarchy thoughtfully, write policy as code, start in Audit, then turn the dial to Deny — and review compliance like you review test coverage.

Move to [Practice Problems](./Practice-Problems.md).
