---
applyTo: "infra/**/*.tf,infra/**/*.tfvars"
---

# Terraform style for TaskFlow

- Provider: `hashicorp/azurerm ~> 4.0`. Pin version.
- Resource names: `<kind>-<app>-<env>-<region>` (e.g. `kv-taskflow-prod-neu`).
- Always set `tags = merge(local.standard_tags, { ... })`.
- Use modules under `infra/modules/`; one module = one concern.
- Variables: typed, with description and validation where sensible.
- Outputs: minimal, named clearly.
- Never commit `.tfvars` for prod; use Key Vault or environment variables.
- Use `for_each` over `count` unless ordering matters.
- Use `azurerm_role_assignment` with `principal_id` from MI; no inline policies.
- All identities are user-assigned MI; rotate via Terraform, not by hand.
