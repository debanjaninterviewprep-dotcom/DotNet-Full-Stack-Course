# Topic 2 — Practice Problems

> Solutions go in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). Each problem has **Goal**, **Tasks**, **Deliverables**, **Look-fors**.

---

## P1 — Author a Production CI Workflow (GitHub Actions)

**Goal:** Write a `ci.yml` that any TaskFlow .NET service can copy and run.

**Tasks**
1. Trigger on push to `main` and on PR to `main`. Add path filters (only run on `src/**` or workflow file changes).
2. Use `concurrency` with `cancel-in-progress` keyed on `ref`.
3. Set workflow-level `permissions:` to least-privilege.
4. Steps:
   - Checkout (`fetch-depth: 0`).
   - Setup .NET 8.
   - Cache NuGet keyed on csproj + lockfile.
   - Restore with `--locked-mode`.
   - Build `Release`.
   - Test with TRX logger + coverage collector.
   - Publish test results (use `dorny/test-reporter`).
   - Upload coverage as artifact.
5. Add a second job `package` that only runs on push to `main` and:
   - Publishes the app to `./publish`.
   - Stamps version `${{ github.run_number }}.0.0`.
   - Uploads as artifact `taskflow-api` with 30-day retention.

**Deliverables**
- `P1-ci.yml`.

**Look-fors**
- [ ] Concurrency cancels superseded runs.
- [ ] `permissions:` set explicitly.
- [ ] All actions pinned by SHA (not floating tag).
- [ ] Coverage upload happens even on test failure (`if: always()`).
- [ ] Package job conditional on push to main.

---

## P2 — CD Workflow with Three Environments

**Goal:** Promote one artifact through `dev → staging → prod` with the right gates.

**Tasks**
1. Trigger on `workflow_run` completion of `ci` on `main`.
2. Three sequential jobs: `deploy-dev`, `deploy-staging`, `deploy-prod`.
3. Each job:
   - Downloads the artifact from the CI run.
   - Logs into Azure via OIDC (different `vars.AZURE_CLIENT_ID` per env).
   - Uses `azure/webapps-deploy@v3`.
4. After staging, run a `curl /health` smoke test that fails the job if not healthy.
5. Prod deploys to **staging slot**, then swaps. The `production` GitHub environment must require manual approval.

**Deliverables**
- `P2-cd.yml`.

**Look-fors**
- [ ] Single artifact reused across all three deploys (no rebuild).
- [ ] Smoke test fails the pipeline on non-200.
- [ ] Prod uses slot swap, not direct deploy.
- [ ] `id-token: write` set.

---

## P3 — Reusable Workflow

**Goal:** Factor out the "build .NET service" pattern so all TaskFlow services share it.

**Tasks**
1. Create `P3-build-dotnet.yml` as a `workflow_call`:
   - Inputs: `project` (path), `dotnet-version` (default 8.0.x), `configuration` (default Release).
   - Outputs: `artifact-name`.
2. Write `P3-consumer.yml` that calls it for both `src/TaskFlow.Api/TaskFlow.Api.csproj` and `src/TaskFlow.Worker/TaskFlow.Worker.csproj` in a matrix.
3. Ensure the consumer pins to a tag, not `@main`.

**Deliverables**
- `P3-build-dotnet.yml`
- `P3-consumer.yml`

**Look-fors**
- [ ] Inputs and outputs declared with `type:`.
- [ ] Consumer uses `uses: ./.github/workflows/...` or `org/repo/...@v1`.
- [ ] Matrix produces one artifact per service.

---

## P4 — Equivalent Azure DevOps Pipeline

**Goal:** Build the same CI in Azure Pipelines YAML.

**Tasks**
1. Write `P4-azure-pipelines.yml`:
   - Trigger on `main` and PRs to `main`.
   - Build, test, coverage (Cobertura), publish artifact.
   - Cache NuGet via `Cache@2`.
2. Add a `stages` section: `build_test` (always) → `package` (only on `main`).
3. Use a template `templates/dotnet-build.yml` with `parameters.project`.

**Deliverables**
- `P4-azure-pipelines.yml`
- `P4-templates/dotnet-build.yml`

**Look-fors**
- [ ] Test results published with `failTaskOnFailedTests: true`.
- [ ] Cache key includes lockfile.
- [ ] Template parameter is typed.

---

## P5 — Artifact Promotion via ACR

**Goal:** Promote a container image across environments using tag copy, not rebuild.

**Tasks**
1. Build & push `taskflow-api:${commit_sha}` to `acrtaskflowdev`.
2. After staging tests pass, write `P5-promote.sh` that:
   - Uses `az acr import` to copy the image into `acrtaskflowprod` under the same tag.
   - Verifies the digest matches between source and destination.
3. Document the **digest pinning** approach: deploy uses `acrtaskflowprod.azurecr.io/taskflow-api@sha256:...` instead of a tag.

**Deliverables**
- `P5-promote.sh`
- `P5-deploy-pinned.yml` (uses the digest, not the tag).

**Look-fors**
- [ ] Promotion is a copy, not a re-push.
- [ ] Digest check fails the script if mismatched.
- [ ] Deployment references digest.

---

## P6 — Quality Gates

**Goal:** Add at least four blocking gates to your CI.

**Tasks**
1. Coverage gate (≥ 70%).
2. `dotnet format --verify-no-changes`.
3. `dotnet list package --vulnerable --include-transitive` — fail on any vulnerability.
4. CodeQL analysis.

For each gate, the failure should:
- Fail the workflow.
- Be marked as a **required status check** in branch protection.

**Deliverables**
- Updated `P6-ci.yml`.
- `P6-required-checks.md` listing the GitHub status check names to require.

**Look-fors**
- [ ] All four gates non-bypassable.
- [ ] Coverage threshold tuned to a realistic starting value.
- [ ] Vulnerable-package check fails on output, not just prints it.

---

## P7 (Stretch) — Tag-Driven Release with Auto Notes

**Goal:** Push a Conventional Commits message → auto-tag → auto-release → auto-deploy.

**Tasks**
1. Install `release-please-action` in a workflow `release.yml`.
2. On push to `main`, it opens / updates a "release PR" with version bump + CHANGELOG.
3. On merge of that PR, it creates a Git tag and a GitHub Release.
4. The CI/CD workflow uses the tag as the artifact version.

**Deliverables**
- `P7-release.yml`
- `P7-release-please-config.json`
- `P7-demo-commits.md` — three example commit messages that produce a minor bump.

**Look-fors**
- [ ] Versioning derived from commit types (`feat:` = minor, `fix:` = patch).
- [ ] CHANGELOG generated automatically.
- [ ] Artifact version equals the Git tag.

---

## Submission

Tell me **"check P1"** (or a range) for graded review.
