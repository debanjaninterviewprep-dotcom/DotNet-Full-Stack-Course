# Topic 1: Azure Fundamentals — Subscriptions, Resource Groups & IAM

> Phase 7 lifts **TaskFlow** from a developer laptop into Azure. Before deploying a single Function App or APIM gateway, you must understand the *shape of Azure*: how accounts are organized, how resources are grouped, and how identity controls every API call. Get this right and the rest of the phase is a series of small, predictable additions. Get it wrong and you ship a system you can't secure, audit, or pay for.

---

## 1. The Azure Hierarchy

Azure organizes everything in a strict **4-level hierarchy**. You will be tested on this in interviews and you will use it every day.

```
Tenant (Microsoft Entra ID directory)
└── Management Group(s)
    └── Subscription(s)
        └── Resource Group(s)
            └── Resource(s)   <-- VMs, Storage Accounts, Function Apps, etc.
```

| Level | What it is | Boundary it provides |
|---|---|---|
| **Tenant** | An Entra ID directory. Identity root. | Identity, users, groups, service principals |
| **Management Group** | A container for many subscriptions | Org-wide policy & RBAC inheritance |
| **Subscription** | Billing + quota container | Spending limit, region quotas, billing owner |
| **Resource Group** | Logical lifecycle container | Deploy / delete / tag / RBAC scope |
| **Resource** | The actual thing (Storage, Function, DB) | Region pinning, SKU, cost item |

> **Why this matters:** RBAC, Policy, and Cost flow *down* this tree. Assigning Reader at the Management Group cascades to every subscription beneath it. Putting two unrelated apps in one resource group means you can't delete one without affecting the other.

### Real-world mapping

A typical company with one Entra tenant might have:

- One **Management Group** per business unit (`eng`, `finance`).
- One **Subscription** per environment (`eng-dev`, `eng-prod`, `finance-prod`).
- One **Resource Group** per app+environment (`taskflow-prod-rg`).
- N **Resources** per app (App Service, SQL DB, Storage, Key Vault, Redis).

For the TaskFlow course, you'll work in **one subscription**, with **one resource group per environment** (`taskflow-dev-rg`, `taskflow-prod-rg`).

---

## 2. Subscriptions: The Billing & Quota Boundary

A subscription is what gets charged on a credit card. It also enforces:

- **Resource quotas** (e.g., 10 Standard_D vCPUs per region by default).
- **Region availability** — which Azure regions you can use.
- **Policy assignments** scoped to it.
- **Cost reporting** — the natural unit for showback / chargeback.

### Common patterns

| Pattern | When to use |
|---|---|
| One sub for *everything* | Personal projects, demos, courses |
| Sub-per-environment | Most teams (`dev`, `staging`, `prod`) |
| Sub-per-business-unit | Large enterprises (HR, Sales, Engineering) |
| Sub-per-product-per-env | Highly regulated orgs (banking) |

> **Anti-pattern:** Mixing `prod` and `dev` resources in the same subscription. A misconfigured policy or a runaway test job can hit production quotas, and RBAC at sub-scope leaks across environments.

---

## 3. Resource Groups: The Lifecycle Boundary

A resource group (RG) is a container with three superpowers:

1. **Lifecycle** — `az group delete` removes everything in it. Treat it as the "if I delete this folder, what should disappear?" question.
2. **RBAC scope** — assign roles once at the RG, inherited by all resources inside.
3. **Tags & cost** — every resource inherits the RG's location label and tags by convention.

### Naming convention (TaskFlow)

```
<workload>-<environment>-<region-short>-rg
```

Examples:
- `taskflow-dev-eus-rg` (East US, Dev)
- `taskflow-prod-weu-rg` (West Europe, Prod)
- `taskflow-shared-eus-rg` (shared infra: Key Vault, Log Analytics)

> **Region note:** A resource group itself has a region (where its metadata lives), but its resources can live in *any* region. In practice, keep them aligned: `weu-rg` should contain `westeurope` resources.

### What goes together?

| Belongs in same RG | Does NOT belong together |
|---|---|
| App + its DB + its Storage + its Key Vault for one workload+env | Two unrelated apps |
| Resources with the same lifecycle | Prod and Dev |
| Resources owned by the same team | Shared infra mixed with workload-specific infra |

---

## 4. Microsoft Entra ID (Azure AD) — The Identity Plane

Every API call to Azure is authenticated against **Microsoft Entra ID** (renamed from Azure AD in 2023). Entra issues OAuth 2.0 tokens; ARM (Azure Resource Manager) validates them and checks RBAC.

### Identity types

| Identity | What it represents | Lives where | Used for |
|---|---|---|---|
| **User** | A human | Entra tenant | Console / `az login` |
| **Group** | A set of users | Entra tenant | Bulk RBAC |
| **Service Principal (SP)** | An app's identity (with a client secret or cert) | Entra tenant (App Registration) | CI/CD, scripts |
| **Managed Identity (MI)** | An SP managed *by Azure* (no secret to rotate) | Bound to a resource | App-to-Azure auth |
| **Workload Identity Federation** | Federated trust to GitHub / external IdP | Entra tenant | OIDC-based CI/CD |

> **Rule of thumb (TaskFlow):**
> - Humans → users (with MFA + Conditional Access).
> - GitHub Actions → **Workload Identity Federation** (OIDC, no secrets).
> - Function App → **System-assigned Managed Identity** to read Key Vault, Storage, etc.

---

## 5. RBAC — Role-Based Access Control

RBAC answers: *"Can identity X do action Y on resource Z?"*

### The model

```
Role Assignment = (security principal) + (role definition) + (scope)
```

- **Security principal**: user / group / SP / MI.
- **Role definition**: a set of allowed actions (e.g. `Storage Blob Data Reader` = `Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read`).
- **Scope**: management group, sub, RG, or single resource.

### Built-in roles you must know

| Role | What it grants | Use for |
|---|---|---|
| **Owner** | Full + can grant access | Subscription owners only |
| **Contributor** | Full management, *cannot grant access* | Most developer access |
| **Reader** | Read-only metadata | Auditors, monitoring tools |
| **User Access Administrator** | Manage RBAC only | Identity admins |
| **Storage Blob Data Reader/Contributor** | Data-plane on blobs (not the account itself) | Apps reading/writing blobs |
| **Key Vault Secrets User** | Read secrets at runtime | Function App MI |
| **Key Vault Secrets Officer** | Manage secret values | CI/CD pipelines |

### The principle of least privilege

- Prefer **data-plane** roles (`Blob Data Reader`) over **management-plane** roles (`Contributor`).
- Prefer **resource-scoped** assignments over RG-scoped, RG over sub.
- Audit `Owner` ruthlessly — there should be ≤ 2 humans with sub-Owner.

> **Anti-pattern:** Granting `Contributor` at the subscription to the entire dev team. Use **groups** + tighter scopes.

---

## 6. Azure Policy — Guardrails Beyond RBAC

RBAC says *who can do something*. Policy says *what is allowed regardless of who*.

Examples:

- *"Resources may only be created in `eastus` or `westeurope`."*
- *"Storage accounts must have public network access disabled."*
- *"All resources must have a `costCenter` tag."*

Policies have effects: `Deny`, `Audit`, `Append`, `DeployIfNotExists`, `Modify`. Assigned at MG / sub / RG scope.

For TaskFlow you'll attach a few baseline policies in Topic 8.

---

## 7. Regions, Availability Zones & Pairs

| Concept | What it is | Why it matters |
|---|---|---|
| **Region** | A geographic Azure datacenter cluster (e.g. `eastus`) | Latency, data residency, regulatory compliance |
| **Availability Zone (AZ)** | A physically isolated datacenter inside a region | Resilience to a single-DC failure |
| **Region Pair** | Two regions Microsoft replicates between (e.g. `eastus` ↔ `westus`) | Geo-redundant storage, paired DR |

For TaskFlow MVP: pick **one region close to your users** (e.g. `eastus`). For production-grade later: deploy across **2 AZs** in one region; use a **paired region** for backup/DR.

---

## 8. Tagging Strategy

Tags are key/value pairs that flow into cost reports, automation, and policy.

**Mandatory TaskFlow tags:**

| Tag | Example | Purpose |
|---|---|---|
| `workload` | `taskflow` | Which app |
| `environment` | `dev` / `staging` / `prod` | Filter & policy |
| `owner` | `debanjan@example.com` | Who to ping |
| `costCenter` | `eng-platform` | Showback |
| `dataClassification` | `internal` / `pii` | Compliance |

Enforce them via Policy: *Append* missing tags, *Deny* resources without `environment`.

---

## 9. The Three Ways to Talk to Azure

| Tool | Best for |
|---|---|
| **Azure Portal** | Exploration, one-off ops, learning |
| **Azure CLI** (`az`) | Scripts, CI/CD, day-to-day ops |
| **Azure PowerShell** (`Az` module) | Windows-shop ops |
| **ARM / Bicep / Terraform** | Declarative IaC (what your infra *should* be) |
| **Azure SDKs** | App code calling Azure services |

For Phase 7 you'll mostly use **Azure CLI** for setup and **Bicep** for IaC.

### Essential CLI commands

```bash
# Login
az login
az account set --subscription "<sub-id-or-name>"

# Resource groups
az group create --name taskflow-dev-eus-rg --location eastus \
  --tags workload=taskflow environment=dev owner=you@example.com

# Show what's in an RG
az resource list --resource-group taskflow-dev-eus-rg --output table

# Role assignments
az role assignment list --resource-group taskflow-dev-eus-rg --output table

# Delete an RG (and everything in it)
az group delete --name taskflow-dev-eus-rg --yes --no-wait
```

---

## 10. Cost Awareness from Day One

Every resource you create costs money. Phase 7 uses **free / consumption-tier** SKUs wherever possible:

| Service | Free / Cheap tier you'll use |
|---|---|
| App Service | F1 Free or B1 Basic |
| Azure Functions | Consumption plan (1 M free executions/month) |
| Storage Account | Standard LRS, hot tier |
| APIM | Consumption tier (no fixed cost) |
| Service Bus | Basic / Standard (only when needed) |
| Redis | Basic C0 (250 MB) — *not* free, ~$16/mo |
| Log Analytics | First 5 GB/month free |

> **Habit:** Set a **Budget Alert** on your subscription before creating anything (covered in P1).

---

## 11. Mental Model Recap

When you create a resource, ask these five questions in order:

1. **Tenant**: Which directory am I in? (`az account show`)
2. **Subscription**: Which one is billing? (`az account list`)
3. **Resource Group**: Does the right RG exist? Same lifecycle?
4. **Region**: Closest to users, paired for DR?
5. **Identity**: How will my app authenticate? (MI, not secrets.)
6. **Tags**: Did I tag for cost & ownership?

If you can answer all six, you're operating like a senior cloud engineer.

---

## Further Reading

- [Microsoft Cloud Adoption Framework — Subscription design](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/resource-org-subscriptions)
- [RBAC built-in roles](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Azure regions & AZs](https://learn.microsoft.com/azure/reliability/availability-zones-overview)
- [Naming and tagging conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming-and-tagging-decision-guide)
