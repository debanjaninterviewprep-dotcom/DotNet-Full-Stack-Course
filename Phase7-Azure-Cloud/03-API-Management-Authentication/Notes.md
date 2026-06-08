# Topic 3: Azure API Management (APIM) with Authentication

> Topic 2 gave you compute. This topic gives you the **front door**: Azure API Management. APIM sits between your clients and your APIs (Function Apps, App Services, anything HTTPS) and adds authentication, rate limiting, transformation, caching, and observability — without changing the backend code. By the end of this topic you'll have a public, secure, key + JWT-protected facade for TaskFlow.

---

## 1. Why an API Gateway?

Without a gateway, every microservice has to implement:

- AuthN/AuthZ
- Rate limiting & quotas
- Versioning
- CORS
- Request/response logging
- Header rewriting
- Caching
- Mock responses for dev

That's duplication, drift, and security risk. A gateway centralizes those concerns at the **edge**, leaving services to do business logic only.

```
Internet ──► APIM (gateway) ──► Function App  (private)
                            ──► App Service   (private)
                            ──► Logic App     (private)
```

> **Key idea:** Backends should be **callable only by APIM** (private network or restriction by header/IP). Clients call the APIM hostname; APIM calls backends.

---

## 2. APIM Tiers

| Tier | Cost | VNet | SLA | Multi-region | Use for |
|---|---|---|---|---|---|
| **Consumption** | Per-call (~$0.10/M) | No | 99.95 | No | Dev, low traffic, serverless front |
| **Basic v2 / Standard v2** | ~$10/day+ | No | 99.95 | No | Most production |
| **Premium** | ~$70/day+ | Yes | 99.99 | Yes | Enterprise, regulated |
| **Developer** | Cheap, no SLA | Yes (limited) | None | No | Pre-prod sandbox |

For Phase 7 / TaskFlow we use the **Consumption** tier — no fixed cost, scales to zero. It has a few limits (no caching policy in the UI, no built-in dev portal feedback) but covers 90% of real-world auth/rate-limit scenarios.

---

## 3. APIM Building Blocks

| Concept | What it is |
|---|---|
| **API** | A logical group of operations (paths) representing a backend |
| **Operation** | One HTTP verb + path (e.g. `GET /tasks/{id}`) |
| **Backend** | The real upstream URL (Function App, App Service, Logic App) |
| **Product** | A bundle of APIs visible to subscribers (e.g. *Free*, *Pro*) |
| **Subscription** | A consumer's key to a product |
| **Policy** | XML rules that run on inbound, outbound, on-error, backend |
| **Named Value** | A reusable variable / secret reference (Key Vault possible) |
| **Revision** | Non-breaking edit of an API; can promote to current |
| **Version** | Breaking change of an API (`v1`, `v2`) — separate URL |

---

## 4. The Policy Pipeline

Every request passes through four stages:

```
       ┌─────────┐   ┌──────────┐   ┌─────────┐   ┌──────────┐
Req ──►│ Inbound │──►│ Backend  │──►│Outbound │──►│Response  │
       └─────────┘   └──────────┘   └─────────┘   └──────────┘
            ▲                                            ▲
            └─────────── On-error  ◄────────────────────┘
```

Policies are **XML snippets**. Common ones:

- `<rate-limit>` / `<quota>`
- `<validate-jwt>`
- `<authentication-managed-identity>`
- `<set-backend-service>`
- `<rewrite-uri>` / `<set-header>`
- `<cache-lookup>` / `<cache-store>` (not Consumption)
- `<choose>...<when>...<otherwise>`
- `<return-response>`

### A complete inbound policy

```xml
<policies>
  <inbound>
    <base />
    <!-- Rate limit: 60 calls/min per subscription key -->
    <rate-limit-by-key calls="60" renewal-period="60"
                       counter-key="@(context.Subscription.Id)" />
    <!-- Validate Microsoft Entra-issued JWT -->
    <validate-jwt header-name="Authorization"
                  failed-validation-httpcode="401"
                  failed-validation-error-message="Unauthorized">
      <openid-config url="https://login.microsoftonline.com/{{tenantId}}/v2.0/.well-known/openid-configuration" />
      <required-claims>
        <claim name="aud">
          <value>{{apiAudience}}</value>
        </claim>
      </required-claims>
    </validate-jwt>
    <!-- Inject correlation ID -->
    <set-header name="x-correlation-id" exists-action="skip">
      <value>@(Guid.NewGuid().ToString())</value>
    </set-header>
  </inbound>
  <backend><base /></backend>
  <outbound>
    <base />
    <set-header name="x-powered-by" exists-action="delete" />
  </outbound>
  <on-error><base /></on-error>
</policies>
```

> **`<base />`** runs the inherited policy at that level (global → product → API → operation). Always include it.

---

## 5. Three Authentication Patterns You Must Know

### 5.1 Subscription Key Only (the simple default)

Every subscriber gets a key (`Ocp-Apim-Subscription-Key` header). APIM rejects requests without it. **Use case:** internal/partner APIs where simple identification is enough.

- Configure: enable on Product or API.
- Pros: dead simple.
- Cons: a key is bearer credential, no per-user identity, hard to revoke individuals.

### 5.2 Subscription Key + Microsoft Entra JWT (recommended for TaskFlow)

Client authenticates the **user** with Entra (acquires JWT), then calls APIM with **both** the subscription key (identifies *the app*) and the JWT (identifies *the user*).

- APIM validates both, forwards the original Authorization header to the backend (or rewrites).
- Backend trusts only requests via APIM (e.g. requires a network restriction or a known header).

### 5.3 OAuth Client Credentials (machine-to-machine)

For service-to-service, a backend service acquires a token from Entra using its own client ID/secret (or MI). APIM validates `roles` or `scp` claim.

```xml
<required-claims>
  <claim name="roles" match="any">
    <value>TaskFlow.Tasks.Read</value>
    <value>TaskFlow.Tasks.Write</value>
  </claim>
</required-claims>
```

---

## 6. CORS at the Edge

Browsers preflight `OPTIONS` requests. Handle them in APIM, not in your backend:

```xml
<inbound>
  <base />
  <cors allow-credentials="true">
    <allowed-origins>
      <origin>https://taskflow.example.com</origin>
      <origin>http://localhost:5173</origin>
    </allowed-origins>
    <allowed-methods>
      <method>GET</method><method>POST</method>
      <method>PUT</method><method>DELETE</method>
      <method>OPTIONS</method>
    </allowed-methods>
    <allowed-headers>
      <header>*</header>
    </allowed-headers>
  </cors>
</inbound>
```

---

## 7. Rate Limiting & Quotas

| Policy | Granularity | Window | Use for |
|---|---|---|---|
| `<rate-limit>` | Per subscription | Short (per minute) | Burst protection |
| `<rate-limit-by-key>` | Custom key (IP, user, sub) | Short | Per-user fairness |
| `<quota>` | Per subscription | Long (per day/month) | Plan tiers (Free vs Pro) |
| `<quota-by-key>` | Custom key | Long | Per-user monthly cap |

```xml
<rate-limit-by-key calls="100" renewal-period="60"
                   counter-key="@(context.Request.IpAddress)"
                   increment-condition="@(context.Response.StatusCode == 200)" />
```

> **Tip:** Counter is per-region per-instance. For Consumption tier, the counter is global. For Premium/Standard, set `counter-key` carefully.

---

## 8. Versioning & Revisions

| Concept | Breaking change? | URL changes? | Use for |
|---|---|---|---|
| **Revision** | No | No | Bug fix, new optional param |
| **Version** | Yes | Yes (e.g. `/v1` → `/v2`) | Renamed field, removed op |

Strategies for versioning URLs:

- **Path** — `/api/v1/tasks` (most common, what TaskFlow uses)
- **Query string** — `/api/tasks?api-version=1.0`
- **Header** — `Api-Version: 1.0`

---

## 9. Backend Authentication: APIM → Function App / App Service

Once APIM holds the front door, the backend must **only accept requests from APIM**. Three ways:

1. **Function key in `<set-header>`** — APIM injects `x-functions-key`. Easy but rotates manually.
2. **Managed Identity** — APIM uses its own MI to call backends that accept Entra tokens. Best.
3. **Network restriction** — Function App / App Service `access restrictions` whitelist APIM's outbound IPs (Consumption: published IP range; Premium: private VNet).

Example using MI to authenticate to a Function App with Easy Auth (Entra) enabled:

```xml
<inbound>
  <base />
  <authentication-managed-identity resource="<backend-app-client-id>" />
  <set-backend-service base-url="https://func-taskflow-dev.azurewebsites.net/api" />
</inbound>
```

---

## 10. The Developer Portal

APIM ships with a **developer portal** at `https://<your-apim>.developer.azure-api.net`:

- Auto-generated documentation from your imported OpenAPI/Swagger.
- Interactive **Try it** console.
- Self-service subscription signup.
- Customizable look-and-feel (Visual Editor).

For TaskFlow, you'll publish your OpenAPI from Phase 6 here so partners can self-serve.

---

## 11. Observability

APIM emits metrics into Azure Monitor and traces into Application Insights:

- **Logs**: every request with `apiId`, `operationId`, latency, status, subscription name.
- **Metrics**: capacity, gateway requests, failures, gateway response time.
- **Diagnostic settings**: send to Log Analytics, Storage, or Event Hubs.

Wire APIM → Application Insights with one toggle: *Diagnose & solve problems → Application Insights*. Sample at 10–50% in production to control cost.

---

## 12. Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Expose Function App / App Service directly to the internet | Put APIM in front, lock backend |
| Store secrets in policy XML | Use **Named Values** with Key Vault references |
| Implement auth in every backend service | Validate JWT once at APIM, forward |
| Use one Product for everything | One Product per consumer tier (Free / Pro / Internal) |
| Edit "Current" revision in production | Create a new revision, test, then **set as current** |
| Hard-code backend URLs | Use **Backends** + Named Values |

---

## 13. Decision Flow for TaskFlow

1. **API design** — your OpenAPI spec (Phase 6 P5) is the source of truth.
2. **Import** into APIM (Portal or `az apim api import`).
3. **Set the backend** to your Function App (Topic 2).
4. **Create a Product** "TaskFlow Core" with your APIs in it.
5. **Add policies**:
    - Subscription key required
    - JWT validation (Entra)
    - CORS
    - Rate limit per subscription
    - Correlation ID
6. **Subscribe** with your client (frontend, Postman) and call.

---

## Further Reading

- [APIM policy reference](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [Validate JWT policy](https://learn.microsoft.com/azure/api-management/validate-jwt-policy)
- [Authenticate to backend with MI](https://learn.microsoft.com/azure/api-management/api-management-authenticate-authorize-azure-openai)
- [Consumption tier features](https://learn.microsoft.com/azure/api-management/api-management-features)
- [Versions and revisions](https://learn.microsoft.com/azure/api-management/api-management-versions)
