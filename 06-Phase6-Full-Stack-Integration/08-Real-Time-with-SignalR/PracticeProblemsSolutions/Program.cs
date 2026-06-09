using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.SignalR;
using Microsoft.IdentityModel.Tokens;
using TaskFlow.Topic08.Hubs;
using TaskFlow.Topic08.Realtime;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddAuthorization();
builder.Services.AddHttpContextAccessor();

// P1: SignalR with detailed errors only in dev, 32KB receive ceiling.
var signalR = builder.Services.AddSignalR(o =>
{
    o.EnableDetailedErrors = builder.Environment.IsDevelopment();
    o.MaximumReceiveMessageSize = 32 * 1024;
    o.ClientTimeoutInterval = TimeSpan.FromSeconds(60);
    o.KeepAliveInterval = TimeSpan.FromSeconds(15);
});

// P5: Redis backplane (optional — only if connection string is set).
var redis = builder.Configuration.GetConnectionString("Redis");
if (!string.IsNullOrWhiteSpace(redis))
{
    signalR.AddStackExchangeRedis(redis, o =>
    {
        o.Configuration.ChannelPrefix = StackExchange.Redis.RedisChannel.Literal("taskflow");
    });
}

// P2: custom IUserIdProvider that reads `sub` claim (matches Topic 5 token issuance).
builder.Services.AddSingleton<IUserIdProvider, SubUserIdProvider>();

// P4: notifier that command handlers inject instead of IHubContext directly.
builder.Services.AddScoped<TaskNotifier>();

// P1: JWT bearer with ?access_token= support for /hubs path.
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.MapInboundClaims = false;
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:SigningKey"]
                    ?? "dev-only-signing-key-please-replace-32chars")),
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = JwtRegisteredClaimNames.UniqueName,
        };
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var path = ctx.HttpContext.Request.Path;
                var token = ctx.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(token) && path.StartsWithSegments("/hubs"))
                    ctx.Token = token;
                return Task.CompletedTask;
            }
        };
    });

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapHub<TaskFlowHub>("/hubs/taskflow").RequireAuthorization();

// Smoke endpoint: dump connection id + claims for the caller.
app.MapGet("/me", (HttpContext http) => new
{
    user = http.User.Identity?.Name,
    sub = http.User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value,
    claims = http.User.Claims.Select(c => new { c.Type, c.Value }),
}).RequireAuthorization();

// TODO P5 demo endpoint: POST /tasks/{id}/status that updates a task and pushes via TaskNotifier.

app.Run();

public partial class Program { }
