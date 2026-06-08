# Topic 8 — Solutions Workspace

```
PracticeProblemsSolutions/
├── README.md
├── P1-api/
│   ├── Program.cs
│   ├── appsettings.json
│   └── TaskFlow.Api.csproj
├── P1-verification.md
├── P2-queries/
│   ├── rps-by-route.kql
│   ├── 5xx-rate.kql
│   ├── latency-percentiles.kql
│   ├── slow-dependencies.kql
│   ├── top-exceptions.kql
│   ├── end-to-end-trace.kql
│   └── orders-funnel.kql
├── P2-cheatsheet.md
├── P3-alerts/
│   ├── action-group.tf
│   ├── alert-5xx.tf
│   ├── alert-latency.tf
│   └── alert-sql-deps.tf
├── P3-runbooks/
│   ├── alert-5xx.md
│   ├── alert-latency.md
│   └── alert-sql-deps.md
├── P4-onCall.json
├── P4-product.json
├── P4-README.md
├── P5-deploy-workbook.json
├── P5-screenshot.md
├── P6-slo.kql
├── P6-alert-fast-burn.tf
├── P6-alert-slow-burn.tf
├── P6-slo.md
├── P7-current-usage.kql
├── P7-transformation.json
└── P7-cost-reduction.md
```

---

## Starter: `P1-api/Program.cs`

```csharp
using Azure.Monitor.OpenTelemetry.AspNetCore;
using System.Diagnostics;
using System.Diagnostics.Metrics;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenTelemetry()
    .UseAzureMonitor(o =>
    {
        o.ConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
        o.SamplingRatio    = 0.2f;
    });

var meter   = new Meter("TaskFlow.Api");
var orders  = meter.CreateCounter<long>("orders_created");

builder.Services.AddSingleton(meter);
builder.Services.AddSingleton(orders);

var app = builder.Build();

app.MapPost("/api/orders", (Counter<long> counter, ILogger<Program> log) =>
{
    var orderId = Guid.NewGuid();
    using var act = Activity.Current?.Source.StartActivity("ChargeCustomer");
    counter.Add(1);
    log.LogInformation("Order created. OrderId={OrderId}", orderId);
    return Results.Created($"/api/orders/{orderId}", new { id = orderId });
});

app.MapGet("/health/live",  () => Results.Ok("live"));
app.MapGet("/health/ready", () => Results.Ok("ready"));

app.Run();
```

`appsettings.json`:
```jsonc
{
  "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=...;IngestionEndpoint=https://..."
}
```

`OTEL_RESOURCE_ATTRIBUTES` (App Setting in Azure):
```
service.name=taskflow-api,deployment.environment=dev,service.version=1.0.0
```

---

## Starter: `P2-queries/5xx-rate.kql`

```kql
// 5xx rate over time, last 24 h, 1-minute buckets
// On-call: anything > 1% sustained for 5 minutes is a Sev 1.
requests
| where timestamp > ago(24h)
| summarize total = count(),
            errors = countif(resultCode startswith "5")
            by bin(timestamp, 1m)
| extend err_rate = todouble(errors) / total
| project timestamp, err_rate, total, errors
| order by timestamp asc
| render timechart
```

## Starter: `P2-queries/end-to-end-trace.kql`

```kql
// End-to-end transaction view. Replace OPID with the operation_Id.
let opid = "REPLACE_WITH_OPERATION_ID";
union requests, dependencies, traces, exceptions
| where operation_Id == opid
| project timestamp, itemType, name, target=column_ifexists("target",""),
          duration=column_ifexists("duration", real(null)),
          resultCode=column_ifexists("resultCode",""),
          message=column_ifexists("message",""),
          severityLevel=column_ifexists("severityLevel", int(null))
| order by timestamp asc
```

---

## Starter: `P3-alerts/alert-5xx.tf`

```hcl
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_5xx" {
  name                = "alert-taskflow-prod-5xx"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  scopes               = [var.app_insights_id]
  severity             = 1
  description          = "5xx rate > 1% over 5 minutes on TaskFlow API. See runbook."

  criteria {
    query                   = <<-Q
      requests
      | summarize total = count(), errors = countif(resultCode startswith "5")
      | extend rate = todouble(errors) / total
      | where rate > 0.01
    Q
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
    custom_properties = {
      runbook_url = "https://runbook.taskflow.io/alert-5xx"
    }
  }
}
```

## Starter: `P3-runbooks/alert-5xx.md`

```markdown
# Runbook — 5xx rate spike

## Symptoms
PagerDuty page: `alert-taskflow-prod-5xx`. App Insights shows `requests` resultCode starting with `5` exceeding 1% over the last 5 min.

## First 60 seconds
1. Open the alert; click "View query results".
2. Run:
   ```kql
   requests
   | where timestamp > ago(15m) and resultCode startswith "5"
   | summarize n = count() by name, resultCode, cloud_RoleInstance
   | top 20 by n desc
   ```
3. Identify if it's one route or many; one instance or all.

## Common causes
- Recent deploy → check Deploy Health dashboard.
- Downstream dependency outage → check `dependencies` table.
- Bad config push → check Key Vault audit logs.

## Mitigation
- If correlated with deploy in last 30 min: revert via slot swap.
- If dependency down: enable feature flag `EmailNotificationsEnabled = false` (etc).
- If one bad instance: `az webapp restart -g rg-taskflow-prod -n app-taskflow-prod`.

## Escalation
- 5 min without improvement → page secondary on-call.
- 15 min → declare Sev 1 incident; open war room.

## Postmortem
File within 24 h using template `templates/postmortem.md`.
```

---

## Starter: `P6-slo.kql`

```kql
let SLO        = 0.999;
let win        = 28d;
let alert_win  = 1h;
let traffic =
    requests
    | where timestamp > ago(win)
    | summarize total = count(),
                errors = countif(success == false);
let recent =
    requests
    | where timestamp > ago(alert_win)
    | summarize r_total = count(),
                r_errors = countif(success == false);
traffic
| extend allowed = total * (1.0 - SLO)
| extend consumed = todouble(errors) / max_of(allowed, 1.0)
| extend recent_rate = toscalar(recent | project todouble(r_errors)/r_total)
| extend burn_rate = recent_rate * (1h/win) / (1.0 - SLO)
| project total, errors, allowed, consumed, recent_rate, burn_rate
```

Fast-burn alert fires when `burn_rate > 10`. Slow-burn at `burn_rate > 2` over 6 h.

---

## Submission

Tell me **"check P2"** (or a range) for graded review.
