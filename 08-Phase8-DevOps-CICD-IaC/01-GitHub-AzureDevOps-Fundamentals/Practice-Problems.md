# Topic 1 — Practice Problems

> Solutions go in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). Each problem has **Goal**, **Tasks**, **Deliverables**, and **Look-fors** the grader uses.

---

## P1 — Bootstrap a Production-Grade Repo Skeleton

**Goal:** Stand up a brand-new repo with all hygiene files, ready for collaboration.

**Tasks**
1. Create a private GitHub repo `taskflow-api` (or simulate locally with `git init`).
2. Add **all** of these files with sensible content:
   - `README.md`, `LICENSE` (MIT or Apache 2.0), `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`
   - `.editorconfig`, `.gitattributes`, `.gitignore` (use `dotnet new gitignore`)
   - `.github/CODEOWNERS`
   - `.github/pull_request_template.md`
   - `.github/ISSUE_TEMPLATE/bug_report.md` and `feature_request.md`
3. Make the first commit conventional-commits style: `chore(repo): initial scaffold`.
4. Tag it `v0.0.0`.

**Deliverables**
- `P1-repo-skeleton/` containing the full tree above.
- Output of `git log --oneline --decorate` showing the conventional commit and tag.

**Look-fors**
- [ ] All files present and non-empty (no `TODO` placeholders).
- [ ] `.gitattributes` enforces LF line endings.
- [ ] `CODEOWNERS` uses paths, not wildcards everywhere.
- [ ] PR template has Why/What/How-to-verify/Risks sections.
- [ ] Commit message follows Conventional Commits.

---

## P2 — Pick & Justify a Branching Strategy

**Goal:** Make an engineering decision with evidence.

**Tasks**
1. Read the Phase 7 TaskFlow architecture (or use the assumptions in `Notes.md §14`).
2. Write `P2-branching-decision.md` answering:
   - Which strategy (Git Flow / GitHub Flow / Trunk / Release Flow)?
   - Why — at least three concrete reasons tied to TaskFlow.
   - How long can a feature branch live before it's "too old"?
   - How do you handle in-flight features at release time?
   - Hotfix procedure (step-by-step).
3. Draw a Mermaid diagram of one full feature lifecycle (branch → PR → merge → deploy → hotfix scenario).

**Deliverables**
- `P2-branching-decision.md` (~600–800 words + Mermaid).

**Look-fors**
- [ ] Decision is explicit, not "it depends".
- [ ] Reasoning references DORA metrics or team realities.
- [ ] Hotfix flow does not require a parallel long-lived branch unless justified.
- [ ] Mermaid diagram renders correctly.

---

## P3 — Lock Down `main` with Branch Protection

**Goal:** Codify the safety net so humans can't bypass it.

**Tasks**
1. In your repo settings (or as JSON for the GitHub API), define branch protection for `main`:
   - Required PR with ≥ 1 approval.
   - Required CODEOWNER review.
   - Required status checks: `build`, `test`, `lint`.
   - Required signed commits.
   - Required linear history.
   - Dismiss stale reviews on new commits.
   - Block force pushes & deletions.
   - Apply to admins.
2. Express the configuration as `P3-branch-protection.json` (matches the PUT `/repos/{owner}/{repo}/branches/{branch}/protection` payload).
3. Document a `gh` CLI command that applies it (one-liner).

**Deliverables**
- `P3-branch-protection.json`
- `P3-apply.sh` with the `gh api` call.

**Look-fors**
- [ ] JSON validates against the GitHub schema.
- [ ] Includes `enforce_admins: true`.
- [ ] Status check list matches your actual CI job names (not generic).
- [ ] Apply script is idempotent (re-running is safe).

---

## P4 — OIDC Federation: Pipeline → Azure (No Secrets)

**Goal:** Authenticate a GitHub workflow to Azure without storing any client secret.

**Tasks**
1. Create (or simulate) a User-Assigned Managed Identity `id-taskflow-cicd-dev`.
2. Add a **federated credential** scoped to the `production` GitHub environment of `org/taskflow-api`.
3. Grant the identity `Contributor` on a resource group `rg-taskflow-dev`.
4. Write `P4-deploy.yml` — a GitHub Actions workflow that:
   - Runs only on push to `main`.
   - Uses the `production` environment.
   - Acquires an OIDC token (`id-token: write`).
   - Logs into Azure via `azure/login@v2`.
   - Runs `az group show` to prove the connection works.
5. Document the exact CLI to create the federated credential (`az identity federated-credential create ...`).

**Deliverables**
- `P4-create-federation.sh`
- `P4-deploy.yml`

**Look-fors**
- [ ] No `client-secret` anywhere.
- [ ] `permissions: id-token: write` is set at job or workflow level.
- [ ] Federated credential subject pins to environment OR branch, not `pull_request`.
- [ ] Identity has least-privilege role (no `Owner` / `User Access Administrator`).

---

## P5 — Pull Request Workflow Walk-Through

**Goal:** Demonstrate the full PR lifecycle, including a forced "bad" review cycle.

**Tasks**
1. Open a feature branch `feature/p5-greeting`.
2. Make a small intentional bug (off-by-one, wrong status code — your choice).
3. Open a PR; assign yourself as reviewer.
4. As reviewer, leave at least three comments: one nit (style), one suggestion (refactor), one blocker (the bug). Use the GitHub "Request changes" button.
5. As author, address all three; push a fixup commit.
6. As reviewer, re-review and approve.
7. Squash-merge with a Conventional Commit message.
8. Screenshot (or copy as markdown) the PR conversation.

**Deliverables**
- `P5-pr-walkthrough.md` containing the conversation transcript + final merged commit hash.

**Look-fors**
- [ ] Reviewer comments are specific (line-anchored), not "please fix this".
- [ ] At least one "Request changes" cycle.
- [ ] Final merge is a single squashed commit on `main`.
- [ ] PR description explains *why*, not just *what*.

---

## P6 — Repo Decision: Mono vs Poly

**Goal:** Defend an architecture choice with numbers.

**Tasks**
1. Inventory TaskFlow's components (API, web, infra, shared types).
2. For both approaches (mono / poly), list:
   - Build pipeline complexity.
   - Onboarding cost (where does a new dev `git clone`?).
   - Cross-cutting refactor cost (e.g., renaming a DTO used in both API and web).
   - Versioning strategy.
   - CI minute cost (rough estimate based on Phase 7 pipelines).
3. Pick one. Write a one-page recommendation.

**Deliverables**
- `P6-mono-vs-poly.md`

**Look-fors**
- [ ] Estimates are at least loosely sourced (e.g., "~3 min build × 30 PRs/week").
- [ ] Recommendation is concrete (not "we should consider …").
- [ ] Lists conditions under which you'd revisit the decision.

---

## P7 (Stretch) — Self-Hosted Runner on Azure

**Goal:** Run a private-network build using a self-hosted runner inside an Azure VNet.

**Tasks**
1. Provision an Ubuntu VM in a VNet that has private connectivity to `rg-taskflow-dev`.
2. Install GitHub Actions runner; register it scoped to your repo with a label `private-vnet`.
3. Configure it as **ephemeral** (single-use job, then de-registers).
4. Write `P7-private-build.yml` — `runs-on: [self-hosted, private-vnet]` that calls a private endpoint (e.g., Function App with IP restriction allowing only the VNet).

**Deliverables**
- `P7-runner-setup.sh`
- `P7-private-build.yml`
- 10-line `P7-notes.md` covering: how you'd auto-scale, why ephemeral matters, what to do for OS patching.

**Look-fors**
- [ ] Runner is ephemeral.
- [ ] Runner is scoped to a single repo (not org-wide).
- [ ] Notes cover patch / scale operational concerns.

---

## Submission

Tell me **"check P1"** (or any range, e.g. "check P1-P4") for graded review.
