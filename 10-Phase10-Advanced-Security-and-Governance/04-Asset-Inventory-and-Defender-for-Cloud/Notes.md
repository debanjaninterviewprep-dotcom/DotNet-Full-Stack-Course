# Topic 4: Azure Asset Inventory & Defender for Cloud

> **Note on the topic title.** The roadmap entry was "Asset Note Integration in Azure" — that reads like a typo. The most useful interpretation in a security-and-governance phase is **Azure asset inventory + Microsoft Defender for Cloud (CSPM/CWP) integration** — knowing every resource you have, attaching security posture to each one, and routing findings to the right teams. If you intended something different (e.g., "Azure Arc integration" for non-Azure assets), tell me and I'll re-author.

## What You'll Learn

How to answer the three foundational governance questions with data, not faith:
1. **What do we have?** (inventory via Azure Resource Graph, ARG)
2. **Is it correctly tagged and owned?** (tag posture)
3. **Is it secure?** (Microsoft Defender for Cloud — Secure Score, recommendations, alerts, regulatory compliance, attack paths)

By the end you can stand up a continuous inventory + security-posture report for TaskFlow and drive remediation through CI/CD.

---

## 1. Why "Asset Inventory" is the First Security Control

You cannot secure what you don't know exists. Cloud sprawl breaks reality in three ways:

- **Shadow resources** — created during incidents, never cleaned up.
- **Untagged resources** — no owner, no cost centre, no environment.
- **Forgotten exposures** — public IPs from a 2024 POC still up.

A reliable inventory + posture pipeline turns that fog into a list with names and remediation owners.

CIS Controls v8 lists "Inventory and Control of Enterprise Assets" as **Control #1** for a reason: every later control assumes you know your assets.

---

## 2. Azure Resource Graph (ARG) — The Single Source of Truth

ARG is a tenant-wide, KQL-queryable index of every Azure resource. It's free, near-real-time, and powerful.

Query everything in your tenant:
```kql
Resources
| project name, type, location, resourceGroup, subscriptionId, tags
| order by type asc, name asc
```

ARG **tables** worth knowing:

| Table | Contents |
|---|---|
| `Resources` | All resources |
| `ResourceContainers` | Subscriptions and resource groups |
| `PolicyResources` | Policy assignments, definitions, exemptions, compliance state |
| `SecurityResources` | Defender for Cloud recommendations, alerts, secure scores |
| `HealthResources` | Resource Health events |
| `AdvisorResources` | Advisor recommendations (cost, performance, reliability, security) |
| `RecoveryServicesResources` | Backup vaults, items, jobs |
| `MaintenanceResources` | Maintenance configurations |
| `AlertsManagementResources` | Active alerts |

### A handful of high-value queries

**Untagged production resources:**
```kql
Resources
| where subscriptionId in ('<prod-sub-id>')
| where isnull(tags.owner) or isnull(tags.costCenter)
| project name, type, resourceGroup, tags
```

**Public IPs by subscription:**
```kql
Resources
| where type =~ 'microsoft.network/publicipaddresses'
| project name, location, resourceGroup, subscriptionId, sku=properties.publicIPAllocationMethod
| summarize count() by subscriptionId
```

**Storage accounts allowing public blob access:**
```kql
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| where properties.allowBlobPublicAccess == true
| project name, resourceGroup, subscriptionId
```

**Resources with NSG rules opening port 22 to the internet:**
```kql
Resources
| where type =~ 'microsoft.network/networksecuritygroups'
| mv-expand rule = properties.securityRules
| where rule.properties.access == 'Allow'
  and rule.properties.direction == 'Inbound'
  and rule.properties.protocol in ('Tcp','*')
  and (rule.properties.destinationPortRange has '22' or rule.properties.destinationPortRanges has '22')
  and rule.properties.sourceAddressPrefix in ('*','0.0.0.0/0','Internet')
| project name, resourceGroup, rule.name, rule.properties.sourceAddressPrefix
```

**Cost drivers (top SKUs in prod):**
```kql
Resources
| where subscriptionId in ('<prod>')
| extend sku = tostring(coalesce(sku.name, properties.sku.name, properties.servicePlan.name))
| summarize count() by type, sku
| order by count_ desc
```

### Querying ARG from code / CI

```powershell
$q = "Resources | where type =~ 'microsoft.storage/storageaccounts' | where properties.allowBlobPublicAccess == true | project id, name, subscriptionId"
$rows = Search-AzGraph -Query $q -First 1000
$rows | Export-Csv -NoTypeInformation -Path public-storage.csv
```

```csharp
using Azure.ResourceManager;
using Azure.ResourceManager.ResourceGraph;
using Azure.ResourceManager.ResourceGraph.Models;

var arm = new ArmClient(new DefaultAzureCredential());
var tenant = arm.GetTenants().First();
var result = await tenant.GetResourcesAsync(new ResourceQueryContent(
    "Resources | summarize count() by type"));
```

---

## 3. Tagging — The Glue Between Inventory and Everything Else

Tags are the universal join key. Without tags:
- Cost reports are anonymous.
- Inventory has no owners.
- Policy targeting fails.
- Incident response can't find the team.

### Mandatory tag set (TaskFlow baseline)

| Tag | Allowed values | Notes |
|---|---|---|
| `owner` | Entra group display name | "Who owns" — group, not person |
| `costCenter` | Finance code | Allow-list of valid codes |
| `environment` | `dev`, `staging`, `prod`, `sandbox` | Free-text strictly rejected |
| `application` | TaskFlow / Other | Cross-app grouping |
| `dataClassification` | `public`, `internal`, `confidential`, `restricted` | Drives policies |

Enforcement (Topic 2): `Modify` policy adds defaults at RG; `Audit` policy on resources without inherited tag.

### Tag inheritance trap
Azure does **not** auto-inherit tags from RG to resource. Use an `inherit_tag` policy (built-in) to propagate at create. Existing resources need a remediation task.

### Tag drift report (run weekly)
```kql
Resources
| extend hasOwner = isnotnull(tags.owner), hasCC = isnotnull(tags.costCenter)
| summarize total=count(), missingOwner=countif(not(hasOwner)), missingCC=countif(not(hasCC)) by subscriptionId, type
| order by missingOwner + missingCC desc
```

---

## 4. Microsoft Defender for Cloud (MDC)

MDC is two things rolled into one:

1. **CSPM (Cloud Security Posture Management)** — continuous assessment of your config against best-practice frameworks (Azure Security Benchmark, CIS, NIST, ISO, PCI). Produces **recommendations** and a **Secure Score**.
2. **CWP (Cloud Workload Protection)** — threat detection at the runtime level (Defender for Servers, SQL, Containers, Storage, App Service, Key Vault, DNS, ARM). Produces **alerts**.

Free tier (Foundational CSPM): inventory + recommendations + ASB.
Paid: **Defender CSPM** (attack-path analysis, agentless scanning, governance) + per-resource-type **Defender plans** (Servers P2, SQL, Containers, etc.).

### The plans you'll actually enable

| Plan | What it covers | Cost driver |
|---|---|---|
| **Defender CSPM** | Attack-path analysis, governance, AppSec | Resource count |
| **Defender for Servers** | EDR on VMs (MDE integration), agentless vuln scan, JIT, FIM | Per VM/hour |
| **Defender for SQL** | Vuln assessment, advanced threat detection on SQL | Per DB/hour |
| **Defender for Storage** | Malware scanning, sensitive-data discovery, anomalous access | Per account |
| **Defender for App Service** | Runtime threat detection on App Service | Per app |
| **Defender for Key Vault** | Anomalous access detection | Per vault |
| **Defender for Containers** | K8s/ACR/AKS coverage; image vuln scan | Per node/image |
| **Defender for Resource Manager** | Detect suspicious control-plane operations | Per sub |
| **Defender for DNS** | Detect DNS-based threats | Per sub |

Enable at the **subscription** level via policy assignment of the built-in **Defender for Cloud** initiatives (one per plan). Then governance rules push recommendations to the right owners.

### Recommendations and Secure Score

Each recommendation is a control with:
- Affected resources.
- Severity (Low / Medium / High).
- Remediation steps (often a one-click fix or `az`/Terraform snippet).
- Linked compliance controls (which ASB / CIS / etc. controls this affects).

**Secure Score** is a weighted percent based on how many recommendations are met. It's the headline metric for executives. Track it weekly.

### Attack-path analysis (Defender CSPM)

Connects findings into **multi-step paths** an attacker could exploit, e.g.:
> Internet-exposed VM → has RCE vuln → can access SQL via private endpoint → SQL contains sensitive data.

Each leg can be remediated. Attack paths cut through the noise of standalone findings.

---

## 5. MDC Configuration as Code

```hcl
# Enable Defender CSPM and Defender for Storage on a subscription
resource "azurerm_security_center_subscription_pricing" "cspm" {
  tier          = "Standard"
  resource_type = "CloudPosture"
  subplan       = "DefenderCspm"   # if applicable
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
  subplan       = "DefenderForStorageV2"
}

# Auto-provision Log Analytics agent / Defender extensions
resource "azurerm_security_center_auto_provisioning" "default" {
  auto_provision = "On"
}

# Workspace settings (where alerts and inventory go)
resource "azurerm_security_center_workspace" "main" {
  scope        = "/subscriptions/<subId>"
  workspace_id = data.azurerm_log_analytics_workspace.platform.id
}

# Contact for alerts
resource "azurerm_security_center_contact" "ops" {
  email               = "secops@taskflow.com"
  phone               = "+1-555-0100"
  alert_notifications = true
  alerts_to_admins    = true
}
```

Configure once per subscription in IaC; never click in the portal.

---

## 6. Querying Security Data with KQL

Defender writes alerts and recommendations to the **Microsoft Sentinel / Log Analytics** workspace it's wired to.

**Top open recommendations by severity:**
```kql
SecurityResources
| where type =~ 'microsoft.security/assessments'
| extend status = tostring(properties.status.code), severity = tostring(properties.metadata.severity)
| where status == 'Unhealthy'
| summarize count() by severity, assessment = tostring(properties.displayName)
| order by count_ desc
```

**Resources missing endpoint protection (EDR):**
```kql
SecurityResources
| where type =~ 'microsoft.security/assessments'
| where properties.displayName has 'Endpoint protection should be installed'
| where properties.status.code == 'Unhealthy'
| project resourceId = tostring(properties.resourceDetails.id)
```

**Active alerts in the last 24 h:**
```kql
SecurityAlert
| where TimeGenerated > ago(24h)
| project TimeGenerated, AlertName, AlertSeverity, CompromisedEntity, Description
| order by AlertSeverity asc, TimeGenerated desc
```

**Recommendations by owner (joining tags):**
```kql
SecurityResources
| where type =~ 'microsoft.security/assessments' and properties.status.code == 'Unhealthy'
| extend rid = tolower(tostring(properties.resourceDetails.id))
| join kind=leftouter (
    Resources
    | project rid = tolower(id), owner = tostring(tags.owner)
) on rid
| summarize Open = count() by owner, severity = tostring(properties.metadata.severity)
```

That last query — pivoted by tag — is how you actually route findings to teams.

---

## 7. Routing & Remediation Loop

A pipeline that closes the loop:

1. **Detect** — daily KQL pull of unhealthy recommendations and alerts.
2. **Attribute** — join with tag-based ownership.
3. **Notify** — open work items in the owner's GitHub repo / Azure DevOps project (auto-generated, with remediation steps).
4. **Track** — workbook shows MTTR per owner per severity.
5. **Auto-remediate** for safe categories (e.g., enable diagnostic settings, install missing agent) — use **Defender Governance rules** that assign a due date, owner, and grace period; then DINE policies handle the fix.
6. **Escalate** at owner-defined SLAs.

### Governance rules (Defender CSPM feature)
- Auto-assign owner from the `owner` tag.
- Auto-set due date based on severity (High: 7 days, Medium: 30, Low: 90).
- Email owners on assignment + before due date.
- Mark as on-time / overdue in Workbook.

---

## 8. Regulatory Compliance Dashboards

MDC ships with regulatory-compliance views that map controls to assessments:

- **Azure Security Benchmark** (Microsoft's own baseline; enabled by default).
- **CIS Microsoft Azure Foundations Benchmark**.
- **NIST SP 800-53 R5**, **NIST SP 800-171**.
- **ISO 27001:2013**.
- **PCI DSS 4**.
- **HIPAA HITRUST**.

Each shows percent compliance, which controls are red, and which assessments roll up.

**Practical use:** pick **one** to optimise (usually ASB or CIS), drive Secure Score up by remediating the highest-weight controls.

---

## 9. Exporting MDC Data

Continuous export of recommendations and alerts:
- **Log Analytics** workspace → KQL queries + alerts (recommended).
- **Event Hub** → SIEM / external tooling.
- **Logic App** → Teams / Slack / Jira.

In IaC:
```hcl
resource "azurerm_security_center_automation" "alerts_to_logic_app" {
  name                = "alerts-to-teams"
  resource_group_name = "rg-platform-secops"
  location            = "northeurope"

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
    type             = "LogicApp"
    resource_id      = azurerm_logic_app_workflow.teams.id
    trigger_url      = "https://..."
  }
}
```

---

## 10. Anti-Patterns

| Anti-pattern | Why it bites | Better |
|---|---|---|
| Free tier everywhere | No threat detection on workloads | Enable per-plan based on data class |
| Defender enabled, no owner on findings | Recommendations rot | Tag-driven routing |
| Manual portal config | Drift after every change | IaC |
| Secure Score as vanity metric | Easy controls inflate it | Track *which* controls drove the gain |
| One LAW for everything | Mixed retention, perms, cost | LAW per tenancy/geo |
| Disabling recommendations to clean Score | False sense of safety | Exempt with justification |
| Ignoring attack paths | Standalone findings drown | Use Attack Path view as priority |
| No regulatory mapping | Audit panic | Pick one framework; track quarterly |
| Email-only alerting | Lost in inbox | Teams / paging integration |
| No tag enforcement | Inventory unowned | Topic 2 policies + remediation |

---

## 11. Putting It Together — Inventory & Posture Report for TaskFlow

A monthly report (auto-generated) covering:

1. **Inventory** — count of resources by type / sub / location; new since last month; deleted since last month.
2. **Tag hygiene** — % resources with all mandatory tags, by sub.
3. **Secure Score** — current %, trend, top 5 controls driving the score.
4. **Open recommendations** — count by severity, owner, age.
5. **Active alerts** — by severity and CompromisedEntity.
6. **Attack paths** — count by criticality.
7. **Compliance** — ASB / CIS % compliance.
8. **Cost-vs-risk** — top recommendations whose remediation reduces both cost and risk (e.g., deleting orphan public IPs).

Built as a Log Analytics **Workbook** with parameters for environment and time range. Exported to PDF for the monthly steering meeting.

---

## 12. Mental Model

> Asset inventory + Defender for Cloud is your **map of the territory**. Tagging is the **legend**. Governance rules and DINE policies are the **road repair crew**. Secure Score is the headline; attack paths are the actionable story. Without all four, security work is guesswork.

Move to [Practice Problems](./Practice-Problems.md).
