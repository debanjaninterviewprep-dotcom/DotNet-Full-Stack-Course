using System.Text.Json;
using StackExchange.Redis;

namespace TaskFlow.RedisApi.Services;

public class TaskCache
{
    private readonly IDatabase _db;
    private readonly TaskRepository _repo;
    private readonly RedisLock _locks;
    private readonly CacheStats _stats;
    private static readonly TimeSpan BaseTtl = TimeSpan.FromMinutes(5);

    public TaskCache(IDatabase db, TaskRepository repo, RedisLock locks, CacheStats stats)
    {
        _db = db; _repo = repo; _locks = locks; _stats = stats;
    }

    public async Task<TaskDto?> GetAsync(string id, CancellationToken ct)
    {
        var key = $"task:{id}";
        var v = await _db.StringGetAsync(key);
        if (v.HasValue)
        {
            _stats.Hit();
            return JsonSerializer.Deserialize<TaskDto>(v!);
        }

        _stats.Miss();

        // Stampede guard: only one caller fetches; others briefly wait then re-read.
        TaskDto? result = null;
        await _locks.TryRunOnceAsync($"lock:cache:{key}", TimeSpan.FromSeconds(5), async () =>
        {
            // Re-check after acquiring
            var v2 = await _db.StringGetAsync(key);
            if (v2.HasValue) { result = JsonSerializer.Deserialize<TaskDto>(v2!); return; }

            var fresh = await _repo.FindAsync(id, ct);
            if (fresh is null) return;

            var ttl = BaseTtl + TimeSpan.FromSeconds(Random.Shared.Next(0, 30));
            await _db.StringSetAsync(key, JsonSerializer.Serialize(fresh), ttl);
            result = fresh;
        });

        if (result is not null) return result;

        // We didn't get the lock; brief wait and re-read.
        await Task.Delay(150, ct);
        v = await _db.StringGetAsync(key);
        return v.HasValue ? JsonSerializer.Deserialize<TaskDto>(v!) : null;
    }

    public async Task UpdateAsync(string id, TaskDto body, CancellationToken ct)
    {
        await _repo.UpdateAsync(id, body, ct);
        await _db.KeyDeleteAsync($"task:{id}");
    }
}
