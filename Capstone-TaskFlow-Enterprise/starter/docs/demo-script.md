# 8-minute Demo Script

Stick to the timings. Practise once before recording.

| t (min) | Beat | Show |
|---:|---|---|
| 0:00 | Open with the **problem**: teams need a multi-tenant board with audit + observability without spending six months building it. | Title slide / open repo README. |
| 0:30 | **User flow**: log in (Entra), pick tenant, view board, drag a card, get a notification. | Staging app, real Entra login. |
| 2:00 | **Architecture in 60s** with the Container diagram. Highlight BFF, OBO, Service Bus, Redis. | `docs/architecture.md` diagram. |
| 3:00 | **Deploy a change**: open a PR with a tiny change. Show preview env URL posted on the PR. | GitHub PR + comment. |
| 4:00 | Merge → staging deploys → smoke tests green. Tag `v1.0.1` → prod waits for approval → approve → prod deploys. | Actions runs side by side. |
| 5:30 | **Operate**: open Defender Secure Score, Policy compliance, App Insights failures + SLO. Show one alert and its runbook entry. | Azure portal. |
| 7:00 | **AI**: run the `bump-api-version` prompt and show the diff Copilot proposes. | VS Code Copilot chat. |
| 7:30 | **Close**: idle cost, on-call ergonomics, what's next on the roadmap. | Slide / README. |
| 8:00 | End. | — |

## Demo data
- Tenant: `acme`
- Users: `alice@acme` (admin), `bob@acme` (member)
- Project: `Q3 launch` with 12 cards across 4 columns.

## Pre-flight
- [ ] Browser windows pre-opened in the right order.
- [ ] Test the live demo once 30 minutes before.
- [ ] Backup recording in case demo gods are angry.
