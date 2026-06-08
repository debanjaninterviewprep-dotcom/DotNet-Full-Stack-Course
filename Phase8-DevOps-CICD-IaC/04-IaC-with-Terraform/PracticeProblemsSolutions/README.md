# Topic 4 — Solutions Workspace

```
PracticeProblemsSolutions/
├── README.md
├── P1-stack/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── .gitignore
├── P2-stack/                     (or extend P1)
├── P3-stack/
├── P4-kv.tf
├── P4-import.md
├── P5-drift-policy.md
├── P6-terraform.yml
├── P6-pr-walkthrough.md
└── P7-policy/
    ├── tags.rego
    ├── tls.rego
    └── public-blob.rego
```

---

## Starter: `P1-stack/providers.tf`

```hcl
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
  }
}

provider "azurerm" {
  features {}
}
```

## Starter: `P1-stack/variables.tf`

```hcl
variable "project" {
  type        = string
  default     = "taskflow"
  description = "Short project name, 4-12 lowercase letters"
  validation {
    condition     = can(regex("^[a-z]{4,12}$", var.project))
    error_message = "project must be 4-12 lowercase letters."
  }
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

## Starter: `P1-stack/main.tf`

```hcl
locals {
  base = "${var.project}-${var.environment}"
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base}"
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

  blob_properties {
    versioning_enabled       = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
}
```

## Starter: `P1-stack/outputs.tf`

```hcl
output "resource_group_name"  { value = azurerm_resource_group.rg.name }
output "storage_account_name" { value = azurerm_storage_account.sa.name }
output "blob_endpoint"        { value = azurerm_storage_account.sa.primary_blob_endpoint }
```

## Starter: `P1-stack/.gitignore`

```
# Local state files (NEVER commit)
*.tfstate
*.tfstate.*
.terraform/
crash.log

# Variable files often contain secrets
*.tfvars
!example.tfvars
```

---

## Starter: `P6-terraform.yml`

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

env:
  TF_VERSION: '1.8.5'
  ARM_USE_OIDC: 'true'
  ARM_TENANT_ID:       ${{ vars.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
  ARM_CLIENT_ID:       ${{ vars.AZURE_CLIENT_ID }}

jobs:
  plan:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: infra } }
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: '${{ env.TF_VERSION }}' }
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
            const { execSync } = require('child_process');
            const out = execSync('cd infra && terraform show -no-color tfplan').toString();
            const body = '### Terraform plan\n\n```hcl\n' + out.slice(0, 60000) + '\n```';
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body
            });

      - if: steps.plan.outputs.exitcode == '1'
        run: exit 1

  apply:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: plan
    runs-on: ubuntu-latest
    environment: production
    defaults: { run: { working-directory: infra } }
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: '${{ env.TF_VERSION }}' }
      - run: terraform init
      - run: terraform plan -out tfplan
      - run: terraform apply tfplan
```

---

## Starter: `P7-policy/tags.rego`

```rego
package terraform.tags

required := {"project", "environment", "cost_center", "managed_by"}

deny[msg] {
  rc := input.resource_changes[_]
  startswith(rc.type, "azurerm_")
  rc.change.actions[_] != "no-op"
  tags := object.get(rc.change.after, "tags", {})
  missing := required - {k | tags[k]}
  count(missing) > 0
  msg := sprintf("Resource %s is missing required tags: %v", [rc.address, missing])
}
```

---

## Submission

Tell me **"check P3"** (or a range) for graded review.
