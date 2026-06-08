# Topic 6: Azure Cache for Redis — Integration Patterns

> A managed key/value store with sub-millisecond reads. Redis turns a slow API into a fast one without rewriting business logic — *if* you cache the right thing the right way. This topic teaches you the canonical patterns (cache-aside, write-through, distributed lock, rate limit) and how to wire Redis into TaskFlow with **Microsoft Entra authentication**, no passwords.

---

## 1. Why Cache?

Caches exist to:

1. **Reduce latency** — sub-millisecond instead of 30 ms SQL.
2. **Reduce load** — protect a downstream (DB, external API) from repeated identical requests.
3. **Smooth bursts** — keep hot data in memory; absorb spikes.
4. **Coordinate distributed work** — locks, counters, pub/sub.

Redis is the de-facto in-memory data store: in-process speed (data in RAM), multiple data structures (strings, hashes, lists, sorted sets, streams), and a battle-tested protocol.

---

## 2. Azure Cache for Redis Tiers

| Tier | RAM | TLS | VNet | Geo-replication | Modules | Use for |
|---|---|---|---|---|---|---|
| **Basic** | 250 MB – 53 GB | Yes | No | No | No | Dev / non-critical |
| **Standard** | Same range, replicated | Yes | No | No | No | Most prod (HA) |
| **Premium** | 6 GB – 530 GB | Yes | Yes | Yes (Active-passive) | RedisJSON, RediSearch | High-end |
| **Enterprise** / **Enterprise Flash** | Big | Yes | Yes | Active-active | All modules | Multi-region active |

For TaskFlow MVP: **Standard C0** (250 MB, ~$16/mo) — gives you HA failover. Move to Premium when you need VNet, persistence, or larger sizes.

---

## 3. Authentication: Use Entra, Not Access Keys

Redis traditionally uses two access keys (primary/secondary). They're admin-level passwords. Azure now supports **Microsoft Entra authentication** (preview-GA) where:

- Users / SPs / Managed Identities authenticate to Redis with an Entra token.
- Roles control what they can do (`Data Owner`, `Data Contributor`).
- No passwords to rotate.

```csharp
// .NET 8 with StackExchange.Redis 2.7+ + Azure.Identity
var configuration = new ConfigurationOptions
{
    EndPoints = { "redis-taskflow-dev.redis.cache.windows.net:6380" },
    Ssl = true,
    AbortOnConnectFail = false,
};

await configuration.ConfigureForAzureWithTokenCredentialAsync(
    new DefaultAzureCredential(),
    principalId: "<your-aad-object-id>");

var redis = await ConnectionMultiplexer.ConnectAsync(configuration);
IDatabase db = redis.GetDatabase();
```

If your tier doesn't yet support Entra, fall back to access keys but **store them in Key Vault** and reference from app config.

---

## 4. Pattern: Cache-Aside (Lazy Loading)

The most common pattern.

```
1. App receives GET /tasks/123
2. App: GET task:123 from Redis
   ├── Hit  -> return
   └── Miss -> SELECT FROM Tasks WHERE Id=123
              -> SET task:123 with TTL=5m
              -> return
```

```csharp
public async Task<TaskDto?> GetTaskAsync(Guid id, CancellationToken ct)
{
    var key = $"task:{id}";
    var cached = await _redis.StringGetAsync(key);
    if (cached.HasValue)
        return JsonSerializer.Deserialize<TaskDto>(cached!);

    var task = await _repo.FindAsync(id, ct);
    if (task is null) return null;

    var ttl = TimeSpan.FromMinutes(5);
    await _redis.StringSetAsync(key, JsonSerializer.Serialize(task), ttl);
    return task;
}
```

**Invalidation**: when the task is updated, delete the key.

```csharp
public async Task UpdateTaskAsync(TaskDto t, CancellationToken ct)
{
    await _repo.UpdateAsync(t, ct);
    await _redis.KeyDeleteAsync($"task:{t.Id}");   // invalidate
}
```

> **TTL is your friend.** Even if invalidation has bugs, stale data heals after `TTL`. Pick TTLs based on tolerance for staleness:
> - Reference data (countries, tags): hours.
> - User profile: 5–10 min.
> - Task list (changes often): 30–60 s.

---

## 5. Pattern: Distributed Lock (SET NX EX)

Two pods can both decide to "send the daily report email" at the same time. A lock prevents duplicates.

```csharp
public async Task<bool> TryRunOnceAsync(string lockKey, TimeSpan ttl)
{
    var token = Guid.NewGuid().ToString("N");
    bool acquired = await _redis.StringSetAsync(
        lockKey, token, ttl, When.NotExists);

    if (!acquired) return false;
    try { await DoWork(); }
    finally
    {
        // Release only if we still own it (atomic via Lua)
        var script = @"
            if redis.call('GET', KEYS[1]) == ARGV[1] then
                return redis.call('DEL', KEYS[1])
            else
                return 0
            end";
        await _redis.ScriptEvaluateAsync(script,
            new RedisKey[] { lockKey }, new RedisValue[] { token });
    }
    return true;
}
```

> **Pitfall:** never use `KeyDelete` to release without checking the token. If your work took longer than the TTL, another worker may now hold the lock — releasing without checking deletes *their* lock.

For mission-critical work that needs locking across multiple Redis nodes, use **Redlock** (a multi-instance algorithm). For TaskFlow, a single Redis lock with reasonable TTL is fine.

---

## 6. Pattern: Rate Limiter (Token Bucket via INCR + EXPIRE)

```csharp
public async Task<bool> AllowAsync(string user, int limit, TimeSpan window)
{
    var key = $"rl:{user}:{DateTimeOffset.UtcNow.Ticks / window.Ticks}";
    var count = await _redis.StringIncrementAsync(key);
    if (count == 1) await _redis.KeyExpireAsync(key, window);
    return count <= limit;
}
```

Bucket flips every `window`; first request in a new bucket sets the TTL. Use this for per-user/per-IP limits if you want it in-app rather than at APIM.

---

## 7. Pattern: Pub/Sub (Light, Fire-and-Forget)

Redis pub/sub is **at-most-once** with no persistence. Useful for:

- Cache invalidation across pods (`PUBLISH cache.invalidate.task:123`).
- Real-time UI hints in the same datacenter.

For real durable events, use **Service Bus** (Topic 5).

---

## 8. Choosing the Right Data Type

| Type | Use | Example commands |
|---|---|---|
| **String** | Serialized object | `SET`, `GET`, `INCR`, `EXPIRE` |
| **Hash** | Object with fields you read individually | `HSET`, `HGETALL`, `HINCRBY` |
| **List** | Recent N feed | `LPUSH`, `LRANGE`, `LTRIM` |
| **Set** | Membership / tags | `SADD`, `SISMEMBER`, `SMEMBERS` |
| **Sorted Set** | Leaderboard / time-ordered | `ZADD`, `ZRANGEBYSCORE` |
| **Stream** | Append-only log | `XADD`, `XREAD`, `XGROUP` |

For TaskFlow, use **strings (JSON)** for cache-aside, **hashes** for partial updates, **sorted sets** for "recent activity for user", and **streams** for an in-memory event ring.

---

## 9. Connection Multiplexing & Lifetime

`ConnectionMultiplexer` is **expensive to create, cheap to share**. One singleton per app:

```csharp
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var cfg = ConfigurationOptions.Parse(builder.Configuration["Redis:Endpoint"]!);
    cfg.Ssl = true;
    cfg.ConnectTimeout = 5000;
    cfg.SyncTimeout = 5000;
    cfg.AbortOnConnectFail = false;
    return ConnectionMultiplexer.Connect(cfg);
});

builder.Services.AddSingleton(sp => sp.GetRequiredService<IConnectionMultiplexer>().GetDatabase());
```

**`AbortOnConnectFail = false`** is important — Redis can be unreachable for seconds during failover; the multiplexer will reconnect.

---

## 10. Resilience: Cache Stampede & Thundering Herd

When a hot key expires, *every* request on a multi-node cluster goes to the DB at the same moment. Fixes:

1. **Random TTL jitter**: `TTL = baseTTL + Random(0..jitter)`.
2. **Mutex/lock per key**: only one worker repopulates; others wait briefly.
3. **Stale-while-revalidate**: serve the expired value while a background refresh runs.

```csharp
var key = $"task:{id}";
var data = await _redis.StringGetAsync(key);
if (data.IsNullOrEmpty)
{
    await using var _ = await TryAcquire($"lock:{key}", TimeSpan.FromSeconds(5));
    // re-check after acquiring
    data = await _redis.StringGetAsync(key);
    if (data.IsNullOrEmpty)
    {
        var fresh = await _repo.FindAsync(id, ct);
        await _redis.StringSetAsync(key, JsonSerializer.Serialize(fresh),
            TimeSpan.FromMinutes(5) + RandomJitter());
        return fresh;
    }
}
return JsonSerializer.Deserialize<TaskDto>(data!);
```

---

## 11. Security & Networking

- TLS only (port 6380; disable 6379 in Azure portal).
- Disable non-SSL traffic.
- Lock down with **firewall rules** or, better, **Private Endpoint** (Premium).
- Use **Microsoft Entra access policies**: `Data Owner`, `Data Contributor`, `Data Reader`.
- Audit slow logs and failed connections via **Azure Monitor**.

---

## 12. Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Cache without a TTL | Always set a TTL |
| Cache the unsanitized DB row including PII you don't need | Cache the DTO; mind GDPR |
| Use Redis as your primary store for state you can't lose | It's a *cache*. Persistence exists but isn't a substitute for SQL |
| Hold the connection per request | Singleton multiplexer |
| Log full Redis values at info-level | They're often big and contain user data |
| Pretend TTL = invalidation | Combine TTL with explicit invalidation on write |
| Forget about thundering herd until it bites you | Jitter + per-key lock from day one |

---

## 13. Observability

- **Cache metrics in portal**: hits, misses, evictions, used memory, server load.
- **Slow log**: shows commands taking > N microseconds.
- **App-side counters**: increment your own hit/miss meters into App Insights (`telemetryClient.GetMetric("redis.hit").TrackValue(1)`).

A hit-rate < 80% on a hot cache means your TTL is wrong, your keys are wrong, or you're caching too narrowly.

---

## Further Reading

- [StackExchange.Redis docs](https://stackexchange.github.io/StackExchange.Redis/)
- [Azure Cache for Redis: Microsoft Entra authentication](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-azure-active-directory-for-authentication)
- [Caching patterns](https://learn.microsoft.com/azure/architecture/patterns/cache-aside)
- [Redlock algorithm](https://redis.io/docs/manual/patterns/distributed-locks/)
- [Cache stampede mitigation](https://en.wikipedia.org/wiki/Cache_stampede)
