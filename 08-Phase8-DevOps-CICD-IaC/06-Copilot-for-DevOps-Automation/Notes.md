# Topic 6: GitHub Copilot for DevOps Automation

> **Goal:** Use GitHub Copilot effectively to *accelerate* DevOps tasks — writing pipelines, Terraform, scripts, runbooks, and reviewing diffs — without being misled by hallucinations. The skill isn't "Copilot writes my pipeline"; it's **prompting, verifying, and integrating** AI output into a disciplined workflow.

---

## 1. What "Copilot for DevOps" Actually Is in 2026

GitHub Copilot now spans several surfaces. You'll use each differently:

| Surface | What it does | Best DevOps use |
|---|---|---|
| **Copilot in IDE** (autocomplete + inline chat) | Suggests as you type; multi-line completions | YAML, HCL, scripts |
| **Copilot Chat (IDE / web)** | Conversational Q&A with workspace context | Explain pipeline, draft Bicep, troubleshoot YAML |
| **Copilot CLI** | Translate intent → shell command | One-off `az`, `kubectl`, `terraform` commands |
| **Copilot in pull requests** | Auto-summarises diff; "Copilot review" suggests changes | First-pass PR review |
| **Copilot Workspace** | Plan → spec → patch across multiple files | Multi-file refactors (pipeline rename, module rewrite) |
| **Copilot Coding Agent** | Background agent that takes an issue → opens a PR | Routine tickets ("upgrade Node to 22 across all workflows") |
| **Copilot Extensions** (Azure, Docker, etc.) | First-party + 3rd-party skills | Querying live Azure context, container best practices |

For DevOps specifically, **Copilot Chat + Copilot CLI + Copilot for PRs** are the three you'll use daily. The Coding Agent is for delegating well-scoped tickets.

---

## 2. The Three Failure Modes (and how to avoid them)

Before any code, internalise these:

### 2.1 Hallucinated APIs / resource types

> "Sure, here's the `azurerm_super_app_service_v3` resource…"

Copilot will invent resource names, CLI flags, and YAML keys that *look* right. **Always verify against the actual docs** before applying. Treat any unfamiliar resource/flag as suspect.

### 2.2 Confidently wrong security

Defaults that look reasonable often aren't safe:
- `Allow public network access` defaulted true.
- `--allow-blob-public-access true` because the example was older.
- Service principal with `Owner` "for simplicity".
- Secrets embedded directly.

Read every line of generated security-relevant code as if you wrote it.

### 2.3 Stale syntax

Tools move fast. Generated `azure-pipelines.yml` may use deprecated tasks, AzureRM provider v3 syntax when you're on v4, GH Actions `set-output` (deprecated). Run `terraform validate` / pipeline lint immediately after pasting.

> Rule: **AI-generated code is a draft. You sign your commits.**

---

## 3. Prompting Patterns for DevOps Tasks

### 3.1 "Generate from spec" pattern

Give Copilot a **clear spec**, not "write a pipeline".

❌ "Write a GitHub Actions workflow for .NET."

✅ ```
Write a GitHub Actions workflow that:
- triggers on PR to main (paths: src/**)
- uses ubuntu-latest, .NET 8
- caches NuGet keyed on packages.lock.json
- runs dotnet restore --locked-mode, build -c Release --no-restore, test --no-build
- collects XPlat Code Coverage
- uploads coverage as artifact
- fails the job if coverage < 70%
- pins all actions to SHA, not floating tag
- sets concurrency cancel-in-progress per ref
- timeout-minutes: 15
- permissions: read-only
```

The result will be 90% there. The remaining 10% is yours to fix.

### 3.2 "Explain → modify" pattern

When working with existing pipelines you didn't write:

```
@workspace /explain Explain what this workflow does, stage by stage:

[paste YAML]
```

Then:

```
Now modify it so the deploy job uses OIDC instead of a service principal secret.
Keep all other behaviour identical.
```

This grounds Copilot in *your* code rather than generating from scratch.

### 3.3 "Translate" pattern

```
Translate this Azure Pipelines YAML to an equivalent GitHub Actions workflow.
Preserve job dependencies, caching, and the production approval gate.
```

Or:

```
Convert this Bicep to Terraform (azurerm provider 4.x), keeping all settings.
Use locals for repeated names. Validation rules on environment.
```

### 3.4 "Apply a checklist" pattern

You define the rules; Copilot enforces them:

```
Review this Terraform module against this checklist and list violations:
1. Every storage account has shared_access_key_enabled = false.
2. Every resource has the required tags: project, environment, cost_center, managed_by.
3. No hard-coded secrets.
4. All providers pinned with ~>.
5. Outputs marked sensitive where appropriate.
6. Variables have description + validation.
```

This converts Copilot into a junior reviewer following *your* rules — not its priors.

### 3.5 "Show me the docs URL" pattern

```
Show me where in the official docs the syntax for terraform_data.replace_triggered_by is defined.
Quote the relevant snippet.
```

This catches hallucinations because Copilot must source the answer. If it can't quote real docs, treat the answer as suspect.

---

## 4. Copilot Chat in VS Code: Useful Commands

```text
@workspace      lets Chat see all your files (paths, contents on demand)
@terminal       gives it your last terminal output (great for debugging)
/explain        explain selected code
/fix            propose a fix for a problem
/tests          generate tests for selected code
/doc            write doc comments
/new            scaffold a new file/project
@github         (web/IDE) ask about your repo's PRs, issues, commits
```

DevOps cheat sheet:

| Task | Prompt |
|---|---|
| Debug failing test | `@terminal /fix the failure shown above` |
| Explain mysterious YAML | `@workspace /explain .github/workflows/deploy.yml` |
| Add coverage gate | "Modify the test step to fail if line coverage < 80%" |
| Refactor Terraform | "Extract the storage block into a module modules/storage-account/" |
| Write runbook | "Write a runbook to recover from accidental terraform destroy of dev" |
| KQL from app insights | "Write a KQL query to find 5xx by route in the last 24h" (see Topic 8) |

---

## 5. Copilot CLI

Install:
```powershell
gh extension install github/gh-copilot
gh copilot suggest "list all storage accounts in eastus with public access enabled"
gh copilot explain "az aks get-credentials --resource-group rg --name aks --admin --overwrite-existing"
```

The CLI is great for:
- `az` commands you've forgotten the flags for.
- `kubectl` queries.
- `terraform` operations.
- `git` plumbing ("undo last commit but keep changes staged").

Always read what it suggests before executing — destructive commands look the same as harmless ones in the suggestion box.

---

## 6. Copilot for Pull Requests

### 6.1 Auto-summarise
On PR open, ask Copilot to draft the description. Then **edit it** — Copilot summaries miss context (why, risks).

### 6.2 PR review with Copilot
- *Copilot can be requested as a reviewer.*
- It posts inline comments on diffs.
- Treat it as a junior on your team — catches obvious things, occasionally wrong, never blocking-quality on its own.
- It does **not** replace a code owner.

### 6.3 What to ask for on each PR
- "Summarise behavioural changes (not file changes)."
- "Are there any backwards-incompatible API changes?"
- "Flag any missing tests for new branches."
- "Identify likely breaking changes for downstream consumers."

---

## 7. Copilot Coding Agent (background workhorse)

Assign an issue to Copilot; it opens a PR.

Excellent fit for **clearly scoped, low-risk** DevOps chores:

- "Bump Node version to 22 in all `.github/workflows/*.yml`. Update `setup-node` action to `@v4`."
- "Add `permissions: contents: read` block to every workflow that doesn't have one."
- "Generate a `terraform-docs` README for every module under `modules/`."
- "Pin all GitHub Actions in this repo by SHA."

**Bad** fits:
- "Refactor our deployment strategy." (too open)
- "Migrate from ARM to Bicep." (too risky, too large)
- "Fix this prod incident." (humans + judgement)

Always review the PR before merging. Always.

---

## 8. Concrete Recipes

### 8.1 Generate a GH Actions workflow from a Terraform plan

Prompt:
```
Given this Terraform plan output, generate a GitHub Actions workflow that:
- runs terraform init/plan/apply on push to main
- uses OIDC (vars.AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)
- comments the plan diff on PRs
- requires production environment approval before apply
- pins all actions by SHA

Plan:
[paste truncated plan]
```

### 8.2 Generate a Bicep → Terraform translation

```
Convert the following Bicep to azurerm provider 4.x Terraform.
- Use snake_case for resource labels.
- Group related resources into modules under modules/.
- Extract repeated string concatenations into locals.

Bicep:
[paste bicep]
```

### 8.3 Generate KQL alerts (Topic 8 preview)

```
Generate a KQL query and a Bicep/Terraform resource for an Application Insights alert that:
- Fires when the 5xx rate of route /api/orders exceeds 1% over a 5-min window.
- Severity 2.
- Sends to an existing Action Group whose ID I'll wire in.
```

### 8.4 Generate an incident runbook from a postmortem

```
Read this postmortem and produce a runbook with: detection signals, mitigation steps, escalation path, rollback procedure. Use markdown headings.

[paste postmortem]
```

### 8.5 "Fix this red build" workflow

1. Re-run failing job with debug logging on.
2. In VS Code, open the workflow + the failing log side-by-side.
3. `@terminal /fix` after pasting the relevant slice of log.
4. Apply the suggested patch, **read it**, run `act` locally or push to a branch and retrigger.

---

## 9. Governance: Using Copilot Safely in an Enterprise

### 9.1 Org-level controls
- **Copilot Content Exclusions**: paths in your repos Copilot should never read or learn from (e.g., `secrets/`, customer data).
- **Enterprise telemetry**: turn off prompt logging if compliance demands.
- **Filter setting**: block public-code matches if your license forbids embedding GPL-style snippets.

### 9.2 Per-repo guidance
Add `.github/copilot-instructions.md`. The Coding Agent and PR review read this for context:

```markdown
# Copilot Instructions for taskflow-infra

## Conventions
- Provider: hashicorp/azurerm ~> 4.0
- Resource naming: `<type-prefix>-<project>-<environment>-<region>`
- Always pin GH Actions by SHA, not floating tag
- All modules live under modules/<name>/ and follow versions/variables/main/outputs/README layout

## Security defaults
- Storage accounts: shared_access_key_enabled = false; min_tls_version = TLS1_2
- App Services: https_only = true; minimum_tls_version = 1.2
- Managed Identity over secrets, always
```

Copilot will follow these for code generation in this repo.

### 9.3 Code-review policy
- No PR merges with **only** AI-generated changes if it touches: production deployment, IAM/RBAC, encryption, network.
- Two-human-eyes rule for those classes; Copilot's review is supplementary.

---

## 10. Measuring Whether Copilot Is Helping

Don't take vendor claims at face value. Measure on your own team:

| Metric | How |
|---|---|
| Time to first PR comment | GitHub Insights — does it shrink? |
| PR cycle time | Same dashboard |
| Defect rate (incidents/month) | Stays flat or improves, not worsens |
| Developer satisfaction | Quarterly survey |
| Copilot suggestion acceptance rate | Built-in Copilot dashboard |
| Cost per developer | Compare licence cost vs measured productivity |

A **dropped** acceptance rate combined with stable productivity is fine — it means people are using Copilot more selectively. A *rising* defect rate is a red flag: you're shipping suggestions without enough review.

---

## 11. Where Copilot Reliably Helps DevOps

✓ Boilerplate YAML (90% of a workflow).
✓ Translating between tools (Bicep → TF, ADO → GH Actions).
✓ Writing one-off scripts (PowerShell, Bash, Python).
✓ Drafting documentation, runbooks, READMEs.
✓ Suggesting `az` / `kubectl` / `terraform` invocations.
✓ Generating tests for modules.
✓ Generating KQL queries.
✓ Reviewing PRs for obvious issues.

## 12. Where Copilot Is *Not* Reliable

✗ Choosing an architecture pattern (deployment strategy, network topology).
✗ Security tradeoffs (which key, which scope, which lifetime).
✗ Cost optimisation requiring price-list knowledge.
✗ Migration plans across major versions of services.
✗ "Why is prod down right now?" — too contextual.
✗ Anything where being slightly wrong is catastrophic and you can't tell from the output.

---

## 13. Workflow Recipe: "AI-assisted infra change"

A repeatable loop that keeps AI in the *acceleration* lane, not the *autopilot* lane:

1. **Define the change in English** (issue, ticket, or comment).
2. **Ask Copilot Chat** to propose the smallest diff and explain its reasoning.
3. **Apply the patch.**
4. **Run** `terraform fmt && validate && plan`. Read every line of the plan.
5. **Run policy checks** (`tfsec`, `conftest`, custom rules).
6. **Open a PR**. Request Copilot review + a human reviewer.
7. **Address Copilot's comments selectively** (it will overflag).
8. **Human approves.** Merge.
9. **CI applies.** Watch the deploy.
10. **Postmortem** the change if anything broke. Feed lessons back into `copilot-instructions.md`.

---

## 14. Anti-Patterns

| Anti-pattern | Why it bites |
|---|---|
| Pasting Copilot output without reading | Subtle security flaws ship; you own them |
| Asking Copilot to "make it more secure" | Vague — get specific demands and decisions |
| Letting the Coding Agent loose on prod IaC | One bad prompt → cascading destroys |
| Skipping linters/validators because "Copilot wrote it" | Tools catch more than humans do; both are needed |
| Treating Copilot review as merging gate | It's a junior; humans approve |
| Using public-internet ChatGPT for code with secrets | Secrets leak to a third party |
| Forgetting `copilot-instructions.md` | Copilot keeps inventing conventions |
| Using AI to write your incident postmortem | Loses the human reflection that makes postmortems useful |

---

## 15. Closing Mental Model

Copilot is the **fastest junior on your team**: instant suggestions, no ego, always available, occasionally confidently wrong. The cost of accepting bad suggestions is the same as merging bad code from any junior — you, the experienced human, own the merge button.

If you ship faster by **20%** but your defect rate stays flat, Copilot paid for itself ten times over. If your defect rate goes up by **5%** and you ship faster by 20%, you're now firefighting in the new time you "saved". Track the metrics; adjust the workflow.

---

## Further Reading

- [Copilot for Business / Enterprise docs](https://docs.github.com/en/copilot)
- [Copilot Coding Agent](https://docs.github.com/en/copilot/copilot-coding-agent)
- [Copilot for Pull Requests](https://docs.github.com/en/copilot/using-github-copilot/code-review)
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli)
- [Repository custom instructions](https://docs.github.com/en/copilot/customizing-copilot/about-customizing-github-copilot-chat-responses)
- [Microsoft Learn — Responsible AI for developers](https://learn.microsoft.com/training/paths/responsible-ai-business-principles/)
