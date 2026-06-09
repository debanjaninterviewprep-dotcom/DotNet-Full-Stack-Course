# Topic 1: Identity & Access Management (IAM)

## What You'll Learn

How identity works in Azure: **Microsoft Entra ID** (formerly Azure AD), **Azure RBAC**, **Managed Identities**, **Conditional Access**, **PIM**, and the patterns that turn "users exist" into "the right principal has the right access at the right time, audited". By the end you can design IAM for a multi-team Azure subscription and explain every choice.

---

## 1. The Three Identity Surfaces You Care About

There are three different "identity systems" in the Microsoft cloud — confusing them is the #1 source of mistakes.

| Surface | What it controls | Where it lives |
|---|---|---|
| **Microsoft Entra ID** | *Who* the user/app/service is | Tenant-wide directory |
| **Azure RBAC** | *What* an Entra principal can do on Azure resources | Per-subscription / RG / resource |
| **Resource-scoped permissions** | *What* a principal can do *inside* a specific PaaS service (e.g., Key Vault access policies, Storage data-plane RBAC) | Per-resource |

A common bug: granting `Owner` on the resource group and assuming that covers the data-plane (e.g., reading blob contents). It does — through "Storage Blob Data Owner" — *only if* you explicitly assigned the data-plane role. Control-plane (`Owner` on the RG) lets you change settings; data-plane lets you read/write the data inside.

---

## 2. Microsoft Entra ID — The Directory

### Core objects

- **User** — human identity (member or guest).
- **Group** — security group (membership-based authorisation) or M365 group.
- **Application** (App Registration) — definition of an app: redirect URIs, API surfaces, exposed scopes.
- **Service Principal** — the *instance* of an app in your tenant. Authorisation hangs off the SP, not the app object.
- **Managed Identity** — Azure-managed SP whose credentials Azure rotates. No secret you ever see.

```
Application object  ──instantiated as──►  Service Principal in tenant
   (one global)                              (one per tenant)
                                                │
                                                └── target of role assignments
```

### Tenants & directories
- A **tenant** = one Entra directory = one organisation boundary.
- A **subscription** is associated with one tenant; all RBAC principals must come from that tenant (or be **guest** users imported via B2B).
- **Cross-tenant**: B2B (invite a user from another tenant), B2C (consumer identities), Cross-Tenant Access settings (control inbound/outbound trust).

### Authentication factors
- Password (with MFA).
- FIDO2 / Passkey.
- Microsoft Authenticator (phone sign-in, push, OTP).
- Certificate-based authentication.
- Windows Hello for Business.

**Recommended baseline:** passwordless (Passkey / WHfB) for users, certificate auth for high-privilege admins, managed identity for workloads.

---

## 3. Azure RBAC — The Authorisation Layer

### Mental model

```
                Scope (where)
                 ↓
   ┌─────────────────────────────┐
   │ Management Group            │
   │  └ Subscription             │
   │     └ Resource Group        │
   │        └ Resource           │
   └─────────────────────────────┘
                 ↓
        Role definition (what — set of actions)
                 ↓
        Role assignment = Principal (who) + Role (what) + Scope (where)
```

A role assignment **inherits down** the scope hierarchy. Granting `Reader` at the subscription gives Reader on every RG and every resource under it.

### Built-in roles you should actually know

| Role | Purpose | Watch out |
|---|---|---|
| `Owner` | Full control + assign roles | Almost never give this — use PIM |
| `Contributor` | Full control minus assign roles | Default "developer" role; still dangerous in prod |
| `Reader` | Read everything | Safe to give broadly for visibility |
| `User Access Administrator` | Assign roles only | The *backdoor* — guard it tightly |
| `Storage Blob Data Reader/Contributor/Owner` | Data-plane on blobs | Required to read blob contents even if you're Owner control-plane |
| `Key Vault Secrets User/Officer` | Data-plane on KV (when RBAC mode enabled) | Required to read secrets even if Owner |
| `App Configuration Data Reader` | Data-plane on App Config | Same pattern |
| `AcrPull` / `AcrPush` | ACR data-plane | Required for image pulls/pushes |
| `Monitoring Reader/Contributor` | Logs + metrics access | Separate from resource access |

### Custom roles — when

- Built-in role is too broad (e.g., need read on metrics but not on configuration).
- You want to scope very specific actions (e.g., restart App Service only).

```jsonc
{
  "Name": "TaskFlow AppService Restart",
  "Description": "Restart App Services only.",
  "Actions": [
    "Microsoft.Web/sites/restart/action",
    "Microsoft.Web/sites/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read"
  ],
  "NotActions": [],
  "DataActions": [],
  "AssignableScopes": ["/subscriptions/<subId>"]
}
```

Custom roles cost ongoing maintenance (Azure adds new actions; you must keep the role aligned). Prefer composition of built-in roles when possible.

### Role assignment best practices

1. Assign **roles to groups**, not users. Lifecycle through group membership.
2. Assign at the **highest scope that's still least-privilege**. RG > resource when the team owns the RG.
3. **Document `why`** in the role-assignment description (or in IaC comments).
4. Time-bound through **PIM** (next section) for any "elevated" role.
5. **Deny assignments** exist for system-managed resources (e.g., AKS managed RGs) — don't waste time trying to override them.

---

## 4. Privileged Identity Management (PIM)

PIM = **just-in-time, time-bound, approval-gated** access to privileged roles.

The model:
- A user is **eligible** for a role (membership exists but isn't active).
- When they need it, they **activate** the role for up to *N* hours, often with:
  - MFA challenge.
  - Justification text (logged).
  - Optional approver approval.
- After expiry, the role drops back to eligible.

Typical configuration:

| Role | Eligibility | Activation policy |
|---|---|---|
| `Owner` (subscription) | 5 named SREs eligible | 4-hour cap, MFA, ticket reference required, second-approver required |
| `User Access Administrator` | 2 named SREs | Same as above |
| `Contributor` (prod RG) | Platform team | 8-hour cap, MFA, justification only |
| `Owner` (dev sub) | Dev leads | 8-hour, MFA, no approver |

Bonus: **Access reviews** — quarterly automated review of who's eligible for what, with reviewers approving/removing.

> If you don't have PIM enabled in production, that's the single highest-leverage change to make. Standing `Owner` on prod is the worst sin.

---

## 5. Managed Identities — The Workload Story

Two flavours:

| Flavour | Lifetime | Sharing |
|---|---|---|
| **System-assigned** | Tied to the resource — created when enabled, deleted when resource deleted | Cannot be shared |
| **User-assigned** | Standalone resource | Can be assigned to many resources |

**Always prefer managed identity over a client secret or certificate where possible.** No rotation burden. No secret to leak. Federated by Entra.

### Pattern: web app calling Azure SQL using managed identity

1. Enable system-assigned MI on the web app:
   ```hcl
   resource "azurerm_linux_web_app" "api" {
     identity { type = "SystemAssigned" }
   }
   ```
2. Grant the MI access on SQL:
   ```sql
   CREATE USER [api-app-name] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [api-app-name];
   ALTER ROLE db_datawriter ADD MEMBER [api-app-name];
   ```
3. Connection string — no password:
   ```
   Server=tcp:sql-taskflow.database.windows.net,1433;
   Database=TaskFlow;
   Authentication=Active Directory Default;
   ```
4. Code uses `DefaultAzureCredential`:
   ```csharp
   var connStr = $"Server=tcp:{server};Database={db};Authentication=Active Directory Default;";
   ```
   No secret in app config. No vault round-trip. Azure injects the token.

### Federated Workload Identity (the OIDC story)

For workloads **outside Azure** (GitHub Actions, Kubernetes, GitLab, etc.) you don't want a long-lived secret. **Workload Identity Federation** lets an external OIDC token be exchanged for an Azure token.

Setup:
1. Create an Entra App Registration.
2. Add a **federated credential** that trusts a specific issuer + subject:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:org/repo:environment:prod`
3. Assign roles to the SP.
4. In GitHub Actions:
   ```yaml
   permissions: { id-token: write, contents: read }
   steps:
     - uses: azure/login@<SHA>
       with:
         client-id:       ${{ vars.AZURE_CLIENT_ID }}
         tenant-id:       ${{ vars.AZURE_TENANT_ID }}
         subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
   ```

No `AZURE_CREDENTIALS` JSON. No secrets to rotate. The federation is **subject-locked** — only the exact repo + environment can mint tokens.

---

## 6. Conditional Access — The Policy Layer

Conditional Access (CA) sits between authentication and authorisation. It says **"under these conditions, require these controls before granting"**.

Signals it can use:
- User / group.
- App targeted.
- Sign-in risk (Identity Protection).
- Device state (compliant / Hybrid Entra-joined).
- Location (named locations / countries).
- Client app type (browser / mobile / legacy).

Controls it can require:
- MFA.
- Compliant device.
- Approved client app.
- Session control (sign-in frequency, persistent browser).
- Block.

### Baseline policies every tenant should have
- **Require MFA for all users** (with break-glass account exemption).
- **Block legacy authentication** (no IMAP/POP/SMTP basic auth).
- **Require compliant device for admin portals**.
- **Block sign-ins from blocked countries / impossible travel**.
- **Require MFA on any high-risk sign-in**.

### Break-glass accounts
- Two cloud-only `*.onmicrosoft.com` accounts.
- Excluded from MFA / Conditional Access (so you can rescue yourself when CA itself is broken).
- Long, vaulted password split between two people.
- Monitored sign-in alerts.
- Used **only** for emergency recovery.

---

## 7. Groups: Static vs Dynamic

| Type | When |
|---|---|
| **Assigned (static)** | Small, stable groups — admins, named role holders |
| **Dynamic user** | "Membership is whoever has property X" (e.g., `department -eq "Engineering"`) |
| **Dynamic device** | All devices of a class |
| **Privileged Access Group (PIM-managed)** | Time-bound membership |

Dynamic groups are powerful but **lag**: rule evaluation can take minutes. Don't rely on them for time-critical access changes.

---

## 8. Auditing & Monitoring

Three logs you must capture:

1. **Entra ID sign-in logs** — every authentication, with risk score and CA outcome.
2. **Entra ID audit logs** — every directory change (role assignment, group membership, app consent).
3. **Azure Activity Log** — every control-plane operation on Azure resources, including who did it.

All three should be forwarded to a **Log Analytics workspace** via Diagnostic Settings, then queried with KQL:

```kql
// All role assignment changes in the last 7 days
AuditLogs
| where TimeGenerated > ago(7d)
| where OperationName in ("Add member to role", "Remove member from role")
| project TimeGenerated, InitiatedBy, TargetResources, OperationName, Result
```

```kql
// All Owner activations via PIM in the last 30 days
AuditLogs
| where TimeGenerated > ago(30d)
| where OperationName == "Add member to role completed (PIM activation)"
| extend Role = tostring(TargetResources[0].displayName)
| where Role contains "Owner"
| project TimeGenerated, Actor=tostring(InitiatedBy.user.userPrincipalName), Role, Reason=AdditionalDetails
```

Build alerts on:
- Role activation outside business hours.
- High-privilege role assigned outside PIM.
- Failed sign-ins above threshold for a privileged user.
- Risky sign-in detected (Identity Protection).

---

## 9. Identity for App-to-App Calls

When **service A** calls **service B** and both are yours, three patterns:

| Pattern | When |
|---|---|
| **MI of service A → API of service B via OAuth client_credentials** | A talks to B as itself (no user context) |
| **MI of service A → API of B with On-Behalf-Of flow** | A acts on behalf of the original user |
| **Shared key in Key Vault** | Legacy / external system that doesn't support OAuth |

OAuth client_credentials with managed identity:

```csharp
var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(
    new TokenRequestContext(new[] { $"api://{taskflowApiAppId}/.default" }));

http.DefaultRequestHeaders.Authorization =
    new AuthenticationHeaderValue("Bearer", token.Token);
```

On the **API side** (B), validate the token requires:
- Issuer matches your tenant.
- Audience matches your API's `api://` URI.
- `appid` claim is in your allow-list of caller MIs.
- `roles` claim contains expected app role (e.g., `TaskFlow.Tasks.Read`).

---

## 10. Common Anti-Patterns

| Anti-pattern | Why it bites | Better |
|---|---|---|
| Standing `Owner` on production | Insider/credential blast radius | PIM with approval |
| Service principal with client secret in source | Credential leak | Managed identity / federated credentials |
| Granting roles to individual users | Lifecycle nightmare | Roles to groups |
| Custom role for every team | Operations drown in role drift | Reuse built-ins |
| Same admin account for daily work + admin | One phish = total compromise | Separate cloud-only admin accounts |
| Disabling Conditional Access "because it broke MFA once" | Trust falls apart | Use report-only mode first |
| No break-glass accounts | Locked out of own tenant | Two break-glass accounts |
| Trusting `azureRBAC` for data-plane | Owner ≠ read blob | Assign data-plane roles explicitly |
| App registration secrets stored in pipeline secret | Leak via log / fork | OIDC Workload Identity Federation |
| Granting `User Access Administrator` casually | Anyone with this becomes root | Treat as nuclear |
| Long-lived guest accounts from prior projects | Stale access | Quarterly access reviews |
| One subscription for everything | No blast-radius isolation | Subscription per environment (see Topic 5) |

---

## 11. Designing IAM for TaskFlow — A Worked Example

**Scope:** prod subscription with API, SQL, Key Vault, Storage, App Insights.

**Groups (Entra, security):**
- `g-taskflow-platform-admins` — eligible for `Owner` via PIM, 4h, MFA + ticket + approver.
- `g-taskflow-dba` — `SQL DB Contributor` standing on SQL only; PIM for Owner.
- `g-taskflow-devs` — `Reader` standing on prod RG; `Contributor` on dev RG standing.
- `g-taskflow-sre` — `Monitoring Reader` standing; PIM for `Owner` 8h.
- `g-taskflow-secrets-readers` — `Key Vault Secrets User` standing (specific scopes).

**Workload identities:**
- API web app: system-assigned MI.
  - SQL: `db_datareader`, `db_datawriter` on `TaskFlow`.
  - Key Vault: `Key Vault Secrets User`.
  - Storage: `Storage Blob Data Reader` on the `assets` container.
- Background Function: user-assigned MI shared with the API (single trust boundary).
- Deploy pipeline (GitHub): federated credential per environment (dev / staging / prod).

**Conditional Access policies:**
- All users: MFA always.
- All admins: compliant device + sign-in frequency every 12 h.
- Break-glass: excluded from CA, sign-in alerted.

**PIM:**
- Owner / UAA: max 4h, MFA, ticket reference, approval by another platform admin.
- Contributor prod: max 8h, MFA, justification.

**Audit:**
- Entra logs → Log Analytics (90 d hot, 1 y archive).
- Alerts on: any Owner activation, role assignments outside PIM, high-risk sign-ins on admin accounts.

**Reviews:**
- Quarterly access review on all PIM-eligible groups.
- Monthly review of guest accounts.

---

## 12. Mental Model

> Identity is a graph: principals on one side, scopes on the other, roles as edges. Eligibility (PIM) is the time dimension. Everything you can't justify on that diagram — standing Owner, secrets in source, generic admin accounts — is debt waiting to compromise you.

Move to [Practice Problems](./Practice-Problems.md).
