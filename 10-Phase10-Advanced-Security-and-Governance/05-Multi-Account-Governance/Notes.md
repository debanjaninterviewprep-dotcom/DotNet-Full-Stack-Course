# Topic 5: Multi-Account Governance

> In AWS the unit is an **account**; in Azure the unit is a **subscription**. This topic uses "multi-subscription" interchangeably with "multi-account" — they map 1:1 in practice.

## What You'll Learn

How to design and operate **dozens to hundreds of Azure subscriptions** as a single coherent platform: Microsoft's **Cloud Adoption Framework (CAF) Landing Zones**, subscription vending, networking topology (hub-spoke / vWAN), centralised logging, FinOps with tag-driven chargeback, cross-tenant scenarios (Azure Lighthouse), and the operating model that keeps it all sane.

---

## 1. Why You End Up with Many Subscriptions

You hit subscription boundaries fast:
- **Quotas** — per-subscription core, VM-family, storage-account, public-IP limits. One workload exhausts another's quota.
- **Blast radius** — accidental delete in prod takes out dev too.
- **Billing** — finance wants per-team, per-app cost separation.
- **Compliance** — different regulatory regimes can't mix.
- **Different tenants** — partner / customer environments via cross-tenant access.

A typical mid-sized org ends with **15–60 subs**. Without governance it's chaos. With a landing zone, it's a platform.

---

## 2. Cloud Adoption Framework (CAF) Landing Zone

Microsoft's reference architecture for a multi-subscription Azure tenancy. Conceptually:

```
Tenant Root MG
├── Platform MG
│   ├── Identity        sub:  Entra Connect, AD DS, jump boxes
│   ├── Management      sub:  Log Analytics, Automation, Backup, Sentinel
│   └── Connectivity    sub:  Hub VNet, Firewall, ExpressRoute, Private DNS
├── Landing Zones MG
│   ├── Corp            sub:  Internal apps (private only)
│   └── Online          sub:  Internet-facing apps
├── Sandbox MG
│   └── Sandbox-*       subs: Developer experimentation, auto-delete
└── Decommissioned MG
    └── Decom-*         subs: Awaiting deletion; deny most operations
```

Each level holds **policy assignments**, **RBAC**, and **budgets** appropriate to scope.

### Landing-zone subscription
Each application or team gets one or more **landing-zone subscriptions** — pre-baked with:
- Mandatory tags enforced.
- Diagnostic settings forwarded.
- Defender plans enabled.
- Networking peered to the hub.
- Identity (group) for the team with PIM roles.
- A baseline budget + alerts.

The team only opens an RG and starts deploying.

### ALZ (Azure Landing Zones) accelerator
Microsoft ships a **Terraform/Bicep accelerator** (`Azure/terraform-azurerm-avm-ptn-alz`) that creates the whole MG hierarchy + baseline policies + log analytics + automation. Start from there; don't roll your own.

---

## 3. Subscription Vending

The pattern that turns "ask, wait, get" into "self-service in 15 minutes".

### Inputs (a small request form)
- Team name → maps to Entra group.
- Cost centre.
- Environment (dev/staging/prod/sandbox).
- Region.
- Connectivity (corp / online / sandbox).
- Data classification.

### What the vending pipeline does
1. Create the subscription (via **EA / MCA billing scope** API).
2. Move it under the correct MG.
3. Tag the subscription (`owner`, `costCenter`, `application`, `env`, `dataClassification`).
4. Apply RBAC: team's Entra group → `Reader` (or `Contributor` for non-prod) standing, `Owner` via PIM with approval.
5. Set the budget and alerts.
6. Peer the spoke VNet to the hub (if connectivity selected).
7. Enable required Defender plans.
8. Output a "welcome" artifact: subscription ID, network info, sample IaC repo, links to dashboards.

### Implementing with Terraform

```hcl
module "subscription" {
  source = "Azure/subscription-vending/azurerm"
  # ...
  subscription_alias_name      = "lz-${var.team}-${var.env}"
  subscription_display_name    = "TaskFlow ${title(var.team)} ${upper(var.env)}"
  subscription_billing_scope   = var.billing_scope
  subscription_management_group_id = local.mg_per_env[var.env]
  subscription_tags = local.standard_tags
}

module "network" {
  source = "./modules/spoke-network"
  count  = var.connectivity != "none" ? 1 : 0
  hub_vnet_id      = var.hub_vnet_id
  spoke_cidr       = var.spoke_cidr
  subscription_id  = module.subscription.subscription_id
}

module "rbac"     { source = "./modules/baseline-rbac"     /* ... */ }
module "budget"   { source = "./modules/baseline-budget"   /* ... */ }
module "defender" { source = "./modules/mdc-baseline"      /* ... */ }
```

A pull request opens → human reviews → merge runs the pipeline → subscription is live with everything wired.

---

## 4. Network Topology

Two common patterns:

### Hub-and-spoke
- One hub VNet in the **Connectivity** sub holds Azure Firewall / Front Door / Private DNS / VPN Gateway / ExpressRoute.
- Each landing-zone sub has a spoke VNet peered to the hub.
- All egress flows through the firewall.

Pros: explicit, well-understood, granular routing.
Cons: VNet peering quotas; design effort per region.

### Azure Virtual WAN (vWAN)
- Managed hubs in chosen regions.
- Spokes connect via VNet connections.
- vWAN handles inter-region routing.

Pros: less manual peering, multi-region built-in.
Cons: cost; some advanced firewall flows still need Azure Firewall.

### Private DNS strategy
- Centralised **Azure Private DNS** zones in the Connectivity sub.
- Each spoke uses the same resolver IPs (custom DNS on VNet pointing to hub DNS resolvers).
- Private endpoints register into the central zones automatically via DNS Resolver inbound endpoints.

---

## 5. Centralised Logging & Monitoring

Anti-pattern: each sub has its own LAW; no cross-sub queries.
Pattern: **central LAW(s) by geography / sovereignty + DCR routing**.

```
            ┌────────────────────────────────────┐
            │  Log Analytics Workspace (per geo) │
            │   in Management subscription       │
            └────────────────────────────────────┘
                ▲                          ▲
         Diagnostic                  Defender
         Settings                    forwarding
            │                          │
   ┌────────┴──────┐         ┌─────────┴────────┐
   │ All resources │         │ All subscriptions │
   │ in all subs   │         │ (security data)   │
   └───────────────┘         └──────────────────┘
```

Use **Data Collection Rules (DCR)** to route logs from agents/resources to specific tables in the right LAW.

KQL `union` across workspaces:
```kql
union
  workspace("/subscriptions/.../platform-law").AppRequests,
  workspace("/subscriptions/.../emea-law").AppRequests
| where TimeGenerated > ago(1h)
| summarize count() by Bin = bin(TimeGenerated, 5m)
```

For Defender, configure each sub's MDC to write to the same LAW so security data is co-located.

---

## 6. Sentinel for Multi-Sub SIEM (optional)

If you need cross-sub threat hunting and case management:
- Enable **Microsoft Sentinel** on the central LAW.
- Connect data sources: AAD, Defender for Cloud, Office 365, third-party.
- Author **Analytics Rules** for tenant-wide threats.
- Build **Workbooks** that span subs.

Sentinel adds cost on top of LAW ingestion. Decide whether you need SIEM, or if Defender + LAW alerts suffice.

---

## 7. FinOps in Multi-Sub

Without governance, costs surprise everyone.

### Cost Management primitives
- **Budgets** per sub / RG / MG / resource — emails on threshold and on forecast.
- **Cost Allocation rules** redistribute shared costs based on tags or usage.
- **Cost Analysis** views (by tag, RG, service, region).
- **Pricing simulator** for what-ifs.

### Tag-driven chargeback (the foundation)
1. Enforce `costCenter` tag (Topic 2 policy: Modify default; Audit unassigned).
2. Enable **tag inheritance** at sub → RG → resource where possible.
3. Configure **cost allocation rules** to redistribute shared platform costs (Hub firewall, central LAW) by spoke utilisation.
4. Export Cost Management data daily to Storage; pipe to Power BI / Fabric.

### Reservations & savings plans
- **Reserved Instances** (1y/3y) for steady-state VMs / SQL.
- **Azure Savings Plan for Compute** for flexible workloads.
- Buy at the **enrollment / billing account** level so any sub benefits.
- Track **utilisation** — unused reservations are pure loss.

### Anomaly detection
- Use built-in Cost anomaly alerts.
- KQL on `Resources` + `consumption` data for fast-rising line items.

---

## 8. Cross-Tenant Scenarios

Sometimes the org isn't one tenant. Two main scenarios:

### Azure Lighthouse — manage another tenant's subs
- Customer onboards your managing tenant by deploying an ARM template that grants RBAC at the chosen scope to your tenant's principals (groups / SPs).
- Your operators sign in to **their own tenant** and see the customer's subs.
- Strong **delegated access**, audited in both tenants.
- Standard tool for MSPs and platform engineering teams operating multiple tenants.

```jsonc
// ARM template snippet for onboarding
{
  "type": "Microsoft.ManagedServices/registrationDefinitions",
  "properties": {
    "managedByTenantId": "<your-managing-tenant>",
    "authorizations": [
      { "principalId": "<your-ops-group>", "roleDefinitionId": "<Contributor-id>" }
    ],
    "registrationDefinitionName": "TaskFlow Ops Access"
  }
}
```

### Entra B2B / Cross-Tenant Access
- Invite guest users from another tenant.
- Configure **Cross-Tenant Access Settings** to allow/block specific inbound/outbound trust per tenant.
- Use **Cross-Tenant Synchronisation** for ongoing user provisioning when the relationship is long-term.

### EA vs MCA billing
- **Enterprise Agreement (EA)** — legacy enterprise billing.
- **Microsoft Customer Agreement (MCA)** — modern. Hierarchy: billing account → billing profile → invoice section → subscription.
- New sub creation API differs between the two; the vending module needs the right `billing_scope`.

---

## 9. Operating Model

### Roles (the platform-engineering "T")
- **Platform team**: owns MGs, policies, networking, identity, billing. Provides paved roads.
- **Application teams**: consume landing zones; own their RGs.
- **SecOps**: owns Defender, Sentinel, secure-score targets, incident response.
- **FinOps**: owns budgets, chargeback, reservations.

### The "paved road"
Application teams should be able to deploy a new workload following:
1. Pick a starter template (from `templates/web-api`, `templates/spa`, etc.).
2. Open a PR in their own repo.
3. CI deploys to the landing-zone subs they own.

Everything else (tags, networking, logging, alerts, secrets) is **baked in**. Deviating requires a security review.

### Documentation & ADRs
- Per-team README in their landing-zone repo.
- Tenant-wide ADRs in a `platform` repo with PR-based change control.
- A self-serve **catalog** (Backstage, Azure Developer CLI templates, Service Catalog) for new projects.

### Exceptions process
Time-bound. Owner. Ticket. Review at quarterly steering committee.

---

## 10. The Required Reports

Build these once; they pay back forever:

| Report | Cadence | Audience |
|---|---|---|
| Sub inventory + owner | Weekly | Platform team |
| Tag hygiene % | Weekly | Platform + workload owners |
| Secure Score per sub | Weekly | SecOps + workload owners |
| Cost vs budget | Daily / Weekly | FinOps + workload owners |
| Reserved instance utilisation | Monthly | FinOps |
| Drift report (policy non-compliance) | Daily | Platform |
| Backup & DR posture | Weekly | SRE |
| Identity hygiene (stale guest, standing privileged) | Monthly | SecOps |

---

## 11. Anti-Patterns

| Anti-pattern | Why it bites | Better |
|---|---|---|
| "One subscription, many RGs" forever | Quota walls; blast radius; billing chaos | Landing zones from the start |
| Hand-clicked subs | No baseline; drift on day one | Vending pipeline |
| Same hub across regions | Latency + noisy neighbours | Per-geo hubs |
| One LAW for the whole world | Sovereignty issues; cost; latency | Per-geo LAW |
| Letting teams choose tags ad-hoc | Reports are noise | Mandatory tag set, policy-enforced |
| Allowing internet egress without firewall | Data exfil; ungoverned dependencies | Force-tunnel via hub firewall |
| Cost data buried in portal | Surprises at month end | Daily export + Power BI |
| Lighthouse with broad standing roles | Tenant compromise blast | PIM in managing tenant too |
| "Decommission later" sandbox subs | Cost leak forever | Auto-delete or "Decommissioned" MG with deny |
| No quarterly review of structure | Drift accumulates | Quarterly review of MGs / subs / costs |

---

## 12. TaskFlow Reference Layout

```
Tenant
├── Platform MG
│   ├── sub-platform-identity        (Entra Connect)
│   ├── sub-platform-management      (Central LAW, Sentinel, Automation, Backup)
│   └── sub-platform-connectivity    (Hub VNet, Firewall, Private DNS, ExpressRoute)
├── Landing Zones MG
│   ├── Corp MG
│   │   ├── sub-corp-taskflow-prod
│   │   └── sub-corp-taskflow-nonprod
│   └── Online MG
│       └── sub-online-taskflow-public
├── Sandbox MG
│   └── sub-sandbox-<dev>            (auto-delete @ 14 days)
└── Decommissioned MG
```

Pipelines:
- ALZ accelerator deploys the MGs + baseline policies + central LAW.
- Subscription-vending pipeline opens new subs as PRs.
- Application teams deploy into their landing-zone subs through their own CI/CD (Phase 8).

---

## 13. Mental Model

> Multi-account governance is product management for your cloud platform. Customers are app teams; product is the paved road; SLAs are uptime, security, and self-service speed. Everything you build twice in two subs should become a module; every recurring exception is a backlog item; every painful manual step is a vending pipeline waiting to be written.

Move to [Practice Problems](./Practice-Problems.md).
