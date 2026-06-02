# TaskFlow Production Runbook (TEMPLATE)

> Copy to `docs/runbook.md` in your repo and fill in. Owner: `<team>` · Last reviewed: `<YYYY-MM-DD>`

## 1. Quick links

| Resource | URL |
|---|---|
| Production app | `https://taskflow.example.com` |
| API health | `https://api.taskflow.example.com/health/ready` |
| Application Insights | `<portal link>` |
| Grafana dashboard | `<link>` |
| Jaeger | `<link>` |
| GHCR images | `https://ghcr.io/<owner>/taskflow-api` |
| Status page | `<link>` |
| On-call schedule | `<link>` |

## 2. Architecture at a glance

```
[ Browser ] → [ Front Door / CDN ] → [ App Service: web ] → [ App Service: api ] → [ Azure SQL ]
                                                                  ↓
                                                        [ Redis ]   [ Blob Storage ]   [ Key Vault ]
```

## 3. Common alerts → first 3 steps

### A. 5xx burst (>2% over 5 min)
1. App Insights → Failures blade → top exception type.
2. Check `CorrelationId` of one failing request → trace in Jaeger.
3. If new deploy in last 30 min → rollback (§5.1).

### B. API p95 > 500 ms (5 min)
1. Live Metrics → check CPU/memory/threadpool.
2. Long-running SQL? `sp_WhoIsActive` against prod DB.
3. Cache miss spike? Check Redis hit rate; consider warming.

### C. Redis down
1. Confirm via `redis-cli ping` from a jumpbox.
2. App keeps running — HybridCache falls back to L1; degraded SignalR (single-pod groups only).
3. Failover Redis (Premium tier auto-failover, ~1 min) or restart cache.

### D. Hangfire queue backlog (>1000 enqueued)
1. Hangfire dashboard → Servers tab → are workers alive?
2. If 0 servers → API pods can't reach SQL/Redis → §A or §C.
3. Scale out workers: `az webapp scale --instance-count 4`.

### E. Database CPU > 90%
1. Query Insights → top resource consumers.
2. If it's a known bad query → kill (`KILL <spid>`) and patch index.
3. If steady-state load → scale up the SQL tier.

## 4. Routine ops

| Task | How |
|---|---|
| Deploy | Tag push → `Release` → `Deploy` workflow |
| Smoke test | `curl https://api.taskflow.example.com/health/ready` should return 200 |
| Rotate signing key | Update Key Vault secret with new value (kid rotation) → app restart |
| Drain & restart pod | App Service → Restart (graceful) |

## 5. Rollback

### 5.1 Slot swap rollback (fastest)
```bash
az webapp deployment slot swap \
  -n taskflow-api -g taskflow-rg \
  --slot production --target-slot staging
```

### 5.2 Image rollback
```bash
az webapp config container set -n taskflow-api -g taskflow-rg \
  --container-image-name ghcr.io/<owner>/taskflow-api:<previous-tag>
```

### 5.3 DB rollback
- Avoid where possible (expand/contract migration discipline).
- If needed: PITR via Azure SQL → restore to a new database → swap connection string.

## 6. Escalation

| Severity | Action | Contact |
|---|---|---|
| SEV-1 | Page primary on-call | `<contact>` |
| SEV-2 | Slack #taskflow-oncall | `<channel>` |
| SEV-3 | Open ticket in Jira | `<project>` |

## 7. Post-incident

- Open a `docs/incidents/YYYY-MM-DD-<short>.md` within 24 h.
- Schedule a 30-min review within 5 business days.
- Track action items in Jira with `sev-followup` label.
