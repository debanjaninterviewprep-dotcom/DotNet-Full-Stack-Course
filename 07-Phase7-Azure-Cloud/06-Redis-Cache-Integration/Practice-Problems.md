# Topic 6: Redis Cache — Practice Problems

> Five exercises that wire **Azure Cache for Redis** into a small ASP.NET Core API and exercise the canonical patterns: cache-aside, distributed lock, rate limit, and stampede protection.

**Concept tags:** `redis` `cache-aside` `lock` `rate-limit` `stampede` `entra-auth`

**Prereqs:**
- A Standard C0 Azure Cache for Redis instance (or Basic if budget is tight).
- TLS enabled (default), non-SSL port disabled.
- Your user has `Data Owner` (preview-GA) or you fall back to a Key-Vault-stored access key.

---

## P1 — Provision Redis + .NET API Bootstrap  *(Easy)*

**Tags:** `provisioning` `multiplexer` `entra-auth`

### Requirements

`P1-redis.sh`:
- Provision `redis-taskflow-dev-<suffix>` Standard C0.
- Enable Microsoft Entra authentication (or document fallback to access key + Key Vault if your tier doesn't support it yet).
- Grant your user `Data Contributor` (Entra) or save the primary key into Key Vault as `Redis--PrimaryKey`.

The `TaskFlow.RedisApi` minimal API has:
- `GET /tasks/{id}` — returns a `TaskDto` (fake repo with 200 ms latency).
- `PUT /tasks/{id}` — updates and invalidates cache.
- A singleton `IConnectionMultiplexer` registered with `AbortOnConnectFail=false`.

### Deliverable

`P1-redis.sh` + working API booting against Redis.

### Look-fors

- [ ] Multiplexer is singleton (one connection across requests).
- [ ] TLS enforced; non-SSL port disabled.
- [ ] No keys in `appsettings.json` — Key Vault reference or Entra.

---

## P2 — Cache-Aside with TTL Jitter  *(Medium)*

**Tags:** `cache-aside` `ttl` `jitter`

### Requirements

Wrap the fake repo in `TaskCache`:
- On miss: fetch from repo, store JSON in Redis with TTL = `5 min + jitter(0..30s)`.
- On hit: return immediately.
- On `PUT`: invalidate the key.
- Expose `/cache-stats` with hit/miss counters.

Benchmark with `hey` or `wrk`: 1000 GETs → expect first slow, rest sub-ms.

### Deliverable

`Services/TaskCache.cs` + `P2-bench.md` with timings before/after.

### Look-fors

- [ ] First request ≈ 200 ms (miss + repo); subsequent requests < 5 ms.
- [ ] Cache hit-rate visible at `/cache-stats`.
- [ ] TTL has jitter (use a deterministic seed in tests).

---

## P3 — Distributed Lock for "Run Once" Job  *(Medium)*

**Tags:** `distributed-lock` `lua` `nx-ex`

### Requirements

Add `POST /jobs/daily-report` that:
- Calls `_locks.TryRunOnceAsync("job:daily-report", TimeSpan.FromMinutes(2))`.
- If acquired: simulates 5 s of work, returns `{ ran: true }`.
- If not acquired: returns `{ ran: false, reason: "another instance is running" }`.

Release the lock with a Lua compare-and-delete (only release if we still own it).

Run two API instances concurrently (`dotnet run` twice on different ports) and call both — only one should run.

### Deliverable

`Services/RedisLock.cs` + `P3-lock.md` showing the two-instance test.

### Look-fors

- [ ] Atomic acquire (`SET NX EX`).
- [ ] Atomic release via Lua check-token-then-DEL.
- [ ] Locks expire even if the process crashes (proves TTL is set).

---

## P4 — Per-User Rate Limiter  *(Medium)*

**Tags:** `rate-limit` `incr` `expire`

### Requirements

Add ASP.NET Core middleware `RedisRateLimiter`:
- Reads `X-User-Id` header.
- `INCR` `rl:{user}:{minute-bucket}` and on first call `EXPIRE 60`.
- If `count > 60`, return 429 with a `Retry-After` header.

Test: hit `/tasks/{id}` 70× in one minute → first 60 succeed (after caching, very fast), 10 get 429.

### Deliverable

`Middleware/RedisRateLimiter.cs` + `P4-rl.md` with a curl loop output.

### Look-fors

- [ ] Counter resets every minute.
- [ ] `Retry-After` is a sane value (seconds until next bucket).
- [ ] Middleware is **not** behind the cache layer (rate limit must run for cached requests too).

---

## P5 — Stampede Protection  *(Hard)*

**Tags:** `stampede` `single-flight` `stale-while-revalidate`

### Requirements

Force a stampede:
- TTL is 30 s.
- Use `wrk -t 4 -c 100 -d 30s` to hammer `/tasks/abc` while you delete the key every 5 s in another shell.

Without protection, you should see the underlying repo called many times each second when the key expires.

Implement **single-flight**:
- On miss, acquire a per-key Redis lock (`lock:cache:task:{id}`) with TTL 5 s.
- Whichever request gets the lock fetches and writes; others wait briefly and re-read.

Optionally also implement **stale-while-revalidate**: serve old value while one worker refreshes.

### Deliverable

`Services/StampedeGuard.cs` + `P5-stampede.md` showing repo call counts before/after.

### Look-fors

- [ ] Repo call rate << request rate when many requests hit at the same time.
- [ ] No starvation: waiters get an answer in < 1 s.
- [ ] You wrote a paragraph on when stale-while-revalidate is appropriate.

---

## Submission Checklist

- [ ] All five deliverables.
- [ ] No Redis access keys in commits — Entra or Key Vault.
- [ ] `README.md` lists endpoints and how to run benchmarks.

---

## Stretch Goals

- Use **`Microsoft.Extensions.Caching.StackExchangeRedis`** for `IDistributedCache` instead of raw multiplexer.
- Add **OpenTelemetry** instrumentation on the Redis client.
- Implement Redis pub/sub for cache invalidation across instances when you scale out.
