# Topic 8 — Practice Problems

> Solutions in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). Each problem produces working code/queries + a brief note explaining the *choice*, not just the *what*.

---

## P1 — Instrument an API with OpenTelemetry + App Insights

**Goal:** Get a service emitting requests, dependencies, traces, metrics, logs to App Insights.

**Tasks**
1. In a small ASP.NET Core API, install `Azure.Monitor.OpenTelemetry.AspNetCore`.
2. Wire `UseAzureMonitor` reading the connection string from config.
3. Add a Service Name and Environment via `OTEL_RESOURCE_ATTRIBUTES`.
4. Use `ILogger` with structured templates everywhere — no string interpolation.
5. Add one custom event (`OrderCreated`) and one custom metric (`OrdersPerSecond`).
6. Run; generate some traffic; verify in App Insights:
   - `requests` populated.
   - `dependencies` shows your SQL/HTTP calls.
   - `traces` shows your logs.
   - `customEvents` has `OrderCreated`.
   - `customMetrics` shows `OrdersPerSecond`.

**Deliverables**
- `P1-api/` source.
- `P1-verification.md` with KQL queries + screenshots / line counts proving each pillar.

**Look-fors**
- [ ] Connection string injected, not key.
- [ ] Sampling configured explicitly (not default-defaults).
- [ ] Custom dimensions present on logs (e.g., `TenantId`).
- [ ] Errors are NOT sampled away.

---

## P2 — KQL: Build a Service Health Query Suite

**Goal:** Author and save the queries on-call will use.

**Tasks**
Write the following KQL queries, each saved to `P2-queries/<name>.kql` with a one-paragraph header explaining purpose:
1. RPS by route (last 1 h).
2. 5xx rate over time (last 24 h).
3. P50 / P95 / P99 latency per route (last 24 h).
4. Slowest dependencies (last 1 h).
5. Top 25 distinct exception signatures (last 7 d).
6. End-to-end trace for a given `operation_Id` (parameterised).
7. Funnel: `OrderStarted` vs `OrderCompleted` per hour.

**Deliverables**
- `P2-queries/*.kql`
- `P2-cheatsheet.md` indexing them.

**Look-fors**
- [ ] Every query has a comment header.
- [ ] Aggregation windows are explicit (`bin()`).
- [ ] No `*` selections — projections are deliberate.

---

## P3 — Alert Rules with Runbooks

**Goal:** Three meaningful alerts wired end-to-end.

**Tasks**
1. Create an Action Group `ag-taskflow-oncall` with email + Teams webhook.
2. Create three alerts:
   - **Sev 1**: 5xx rate > 1% over 5 min (KQL alert).
   - **Sev 1**: p95 latency on `/api/orders` > 1 s over 10 min.
   - **Sev 2**: dependency `sql` failure rate > 5% over 5 min.
3. For each alert, link to a runbook URL (`P3-runbooks/<alert>.md`) with:
   - Symptoms.
   - First diagnosis (KQL).
   - Mitigation.
   - Escalation.

**Deliverables**
- Bicep or Terraform under `P3-alerts/`.
- `P3-runbooks/*.md`.

**Look-fors**
- [ ] Alerts use scheduled-query rule (KQL), not metric thresholds, for the rate ones.
- [ ] Runbooks are concrete (have actual commands, not "investigate logs").
- [ ] Severity matches actionability.

---

## P4 — Two Dashboards for Two Audiences

**Goal:** One for on-call, one for product.

**Tasks**
1. **On-call dashboard**: 6 tiles — RPS, 5xx rate, p95 latency, dependency latency, exception rate, queue depth.
2. **Product KPI dashboard**: 4 tiles — orders/sec, signups/day, conversion rate, revenue/hour.
3. Export both as JSON to `P4-onCall.json` and `P4-product.json` (use the Portal "Share → Download to file").
4. Document audience + refresh cadence in `P4-README.md`.

**Look-fors**
- [ ] No tile is "kitchen sink".
- [ ] Charts have axis labels and reasonable Y-axis scaling.
- [ ] Audience is named.

---

## P5 — Workbook for Deploy Investigation

**Goal:** Hand the on-call engineer a parameterised investigation tool.

**Tasks**
1. Build an App Insights Workbook with parameters: `Environment`, `TimeRange`, `Version`.
2. Sections:
   - Deploy timeline (annotations from `customEvents` where name = `DeploymentCompleted`).
   - Pre vs post comparison (rate of 5xx, p95 latency) computed automatically.
   - Top new exception signatures since the version started.
   - Dependency change comparison.
3. Export as `P5-deploy-workbook.json`.

**Deliverables**
- `P5-deploy-workbook.json`
- `P5-screenshot.md` (or actual screenshots).

**Look-fors**
- [ ] Parameters drive every query.
- [ ] Auto-detects "before" window relative to deploy.
- [ ] Markdown sections explain what each chart means.

---

## P6 — SLO + Error Budget Alert

**Goal:** Alert on burn rate, not raw thresholds.

**Tasks**
1. Define an SLO for TaskFlow API: 99.9% success over 28 days.
2. Write the KQL that computes consumed error budget and burn rate.
3. Two alerts:
   - **Fast burn** (10× budget in 1 h) → Sev 1.
   - **Slow burn** (2× over 6 h) → Sev 2.
4. Write `P6-slo.md` explaining: what counts as success, freeze policy when burn ≥ 100%, who owns the budget.

**Deliverables**
- `P6-slo.kql`
- Two alert rule definitions.
- `P6-slo.md`.

**Look-fors**
- [ ] KQL handles low-traffic windows without divide-by-zero.
- [ ] Freeze policy is concrete (no new features when burned out).

---

## P7 (Stretch) — Cost-Reduce a Noisy Workspace

**Goal:** Cut LA cost by 30%+ without losing forensic value.

**Tasks**
1. In Log Analytics, run `Usage | where TimeGenerated > ago(7d)` — identify the top 5 tables by GB.
2. Propose changes for each (lower retention, switch to Basic Logs, ingest-time transform to drop fields, sampling).
3. Implement at least three of the proposals.
4. Recompute after one week (or simulate with a smaller window).
5. Document in `P7-cost-reduction.md`.

**Deliverables**
- `P7-current-usage.kql`
- Transformation rule JSON / Bicep.
- `P7-cost-reduction.md` with before/after numbers.

**Look-fors**
- [ ] Real measurement, not guess.
- [ ] No security-critical data dropped (audit logs, sign-ins).
- [ ] Daily cap configured as a safety net.

---

## Submission

Tell me **"check P2"** (or a range) for graded review.
