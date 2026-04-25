# Topic 7: Authentication & Authorization (JWT)

## 📘 Authentication vs Authorization

| Concept | Question | Example |
|---------|----------|---------|
| **Authentication** | "Who are you?" | Login with username/password → get a token |
| **Authorization** | "What can you do?" | Admin can delete, User can only read |

```
Client → Login (credentials) → Server validates → Returns JWT token
Client → API request + JWT token → Server verifies token → Checks permissions → Allows/Denies
```

---

## 📘 What is JWT (JSON Web Token)?

JWT is a compact, URL-safe token format for securely transmitting claims between parties.

### JWT Structure

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4iLCJyb2xlIjoiQWRtaW4ifQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
[Header].[Payload].[Signature]
```

| Part | Contents | Example |
|------|----------|---------|
| **Header** | Algorithm & token type | `{ "alg": "HS256", "typ": "JWT" }` |
| **Payload** | Claims (user data) | `{ "sub": "123", "name": "John", "role": "Admin", "exp": 1700000000 }` |
| **Signature** | Verification hash | `HMACSHA256(base64(header) + "." + base64(payload), secret)` |

### Standard Claims

| Claim | Full Name | Purpose |
|-------|-----------|---------|
| `sub` | Subject | User identifier |
| `iss` | Issuer | Who created the token |
| `aud` | Audience | Intended recipient |
| `exp` | Expiration | Token expiry time (Unix timestamp) |
| `iat` | Issued At | When token was created |
| `nbf` | Not Before | Token not valid before this time |
| `jti` | JWT ID | Unique token identifier |

---

## 📘 Setting Up JWT Authentication

### Install Package

```bash
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

### Configuration in appsettings.json

```json
{
  "JwtSettings": {
    "Secret": "YourSuperSecretKeyAtLeast32CharactersLong!",
    "Issuer": "TaskFlowApi",
    "Audience": "TaskFlowClient",
    "ExpiryInMinutes": 60,
    "RefreshTokenExpiryInDays": 7
  }
}
```

### Register JWT in Program.cs

```csharp
var jwtSettings = builder.Configuration.GetSection("JwtSettings");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtSettings["Secret"]!)),
        ClockSkew = TimeSpan.Zero  // No grace period for expiry
    };
});

builder.Services.AddAuthorization();

// In the middleware pipeline (ORDER MATTERS!)
app.UseAuthentication();   // Must come before Authorization
app.UseAuthorization();
```

---

## 📘 Token Generation Service

```csharp
public interface ITokenService
{
    string GenerateAccessToken(User user);
    string GenerateRefreshToken();
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string token);
}

public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerateAccessToken(User user)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtSettings["Secret"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("department", user.Department ?? ""),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(double.Parse(jwtSettings["ExpiryInMinutes"]!)),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    public ClaimsPrincipal? GetPrincipalFromExpiredToken(string token)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var tokenValidationParams = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSettings["Secret"]!)),
            ValidateLifetime = false  // Allow expired tokens for refresh
        };

        var handler = new JwtSecurityTokenHandler();
        var principal = handler.ValidateToken(token, tokenValidationParams, out var securityToken);

        if (securityToken is not JwtSecurityToken jwtToken ||
            !jwtToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256,
                StringComparison.InvariantCultureIgnoreCase))
        {
            return null;
        }

        return principal;
    }
}
```

---

## 📘 Auth Controller

```csharp
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        var result = await _authService.RegisterAsync(dto);
        if (!result.IsSuccess)
            return BadRequest(new { errors = result.Errors });
        return Ok(new { message = "Registration successful" });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var result = await _authService.LoginAsync(dto);
        if (!result.IsSuccess)
            return Unauthorized(new { message = "Invalid credentials" });
        
        return Ok(new
        {
            accessToken = result.AccessToken,
            refreshToken = result.RefreshToken,
            expiresAt = result.ExpiresAt
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshToken(RefreshTokenDto dto)
    {
        var result = await _authService.RefreshTokenAsync(dto);
        if (!result.IsSuccess)
            return Unauthorized(new { message = "Invalid refresh token" });
        
        return Ok(new
        {
            accessToken = result.AccessToken,
            refreshToken = result.RefreshToken,
            expiresAt = result.ExpiresAt
        });
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        await _authService.LogoutAsync(int.Parse(userId!));
        return NoContent();
    }
}
```

---

## 📘 Password Hashing

Never store passwords in plain text. Use BCrypt or ASP.NET Core Identity's hasher:

```csharp
// Using BCrypt
// dotnet add package BCrypt.Net-Next

public class AuthService : IAuthService
{
    public async Task<AuthResult> RegisterAsync(RegisterDto dto)
    {
        // Hash password
        string passwordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password);
        
        var user = new User
        {
            Username = dto.Username,
            Email = dto.Email,
            PasswordHash = passwordHash,
            Role = "User"
        };
        
        await _unitOfWork.Users.AddAsync(user);
        await _unitOfWork.SaveChangesAsync();
        
        return AuthResult.Success();
    }

    public async Task<LoginResult> LoginAsync(LoginDto dto)
    {
        var user = await _unitOfWork.Users.GetByUsernameAsync(dto.Username);
        if (user == null)
            return LoginResult.Failure("Invalid credentials");
        
        // Verify password
        bool isValid = BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash);
        if (!isValid)
            return LoginResult.Failure("Invalid credentials");
        
        // Generate tokens
        var accessToken = _tokenService.GenerateAccessToken(user);
        var refreshToken = _tokenService.GenerateRefreshToken();
        
        // Store refresh token
        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
        await _unitOfWork.SaveChangesAsync();
        
        return LoginResult.Success(accessToken, refreshToken);
    }
}
```

---

## 📘 Authorization: Protecting Endpoints

### [Authorize] Attribute

```csharp
// Require authentication (any authenticated user)
[Authorize]
[HttpGet("profile")]
public IActionResult GetProfile()
{
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    return Ok(new { userId });
}

// Require specific role
[Authorize(Roles = "Admin")]
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id) { }

// Require multiple roles (any of these)
[Authorize(Roles = "Admin,Manager")]
[HttpPut("{id}")]
public async Task<IActionResult> Update(int id) { }

// Allow anonymous (override class-level [Authorize])
[AllowAnonymous]
[HttpGet("public")]
public IActionResult PublicEndpoint() => Ok("Anyone can see this");
```

### Policy-Based Authorization

```csharp
// Program.cs
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    
    options.AddPolicy("MinAge18", policy =>
        policy.RequireAssertion(context =>
        {
            var ageClaim = context.User.FindFirst("age")?.Value;
            return ageClaim != null && int.Parse(ageClaim) >= 18;
        }));
    
    options.AddPolicy("DepartmentManager", policy =>
        policy.RequireClaim("department")
              .RequireRole("Manager"));
});

// Usage
[Authorize(Policy = "AdminOnly")]
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id) { }
```

### Custom Authorization Handler

```csharp
public class ResourceOwnerRequirement : IAuthorizationRequirement { }

public class ResourceOwnerHandler : AuthorizationHandler<ResourceOwnerRequirement, Product>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        ResourceOwnerRequirement requirement,
        Product resource)
    {
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (userId != null && resource.CreatedBy == userId)
        {
            context.Succeed(requirement);
        }
        
        return Task.CompletedTask;
    }
}

// Register
builder.Services.AddSingleton<IAuthorizationHandler, ResourceOwnerHandler>();
```

---

## 📘 Accessing User Claims in Controllers

```csharp
[Authorize]
[HttpGet("me")]
public IActionResult GetCurrentUser()
{
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    var username = User.FindFirst(ClaimTypes.Name)?.Value;
    var email = User.FindFirst(ClaimTypes.Email)?.Value;
    var role = User.FindFirst(ClaimTypes.Role)?.Value;
    var isAdmin = User.IsInRole("Admin");
    
    return Ok(new { userId, username, email, role, isAdmin });
}
```

---

## 📘 Refresh Token Flow

```
1. Client → POST /auth/login (username, password)
2. Server → { accessToken (15min), refreshToken (7 days) }
3. Client → GET /api/data + Authorization: Bearer {accessToken}
4. Server → 200 OK (token valid)
   ...time passes, access token expires...
5. Client → GET /api/data + Authorization: Bearer {expiredAccessToken}
6. Server → 401 Unauthorized (token expired)
7. Client → POST /auth/refresh { accessToken, refreshToken }
8. Server → { newAccessToken, newRefreshToken }
9. Client → GET /api/data + Authorization: Bearer {newAccessToken}
10. Server → 200 OK
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| Authentication | Verifying identity (login) — "Who are you?" |
| Authorization | Checking permissions — "What can you do?" |
| JWT | Compact token with Header.Payload.Signature |
| Claims | Key-value pairs in the token (userId, role, email) |
| Token Service | Generates and validates JWT tokens |
| Password Hashing | BCrypt — never store plain-text passwords |
| [Authorize] | Attribute to protect endpoints |
| Roles | Simple authorization: Admin, User, Manager |
| Policies | Complex authorization with custom requirements |
| Refresh Tokens | Long-lived token to get new access tokens |
| Middleware Order | UseAuthentication() BEFORE UseAuthorization() |

> **Next Topic**: Middleware, Filters & Error Handling — Building robust request pipelines.
