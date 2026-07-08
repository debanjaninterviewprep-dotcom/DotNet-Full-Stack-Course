# Topic 05: Authentication & Authorization — End-to-End — Interview Questions

---

## Q1. What is the end-to-end JWT authentication flow?
**Answer:**
```
1. User submits credentials (POST /api/auth/login)
2. Server validates credentials
3. Server generates: { accessToken (15min), refreshToken (7days) }
4. Client stores tokens (HttpOnly cookie or memory + secure storage)
5. Client sends: Authorization: Bearer {accessToken} on every request
6. Server middleware validates JWT (signature, expiry, issuer, audience)
7. Server sets HttpContext.User from token claims
8. When accessToken expires → client uses refreshToken to get new pair
9. On logout → revoke refreshToken server-side
```

```csharp
// Login endpoint
[HttpPost("login"), AllowAnonymous]
public async Task<ActionResult<AuthResponseDto>> Login(LoginDto dto)
{
    var user = await _userMgr.FindByEmailAsync(dto.Email);
    if (user is null || !await _userMgr.CheckPasswordAsync(user, dto.Password))
        return Unauthorized("Invalid credentials");

    var accessToken  = _tokenService.GenerateAccessToken(user);
    var refreshToken = await _tokenService.GenerateRefreshTokenAsync(user.Id);

    return Ok(new AuthResponseDto {
        AccessToken  = accessToken,
        RefreshToken = refreshToken,
        ExpiresIn    = 900 // 15 minutes
    });
}
```

---

## Q2. How do you store JWT tokens securely on the frontend?
**Answer:**
```
Option 1: HttpOnly Cookie (recommended)
  + JavaScript cannot access it → XSS-proof
  + Automatically sent on every request
  - Vulnerable to CSRF attacks → mitigate with SameSite=Strict and CSRF tokens
  - Harder to implement for mobile apps

Option 2: Memory (JavaScript variable) + Refresh Token in HttpOnly Cookie
  + Access token in memory → not persisted → XSS-safe
  + Refresh token in HttpOnly cookie → survives page refresh
  - Access token lost on page refresh → use refresh flow to restore

Option 3: localStorage (NOT recommended for sensitive tokens)
  + Simple to implement
  - Vulnerable to XSS attacks → any injected script can steal the token

// ASP.NET Core: set token as HttpOnly cookie
Response.Cookies.Append("refreshToken", refreshToken, new CookieOptions {
    HttpOnly = true,
    Secure   = true,
    SameSite = SameSiteMode.Strict,
    Expires  = DateTimeOffset.UtcNow.AddDays(7)
});
```

---

## Q3. What is refresh token rotation and why is it important?
**Answer:**
Token rotation issues a new refresh token on every use — invalidating the previous one:

```csharp
// Refresh endpoint
[HttpPost("refresh"), AllowAnonymous]
public async Task<ActionResult<AuthResponseDto>> Refresh([FromBody] RefreshDto dto)
{
    // Validate existing refresh token
    var stored = await _tokenRepo.GetByTokenAsync(dto.RefreshToken);

    if (stored is null)
        return Unauthorized("Invalid refresh token");

    if (stored.IsRevoked)
    {
        // Token reuse detected — revoke entire family (security measure)
        await _tokenRepo.RevokeAllForUserAsync(stored.UserId);
        return Unauthorized("Token reuse detected — please login again");
    }

    if (stored.ExpiresAt < DateTime.UtcNow)
        return Unauthorized("Refresh token expired");

    // Rotate: revoke old, issue new
    await _tokenRepo.RevokeAsync(stored);
    var user = await _userMgr.FindByIdAsync(stored.UserId.ToString());
    var newAccess  = _tokenService.GenerateAccessToken(user!);
    var newRefresh = await _tokenRepo.CreateAsync(stored.UserId, stored.FamilyId); // same family

    return Ok(new AuthResponseDto { AccessToken = newAccess, RefreshToken = newRefresh });
}
```

**Why rotation matters:** If an attacker steals a refresh token and uses it, the original token is invalidated. When the legitimate user tries to use their (now revoked) token, the server detects reuse and revokes all tokens for that user.

---

## Q4. How do you implement role-based access control end-to-end?
**Answer:**
```csharp
// Backend: Add roles to JWT
var roles = await _userMgr.GetRolesAsync(user);
var claims = roles.Select(r => new Claim(ClaimTypes.Role, r)).ToList();
claims.Add(new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()));

// Backend: Protect endpoints
[Authorize(Roles = "Admin")]
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id) { }

// Backend: Check in service
if (!_currentUser.IsInRole("Admin") && order.UserId != _currentUser.Id)
    throw new ForbiddenException("Cannot access this order");
```

```typescript
// Angular: Parse JWT and check roles
const token = localStorage.getItem('token');
const payload = JSON.parse(atob(token.split('.')[1]));
const roles: string[] = payload.role ?? []; // from JWT claim

// Angular Guard
const adminGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  return auth.hasRole('Admin') ? true : inject(Router).createUrlTree(['/unauthorized']);
};

// Angular template
@if (authService.hasRole('Admin')) {
  <button (click)="deleteUser()">Delete</button>
}
```

---

## Q5. What is the difference between `[Authorize]` and resource-based authorization?
**Answer:**
```csharp
// Simple [Authorize] — checks authentication + role/policy
[Authorize(Roles = "Admin")]
public async Task<IActionResult> DeleteUser(int id) { }
// Problem: ANY admin can delete ANY user — no ownership check

// Resource-based — checks relationship between user and specific resource
[Authorize]
public async Task<IActionResult> UpdateOrder(int id, UpdateOrderDto dto)
{
    var order = await _repo.GetByIdAsync(id);
    if (order is null) return NotFound();

    // Check: can THIS user edit THIS order?
    var authResult = await _authorizationService.AuthorizeAsync(User, order, "CanEditOrder");
    if (!authResult.Succeeded) return Forbid();

    await _svc.UpdateAsync(id, dto);
    return NoContent();
}

// Handler checks ownership
public class OrderAuthorizationHandler
    : AuthorizationHandler<CanEditOrderRequirement, Order>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext ctx,
        CanEditOrderRequirement requirement,
        Order order)
    {
        var userId = ctx.User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (order.UserId.ToString() == userId || ctx.User.IsInRole("Admin"))
            ctx.Succeed(requirement);
        return Task.CompletedTask;
    }
}
```

---

## Q6. What is the security vulnerability in exposing sequential IDs?
**Answer:**
Sequential integer IDs expose:
- **Enumeration attacks:** `GET /api/orders/1`, `/orders/2`, `/orders/3` — scrape all data.
- **Business intelligence:** Order volume (last order = total orders created).

**Solutions:**
```csharp
// Option 1: GUIDs (no guessing, but larger, unordered)
public class Order { public Guid Id { get; set; } = Guid.NewGuid(); }

// Option 2: Sequential GUIDs (ordered for DB index performance)
using MassTransit; // or similar library
public Guid NewId() => NewId.NextGuid(); // time-ordered GUID

// Option 3: Hashids (encode int as short hash)
var hashids = new Hashids("secret_salt", minHashLength: 8);
string hash = hashids.Encode(42);  // "abc123de"
int id = hashids.Decode(hash)[0];  // 42

// Option 4: Authorization checks (still allow sequential but verify ownership)
var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id && o.UserId == currentUserId);
if (order is null) return NotFound(); // same response for not-found and not-owned
```

---

## Q7. What is CSRF and how do you protect against it?
**Answer:**
CSRF (Cross-Site Request Forgery) tricks a victim into making authenticated requests to your API from another site:

```
Scenario:
1. User logs into your bank (session cookie set)
2. User visits evil.com
3. evil.com has: <form action="https://bank.com/transfer" method="POST">
4. Form auto-submits → browser sends bank's cookie → transfer happens!
```

**Mitigations:**
```csharp
// 1. SameSite cookie attribute (best protection)
Response.Cookies.Append("auth", token, new CookieOptions {
    SameSite = SameSiteMode.Strict  // cookie not sent on cross-site requests
});

// 2. Anti-forgery tokens (traditional MVC)
builder.Services.AddAntiforgery();
// All POST/PUT/PATCH/DELETE forms must include __RequestVerificationToken

// 3. Custom header check (for AJAX/SPA)
// Attacker forms can't set custom headers:
[HttpPost]
public IActionResult Action()
{
    if (!Request.Headers.ContainsKey("X-Requested-With"))
        return Forbid();
}

// 4. For JWT in Authorization header (not cookies)
// CSRF doesn't apply — attacker can't set Authorization header
```

---

## Q8. What is OAuth2 implicit flow vs authorization code flow?
**Answer:**
```
Authorization Code Flow + PKCE (current best practice for SPAs/mobile):
1. App redirects to Auth Server with code_challenge (hash of random verifier)
2. User logs in on Auth Server
3. Auth Server returns short-lived authorization code to redirect_uri
4. App exchanges code + code_verifier for tokens
5. Auth Server verifies: hash(code_verifier) == code_challenge

Benefits:
- code_verifier never travels in URL (no leak in browser history/referer)
- Tokens returned server-to-server (not in URL fragment)
- Even if code is intercepted, attacker can't use it without code_verifier

Implicit Flow (deprecated):
- Tokens returned directly in URL fragment → visible in browser history
- No refresh tokens → poor UX
- ❌ Do not use for new applications
```

---

## Q9. What is the principle of least privilege and how do you apply it to APIs?
**Answer:**
Only grant the minimum permissions necessary to perform a task:

```csharp
// Define granular permissions
public static class Permissions
{
    public const string UsersRead   = "users:read";
    public const string UsersWrite  = "users:write";
    public const string UsersDelete = "users:delete";
    public const string OrdersRead  = "orders:read";
    public const string ReportsView = "reports:view";
}

// Role → permissions mapping
Admin   = { UsersRead, UsersWrite, UsersDelete, OrdersRead, ReportsView, ... all }
Manager = { UsersRead, OrdersRead, ReportsView }
User    = { OrdersRead (own orders only) }
Reporter = { ReportsView }

// API scopes in JWT
{ "permissions": ["orders:read", "orders:write"] }

// Endpoint authorization
builder.Services.AddAuthorization(opts => {
    opts.AddPolicy("CanDeleteUsers", p => p.RequireClaim("permissions", Permissions.UsersDelete));
});

[Authorize(Policy = "CanDeleteUsers")]
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id) { }
```

---

## Q10. What is SSO (Single Sign-On) and how does it work with ASP.NET Core?
**Answer:**
SSO allows users to authenticate once and access multiple applications:

```
User → App A (no session) → Redirect to Identity Server
User logs in at Identity Server
Identity Server → Returns to App A with token
App A sets session → User is logged in

User → App B (no session) → Redirect to Identity Server
Identity Server checks existing session → SSO → Returns token
App B sets session → User is logged in (without re-entering credentials)
```

```csharp
// ASP.NET Core with Azure AD SSO
builder.Services.AddAuthentication().AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// Or with Auth0
builder.Services.AddAuthentication(options => {
    options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = "Auth0";
})
.AddCookie()
.AddOAuth("Auth0", options => {
    options.Authority = builder.Configuration["Auth0:Domain"];
    options.ClientId = builder.Configuration["Auth0:ClientId"];
    options.ClientSecret = builder.Configuration["Auth0:ClientSecret"];
});
```

---

## Q11. What is claims transformation and when is it needed?
**Answer:**
Claims transformation adds or modifies claims from an external token to match your application's needs:

```csharp
public class AppClaimsTransformation : IClaimsTransformation
{
    private readonly IUserRepository _userRepo;

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        // Load user from DB, add application-specific claims
        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = await _userRepo.GetByIdAsync(int.Parse(userId!));

        if (user is null) return principal;

        var identity = (ClaimsIdentity)principal.Identity!;

        // Add app-specific claims not in the JWT
        if (!identity.HasClaim(c => c.Type == "tenant_id"))
            identity.AddClaim(new Claim("tenant_id", user.TenantId.ToString()));

        if (!identity.HasClaim(c => c.Type == "subscription"))
            identity.AddClaim(new Claim("subscription", user.SubscriptionTier));

        return principal;
    }
}

builder.Services.AddTransient<IClaimsTransformation, AppClaimsTransformation>();
```

---

## Q12. What is the difference between `[Authorize]` and middleware authentication?
**Answer:**
```csharp
// Middleware (UseAuthentication) — runs for ALL requests, sets HttpContext.User
// Does NOT reject requests — just sets the identity if a valid token exists
app.UseAuthentication(); // "I'll try to identify you"

// [Authorize] attribute — rejects unauthenticated/unauthorized requests
// Returns 401 if not authenticated, 403 if not authorized
[Authorize] // "You MUST be authenticated to access this"
public IActionResult Secret() => Ok();

// Global authorization policy — all endpoints require auth by default
builder.Services.AddAuthorization(opts =>
    opts.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser().Build());

// Then opt out specific endpoints
[AllowAnonymous] [HttpGet("public")]
public IActionResult Public() => Ok();
```

---

## Q13. How do you test authentication and authorization in integration tests?
**Answer:**
```csharp
// Custom WebApplicationFactory with test auth
public class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(services => {
            services.AddAuthentication("Test")
                .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", _ => {});
        });
    }
}

// Test auth handler — inject any identity
public class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var claims = new[] {
            new Claim(ClaimTypes.NameIdentifier, "1"),
            new Claim(ClaimTypes.Role, "Admin")
        };
        var identity = new ClaimsIdentity(claims, "Test");
        var principal = new ClaimsPrincipal(identity);
        return Task.FromResult(AuthenticateResult.Success(
            new AuthenticationTicket(principal, "Test")));
    }
}

// Test
[Fact]
public async Task AdminEndpoint_RequiresAdminRole()
{
    var client = _factory.CreateClient();
    var response = await client.DeleteAsync("/api/users/1");
    Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
}
```

---

## Q14. What is two-factor authentication (2FA) and how is it implemented?
**Answer:**
2FA adds a second verification step beyond password:

```csharp
// ASP.NET Core Identity + TOTP (Time-based One-Time Password)

// Enable 2FA for a user
await _userMgr.SetTwoFactorEnabledAsync(user, true);
var authenticatorKey = await _userMgr.GetAuthenticatorKeyAsync(user);
// Show QR code to user (encodes authenticatorKey)
// User scans with Google Authenticator / Microsoft Authenticator

// Verify TOTP code on login
[HttpPost("verify-2fa")]
public async Task<IActionResult> Verify2FA(TwoFactorDto dto)
{
    var user = await _signMgr.GetTwoFactorAuthenticationUserAsync();
    if (user is null) return Unauthorized();

    var isValid = await _userMgr.VerifyTwoFactorTokenAsync(
        user, _userMgr.Options.Tokens.AuthenticatorTokenProvider, dto.Code);

    if (!isValid) return Unauthorized("Invalid 2FA code");

    var token = _tokenService.GenerateAccessToken(user);
    return Ok(new { token });
}
```

---

## Q15. What is the principle of defense in depth for API security?
**Answer:**
Defense in depth applies multiple security layers — one layer failing doesn't compromise the system:

```
Layer 1: Network     — Firewall, DDoS protection, VPN for admin endpoints
Layer 2: Transport   — TLS/HTTPS everywhere, certificate pinning for mobile
Layer 3: Authentication — JWT + HTTPS, short expiry, refresh rotation
Layer 4: Authorization — [Authorize], role/policy checks, resource-based auth
Layer 5: Input Validation — FluentValidation, never trust client input
Layer 6: Output Encoding — DTOs prevent over-exposure, no entity serialization
Layer 7: Rate Limiting — throttle auth endpoints, per-user limits
Layer 8: Monitoring — log all auth events, alert on anomalies
Layer 9: Secrets Management — Azure Key Vault, never commit secrets

An attacker who bypasses authentication is still stopped by:
- Resource-based authorization (can't access another user's data)
- Rate limiting (can't enumerate resources quickly)
- Monitoring (attack detected and blocked)
```
