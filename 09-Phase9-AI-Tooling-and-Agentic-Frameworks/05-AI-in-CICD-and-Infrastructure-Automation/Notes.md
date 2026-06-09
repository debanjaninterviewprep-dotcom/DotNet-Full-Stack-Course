# Topic 5: AI in CI/CD & Infrastructure Automation

## What You'll Learn

Where AI fits into your **pipelines** and **infrastructure as code** — without becoming the next outage. Concrete patterns for AI-assisted YAML authoring, log triage, flaky-test detection, Terraform/Bicep generation, drift remediation, security review, cost forecasting, MCP servers in CI, and AI-driven on-call runbooks.

> **Hard rule:** AI proposes, humans approve. Autonomous AI changes to production are not on the table for any system that matters.

---

## 1. Where AI Helps in CI/CD (and Where It Doesn't)

### Wins

| Activity | Win |
|---|---|
| YAML scaffolding | Copilot writes 80% of a new workflow correctly |
| Pipeline debugging | Summarises huge logs into "the actual failure" |
| Flaky-test triage | Spots intermittent patterns across many runs |
| Terraform module skeletons | Generates idiomatic module structure |
| Schema migrations | Drafts EF/Bicep diffs from a description |
| Security review | Catches obvious anti-patterns in PR-time pipeline edits |
| Incident triage | Drafts the runbook narrative from alerts + logs |
| Documentation | Keeps READMEs and ADRs current with diffs |

### Things AI is bad at

| Activity | Why |
|---|---|
| Choosing between three reasonable architectural options | Reasoning depth + missing org context |
| Estimating real-world Azure cost | Token-level intuition; pricing changes |
| Diagnosing novel infra bugs | Without telemetry context, it confabulates |
| Modifying production without rollback path | Trust boundary |
| Replacing oncall judgement at 3 AM | Confidence ≠ correctness |

### The non-negotiable boundary

```
AI is in the loop everywhere EXCEPT the final apply on production.
That step needs a human-typed approval or a tightly scoped, reviewed,
auditable automation — never a chat agent free-form.
```

---

## 2. AI-Assisted Workflow Authoring

A practical sequence:

1. **Describe the goal in plain English** at the top of the file:
   ```yaml
   # Goal: build, test, dotnet stryker on PR; deploy to dev on push to main
   #       via slot-swap; require approval for staging and prod.
   ```
2. Generate first draft with Copilot Edits or Chat.
3. **Verify versions** (Copilot loves stale action versions). SHA-pin everything.
4. **Verify permissions**. The default model assumes `permissions: write-all`. Force `permissions: contents: read` + minimal additions.
5. **Verify OIDC**. If you see `secrets.AZURE_CREDENTIALS`, replace with `azure/login` OIDC flow.
6. Run on a throwaway branch with `act` or a dev branch protection.

### Prompt example (good)

```
Generate a GitHub Actions workflow that:
- Triggers on PR to main and push to main.
- Builds a .NET 8 solution, runs xUnit tests, uploads TRX + coverage.
- On push to main only: publishes the API, uploads as artifact, deploys
  to App Service slot 'staging' using OIDC azure/login.
- Concurrency: cancel-in-progress on same ref.
- Permissions: contents:read by default; id-token:write only on the deploy job.
- Pin every action by SHA.
- Use ubuntu-latest. Use actions/cache for NuGet.
```

The constraint list is what makes the output usable.

### Common mistakes Copilot makes

| Mistake | Symptom | Fix |
|---|---|---|
| `actions/checkout@v3` (stale) | Deprecated warning | Pin SHA of `v4` |
| `permissions: write-all` | Token over-privileged | Default read; add per-job |
| `secrets.GITHUB_TOKEN` for cross-repo | 403 | Use a fine-grained PAT or app token |
| Missing `concurrency.group` | Concurrent deploys race | Add `${{ github.ref }}` |
| `if: success()` everywhere | Steps run after fail | Default behaviour is success(); remove |
| Hard-coded environment | Drift between dev/prod | Use environment matrix or job env |

---

## 3. AI Log Triage

CI logs are noisy. AI flattens that noise into "the actual failure".

### Patterns

**Pattern 1: paste-and-summarise.** Open the failed step's raw log, paste into chat:
```
Below is the failing step log. Identify:
1. The line where the actual failure starts.
2. The probable root cause in one sentence.
3. The minimal fix.
Do not invent if uncertain — say "insufficient context" instead.
```

**Pattern 2: "is this flaky?"** When you have a suspicion, give the last 20 runs of the same job:
```
For each run, classify pass / fail / cancelled.
For each fail, summarise the error.
Cluster failures by similarity.
Are these consistent with one root cause or many?
```

**Pattern 3: automatic comment on red CI.** A GitHub Action that, when the CI workflow fails on a PR, runs a small model with the step output and posts a comment with the suggested diagnosis. Caveat: needs careful prompt-injection guardrails on log content.

### Anti-pattern
Pasting the entire build log (often 500 KB+). The model summarises shallowly because most of the context is `npm install` noise. Trim to the failed step.

---

## 4. AI for Terraform / Bicep Generation

### Module scaffolding

Prompt template:
```
Generate a Terraform module 'azure-app-service' with:
- INPUTS: name (string), resource_group_name (string), location (string),
          sku_name (string, default 'P1v3'), app_settings (map(string), default {}),
          tags (map(string)).
- RESOURCES: azurerm_service_plan, azurerm_linux_web_app with deployment slot 'staging'.
- OUTPUTS: web_app_id, default_hostname, slot_hostname.
- Use provider `hashicorp/azurerm ~> 4.0`.
- Sensible defaults: HTTPS only, FTP disabled, TLS 1.2 min.
- Include README.md with usage example.
- Include variables.tf with validation blocks for sku_name (allowed list).
```

Then **read every line** — the model loves to:
- Forget `https_only = true`.
- Default `min_tls_version` to nothing.
- Use deprecated resources (e.g., `azurerm_app_service` instead of `azurerm_linux_web_app`).
- Omit validation blocks.
- Add `client_secret` variables you don't want.

### Plan diffing assistance

After `terraform plan`:
```
Below is a terraform plan output (~200 lines). Categorise the changes:
- ADDS (resource type counts)
- MODIFIES (with which attributes change)
- DESTROYS (call these out loudly)
- REPLACEMENTS (recreate-in-place that will cause downtime)
Identify anything in DESTROYS or REPLACEMENTS that should require a manual ticket.
```

This is the single most useful pipeline use case — fast, low-risk, high-value.

### Drift remediation

When `terraform plan` reports drift (someone changed something in the portal):
```
This plan shows drift. For each drifted resource:
- Was the change additive or destructive?
- Should we accept the drift (update config) or revert (let plan apply)?
- Any blast-radius concerns?
Output a Markdown table.
```

Use the table to drive a decision meeting; don't auto-apply.

---

## 5. MCP — Model Context Protocol in CI/CD

**Model Context Protocol** is an open protocol (originated at Anthropic, adopted across the industry including Microsoft) that lets AI assistants talk to **tools** — file systems, databases, APIs, git, Kubernetes — via a standard wire format.

Why it matters for CI/CD:
- Your CI agents (running Copilot CLI or a coding agent) can call **standardised MCP servers** to read git history, run `terraform plan`, query monitoring, etc., without you wiring each integration manually.
- Microsoft and the community ship MCP servers for: filesystem, git, GitHub, Azure DevOps, Kubernetes, PostgreSQL, Azure Resource Graph, App Insights/Log Analytics, Cosmos DB.

### Example: an MCP-enabled CI assistant

A GitHub Action that, on a comment `@copilot triage` in a failing PR:
1. Spins up MCP servers: GitHub (read PR diff), App Insights (query last hour of telemetry), Terraform (run plan in dev).
2. Sends a structured request to a Copilot agent: "the build failed; here's the diff, the test log, and the telemetry — propose a root cause."
3. Posts the agent's analysis as a PR comment.

MCP standardises step 1 across agents. Without it, every tool integration is custom.

### Security considerations for MCP in CI
- MCP servers expose tools to LLMs. **Treat the LLM as a low-trust caller.**
- Restrict server permissions to read-only where possible.
- Never run an MCP server with cluster-admin / subscription-owner credentials.
- Log every MCP call with the prompt that triggered it (audit trail).
- Pin MCP server versions (supply-chain risk identical to any other binary).

---

## 6. AI in Infrastructure Security Review

Pipeline pattern:
1. Terraform PR opens.
2. CI runs `terraform plan` and saves to `plan.txt`.
3. Run `tfsec` / `checkov` for known anti-patterns.
4. Pipe `plan.txt` + scanner output into Copilot:
   ```
   Review this plan + scanner output. Identify:
   - any storage account with public network access
   - any role assignment broader than necessary
   - any KMS / Key Vault setting that weakens security
   - any cost spike beyond $X/month for net-new resources
   Categorise as MUST_FIX / SHOULD_FIX / NICE.
   ```
5. Post the categorised list as a PR comment.
6. Reviewer signs off on each MUST_FIX explicitly.

This catches a *meaningful* fraction of misconfigurations that scanners alone miss because scanners check resource-level rules, not cross-resource intent.

---

## 7. AI-Assisted Cost & Capacity Estimation

Two practical patterns:

### Pre-merge plan
Run `infracost` on the plan. Post the diff in PR comments. Then ask Copilot:
```
Below is an infracost diff. For each net-new monthly cost > $50:
- Is the SKU appropriate for the workload described in the PR?
- Suggest a cheaper alternative that meets the SLA.
- Quantify the savings.
```

### Capacity forecasting
Feed last 90 days of `requests | summarize sum(itemCount) by bin(timestamp, 1d)` to Copilot:
```
Project the next 30 days assuming linear growth. Then assuming compounding 5%/week. Compare. Recommend whether to scale the App Service Plan from P1v3 to P2v3 and when.
```

Treat this as a *first draft*. Run the same numbers through a proper forecaster (`Prophet`, internal model) for any spend decision > a small threshold.

---

## 8. AI for Incident Response

The dream: an alert fires, AI drafts a triage note, on-call reviews.

A realistic pipeline:
1. Alert (e.g., 5xx rate breach) fires via Azure Monitor.
2. Action Group webhook hits a Function App.
3. Function:
   - Pulls last 30 min of relevant KQL (failed requests, deps, exceptions).
   - Pulls last 24 h of changes (Azure Activity Log, GitHub deploys).
   - Calls a Copilot/LLM with: alert details + telemetry + change feed + the on-call runbook.
   - Posts a draft triage to the Teams incident channel:
     ```
     Likely root cause: deploy 2026-06-08 14:22 introduced N+1 query on /api/projects.
     Suggested action: roll back via slot swap (last good = 2026-06-08 14:01).
     Confidence: medium.
     Evidence: [links to App Insights queries used]
     ```
4. On-call reviews, accepts/rejects, takes action.

What this is **not**: an AI auto-rollback. The human still pulls the trigger. The AI just compresses the first 15 minutes of triage into 30 seconds of reading.

### Implementation pattern
Use **Semantic Kernel** or **Microsoft Agent Framework** (Topic 3). Tools:
- `query_app_insights` (KQL).
- `list_recent_deploys` (GitHub API).
- `list_azure_activity_log` (last 24 h, filtered).
- `read_runbook` (markdown from a known repo path).

Output schema (force JSON):
```json
{
  "summary": "string",
  "likely_root_cause": "string",
  "confidence": "low|medium|high",
  "suggested_actions": [{"action": "string", "risk": "low|medium|high"}],
  "evidence_links": ["url"]
}
```

Structured output prevents wild prose and lets you template the Teams message.

---

## 9. Documentation Automation

AI keeps docs current — if you wire it into the pipeline.

Patterns:
- **PR description from diff** (Topic 4) → also auto-publish to release notes.
- **ADR (Architecture Decision Record) draft from a Slack/Teams discussion**: paste the conversation, ask Copilot to draft an ADR in the project's template.
- **Runbook from incident timeline**: after each incident, feed the timeline → draft updated runbook section.
- **API reference from OpenAPI**: regenerate every release; AI suggests improvements to operation summaries by reading the actual implementation.

Trap: AI is *very* willing to keep doc auto-regenerated. Without human gating, docs become slop. Always have a human approve.

---

## 10. Putting It Together — A Reference Pipeline

```yaml
name: ci-cd-with-ai

on:
  pull_request:
  push: { branches: [main] }

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write    # for AI comments
    steps:
      - uses: actions/checkout@<SHA>          # pinned
      - uses: actions/setup-dotnet@<SHA>
        with: { dotnet-version: '8.0.x' }
      - run: dotnet test -c Release --logger "trx" --collect:"XPlat Code Coverage"
      - name: AI log triage on failure
        if: failure()
        uses: ./.github/actions/ai-log-triage
        with:
          step-log-path: ${{ steps.test.outputs.log }}
          model: gpt-4o-mini

  terraform-plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      id-token: write
    steps:
      - uses: actions/checkout@<SHA>
      - uses: azure/login@<SHA>
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: terraform init && terraform plan -out tfplan -no-color | tee plan.txt
      - run: tfsec . --format json > tfsec.json
      - run: infracost diff --path . --format json > cost.json
      - name: AI review of plan + scanners + cost
        uses: ./.github/actions/ai-tf-review
        with:
          plan: plan.txt
          tfsec: tfsec.json
          cost: cost.json
          comment-pr: true

  deploy-staging:
    if: github.event_name == 'push'
    needs: build
    runs-on: ubuntu-latest
    environment: staging          # human approval required
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: azure/login@<SHA>
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: az webapp deploy ...
```

Reusable AI steps (`./.github/actions/ai-log-triage`, `./.github/actions/ai-tf-review`) wrap a small CLI that calls the model with structured input + a system prompt and posts a PR comment. Same pattern, many uses.

---

## 11. Anti-Patterns

| Anti-pattern | Why it's bad | Better |
|---|---|---|
| Autonomous AI changes to prod | Trust + accountability | AI proposes, human approves |
| Pasting full multi-MB logs into chat | Shallow analysis | Trim to failing step |
| AI-suggested Terraform applied without `plan` review | Subtle destroys | Always `terraform plan` first |
| Wide-permission MCP servers | LLM is a low-trust caller | Read-only, scoped credentials |
| AI generating workflows with `permissions: write-all` | Token over-privilege | Default `contents: read` + per-job adds |
| Copilot CLI in CI runner with secrets in env | Leak risk | Run CLI in a sandboxed step; redact env |
| Auto-merging Copilot PRs without review | Same as humans without review | Branch protection + human reviewer |
| Trusting AI cost estimates as ground truth | Stale pricing data | Cross-check with infracost / pricing API |
| Letting AI compose alert thresholds | False sense of rigor | Engineer-defined SLOs |
| "We'll add the runbook later" | Incident at 3 AM | AI drafts the runbook from postmortems automatically |

---

## 12. Measuring the Value

| Metric | What it tells you | Trap |
|---|---|---|
| Mean time to triage (MTTT) | AI log triage value | If MTTR doesn't follow, you're polishing brass |
| Mean time to recovery (MTTR) | Real incident-response benefit | Lagging; needs many incidents |
| % of TF PRs with AI review comment acted upon | Are humans listening? | "Acted upon" loose; define it |
| % of CI failures with model diagnosis matching the real fix | Quality of triage | Needs honest post-fix scoring |
| Cost of AI in the pipeline | Don't lose money on the AI | Track per-run cost, cap monthly |

---

## 13. Mental Model

> AI in CI/CD is the **first responder**: it triages, drafts, and proposes. Humans approve, deploy, and own the outcome. Wire AI everywhere except the final apply on production — and even there, only with a human-typed `yes`.

Move to [Practice Problems](./Practice-Problems.md).
