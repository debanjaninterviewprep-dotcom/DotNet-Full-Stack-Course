# Topic 6 — Practice Solutions

| File | Problem |
|---|---|
| `P1-redis.sh` | Provision Redis Standard C0 |
| `TaskFlow.RedisApi/` | Minimal API with cache-aside, lock, rate limit, stampede guard |
| `P2-bench.md` | Cache-aside benchmark |
| `P3-lock.md` | Two-instance distributed-lock log |
| `P4-rl.md` | Rate-limiter curl loop log |
| `P5-stampede.md` | Stampede protection benchmark |

## Build & run

```bash
cd TaskFlow.RedisApi
dotnet run
# Open http://localhost:5050/swagger
```

Configuration (`appsettings.json`):

```json
{
  "Redis": {
    "Endpoint": "redis-taskflow-dev-xxxx.redis.cache.windows.net:6380",
    "UseEntraAuth": true,
    "PrincipalId": "<your-aad-object-id>"
  }
}
```

## Cleanup

```bash
az redis delete -g taskflow-dev-eus-rg -n redis-taskflow-dev-xxxx --yes
```
