# infra/modules/

Shared Terraform modules. Each module owns **one** concern.

## Expected modules

| Module | Owns |
|---|---|
| `network`       | Spoke VNet, subnets, NSGs, private endpoints, private DNS links |
| `data`          | Azure SQL or Postgres flexible server, Redis cache, DBs, firewall, MI grants |
| `app`           | Container Apps env, Core API app, BFF app, revisions |
| `observability` | Log Analytics workspace, App Insights (workspace-based), DCRs, diagnostic settings |
| `security`      | Key Vault, user-assigned MI, RBAC assignments, KV secret references |
| `integration`   | APIM, Service Bus namespace + queues/topics, Storage |

## Module template

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}

variable "name_prefix"      { type = string }
variable "location"         { type = string }
variable "resource_group"   { type = string }
variable "tags"             { type = map(string) }

# resources here

output "id" { value = azurerm_xxx.this.id }
```

## Naming
`<kind>-<app>-<env>-<region>` e.g. `kv-taskflow-prod-neu`. Keep ≤ 24 chars where required.

See [Phase 8](../../../08-Phase8-DevOps-CICD-IaC/) and [Phase 10](../../../10-Phase10-Advanced-Security-and-Governance/) for the techniques.
