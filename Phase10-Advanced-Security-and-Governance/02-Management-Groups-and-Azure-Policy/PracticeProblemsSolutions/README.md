# Solutions — Management Groups & Azure Policy

Drop your answers here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-mg-design.md
├── P2-policies/
│   ├── allowed-locations.tf
│   ├── required-tags.tf
│   ├── initiative.tf
│   ├── assignment.tf
│   └── demo/
├── P3-audit-then-deny/
│   ├── policy-audit.tf
│   ├── policy-deny.tf
│   ├── triage.csv
│   └── screenshots/
├── P4-dine-diag-settings/
│   ├── policy.tf
│   ├── assignment.tf
│   ├── remediation.md
│   └── screenshots/
├── P5-locks/
│   ├── locks.tf
│   └── lock-removal-runbook.md
├── P6-ci/
│   ├── .github/workflows/policy.yml
│   ├── .pre-commit-config.yaml
│   └── pr-comment.png
└── P7-exemption-lifecycle/
    ├── exemption.tf
    ├── expiring-exemptions.kql
    ├── .github/workflows/exemption-monitor.yml
    └── PR_TEMPLATE.md
```

Tell me **"check"** when done.

---

## P2 Starter — `allowed-locations.tf`

```hcl
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "taskflow-allowed-locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "TaskFlow - Allowed locations"
  description  = "Restrict resource creation to allowed locations."

  parameters = jsonencode({
    allowedLocations = {
      type     = "Array"
      metadata = { displayName = "Allowed locations", strongType = "location" }
      defaultValue = ["northeurope", "westeurope"]
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "location", notIn = "[parameters('allowedLocations')]" },
        { field = "location", notEquals = "global" },
        { field = "type",     notEquals = "Microsoft.AzureActiveDirectory/b2cDirectories" }
      ]
    }
    then = { effect = "deny" }
  })
}
```

## P2 Starter — `required-tags.tf`

```hcl
locals { required_tags = ["owner", "costCenter", "environment"] }

resource "azurerm_policy_definition" "required_tag" {
  for_each     = toset(local.required_tags)
  name         = "taskflow-required-tag-${each.value}"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "TaskFlow - Require tag ${each.value} on RGs"

  parameters = jsonencode({
    defaultValue = { type = "String", metadata = { displayName = "Default value" }, defaultValue = "unspecified" }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type",            equals = "Microsoft.Resources/subscriptions/resourceGroups" },
        { field = "tags['${each.value}']", exists = "false" }
      ]
    }
    then = {
      effect = "modify"
      details = {
        roleDefinitionIds = ["/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"] # Contributor
        operations = [{ operation = "add", field = "tags['${each.value}']", value = "[parameters('defaultValue')]" }]
      }
    }
  })
}
```

## P4 Starter — DINE policy assignment with MI

```hcl
resource "azurerm_management_group_policy_assignment" "diag_dine" {
  name                 = "diag-dine"
  management_group_id  = data.azurerm_management_group.workloads.id
  policy_definition_id = data.azurerm_policy_definition.diag_dine_appservice.id   # built-in or custom
  enforce              = true
  location             = "northeurope"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_dine.id]
  }

  parameters = jsonencode({
    logAnalytics = { value = data.azurerm_log_analytics_workspace.platform.id }
  })
}

# Least-privilege roles for the policy MI
resource "azurerm_role_assignment" "policy_law_contrib" {
  scope                = data.azurerm_log_analytics_workspace.platform.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_user_assigned_identity.policy_dine.principal_id
}
resource "azurerm_role_assignment" "policy_monitoring_contrib" {
  scope                = data.azurerm_management_group.workloads.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_user_assigned_identity.policy_dine.principal_id
}
```

## P5 Starter — `lock-removal-runbook.md`

```markdown
# Removing a CanNotDelete lock

1. File a ticket in the SECURITY queue with:
   - resource ID
   - reason
   - rollback plan
   - approver (must be a second platform-admin)
2. After approval, the on-call platform engineer runs:
   ```
   az lock delete --name do-not-delete-prod \
                  --resource-group rg-taskflow-prod
   ```
3. Perform the destructive operation.
4. Re-apply the lock by running `terraform apply` for the locks module.
5. Close the ticket with the audit-log link of the lock removal + recreation.
```

## P6 Starter — `.github/workflows/policy.yml`

```yaml
name: policy-iac
on:
  pull_request:
  push: { branches: [main] }

permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  plan:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: hashicorp/setup-terraform@b9cd54a3c349d3f38e8881555d616ced269862dd
      - uses: azure/login@a65d910e8af852a8061c627c456678983e180302
        with:
          client-id:       ${{ vars.AZURE_CLIENT_ID }}
          tenant-id:       ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: terraform fmt -check
      - run: terraform init && terraform validate
      - run: terraform plan -no-color -out tfplan | tee plan.txt
      - uses: actions/github-script@60a0d83039c74a4aee543508d2ffcb1c3799cdea
        with:
          script: |
            const fs = require('fs');
            const body = "```\n" + fs.readFileSync('plan.txt','utf8').slice(0, 60000) + "\n```";
            await github.rest.issues.createComment({
              issue_number: context.issue.number, owner: context.repo.owner, repo: context.repo.repo, body
            });

  apply:
    needs: plan
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: hashicorp/setup-terraform@b9cd54a3c349d3f38e8881555d616ced269862dd
      - uses: azure/login@a65d910e8af852a8061c627c456678983e180302
        with:
          client-id:       ${{ vars.AZURE_CLIENT_ID }}
          tenant-id:       ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: terraform init && terraform apply -auto-approve
```

## P7 Starter — `expiring-exemptions.kql`

```kql
PolicyResources
| where type =~ "microsoft.authorization/policyexemptions"
| extend expires = todatetime(properties.expiresOn)
| where isnotnull(expires) and expires between (now() .. now() + 30d)
| project name, scope = id, expires, owner = tostring(properties.description)
| order by expires asc
```
