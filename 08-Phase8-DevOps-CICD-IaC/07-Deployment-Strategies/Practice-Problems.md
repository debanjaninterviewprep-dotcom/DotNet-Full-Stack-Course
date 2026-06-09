# Topic 7 — Practice Problems

> Solutions in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). For each problem, capture **what** you deployed, **how you measured**, and **what you'd do differently**.

---

## P1 — Wire Up Proper Health Checks

**Goal:** A reliable `/health` is the prerequisite for every strategy below.

**Tasks**
1. In a small ASP.NET Core API, add `Microsoft.Extensions.Diagnostics.HealthChecks` packages.
2. Add three checks: SQL, Blob Storage, Service Bus (mocks fine).
3. Expose:
   - `/health/live` — always 200 if process is up.
   - `/health/ready` — only 200 if all "ready" checks pass.
4. Configure the response writer to return JSON with status, duration, and individual results.
5. Write `P1-test.md` showing both endpoints under healthy / degraded / unhealthy states.

**Deliverables**
- `P1-api/` with the `Program.cs` and any custom check classes.
- `P1-test.md`.

**Look-fors**
- [ ] Liveness does NOT depend on external services.
- [ ] Readiness fails when any dependency is broken.
- [ ] Response JSON includes per-check duration.

---

## P2 — Blue-Green via App Service Slots

**Goal:** Zero-downtime deploy with one-click revert.

**Tasks**
1. Provision (Terraform) an App Service + `staging-slot`.
2. Configure `/health/ready` as the slot warm-up path.
3. Mark `ASPNETCORE_ENVIRONMENT` as sticky.
4. Write `P2-deploy.yml`:
   - Build artifact.
   - Deploy to `staging-slot`.
   - Poll `/health/ready` until 200 (with timeout).
   - Run smoke tests.
   - Swap.
   - Verify prod `/health/ready`.
5. Deploy v1 → v2 → demonstrate revert by re-swapping.
6. Capture timings in `P2-results.md` (deploy, warm-up, smoke, swap).

**Deliverables**
- Terraform under `P2-infra/`.
- `P2-deploy.yml`.
- `P2-results.md`.

**Look-fors**
- [ ] Slot has its own MI granted the same roles as prod.
- [ ] Smoke tests fail the pipeline if non-200.
- [ ] Revert is a single command.

---

## P3 — Canary with Traffic Routing

**Goal:** Send 10% of real traffic to the new version before full promotion.

**Tasks**
1. Reuse P2's setup. After deploy to staging-slot (and successful warm-up), set traffic routing to 10% on `staging-slot`.
2. Hold for 15 min while you watch metrics (App Insights — request rate, failure rate, p95 latency).
3. Decide based on **pre-declared** success criteria:
   - Error rate on canary ≤ baseline + 0.1pp.
   - p95 latency on canary ≤ baseline × 1.1.
4. If pass → swap. If fail → set routing back to 0.
5. Write `P3-canary-runbook.md` with the criteria, the queries, and the decision tree.

**Deliverables**
- `P3-canary.yml` (the pipeline that sets routing and pauses).
- `P3-canary-runbook.md`.
- Screenshots / KQL exports of the metric comparisons.

**Look-fors**
- [ ] Success criteria written **before** the canary, not invented after.
- [ ] Decision is metric-driven, not vibes.
- [ ] Rollback step actually tested.

---

## P4 — Feature Flag with Azure App Configuration

**Goal:** Decouple deploy from release.

**Tasks**
1. Add an App Configuration store with `Microsoft.Targeting` filter enabled.
2. In the API, gate a new endpoint (`/api/orders/new`) behind a `NewOrderPipeline` flag.
3. Initially target 0% rollout, plus user list of one beta tester.
4. Deploy. Verify beta tester sees it, others don't.
5. Bump rollout to 25%; verify approximately 25% of `IsEnabledAsync` calls return true.
6. Write `P4-flag-lifecycle.md` describing: who can flip flags, how flags are reviewed, and when they're removed.

**Deliverables**
- `P4-api/` with the flag wiring.
- App Configuration export (`P4-flags.json`).
- `P4-flag-lifecycle.md`.

**Look-fors**
- [ ] `IsEnabledAsync` checked at request time (not just startup).
- [ ] Cache expiration documented and reasonable (≤ 60 s).
- [ ] Lifecycle doc commits to a removal date.

---

## P5 — Schema Migration with Expand/Contract

**Goal:** Rename a column without breaking either version.

**Tasks**
1. Pick a column to rename (e.g., `Customer.PhoneNumber` → `Customer.PrimaryPhoneNumber`).
2. Plan the four steps (Expand, Migrate, Switch, Contract).
3. Write four EF Core migrations + the corresponding code changes.
4. Deploy each step independently. After each step, **both** the old and new code must still work.
5. `P5-migration-plan.md` documents each step + the rollback for each.

**Deliverables**
- `P5-migrations/Step1-...` through `Step4-...`
- `P5-migration-plan.md`

**Look-fors**
- [ ] No step requires both old and new code to be live simultaneously broken.
- [ ] Each step has a rollback path.
- [ ] Backfill script (Step 2) is idempotent.

---

## P6 — Auto-Rollback on Alert

**Goal:** Self-healing on a high-confidence signal.

**Tasks**
1. Create an App Insights alert: 5xx rate > 5% over 2 min (Severity 1).
2. Wire the alert to a webhook that triggers a GitHub `repository_dispatch` event.
3. Write `P6-rollback.yml`:
   - Triggered on `repository_dispatch` with `event_type: prod-5xx-spike`.
   - Re-swaps the slot back.
   - Annotates App Insights with `RollbackTriggered`.
   - Posts to a Teams/Slack channel.
4. Demonstrate by force-deploying a broken build, observing alert, observing rollback.

**Deliverables**
- Alert definition (`P6-alert.json` or Bicep).
- `P6-rollback.yml`.
- `P6-demo.md` with the timeline.

**Look-fors**
- [ ] Signal threshold isn't so jumpy that flaky deploys trigger unfair rollbacks.
- [ ] Notification fires.
- [ ] Rollback is logged.

---

## P7 (Stretch) — Container Apps Revisions

**Goal:** Same idea, different platform.

**Tasks**
1. Deploy the API as a Container App with two revisions live.
2. Split traffic 90/10.
3. Promote to 100% on success; revert via `traffic` set.
4. Compare developer experience vs App Service slots in `P7-comparison.md`.

**Deliverables**
- `P7-containerapp.bicep` or Terraform.
- `P7-deploy.sh`
- `P7-comparison.md`.

**Look-fors**
- [ ] Old revision deactivated after promotion (else cost leaks).
- [ ] Comparison is concrete, not generic.

---

## Submission

Tell me **"check P2"** (or a range) for graded review.
