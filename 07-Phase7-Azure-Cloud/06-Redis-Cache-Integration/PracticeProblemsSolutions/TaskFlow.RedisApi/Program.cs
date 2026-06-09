using Azure.Identity;
using StackExchange.Redis;
using TaskFlow.RedisApi.Middleware;
using TaskFlow.RedisApi.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var endpoint = builder.Configuration["Redis:Endpoint"]!;
    var useEntra = bool.Parse(builder.Configuration["Redis:UseEntraAuth"] ?? "false");
    var principalId = builder.Configuration["Redis:PrincipalId"]!;

    var cfg = new ConfigurationOptions
    {
        EndPoints = { endpoint },
        Ssl = true,
        AbortOnConnectFail = false,
        ConnectTimeout = 5000,
        SyncTimeout = 5000,
    };

    if (useEntra)
    {
        cfg.ConfigureForAzureWithTokenCredentialAsync(
            new DefaultAzureCredential(), principalId).GetAwaiter().GetResult();
    }
    else
    {
        // Fallback: pull access key from Key Vault into env var REDIS_ACCESSKEY
        cfg.Password = Environment.GetEnvironmentVariable("REDIS_ACCESSKEY");
    }

    return ConnectionMultiplexer.Connect(cfg);
});

builder.Services.AddSingleton(sp => sp.GetRequiredService<IConnectionMultiplexer>().GetDatabase());
builder.Services.AddSingleton<TaskRepository>();
builder.Services.AddSingleton<TaskCache>();
builder.Services.AddSingleton<RedisLock>();
builder.Services.AddSingleton<CacheStats>();

var app = builder.Build();
app.UseSwagger();
app.UseSwaggerUI();
app.UseMiddleware<RedisRateLimiter>();

app.MapGet("/tasks/{id}", async (string id, TaskCache cache, CancellationToken ct) =>
{
    var t = await cache.GetAsync(id, ct);
    return t is null ? Results.NotFound() : Results.Ok(t);
});

app.MapPut("/tasks/{id}", async (string id, TaskDto body, TaskCache cache, CancellationToken ct) =>
{
    await cache.UpdateAsync(id, body, ct);
    return Results.NoContent();
});

app.MapPost("/jobs/daily-report", async (RedisLock locks) =>
{
    var ok = await locks.TryRunOnceAsync("job:daily-report", TimeSpan.FromMinutes(2), async () =>
    {
        await Task.Delay(TimeSpan.FromSeconds(5));
    });
    return Results.Ok(new { ran = ok });
});

app.MapGet("/cache-stats", (CacheStats s) => Results.Ok(new { s.Hits, s.Misses, HitRate = s.HitRate }));

app.Run();
