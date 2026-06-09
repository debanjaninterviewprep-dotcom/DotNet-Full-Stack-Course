# Topic 7: Deployment Strategies (Blue-Green, Canary, Rolling, Feature Flags)

> **Goal:** Choose and implement a deployment strategy that minimises blast radius. By the end you can explain when each strategy fits, build a blue-green deployment with App Service slots, a canary rollout via Azure Front Door / Traffic Manager, and a feature-flag-based progressive exposure pattern.

---

## 1. Why Strategy Matters

Every deploy is a controlled change to production. The strategy decides:

1. **Who sees the new version when?** (everyone vs subset)
2. **How fast do we notice if it's bad?** (seconds vs hours)
3. **How fast can we revert?** (one click vs full redeploy)

Old-school "stop service, upload zip, start service" gives you: everyone at once, you find out via tickets, revert = rebuild last version. That's why we have strategies.

The right strategy minimises **MTTR for a bad deploy** without slowing down good deploys.

---

## 2. The Six Strategies (and when each fits)

| Strategy | Mechanism | Detect bad deploy by | Fits when |
|---|---|---|---|
| **Recreate / Big-bang** | Stop old, start new | Downtime alert | Internal tools, dev/test |
| **Rolling** | Replace N instances at a time | Health probe failure | Stateless services with N≥3 |
| **Blue-Green** | Two full envs; swap traffic | Smoke test on green before swap | Single artifact you can stage |
| **Canary** | 1–5% real traffic on new | Error rate / latency / business metric | High-traffic, mature monitoring |
| **A/B testing** | Split traffic by user segment | Conversion metric (business-side) | Feature experiments, not safety |
| **Progressive exposure (feature flags)** | Single deploy; flag-gate code paths | Telemetry per flag cohort | Continuous deployment, decoupled deploy from release |

You'll likely combine: **blue-green for the *deployment*** + **feature flags for the *release*** + **canary on truly risky changes**.

---

## 3. Health Checks: the foundation

No strategy works without reliable health checks. App Service / Functions / AKS all need:

### 3.1 `/health` endpoint
- Returns 200 when the app can serve traffic.
- Returns 503 when it can't (DB unreachable, queue down).
- Should check **only what the app needs to function**. Don't make health depend on an unrelated dashboard service.

ASP.NET Core minimal:
```csharp
builder.Services.AddHealthChecks()
    .AddSqlServer(connectionString, name: "sql", tags: ["ready"])
    .AddAzureBlobStorage(blobUri, credential, name: "blob", tags: ["ready"]);

app.MapHealthChecks("/health/live",  new HealthCheckOptions { Predicate = _ => false });
app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = c => c.Tags.Contains("ready") });
```

Two endpoints:
- **liveness** (`/health/live`) — am I running? Always true if process is up. Used by orchestrator to decide "kill and restart".
- **readiness** (`/health/ready`) — should I receive traffic right now? False during warm-up; false if dependencies broken.

App Service slot warm-up calls `/health` repeatedly before completing a swap (next section).

---

## 4. Blue-Green with App Service Slots

App Service ships with **deployment slots** — additional instances of your app inside the same plan. The "swap" operation switches their hostnames atomically.

### 4.1 Mental model

```
Before swap:
  app-taskflow.azurewebsites.net          → SLOT: production  (v1.4.2)
  app-taskflow-staging.azurewebsites.net  → SLOT: staging-slot (v1.4.3, warmed)

Swap operation:
  Slot identities (and traffic) atomically exchanged.

After swap:
  app-taskflow.azurewebsites.net          → SLOT: production  (v1.4.3)
  app-taskflow-staging.azurewebsites.net  → SLOT: staging-slot (v1.4.2, "old")
```

The old version is now in `staging-slot` — instant revert by swapping back.

### 4.2 Provision (Terraform)

```hcl
resource "azurerm_linux_web_app" "api" {
  name                = "app-taskflow-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack { dotnet_version = "8.0" }
    health_check_path                  = "/health/ready"
    health_check_eviction_time_in_min  = 5
    minimum_tls_version                = "1.2"
  }

  https_only = true
  identity { type = "SystemAssigned" }
}

resource "azurerm_linux_web_app_slot" "staging" {
  name             = "staging-slot"
  app_service_id   = azurerm_linux_web_app.api.id

  site_config {
    application_stack { dotnet_version = "8.0" }
    health_check_path = "/health/ready"
    minimum_tls_version = "1.2"
  }

  https_only = true
  identity { type = "SystemAssigned" }
}
```

Service Plan must be **Standard tier or higher** for slots. Basic doesn't support them.

### 4.3 Slot-sticky vs swappable settings

By default, app settings move with the swap. You usually want **some settings to stay with the slot**:
- `ASPNETCORE_ENVIRONMENT` = `Staging` on staging-slot, `Production` on prod.
- Per-slot connection strings if you keep an isolated DB for verification.

Mark them sticky in Terraform:
```hcl
resource "azurerm_linux_web_app" "api" {
  ...
  sticky_settings {
    app_setting_names       = ["ASPNETCORE_ENVIRONMENT"]
    connection_string_names = ["SqlDb"]
  }
}
```
…and set each setting per-slot with `azurerm_app_service_app_setting`-style overrides.

### 4.4 Pipeline: build → deploy to staging-slot → warm → swap

```yaml
- name: Deploy to staging slot
  uses: azure/webapps-deploy@v3
  with:
    app-name: app-taskflow-prod
    slot-name: staging-slot
    package: ./publish

- name: Wait for slot to be healthy
  run: |
    for i in {1..30}; do
      code=$(curl -s -o /dev/null -w "%{http_code}" https://app-taskflow-prod-staging-slot.azurewebsites.net/health/ready)
      if [[ "$code" == "200" ]]; then echo "Ready"; exit 0; fi
      sleep 10
    done
    echo "Slot never went healthy" >&2; exit 1

- name: Smoke tests against staging slot
  run: dotnet test ./tests/Smoke -- TestRunParameters.Parameter\(name=BaseUrl,value=https://app-taskflow-prod-staging-slot.azurewebsites.net\)

- name: Swap slots
  run: |
    az webapp deployment slot swap \
      -g rg-taskflow-prod \
      -n app-taskflow-prod \
      --slot staging-slot \
      --target-slot production

- name: Verify production
  run: |
    code=$(curl -s -o /dev/null -w "%{http_code}" https://app-taskflow-prod.azurewebsites.net/health/ready)
    [[ "$code" == "200" ]] || { echo "Prod not healthy after swap"; exit 1; }
```

### 4.5 Rollback
Two clicks (or one `az` command):
```bash
az webapp deployment slot swap \
  -g rg-taskflow-prod \
  -n app-taskflow-prod \
  --slot staging-slot \
  --target-slot production
```
Same command — swap goes the other way, restoring the previous version.

### 4.6 Auto Swap (proceed with care)
App Service supports auto-swap: deploy to staging-slot, when warmup succeeds, swap automatically. Set in Terraform:
```hcl
resource "azurerm_linux_web_app_slot" "staging" {
  ...
  site_config {
    auto_swap_slot_name = "production"
  }
}
```
Skip in pipelines if you want manual approval — auto-swap can fire on hot-fix deploys you'd rather hold.

### 4.7 Caveats / gotchas
- **Schema migrations** must be backwards-compatible. After swap, the *new* code reads/writes the same DB as the *old* code (during warm-up window). See §10.
- **In-flight connections** are drained for ~30s by default. Long-lived WebSocket clients reconnect to the new slot.
- **Slot count** is plan-tier-limited. Standard = 5 slots; Premium V3 = 20.

---

## 5. Canary with Azure Front Door / Traffic Manager

When the change is risky and rollback time matters more than infra cost, ship to a small slice first.

### 5.1 With App Service Traffic Routing (simplest)

App Service slots support **percentage-based routing** out of the box:
```bash
az webapp traffic-routing set \
  -g rg-taskflow-prod \
  -n app-taskflow-prod \
  --distribution staging-slot=10
```
10% of requests to `app-taskflow-prod.azurewebsites.net` are now routed to `staging-slot`. Watch metrics for ~15 min, then either:
- Promote: swap.
- Abort: `--distribution staging-slot=0`.

### 5.2 With Azure Front Door (richer control)

If you need:
- Header / cookie-based stickiness (a given user stays on the canary all session).
- Region-based canary (only EU customers).
- Mixed sources (App Service + Container Apps + Static Web Apps).

…use Front Door with two backend pools and a routing rule weighted 95/5.

```hcl
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name = "og-taskflow"
  ...
  load_balancing { sample_size = 4; successful_samples_required = 3 }
}

resource "azurerm_cdn_frontdoor_origin" "blue" {
  name                  = "blue"
  origin_group_id       = azurerm_cdn_frontdoor_origin_group.main.id
  host_name             = "app-taskflow-blue.azurewebsites.net"
  weight                = 95
  enabled               = true
}

resource "azurerm_cdn_frontdoor_origin" "green" {
  name                  = "green"
  origin_group_id       = azurerm_cdn_frontdoor_origin_group.main.id
  host_name             = "app-taskflow-green.azurewebsites.net"
  weight                = 5
  enabled               = true
}
```

Front Door distributes 95/5 by weight. Increase progressively: 5 → 25 → 50 → 100. Each stage holds for an SLO-sized observation window.

### 5.3 Success criteria for promoting canary

Define **before deploy**:
- Error rate on canary ≤ baseline + 0.1 percentage points.
- p95 latency on canary ≤ baseline × 1.1.
- No new error signatures in App Insights.
- Business metric (orders/sec) within ±5% of baseline.

If any fail, rollback weight to 0. Don't reason in the moment — your future self under stress will get it wrong.

### 5.4 Automated canary analysis
For mature teams: scripts query App Insights every minute, evaluate the criteria, automatically increase or rollback. Tools: [Flagger](https://flagger.app) (Kubernetes), home-grown PowerShell/Python for App Service.

---

## 6. Rolling Deployments (AKS / Container Apps / VMSS)

When the unit of deployment is a container or VM and you have ≥ 3 replicas, **rolling** is natural.

### 6.1 Kubernetes `RollingUpdate`
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
        - name: api
          image: acrtaskflow.azurecr.io/api:1.4.3
          readinessProbe:
            httpGet: { path: /health/ready, port: 8080 }
            periodSeconds: 5
            failureThreshold: 3
```

- `maxUnavailable: 1` — at most 1 pod down at once.
- `maxSurge: 1` — at most 1 extra pod above replica count during rollout.
- Bad pods that fail readiness never receive traffic; rollout stalls.

Rollback:
```bash
kubectl rollout undo deployment/api
```

### 6.2 Azure Container Apps
Container Apps does rolling automatically per revision:
```bash
az containerapp update -n api -g rg-taskflow-prod \
  --image acrtaskflow.azurecr.io/api:1.4.3
```
New revision starts; traffic shifts when healthy. You can keep multiple revisions live and split traffic — effectively built-in canary.

### 6.3 VM Scale Sets
Use **rolling upgrade policy**:
```bash
az vmss update -g rg -n vmss-api --set upgradePolicy.mode=Rolling
az vmss rolling-upgrade start -g rg -n vmss-api
```

### 6.4 Pros / cons vs blue-green
- **Pros:** No double infra cost. Simple. Built into orchestrator.
- **Cons:** Two versions live simultaneously during rollout → must be DB-compatible. Slower rollback (rolling back the rolling update). Harder to test before traffic shifts.

---

## 7. Feature Flags / Progressive Exposure

**Decouple deploy from release.** A flag is a runtime switch that determines whether code is exercised.

### 7.1 The mental shift
- **Deploy** = code in production, dormant.
- **Release** = users see the behaviour.

A bad release no longer requires redeploy — just flip the flag.

### 7.2 Azure App Configuration + feature flags

```csharp
builder.Configuration
    .AddAzureAppConfiguration(options =>
    {
        options
            .Connect(new Uri(appConfigUri), new DefaultAzureCredential())
            .UseFeatureFlags(o => o.CacheExpirationInterval = TimeSpan.FromSeconds(30));
    });

builder.Services.AddAzureAppConfiguration();
builder.Services.AddFeatureManagement();

var app = builder.Build();
app.UseAzureAppConfiguration();

app.MapGet("/api/orders", async (IFeatureManager flags) =>
{
    if (await flags.IsEnabledAsync("NewOrderPipeline"))
        return Results.Ok(await NewOrderService.ListAsync());
    return Results.Ok(await LegacyOrderService.ListAsync());
});
```

### 7.3 Targeting filter (per-user / per-group rollout)

```jsonc
{
  "id": "NewOrderPipeline",
  "enabled": true,
  "conditions": {
    "client_filters": [{
      "name": "Microsoft.Targeting",
      "parameters": {
        "Audience": {
          "Users": ["alice@taskflow.io"],
          "Groups": [{ "Name": "BetaUsers", "RolloutPercentage": 25 }],
          "DefaultRolloutPercentage": 5
        }
      }
    }]
  }
}
```

Beta group sees it at 25%, everyone else at 5%, named users always.

### 7.4 The right flag taxonomy

| Type | Lifetime | Example |
|---|---|---|
| **Release flag** | Days to weeks | "Use NewOrderPipeline" |
| **Experiment flag** | Weeks (then deleted) | "ShowNewCheckoutCTA" |
| **Operational kill switch** | Permanent | "EmailNotificationsEnabled" — turn off during outage |
| **Permission flag** | Permanent | "EnableExportAPI" — entitlement, not deploy |

**Always plan flag retirement.** Stale flags rot codebases.

### 7.5 Anti-patterns
- Flags inside other flags inside other flags — combinatorial explosion of test cases.
- Long-lived release flags — never cleaned up; old code path bit-rots.
- Flag values cached too long — turning off doesn't take effect for an hour.

---

## 8. Database Changes During Deploys

The hardest part of any deployment strategy.

### 8.1 Expand / Migrate / Contract

To change a column without breaking either version:

1. **Expand** — add the new column (nullable). Deploy schema. Old code ignores it.
2. **Migrate** — deploy new code that **writes to both** old and new columns; reads from old. Deploy. Backfill data to new column with a background job.
3. **Switch** — deploy code that reads from new column.
4. **Contract** — once nothing reads from old column, drop it. Deploy schema.

Each step is independently safe: at any point, both old and new code work.

### 8.2 Renaming a column
Treat as: add new, dual-write, swap reads, drop old. Same pattern; never an in-place rename.

### 8.3 Backwards-compatible API changes
- Adding endpoints / fields = safe (consumers ignore unknown fields if you use JSON properly).
- Removing fields / endpoints = breaking. Version the API (`/v1`, `/v2`) or use feature flags + deprecation period.
- Tightening validation = breaking. Same rules.

### 8.4 Schema migration in pipeline
```yaml
- name: EF migration (idempotent)
  run: |
    dotnet ef database update \
      --project src/TaskFlow.Data \
      --connection "$ConnectionString"
```
Run **before** swapping the slot. If migration fails, abort the deploy.

For destructive migrations (drop column), require an extra manual approval gate.

---

## 9. Observability for Deploys

You need to **measure the deploy**, not just deploy it:

### 9.1 Deployment annotations
Mark the moment in App Insights:
```csharp
telemetryClient.TrackEvent("DeploymentCompleted", new Dictionary<string, string> {
    ["version"] = appVersion,
    ["environment"] = env,
    ["commit"] = commitSha
});
```

Charts then show "before vs after this point".

### 9.2 Compare baselines
Have your dashboards compare current 5 min vs the 5 min before deploy, and vs the same 5 min yesterday. A jump on both = real regression. A jump on first only = expected post-deploy noise.

### 9.3 Auto-rollback signals
Wire alerts (Topic 8) to:
- 5xx rate > X for 2 min → page on-call.
- Auto-revert: GitHub Action triggered by the alert, re-swaps slots.

Auto-revert needs **very** high-confidence signals. Most teams start with "alert + human decides".

---

## 10. Failure Modes & Mitigations

| Failure | What happens | Mitigation |
|---|---|---|
| New version OOMs | All replicas die in rolling | Liveness probe restarts; canary catches before full rollout |
| Schema change breaks old code (still running) | Errors during rollout window | Expand/contract |
| Slot warm-up never completes | Swap hangs | Set `WEBSITE_WARMUP_PATH` to `/health/ready`; bound swap timeout |
| Cache poisoned with bad keys | Even rollback shows bad data | Bump cache key prefix on deploy |
| Long-running request crosses swap | Some requests see partial behaviour | Connection draining; graceful shutdown handler |
| Background job runs against old DB schema | Wrong updates | Stop workers during migration; or use schema-tolerant migrations |
| Pipeline applies wrong artifact to wrong env | Wrong version in prod | Pin by digest; environment-scoped identities |
| Manual `az webapp restart` during deploy | Race | Don't. Wait for pipeline. |

---

## 11. Decision Framework

When choosing a strategy for a change:

```
Is the risk of this change LOW (CSS tweak, copy change)?
  → recreate / rolling is fine

Is it a stateless API change with backwards-compatible schema?
  → blue-green slot swap

Is it a major rewrite of a hot-path?
  → canary (5% → 25% → 100%) + feature flag

Is it a DB schema change?
  → expand/migrate/contract; pipeline gates the destructive contract step

Is it a UI experiment?
  → feature flag with targeting; not a deploy strategy at all
```

Don't always use the biggest hammer. Blue-green every PR adds latency to deploy. Reserve canary for the truly risky.

---

## 12. TaskFlow Reference Topology

For TaskFlow we use:

- **API**: blue-green via App Service slots. Schema changes follow expand/contract.
- **Worker (Service Bus consumer)**: rolling on Container Apps — graceful shutdown drains in-flight messages.
- **Web frontend** (Static Web Apps): atomic deploy; rollback by redeploying previous version.
- **Risky changes** (e.g., new pricing engine): wrapped in a feature flag with 5% targeting first.
- **Database migrations**: applied in a separate, manually-approved pipeline before app deploy.

---

## 13. Anti-Patterns

| Anti-pattern | Why it bites |
|---|---|
| Blue-green without warm-up | First requests after swap fail (JIT, cache cold) |
| Slot swap with non-backwards-compatible schema | Old code in old slot now reads corrupted shape |
| Canary with no clear success criteria | You'll always promote because "looks fine" |
| Feature flag with no removal date | Stale flags accumulate; cleanup never happens |
| Auto-revert on flaky signal | Repeated thrash; lose confidence in deploys |
| One huge release branch per quarter | Big-bang deploy; back to square one |
| Stopping the service to deploy | Why are we even doing this topic |
| "Deploy hour" each day | Concentrates risk; bad for DORA frequency |
| Rolling with `maxUnavailable=50%` | Effectively big-bang; defeats purpose |

---

## Further Reading

- [Azure App Service deployment slots](https://learn.microsoft.com/azure/app-service/deploy-staging-slots)
- [Azure Front Door routing](https://learn.microsoft.com/azure/frontdoor/front-door-routing-methods)
- [Container Apps revisions & traffic splitting](https://learn.microsoft.com/azure/container-apps/revisions)
- [Microsoft Feature Management library](https://learn.microsoft.com/azure/azure-app-configuration/feature-management-dotnet-reference)
- [Martin Fowler — Blue-Green Deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Martin Fowler — Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
- [Google SRE — Canarying](https://sre.google/workbook/canarying-releases/)
