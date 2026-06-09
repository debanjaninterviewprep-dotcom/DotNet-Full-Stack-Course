using StackExchange.Redis;

namespace TaskFlow.RedisApi.Middleware;

public class RedisRateLimiter
{
    private readonly RequestDelegate _next;
    private readonly IDatabase _db;
    private const int LimitPerMin = 60;

    public RedisRateLimiter(RequestDelegate next, IDatabase db)
    {
        _next = next; _db = db;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        var user = ctx.Request.Headers["X-User-Id"].FirstOrDefault() ?? "anon";
        var nowMin = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / 60;
        var key = $"rl:{user}:{nowMin}";

        var count = await _db.StringIncrementAsync(key);
        if (count == 1) await _db.KeyExpireAsync(key, TimeSpan.FromSeconds(60));

        if (count > LimitPerMin)
        {
            var retryAfter = 60 - (DateTimeOffset.UtcNow.ToUnixTimeSeconds() % 60);
            ctx.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            ctx.Response.Headers["Retry-After"] = retryAfter.ToString();
            await ctx.Response.WriteAsync("rate limit exceeded");
            return;
        }

        await _next(ctx);
    }
}
