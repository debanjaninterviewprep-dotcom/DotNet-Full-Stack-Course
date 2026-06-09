# Phase 10 Revision Test — Advanced Security & Governance

> Closed-book where you can. Use docs only where noted. **Total 100. Pass 70.**
> Time-box: 4–5 hours across a day. Save answers under `PracticeProblemsSolutions/`.

---

## Section A — Quick-fire (12 × 2 = 24 pts)

Answer in **one or two sentences** each.

1. **Why is RBAC always preferred over classic admin roles**, and which classic roles still exist for legacy reasons?
2. **What does PIM give you that a permanent role assignment does not?** List three benefits.
3. **System-assigned vs user-assigned managed identity — when do you pick which?**
4. **Workload identity federation:** what problem does it solve and which secret material is removed?
5. **In JWT validation, why is `MapInboundClaims = false` recommended?**
6. **OAuth Authorization Code + PKCE:** what does PKCE protect against?
7. **Azure Policy effects:** explain Audit vs Deny vs Modify vs DeployIfNotExists vs AuditIfNotExists in one line each.
8. **Why is Management Group the correct scope for org-wide policy, not the Subscription?**
9. **One ARG query you'd run weekly** — describe its purpose and give the table(s) it queries.
10. **CSPM vs CWP** in Microsoft Defender for Cloud — what's each for?
11. **Why is "one subscription for everything" an anti-pattern** for organisations beyond ~10 engineers?
12. **Azure Lighthouse:** what scenario does it enable and what role does PIM play in the **managing** tenant?

---

## Section B — Diagrams (3 × 5 = 15 pts)

Provide each as a Mermaid diagram in `B-diagrams.md`.

**B1.** **Identity flow** for a user calling a frontend SPA → BFF (`Microsoft.Identity.Web`) → downstream API (`api://taskflow-core`) using **On-Behalf-Of**. Show tokens (id_token / access_token / OBO access_token) and where each is validated.

**B2.** **CAF landing-zone MG hierarchy** for TaskFlow including Platform / Landing Zones / Sandbox / Decommissioned, with at least one subscription under each MG and the policies / RBAC inherited.

**B3.** **Subscription-vending pipeline:** PR → validation → Terraform apply → outputs. Show OIDC trust to GitHub, what gets created in Azure, and the human review gate.

---

## Section C — Bug Hunts (4 × 4 = 16 pts)

For each snippet, identify **what's wrong** and **how to fix it**.

**C1.** JWT validation:
```csharp
options.TokenValidationParameters = new TokenValidationParameters
{
    ValidateIssuer = true,
    ValidIssuer = "https://login.microsoftonline.com/<tenant>/v2.0",
    ValidateAudience = false,
    ValidateLifetime = true
};
```

**C2.** GitHub Actions workflow:
```yaml
on:
  push: { branches: [main] }
permissions:
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - run: az deployment sub create -l northeurope -f infra/main.bicep
```

**C3.** Policy assignment:
```hcl
resource "azurerm_management_group_policy_assignment" "diag" {
  name                 = "diag-law"
  management_group_id  = data.azurerm_management_group.lz.id
  policy_definition_id = data.azurerm_policy_definition.dine_diag.id
  parameters           = jsonencode({ logAnalytics = { value = var.law_id } })
  # no identity, no location
}
```

**C4.** Lighthouse onboarding template:
```jsonc
"authorizations": [
  {
    "principalId": "<your-ops-group>",
    "roleDefinitionId": "8e3af657-a8ff-443c-a75c-2fe8c4bcb635"  // Owner
  }
]
```

---

## Section D — Hands-on (pick **2 of 3** × 12 = 24 pts)

**D1. Token-bound calls.** Implement a minimal API that issues access tokens with **DPoP** binding, and a client that constructs the DPoP proof per request. Validate on the server. Provide repro instructions.

**D2. Policy-as-code.** Author and assign at MG scope: a custom **deny-locations** policy (allow `northeurope`, `westeurope` only) and a **DINE** policy that enables Diagnostic Settings forwarding to a chosen LAW for all `Microsoft.Web/sites`. Deliver Terraform + remediation task evidence.

**D3. Vending demo.** Build a minimal subscription-vending repo: PR creates `requests/<x>.yaml`; on merge, GitHub Actions creates an **Alias** subscription (or simulates via stub if no billing scope available), tags it, peers a tiny spoke VNet to a stub hub VNet, applies a budget. Deliver repo + a run log.

---

## Section E — Cost / Safety / Governance (3 × 5 = 15 pts)

**E1.** Your Defender for Cloud bill jumped 4x in a month. Walk through how you triage **which plan** and **which subscription / resource type** is driving the spike, using ARG and the Defender pricing page.

**E2.** A platform engineer accidentally deleted a `CanNotDelete` lock and then deleted a production storage account. Describe the **detection**, **immediate response**, and **prevention** you'd put in place.

**E3.** An exemption from the "deny public storage" policy was created 11 months ago and is still active. Describe how you'd find such cases, and how you'd structure exemptions so this doesn't repeat.

---

## Section F — Security Audit (6 pts)

You're given access to a fresh subscription. In `F-audit.md`, write the **first 10 checks** you'd run (KQL + portal mix) and what "good" looks like for each. Examples to consider: PIM coverage, MFA on Owners, public IPs, public storage, key vault firewall, NSG 22/3389, Defender plans, MG placement, tag hygiene, diagnostic settings.

---

## Submission Layout

```
PracticeProblemsSolutions/
├── A-quickfire.md
├── B-diagrams.md
├── C-bug-hunts.md
├── D-handson/
│   ├── D1-dpop/         (if chosen)
│   ├── D2-policy/       (if chosen)
│   └── D3-vending/      (if chosen)
├── E-cost-safety.md
└── F-audit.md
```

When done, say **"check"** and I'll mark.
