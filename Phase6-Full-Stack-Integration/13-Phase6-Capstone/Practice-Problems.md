# Topic 13 — Practice Problems (Capstone)

> Capstone practice = the **B1–B5 stretch challenges** described in `Notes.md` plus the integration drills below. Pick **at least two** B-series challenges and complete **all** of D1–D3.

---

## D1 — End-to-end demo dress rehearsal

**Goal:** Run the 5-minute demo script (Notes.md §4) cold, on a freshly cloned machine.

**Tasks**
1. On a clean directory: `git clone <your-repo> taskflow && cd taskflow`.
2. `docker compose up -d` — confirm all services Healthy within 90 s.
3. Run through every step of the demo script with a stopwatch.
4. Record any step that needed manual intervention. Fix the underlying cause (config, seed, doc).
5. Re-run until the demo is fully self-serve.

**Acceptance**
- Demo runs end-to-end in ≤ 5 min from `docker compose up` to "Wrap".
- Reviewer can reproduce on their machine without messaging you.

---

## D2 — Production runbook

**Goal:** Write the on-call runbook a stranger could use during an outage.

**Tasks**
1. Author `docs/runbook.md` with sections:
   - **Health URLs & dashboards** (App Insights, Grafana, Jaeger, GHCR).
   - **Common alerts** with first-3-steps for each (5xx burst, DB latency, Redis down, queue backlog).
   - **Rollback procedures** (slot swap, image redeploy, DB).
   - **Escalation contacts** (placeholder names + on-call schedule reference).
2. Run a tabletop exercise: pick one alert, walk a colleague through the runbook with you watching silently.
3. Update gaps where the colleague hesitated.

**Acceptance**
- A teammate unfamiliar with the codebase resolves a simulated alert using only the runbook.

---

## D3 — Threat model review

**Goal:** Refresh the STRIDE threat model from Topic 1 against the now-shipped system.

**Tasks**
1. Open `docs/threat-model.md` (from T1) — re-validate each entry against the actual code.
2. Add new entries for: SignalR (T8), uploads (T9), email (T9), background jobs (T9), CI/CD secrets (T12).
3. For each High-rated risk, link to either the mitigating code or an open ticket.
4. Stamp the doc with the current date and your initials.

**Acceptance**
- Every High risk has a code link or a tracked ticket.
- Threat model is no older than 30 days at submission time.

---

## B1–B5 — Stretch challenges

See `Notes.md` §6 for full briefs. Each lives in its own feature branch and ships through your CI.

| ID | Title | Hard part |
|---|---|---|
| B1 | Multi-tenancy with global query filter | Migrating existing data with no downtime |
| B2 | Full-text search | Picking SQL FTS vs Elastic, tuning relevance |
| B3 | Export to CSV/PDF as background job | Streaming without buffering 100k rows |
| B4 | Audit log viewer with diff | Capturing changes via EF interceptor without slowing writes |
| B5 | i18n end-to-end | Email template translations + locale fallback |

For each chosen challenge:
1. Open a tracking issue with the brief copied in.
2. Author an ADR: `docs/adrs/000X-<challenge>.md`.
3. Implement behind a feature flag; roll out incrementally.
4. Update the demo script to showcase it (10–20 s slot).
5. Update the rubric self-score.

**Submission acceptance**
- ≥ 2 B-series challenges merged into `main`.
- Each has: ADR, tests, observability hooks, demo coverage.
