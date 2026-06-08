# Topic 3: Secure API Authentication (Tokens, Certificates)

## What You'll Learn

How to authenticate users and services calling APIs **correctly** — OAuth 2.1 / OIDC flows, JWT validation, refresh strategy, mutual TLS, certificate auth, JWKS rotation, sender-constrained tokens (DPoP, mTLS-bound), Key Vault for cert lifecycle, and the long list of patterns that show up wrong in real codebases.

> If you take one thing from this topic: **never write a token validator from scratch.** Use battle-tested libraries (`Microsoft.AspNetCore.Authentication.JwtBearer`, MSAL). Configure them strictly. Test them adversarially.

---

## 1. Why API Auth is Hard

The protocols look simple from afar. The traps are in the details:

- "We validate the JWT signature" — but with what keys? Cached or live?
- "We use OAuth" — which flow? PKCE? Client secret in the SPA?
- "We require Bearer tokens" — replayable across services? Audience checked?
- "We use mTLS" — chain validation? Pinned? CRL/OCSP?
- "We rotate certificates" — including the trust store? With overlap?

Get one detail wrong and the whole system is broken — without obvious symptoms.

---

## 2. OAuth 2.1 — The Modern Default

OAuth 2.1 consolidates the **good** parts of OAuth 2.0 and bans the **bad** parts:
- **PKCE required** for all authorisation code flows (including server-side).
- **Implicit flow removed.**
- **Resource Owner Password flow removed.**
- **Bearer tokens not allowed in URL query strings.**
- **Refresh-token rotation required.**

### Flows you'll actually use

| Flow | When |
|---|---|
| **Authorization Code + PKCE** | Web apps, SPAs, mobile apps (anywhere a user is present) |
| **Client Credentials** | Service-to-service, no user (workload identity / MI / cert / secret) |
| **On-Behalf-Of (OBO)** | API A receives user token, calls API B as the same user |
| **Device Code** | Devices with no browser (CLI tools, TVs) |
| **Refresh Token** | Maintains a session without re-prompting |

You will **not** use: Implicit, ROPC, or hybrid flows in new code.

### Authorization Code + PKCE in one diagram

```
[Browser] ─1. /authorize?response_type=code&code_challenge=…&...──► [Authz Server]
[Browser] ◄────────────────── 2. redirect with ?code= ─────────── [Authz Server]
[BFF/SPA] ─3. POST /token (code, code_verifier, client_id) ─────► [Authz Server]
[BFF/SPA] ◄────────── 4. access_token + id_token + refresh_token ─[Authz Server]
[BFF/SPA] ─5. GET /api/data  Authorization: Bearer ………──────────► [Resource API]
```

PKCE: client generates a `code_verifier` and sends `SHA256(verifier)` as `code_challenge`. At step 3 it returns the verifier; the server matches. Defeats interception of the code at step 2.

---

## 3. JWT Validation — Get Every Check Right

A JWT looks like `header.payload.signature` and **anyone can forge one** unless you validate properly. The full validation list:

1. **Signature** valid against the public key from JWKS (issuer's `jwks_uri`).
2. **alg** matches expected (e.g., `RS256`); reject `none` and unexpected algs.
3. **iss** equals your expected issuer (e.g., `https://login.microsoftonline.com/<tenantId>/v2.0`).
4. **aud** equals **your** API's audience (the `api://` URI or app ID).
5. **exp** in the future (lifetime not expired).
6. **nbf** in the past (token already valid).
7. **iat** sane (not far in future).
8. **typ** is `JWT` (not `JWE` unless you handle encryption).
9. **azp / appid** is in your allow-list of caller apps (for client-credentials).
10. **roles** / **scp** claim matches the operation being performed.
11. **JWKS cache**: respect cache headers; refresh on `kid` miss.

ASP.NET Core does most of this if configured right:

```csharp
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.Authority = $"https://login.microsoftonline.com/{tenantId}/v2.0";
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer       = $"https://login.microsoftonline.com/{tenantId}/v2.0",
            ValidAudience     = $"api://{apiAppId}",
            ValidateIssuer    = true,
            ValidateAudience  = true,
            ValidateLifetime  = true,
            ValidateIssuerSigningKey = true,
            ClockSkew         = TimeSpan.FromMinutes(2),
            NameClaimType     = "preferred_username",
            RoleClaimType     = "roles"
        };
        o.MapInboundClaims = false;       // keep original short names (oid, scp, etc.)
        o.RefreshOnIssuerKeyNotFound = true;  // pull JWKS again on kid miss
    });
```

Then policies enforce roles/scopes:
```csharp
builder.Services.AddAuthorization(o =>
{
    o.AddPolicy("TasksRead", p => p.RequireClaim("scp", "Tasks.Read")
                                   .RequireClaim("roles", "TaskFlow.Tasks.Read")
                                   .Combine(...) /* OR via custom requirement */);
});
```

### Common JWT bugs

| Bug | Why it's bad |
|---|---|
| Skipping audience check | Tokens minted for another API accepted here |
| `ValidateLifetime = false` | Expired tokens accepted forever |
| Trusting `alg` from token | `none` algorithm attack |
| Caching JWKS forever | Can't rotate signing keys |
| Hard-coded JWKS in source | Same problem |
| Accepting `unsigned` JWE | Misses confidentiality |
| Accepting multiple issuers without validating them all | Trust gone |
| Using a single shared secret as HMAC for prod APIs | Compromise = mint anything |

---

## 4. Scopes vs Roles vs App Permissions

Easy to confuse — they sound similar.

| Concept | Where defined | Who consents |
|---|---|---|
| **Delegated permission / scope (`scp`)** | API's exposed scopes | User (or admin on behalf) |
| **App role (`roles`)** | API's `appRoles` array | Admin only |
| **Group claim** | Entra group membership | Admin (overage handling needed) |

**Delegated scope** = user + app together can do X.
**App role** (application permission) = app can do X **without a user**.
**Group claim** = the user is in group G.

A common design:
- Use **scopes** for user-driven calls (`Tasks.Read`, `Tasks.ReadWrite`).
- Use **app roles** for service-to-service (`TaskFlow.Tasks.Read.All`).
- Reserve **groups** for coarse role mapping (e.g., "tenant admin").

When the API receives a token, it checks:
- If `scp` present → use scope semantics + user identity (`oid`).
- If `roles` present → service identity (`appid` / `oid` of SP).
- Never accept a request lacking *both* (depending on your design).

---

## 5. Refresh Tokens, Rotation, and Sessions

A refresh token (RT) is a long-lived credential to get new access tokens. Treat it with the same care as a password.

Rules:
- **Rotate on use**: every refresh returns a new RT; the old one is invalidated. Required by OAuth 2.1.
- **Bind to the client**: with PKCE in the original flow, and ideally **DPoP** or **mTLS-bound** thereafter (see §6).
- **Detect reuse**: if a rotated RT is presented after rotation, **revoke the whole family** — likely theft.
- **Store securely**: server-side encrypted at rest in a session store; never in `localStorage` for SPAs.
- **Sliding inactivity timeout** + absolute lifetime (e.g., 30 days idle / 90 days absolute).

For SPAs the safest pattern is **Backend-for-Frontend (BFF)**:
- The SPA never holds tokens.
- The BFF authenticates the user, holds the RT in a server-side encrypted session store, and exchanges for access tokens server-side.
- The SPA gets an HttpOnly Secure cookie tied to the BFF.

This eliminates a whole class of XSS-driven token theft.

---

## 6. Sender-Constrained Tokens (DPoP, mTLS)

Bearer tokens are **bearer instruments** — whoever has them is the user. Sender-constrained tokens bind the token to a proof-of-possession key, defeating replay.

### DPoP (Demonstration of Proof-of-Possession)

- Client generates a key pair.
- For each request, signs a DPoP JWT carrying the request URL, method, and a `jti`.
- Server validates the DPoP JWT and that the access token's `cnf` (confirmation) claim matches the key thumbprint.
- A stolen access token alone is useless without the private key.

### Mutual TLS-bound tokens (RFC 8705)

- Client authenticates with a client certificate during the TLS handshake.
- The access token's `cnf.x5t#S256` carries the certificate thumbprint.
- The resource API requires the same client cert on its TLS connection.
- Token presented without the matching cert is rejected.

Use sender-constrained tokens for **high-value APIs**: payments, finance, healthcare, internal service-to-service in zero-trust environments.

---

## 7. Certificate-Based Authentication

Two common modes:

### Mode A — Client authenticating to your API (mTLS)
- Your API accepts only TLS connections where the client presents a cert from a trusted issuer.
- Identity is **the cert subject** (or a SAN). Map it to a principal in your authz layer.
- Useful for: B2B integrations, IoT devices, service-to-service inside a private network.

ASP.NET Core:
```csharp
builder.Services.AddAuthentication(CertificateAuthenticationDefaults.AuthenticationScheme)
    .AddCertificate(o =>
    {
        o.AllowedCertificateTypes  = CertificateTypes.Chained;
        o.RevocationFlag           = X509RevocationFlag.EntireChain;
        o.RevocationMode           = X509RevocationMode.Online;
        o.ValidateCertificateUse   = true;
        o.ValidateValidityPeriod   = true;
        o.Events = new CertificateAuthenticationEvents
        {
            OnCertificateValidated = ctx =>
            {
                var thumb = ctx.ClientCertificate.Thumbprint;
                if (!_allowed.Contains(thumb))
                {
                    ctx.Fail("Untrusted thumbprint");
                    return Task.CompletedTask;
                }
                var claims = new[] { new Claim(ClaimTypes.Name, ctx.ClientCertificate.Subject) };
                ctx.Principal = new ClaimsPrincipal(new ClaimsIdentity(claims, "cert"));
                ctx.Success();
                return Task.CompletedTask;
            }
        };
    });
```

Hosting note: In App Service, enable **client cert** and set forwarding header `X-ARR-ClientCert`. In Front Door / Application Gateway, configure mTLS termination + forwarding.

### Mode B — Your service authenticating to Entra with a certificate (instead of secret)
- Upload the certificate's public key to the App Registration.
- Sign a JWT assertion with the private key.
- Send as `client_assertion` on `/token` requests.

```csharp
var cert = new X509Certificate2(File.ReadAllBytes("client.pfx"), pw);
var app = ConfidentialClientApplicationBuilder
    .Create(clientId)
    .WithCertificate(cert)
    .WithAuthority($"https://login.microsoftonline.com/{tenantId}")
    .Build();
var result = await app.AcquireTokenForClient(new[] { $"api://{apiId}/.default" }).ExecuteAsync();
```

Why prefer certificates over client secrets?
- Higher entropy.
- Longer lifetime acceptable.
- Tied to a key in HSM / Key Vault; private key may never leave.
- Audit clearer (cert thumbprint logged).

Best-of-all: **managed identity** (Topic 1) so even the cert is Azure-managed.

---

## 8. Key Vault for Certificate Lifecycle

Key Vault is the right home for any cert your code uses.

Capabilities:
- **Generate certs** (with built-in CA, DigiCert, or BYO CA).
- **Auto-rotate** before expiry (`life-action: AutoRenew` at percent-of-lifetime, e.g., 80%).
- **Notify** before expiry (Event Grid → Logic App → Teams).
- **Distribute** to App Service / VMSS / AKS via:
  - App Service: KV reference in app settings.
  - AKS: CSI driver for secrets store.
  - VMSS: extension to install in machine store.
- **Audit** every read with diagnostic logs.

Pattern: never embed a `.pfx` in source or pipeline. Vault holds it; runtime fetches.

---

## 9. Storage of Secrets, Tokens, and Refresh State

| Storage | Verdict | Notes |
|---|---|---|
| `appsettings.json` (plain) | Forbidden | Goes to source control |
| `localStorage` (SPA) | Avoid | XSS = token theft |
| Cookies, HttpOnly + Secure + SameSite=Lax | Good | The pattern for sessions |
| Environment variables | OK for non-prod | Leak via crash dumps |
| Azure Key Vault | Best for secrets | Use MI to read |
| App Configuration with KV reference | Best for config + secrets | Single config surface |
| Managed Identity | Best for resource-to-resource | No secret at all |
| Token cache (server-side, encrypted) | Required if you cache | Use MSAL distributed cache |

---

## 10. Defensive Patterns You Should Have

### Strict CORS
Allow only your trusted origins. No wildcards on credentialed requests.

### Anti-CSRF
- Cookie-based sessions: SameSite=Lax (or Strict) + CSRF token on state-changing requests.
- Bearer-only APIs: less risk because tokens aren't auto-attached, but still verify Origin / Referer for sensitive ops.

### Rate limiting per principal
```csharp
builder.Services.AddRateLimiter(o =>
{
    o.AddPolicy("per-user", ctx =>
        RateLimitPartition.GetFixedWindowLimiter(
            ctx.User.FindFirstValue("oid") ?? "anon",
            _ => new() { PermitLimit = 100, Window = TimeSpan.FromMinutes(1) }));
});
```

### Lockout / brute-force protection
- For password endpoints (legacy), exponential backoff + IP throttle.
- For MFA — log and alert on bursts.

### Audit log
- Every authn outcome.
- Every authz decision on sensitive operations.
- Failed token validations (with `kid`, `iss`, `aud` of the failing token).

### Replay protection
- For mTLS-bound or DPoP-bound tokens, validate the `jti` not seen recently.

### Token introspection / revocation
- For OAuth 2.1, support RT revocation endpoint.
- On user sign-out, evict server-side session.

---

## 11. Anti-Patterns

| Anti-pattern | Why it's bad |
|---|---|
| Storing access tokens in `localStorage` | XSS = compromise |
| Long-lived JWTs (days) without rotation | Can't revoke; rotation impossible |
| Skipping `aud` validation | Cross-service token reuse |
| Caching JWKS forever | Can't rotate keys |
| Using HS256 with a shared secret for prod | Shared blast radius |
| Encoding sensitive PII in JWT | Logs everywhere; tokens visible to client |
| Putting JWTs in URL query string | Logs and referer leaks |
| Implicit flow for new SPAs | Banned in 2.1; tokens in URL fragment |
| Forgetting refresh-token rotation | Stolen RT = forever access |
| Skipping PKCE because "we're server-side" | Required in 2.1; cheap to add |
| Not pinning trusted client cert thumbprints | Anyone with a CA-issued cert is in |
| No DPoP / mTLS-bound on high-value APIs | Bearer replay |
| Sharing one client secret across environments | One leak = all envs compromised |

---

## 12. End-to-End Sketch — TaskFlow API

**Users (Angular SPA + .NET BFF):**
- SPA calls `/bff/login` → BFF initiates auth code + PKCE against Entra.
- BFF receives tokens, stores in distributed session (Redis + DPAPI).
- SPA receives HttpOnly cookie.
- SPA calls `/bff/api/projects` — BFF attaches access token to upstream `TaskFlow.Api`.

**TaskFlow.Api:**
- JwtBearer middleware as in §3.
- Policies per scope (`Tasks.Read`, `Tasks.ReadWrite`) and per app role (`TaskFlow.Tasks.Read.All` for background jobs).
- Rate limiter per `oid` and per `appid`.
- Audit log of every authz failure.

**TaskFlow.Worker (background) → TaskFlow.Api:**
- Worker uses managed identity.
- Acquires token for `api://taskflow-api/.default`.
- API allows `appid` matching worker's MI + role `TaskFlow.Tasks.Read.All`.

**External partner integration:**
- mTLS termination on Application Gateway.
- API validates client cert thumbprint against an allow-list stored in App Configuration.
- Per-partner rate limit + audit.

**Cert lifecycle:**
- All certs in Key Vault with auto-renew at 80%.
- Event Grid alert 30 days pre-expiry to a Teams channel.

---

## 13. Mental Model

> Auth is a *configuration* problem more than a code problem. Pick the right flow, validate every claim, never trust a token without checking the audience, and bind high-value tokens to their sender. Then write code that **only** delegates to the framework's middleware.

Move to [Practice Problems](./Practice-Problems.md).
