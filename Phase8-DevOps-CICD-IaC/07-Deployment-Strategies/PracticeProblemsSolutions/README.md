# Topic 7 — Solutions Workspace

```
PracticeProblemsSolutions/
├── README.md
├── P1-api/
│   ├── Program.cs
│   └── Checks/
├── P1-test.md
├── P2-infra/   (TF: app service + staging-slot + sticky settings)
├── P2-deploy.yml
├── P2-results.md
├── P3-canary.yml
├── P3-canary-runbook.md
├── P4-api/
├── P4-flags.json
├── P4-flag-lifecycle.md
├── P5-migrations/
├── P5-migration-plan.md
├── P6-alert.json
├── P6-rollback.yml
├── P6-demo.md
├── P7-containerapp.bicep
├── P7-deploy.sh
└── P7-comparison.md
```

---

## Starter: `P1-api/Program.cs`

```csharp
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration["SqlConnection"]!, name: "sql", tags: ["ready"])
    .AddAzureBlobStorage(
        new Uri(builder.Configuration["BlobUri"]!),
        new Azure.Identity.DefaultAzureCredential(),
        name: "blob", tags: ["ready"])
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: ["live"]);

var app = builder.Build();

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate     = c => c.Tags.Contains("live"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate     = c => c.Tags.Contains("ready"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapGet("/", () => "TaskFlow API");
app.Run();
```

---

## Starter: `P2-deploy.yml`

```yaml
name: deploy-prod-blue-green

on:
  workflow_dispatch:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    env:
      RG:   rg-taskflow-prod
      APP:  app-taskflow-prod
      SLOT: staging-slot
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '8.0.x' }
      - run: dotnet publish src/TaskFlow.Api -c Release -o publish

      - uses: azure/login@v2
        with:
          client-id:       ${{ vars.AZURE_CLIENT_ID }}
          tenant-id:       ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy to staging-slot
        uses: azure/webapps-deploy@v3
        with:
          app-name: ${{ env.APP }}
          slot-name: ${{ env.SLOT }}
          package: ./publish

      - name: Wait for staging-slot to be ready
        run: |
          host="${APP}-${SLOT}.azurewebsites.net"
          for i in {1..30}; do
            code=$(curl -s -o /dev/null -w "%{http_code}" "https://$host/health/ready")
            if [ "$code" = "200" ]; then echo "Ready"; exit 0; fi
            sleep 10
          done
          echo "Slot never went ready"; exit 1

      - name: Smoke test (staging-slot)
        run: |
          host="${APP}-${SLOT}.azurewebsites.net"
          curl -fsSL "https://$host/api/version" | tee /tmp/v.json
          grep -q '"status":"ok"' /tmp/v.json

      - name: Swap
        run: |
          az webapp deployment slot swap \
            -g $RG -n $APP --slot $SLOT --target-slot production

      - name: Verify production
        run: |
          for i in {1..10}; do
            code=$(curl -s -o /dev/null -w "%{http_code}" "https://${APP}.azurewebsites.net/health/ready")
            if [ "$code" = "200" ]; then exit 0; fi
            sleep 5
          done
          echo "Prod not ready after swap; consider re-swap"; exit 1
```

---

## Starter: `P3-canary-runbook.md`

```markdown
# Canary Runbook — TaskFlow API

## Success criteria (pre-declared)
A canary at N% is **promoted** only if ALL hold for the full observation window:
1. `customMetrics | summarize avg(rate_5xx)` on canary ≤ baseline + 0.1pp
2. `requests | summarize p95 = percentile(duration, 95)` on canary ≤ baseline × 1.1
3. No new error signatures (compare `exceptions | summarize by problemId` to baseline)
4. Orders/sec within ±5% of baseline (business metric)

## Stages
| Stage | % | Hold | Decision |
|---|---|---|---|
| 1 | 5%  | 15 min | promote / rollback |
| 2 | 25% | 30 min | promote / rollback |
| 3 | 100% | done | — |

## KQL — canary vs baseline 5xx
```kql
requests
| where timestamp > ago(20m)
| extend cohort = iff(cloud_RoleInstance has "staging-slot", "canary", "baseline")
| summarize total = count(), errors = countif(success == false) by cohort, bin(timestamp, 1m)
| extend err_rate = todouble(errors) / total
| project timestamp, cohort, err_rate
```

## Rollback procedure
```bash
az webapp traffic-routing set -g rg-taskflow-prod -n app-taskflow-prod --distribution staging-slot=0
```
```

---

## Submission

Tell me **"check P2"** (or a range) for graded review.
