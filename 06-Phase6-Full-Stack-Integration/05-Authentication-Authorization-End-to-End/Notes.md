# Topic 5: Authentication & Authorization End-to-End

> Build TaskFlow's identity layer from sign-up through silent token refresh, role + policy authorization, password security, and lockout. **Own the JWT issuer**; option to swap to Azure AD B2C later is preserved.

---

## 1. Authentication vs Authorization — Don't Confuse Them

| Term | Question it answers |
|---|---|
| **AuthN (Authentication)** | *Who are you?* |
| **AuthZ (Authorization)** | *What are you allowed to do?* |

ASP.NET Core wires them in this order:

```csharp
app.UseAuthentication(); // sets HttpContext.User from token / cookie
app.UseAuthorization();  // reads HttpContext.User to enforce policies
```

Swap the order → Authorization always sees an anonymous user.

---

## 2. Token-Based Auth: Why JWTs

| Approach | Pros | Cons |
|---|---|---|
| **Session cookies** | Simple, server-side revocation easy | Sticky sessions / shared store; CSRF concerns |
| **JWT** | Stateless, signed, mobile-friendly | Hard to revoke before expiry; size larger than session id |
| **OIDC / Azure AD B2C** | Outsourced identity | External dependency, learning curve |

**TaskFlow choice:** **own JWT issuer** + **rotating refresh tokens**. Stateless API, controlled rotation/revocation via the refresh-token table.

---

## 3. JWT Anatomy

A JWT is `header.payload.signature`, each Base64Url-encoded.

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9     // header  {alg, typ}
eyJzdWIiOiI3NWNkLi4uIiwidW5pcXVlX25hbWUiOiJkZWJAdGFza2Zsb3cubGFiIiwiZXhwIjoxNzU0..., "iat": ..., "iss":"taskflow", "aud":"taskflow-api"}  // payload (claims)
HMAC-SHA256(base64Url(header)+"."+base64Url(payload), signingKey)        // signature
```

**Key claims:**

| Claim | Meaning | TaskFlow uses |
|---|---|---|
| `sub` | Subject (user id) | yes |
| `iss` | Issuer | `https://taskflow.local` |
| `aud` | Audience | `taskflow-api` |
| `exp` | Expiry (unix seconds) | 15 min |
| `nbf` | Not-before | yes |
| `iat` | Issued-at | yes |
| `jti` | Unique token id (for replay defense) | yes |
| custom: `role`, `org_id`, `tier` | Authorization data | yes (small only) |

> **Don't put PII in the token.** Anyone with the JWT can decode the payload — it's signed, not encrypted.

---

## 4. Algorithm Choice: HS256 vs RS256

| Algorithm | Key | When |
|---|---|---|
| **HS256** | Symmetric secret | Single service issues + validates (TaskFlow MVP) |
| **RS256 / ES256** | Public/private key pair | Multiple services validate without sharing the secret |

For TaskFlow MVP (one API), **HS256** is fine. Use `RS256` once the API is split into multiple services or third parties need to validate tokens.

Generate a 32-byte signing key:

```powershell
[Convert]::ToBase64String((1..32 | % { Get-Random -Maximum 256 }))
```

Store in **User Secrets** (dev) / **Key Vault** (prod). Never in `appsettings.json`.

---

## 5. Password Hashing — BCrypt vs Argon2id

Never store plaintext or fast-hash (SHA-256) passwords. Use a **slow** adaptive hash with a per-password salt.

| Algorithm | Notes |
|---|---|
| **BCrypt** | Mature, well-supported (`BCrypt.Net-Next`); cost 12 in 2026 |
| **Argon2id** | OWASP recommendation; memory + time hard; `Konscious.Security.Cryptography.Argon2` |
| **PBKDF2-HMAC-SHA256** | Built-in (`Rfc2898DeriveBytes`); acceptable but weakest of the three |

```csharp
public sealed class BCryptHasher : IPasswordHasher
{
    public string Hash(string p) => BCrypt.Net.BCrypt.HashPassword(p, workFactor: 12);
    public bool Verify(string p, string h) => BCrypt.Net.BCrypt.Verify(p, h);
    public bool NeedsRehash(string h) =>
        BCrypt.Net.BCrypt.PasswordNeedsRehash(h, workFactor: 12);
}
```

On every successful login, call `NeedsRehash` — if true, re-hash with the current cost factor (cheap upgrade path as hardware improves).

---

## 6. Refresh Tokens — Rotating + Persisted

The **access token** is short-lived (15 min). The **refresh token** is long-lived (7 days), opaque, single-use, persisted as a hash.

### Flow

```mermaid
sequenceDiagram
    participant Web
    participant API
    Web->>API: POST /auth/login {email, password}
    API-->>Web: 200 { accessToken, refreshToken }
    Note over Web: stores refresh in HttpOnly cookie
    Web->>API: GET /tasks (Authorization: Bearer access)
    API-->>Web: 200
    Note over Web: 15 min later, access expires
    Web->>API: POST /auth/refresh (cookie sent)
    API-->>Web: 200 { newAccess, newRefresh }
    Note right of API: old refresh marked Used; new one issued
```

**Why rotation?** If a refresh token is stolen, the legitimate user's next refresh fails because the token is already `Used` — the API detects the breach and revokes all sibling tokens.

### Schema

```csharp
public sealed class RefreshToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = default!;  // SHA-256 of opaque value
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public string? RevokedReason { get; set; }   // "used", "logout", "compromised"
    public Guid? ReplacedById { get; set; }      // chain for forensics
    public string CreatedByIp { get; set; } = default!;
    public string? UserAgent { get; set; }
}
```

The plain refresh value goes to the client; we only ever store the **hash**.

---

## 7. Sign-up + Login

```csharp
public sealed record RegisterRequest(string Email, string Password, string DisplayName);

public sealed class RegisterHandler(...) : IRequestHandler<RegisterCommand, Result<TokensDto>>
{
    public async Task<Result<TokensDto>> Handle(RegisterCommand cmd, CancellationToken ct)
    {
        // 1. Lowercase + uniqueness check
        // 2. Hash password (BCrypt cost 12)
        // 3. Insert User
        // 4. Issue access + refresh tokens
        // 5. Return tokens
    }
}
```

**Generic error message** for failures: `"Invalid email or password"` — don't leak which side failed (email enumeration defense).

### Login throttling / lockout

Track failures per `(emailHash, ip)` in Redis or a cache. After 5 failures within 15 min → 429 with `Retry-After`. Reset on success.

```csharp
[HttpPost("login")]
[EnableRateLimiting("login")]   // .NET 8 RateLimiter (5/min/ip)
public Task<TokensDto> Login(LoginRequest body, CancellationToken ct)
    => mediator.Send(new LoginCommand(body), ct);
```

---

## 8. JWT Bearer Configuration

```csharp
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        var jwt = builder.Configuration.GetSection("Jwt").Get<JwtOptions>()!;
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,            ValidIssuer = jwt.Issuer,
            ValidateAudience = true,          ValidAudience = jwt.Audience,
            ValidateLifetime = true,          ClockSkew = TimeSpan.FromMinutes(1),
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Convert.FromBase64String(jwt.SigningKey)),
            NameClaimType = ClaimTypes.NameIdentifier,
            RoleClaimType = "role"
        };
        o.MapInboundClaims = false; // keep claim names verbatim (sub stays sub)
    });
```

> **`ClockSkew`** defaults to 5 min. Reduce to 1 minute or zero — production servers should be NTP-synced.

---

## 9. Generating Tokens

```csharp
public sealed class JwtTokenService(IOptions<JwtOptions> opts, TimeProvider clock) : IJwtTokenService
{
    public (string token, DateTime expiresAt) CreateAccessToken(User u, IEnumerable<string> roles)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var exp = now.AddMinutes(opts.Value.AccessTokenMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, u.Id.ToString()),
            new(JwtRegisteredClaimNames.UniqueName, u.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        claims.AddRange(roles.Select(r => new Claim("role", r)));
        var key = new SymmetricSecurityKey(Convert.FromBase64String(opts.Value.SigningKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(opts.Value.Issuer, opts.Value.Audience, claims, now, exp, creds);
        return (new JwtSecurityTokenHandler().WriteToken(token), exp);
    }
}
```

In .NET 9+, prefer the new `JsonWebTokenHandler` (faster, allocation-friendly).

---

## 10. ICurrentUser + Authorize

```csharp
public interface ICurrentUser
{
    Guid? Id { get; }
    string? Email { get; }
    bool IsInRole(string role);
}

public sealed class HttpCurrentUser(IHttpContextAccessor ctx) : ICurrentUser
{
    private ClaimsPrincipal? P => ctx.HttpContext?.User;
    public Guid? Id => Guid.TryParse(P?.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;
    public string? Email => P?.FindFirstValue(JwtRegisteredClaimNames.UniqueName);
    public bool IsInRole(string role) => P?.IsInRole(role) ?? false;
}
services.AddHttpContextAccessor();
services.AddScoped<ICurrentUser, HttpCurrentUser>();
```

Inject anywhere — handlers, repositories, the audit interceptor. Removes `HttpContext` from the application layer.

---

## 11. Roles vs Policies vs Permissions

| Approach | When |
|---|---|
| **Roles** (`[Authorize(Roles="Admin")]`) | Coarse, app-wide categorization |
| **Policy** (`[Authorize(Policy="CanManageOrg")]`) | Multi-claim or computed checks |
| **Permission/Resource-based** | Per-row authorization (project membership) |

```csharp
builder.Services.AddAuthorization(o =>
{
    o.AddPolicy("AdminOnly", p => p.RequireRole("Admin"));
    o.AddPolicy("CanManageOrg", p => p.RequireAuthenticatedUser().RequireClaim("permission", "org.manage"));
});
```

### Resource-based authorization

Roles aren't enough for "user can edit *this* project". Use `IAuthorizationHandler<TRequirement, TResource>`:

```csharp
public sealed record CanEditProject() : IAuthorizationRequirement;

public sealed class ProjectMemberHandler(TaskFlowDbContext db, ICurrentUser me)
    : AuthorizationHandler<CanEditProject, Project>
{
    protected override async Task HandleRequirementAsync(AuthorizationHandlerContext ctx, CanEditProject _, Project p)
    {
        if (me.Id is null) return;
        var role = await db.ProjectMembers
            .Where(m => m.ProjectId == p.Id && m.UserId == me.Id)
            .Select(m => (ProjectRole?)m.Role).FirstOrDefaultAsync();
        if (role is ProjectRole.Owner or ProjectRole.Admin) ctx.Succeed(_);
    }
}
```

In a controller:

```csharp
var auth = await authService.AuthorizeAsync(User, project, new CanEditProject());
if (!auth.Succeeded) return Forbid();
```

---

## 12. CORS for the Frontend

```csharp
builder.Services.AddCors(o => o.AddPolicy("Web", p => p
    .WithOrigins(builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()!)
    .AllowAnyHeader()
    .AllowAnyMethod()
    .WithExposedHeaders("ETag", "X-Correlation-Id")
    .AllowCredentials()));   // required if refresh-token cookie used
```

For production: restrict to **exact** origins, not `*`. `AllowCredentials` + `*` is rejected by browsers.

---

## 13. Where Does the Refresh Token Live in the Browser?

| Storage | XSS | CSRF | Notes |
|---|---|---|---|
| LocalStorage | ❌ readable by JS — *don't* | safe | most JWT tutorials, but vulnerable to XSS |
| HttpOnly Secure cookie | ✅ JS can't read | needs CSRF mitigation | recommended for refresh token |
| In-memory (JS variable) | ✅ | ✅ | great for **access** token; lost on refresh |

**TaskFlow uses:** access token in **memory**, refresh token in **HttpOnly Secure SameSite=Strict cookie**.

```csharp
Response.Cookies.Append("rt", refreshTokenValue, new CookieOptions
{
    HttpOnly = true,
    Secure = true,
    SameSite = SameSiteMode.Strict,
    Path = "/auth",
    Expires = DateTimeOffset.UtcNow.AddDays(7)
});
```

CSRF concern is reduced by `SameSite=Strict`. For maximum safety, also send a custom header (`X-Requested-With`) checked on the refresh endpoint.

---

## 14. Logout & Revocation

`POST /auth/logout`:

1. Mark the current refresh token as `Revoked`.
2. Clear the cookie.
3. (Optional) blacklist the access JTI in Redis until expiry.

`POST /auth/logout-all` revokes every active refresh token for the user — useful after password change or breach.

> JWTs aren't revocable mid-life by design. Keep access TTLs short and revoke at the refresh layer.

---

## 15. Password Reset Flow

1. User requests reset → server generates a single-use, hashed token, stores it with TTL (1 h), emails the link.
2. User clicks link → submits new password + token → server verifies, updates `PasswordHash`, **revokes all refresh tokens**.
3. Notify user by email that password changed.

Resist enumeration — always reply 200 to `forgot-password` regardless of whether the email exists.

---

## 16. Email Verification

On register:

1. Issue tokens but mark `EmailConfirmed=false`.
2. Generate verification token (single use, 24 h TTL), email link.
3. Restrict sensitive actions to `EmailConfirmed=true` users via a policy.

---

## 17. Rate Limiting (.NET 8+)

```csharp
builder.Services.AddRateLimiter(o =>
{
    o.AddFixedWindowLimiter("login", p => { p.PermitLimit = 5; p.Window = TimeSpan.FromMinutes(1); });
    o.AddPolicy("perUser", ctx =>
        RateLimitPartition.GetTokenBucketLimiter(ctx.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "anon",
            _ => new() { TokenLimit = 100, ReplenishmentPeriod = TimeSpan.FromSeconds(10), TokensPerPeriod = 20 }));
});
app.UseRateLimiter();
```

Apply with `[EnableRateLimiting("login")]` on sensitive endpoints.

---

## 18. Threats and Mitigations Summary

| Threat | Mitigation |
|---|---|
| Brute-force login | Rate limiter + lockout + slow hash |
| XSS stealing token | HttpOnly refresh cookie, CSP, sanitize React rendering |
| Token replay | `jti` blacklist or refresh rotation |
| Refresh token theft | Single-use rotation; sibling revocation on misuse |
| CSRF on refresh | `SameSite=Strict` + double-submit token |
| Algorithm "none" attack | `ValidateIssuerSigningKey=true`, fixed alg list |
| Clock skew acceptance | `ClockSkew` ≤ 1 min + NTP-synced servers |
| Email enumeration | Generic responses |

---

## 19. Common Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| `MapInboundClaims = true` (default) | `sub` becomes `nameidentifier` etc. — confusing | Set `false` for predictable claim names |
| Storing refresh token in localStorage | XSS = full account takeover | HttpOnly cookie |
| 24-hour access tokens | Long compromise window | 5–15 min, refresh rotates |
| Logging tokens | Tokens in log aggregator are bearer creds | Redact `Authorization` header |
| Same signing key in dev + prod | A dev breach compromises prod | Per-environment Key Vault keys |

---

## 20. Interview Q&A

**Q1. Why short-lived access + long-lived refresh?** Limit blast radius of a leaked access token; refresh isolation also enables revocation.

**Q2. JWT vs cookie session?** JWT is stateless (signed claims), great for APIs and mobile; cookie session needs server store but is trivially revocable.

**Q3. HS256 vs RS256?** HS256 = symmetric secret (one issuer/validator); RS256 = public/private — multiple services can validate without secret sharing.

**Q4. How do you revoke a JWT?** You don't, mid-life. Keep TTL short, use a refresh-token table to control session, optionally blacklist `jti` in cache.

**Q5. Where to store refresh tokens client-side?** HttpOnly Secure SameSite=Strict cookie — out of JS reach.

**Q6. What's `ClockSkew` and why default 5 min?** Tolerance window for clock drift between issuer and validator. Reduce on time-synced infra.

**Q7. Difference between role and policy authorization?** Role = single claim check; policy = composable requirements (claim + role + custom handler).

**Q8. Resource-based authorization use case?** "Can user X edit project Y?" — depends on row-level membership, not a global role.

**Q9. Why hash refresh tokens server-side?** A DB leak shouldn't reveal active session secrets; client holds the only plaintext copy.

**Q10. CSRF in JWT-with-cookie setup?** SameSite=Strict mitigates browser-driven CSRF; backup with custom header (`X-Requested-With`) and CORS allow-list.

---

## 21. Further Reading

- IETF — RFC 7519 (JWT), RFC 6749 (OAuth 2.0), RFC 6750 (Bearer tokens)
- OWASP — *Authentication Cheat Sheet*, *JWT Cheat Sheet*, *Session Management Cheat Sheet*
- Microsoft — `Microsoft.AspNetCore.Authentication.JwtBearer` docs
- Auth0 blog — *Refresh token rotation*
- Andrew Lock — JWT bearer auth deep dives
