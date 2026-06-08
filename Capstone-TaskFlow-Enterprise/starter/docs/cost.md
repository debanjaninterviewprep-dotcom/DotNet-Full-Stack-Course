# Cost

> Snapshot of the current spend posture.

## Monthly estimate (per env)

| Service | Dev | Staging | Prod |
|---|---:|---:|---:|
| Container Apps (Core API) | £8 | £20 | £80 |
| Container Apps (BFF) | £5 | £12 | £40 |
| Azure SQL (Basic / S0 / S2) | £4 | £12 | £60 |
| Redis (Basic C0 / Standard C1) | £12 | £25 | £55 |
| Service Bus (Basic / Standard) | £0 | £8 | £8 |
| APIM (Consumption / Developer) | £0 | £30 | £100 |
| App Insights + LAW (ingest cap) | £5 | £15 | £40 |
| Key Vault | £0 | £0 | £1 |
| Storage (state + blobs) | £1 | £2 | £5 |
| Front Door (Standard) | £0 | £25 | £25 |
| Defender plans | £0 | £20 | £60 |
| **Estimated total** | **£35** | **£169** | **£474** |

(Adjust to your subscription. Pull real numbers from Cost Analysis monthly.)

## Optimisation backlog

- [ ] Scale Container Apps to zero outside business hours (dev/staging).
- [ ] Move APIM to Consumption SKU in non-prod.
- [ ] Set LAW daily cap; trim verbose categories via DCR.
- [ ] Reserved capacity / savings plan on prod compute after 3 months of steady load.
- [ ] Auto-delete sandbox subs after 14 days.

## Budget alerts

- Dev: £50 / month, alerts at 70 / 90 / 100%.
- Staging: £250 / month.
- Prod: £700 / month.

Configured in `infra/modules/observability/budgets.tf`.
