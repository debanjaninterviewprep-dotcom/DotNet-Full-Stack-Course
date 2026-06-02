# Capstone Acceptance Checklist

> Mirror of Notes.md §2 + §3 in printable form. Tick as you verify.

## Functional

- [ ] **Auth**: signup → confirm email → login → silent refresh after 15 min → reuse-detection revokes family
- [ ] **Projects CRUD**: create / list / get / patch / delete with ETag/If-Match → 412 on stale write
- [ ] **Tasks**: offset + keyset pagination, sort whitelist, JSON Patch with Idempotency-Key
- [ ] **Realtime**: cross-tab live update < 500 ms; presence on connect/disconnect
- [ ] **Uploads**: ≤50 MB streaming → background scan + thumbnail → "ready" toast via SignalR
- [ ] **Email**: welcome on signup; daily 08:00 digest visible in Mailpit
- [ ] **Cache**: HybridCache hit on second `/stats`; tag invalidation scoped to one project
- [ ] **Observability**: CorrelationId on every request; Jaeger trace spans HTTP→EF→Redis; `/metrics` has custom counters

## Non-functional

- [ ] API p95 `/projects` < 200 ms
- [ ] API p99 < 500 ms
- [ ] Frontend LCP < 2.5 s on 4G
- [ ] Initial JS bundle < 200 KB gz
- [ ] Per-route chunk < 80 KB gz
- [ ] API coverage ≥ 70% line, ≥ 60% branch
- [ ] Web coverage ≥ 60% lines
- [ ] CI duration on PR < 10 min
- [ ] API image < 200 MB
- [ ] Web image < 30 MB
- [ ] 0 critical/high vulnerabilities in image scan

## Process

- [ ] D1 demo dress rehearsal complete
- [ ] D2 runbook tabletop-tested
- [ ] D3 threat model dated within 30 days
- [ ] ≥ 2 of B1–B5 merged with ADRs
- [ ] `v1.0.0` tagged; deploy workflow green
