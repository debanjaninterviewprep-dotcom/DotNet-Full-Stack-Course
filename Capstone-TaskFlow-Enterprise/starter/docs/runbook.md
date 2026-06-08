# Runbook

> Replace placeholders. Keep this short and runnable.

## Deploy

### Staging
- Trigger: merge to `main`.
- Workflow: `.github/workflows/staging.yml`.
- Approval: none.
- Smoke: `GET https://staging.api.taskflow.example/readyz` → 200; `GET /api/tasks` (seeded user) → 200.

### Production
- Trigger: tag `vX.Y.Z` or `workflow_dispatch`.
- Workflow: `.github/workflows/prod.yml`.
- Approval: required reviewer in repo Environment settings.
- Smoke: same as staging plus 1-minute synthetic monitor.

## Rollback

### Backend
- Azure Portal → Container App → Revisions → split traffic to the last good revision.
- Or CLI: `az containerapp revision set-mode --mode single --name <app> --resource-group <rg>` then `az containerapp ingress traffic set --revision-weight <old>=100`.

### Frontend
- Static Web Apps / App Service: redeploy the previous build artefact from Actions cache.

### Infra
- `terraform apply` on the previous tag of the `infra/` directory; review plan carefully.

### Database
- Restore PITR to N minutes before incident; bring app down first; cut over connection string.

## Common alerts

| Alert | Trigger | First check | First action |
|---|---|---|---|
| SLO burn fast (1h) | Error rate > 5% / 5 min | App Insights failures view | Roll back last deploy |
| SQL DTU > 90% | Sustained 10 min | Query Store top consumers | Scale tier; capture top queries for fix |
| Service Bus DLQ > 0 | Any | Inspect message + reason | Drain to dead-letter sink; replay tool |
| Defender high alert | Any | Alert details | Page on-call; isolate resource per playbook |
| Cost anomaly | Daily report | Cost Analysis by resource | Identify line item; tag for owner |

## On-call playbook

1. Acknowledge in the alert channel within 5 minutes.
2. Open the incident channel `inc-yyyymmdd-<n>`.
3. Page IC if SEV1/2; otherwise self-driven.
4. Update status page at T+15.
5. Resolve, then write a 1-page incident note within 48h.

## Contacts

| Role | Contact |
|---|---|
| On-call primary | … |
| Platform team | … |
| SecOps | … |
| FinOps | … |
