namespace TaskFlow.RedisApi.Services;

public class CacheStats
{
    private long _hits;
    private long _misses;

    public long Hits => Interlocked.Read(ref _hits);
    public long Misses => Interlocked.Read(ref _misses);
    public double HitRate => (Hits + Misses) == 0 ? 0 : (double)Hits / (Hits + Misses);

    public void Hit() => Interlocked.Increment(ref _hits);
    public void Miss() => Interlocked.Increment(ref _misses);
}
