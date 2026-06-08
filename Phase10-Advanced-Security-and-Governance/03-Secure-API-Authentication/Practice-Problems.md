# Practice Problems — Secure API Authentication

> Tell me **"check"** after finishing.

---

## P1 — JWT Validation Hardening

**Goal:** Take an insecure ASP.NET Core API and harden its JWT validation.

Starting point (insecure):
```csharp
builder.Services.AddAuthentication("Bearer").AddJwtBearer(o =>
{
    o.Authority = "https://login.microsoftonline.com/common";
    o.TokenValidationParameters = new() { ValidateIssuer = false, ValidateAudience = false };
});
```

**Tasks:**
1. Fix every issue: issuer pinned to tenant, audience pinned to your API, lifetime + signing key validated, clock skew tightened, MapInboundClaims = false, RefreshOnIssuerKeyNotFound = true, role/scope policies.
2. Add a custom `ITokenValidator` filter that logs failed validations with `kid`, `iss`, `aud`, reason.
3. Write 6 xUnit tests against a fake JWT issuer (using `Microsoft.IdentityModel.Tokens` + an in-test signing key swap) — cover: valid, wrong audience, wrong issuer, expired, none-alg, wrong key.

**Deliverable:** Hardened Program.cs + custom filter + test project.

**Look-fors:** Every validation flag explicit; tests cover bad cases; filter doesn't log token contents.

---

## P2 — Authorization-Code-with-PKCE for an Angular + BFF

**Goal:** Build the BFF pattern for a small TaskFlow front-end.

**Tasks:**
1. .NET 8 minimal API as BFF using `Microsoft.Identity.Web`.
2. `/bff/login`, `/bff/logout`, `/bff/me`, and `/bff/api/{*path}` proxy.
3. Tokens cached server-side in a distributed cache (Redis or in-memory for dev).
4. Angular SPA calls `/bff/api/...` with credentials cookie; never sees a token.
5. CSRF protection on state-changing requests.
6. SameSite=Lax cookies; HttpOnly; Secure.

**Deliverable:** BFF source, Angular module/component source, README with run instructions.

**Look-fors:** SPA bundle contains zero token logic; cookies set with correct flags; CSRF token present; logout actually clears session.

---

## P3 — Refresh-Token Rotation & Reuse Detection

**Goal:** Implement RT rotation and detect reuse.

**Tasks:**
1. Use MSAL's distributed token cache; ensure RT is rotated on each refresh.
2. Implement a small store of "previously seen RTs" (hash only, with a TTL) per user.
3. If a rotated RT is presented after rotation, revoke the whole family (sign user out across sessions) and alert.
4. Unit test: simulate a stolen RT being used after rotation; assert revocation occurs and an alert is emitted.

**Deliverable:** Source + tests.

**Look-fors:** Only hashes of RT stored; family revocation actually invalidates sibling sessions; alert path is real.

---

## P4 — Service-to-Service with Managed Identity + App Role

**Goal:** Background worker calls TaskFlow API as itself, validated server-side via an app role.

**Tasks:**
1. App Registration for TaskFlow API exposes app role `TaskFlow.Tasks.Read.All` (application permission).
2. Assign the role to the worker's system-assigned MI through Microsoft.Graph PowerShell:
   ```powershell
   New-MgServicePrincipalAppRoleAssignment ...
   ```
3. Worker code uses `DefaultAzureCredential` to get a token for `api://<apiAppId>/.default`.
4. API validates: `roles` claim contains the expected role; `appid` is on the allow-list.
5. Demonstrate 200 then revoke the role and demonstrate 403.

**Deliverable:** Worker + API source + role-assignment script + screenshots.

**Look-fors:** No secrets; role check is server-side; allow-list of appids matched.

---

## P5 — Mutual TLS for a Partner Integration

**Goal:** Authenticate a partner via mTLS on an App Service-hosted API.

**Tasks:**
1. Enable client-cert requirement on App Service (Terraform).
2. ASP.NET Core: `AddCertificate` with chained validation, online revocation, thumbprint allow-list from configuration.
3. Map cert subject → ClaimsPrincipal with a partner-id claim.
4. Demonstrate: trusted cert returns 200; untrusted thumbprint returns 403; revoked cert returns 403.

**Deliverable:** Terraform + API source + curl test commands showing all three cases.

**Look-fors:** Revocation actually checked; allow-list stored centrally (not hardcoded); cert claim feeds authz.

---

## P6 — Certificate-Based Authentication to Entra

**Goal:** Replace a confidential-client secret with a Key Vault-managed certificate.

**Tasks:**
1. Generate a cert in Key Vault (subject `CN=taskflow-api-svc`, auto-renew at 80%).
2. Upload public key to the App Registration `keyCredentials`.
3. App code:
   ```csharp
   var cert = await new SecretClient(kvUri, cred).GetSecretAsync("taskflow-cert");
   var x509 = new X509Certificate2(Convert.FromBase64String(cert.Value.Value), "");
   var app  = ConfidentialClientApplicationBuilder.Create(clientId)
                   .WithCertificate(x509).WithAuthority(authority).Build();
   ```
4. Demonstrate token acquisition.
5. Document rotation procedure (KV auto-renews cert; pipeline updates app-registration `keyCredentials` from KV via a scheduled job).

**Deliverable:** Source + rotation runbook.

**Look-fors:** No secret in code or config; rotation job documented; old cert overlap period exists.

---

## P7 — DPoP or mTLS-Bound Token Demo

**Goal:** Demonstrate sender-constrained tokens for a high-value endpoint.

Pick **one** (DPoP or mTLS-bound):

### DPoP path
- Client generates an EC key pair.
- Acquires an access token from Entra (or a self-hosted IdP that supports DPoP).
- For each request, attaches DPoP proof JWT in `DPoP` header.
- Server validates `cnf.jkt` against DPoP JWT's key.

### mTLS-bound path
- Client presents a client cert in TLS handshake.
- Server confirms the token's `cnf.x5t#S256` matches the cert thumbprint.

**Tasks:**
1. Working minimum API endpoint that demands sender-constrained tokens.
2. Test showing: valid token + valid binding → 200; valid token + wrong binding → 401.
3. Note in `notes.md` why this matters for the chosen scenario.

**Deliverable:** Source + tests + notes.

**Look-fors:** Real binding (not just header check); failure path tested.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 15 | All flags explicit; tests cover all cases |
| P2 | 20 | SPA carries zero token logic; CSRF + cookie flags right |
| P3 | 15 | RT family revoked on reuse; alerting wired |
| P4 | 15 | Role check works; no secrets |
| P5 | 15 | mTLS works including revocation |
| P6 | 10 | Cert from KV; rotation runbook |
| P7 | 10 | Sender-constrained working end-to-end |

Total: 100. Pass: 70.
