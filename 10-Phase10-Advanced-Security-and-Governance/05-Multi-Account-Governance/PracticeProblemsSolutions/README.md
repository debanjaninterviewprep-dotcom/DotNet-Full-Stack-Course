# Solutions — Multi-Account Governance

Drop your work here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-landing-zone-design.md
├── P2-vending/
│   ├── requests/
│   ├── modules/subscription/
│   ├── modules/spoke-network/
│   ├── modules/baseline-rbac/
│   ├── modules/baseline-budget/
│   └── .github/workflows/vend.yml
├── P3-network/
│   ├── hub/
│   ├── spoke-a/
│   ├── spoke-b/
│   └── verify.md
├── P4-central-logging/
│   ├── law.tf
│   ├── policy-dine-diag.tf
│   ├── cross-workspace.kql
│   └── screenshots/
├── P5-finops/
│   ├── tag-policy.tf
│   ├── cost-export.tf
│   ├── allocation-rule.json
│   ├── budgets.tf
│   └── report.png
├── P6-lighthouse/
│   ├── onboarding.json
│   ├── pim-managing.ps1
│   └── screenshots/
└── P7-reports/
    ├── 01-inventory.kql
    ├── 02-tag-hygiene.kql
    ├── 03-secure-score.kql
    ├── 04-cost-vs-budget.kql
    ├── 05-policy-noncompliance.kql
    └── trigger.tf
```

Tell me **"check"** when done.

---

## P2 Starter — vending request schema

`requests/_schema.yaml`:
```yaml
team:            { type: string, required: true }
env:             { type: string, enum: [dev, staging, prod, sandbox] }
cost_center:     { type: string, pattern: '^CC-\d{4}$' }
region:          { type: string, enum: [northeurope, westeurope, eastus2] }
connectivity:    { type: string, enum: [corp, online, sandbox, none] }
data_class:      { type: string, enum: [public, internal, confidential, restricted] }
sla:             { type: string, enum: [bronze, silver, gold] }
```

`requests/taskflow-prod.yaml`:
```yaml
team:            taskflow
env:             prod
cost_center:     CC-1042
region:          northeurope
connectivity:    corp
data_class:      confidential
sla:             gold
```

`.github/workflows/vend.yml` (sketch):
```yaml
on:
  pull_request:
    paths: [requests/*.yaml]
  push:
    branches: [main]
    paths: [requests/*.yaml]
permissions:
  contents: read
  id-token: write
  pull-requests: write
jobs:
  vend:
    runs-on: ubuntu-latest
    environment: ${{ github.event_name == 'push' && 'platform-prod' || 'platform-plan' }}
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
      - uses: azure/login@a65d910e8af852a8061c627c456678983e180302
        with:
          client-id:       ${{ vars.AZURE_CLIENT_ID }}
          tenant-id:       ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_BILLING_SUBSCRIPTION_ID }}
      - run: |
          for req in requests/*.yaml; do
            terraform -chdir=runner init
            terraform -chdir=runner ${{ github.event_name == 'push' && 'apply -auto-approve' || 'plan -no-color' }} -var-file=../$req
          done
```

## P3 Starter — hub Terraform

```hcl
resource "azurerm_resource_group" "hub" { name = "rg-platform-hub-${var.region}" location = var.region }

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.region}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "fw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_firewall" "hub" {
  name                = "afw-hub-${var.region}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.fw.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}
```

## P4 Starter — `cross-workspace.kql`

```kql
union
  workspace("/subscriptions/<plat>/resourceGroups/rg-platform-management/providers/microsoft.operationalinsights/workspaces/law-platform").AppRequests,
  workspace("/subscriptions/<plat>/resourceGroups/rg-platform-management/providers/microsoft.operationalinsights/workspaces/law-emea").AppRequests
| where TimeGenerated > ago(1h)
| extend env = tostring(Properties.environment)
| summarize Requests = count() by env, bin(TimeGenerated, 5m)
| render timechart
```

## P6 Starter — `onboarding.json`

```jsonc
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "mspOfferName":        { "type": "string", "defaultValue": "TaskFlow Platform Engineering Ops" },
    "mspOfferDescription": { "type": "string", "defaultValue": "Delegated platform operations." },
    "managedByTenantId":   { "type": "string" },
    "authorizations":      { "type": "array" }
  },
  "resources": [
    {
      "type": "Microsoft.ManagedServices/registrationDefinitions",
      "apiVersion": "2022-10-01",
      "name": "[guid(parameters('mspOfferName'))]",
      "properties": {
        "registrationDefinitionName": "[parameters('mspOfferName')]",
        "description":                "[parameters('mspOfferDescription')]",
        "managedByTenantId":          "[parameters('managedByTenantId')]",
        "authorizations":             "[parameters('authorizations')]"
      }
    },
    {
      "type": "Microsoft.ManagedServices/registrationAssignments",
      "apiVersion": "2022-10-01",
      "name": "[guid(parameters('mspOfferName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.ManagedServices/registrationDefinitions/', guid(parameters('mspOfferName')))]"
      ],
      "properties": {
        "registrationDefinitionId":
          "[resourceId('Microsoft.ManagedServices/registrationDefinitions/', guid(parameters('mspOfferName')))]"
      }
    }
  ]
}
```
