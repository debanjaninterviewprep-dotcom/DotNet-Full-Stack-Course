# Topic 1: GitHub & Azure DevOps Fundamentals

> **Goal:** By the end of this topic you can confidently explain the difference between GitHub and Azure DevOps, set up a repository with the right branching strategy and protections, configure service connections / OIDC federation to Azure, and pick the right CI host for a given team. Every section ends with **TaskFlow-specific guidance** so the patterns map back to a real project.

---

## 1. Why DevOps Exists (and what it actually means)

DevOps is **not a tool**. It's an operating model whose goal is to make the path from "developer types code" to "value running in production" short, safe, and observable.

The four DORA metrics (from *Accelerate*) tell you whether your DevOps is working:

| Metric | What it measures | Elite target |
|---|---|---|
| **Deployment Frequency** | How often you ship | On-demand (multiple/day) |
| **Lead Time for Changes** | Commit → prod time | < 1 day |
| **Change Failure Rate** | % deploys causing incidents | 0–15% |
| **MTTR** | Time to recover from incident | < 1 hour |

Tools (GitHub, Azure DevOps, Terraform, etc.) are means to move those numbers. Always justify a tool choice by which metric it improves.

### The DevOps lifecycle

```
Plan → Code → Build → Test → Release → Deploy → Operate → Monitor → (back to Plan)
```

Each stage maps to features in GitHub / Azure DevOps:

| Stage | GitHub | Azure DevOps |
|---|---|---|
| Plan | Issues, Projects | Boards |
| Code | Repos, PRs | Repos, PRs |
| Build | Actions | Pipelines (Build) |
| Test | Actions + 3rd party | Pipelines + Test Plans |
| Release | Environments, Deployments | Pipelines (Release) / YAML |
| Deploy | Actions (with environments) | Pipelines + Deployment Groups |
| Operate | — (via Azure) | — (via Azure) |
| Monitor | Insights, Code Scanning | Analytics, Test Analytics |

---

## 2. Git Internals You Must Know

Most pipeline failures trace back to a misunderstood Git concept. Five you cannot skip:

### 2.1 The three trees
- **Working directory** — files you edit.
- **Staging area (index)** — what `git add` records; what the next commit will contain.
- **HEAD** — the commit your branch currently points to.

A commit is a snapshot, not a diff. Branches are *pointers* to commits.

### 2.2 Fast-forward vs three-way merge
- **Fast-forward**: target branch hasn't moved → pointer just slides forward. Linear history.
- **Three-way merge**: both branches moved → Git produces a merge commit with two parents.

Pick one strategy *organisation-wide* and enforce it via branch protection.

### 2.3 Rebase vs merge

| | `git merge` | `git rebase` |
|---|---|---|
| History shape | Branchy, preserves topology | Linear |
| Conflicts | Resolved once, in merge commit | Resolved per replayed commit |
| Safe on shared branch? | Yes | **No** (rewrites history) |
| Pick when | Long-lived feature, team workflow | Personal/short branch before PR |

Golden rule: **never rebase commits that have been pushed and others have based work on**.

### 2.4 The reflog is your seatbelt
```bash
git reflog                    # every HEAD movement, last 90 days
git reset --hard HEAD@{2}     # jump back 2 movements
```
You almost never lose work as long as a commit was created locally. Train this reflex.

### 2.5 .gitignore vs assume-unchanged vs skip-worktree

| Mechanism | Use case |
|---|---|
| `.gitignore` | Files Git should never see (build output, `.env`) |
| `git update-index --assume-unchanged file` | Performance hint; don't use to "hide" changes |
| `git update-index --skip-worktree file` | Locally modify a tracked file (e.g., `appsettings.Development.json`) without committing |

---

## 3. Branching Strategies (and which to pick)

There are four mainstream strategies. They differ in **branch lifetime** and **release coupling**.

### 3.1 Git Flow (heavy)

```
main (production) ──────────────────────●─────●─── (release tags)
                                       /     /
develop ────●──●──●──●──●──●──●──●──●──●──●──●──
            \   \      /     /         \
            feat1 feat2 ────/         hotfix
```

- Branches: `main`, `develop`, `feature/*`, `release/*`, `hotfix/*`.
- Best for: scheduled releases (mobile apps, regulated industries).
- Cost: heavy ceremony, long-lived branches → painful merges.

### 3.2 GitHub Flow (lightweight)

```
main ●────●────●────●────●  (always deployable)
      \    \    \    \
      f1   f2   f3   f4    (short branches, PR to main)
```

- One long-lived branch (`main`). PRs target `main`. Deploys after merge.
- Best for: web apps, SaaS, anything with continuous deployment.
- Requires: strong test suite + feature flags for in-flight features.

### 3.3 Trunk-Based Development

- Like GitHub Flow but branches live **hours, not days**.
- Continuous integration multiple times per day per dev.
- Pairs with **feature flags** because half-built features land in `main`.
- DORA elite teams almost universally use this.

### 3.4 Release Flow (Microsoft variant)

- Trunk-based + short-lived `release/*` branches for each ship train.
- Hotfixes cherry-picked from `main` to the release branch.
- Good middle ground for products with scheduled customer releases.

### 3.5 TaskFlow decision

TaskFlow is a SaaS web app with internal users. **Pick GitHub Flow + feature flags**, evolving to trunk-based as the team matures. Reasoning:
- Single deployable artifact → no need for release branches.
- Web users get fixes via redeploy in minutes.
- Feature flags (Topic 7) let us merge incomplete work safely.

---

## 4. Pull Requests Done Right

A PR is a **code review artifact** first and a merge mechanism second. Treat it that way.

### 4.1 What a good PR looks like
- **Small**: < 400 lines changed (changes < 200 lines find ~70% of defects; > 1000 lines find < 30%).
- **Single intent**: one bug fix OR one feature, not both.
- **Tested**: green CI + unit tests for new logic.
- **Documented**: PR description explains *why*, not *what*.
- **Linked**: references issue / work item ID.

### 4.2 Required PR description template

Create `.github/pull_request_template.md`:

```markdown
## Why
<!-- problem statement, link to issue -->

## What
<!-- short bullet list of changes -->

## How to verify
1. ...
2. ...

## Risks / rollback
<!-- what could break, how to roll back -->

## Checklist
- [ ] Unit tests added/updated
- [ ] Docs updated (if needed)
- [ ] No secrets committed
- [ ] Feature flag controls roll-out
```

### 4.3 Required reviewers and CODEOWNERS

`.github/CODEOWNERS`:
```
# Default owners
*           @taskflow/platform

# Frontend
/web/       @taskflow/frontend

# Pipelines & infra
/.github/   @taskflow/devops
/infra/     @taskflow/devops

# Security-sensitive
/auth/      @taskflow/security @taskflow/platform
```

GitHub will *auto-request* the right team based on changed paths. Combined with **required reviews from code owners** in branch protection, you can't merge into restricted code without the right approval.

### 4.4 Review checklist (for the reviewer)
1. Does the diff match the PR description?
2. Are tests meaningful (not just smoke)?
3. Is naming clear?
4. Any new dependencies — license OK? Maintained?
5. Any secrets / connection strings in diff?
6. Performance hot path touched? Allocation / DB-call cost?
7. Backwards compatible (API, DB schema)?

If any of these are "no" → request changes, don't approve.

---

## 5. Branch Protection (the safety net)

GitHub branch protection rules **enforce** what your team has agreed to. Without them, agreements rot.

### 5.1 Required settings for `main`
- **Require a pull request before merging** — no direct pushes.
- **Require approvals**: minimum 1, ideally 2 for shared services.
- **Dismiss stale reviews** when new commits are pushed.
- **Require review from Code Owners**.
- **Require status checks to pass** — list every required CI job by name.
- **Require branches to be up to date** before merge (forces re-test after rebase).
- **Require signed commits** (use GPG / SSH or `gh auth setup-git`).
- **Require linear history** (forbids merge commits — pairs with squash-merge).
- **Include administrators** — protections apply to admins too.
- **Restrict who can push** — empty list (everyone uses PRs).
- **Block force pushes**.
- **Block deletions**.

JSON for the GitHub API (see `PracticeProblemsSolutions/P3-branch-protection.json` later):
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["build", "test", "lint", "security-scan"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_signatures": true
}
```

### 5.2 Rulesets (newer, recommended)

GitHub Rulesets supersede branch protection rules. They:
- Support multiple overlapping rules (branch + tag rules).
- Are evaluated as a stack.
- Can be applied across an **entire org** (enterprise feature).

Prefer Rulesets for new setups; legacy projects can stick with branch protection.

---

## 6. GitHub vs Azure DevOps: When to Pick Which

Both exist. Both are owned by Microsoft. Both have CI, repos, boards. Differences matter.

| Capability | GitHub | Azure DevOps |
|---|---|---|
| **Repos** | Git only | Git + TFVC (legacy) |
| **CI/CD** | Actions (YAML, marketplace huge) | Pipelines (YAML + Classic UI) |
| **Boards** | Issues + Projects | Boards (richer — Epics, Sprints, queries) |
| **Test management** | Limited | Test Plans (manual + automated test cases) |
| **Artifacts** | Packages (npm, nuget, maven, docker) | Artifacts (npm, nuget, maven, pypi, universal) |
| **Wiki** | Repo-based | First-class wiki |
| **Audit log** | Enterprise plan | Built-in |
| **Pricing** | Per user, generous free tier | Per user, free for 5 users + unlimited stakeholders |
| **OSS friendliness** | First-class | Possible but uncommon |
| **AI** | Copilot, Code Scanning, Dependabot | Pipelines AI (Preview) |

### 6.1 Pick GitHub when…
- Project is OSS or partly public.
- You want a huge action marketplace.
- The team already lives on GitHub (UI familiarity).
- You're using GitHub Advanced Security (CodeQL, secret scanning, Dependabot).

### 6.2 Pick Azure DevOps when…
- Enterprise needs heavy test management (Test Plans).
- You need Boards that handle complex hierarchies and queries.
- Compliance demands audit / WIQL / advanced permissions.
- You're already in Microsoft enterprise (E5 / GCC) and stuck on AAD groups.

### 6.3 The "use both" pattern (common today)
- **Repos + CI** in GitHub.
- **Boards + Test Plans** in Azure DevOps (linked via Service Hooks / GitHub Connection).
- Best of both worlds when migrating gradually.

---

## 7. Repositories: Structure & Hygiene

### 7.1 Monorepo vs polyrepo

| | Monorepo | Polyrepo |
|---|---|---|
| Cross-cutting refactors | Easy | Hard (multi-PR dance) |
| CI complexity | High (need build graphs) | Low |
| Onboarding | High (huge tree) | Lower per repo |
| Tooling | Bazel, Nx, Turborepo | Vanilla |
| Versioning | One version for all | Per-repo |

For TaskFlow's size (one API, one web app, shared types) a **polyrepo** is fine. Reach for a monorepo only when cross-cutting changes are constant.

### 7.2 Minimum files every repo must have

```
.editorconfig            # consistent whitespace / line endings
.gitattributes           # text=auto, binary handling
.gitignore               # language-appropriate
.github/
  CODEOWNERS
  pull_request_template.md
  ISSUE_TEMPLATE/
    bug_report.md
    feature_request.md
  workflows/
    ci.yml
README.md                # what / why / how to run / how to deploy
LICENSE                  # required even for private repos
SECURITY.md              # how to report a vuln
CONTRIBUTING.md          # branch rules, commit style
CHANGELOG.md             # human-readable history
```

### 7.3 .gitattributes essentials

```
* text=auto eol=lf
*.sln text eol=crlf
*.png binary
*.jpg binary
*.pdf binary
```

Stops "the entire file changed" diffs caused by Windows/Unix line endings.

### 7.4 Commit message convention (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore`, `perf`, `revert`.

Example:
```
feat(auth): allow workspace-scoped API keys

Adds X-Workspace header validation in auth middleware. Keys
scoped to a workspace cannot read other workspaces' data.

Closes #482
```

Why? Tools like `semantic-release` generate version bumps + changelogs automatically from these. We'll wire that in Topic 2.

---

## 8. Identity: Connecting Pipelines to Azure (Securely)

Old pattern: service principal + client secret stored in a pipeline variable. **Don't.** Secrets leak, rotate badly, and grant infinite-lifetime access.

### 8.1 Workload Identity Federation (the modern way)

GitHub Actions and Azure Pipelines can present a short-lived **OIDC token** to Azure AD. Azure trusts that token and returns an access token — no secret stored anywhere.

```
[ GitHub workflow run ]
        │  OIDC id-token (1-hour, signed by GitHub)
        ▼
[ Azure AD federated identity credential ]
        │  azure access token (1-hour)
        ▼
[ az / Terraform / dotnet azure SDK calls ]
```

### 8.2 Setting it up (GitHub → Azure)

1. Create an Entra **App Registration** (or use a User-Assigned Managed Identity — preferred for prod).
2. Add a **Federated Credential** with:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:<org>/<repo>:environment:production`
   - Audience: `api://AzureADTokenExchange`
3. Grant the identity RBAC on target resources (e.g., `Contributor` on RG).
4. In the workflow:

```yaml
permissions:
  id-token: write   # required to mint the OIDC token
  contents: read

jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: az group list
```

No `client-secret` parameter. Notice `id-token: write` — without it, OIDC mint silently fails.

### 8.3 Setting it up (Azure DevOps → Azure)

Azure DevOps **Service Connection** of type *Azure Resource Manager* now supports **Workload Identity Federation** (GA since 2024):

1. Project Settings → Service Connections → New → Azure Resource Manager → **Workload Identity Federation (automatic)**.
2. Pick the subscription; Azure DevOps creates the App Reg + federation for you.
3. In YAML:
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: 'sc-taskflow-prod'
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: az group list
```

### 8.4 Subject claim patterns (lock down which workflow can deploy)

| Subject | Allows |
|---|---|
| `repo:org/repo:ref:refs/heads/main` | Only the main branch |
| `repo:org/repo:environment:production` | Only when targeting GH `production` environment |
| `repo:org/repo:pull_request` | Any PR (dangerous; never for prod) |
| `repo:org/repo:ref:refs/tags/v*` | Tag-triggered runs |

**Always** scope to environment or tag for production. A leaked workflow that runs in a fork should not be able to deploy.

---

## 9. Environments, Approvals, Secrets

### 9.1 GitHub Environments

`Settings → Environments → New`. An environment can carry:
- **Secrets** scoped to the environment (override repo-level).
- **Variables** scoped to the environment.
- **Required reviewers** — N humans must approve before the job runs.
- **Wait timer** — delay before deployment (cooling-off).
- **Deployment branches** — only specified branches can deploy.

Workflow:
```yaml
jobs:
  deploy-prod:
    environment:
      name: production
      url: https://taskflow.example.com
    runs-on: ubuntu-latest
    steps: [...]
```

When the job reaches `deploy-prod`, GitHub pauses, sends an approval notification, and only proceeds after approval. The deployment shows up in **Deployments** with URL + history.

### 9.2 Azure DevOps Environments

Same concept under Pipelines → Environments. Supports:
- Approvals (humans, groups, business-hours window).
- Checks (REST API call, Azure Function, ServiceNow ticket exists, branch control).
- Resources (Kubernetes, VMs) for traceable deployments.

### 9.3 Secrets handling — non-negotiables

- **Never** commit secrets. Use `git-secrets` / GitHub secret scanning (Topic 3).
- **Never** echo secrets in logs (GitHub masks env vars matching secret values; still — don't `cat` them).
- **Rotate** anything that was leaked. Don't "rotate it later."
- **Prefer OIDC** over long-lived PATs / service principal secrets.
- **Scope** secrets to environments, not the whole repo.
- For Azure resources, the secret should live in **Key Vault**, referenced by Function/App-Service settings — your pipeline never reads it.

---

## 10. Issues, Projects, Work Items

### 10.1 GitHub Issues + Projects (v2)
- Issues are *threads* with assignees, labels, milestones, linked PRs.
- Projects v2 = spreadsheet/board/roadmap over issues across repos.
- Custom fields (status, priority, sprint, estimate).
- Automation: when PR is merged, move card to Done.

### 10.2 Azure Boards
- Hierarchical: Epic → Feature → User Story → Task.
- Sprints with capacity planning.
- Query language (WIQL).
- Built-in burndown / velocity.

### 10.3 Connecting commits to work items
Mention the work item ID in the commit / PR:
- GitHub: `Closes #482` auto-closes issue on merge.
- Azure DevOps: `AB#1234` links a PR to a work item.

---

## 11. Self-Hosted vs Microsoft-Hosted Runners

| | Microsoft-hosted | Self-hosted |
|---|---|---|
| Setup | Zero | Install runner agent on VM/container |
| Cost | Free (limits) → paid minutes | You pay for VM, runner is free |
| Performance | Cold each run | Warm cache, fast |
| Network access | Public IP egress | Can be inside VNet (private resources) |
| Security | Microsoft-managed | You patch the OS |
| Best for | OSS, simple builds | Private resources, GPU, long builds |

**Use self-hosted runners when:**
- You need network access to private Azure resources (App Service in VNet, AKS cluster).
- Build is consistently > 10 min and you'd save real money.
- You require specific hardware (GPU, ARM, Windows-with-X-tooling).

**Security note:** never run self-hosted runners on a public repo without isolation. A malicious PR could run arbitrary code on your network. Use GitHub's [ephemeral runners with auto-scaling](https://docs.github.com/en/actions/hosting-your-own-runners) (e.g., actions-runner-controller on AKS) and **scoped to private repos only**.

---

## 12. Cost Model (so DevOps doesn't blindside finance)

### 12.1 GitHub Actions billing
- Free tier per plan (e.g., 2,000 min/month for Free, 50,000 for Enterprise).
- Public repos: free unlimited.
- Linux runner = 1× multiplier. Windows = 2×. macOS = 10×.
- Storage for artifacts: 500 MB to 50 GB depending on plan.

### 12.2 Azure DevOps billing
- 1 free Microsoft-hosted parallel job + 1,800 free minutes per org.
- Additional jobs: ~$40/month each.
- Self-hosted: 1 free job, then $15/month each.
- Test Plans / Artifacts have separate per-user pricing.

### 12.3 Optimisation levers (full deep-dive in Topic 3)
- **Cache dependencies** (NuGet, npm, pip).
- **Path filters** — don't run the whole pipeline if only `docs/` changed.
- **Matrix smartly** — don't fan out unless the matrix dimensions add value.
- **Self-host for the hot path** (e.g., the 30× daily nightly build).

---

## 13. Common Anti-Patterns (and the fix)

| Anti-pattern | Why it's bad | Fix |
|---|---|---|
| Long-lived feature branches | Painful merges; integration risk hidden | Branch lives < 3 days; merge to `main` behind a flag |
| "Manual deployment script no one runs" | Drift, single point of failure | Codify in pipeline; delete the script |
| Mixing app code + Terraform in one job | Slow, hard to debug | Separate workflows (Topic 2) |
| Direct push to `main` "just this once" | Bypasses CI, history isn't auditable | Branch protection with `enforce_admins` |
| Secrets in `.env` checked into repo | Permanent leak | Pre-commit hook + secret scanning + rotate |
| Pipeline approves itself (no env / human) | Compromised PR → prod | GitHub Environment with required reviewer |
| Self-hosted runner on public repo | Arbitrary code execution by strangers | Ephemeral, isolated, private-repo-only |
| Service principal client secret | Leaks, never rotated | OIDC federation |
| 800-line PR | Reviewers rubber-stamp | Hard cap; break the work down |
| One Git user for the team | No traceability | Per-user accounts + 2FA + signed commits |

---

## 14. TaskFlow Reference Setup (what we'll build over Phase 8)

By end of Phase 8 you will have, for TaskFlow:

- A polyrepo (`taskflow-api`, `taskflow-web`, `taskflow-infra`) with branch protection and CODEOWNERS.
- GitHub Actions CI: build, test, security scan, container image push to ACR — on every PR.
- GitHub Actions CD: OIDC → Azure → deploy to **dev** (auto), **staging** (auto with smoke tests), **prod** (manual approval + blue-green slot swap).
- Terraform modules in `taskflow-infra` provisioning everything from Phase 7 (Function Apps, APIM, Storage, Service Bus, Redis).
- Remote Terraform state in Azure Storage with state locking.
- Pipeline-generated test/coverage reports + App Insights dashboards + Action Group alerts.
- Defender for Cloud + GitHub Advanced Security wired in.

Topic 1 sets the **foundation** — repo hygiene, branching, identity, environments. Everything else is built on top of these.

---

## Further Reading

- [GitHub Docs — Branch protection rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository)
- [GitHub Docs — Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Microsoft Learn — Workload identity federation for Azure DevOps](https://learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure)
- [Conventional Commits 1.0](https://www.conventionalcommits.org/)
- [Google — DORA "Accelerate State of DevOps"](https://dora.dev/)
- [Atlassian — Comparing Git workflows](https://www.atlassian.com/git/tutorials/comparing-workflows)
