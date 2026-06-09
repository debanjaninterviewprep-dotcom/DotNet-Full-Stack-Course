# Topic 5: Terraform Modules & State Management

> **Goal:** Move from a single root config to a **modular, multi-environment** Terraform codebase with **remote state**, **state isolation per environment**, and clean module composition. By the end you can design modules other teams will reuse and operate state safely under concurrent CI runs.

---

## 1. Why Modules Exist

A module is just a directory of `.tf` files. **Every Terraform configuration is already a module — the "root module".** What we call *modules* in practice are reusable child modules.

You reach for modules when you find yourself:
- Copy-pasting 200 lines of the same resources across environments.
- Wanting one team to consume infrastructure others provide (Storage team owns the storage module; app teams consume it).
- Versioning a slice of your infra so consumers can adopt changes on their own schedule.

Modules ≠ classes. Don't over-abstract. A good module is one *coherent capability* (a network, a web app + its identity + its policy, a storage account with the right defaults), not a generic helper.

---

## 2. Module Anatomy

```
modules/
└── storage-account/
    ├── README.md            # auto-generate with terraform-docs
    ├── versions.tf          # required Terraform / provider versions
    ├── variables.tf         # inputs
    ├── main.tf              # resources
    ├── outputs.tf           # outputs
    └── examples/
        └── minimal/
            ├── main.tf
            └── README.md
```

### 2.1 `versions.tf`
```hcl
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```
A child module should **declare** required providers but not configure them — the root module owns provider config.

### 2.2 `variables.tf` (interface contract)
```hcl
variable "name" {
  type        = string
  description = "Globally unique storage account name (3-24 lowercase alphanumeric)"
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" { type = string }
variable "location"            { type = string }

variable "replication_type" {
  type    = string
  default = "LRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Invalid replication_type."
  }
}

variable "soft_delete_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

### 2.3 `main.tf`
```hcl
resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags                            = var.tags

  blob_properties {
    versioning_enabled       = true
    delete_retention_policy { days = var.soft_delete_days }
    container_delete_retention_policy { days = var.soft_delete_days }
  }
}
```

### 2.4 `outputs.tf`
```hcl
output "id"                    { value = azurerm_storage_account.this.id }
output "name"                  { value = azurerm_storage_account.this.name }
output "primary_blob_endpoint" { value = azurerm_storage_account.this.primary_blob_endpoint }
```

### 2.5 Consuming the module
```hcl
module "storage" {
  source  = "../../modules/storage-account"

  name                = "sttaskflowdev${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  replication_type    = "ZRS"
  tags                = local.common_tags
}

# Reference outputs:
# module.storage.id
# module.storage.primary_blob_endpoint
```

---

## 3. Module Design Principles

1. **One clear capability per module.** A `web-app` module shouldn't also create the network it depends on; take that as input.
2. **Inputs flow in; outputs flow out.** No side effects through globals.
3. **Sensible defaults that produce a *secure* baseline.** Public access off, TLS 1.2, no shared keys.
4. **Validation at the boundary.** Catch bad inputs at plan time, not deep inside Azure.
5. **Stable interface.** Renaming an input variable is a breaking change for every consumer.
6. **Document the contract.** README with usage example, inputs, outputs (use `terraform-docs`).
7. **Test the example.** The `examples/` folder must run `terraform validate` clean and ideally apply in CI.

### When NOT to make a module
- A single resource with no policy decisions baked in. Just inline it.
- A resource you'll use exactly once.
- A wrapper around an existing module that just renames variables.

---

## 4. Where Modules Live

| Source | Syntax | When to use |
|---|---|---|
| Local path | `source = "../modules/x"` | Within a monorepo |
| Git | `source = "git::https://github.com/org/tf-modules.git//modules/x?ref=v1.2.0"` | Cross-repo, no registry |
| Registry (public) | `source = "Azure/avm-res-storage-storageaccount/azurerm"` | Battle-tested community modules |
| Registry (private) | `source = "app.terraform.io/yourorg/x/azurerm"` | If you use Terraform Cloud |
| ACR / OCI | `source = "oci://acrtaskflow.azurecr.io/modules/x:1.2.0"` | New (TF 1.10+); promising |

### 4.1 Pinning sources

Always pin **by tag or SHA**, never `main`:
```hcl
source = "git::https://github.com/taskflow/tf-modules.git//modules/storage-account?ref=v1.4.2"
```
A moving target in `source` is identical in danger to a moving GitHub Action tag (Topic 2 §14).

### 4.2 Azure Verified Modules (AVM)
Microsoft now ships [AVM](https://aka.ms/AVM) — opinionated, supported Terraform modules following an enterprise pattern. Worth checking before writing your own:
```hcl
module "sa" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.4"
  # ...
}
```

---

## 5. Composition Patterns

### 5.1 Flat composition (most common)
Root module instantiates several leaf modules:

```
root/
├── module "network"       (source = ../../modules/network)
├── module "storage"       (source = ../../modules/storage-account)
├── module "service_bus"   (source = ../../modules/service-bus)
└── module "api"           (source = ../../modules/web-app)
```

Wire them by passing outputs as inputs:
```hcl
module "api" {
  source = "../../modules/web-app"
  storage_account_id = module.storage.id
  subnet_id          = module.network.app_subnet_id
}
```

### 5.2 Stack / layer composition
Multiple **root** modules each owning a "layer" with separate state:
- `00-platform/` — shared MGs, subs, networks.
- `10-data/` — databases, queues.
- `20-app/` — app services, container apps.

Lower layers expose outputs via `terraform_remote_state`:
```hcl
data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate123"
    container_name       = "tfstate"
    key                  = "platform/dev.tfstate"
  }
}

resource "azurerm_linux_web_app" "api" {
  service_plan_id = data.terraform_remote_state.platform.outputs.shared_plan_id
}
```

Use when ownership is split across teams (platform team owns layer 0, app team owns layer 2).

### 5.3 Nested modules
Modules call modules. Allowed but use sparingly — debugging gets harder with each nesting level. Two levels max.

---

## 6. State Management Deep Dive

Topic 4 introduced state. Now we make it production-grade.

### 6.1 Remote state in Azure Storage

Bootstrap (chicken-and-egg: you provision the state storage *outside* of state):

```bash
RG=rg-tfstate
LOC=eastus
SA=sttfstate$RANDOM$RANDOM   # must be globally unique
CONTAINER=tfstate

az group create -n $RG -l $LOC
az storage account create \
  -g $RG -n $SA -l $LOC \
  --sku Standard_GRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false
az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Storage Blob Data Contributor" \
  --scope $(az storage account show -g $RG -n $SA --query id -o tsv)
az storage container create \
  --name $CONTAINER \
  --account-name $SA \
  --auth-mode login
```

Enable:
- **Versioning** + **soft delete**: recover a clobbered tfstate.
- **Private endpoint**: state never traverses public internet.
- **RBAC** (`Storage Blob Data Contributor`): no shared keys.
- **Lock** the container with a resource lock if you really want to belt-and-suspenders it.

### 6.2 Backend config

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate12345"
    container_name       = "tfstate"
    key                  = "taskflow/dev.tfstate"   # path inside container
    use_oidc             = true
    use_azuread_auth     = true
  }
}
```

Backend block **cannot interpolate variables**. Two options:

**Option A — Partial config + `-backend-config`:**
```hcl
terraform { backend "azurerm" {} }
```
```bash
terraform init \
  -backend-config="resource_group_name=$RG" \
  -backend-config="storage_account_name=$SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=taskflow/${ENV}.tfstate"
```

**Option B — Backend config files:**
```bash
terraform init -backend-config="backend-dev.hcl"
```
With `backend-dev.hcl`:
```hcl
resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstate12345"
container_name       = "tfstate"
key                  = "taskflow/dev.tfstate"
```

Prefer Option B in CI: one file per env, easy to swap.

### 6.3 State isolation strategies

**Pick exactly one and stick with it.**

#### A — One state file per environment (key prefix)
```
tfstate/
├── taskflow/dev.tfstate
├── taskflow/staging.tfstate
└── taskflow/prod.tfstate
```
- Pros: small blast radius; clear ownership.
- Cons: must promote changes through environments (you want that anyway).
- **Use this.** It's the default for serious teams.

#### B — One state file per layer × environment
```
tfstate/
├── platform/dev.tfstate
├── platform/prod.tfstate
├── data/dev.tfstate
└── app/dev.tfstate
```
- Pros: even smaller blast radius; team autonomy.
- Cons: more cross-state wiring (`terraform_remote_state`).
- Use when teams own layers.

#### C — Terraform workspaces
```bash
terraform workspace new dev
terraform workspace select dev
```
- Single backend, multiple state files keyed by workspace name.
- Pros: minimal extra config.
- Cons: easy to apply to the wrong workspace ("did I switch?"). All envs share the **same** code and provider versions — bad for production sanity.
- HashiCorp themselves now say: **don't use workspaces for separating environments**. Use them for ephemeral previews or sandboxes.

### 6.4 State locking

Azure Storage backend uses **blob leases** for locking:
- `terraform plan`/`apply` acquires lease.
- Other runs block until released.
- If a process dies, the lease holds for ~60s then becomes acquirable, **or** stays stuck — in which case:

```bash
terraform force-unlock <LOCK_ID>
```

Only use `force-unlock` when **certain** no other process is touching state. Otherwise two concurrent applies can both write — corruption.

### 6.5 Sensitive data in state

State stores resource attributes. Many of those include secrets (storage account keys, randomly-generated passwords). Therefore:

- **Encrypt at rest** (Azure Storage does this; verify CMK if compliance requires).
- **Encrypt in transit** (HTTPS to backend; TLS 1.2+).
- **RBAC-only access** — humans should not read state directly.
- **Never commit** `*.tfstate*` files.
- **Avoid resources whose state contains long-lived secrets**. Prefer Key Vault references; rotate via separate process.

---

## 7. State Operations You Will Need

### 7.1 Inspect
```bash
terraform state list
terraform state show module.storage.azurerm_storage_account.this
```

### 7.2 Move (refactor without recreate)
After renaming a resource or moving it into a module:
```bash
terraform state mv \
  azurerm_storage_account.sa \
  module.storage.azurerm_storage_account.this
```
Plan after move should show **no changes**. If it does, you have a config drift.

### 7.3 Remove (disown without destroying)
```bash
terraform state rm module.legacy.azurerm_resource_group.old
```
Use when retiring a resource Terraform shouldn't manage anymore. Don't run plan/apply blindly afterwards — Terraform may "re-create" it.

### 7.4 Import (adopt without recreate)
```bash
terraform import module.kv.azurerm_key_vault.this \
  /subscriptions/.../providers/Microsoft.KeyVault/vaults/kv-x
```

Or declaratively (TF 1.5+):
```hcl
import {
  to = module.kv.azurerm_key_vault.this
  id = "/subscriptions/.../vaults/kv-x"
}
```

The `import {}` block runs as part of `apply` and creates state. The CLI command is one-shot; the block is reproducible. Prefer the block.

### 7.5 Refresh
```bash
terraform plan -refresh-only        # update state from real world
```
Drift detection (Topic 4 §11). Do not confuse with full plan.

### 7.6 Replace
```bash
terraform apply -replace=module.api.azurerm_linux_web_app.this
```
Force destroy & recreate. Use when a resource is broken or rotating something that requires re-creation.

---

## 8. Refactoring Safely

When changing module structure:

1. **Run `terraform plan` first.** If you see destroys, stop and think.
2. **Use `terraform state mv` (or `moved {}` blocks)** to preserve resources across renames.

```hcl
moved {
  from = azurerm_storage_account.sa
  to   = module.storage.azurerm_storage_account.this
}
```

The `moved {}` block (TF 1.1+) is reproducible — every consumer migrating the module gets the same state move applied automatically.

3. **Plan again.** Should now show *no destroys*. If it does, your `moved` is wrong.
4. **Apply.** Resources are unchanged; their state addresses moved.

---

## 9. Multi-Environment Project Layout

Pick one of these. Document the choice in `README.md`.

### 9.1 Folder-per-env (recommended for most teams)

```
infra/
├── modules/
│   ├── network/
│   ├── storage-account/
│   └── web-app/
└── envs/
    ├── dev/
    │   ├── main.tf
    │   ├── backend.hcl
    │   └── terraform.tfvars
    ├── staging/
    │   ├── main.tf
    │   ├── backend.hcl
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        ├── backend.hcl
        └── terraform.tfvars
```

- Pros: explicit, no "wrong workspace" risk; per-env provider versions allowed.
- Cons: some duplication; mitigated by modules + a thin root `main.tf` per env.

### 9.2 Single root + tfvars

```
infra/
├── modules/
├── main.tf
├── variables.tf
├── env/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── backend/
    ├── dev.hcl
    ├── staging.hcl
    └── prod.hcl
```
- Pros: less duplication.
- Cons: must pass `-var-file` and `-backend-config` every time — easy to mix up.

### 9.3 Workspaces (only for ephemerals)

```bash
terraform workspace new pr-1234     # ephemeral preview env
terraform apply -var "instance_count=1"
# tear down at PR close
terraform workspace select default
terraform workspace delete pr-1234
```

---

## 10. CI/CD with Modules & Per-Env State

Pipeline triggers a matrix run, one per environment:

```yaml
strategy:
  matrix:
    environment: [dev, staging, prod]
steps:
  - run: terraform init -backend-config=envs/${{ matrix.environment }}/backend.hcl
    working-directory: infra
  - run: terraform plan -var-file=envs/${{ matrix.environment }}/terraform.tfvars -out tfplan
    working-directory: infra
```

But for **applies**, do them in sequence with approval between envs:

```yaml
jobs:
  apply-dev:        { environment: dev,        ... }
  apply-staging:    { environment: staging,    needs: apply-dev, ... }
  apply-prod:       { environment: production, needs: apply-staging, ... }
```

This guarantees staging applies only if dev applied; prod only if staging did.

---

## 11. Module Versioning & Release Workflow

Treat modules like libraries:

1. Modules live in their own repo (`taskflow/tf-modules`).
2. Each module folder has a `CHANGELOG.md`.
3. Tag with **semver**:
   - `v1.0.0` initial
   - `v1.1.0` add input (backward-compat)
   - `v1.1.1` bug fix
   - `v2.0.0` rename/remove input (breaking)
4. Consumers pin: `?ref=v1.4.2`.
5. Automation:
   - PR runs `terraform validate` + `tflint` + `tfsec` on every module.
   - `examples/` folder validated and `plan`-tested in CI.
   - On merge with conventional commits, `release-please` bumps version + tags.

---

## 12. Testing Modules

Terraform's own test framework (TF 1.6+) lives in `tests/*.tftest.hcl`:

```hcl
run "minimal" {
  module {
    source = "./examples/minimal"
  }

  assert {
    condition     = output.id != ""
    error_message = "storage account id should be set"
  }
}

run "validation_blocks_public_access" {
  command = plan

  variables {
    public_network_access_enabled = true
  }

  expect_failures = [
    var.public_network_access_enabled
  ]
}
```

Run:
```bash
terraform test
```

For deeper integration tests, [terratest](https://terratest.gruntwork.io/) (Go) actually applies, asserts via SDK, then destroys. Heavier but unmatched for catching real-world failures.

---

## 13. Cost Visibility in IaC

You can't keep finance happy if every PR is a wild card.

- Use **`infracost`** in CI to comment $$ delta on every PR:
  ```yaml
  - uses: infracost/actions/setup@v3
    with: { api-key: ${{ secrets.INFRACOST_API_KEY }} }
  - run: infracost breakdown --path infra --format json --out-file infracost.json
  - run: infracost comment github --path infracost.json --repo "$GITHUB_REPOSITORY" --pull-request "$PR" --behavior update
  ```
- Tag everything with `cost_center` and `owner` (Phase 7 Topic 1).
- Set Azure **Budgets + Action Group** alerts on each RG.

---

## 14. Anti-Patterns Specific to Modules & State

| Anti-pattern | Why it hurts |
|---|---|
| One mega-module per environment | No reuse; cannot promote changes per capability |
| Module that wraps a single resource with no defaults added | Adds indirection, no value |
| Module that calls `provider`/`backend` | Breaks consumer ability to control them |
| Source `?ref=main` | Same supply-chain risk as floating Action tags |
| Workspaces for prod separation | Easy to apply to wrong env |
| One giant state file | Long plan times; concurrency bottleneck |
| Shared `tfstate` storage between unrelated subscriptions | Blast radius too big |
| Storing state on a public bucket | Game over |
| Editing state JSON by hand | Almost always wrong; use `state mv`/`state rm` |
| `terraform destroy` from a developer machine | No review; no audit |

---

## 15. Reference: TaskFlow's Module Catalogue

By end of Phase 8 you should have these modules:

| Module | Owns | Inputs (key) | Outputs (key) |
|---|---|---|---|
| `network` | VNet, subnets, NSGs | `address_space`, `subnet_map` | `vnet_id`, `subnet_ids` |
| `storage-account` | Storage + private endpoint | `name`, `replication_type` | `id`, `primary_blob_endpoint` |
| `service-bus` | Namespace, topics, subs | `topics` (map) | `namespace_id`, `topic_ids` |
| `web-app` | App Service Plan + Linux Web App + MI + AI | `sku`, `plan_id` | `default_hostname`, `principal_id` |
| `function-app` | Function App + Storage + MI | `runtime`, `plan_id` | `default_hostname` |
| `key-vault` | KV + access policies / RBAC | `tenant_id`, `enable_rbac` | `id`, `vault_uri` |
| `redis` | Redis + private endpoint | `sku`, `capacity` | `host`, `port` |

Each in `taskflow/tf-modules/modules/<name>/`, versioned independently.

---

## Further Reading

- [HashiCorp — Module composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [Azure Verified Modules](https://aka.ms/AVM)
- [Terraform `moved` blocks](https://developer.hashicorp.com/terraform/language/moved)
- [Terraform `import` blocks](https://developer.hashicorp.com/terraform/language/import)
- [Terraform test framework](https://developer.hashicorp.com/terraform/language/tests)
- [Infracost](https://www.infracost.io/)
- [Terragrunt (if you outgrow plain TF)](https://terragrunt.gruntwork.io/)
