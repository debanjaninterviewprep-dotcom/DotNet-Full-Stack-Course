# Solutions — Identity & Access Management

Drop your work here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-iam-design.md
├── P2-mi-migration/
│   ├── before/
│   ├── after/
│   ├── iac.diff
│   └── verification.log
├── P3-oidc-federation/
│   ├── setup.ps1
│   ├── deploy.yml
│   ├── success.png
│   └── rejected.png
├── P4-pim/
│   ├── configure-pim.ps1
│   ├── activation-audit.png
│   └── access-review.png
├── P5-conditional-access/
│   ├── policies/
│   │   ├── 01-require-mfa.json
│   │   ├── 02-block-legacy.json
│   │   ├── 03-admin-compliant-device.json
│   │   ├── 04-priv-sign-in-frequency.json
│   │   └── 05-block-countries.json
│   └── rollout-plan.md
├── P6-alerts/
│   ├── alerts.kql
│   └── runbooks.md
└── P7-app-to-app/
    ├── TaskFlow.ServiceA/
    ├── TaskFlow.ServiceB/
    └── screenshots/
```

Tell me **"check"** when done.

---

## P3 Starter — `setup.ps1`

```powershell
param(
    [Parameter(Mandatory)] [string] $AppName = "taskflow-ci",
    [Parameter(Mandatory)] [string] $GitHubOrg,
    [Parameter(Mandatory)] [string] $GitHubRepo,
    [string[]] $Environments = @("dev","staging","prod")
)

# 1) App registration + SP
$app = az ad app create --display-name $AppName | ConvertFrom-Json
$sp  = az ad sp create --id $app.appId | ConvertFrom-Json

# 2) Federated credentials, one per environment, subject-locked
foreach ($env in $Environments) {
    $cred = @{
        name      = "$AppName-$env"
        issuer    = "https://token.actions.githubusercontent.com"
        subject   = "repo:$($GitHubOrg)/$($GitHubRepo):environment:$env"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress
    az ad app federated-credential create --id $app.appId --parameters $cred | Out-Null
    Write-Host "Created federation for $env"
}

# 3) Grant roles per env at appropriate scope (example: Contributor on the env RG)
foreach ($env in $Environments) {
    $rg = "rg-taskflow-$env"
    az role assignment create `
        --assignee $sp.id `
        --role "Contributor" `
        --scope (az group show -n $rg --query id -o tsv) | Out-Null
}

Write-Host "AZURE_CLIENT_ID = $($app.appId)"
Write-Host "AZURE_TENANT_ID = $(az account show --query tenantId -o tsv)"
```

## P3 Starter — `deploy.yml`

```yaml
name: deploy
on:
  push: { branches: [main] }

permissions:
  contents: read
  id-token: write          # OIDC

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod      # PR runs cannot satisfy the subject 'repo:org/repo:environment:prod'
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
      - uses: azure/login@a65d910e8af852a8061c627c456678983e180302       # v2.2.0
        with:
          client-id:       ${{ vars.AZURE_CLIENT_ID }}
          tenant-id:       ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: az webapp deploy -g rg-taskflow-prod -n app-taskflow-prod --src-path ./publish.zip
```

## P4 Starter — `configure-pim.ps1`

```powershell
# Requires Microsoft.Graph PowerShell module and Privileged Access Reader/Admin role.
Connect-MgGraph -Scopes "RoleManagementPolicy.ReadWrite.AzureADGroup","PrivilegedAccess.ReadWrite.AzureResources"

# Example: tighten activation policy for 'Owner' on subscription <subId>
$scope = "/subscriptions/<subId>"
$roleDefinitionId = (Get-AzRoleDefinition -Name "Owner").Id

# (Pseudo) update the role management policy:
#  - Activation max 4h
#  - Require MFA
#  - Require justification
#  - Require ticket info
#  - Require approval (assign approver group)
# Use Update-MgPolicyRoleManagementPolicy* cmdlets per the latest Graph schema.

Write-Host "Configure approver group, MFA, and 4h cap via the Graph cmdlets per the latest schema."
```

## P6 Starter — `alerts.kql`

```kql
// 1) Role assignment outside PIM
AuditLogs
| where TimeGenerated > ago(15m)
| where OperationName == "Add member to role"
| where AdditionalDetails !has "PIM activation"
| project TimeGenerated, Actor=tostring(InitiatedBy.user.userPrincipalName),
          Target=tostring(TargetResources[0].userPrincipalName),
          Role=tostring(TargetResources[2].displayName)

// 2) Owner activation outside business hours (07:00-20:00 local; adjust TZ)
AuditLogs
| where TimeGenerated > ago(1h)
| where OperationName has "PIM activation" and TargetResources[0].displayName contains "Owner"
| extend hour = datetime_part("Hour", TimeGenerated)
| where hour < 7 or hour >= 20

// 3) Federated credential change
AuditLogs
| where TimeGenerated > ago(1h)
| where OperationName in ("Add federated identity credentials", "Update federated identity credentials")
| project TimeGenerated, Actor=tostring(InitiatedBy.user.userPrincipalName),
          App=tostring(TargetResources[0].displayName), AdditionalDetails

// 4) Service principal credential added
AuditLogs
| where TimeGenerated > ago(1h)
| where OperationName == "Add service principal credentials"
| project TimeGenerated, Actor=tostring(InitiatedBy.user.userPrincipalName),
          App=tostring(TargetResources[0].displayName)

// 5) Sign-in from never-seen country for this UPN in 90d
let lookback = 90d;
let recent = SigninLogs
| where TimeGenerated > ago(15m)
| where ResultType == 0
| project UserPrincipalName, Country=tostring(LocationDetails.countryOrRegion), TimeGenerated;
let history = SigninLogs
| where TimeGenerated between (ago(lookback) .. ago(15m))
| where ResultType == 0
| summarize KnownCountries = make_set(tostring(LocationDetails.countryOrRegion)) by UserPrincipalName;
recent
| join kind=leftouter history on UserPrincipalName
| where isnull(KnownCountries) or not(set_has_element(KnownCountries, Country))
```

## P7 Starter — Service B token validation

```csharp
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.Authority = $"https://login.microsoftonline.com/{tenantId}/v2.0";
        o.TokenValidationParameters = new()
        {
            ValidIssuer   = $"https://login.microsoftonline.com/{tenantId}/v2.0",
            ValidAudience = $"api://{serviceBAppId}",
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true
        };
    });

builder.Services.AddAuthorization(o =>
{
    o.AddPolicy("TasksRead", p => p.RequireClaim("roles", "TaskFlow.Tasks.Read"));
});

app.MapGet("/tasks", () => Results.Ok(new { ok = true }))
   .RequireAuthorization("TasksRead");
```
