# Solutions — Azure Asset Inventory & Defender for Cloud

Put your work here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-inventory/
│   ├── inventory.kql
│   └── workbook.json
├── P2-tag-drift/
│   ├── tag-drift-report.md
│   ├── remediate-tags.ps1
│   └── tickets.csv
├── P3-mdc-iac/
│   ├── modules/mdc-baseline/
│   ├── envs/prod/
│   ├── envs/nonprod/
│   ├── before-score.png
│   └── after-score.png
├── P4-governance-rule/
│   ├── rule.json
│   └── screenshots/
├── P5-teams-routing/
│   ├── logic-app.json (or .tf)
│   ├── automation-rule.json
│   └── teams-card.png
├── P6-by-owner/
│   ├── by-owner.kql
│   ├── scheduled-query.tf
│   └── sample-output.csv
└── P7-monthly-report/
    ├── workbook.json
    └── report.pdf
```

Tell me **"check"** when done.

---

## P1 Starter — `inventory.kql`

```kql
// 1) Count per type per subscription
Resources
| summarize Count = count() by subscriptionId, type
| order by Count desc

// 2) Created in last 30 days (using activity log + ARG cross-ref)
Resources
| where todatetime(properties.createdTime) > ago(30d)
| project name, type, resourceGroup, subscriptionId, created = todatetime(properties.createdTime)

// 3) Missing owner tag
Resources
| where isnull(tags.owner) or tostring(tags.owner) == ""
| project name, type, resourceGroup, subscriptionId

// 4) Missing costCenter tag
Resources
| where isnull(tags.costCenter)
| project name, type, resourceGroup, subscriptionId

// 5) Public IPs by sub
Resources
| where type =~ 'microsoft.network/publicipaddresses'
| summarize PIPs = count() by subscriptionId

// 6) Storage accounts with public blob access
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| where properties.allowBlobPublicAccess == true
| project name, resourceGroup, subscriptionId
```

## P3 Starter — `modules/mdc-baseline/main.tf`

```hcl
variable "subscription_id"   { type = string }
variable "workspace_id"      { type = string }
variable "security_contact"  { type = string }
variable "plans" {
  type = map(string) # name -> tier (Standard|Free)
  default = {
    CloudPosture     = "Standard"
    StorageAccounts  = "Free"
    SqlServers       = "Free"
    AppServices      = "Free"
    KeyVaults        = "Free"
    Containers       = "Free"
    Arm              = "Standard"
    Dns              = "Standard"
  }
}

resource "azurerm_security_center_subscription_pricing" "plan" {
  for_each      = var.plans
  tier          = each.value
  resource_type = each.key
}

resource "azurerm_security_center_auto_provisioning" "default" {
  auto_provision = "On"
}

resource "azurerm_security_center_workspace" "ws" {
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = var.workspace_id
}

resource "azurerm_security_center_contact" "ops" {
  email               = var.security_contact
  alert_notifications = true
  alerts_to_admins    = true
}
```

## P6 Starter — `by-owner.kql`

```kql
SecurityResources
| where type =~ 'microsoft.security/assessments'
| where properties.status.code == 'Unhealthy'
| extend rid = tolower(tostring(properties.resourceDetails.id))
| extend severity = tostring(properties.metadata.severity)
| join kind=leftouter (
    Resources | project rid = tolower(id), owner = tostring(tags.owner)
) on rid
| summarize Open = count() by owner = coalesce(owner, "unassigned"), severity
| evaluate pivot(severity, sum(Open))
| order by High desc
```

## P5 Starter — Defender continuous-export automation (Terraform)

```hcl
resource "azurerm_security_center_automation" "high_alerts_to_teams" {
  name                = "high-alerts-to-teams"
  resource_group_name = azurerm_resource_group.secops.name
  location            = azurerm_resource_group.secops.location

  scopes = [data.azurerm_subscription.prod.id]

  source {
    event_source = "Alerts"
    rule_set {
      rule {
        property_path  = "Severity"
        operator       = "Equals"
        property_type  = "String"
        expected_value = "High"
      }
    }
  }

  action {
    type        = "LogicApp"
    resource_id = azurerm_logic_app_workflow.teams_alerts.id
    trigger_url = azurerm_logic_app_workflow.teams_alerts.access_endpoint
  }
}
```

## P7 Starter — Workbook layout

```
Section 1: Inventory delta (this month vs last) — Counter tiles + table.
Section 2: Tag hygiene — Donut chart per sub.
Section 3: Secure Score — Time-series line.
Section 4: Top 5 open recommendations — Sorted table with severity badges.
Section 5: Active High alerts (24h) — Table with link to portal.
Section 6: Attack paths — Counter + drill-down table.
Section 7: Compliance % (CIS) — Bar chart of control sections.
Section 8: Quick win — Static markdown box; auto-suggest based on cost-saving recs.
```
