using StackExchange.Redis;

namespace TaskFlow.RedisApi.Services;

public class RedisLock
{
    private readonly IDatabase _db;
    private const string ReleaseScript = @"
        if redis.call('GET', KEYS[1]) == ARGV[1] then
            return redis.call('DEL', KEYS[1])
        else
            return 0
        end";

    public RedisLock(IDatabase db) => _db = db;

    public async Task<bool> TryRunOnceAsync(string key, TimeSpan ttl, Func<Task> work)
    {
        var token = Guid.NewGuid().ToString("N");
        var acquired = await _db.StringSetAsync(key, token, ttl, When.NotExists);
        if (!acquired) return false;
        try
        {
            await work();
        }
        finally
        {
            await _db.ScriptEvaluateAsync(ReleaseScript,
                new RedisKey[] { key }, new RedisValue[] { token });
        }
        return true;
    }
}
