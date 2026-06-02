// ===============================================================
//  Topic 5 - Authentication & Authorization End-to-End
// ===============================================================
//  Browse Swagger at https://localhost:7105/swagger after dotnet run.
//  Set Jwt:SigningKey via dotnet user-secrets before first run.

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TaskFlow Topic 5", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Paste an access token here (no 'Bearer ' prefix)."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        [new OpenApiSecurityScheme {
            Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }] = Array.Empty<string>()
    });
});

// ---------------------------------------------------------------
// JWT bearer baseline — fully wired so P3 + P4 endpoints work.
// TODO: replace direct config read with strongly-typed JwtOptions
//       (add ValidateDataAnnotations + ValidateOnStart per Topic 3).
var signingKey = builder.Configuration["Jwt:SigningKey"]
    ?? throw new InvalidOperationException("Set Jwt:SigningKey via user-secrets.");
var issuer    = builder.Configuration["Jwt:Issuer"]   ?? "https://taskflow.local";
var audience  = builder.Configuration["Jwt:Audience"] ?? "taskflow-api";

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false;
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,            ValidIssuer = issuer,
            ValidateAudience = true,          ValidAudience = audience,
            ValidateLifetime = true,          ClockSkew = TimeSpan.FromMinutes(1),
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
            NameClaimType = ClaimTypes.NameIdentifier,
            RoleClaimType = "role"
        };
    });

builder.Services.AddAuthorization(o =>
{
    o.AddPolicy("AdminOnly",      p => p.RequireRole("Admin"));
    o.AddPolicy("EmailConfirmed", p => p.RequireClaim("email_verified", "true"));
});

builder.Services.AddHttpContextAccessor();

// ---------------------------------------------------------------
// TODO P1: User entity, IPasswordHasher (BCrypt), IJwtTokenService,
//          POST /auth/register, POST /auth/login.

// ---------------------------------------------------------------
// TODO P2: RefreshToken entity, /auth/refresh + /auth/logout, rotation
//          + reuse-detection logic + HttpOnly cookie.

// ---------------------------------------------------------------
// TODO P3: HttpCurrentUser implementation + sample policies endpoints.

// ---------------------------------------------------------------
// TODO P4: Resource-based authorization handler for projects
//          (Owner/Admin = succeed, Member/Viewer = fail on edit).

// ---------------------------------------------------------------
// TODO P5: Rate limiter for /auth/login + lockout via IDistributedCache.
// builder.Services.AddRateLimiter(o => { ... });

// ---------------------------------------------------------------
// TODO P6: Forgot-password + reset-password (single-use token) +
//          POST /auth/logout-all.

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
// app.UseRateLimiter();   // requires P5

app.MapControllers();
app.MapGet("/me", (ClaimsPrincipal user) => Results.Ok(user.Claims.ToDictionary(c => c.Type, c => c.Value)))
    .RequireAuthorization();

app.Run();

public partial class Program { }
