# Practice Problems — AI in CI/CD & Infrastructure Automation

> Tell me **"check"** after finishing.

---

## P1 — AI-Authored CI Workflow (Manually Hardened)

**Goal:** Use Copilot to draft a CI workflow, then harden it.

**Tasks:**
1. Prompt Copilot to generate a `.github/workflows/ci.yml` for a .NET 8 solution: build, test (xUnit), coverage upload.
2. Save **Copilot's first draft verbatim** in `ci-draft.yml`.
3. Audit it for: stale action versions, `permissions: write-all`, missing concurrency, missing cache, missing TRX upload, etc.
4. Produce a hardened `ci.yml`.
5. In `audit.md`, list every issue + fix.

**Deliverable:** both YAMLs + `audit.md`.

**Look-fors:** Pinned SHAs in hardened version; `permissions: contents: read` default; concurrency present; at least 6 audit findings.

---

## P2 — AI Log Triage Action

**Goal:** Build a reusable composite action that summarises failing-step output and comments on the PR.

**Tasks:**
1. Compose `.github/actions/ai-log-triage/action.yml` with inputs: `step-log-path`, `model`, `max-tokens`.
2. Action runs a Bash/PowerShell step that:
   - Trims the log to the last 200 lines (or the section after the first ERROR).
   - Calls Azure OpenAI / OpenAI with a structured prompt requesting JSON output.
   - Parses the JSON.
   - Posts a comment via `gh pr comment` containing the diagnosis and the trimmed snippet.
3. Wire it into a CI workflow that intentionally fails.
4. Capture the resulting PR comment.

**Deliverable:** `action.yml`, the wiring workflow, and a screenshot of the comment on a failed PR.

**Look-fors:** Output is structured JSON; comment is concise; secrets not leaked; runs only on `failure()`.

---

## P3 — Terraform PR Reviewer

**Goal:** Build a PR-time AI reviewer for Terraform plans.

**Tasks:**
1. Workflow runs `terraform plan -out tfplan` then `terraform show -no-color tfplan > plan.txt`.
2. Also runs `tfsec . --format json > tfsec.json` and `infracost diff --path . --format json > cost.json`.
3. A composite action takes the three files, calls a model, and posts:
   - MUST_FIX / SHOULD_FIX / NICE list.
   - Net-new monthly cost.
   - Resources marked for destroy/replace.
4. Trigger on a real PR with a meaningful change. Capture the comment.

**Deliverable:** Workflow + composite action + screenshot.

**Look-fors:** All three signals used; destroys called out loudly; cost shown.

---

## P4 — MCP-Enabled Incident Triage Agent

**Goal:** Build a small triage agent using MAF (or SK) and at least 2 MCP servers (or simulated tool wrappers).

**Tasks:**
1. .NET 8 console / Function app.
2. Tools (real MCP servers if available, otherwise local function wrappers): `query_app_insights(kql)`, `list_recent_deploys(repo)`, `read_runbook(name)`.
3. Agent system prompt asks for structured JSON output (see Notes §8).
4. Simulated input: an alert payload JSON.
5. Output: the triage JSON + a formatted Teams-style markdown card.

**Deliverable:** Source + sample input + sample output.

**Look-fors:** Tools are well-scoped (read-only); output schema strictly enforced (e.g., via System.Text.Json validation); refuses to invent if tool returns empty.

---

## P5 — Documentation Pipeline

**Goal:** Pipeline that updates `docs/api-reference.md` from the OpenAPI spec on every release.

**Tasks:**
1. Workflow trigger: release published.
2. Steps: generate OpenAPI → render to markdown → AI pass to enrich operation summaries from XML doc comments of the matching C# methods.
3. Open a PR (not push direct) so a human approves.
4. Demonstrate one round-trip.

**Deliverable:** Workflow + PR screenshot.

**Look-fors:** Opens PR; doesn't push direct; enrichment doesn't fabricate; PR has a clear title and description.

---

## P6 — AI Cost & Capacity Forecast

**Goal:** Forecast next 30 days of traffic and recommend SKU.

**Tasks:**
1. Pull (or simulate) 90 days of daily request counts from App Insights.
2. Feed to AI with the prompt template from Notes §7.
3. Cross-check with a simple linear regression in Python or Excel.
4. Produce a `recommendation.md` with both numbers and a final decision.

**Deliverable:** Data CSV + AI output transcript + cross-check sheet + `recommendation.md`.

**Look-fors:** AI is treated as draft; cross-check actually performed; recommendation honest about uncertainty.

---

## P7 — Security & Governance Checklist for AI in CI

**Goal:** Define your team's guardrails.

**Tasks:** Author `ai-in-ci-governance.md` covering:
1. Allowed models / endpoints (and why).
2. Where prompts and outputs are logged.
3. How secrets are kept out of prompts.
4. Approval matrix: who can change AI-using workflows.
5. Kill switch: how to disable all AI steps tenant-wide in < 5 min.
6. Cost ceiling per repo / month.
7. Annual review schedule + owner.

**Deliverable:** `ai-in-ci-governance.md`.

**Look-fors:** Real owners named; kill switch credible; cost ceiling enforceable.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 10 | Audit findings substantive; hardened YAML correct |
| P2 | 20 | Triage action works end-to-end; structured output |
| P3 | 20 | PR comment substantive; destroys highlighted |
| P4 | 20 | Agent uses tools; refuses on empty; output schema strict |
| P5 | 10 | Pipeline opens PR; no fabricated content |
| P6 | 10 | Cross-check performed; uncertainty stated |
| P7 | 10 | Real governance; kill switch credible |

Total: 100. Pass: 70.
