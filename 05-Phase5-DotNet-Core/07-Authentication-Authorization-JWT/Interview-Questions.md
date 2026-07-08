# Topic 07: Authentication, Authorization & JWT — Interview Questions

---

## Q1. What is the difference between Authentication and Authorization?
**Answer:**
- **Authentication** — verifying **who you are** (identity). "Is this really Alice?"
- **Authorization** — verifying **what you can do** (permissions). "Can Alice delete users?"

```csharp
// In ASP.NET Core pipeline:
app.UseAuthentication(); // 1st — identifies the user from token/cookie
app.UseAuthorization();  // 2nd — checks if identified user can access the resource

// Authentication sets: HttpContext.User (ClaimsPrincipal)
// Authorization reads: HttpContext.User.Claims to check permissions
```

---

## Q2. What is a JWT and what is its structure?
**Answer:**
JWT (JSON Web Token) is a compact, URL-safe token format for securely transmitting claims between parties.

Structure: `header.payload.signature` (Base64Url encoded, separated by dots)

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NSIsIm5hbWUiOiJEZWJhbmphbiIsInJvbGUiOiJBZG1pbiIsImV4cCI6MTczNTY4MDAwMH0.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

```
// Header — algorithm and type
{ "alg": "HS256", "typ": "JWT" }

// Payload — claims (don't put secrets here!)
{
  "sub": "12345",           // subject (user ID)
  "name": "Debanjan",       // custom claim
  "role": "Admin",
  "email": "d@example.com",
  "iat": 1704067200,        // issued at (Unix timestamp)
  "exp": 1704153600         // expiry
}

// Signature
HMACSHA256(base64(header) + "." + base64(payload), secret)
```

---

## Q3. How do you implement JWT authentication in ASP.NET Core?
**Answer:**
```csharp
// 1. Install: Microsoft.AspNetCore.Authentication.JwtBearer

// 2. Configure in Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.TokenValidationParameters = new TokenValidationParameters {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = builder.Configuration["Jwt:Issuer"],
            ValidAudience            = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey         = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]!))
        };
    });

// 3. Generate JWT in auth service
public string GenerateToken(User user)
{
    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Secret"]!));
    var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

    var claims = new[] {
        new Claim(JwtRegisteredClaimNames.Sub,   user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email),
        new Claim(ClaimTypes.Role,               user.Role),
        new Claim(JwtRegisteredClaimNames.Jti,   Guid.NewGuid().ToString())
    };

    var token = new JwtSecurityToken(
        issuer:             _config["Jwt:Issuer"],
        audience:           _config["Jwt:Audience"],
        claims:             claims,
        expires:            DateTime.UtcNow.AddHours(1),
        signingCredentials: creds);

    return new JwtSecurityTokenHandler().WriteToken(token);
}

// 4. Use in middleware pipeline
app.UseAuthentication();
app.UseAuthorization();
```

---

## Q4. What are Claims and how are they used in authorization?
**Answer:**
Claims are key-value statements about the user encoded in the JWT:

```csharp
// Read claims in controller
var userId = User.FindFirstValue(ClaimTypes.NameIdentifier); // "sub" claim
var email  = User.FindFirstValue(ClaimTypes.Email);
var role   = User.FindFirstValue(ClaimTypes.Role);
bool isAdmin = User.IsInRole("Admin");

// Read claims in service
public class UserContext(IHttpContextAccessor http)
{
    public int CurrentUserId => int.Parse(
        http.HttpContext!.User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    public string CurrentUserEmail =>
        http.HttpContext!.User.FindFirstValue(ClaimTypes.Email)!;
    public bool IsAdmin =>
        http.HttpContext!.User.IsInRole("Admin");
}

// Custom claims
new Claim("department", "Engineering"),
new Claim("subscription", "Premium"),
new Claim("tenant_id", tenantId.ToString())
```

---

## Q5. What is role-based vs policy-based authorization?
**Answer:**
```csharp
// Role-based — simple, role membership check
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase { }

[Authorize(Roles = "Admin,Manager")]  // Admin OR Manager
public IActionResult GetReports() => Ok();

// Policy-based — flexible, based on any claim/requirement
builder.Services.AddAuthorization(options => {
    options.AddPolicy("RequireAdminRole", p => p.RequireRole("Admin"));

    options.AddPolicy("MinAge18", p =>
        p.RequireClaim("age").Requirements.Add(new MinAgeRequirement(18)));

    options.AddPolicy("PremiumUser", p =>
        p.RequireClaim("subscription", "Premium"));

    options.AddPolicy("CanEditOrders", p =>
        p.RequireAssertion(ctx =>
            ctx.User.IsInRole("Admin") ||
            ctx.User.HasClaim("permission", "orders.edit")));
});

[Authorize(Policy = "PremiumUser")]
public IActionResult GetPremiumContent() => Ok();

// Custom requirement
public class MinAgeRequirement(int minAge) : IAuthorizationRequirement { public int MinAge = minAge; }
public class MinAgeHandler : AuthorizationHandler<MinAgeRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext ctx, MinAgeRequirement req)
    {
        if (int.TryParse(ctx.User.FindFirstValue("age"), out int age) && age >= req.MinAge)
            ctx.Succeed(req);
        return Task.CompletedTask;
    }
}
builder.Services.AddSingleton<IAuthorizationHandler, MinAgeHandler>();
```

---

## Q6. What are refresh tokens and why are they needed?
**Answer:**
Access tokens (JWT) are short-lived (15-60 min). Refresh tokens allow getting a new access token without re-authentication:

```
Client: POST /auth/login
Server: returns { accessToken, refreshToken }

[client uses accessToken for API calls]

accessToken expires...

Client: POST /auth/refresh { refreshToken }
Server: validates refreshToken, returns new { accessToken, refreshToken }

[repeat until refresh token expires or is revoked]
```

```csharp
// Refresh token model
public class RefreshToken
{
    public string Token { get; set; } = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N");
    public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddDays(30);
    public bool IsRevoked { get; set; }
    public int UserId { get; set; }
}

// Refresh endpoint
[HttpPost("refresh")]
public async Task<IActionResult> Refresh(RefreshDto dto) {
    var stored = await _tokenRepo.GetByTokenAsync(dto.RefreshToken);
    if (stored is null || stored.IsRevoked || stored.ExpiresAt < DateTime.UtcNow)
        return Unauthorized("Invalid or expired refresh token");

    await _tokenRepo.RevokeAsync(stored); // rotate: old token invalidated
    var newTokens = await _authService.RefreshAsync(stored.UserId);
    return Ok(newTokens);
}
```

---

## Q7. What is ASP.NET Core Identity?
**Answer:**
ASP.NET Core Identity is a membership system for handling users, passwords, roles, and claims:

```csharp
// Setup
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options => {
    options.Password.RequiredLength = 8;
    options.Password.RequireDigit = true;
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();

// ApplicationUser — extends IdentityUser
public class ApplicationUser : IdentityUser
{
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

// Usage via UserManager / SignInManager
public class AuthService(UserManager<ApplicationUser> userMgr, SignInManager<ApplicationUser> signMgr)
{
    public async Task<IdentityResult> RegisterAsync(RegisterDto dto) {
        var user = new ApplicationUser { UserName = dto.Email, Email = dto.Email };
        return await userMgr.CreateAsync(user, dto.Password); // hashes password
    }

    public async Task<SignInResult> LoginAsync(LoginDto dto)
        => await signMgr.CheckPasswordSignInAsync(await userMgr.FindByEmailAsync(dto.Email)!, dto.Password, false);
}
```

---

## Q8. What is OAuth2 and how does it differ from JWT?
**Answer:**
- **JWT** — a token **format** (structure: header.payload.signature).
- **OAuth2** — an authorization **framework/protocol** (defines how to obtain and use access tokens).
- **OpenID Connect (OIDC)** — identity layer on top of OAuth2 (adds user info, ID tokens).

```
OAuth2 flows:
- Authorization Code (+ PKCE) — for web/mobile apps ✓ (most secure)
- Client Credentials — for machine-to-machine (no user) ✓
- Implicit — deprecated (was for SPAs)
- Resource Owner Password — deprecated (avoid)

JWT tokens are commonly used AS the access tokens in OAuth2 flows.
```

```csharp
// Validate JWT from external IdP (Azure AD, Auth0, Okta)
builder.Services.AddAuthentication().AddJwtBearer(options => {
    options.Authority = "https://login.microsoftonline.com/{tenantId}/v2.0";
    options.Audience  = "api://your-app-id";
    // Automatic key rotation, OIDC discovery document
});
```

---

## Q9. What is HTTPS and TLS and why are they critical for JWT?
**Answer:**
JWT tokens are **signed** (tamper-proof) but **not encrypted** — the payload is Base64-encoded and readable by anyone.

Without HTTPS/TLS:
- Tokens transmitted in clear text can be stolen (MITM attack).
- A stolen JWT can be used until expiry.

```csharp
// Always enforce HTTPS in production
app.UseHttpsRedirection();
app.UseHsts();

// JWT token should be:
// - Stored in HttpOnly cookies (not localStorage) to prevent XSS theft
// - Short-lived (15-60 minutes) with refresh token rotation
// - Include jti (JWT ID) claim for revocation if needed

// Sending token
// Authorization: Bearer eyJhbGci...

// Receiving: HttpClient
httpClient.DefaultRequestHeaders.Authorization =
    new AuthenticationHeaderValue("Bearer", token);
```

---

## Q10. What are resource-based and operation-based authorization?
**Answer:**
```csharp
// Resource-based authorization — check ownership
public class DocumentAuthorizationHandler
    : AuthorizationHandler<EditDocumentRequirement, Document>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext ctx,
        EditDocumentRequirement requirement,
        Document document)
    {
        var userId = ctx.User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (document.OwnerId.ToString() == userId || ctx.User.IsInRole("Admin"))
            ctx.Succeed(requirement);
        return Task.CompletedTask;
    }
}

// Controller — pass the resource to authorization
[HttpPut("{id}")]
public async Task<IActionResult> Update(int id, UpdateDocumentDto dto)
{
    var document = await _repo.GetByIdAsync(id);
    var authResult = await _authService.AuthorizeAsync(User, document, "EditDocument");
    if (!authResult.Succeeded) return Forbid();
    // ...
}
```

---

## Q11. What is the `[AllowAnonymous]` attribute?
**Answer:**
`[AllowAnonymous]` bypasses authentication and authorization checks — allows unauthenticated access:

```csharp
// Apply [Authorize] globally
builder.Services.AddAuthorization(opts =>
    opts.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build());

// All endpoints require auth by default
// Exempt specific endpoints:
[AllowAnonymous]
[HttpPost("login")]
public async Task<IActionResult> Login(LoginDto dto) => Ok();

[AllowAnonymous]
[HttpPost("register")]
public async Task<IActionResult> Register(RegisterDto dto) => Ok();

[AllowAnonymous]
[HttpGet("health")]
public IActionResult Health() => Ok("healthy");
```

---

## Q12. What is token revocation and how do you implement it?
**Answer:**
JWTs are stateless — they're valid until expiry. Revocation requires maintaining a denylist:

```csharp
// Option 1: Short access token + revocable refresh token
// Access token: 15 min — just let it expire; revoke the refresh token
// Revoked refresh tokens stored in DB

// Option 2: Distributed cache denylist (for when immediate revocation is required)
public class JwtRevocationService(IDistributedCache cache)
{
    public async Task RevokeAsync(string jti, TimeSpan ttl)
        => await cache.SetStringAsync($"revoked:{jti}", "1", new() { AbsoluteExpirationRelativeToNow = ttl });

    public async Task<bool> IsRevokedAsync(string jti)
        => await cache.GetStringAsync($"revoked:{jti}") is not null;
}

// Add to JWT validation events
options.Events = new JwtBearerEvents {
    OnTokenValidated = async ctx => {
        var jti = ctx.Principal!.FindFirstValue(JwtRegisteredClaimNames.Jti);
        var revocationSvc = ctx.HttpContext.RequestServices.GetRequiredService<JwtRevocationService>();
        if (await revocationSvc.IsRevokedAsync(jti!))
            ctx.Fail("Token has been revoked");
    }
};
```

---

## Q13. What is multi-tenancy authentication?
**Answer:**
Multi-tenant apps must isolate data per tenant while sharing the same application:

```csharp
// Tenant identifier in JWT
new Claim("tenant_id", user.TenantId.ToString())

// Tenant resolution service
public class TenantService(IHttpContextAccessor accessor)
{
    public Guid TenantId => Guid.Parse(
        accessor.HttpContext!.User.FindFirstValue("tenant_id")!);
}

// DbContext scoped per tenant
public class AppDbContext(DbContextOptions<AppDbContext> opts, TenantService tenant) : DbContext(opts)
{
    protected override void OnModelCreating(ModelBuilder mb)
    {
        // Global query filter — all queries automatically scoped to current tenant
        mb.Entity<User>().HasQueryFilter(u => u.TenantId == tenant.TenantId);
        mb.Entity<Order>().HasQueryFilter(o => o.TenantId == tenant.TenantId);
    }
}
```

---

## Q14. What is the difference between symmetric and asymmetric JWT signing?
**Answer:**
| | Symmetric (HMAC) | Asymmetric (RSA/ECDSA) |
|---|---|---|
| **Algorithm** | HS256, HS384, HS512 | RS256, ES256, PS256 |
| **Keys** | One shared secret | Public/private key pair |
| **Who can verify?** | Anyone with the secret | Anyone with the public key |
| **Security** | Secret must be kept private | Private key is secret; public key is shareable |
| **Use case** | Single service | Multiple services, public verification |

```csharp
// Asymmetric — auth server signs with private key, APIs verify with public key
var rsa = RSA.Create();
rsa.ImportRSAPrivateKey(privateKeyBytes, out _);
var signingCredentials = new SigningCredentials(
    new RsaSecurityKey(rsa), SecurityAlgorithms.RsaSha256);

// Any service can verify with the public key (no shared secret)
var publicKey = new RsaSecurityKey(rsa) { KeyId = "key-1" };
options.TokenValidationParameters.IssuerSigningKeys = new[] { publicKey };
```

---

## Q15. What is the `[Authorize]` attribute and its properties?
**Answer:**
```csharp
[Authorize]                                    // any authenticated user
[Authorize(Roles = "Admin")]                   // specific role
[Authorize(Roles = "Admin,Manager")]           // Admin OR Manager
[Authorize(Policy = "AtLeast21")]              // specific policy
[Authorize(AuthenticationSchemes = "Bearer")]  // specific auth scheme

// Multiple attributes — AND logic (must satisfy ALL)
[Authorize(Roles = "Admin")]
[Authorize(Policy = "OfficeHoursOnly")]
public class SecureController : ControllerBase { }

// Controller-level + action-level override
[Authorize]                                    // default for all actions
public class UserController : ControllerBase
{
    [AllowAnonymous]                           // override — this action is public
    [HttpGet("public")]
    public IActionResult Public() => Ok();

    [Authorize(Roles = "Admin")]               // more restrictive override
    [HttpDelete("{id}")]
    public IActionResult Delete(int id) => NoContent();
}
```
