# Solutions — Secure API Authentication

Put your work here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-jwt-hardening/
│   ├── TaskFlow.Api/
│   └── TaskFlow.Api.Tests/
├── P2-bff/
│   ├── TaskFlow.Bff/
│   └── taskflow-spa/
├── P3-rt-rotation/
│   ├── TaskFlow.Identity/
│   └── tests/
├── P4-s2s/
│   ├── TaskFlow.Worker/
│   ├── TaskFlow.Api/
│   ├── assign-app-role.ps1
│   └── screenshots/
├── P5-mtls/
│   ├── infra/
│   ├── TaskFlow.Partner.Api/
│   └── curl-tests.md
├── P6-cert-auth/
│   ├── infra/
│   ├── TaskFlow.Confidential/
│   └── rotation-runbook.md
└── P7-sender-constrained/
    ├── TaskFlow.HighValue/
    └── tests/
```

Tell me **"check"** when done.

---

## P1 Starter — hardened `Program.cs`

```csharp
var tenantId = builder.Configuration["AzureAd:TenantId"]!;
var apiAppId = builder.Configuration["AzureAd:ApiAppId"]!;

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.Authority = $"https://login.microsoftonline.com/{tenantId}/v2.0";
        o.MapInboundClaims = false;
        o.RefreshOnIssuerKeyNotFound = true;
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer       = $"https://login.microsoftonline.com/{tenantId}/v2.0",
            ValidAudience     = $"api://{apiAppId}",
            ValidateIssuer    = true,
            ValidateAudience  = true,
            ValidateLifetime  = true,
            ValidateIssuerSigningKey = true,
            RequireSignedTokens = true,
            ClockSkew         = TimeSpan.FromMinutes(2),
            NameClaimType     = "preferred_username",
            RoleClaimType     = "roles"
        };
        o.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = ctx =>
            {
                var token = ctx.SecurityToken as JsonWebToken;
                ctx.HttpContext.RequestServices
                   .GetRequiredService<ILogger<Program>>()
                   .LogWarning("JWT validation failed for kid={Kid} iss={Iss} aud={Aud}: {Reason}",
                        token?.Kid, token?.Issuer, string.Join(',', token?.Audiences ?? []), ctx.Exception.Message);
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization(o =>
{
    o.AddPolicy("TasksRead", p => p.RequireAssertion(c =>
        c.User.HasClaim("scp",   "Tasks.Read") ||
        c.User.HasClaim("roles", "TaskFlow.Tasks.Read.All")));
});
```

## P2 Starter — BFF tokens stored server-side

```csharp
builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApp(o =>
    {
        builder.Configuration.Bind("AzureAd", o);
        o.UsePkce = true;
        o.SaveTokens = false; // tokens go to the cache, not the cookie
    })
    .EnableTokenAcquisitionToCallDownstreamApi(["api://taskflow-api/Tasks.Read"])
    .AddDistributedTokenCaches();

builder.Services.AddStackExchangeRedisCache(o => o.Configuration = builder.Configuration["Redis"]);

app.MapGet("/bff/api/{*path}", async (HttpContext ctx, ITokenAcquisition ta, IHttpClientFactory http, string path) =>
{
    var token = await ta.GetAccessTokenForUserAsync(["api://taskflow-api/Tasks.Read"]);
    var client = http.CreateClient("api");
    client.DefaultRequestHeaders.Authorization = new("Bearer", token);
    var upstream = await client.GetAsync($"/{path}");
    var body = await upstream.Content.ReadAsStringAsync();
    return Results.Content(body, upstream.Content.Headers.ContentType?.ToString());
}).RequireAuthorization();
```

## P5 Starter — App Service mTLS Terraform

```hcl
resource "azurerm_linux_web_app" "partner_api" {
  name                = "app-taskflow-partner"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  client_certificate_enabled         = true
  client_certificate_mode            = "Required"
  client_certificate_exclusion_paths = "/health"
  https_only                         = true

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
  }
}
```

## P6 Starter — `rotation-runbook.md`

```markdown
# Certificate Rotation Runbook — TaskFlow Confidential Client

## Schedule
Key Vault auto-renews at 80% of lifetime (default policy).

## Pipeline (runs daily)
1. Pull latest version of cert from KV (`Get-AzKeyVaultCertificate`).
2. Compare thumbprint with what's currently registered on the App Registration's `keyCredentials`.
3. If different, **add new credential** (do NOT remove the old). Overlap window: 7 days.
4. After 7 days, remove the old credential.

## Manual recovery
- If the cert is compromised:
  1. KV: `az keyvault certificate set-attributes --enabled false --name taskflow-cert`
  2. App reg: remove `keyCredentials` entry of the bad cert via Graph.
  3. Force new cert: `az keyvault certificate create ...`
  4. Notify affected apps.

## Monitoring
- Event Grid: 30-days-before-expiry → Teams channel.
- KQL alert on cert reads from KV by non-allowlisted MIs.
```

## P7 Starter — DPoP proof skeleton (server side validation)

```csharp
app.MapPost("/transfer", async (HttpContext ctx) =>
{
    var dpop = ctx.Request.Headers["DPoP"].FirstOrDefault()
        ?? throw new UnauthorizedAccessException("Missing DPoP");
    var token = ctx.Request.Headers.Authorization.ToString()["DPoP ".Length..];

    var dpopJwt = new JsonWebToken(dpop);
    var jkt = dpopJwt.Header.Get<string>("jwk")!.ToJkt();      // SHA-256 thumbprint of JWK
    var atJwt = new JsonWebToken(token);
    var cnfJkt = atJwt.GetPayloadValue<JsonElement>("cnf").GetProperty("jkt").GetString();
    if (jkt != cnfJkt) return Results.Unauthorized();

    // Validate DPoP claims (htm, htu, iat, jti not seen recently) — omitted for brevity.
    return Results.Ok();
});
```
