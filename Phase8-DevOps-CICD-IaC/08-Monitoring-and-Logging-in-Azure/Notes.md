# Topic 8: Monitoring & Logging in Azure

> **Goal:** Build a production observability stack on Azure — structured logging, metrics, traces, alerts, dashboards — so you find problems before customers do, and root-cause them in minutes, not days. By the end you can instrument an ASP.NET Core / Function App service with OpenTelemetry, query App Insights / Log Analytics with KQL, and design alerts that on-call engineers actually want to receive.

---

## 1. The Three Pillars (and what they tell you)

| Pillar | Answers | Cost shape | Typical retention |
|---|---|---|---|
| **Metrics** | "Is the system getting better or worse over time?" | Cheap, pre-aggregated | 93 days raw, years rolled up |
| **Logs** | "What happened in this specific case?" | Mid-expensive, per-GB ingested | 30–90 days standard, archive longer |
| **Traces** | "Where in the request chain did time/error go?" | Expensive at high RPS | Same as logs, often sampled |

Beyond pillars: **events** (deployments, config changes, business actions) — annotate metrics charts so you can correlate.

You want all three. Metrics for dashboards & alerts, logs for forensics, traces for distributed debugging.

---

## 2. Azure's Observability Stack (the components)

```
┌──────────────────────────────────────────────────┐
│           Your apps / Azure resources             │
└──────────────────────┬───────────────────────────┘
                       │ (SDK / agent / diag setting)
                       ▼
┌──────────────────────────────────────────────────┐
│              Azure Monitor                        │
│  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  Metrics     │  │   Log Analytics Workspace │  │
│  │  (TSDB)      │  │   (KQL store)             │  │
│  └──────────────┘  └──────────────────────────┘  │
│         ▲                       ▲                 │
│         │                       │                 │
│   ┌─────┴─────┐         ┌───────┴─────────┐       │
│   │ Alerts +  │         │ Application      │       │
│   │ Action    │         │ Insights (apm)   │       │
│   │ Groups    │         │ (sits on LA)     │       │
│   └───────────┘         └──────────────────┘       │
│         │                                          │
│         ▼                                          │
│   ┌───────────┐         ┌──────────────────┐      │
│   │ Dashboards│         │ Workbooks/Power BI│      │
│   └───────────┘         └──────────────────┘      │
└──────────────────────────────────────────────────┘
```

### 2.1 Application Insights
APM for code-instrumented services. Stores in a Log Analytics workspace (Workspace-based AI is the only kind worth using in 2026; classic is deprecated). Captures requests, dependencies, exceptions, custom events/metrics, traces. Built-in correlation across services.

### 2.2 Log Analytics Workspace
The data lake for everything else: Azure resource diagnostics, VM logs, Defender events, custom tables. Queried with **KQL** (Kusto).

### 2.3 Metrics
Platform-emitted, pre-aggregated time-series. Cheap, fast to alert on, but limited dimensionality (typically up to ~10 dimensions per metric).

### 2.4 Action Groups
Reusable definitions of who/what to notify: email, SMS, voice, Teams/Slack webhook, Function App, Logic App, ITSM connector.

### 2.5 Alerts
Rules that evaluate metrics or KQL queries on a schedule, fire actions when conditions met.

### 2.6 Dashboards / Workbooks
- **Dashboards** = simple pinned tiles, per-user or shared.
- **Workbooks** = parameterised reports with code blocks; export-friendly.

### 2.7 Defender for Cloud
Security telemetry: vulnerabilities, attack paths, regulatory compliance. Lives in the same Log Analytics workspace.

---

## 3. One Workspace or Many?

Default to **one workspace per environment** (dev/staging/prod):
- Single query pane for cross-resource analysis.
- Simpler RBAC.
- Lower per-GB cost via Commitment tiers.

Split when:
- **Compliance** (data residency requires regional segregation).
- **Chargeback** (per-team billing).
- **Defender** vs **app** isolation (security teams want their own).

For TaskFlow: `log-taskflow-{env}` workspace, all resources in that env send here.

---

## 4. App Insights with OpenTelemetry (.NET)

In 2026 the **OpenTelemetry path is the recommended one** — broader vendor compat, more flexibility than the legacy SDK.

### 4.1 Setup

```xml
<PackageReference Include="Azure.Monitor.OpenTelemetry.AspNetCore" Version="1.3.0-beta.2" />
```

```csharp
using Azure.Monitor.OpenTelemetry.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenTelemetry()
    .UseAzureMonitor(o =>
    {
        o.ConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
        o.SamplingRatio    = 0.2f;          // 20% trace sampling
    });

// Optional: tune what's collected
builder.Services.Configure<OtlpExporterOptions>(o => { /* ... */ });
```

That single `UseAzureMonitor` wires up:
- HTTP server instrumentation (incoming requests).
- HTTP client instrumentation (outgoing requests).
- SQL client instrumentation (dependencies).
- Log forwarding (`ILogger` → AI traces).
- Metrics (built-in + custom).
- Distributed tracing with W3C trace context.

### 4.2 Connection string, not instrumentation key
Use the connection string — it carries the AI endpoint plus region. The plain InstrumentationKey is being deprecated; today's AI resources may not even surface one.

Set via App Setting:
```
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=...;IngestionEndpoint=https://...
```

In Terraform:
```hcl
app_settings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai.connection_string
  OTEL_RESOURCE_ATTRIBUTES              = "service.name=taskflow-api,deployment.environment=${var.environment}"
}
```

### 4.3 Sampling
Defaults: adaptive sampling on the SDK side — keeps cost predictable.
- **Fixed-rate** (`SamplingRatio = 0.2f`) — simpler, predictable cost.
- **Adaptive** — adjusts to keep ≤ X items/sec.
- Always sample **whole traces** (parent-based), never individual spans, or your traces look swiss-cheese.

For prod TaskFlow: 20% fixed rate is a reasonable starting point; **never sample errors** — those are always retained.

### 4.4 Custom dimensions
Add cross-cutting context with a `TelemetryProcessor` or by enriching `Activity`:

```csharp
using var act = Activity.Current?.SetTag("tenant.id", tenantId)
                              ?.SetTag("user.id", userId);
```

These become **`customDimensions`** in KQL — queryable, indexable.

### 4.5 Live Metrics
The "Live Metrics" blade shows real-time RPS, failure rate, dependency health. **Not sampled.** Indispensable during deploys to watch for regressions.

---

## 5. Structured Logging (vs printf logging)

Stop logging strings; log **events with fields**.

❌
```csharp
_logger.LogInformation($"User {userId} created order {orderId} for ${total}");
```

✅
```csharp
_logger.LogInformation("Order created. UserId={UserId} OrderId={OrderId} Total={Total}",
    userId, orderId, total);
```

Why: each `{Placeholder}` becomes a `customDimensions` field. You can later:
```kql
traces
| where message has "Order created"
| summarize total_revenue = sum(toreal(customDimensions["Total"])) by bin(timestamp, 5m)
```

**Never** interpolate values into the message template. Always pass as parameters.

### 5.1 Log levels — when to use which

| Level | Meaning | Frequency |
|---|---|---|
| `Trace` | Diagnostic minutiae for devs | Off in prod |
| `Debug` | Developer-relevant flow | Off in prod, on briefly to debug |
| `Information` | Business events, lifecycle | Sparingly |
| `Warning` | Recoverable issue / unusual condition | Action only if it spikes |
| `Error` | Failed operation; user-impacting | Always investigate |
| `Critical` | Process/system failure | Page on-call |

Don't log every method entry/exit. Future-you will hate present-you.

### 5.2 PII & secrets in logs
**Never** log:
- Passwords, tokens, API keys.
- Full credit card / SSN.
- Free-form user input that may contain PII.

Use a **redaction processor**:
```csharp
builder.Logging.AddRedaction(o =>
{
    o.SetRedactor<StarRedactor>(new HashSet<string> { "Email", "Phone" });
});
```

Or strip server-side via a Workbook transformation.

### 5.3 Correlation
The `Activity` API propagates trace context across HTTP/gRPC/messaging. Every log emitted within a request automatically carries `operation_Id` and `operation_ParentId`. In KQL:
```kql
union requests, traces, dependencies, exceptions
| where operation_Id == "5e8e02e34a2e..."   // one request, end to end
| order by timestamp asc
```

---

## 6. KQL Crash Course

KQL = pipeline language. Read top-to-bottom.

### 6.1 Skeleton
```kql
TableName
| where <filter>
| project <columns>
| summarize <aggregation> by <group>
| order by <column> [asc|desc]
| limit N
```

### 6.2 Top-25 KQL operators

```kql
where, project, extend, project-rename, project-away,
summarize, count(), countif(), avg(), sum(), percentile(), min(), max(),
take, limit, top,
order by,
join, union,
bin(), bin_at(),
ago(), now(), datetime_diff,
parse_json, parse_csv, parse_url,
todouble, tostring, toreal, todatetime,
has, contains, startswith, matches regex
```

### 6.3 Worked examples

**Requests per minute, last hour:**
```kql
requests
| where timestamp > ago(1h)
| summarize total = count() by bin(timestamp, 1m)
| render timechart
```

**P95 latency by route, last day:**
```kql
requests
| where timestamp > ago(1d) and success == true
| summarize p95 = percentile(duration, 95) by name
| top 20 by p95 desc
```

**5xx rate over time:**
```kql
requests
| where timestamp > ago(2h)
| summarize total = count(), errors = countif(resultCode startswith "5")
            by bin(timestamp, 1m)
| extend err_rate = todouble(errors) / total
| render timechart
```

**Find the noisiest exception:**
```kql
exceptions
| where timestamp > ago(1d)
| summarize n = count(), first = min(timestamp), last = max(timestamp)
            by type, problemId
| top 25 by n desc
```

**Slowest dependency:**
```kql
dependencies
| where timestamp > ago(1h)
| summarize p95 = percentile(duration, 95), n = count() by target, name
| where n > 50
| top 20 by p95 desc
```

**Cross-table join — every failed request and its child exceptions:**
```kql
requests
| where timestamp > ago(1h) and success == false
| project operation_Id, name, resultCode, duration
| join kind=inner (
    exceptions
    | where timestamp > ago(1h)
    | project operation_Id, type, outerMessage
  ) on operation_Id
```

**Funnel — orders started vs completed:**
```kql
customEvents
| where timestamp > ago(7d) and name in ("OrderStarted", "OrderCompleted")
| summarize count() by name, bin(timestamp, 1h)
| render columnchart
```

### 6.4 Save expensive queries as functions
```kql
.create function five_xx_rate(env:string) {
    requests
    | where customDimensions.environment == env
    | summarize total = count(), errors = countif(resultCode startswith "5")
                by bin(timestamp, 1m)
    | extend rate = todouble(errors) / total
}
```
Call as `five_xx_rate("prod")`. Reusable in alerts and workbooks.

---

## 7. Alerts that People Actually Read

### 7.1 Five rules for good alerts

1. **Actionable.** If on-call can't do something specific, it shouldn't page.
2. **Symptomatic.** Alert on user impact (5xx rate, latency, SLO budget), not internal causes (CPU high). Cause-based alerts are noise; symptoms are truth.
3. **Sensitive enough to catch real incidents, specific enough to avoid noise.** Tune the threshold.
4. **One alert per *condition*, not per resource.** Use **dynamic thresholds** or **multi-resource alerts** where possible.
5. **Self-documenting.** The alert payload links to a runbook and the relevant query.

### 7.2 Severity scale (standardise this)

| Severity | Meaning | Channel |
|---|---|---|
| Sev 0 | Service down | Phone + page; war room |
| Sev 1 | Severe user impact | Page on-call |
| Sev 2 | Significant impact, non-critical path | Slack/Teams + ticket |
| Sev 3 | Degraded; warning | Ticket only |
| Sev 4 | Informational | Log channel |

### 7.3 Anatomy: Alert rule (Bicep / Terraform)

Terraform:
```hcl
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_5xx" {
  name                = "alert-taskflow-prod-5xx"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  evaluation_frequency = "PT1M"
  window_duration      = "PT5M"
  scopes               = [azurerm_application_insights.ai.id]
  severity             = 1
  description          = "5xx rate > 1% over 5 minutes on TaskFlow API"

  criteria {
    query                   = <<-QUERY
      requests
      | summarize total = count(), errors = countif(resultCode startswith "5")
      | extend rate = todouble(errors) / total
      | where rate > 0.01
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.oncall.id]
    custom_properties = {
      runbook_url = "https://runbook.taskflow.io/api-5xx"
    }
  }
}
```

### 7.4 SLO-based alerting (the modern way)

Instead of "5xx > 1%", define an **SLO** (e.g., 99.9% successful requests over 28 days) and alert on **error budget burn rate**:
- **Fast burn** (10× budget consumed in 1 h): page now.
- **Slow burn** (2× over 6 h): ticket.

This naturally tunes sensitivity to user impact rather than a static threshold.

### 7.5 Alert payload must include
- What happened (which metric, current value, threshold).
- Where (resource, region).
- When (timestamp).
- **Link to a runbook**.
- **Link to a pre-baked KQL query** so on-call doesn't reinvent it at 3 AM.
- A short message suitable for SMS.

---

## 8. Diagnostic Settings (the firehose)

Every Azure resource has a **Diagnostic Setting** controlling what it sends to Log Analytics.

### 8.1 What to enable
- **`AuditLogs`** / **`AdministrativeLogs`** — *always*.
- **`AllMetrics`** — yes, for trend dashboards.
- **Resource-specific logs** — depends; e.g., `AzureFunctionAppLogs`, `AppServiceHTTPLogs`, `KeyVaultAuditLogs`.

### 8.2 Govern with Policy
A Deploy-If-Not-Exists policy auto-creates Diagnostic Settings on every new resource:
```bicep
// pseudo
policyDefinition: builtin '7f89b1eb-583c-429a-8828-af049802c1d9'  // diagnostic settings for app services
```
Phase 7 Topic 8 covered the policy authoring; Phase 8 plugs in the destination LA.

### 8.3 Cost discipline
Per-GB ingestion is the biggest LA cost. Apply **Basic Logs** or **Auxiliary** tiers for high-volume / low-value tables:
- `AppTraces` chatty? Move debug-level to Basic; warning+ to Analytics.
- Transform pipelines to drop noisy fields before ingest.

---

## 9. Dashboards & Workbooks

### 9.1 Dashboards (the "TV in the office")
- Use for **at-a-glance** health.
- 6–10 tiles max; more is noise.
- One per audience: **on-call dashboard**, **business KPI dashboard**, **deploy dashboard**.

### 9.2 Workbooks (the investigation tool)
- Parameters (env, time range, route).
- Markdown sections explaining what to look for.
- Multiple queries in one place.
- Exportable to PDF for incident reports.

### 9.3 The four dashboards every team should have

1. **Service Health**: RPS, 5xx rate, p95 latency, dependency latency, queue depth.
2. **Reliability / SLO**: error budget remaining, burn rate, top error signatures.
3. **Deploy Health**: events overlay, version distribution, canary vs baseline metrics.
4. **Business KPIs**: orders/sec, signups, conversion — the metrics product cares about.

Pin the same chart with a vertical line at deploy time. Saves hours during incidents.

---

## 10. Tracing: distributed by default

OpenTelemetry handles W3C trace context propagation automatically across:
- HTTP (`traceparent` header).
- gRPC.
- Service Bus / Storage Queues (via message properties).
- HttpClientFactory.

Result: you can pick any failed request in App Insights → click **End-to-end transaction** → see every downstream call with timing.

### 10.1 Manual span when SDK isn't enough
```csharp
using var activity = Activity.Current?.Source.StartActivity("ChargeCustomer");
activity?.SetTag("paymentProvider", provider);
activity?.SetTag("amountUsd", amount);
try { /* work */ }
catch (Exception ex)
{
    activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
    throw;
}
```

### 10.2 Trace what matters
Don't trace tight loops or millisecond-level work. Spans cost ingest. Trace at:
- Service boundaries (entering/leaving your service).
- Significant business steps (auth, charge, fulfilment).
- External calls (already auto-instrumented).

---

## 11. SLOs, SLIs, Error Budgets

### 11.1 Definitions
- **SLI** (Indicator): a metric you measure (success rate, latency).
- **SLO** (Objective): the target for that metric over a window ("99.9% of requests succeed over 28 days").
- **Error budget**: `1 - SLO` × traffic. The amount of badness you're allowed before it counts as a failure of the objective.

### 11.2 Why it matters operationally
- **Below budget** → focus on reliability work; freeze risky features.
- **Above budget** → ship faster; tolerate more risk.

The budget converts "is it broken?" into a tradeoff with product velocity.

### 11.3 Computing burn rate in KQL
```kql
let SLO = 0.999;
let window = 28d;
requests
| where timestamp > ago(window)
| summarize total = count(), errors = countif(success == false)
| extend slo_failures_allowed = total * (1.0 - SLO)
| extend budget_consumed = todouble(errors) / slo_failures_allowed
| extend burn_rate = budget_consumed * (window / 1h)
```

Alert on burn_rate > 1 in last 1 h → fast burn → page.

---

## 12. Operational Excellence Patterns

### 12.1 Runbooks
Every alert links to a runbook. Runbook contains:
- Symptoms (what triggered the page).
- Quick diagnosis steps (KQL queries to run).
- Mitigation (knobs to turn, scripts to run).
- Escalation (who to wake next).
- Postmortem template link.

### 12.2 Synthetic monitoring
App Insights **Availability tests** (or custom Functions) hit your endpoints from multiple regions on a schedule. Catches DNS/cert/network issues invisible from your own infra.

### 12.3 Game days
Periodically inject failure (kill a pod, throttle a dependency) to verify your alerts and runbooks. If nothing pages, your monitoring lied to you.

### 12.4 Incident timelines
Annotate App Insights with deploys, config changes, and known events (third-party outages). When investigating, the timeline tells the story.

---

## 13. Cost Control for Observability

LA is one of the largest Azure cost lines if you don't manage it.

### 13.1 Cost levers (highest impact first)
1. **Daily cap** on the workspace (defensive limit; not for normal operation).
2. **Commitment tiers** (100 GB/day commits ~30% off pay-as-you-go).
3. **Sampling** in App Insights (20% is fine for most TaskFlow workloads).
4. **Drop noisy fields** with [ingestion-time transformations](https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-transformations).
5. **Move chatty tables to Basic/Aux logs** (cheaper ingest, slower query).
6. **Shorter retention** for low-value tables.
7. **Archive** old data to cheap storage; only restore when needed.

### 13.2 Track your bill
Pin a Cost Management chart showing weekly LA spend by table. If a number jumps, find out *why* before paying the bill.

---

## 14. Reference Architecture: TaskFlow Observability

```
TaskFlow API (Web App) ──┐
TaskFlow Worker (Func)   │
TaskFlow Web (SWA)       ├── App Insights ── Log Analytics Workspace
APIM                      │
Storage / Service Bus     │── Diagnostic Settings ─┘
Key Vault                 │
Redis                     │
                          │
              Action Groups ─── Teams + PagerDuty
              Alert Rules ──────/
              Dashboards ───── pinned per team
              Workbooks ────── investigation reports
              SLO/Burn-rate ── error budget enforcement
```

All identities use OIDC (Phase 7) and Managed Identity. Diagnostic Settings deployed by Azure Policy `DeployIfNotExists`. Daily cap configured per env (dev: 1 GB, staging: 5 GB, prod: 50 GB).

---

## 15. Anti-Patterns

| Anti-pattern | Why it bites |
|---|---|
| String-interpolated log messages | Lose structured fields; can't query |
| Logging PII / secrets | Compliance breach |
| Cause-based alerts (CPU high) | Noise; users may not care |
| One alert per resource | Page storm during incidents |
| No runbook link in alert | On-call invents the response at 3 AM |
| Dashboards with 40 tiles | Nobody reads them |
| Sampling errors away | Lose the cases you most want to see |
| Per-team workspaces with no cross-query | Can't correlate incidents |
| No daily cap, no commitment tier | Surprise bill |
| Disabling diag settings to save cost | You lose forensics when you need them |
| Treating availability tests as "tests" | They're SLO signals; failures count |

---

## Further Reading

- [Azure Monitor docs](https://learn.microsoft.com/azure/azure-monitor/)
- [App Insights for ASP.NET Core (OpenTelemetry)](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [KQL quick reference](https://learn.microsoft.com/azure/data-explorer/kql-quick-reference)
- [Google SRE Workbook — Implementing SLOs](https://sre.google/workbook/implementing-slos/)
- [Charity Majors — Observability Engineering (book)](https://www.honeycomb.io/observability-engineering-oreilly-book-2022)
- [Ingestion-time transformations](https://learn.microsoft.com/azure/azure-monitor/essentials/data-collection-transformations)
