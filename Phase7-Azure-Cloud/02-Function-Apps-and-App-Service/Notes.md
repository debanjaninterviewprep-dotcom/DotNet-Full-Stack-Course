# Topic 2: Azure Function Apps & App Service

> Now that you understand the Azure hierarchy, you'll deploy actual code. This topic covers the two most common ways to host server-side .NET workloads in Azure: **Azure Functions** (event-driven, serverless) and **App Service** (always-on, full web apps). You'll learn the trade-offs, the hosting plans, the deployment story, and how to wire each to identity (Managed Identity) and configuration (App Settings + Key Vault).

---

## 1. Two Compute Choices, One Mental Model

| | **Azure Functions** | **App Service (Web App / API App)** |
|---|---|---|
| **Programming model** | Triggered functions (HTTP, queue, timer, blob, etc.) | Long-running ASP.NET Core process (Kestrel) |
| **Scaling** | Per-execution, 0-to-N | Per-instance, manual / auto-rules |
| **Cold start** | Possible (Consumption plan) | Rare (always running) |
| **Pricing** | Per-execution + GB-s | Per-instance-hour |
| **Best for** | Event handlers, webhooks, scheduled jobs, glue code | Full APIs, MVC apps, SignalR backends |
| **Max execution time** | 5 min (Consumption), 30 min (Premium), unlimited (Dedicated) | Unlimited |
| **Worker model** | Out-of-process (.NET Isolated) **or** in-process | Standard ASP.NET Core |

> **TaskFlow rule of thumb:**
> - **Main API** (`api.taskflow.com`) → App Service.
> - **Image thumbnail generator, daily cleanup, webhook receivers** → Functions.
> - **Both** can sit behind APIM (Topic 3).

---

## 2. App Service Plans (Hosting SKU)

The **App Service Plan** is the VM(s) underneath your apps. Multiple Function Apps and Web Apps can share the same plan.

| Plan | Tier | Always-on | Custom domain | Scale | Use for |
|---|---|---|---|---|---|
| **F1** | Free | No (idles after 20 min) | No | 1 instance | Demos |
| **B1 / B2 / B3** | Basic | Yes | Yes | 1–3 manual | Dev / staging |
| **S1 / S2 / S3** | Standard | Yes | Yes | Up to 10 auto-scale | Small prod |
| **P1v3 / P2v3 / P3v3** | Premium v3 | Yes | Yes | Up to 30 auto-scale, deployment slots, VNet | Real prod |
| **I-tier (ASE)** | Isolated | Yes | Yes | Single-tenant, VNet by default | Regulated/enterprise |

For Functions specifically, the plan vocabulary is slightly different:

| Functions plan | Cold start | VNet | Max duration | Pricing |
|---|---|---|---|---|
| **Consumption** | Yes | No | 5 min | Per-execution + GB-s |
| **Flex Consumption** | Reduced (instance pre-warming) | Yes | 60 min | Per-execution, faster cold start |
| **Premium (EP1/EP2/EP3)** | None (warm instances) | Yes | Unlimited | Hourly + per-execution |
| **Dedicated (App Service Plan)** | None | Yes | Unlimited | Hourly |

> **For this course:** Use **Consumption** for Functions and **B1** for App Service unless an exercise calls out otherwise.

---

## 3. The .NET Functions Programming Model: Isolated Worker

Since .NET 8, the **Isolated Worker** model is the default and only option going forward (in-process is being retired). Your Function runs in its own process and talks to the Functions host over gRPC.

### Anatomy of an Isolated Function project

```
TaskFlow.Functions/
├── Program.cs                  # builds the host
├── HttpTriggers/
│   └── PingFunction.cs
├── QueueTriggers/
│   └── EmailDispatcher.cs
├── host.json                   # runtime config (timeouts, retries)
├── local.settings.json         # local dev secrets (gitignored)
└── TaskFlow.Functions.csproj
```

### `Program.cs` (Isolated, .NET 8+)

```csharp
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()       // ASP.NET Core integration
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();
        services.AddHttpClient();
    })
    .Build();

await host.RunAsync();
```

### A simple HTTP trigger

```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using System.Net;

public class PingFunction
{
    [Function("Ping")]
    public HttpResponseData Run(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        var res = req.CreateResponse(HttpStatusCode.OK);
        res.WriteString("pong");
        return res;
    }
}
```

### A queue-triggered function

```csharp
[Function("EmailDispatcher")]
public async Task Run(
    [QueueTrigger("email-queue", Connection = "Storage")] EmailMessage msg,
    FunctionContext ctx)
{
    var log = ctx.GetLogger<EmailDispatcher>();
    log.LogInformation("Sending email to {to}", msg.To);
    // ... call SendGrid / Graph / SMTP
}
```

> **Bindings = magic with limits.** Input/output bindings (queue, blob, etc.) save boilerplate but hide retry semantics. For complex flows, prefer manual SDK calls inside the function.

---

## 4. Triggers You Should Know

| Trigger | Fires when | Typical TaskFlow use |
|---|---|---|
| **HTTP** | HTTPS request hits the function | Webhooks, public REST endpoints fronted by APIM |
| **Timer** | CRON expression | Daily archive job, stale-token cleanup |
| **Queue** | Message in Azure Storage Queue | Async work decoupled from API |
| **Service Bus** | Message in SB queue/topic | Reliable inter-service events |
| **Blob** | Blob created/modified | Thumbnail generation on upload |
| **Event Grid** | Resource event (e.g. blob, custom) | Reactive workflows |
| **Cosmos DB / SQL** | Change-feed trigger | Materialize read models |

CRON examples (NCRONTAB, 6 fields incl. seconds):

```
0 0 2 * * *      # every day at 02:00
0 */15 * * * *   # every 15 minutes
0 0 9 * * 1-5    # 09:00 on weekdays
```

---

## 5. App Service for ASP.NET Core APIs

App Service hosts `dotnet` web apps directly. Your `Program.cs` is the standard ASP.NET Core minimal API:

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();
app.MapControllers();
app.Run();
```

App Service handles:
- TLS termination at `*.azurewebsites.net` (free wildcard cert).
- Health probes & instance recycling.
- Log streaming (`az webapp log tail`).
- **Deployment slots** — staging + production with one-click swap.

### Deployment slots (the killer feature)

A slot is a clone of the live app on the same plan. Patterns:

1. Deploy to `staging` slot.
2. Run smoke tests against `https://taskflow-api-staging.azurewebsites.net`.
3. **Swap** — staging becomes production with a warmed-up app and zero downtime.
4. If something's wrong, **swap back**.

> Slots are available on **Standard tier and above**. Worth the upgrade for production.

---

## 6. Configuration & Secrets

Both Functions and App Service expose **App Settings** as environment variables to your code.

### Three layers of config

1. **Code defaults** — sensible fallbacks in `appsettings.json`.
2. **App Settings** — environment-specific values set in the portal/CLI.
3. **Key Vault references** — for secrets, never the secret itself.

### App Settings example

| Key | Value |
|---|---|
| `ConnectionStrings__SqlDb` | `@Microsoft.KeyVault(SecretUri=https://kv-taskflow.vault.azure.net/secrets/SqlConn)` |
| `Logging__LogLevel__Default` | `Information` |
| `ASPNETCORE_ENVIRONMENT` | `Production` |

### Why Key Vault references > storing secrets in App Settings

- Rotation: change the secret in KV; app picks it up on next refresh.
- Audit: every read is logged.
- Access: scoped via RBAC + Managed Identity, not a portal-pasted blob.

---

## 7. Managed Identity in Action

Recall from Topic 1: a Managed Identity is an automatically-managed Service Principal bound to your Azure resource. Here's how the app uses it:

```csharp
// Talking to Storage with Managed Identity (no connection string!)
var blobClient = new BlobServiceClient(
    new Uri("https://sttaskflowdev.blob.core.windows.net"),
    new DefaultAzureCredential());

// Reading a Key Vault secret
var secretClient = new SecretClient(
    new Uri("https://kv-taskflow.vault.azure.net/"),
    new DefaultAzureCredential());

KeyVaultSecret secret = await secretClient.GetSecretAsync("SqlConn");
```

`DefaultAzureCredential` tries multiple sources in order:
1. `EnvironmentCredential` (env vars — useful in dev/CI)
2. `ManagedIdentityCredential` (when running in Azure)
3. Visual Studio / `az login` credentials (your dev machine)

> **Local dev:** `az login` once on your laptop. The same code that uses MI in Azure picks up your CLI identity locally. Zero secrets in either place.

---

## 8. Deployment Options

| Method | When | Notes |
|---|---|---|
| `az functionapp deployment source config-zip` | Quick from CI | Push a `.zip` of build output |
| `az webapp deploy --src-path` | App Service zip | Same pattern |
| **GitHub Actions** | Recommended | Workload Identity Federation, no secrets |
| **Azure DevOps Pipelines** | Enterprise CI/CD | Same pattern |
| **Bicep + zip** | IaC + app together | Best for repeatable envs |

A minimal GitHub Actions deploy (with OIDC):

```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- run: dotnet publish -c Release -o ./publish
- run: |
    cd publish
    zip -r ../app.zip .
- uses: azure/webapps-deploy@v3
  with:
    app-name: taskflow-api-dev
    package: app.zip
```

---

## 9. Observability: Application Insights

Every Function App and Web App should be wired to **Application Insights** (a Log Analytics-backed APM tool).

What you get:
- **Live Metrics** stream (RPS, latency, failures).
- **Distributed traces** (operation_Id correlation across HTTP → Queue → Function).
- **Failures blade** — exception aggregation.
- **KQL** for custom queries:

```kusto
requests
| where timestamp > ago(1h) and resultCode startswith "5"
| summarize count() by bin(timestamp, 5m), name
| render timechart
```

In code:

```csharp
builder.Services.AddApplicationInsightsTelemetry();
```

Enable **sampling** in production to control cost.

---

## 10. Common Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Use the in-process Functions model in 2026 | Use Isolated Worker (.NET 8/9) |
| Store secrets in App Settings as plain text | Use Key Vault references |
| Run heavy CPU work inside an HTTP-triggered Function | Offload to a queue-triggered Function or App Service |
| Single Function App for 50 unrelated functions | One Function App per bounded context |
| Deploy directly to production | Use deployment slots and swap |
| Long-running work on Consumption plan | Premium / Dedicated, or break into events |
| Talk to Azure with connection strings | Managed Identity + RBAC |

---

## 11. Decision Cheat Sheet

| Question | Functions | App Service |
|---|---|---|
| Bursty, event-driven, scale-to-zero? | ✅ | |
| Needs always-on, < 100 ms warm latency? | | ✅ |
| Long request/response (> 5 min)? | EP/Dedicated only | ✅ |
| Heavy CPU, predictable load? | | ✅ |
| Glue between two services? | ✅ | |
| Full SignalR with sticky-ish state? | ❌ | ✅ |
| Tiny, cheap, unpredictable? | ✅ Consumption | |

---

## Further Reading

- [Azure Functions Isolated Worker model](https://learn.microsoft.com/azure/azure-functions/dotnet-isolated-process-guide)
- [App Service deployment slots](https://learn.microsoft.com/azure/app-service/deploy-staging-slots)
- [Key Vault references for App Service & Functions](https://learn.microsoft.com/azure/app-service/app-service-key-vault-references)
- [DefaultAzureCredential behavior](https://learn.microsoft.com/dotnet/api/azure.identity.defaultazurecredential)
- [Application Insights for .NET](https://learn.microsoft.com/azure/azure-monitor/app/asp-net-core)
