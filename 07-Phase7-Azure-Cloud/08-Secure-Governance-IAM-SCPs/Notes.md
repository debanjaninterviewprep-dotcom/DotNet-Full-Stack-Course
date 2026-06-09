# Topic 8: Secure Governance — IAM Roles & Service Control Policies

> Topic 1 introduced RBAC at the workload level. This topic zooms out to **organization-wide governance**: how to enforce security and compliance across many subscriptions/accounts, regardless of who owns each one. You'll learn Azure's hierarchy (Management Groups + Policy + Blueprints), the AWS equivalent (Organizations + SCPs), and how to map them to a single security baseline.

---

## 1. Why "Governance" Is a Senior-Engineer Problem

A single team can secure their own subscription with RBAC and a few policies. The problem starts when:

- 50 teams have 50 subscriptions; each "owns" their security.
- Auditors want to prove that *no* subscription stores PII in unsanctioned regions.
- A new compliance regulation (SOC 2, HIPAA, GDPR) lands; you need to enforce it everywhere.
- A pipeline misconfiguration could expose an internal service to the internet.

You need **inheritable**, **non-bypassable** controls — independent of who's an Owner of any one subscription. That's governance.

---

## 2. Azure: The Governance Stack

```
Tenant Root MG
  ├── Platform MG               (shared infra, networking, identity)
  ├── Landing Zones MG
  │     ├── Corp MG             (internal apps)
  │     ├── Online MG           (internet-facing apps)
  │     └── Sandbox MG          (experimental)
  └── Decommissioned MG
```

| Layer | Purpose |
|---|---|
| **Management Group** | Inherit RBAC + Policy down a tree of subscriptions |
| **Azure Policy** | Audit / Deny / Append / DeployIfNotExists rules |
| **Azure Blueprint** *(deprecated, replaced by Bicep + assignments)* | Templated landing zones |
| **Microsoft Entra Conditional Access** | Identity-side controls (MFA, device compliance) |
| **Microsoft Defender for Cloud** | CSPM + workload-protection alerts |
| **Microsoft Sentinel** | SIEM/SOAR |

### Microsoft's reference model: "Cloud Adoption Framework — Enterprise-scale Landing Zones" (Azure Landing Zones)

Azure Landing Zones is the **opinionated, ready-to-deploy** answer:
- Pre-defined MG hierarchy.
- Baseline policies (allowed regions, required tags, deny public IPs, etc.).
- Hub-spoke networking templates.
- Naming/tagging standards.

Use it as a starting point unless you have very strong reasons not to.

---

## 3. Azure Policy in Depth

A policy is a **JSON definition** + an **assignment** to a scope.

### Effects

| Effect | Meaning |
|---|---|
| `audit` | Log a violation; allow the resource |
| `deny` | Block the resource creation/update |
| `append` | Add a property (e.g. tag) automatically |
| `modify` | Modify properties (e.g. add tag, force HTTPS) |
| `deployIfNotExists` (DINE) | Deploy a remediation when conditions met (e.g. enable diag logs) |
| `auditIfNotExists` (AINE) | Audit if a related resource is missing |

### Phase 1 baseline policies for TaskFlow (all clouds eventually)

| Goal | Policy / Effect |
|---|---|
| Allowed regions | Built-in `Allowed locations` (Deny) |
| Allowed SKUs (e.g. Standard storage only) | Built-in `Allowed storage account SKUs` |
| Required tags | `Require a tag and its value` (Deny) |
| Force HTTPS only | `Storage accounts should require secure transfer` (Audit) |
| Enable diag logs | DINE policy emitting to Log Analytics |
| No public network access on Storage | `Storage accounts should disable public network access` (Deny) |
| TLS 1.2 minimum | `Storage minimum TLS version` (Deny < 1.2) |
| RBAC, not access keys | `Storage accounts should have shared key access disabled` (Deny) |
| No public IPs on VMs | Built-in (Deny) |

### Initiative (policy bundle)

A **Policy Initiative** is a named group of policies — easier to assign and report on. Microsoft ships initiatives for ISO 27001, PCI DSS, NIST, CIS Microsoft Azure Foundations Benchmark, etc.

Assign one to your `Landing Zones` MG and you immediately see compliance status across all child subs.

### Compliance reporting

```
az policy state summarize --management-group-name lz-mg
```

The portal blade *Policy → Compliance* gives a heat-map by initiative.

---

## 4. AWS: Organizations + SCPs (the Direct Equivalent)

```
Root OU
  ├── Security OU
  ├── Workloads OU
  │     ├── Prod OU
  │     └── NonProd OU
  └── Sandbox OU
```

- **AWS Organizations** is the multi-account container.
- **Service Control Policies (SCPs)** are *deny-only* policies on OUs/accounts. They limit *what's possible* even for account root.
- **AWS Config + Conformance Packs** provide audit-style compliance similar to Azure Policy `audit` effect.
- **AWS Control Tower** = Azure Landing Zones equivalent.

### SCP example — "Only us-east-1 and eu-west-1"

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllOutsideAllowedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "support:*",
        "trustedadvisor:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "eu-west-1"]
        }
      }
    }
  ]
}
```

### Mapping concepts

| Azure | AWS |
|---|---|
| Management Group | OU (Organizational Unit) |
| Subscription | Account |
| Azure Policy `Deny` | SCP |
| Azure Policy `Audit/DINE` | AWS Config rule + Remediation |
| Initiative | SCP set / Conformance Pack |
| Built-in policy | AWS-managed SCP / AWS Config managed rule |
| Landing Zones | Control Tower |
| Defender for Cloud | Security Hub |

Knowing both vocabularies is now table-stakes for senior cloud engineering.

---

## 5. Identity-Side Governance: Conditional Access & Privileged Identity Management

Even with perfect RBAC, **how a human or app got the token** matters:

- **Conditional Access** (Entra): require MFA, compliant device, named location, low risk.
- **Privileged Identity Management (PIM)**: just-in-time Owner / User Access Administrator, with approval and audit.
- **Access Reviews**: quarterly review of who has what.

Production access without PIM and CA is an audit finding.

---

## 6. The Tag & Naming Spine

Already introduced in Topic 1. At the org level you must enforce them via Policy:

- `environment`, `costCenter`, `owner`, `dataClassification` — required.
- Resource group inherits → resources get them by Policy `append`.
- Cost reports use them. Showback dashboards live or die by tag hygiene.

---

## 7. Defender for Cloud (CSPM)

Cloud Security Posture Management — continuously scans your subscriptions:

- Identifies misconfigurations (public storage, weak TLS, no MFA on owner).
- Prioritizes by **secure score**.
- Suggests one-click remediations.
- Free tier covers basic recommendations; **Defender Plans** add workload protection.

For TaskFlow course: enable **Defender for Cloud Free** at sub-scope. It's free and shows you what an auditor will see.

---

## 8. Microsoft Sentinel (SIEM)

When you outgrow Defender's queries, Sentinel ingests:

- Activity logs from all subs.
- Diagnostic logs from resources.
- Defender alerts.
- Third-party connectors (Okta, AWS, GitHub, M365).

KQL hunting + automated playbooks (Logic Apps) for response. This is where the SOC team lives.

---

## 9. Designing Your TaskFlow Governance Baseline

Even at student scale, practice the pattern:

1. **Naming + tags** — enforced at MG (Topic 1 P6).
2. **Allowed regions** — enforced at MG.
3. **Storage hardening** — initiative covering: shared-key-disabled, no-public-blob, TLS 1.2, secure transfer.
4. **Network hardening** — no public IPs, enforce private endpoints for prod.
5. **Identity hardening** — Conditional Access (MFA required), PIM for sub-Owner.
6. **Logging baseline** — DINE policy: diag logs → Log Analytics on every resource.

You'll write the assignments in P1.

---

## 10. Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Per-subscription bespoke policies | Inherit from MG; per-sub overrides only when justified |
| Owner forever | PIM with time-bound activation |
| Tags as a "best practice" suggestion | Tags enforced by Deny policy |
| Defender ignored "we'll do it later" | Free tier on day one |
| One global Allow-list of regions | Different lists per LZ (Corp vs Online vs Sandbox) |
| Allow workloads to disable diag logs | DINE re-deploys them |

---

## 11. Org-Level Cost Governance

- **Budgets** per subscription with email + automation actions.
- **Cost Anomaly alerts** (ML-based) — detects unexpected spikes.
- **Reserved Instances / Savings Plans** for predictable workloads.
- **Auto-shutdown** policies on dev VMs / non-prod App Services.

A common rule: every non-prod subscription has a **monthly hard cap** by Policy + Logic App (delete VMs, scale to F1).

---

## Further Reading

- [Azure Landing Zones overview](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Policy effects](https://learn.microsoft.com/azure/governance/policy/concepts/effects)
- [AWS Organizations and SCPs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [Conditional Access design](https://learn.microsoft.com/azure/active-directory/conditional-access/plan-conditional-access)
- [Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction)
