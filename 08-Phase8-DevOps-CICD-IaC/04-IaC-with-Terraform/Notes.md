# Topic 4: Infrastructure as Code (IaC) with Terraform

> **Goal:** Provision Azure resources declaratively with Terraform. By the end you can write, plan, apply, and destroy a multi-resource Azure environment from a single repo, understand the state file, manage providers and versions, and integrate Terraform with a CI/CD pipeline using OIDC.

---

## 1. Why Infrastructure as Code at All

Three reasons your infra should live in a repo, not in someone's Azure tab:

1. **Reproducibility.** Recreate `staging` from scratch in 20 minutes. Test changes in `dev` first. Spin up an isolated env per PR.
2. **Auditability.** Every change has a commit, a diff, an author, a review. The Portal has none of that.
3. **Change control.** A bad change is `git revert` away. A bad portal click is a postmortem.

IaC isn't optional once you have more than a single environment. The only question is *which tool*.

### 1.1 Why Terraform (vs Bicep, ARM, Pulumi, CDK)

| Tool | Strengths | Weaknesses | Best for |
|---|---|---|---|
| **Terraform** | Multi-cloud, huge provider ecosystem, mature state model, HCL is readable | Slower to adopt new Azure features than Bicep | Multi-cloud, teams who want one tool |
| **Bicep** | First-party Azure, ships day-1 features, no state file | Azure-only | Pure-Azure shops |
| **ARM JSON** | Lowest-level | Verbose, hard to read | Niche; almost always prefer Bicep |
| **Pulumi** | Real programming languages (C#, TS, Python) | State server (Pulumi Cloud) or your own | Teams that hate DSLs |
| **AWS CDK / Azure CDKtf** | Real code → IaC | Compile step; debugging weirder | Teams already on CDK culture |

TaskFlow is Azure-primary but Topic 7 of Phase 7 introduced **multi-cloud**. We use **Terraform** here so the same toolchain provisions Azure and AWS resources. We'll show Bicep where it's clearly simpler.

### 1.2 Declarative vs imperative

```bash
# Imperative
az group create -n rg-taskflow-dev -l eastus
az appservice plan create -g rg-taskflow-dev -n plan-taskflow-dev --sku S1
az webapp create -g rg-taskflow-dev -p plan-taskflow-dev -n app-taskflow-dev
```

```hcl
# Declarative
resource "azurerm_resource_group" "rg" {
  name     = "rg-taskflow-dev"
  location = "eastus"
}
```

The imperative script is fine the first time. On run #2 it fails because the RG already exists. Terraform's mental model is **"this is the desired state — make it so."** It compares to actual state and computes a diff.

---

## 2. Terraform Architecture (the big picture)

```
┌─────────────────┐      plan / apply       ┌─────────────────┐
│  .tf files      │ ──────────────────────▶ │  Azure          │
│  (your code)    │                          │  (real world)   │
└────────┬────────┘                          └────────┬────────┘
         │                                            │
         ▼                                            ▼
   ┌──────────┐       compare & reconcile      ┌──────────┐
   │ desired  │  ◀────────────────────────────▶│  actual  │
   │  state   │                                │  state   │
   └──────────┘                                └──────────┘
         ▲
         │ persisted between runs
   ┌──────────┐
   │  state   │  (local file or remote backend)
   │  file    │
   └──────────┘
```

Five concepts:

| Concept | What it is |
|---|---|
| **Configuration** | `.tf` files (HCL) describing desired state |
| **Provider** | Plugin that talks to a target API (azurerm, aws, kubernetes) |
| **Resource** | A single thing (RG, VNet, App Service) |
| **State** | Terraform's memory of what it created and current attributes |
| **Backend** | Where state is stored (local file, Azure Storage, S3, Terraform Cloud) |

---

## 3. Installation & First Project

### 3.1 Install
```powershell
winget install HashiCorp.Terraform
terraform -version
```

Recommended companions:
- `tflint` — lint HCL.
- `tfsec` / `checkov` — security/IaC scanning.
- `terraform-docs` — auto-generate module README.
- VS Code extension **"HashiCorp Terraform"**.

### 3.2 Project layout (start simple)

```
infra/
├── providers.tf       # which providers + version pins
├── variables.tf       # inputs (with defaults & validation)
├── main.tf            # resources
├── outputs.tf         # values to expose
├── terraform.tfvars   # variable values (often gitignored)
└── .terraform.lock.hcl   # provider versions lock (commit this)
```

### 3.3 First Terraform file

`providers.tf`:
```hcl
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  # Auth from env vars (ARM_*) or az login — never hard-code
}
```

`variables.tf`:
```hcl
variable "project" {
  description = "Project short name; lowercase, 4-12 chars"
  type        = string
  default     = "taskflow"
  validation {
    condition     = can(regex("^[a-z]{4,12}$", var.project))
    error_message = "project must be 4-12 lowercase letters."
  }
}

variable "environment" {
  description = "Environment: dev / staging / prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
```

`main.tf`:
```hcl
locals {
  base_name = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.common_tags
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_storage_account" "sa" {
  name                            = "st${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}
```

`outputs.tf`:
```hcl
output "resource_group_name" { value = azurerm_resource_group.rg.name }
output "storage_account_name" { value = azurerm_storage_account.sa.name }
output "storage_account_id"   { value = azurerm_storage_account.sa.id }
```

`terraform.tfvars` (gitignore this file or use `.auto.tfvars` per env):
```hcl
environment = "dev"
location    = "eastus"
tags = {
  cost_center = "platform"
  owner       = "platform-team@taskflow.io"
}
```

### 3.4 The four commands you'll run forever

```powershell
az login
terraform init      # download providers, set up backend
terraform fmt -recursive   # canonical formatting
terraform validate         # static check
terraform plan -out tfplan # compute diff against real world
terraform apply tfplan     # apply the saved plan
terraform destroy          # tear it all down
```

**Always plan to a file**, then apply that file. Don't apply a fresh plan — drift between plan and apply has caused outages.

---

## 4. Providers

### 4.1 Version pinning
Three operators:
- `= "4.7.0"` exact
- `~> 4.0` allow patch & minor (`4.x`)
- `>= 4.0, < 5.0` range

**Use `~> X.Y` for libraries you trust to follow semver.** Pin exactly when burned by a regression.

### 4.2 Multiple subscriptions
```hcl
provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000001"
  alias           = "platform"
}

provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000002"
  alias           = "workload"
}

resource "azurerm_resource_group" "platform_rg" {
  provider = azurerm.platform
  name     = "rg-platform"
  location = "eastus"
}
```

### 4.3 Authentication options (order of preference)

1. **OIDC from CI** (Topic 1) — `ARM_USE_OIDC=true`, no secret stored.
2. **Managed Identity** on the runner — `ARM_USE_MSI=true`.
3. **`az login` developer flow** — fine for local; never CI.
4. **Service principal + secret** — legacy; avoid.

Env-driven auth (CI uses these):
```
ARM_TENANT_ID
ARM_SUBSCRIPTION_ID
ARM_CLIENT_ID
ARM_USE_OIDC=true            # mints OIDC token from the GH runner
```

---

## 5. Resources & Data Sources

### 5.1 Resource block
```hcl
resource "<TYPE>" "<NAME>" {
  argument = "value"
  nested_block {
    field = "value"
  }
}
```

- `TYPE` — provider name + resource (e.g., `azurerm_storage_account`).
- `NAME` — your label inside Terraform. Not the Azure name.

Reference an attribute: `azurerm_storage_account.sa.primary_blob_endpoint`.

### 5.2 Data sources (read-only lookup)

```hcl
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "shared" {
  name = "rg-shared-platform"
}

resource "azurerm_role_assignment" "ra" {
  scope                = data.azurerm_resource_group.shared.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}
```

Data sources are read at plan time. Use them for things Terraform didn't create.

### 5.3 Dependencies
- **Implicit:** if A references `B.id`, Terraform knows A depends on B.
- **Explicit:** use `depends_on = [B]` when no attribute reference but you need ordering (rare; usually a code smell).

---

## 6. Variables, Locals, Outputs

### 6.1 Variables
```hcl
variable "instance_count" {
  type        = number
  default     = 2
  description = "App Service plan instance count"
  sensitive   = false
  nullable    = false
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count must be 1-10."
  }
}
```

- `sensitive = true` masks the value in plan output.
- `nullable = false` forces a value.
- Validation runs at plan time — fail fast.

Setting values, in precedence order (highest wins):
1. `-var` CLI flag
2. `-var-file` CLI flag
3. `*.auto.tfvars` files (alphabetical)
4. `terraform.tfvars`
5. Environment variables `TF_VAR_<name>`
6. Variable default

### 6.2 Locals
Computed within the config; not user-tunable:
```hcl
locals {
  is_prod    = var.environment == "prod"
  sku        = local.is_prod ? "P1v3" : "B1"
  capacity   = local.is_prod ? 3 : 1
  base_name  = "${var.project}-${var.environment}"
}
```

Use `locals` for expressions you reuse. Don't over-extract — keep simple expressions inline.

### 6.3 Outputs
```hcl
output "app_url" {
  value       = "https://${azurerm_linux_web_app.api.default_hostname}"
  description = "API base URL"
}

output "connection_string" {
  value     = azurerm_storage_account.sa.primary_connection_string
  sensitive = true   # never logged
}
```

Outputs become inputs for other root modules via `terraform_remote_state`, or get consumed by your pipeline (`terraform output -raw app_url`).

---

## 7. Expressions, Functions, Meta-Arguments

### 7.1 Common functions
```hcl
length(var.list)                # 3
upper("abc")                    # "ABC"
lower("ABC")                    # "abc"
substr("hello", 0, 3)           # "hel"
format("%s-%02d", "env", 5)     # "env-05"
join("-", ["a", "b", "c"])      # "a-b-c"
split(",", "a,b,c")             # ["a","b","c"]
contains(["a","b"], "a")        # true
lookup(map, key, default)
merge(map1, map2)
file("${path.module}/policy.json")
jsondecode(file(...))
base64encode("text")
cidrsubnet("10.0.0.0/16", 8, 1) # "10.0.1.0/24"
```

### 7.2 `for_each` vs `count`
```hcl
# count -- ordered list, identified by index
resource "azurerm_subnet" "x" {
  count                = 3
  name                 = "snet-${count.index}"
  ...
}

# for_each -- keyed map/set; stable identity even if order changes
resource "azurerm_subnet" "y" {
  for_each             = toset(["api", "web", "data"])
  name                 = "snet-${each.key}"
  ...
}
```

**Prefer `for_each`.** With `count`, deleting an item in the middle re-creates all items after it (because indices shift). `for_each` doesn't.

### 7.3 Dynamic blocks
```hcl
dynamic "ip_restriction" {
  for_each = var.allowed_ips
  content {
    ip_address = ip_restriction.value
    action     = "Allow"
  }
}
```

Use sparingly. Static blocks are clearer when the number is known.

### 7.4 Conditional expressions
```hcl
sku_name = var.environment == "prod" ? "P1v3" : "B1"

# Optional resource
resource "azurerm_application_insights" "ai" {
  count               = var.enable_app_insights ? 1 : 0
  ...
}
# Reference: azurerm_application_insights.ai[0].id  (only when count = 1)
```

### 7.5 Lifecycle
```hcl
resource "azurerm_storage_account" "sa" {
  ...
  lifecycle {
    prevent_destroy       = true   # cannot be destroyed accidentally
    ignore_changes        = [tags["created"]]
    create_before_destroy = true   # for resources that don't allow update-in-place
  }
}
```

`prevent_destroy` on critical state — Storage accounts holding data, prod databases.

---

## 8. State: the most important file

### 8.1 What it stores
```json
{
  "version": 4,
  "terraform_version": "1.8.5",
  "resources": [
    {
      "mode": "managed",
      "type": "azurerm_resource_group",
      "name": "rg",
      "instances": [
        {
          "attributes": { "name": "rg-taskflow-dev", "location": "eastus", "id": "...", ... }
        }
      ]
    }
  ]
}
```

State = Terraform's source of truth. Lose it and Terraform thinks **none of your resources exist** and tries to recreate them.

### 8.2 Local state (default)
File `terraform.tfstate` next to your config. Only OK for solo, throw-away exploration. Never commit it (contains secrets).

### 8.3 Remote state with locking
Use Azure Storage as the backend. Topic 5 covers this in depth; here's the minimum:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateXYZ123"
    container_name       = "tfstate"
    key                  = "taskflow/dev.tfstate"
    use_oidc             = true   # use OIDC from CI
  }
}
```

`terraform init` then prompts to migrate local → remote.

Backend can't use variables. Either hard-code or use `terraform init -backend-config=...`:
```bash
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=sttfstate$RAND" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=taskflow/$ENV.tfstate"
```

### 8.4 State locking
The Azure backend locks via blob lease. While a `plan`/`apply` runs, the state is locked — no concurrent apply can corrupt it. If a job dies you may need:
```bash
terraform force-unlock <LOCK_ID>
```
Use only when sure no one else is running. Otherwise you'll race two applies.

### 8.5 State commands you must know

```bash
terraform state list                         # all resources
terraform state show azurerm_resource_group.rg
terraform state mv old.address new.address   # rename without recreate
terraform state rm azurerm_role_assignment.x # forget without destroying
terraform import azurerm_resource_group.rg /subscriptions/.../rg-x   # adopt existing
```

`state mv` is gold when you refactor (rename a resource, move into a module).

`state rm` is dangerous — Terraform will think the resource doesn't exist and recreate on next apply. Use to disown resources you intentionally hand off.

`terraform import` adopts existing portal-created resources into state. Pair with hand-written config that matches. Then `plan` should show **no changes**.

---

## 9. Plan & Apply, in detail

### 9.1 Plan output

```
# azurerm_storage_account.sa will be created
+ resource "azurerm_storage_account" "sa" {
    + access_tier = (known after apply)
    + name        = "sttaskflowdev123456"
    + ...
  }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Symbols:
- `+` create
- `-` destroy
- `~` update in place
- `-/+` destroy and recreate (force-new)
- `<=` data source read

Anything red (force-recreate) on a production resource = stop and read carefully.

### 9.2 Save plan, then apply

```bash
terraform plan -out tfplan
terraform show -json tfplan > plan.json   # machine-readable for CI checks
terraform apply tfplan
```

### 9.3 Targeting (escape hatch, not normal)
```bash
terraform plan -target=azurerm_storage_account.sa
```
Use for surgical fixes. **Never** in normal CI flow — Terraform should manage the whole graph.

### 9.4 `-replace=` (force recreation)
```bash
terraform apply -replace=azurerm_storage_account.sa
```
Use when a resource is corrupt or you need to bounce it.

---

## 10. CI/CD Integration

Standard pattern (full code in Topic 5):

```
PR opened           → terraform plan          (post diff as PR comment)
PR merged to main   → terraform apply         (with environment gate for prod)
Tag push (optional) → tag-driven prod apply
```

### 10.1 GitHub Actions skeleton

```yaml
name: terraform

on:
  pull_request:
    paths: ['infra/**']
  push:
    branches: [main]
    paths: ['infra/**']

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  plan:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: infra } }
    env:
      ARM_USE_OIDC: 'true'
      ARM_TENANT_ID:       ${{ vars.AZURE_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      ARM_CLIENT_ID:       ${{ vars.AZURE_CLIENT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: '1.8.5' }
      - run: terraform fmt -check -recursive
      - run: terraform init
      - run: terraform validate
      - id: plan
        run: terraform plan -out tfplan -detailed-exitcode
        continue-on-error: true
      - if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const out = require('child_process')
              .execSync('cd infra && terraform show -no-color tfplan')
              .toString();
            const body = '```\n' + out.slice(0, 65000) + '\n```';
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body
            });
      - if: steps.plan.outputs.exitcode == '1'
        run: exit 1   # genuine error

  apply:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: plan
    runs-on: ubuntu-latest
    environment: production
    defaults: { run: { working-directory: infra } }
    env:
      ARM_USE_OIDC: 'true'
      ARM_TENANT_ID:       ${{ vars.AZURE_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      ARM_CLIENT_ID:       ${{ vars.AZURE_CLIENT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: '1.8.5' }
      - run: terraform init
      - run: terraform plan -out tfplan
      - run: terraform apply tfplan
```

### 10.2 PR plan comment — the gold pattern
Reviewers see the exact diff in the PR. They approve "the diff" not "the code". This catches accidents like "renaming a variable that triggers RG recreate" *before* merge.

---

## 11. Drift Detection

Drift = Portal change / Azure auto-change / out-of-band edit makes real world ≠ state.

### 11.1 Detect
```bash
terraform plan -refresh-only
```
Refreshes state from Azure and shows what changed externally.

### 11.2 Schedule it
Run on cron and fail / alert on drift:
```yaml
on: { schedule: [{ cron: '0 4 * * *' }] }
...
- run: terraform plan -refresh-only -detailed-exitcode
  # exit 2 = drift detected; CI fails -> alert
```

### 11.3 Decide policy per resource
- **Reject all drift** (default): every change must come from Terraform.
- **Allow tags/some labels to be Portal-managed**: use `ignore_changes`.
- **Mark as data source**: if Terraform shouldn't own it.

---

## 12. Security Hygiene

| Risk | Fix |
|---|---|
| Secret in `.tf` | Use `sensitive = true`; better, fetch from Key Vault data source |
| State file leaks | Backend in private storage; RBAC-scoped; encrypted at rest |
| `tfstate` committed | `.gitignore` `*.tfstate*`; check git history with `git log --all -- '*.tfstate'` |
| Wide-open service principal | OIDC + RG-scoped role |
| Plan applied by anyone | GH `environment` with required reviewer |
| Provider supply-chain | `.terraform.lock.hcl` committed; `terraform providers lock` for multi-platform |
| `terraform destroy` in CI | Never. Reserve for explicit manual workflow with hard confirmation |

### Plan-time policy: OPA / Conftest / `tfsec`

```bash
tfsec infra/                          # scans for "knownbad" patterns
checkov -d infra/                     # similar
conftest test infra/plan.json -p policy/   # OPA rego policies
```

Common rules:
- Storage public network access must be Disabled.
- VM disks must be encrypted.
- App Services must require HTTPS.
- All resources must have `cost_center` and `owner` tags.

Fail the pipeline on violation. Same as test failures.

---

## 13. Real Mini-Project: TaskFlow Dev Environment

End-to-end `main.tf` that provisions a real dev environment for TaskFlow (mirrors Phase 7's setup). Solutions folder includes the full code; here are the highlights:

```hcl
# Resource Group
resource "azurerm_resource_group" "rg" { ... }

# Storage Account (private, no shared keys)
resource "azurerm_storage_account" "sa" {
  ...
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  blob_properties {
    versioning_enabled       = true
    delete_retention_policy { days = 30 }
  }
}

# Service Bus (Standard, with topic)
resource "azurerm_servicebus_namespace" "sb" {
  sku = "Standard"
}
resource "azurerm_servicebus_topic" "events" {
  name         = "taskflow-events"
  namespace_id = azurerm_servicebus_namespace.sb.id
  enable_partitioning   = true
  requires_duplicate_detection = true
}

# App Service Plan + Linux Web App
resource "azurerm_service_plan" "asp" {
  sku_name = local.is_prod ? "P1v3" : "B1"
}
resource "azurerm_linux_web_app" "api" {
  identity { type = "SystemAssigned" }
  site_config {
    application_stack { dotnet_version = "8.0" }
    health_check_path = "/health"
    minimum_tls_version = "1.2"
  }
  app_settings = {
    AzureWebJobsStorage__credential = "managedidentity"
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai.connection_string
  }
  https_only = true
}

# RBAC: web app identity gets Storage Blob Data Contributor
resource "azurerm_role_assignment" "app_to_storage" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.api.identity[0].principal_id
}
```

---

## 14. Anti-Patterns

| Anti-pattern | Why it bites |
|---|---|
| `terraform apply` from a developer laptop into prod | No audit, no review |
| State in a public bucket | Anyone who finds it owns your infra |
| Bare `terraform apply` (no plan file) | Drift between plan & apply |
| `count` instead of `for_each` for keyed resources | Recreate cascade on delete |
| Hard-coded subscription IDs | Hard to copy env |
| Wildcard tags | Can't filter by env / cost |
| `prevent_destroy = true` on **everything** | Disabling becomes ritual; loses signal |
| `terraform destroy` in CI without `confirm: yes` input | One bad merge = wiped env |
| Mixing app code + IaC in same repo without subdir | Triggers re-plan on every code commit |
| Skipping `lock.hcl` commit | Non-reproducible plans |
| Tests against real Azure on PR | Slow + costs $$$ | Use TF mocks or ephemeral subscription |

---

## Further Reading

- [Terraform Azure provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [HashiCorp — Terraform language](https://developer.hashicorp.com/terraform/language)
- [Microsoft Learn — Terraform on Azure](https://learn.microsoft.com/azure/developer/terraform/)
- [OPA — Conftest for Terraform](https://www.conftest.dev/)
- [tfsec rules](https://aquasecurity.github.io/tfsec/)
- [Gruntwork — A Comprehensive Guide to Terraform](https://blog.gruntwork.io/a-comprehensive-guide-to-terraform-b3d32832baca)
