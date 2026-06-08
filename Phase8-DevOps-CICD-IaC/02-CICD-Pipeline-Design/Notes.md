# Topic 2: CI/CD Pipeline Design (Build & Release)

> **Goal:** Design and write production-grade CI and CD pipelines in **both GitHub Actions and Azure DevOps**, with clear separation between *build once* and *deploy many times*, the right gates, and proper artifact handling.

---

## 1. Mental Model: What CI and CD Actually Are

People say "CI/CD" as if it's one thing. It's three:

| | Definition | Trigger | Output |
|---|---|---|---|
| **CI — Continuous Integration** | Every commit is automatically built, tested, packaged | On PR / push | A versioned artifact + test report |
| **CD — Continuous Delivery** | Every artifact is automatically deployable to any env, but prod is gated | On artifact ready | A button you can press |
| **CD — Continuous Deployment** | Every passing artifact goes to prod automatically | On artifact ready | A live deployment |

The difference between Delivery and Deployment is **whether prod is automatic**. Most teams should aim for Delivery first; Deployment is the elite-DORA destination once tests + monitoring are mature.

### The cardinal rule: *build once, deploy many*

```
[Source] → Build → Test → Package → Artifact
                                       │
                                       ├── Deploy → Dev
                                       ├── Deploy → Staging   (same artifact)
                                       └── Deploy → Prod      (same artifact)
```

If you rebuild per environment, the binary in prod is **not** the binary you tested. Always pass a single immutable artifact through environments.

---

## 2. Anatomy of a Pipeline

Every pipeline has the same logical shape regardless of tool:

```
trigger → checkout → setup → restore → build → test → scan → package → publish → deploy
```

| Stage | What | Common tools |
|---|---|---|
| Trigger | When does it run? | push, PR, schedule, manual, repo dispatch |
| Checkout | Get source | `actions/checkout`, `checkout` task |
| Setup | Install runtime / SDK | `actions/setup-dotnet`, `UseDotNet@2` |
| Restore | Pull dependencies (with cache) | `dotnet restore`, npm/pip with cache |
| Build | Compile | `dotnet build -c Release --no-restore` |
| Test | Run unit/integration tests | `dotnet test`, jest, pytest |
| Scan | Static analysis, secrets, deps | CodeQL, Snyk, Trivy, gitleaks |
| Package | Create deployable artifact | `dotnet publish`, `docker build`, `zip` |
| Publish | Push to artifact store | `actions/upload-artifact`, ACR, Artifacts feed |
| Deploy | Push to env | Azure CLI, Bicep/Terraform, `webapps-deploy` |

---

## 3. Triggers (and how to avoid runaway pipelines)

### 3.1 GitHub Actions
```yaml
on:
  push:
    branches: [main]
    paths: ['src/**', '.github/workflows/ci.yml']
  pull_request:
    branches: [main]
    paths-ignore: ['docs/**', '**.md']
  schedule:
    - cron: '0 4 * * *'   # nightly 04:00 UTC
  workflow_dispatch:
    inputs:
      target_env:
        description: 'Environment'
        required: true
        type: choice
        options: [dev, staging, prod]
```

### 3.2 Azure Pipelines
```yaml
trigger:
  branches:
    include: [main]
  paths:
    include: [src/*]
    exclude: [docs/*, '**/*.md']

pr:
  branches:
    include: [main]

schedules:
  - cron: '0 4 * * *'
    displayName: Nightly
    branches:
      include: [main]
    always: false   # only if changes since last run
```

### 3.3 Anti-patterns to avoid
- **Cyclic triggers** — workflow pushes a commit that retriggers itself. Fix: skip with `[skip ci]` or `[ci skip]` in commit msg, or check the actor.
- **No path filters** — every doc typo runs a 12-minute build. Fix: `paths` / `paths-ignore`.
- **Manual deploy job in `on: push`** — accidentally clicking "Re-run all jobs" reships prod. Fix: deploy in separate workflow triggered by `workflow_dispatch` or environment.

---

## 4. GitHub Actions: Production CI Workflow

A complete CI workflow for a .NET 8 API:

```yaml
name: ci

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true       # supersede old runs on the same branch

permissions:
  contents: read
  id-token: write                # needed only if we push to ACR via OIDC

env:
  DOTNET_VERSION: '8.0.x'
  BUILD_CONFIGURATION: Release

jobs:
  build-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # full history (needed for GitVersion / blame)

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      - name: Cache NuGet
        uses: actions/cache@v4
        with:
          path: ~/.nuget/packages
          key: nuget-${{ runner.os }}-${{ hashFiles('**/*.csproj', '**/packages.lock.json') }}
          restore-keys: |
            nuget-${{ runner.os }}-

      - name: Restore
        run: dotnet restore --locked-mode

      - name: Build
        run: dotnet build -c ${{ env.BUILD_CONFIGURATION }} --no-restore

      - name: Test (with coverage)
        run: |
          dotnet test \
            --no-build \
            -c ${{ env.BUILD_CONFIGURATION }} \
            --logger "trx;LogFileName=test-results.trx" \
            --collect:"XPlat Code Coverage" \
            --results-directory ./TestResults

      - name: Publish test results
        if: always()
        uses: dorny/test-reporter@v1
        with:
          name: dotnet-tests
          path: TestResults/**/*.trx
          reporter: dotnet-trx

      - name: Upload coverage
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: TestResults/**/coverage.cobertura.xml

  security:
    runs-on: ubuntu-latest
    needs: build-test
    permissions:
      security-events: write    # CodeQL needs this
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with: { languages: csharp }
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3

  package:
    runs-on: ubuntu-latest
    needs: [build-test, security]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with: { dotnet-version: '8.0.x' }

      - name: Publish
        run: |
          dotnet publish src/TaskFlow.Api/TaskFlow.Api.csproj \
            -c Release \
            -o ./publish \
            /p:Version=${{ github.run_number }}.0.0

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: taskflow-api
          path: ./publish
          retention-days: 30
```

### 4.1 Key choices explained
- **`concurrency` + `cancel-in-progress`** — when you push twice to the same branch, the older run is cancelled. Saves minutes.
- **`--locked-mode`** — fails if `packages.lock.json` is out of date. Reproducible restore.
- **Separate `security` job** — runs in parallel with packaging? No, here it gates packaging. Choose based on whether you want package to be blocked by SAST.
- **Versioning via `run_number`** — simple monotonic version. For semver use GitVersion or [git-cliff](https://git-cliff.org/).
- **Artifact retention** — explicit `retention-days` overrides org default (which may be too short or too long).

---

## 5. Azure Pipelines: Equivalent CI YAML

```yaml
trigger:
  branches: { include: [main] }
pr:
  branches: { include: [main] }

variables:
  buildConfiguration: 'Release'
  dotnetVersion: '8.0.x'

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: build_test
    displayName: Build & Test
    jobs:
      - job: build_test
        timeoutInMinutes: 15
        steps:
          - checkout: self
            fetchDepth: 0

          - task: UseDotNet@2
            inputs:
              version: $(dotnetVersion)

          - task: Cache@2
            inputs:
              key: 'nuget | "$(Agent.OS)" | **/*.csproj,**/packages.lock.json'
              path: '$(NUGET_PACKAGES)'
            env:
              NUGET_PACKAGES: $(Pipeline.Workspace)/.nuget/packages

          - script: dotnet restore --locked-mode
            displayName: Restore

          - script: dotnet build -c $(buildConfiguration) --no-restore
            displayName: Build

          - script: |
              dotnet test --no-build -c $(buildConfiguration) \
                --logger trx \
                --collect:"XPlat Code Coverage" \
                --results-directory $(Agent.TempDirectory)/TestResults
            displayName: Test

          - task: PublishTestResults@2
            condition: always()
            inputs:
              testResultsFormat: VSTest
              testResultsFiles: '**/*.trx'
              searchFolder: $(Agent.TempDirectory)/TestResults
              failTaskOnFailedTests: true

          - task: PublishCodeCoverageResults@2
            condition: always()
            inputs:
              summaryFileLocation: '$(Agent.TempDirectory)/TestResults/**/coverage.cobertura.xml'

  - stage: package
    dependsOn: build_test
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: pack
        steps:
          - task: UseDotNet@2
            inputs: { version: '8.0.x' }
          - script: |
              dotnet publish src/TaskFlow.Api/TaskFlow.Api.csproj \
                -c Release -o $(Build.ArtifactStagingDirectory)/publish \
                /p:Version=$(Build.BuildNumber)
            displayName: Publish
          - publish: $(Build.ArtifactStagingDirectory)/publish
            artifact: taskflow-api
```

---

## 6. The Release / CD Pipeline

CD should be **a separate workflow / pipeline** from CI. Why:
- CI runs every PR; CD runs only on releases. Different cadence.
- CI is read-only on Azure (or no Azure at all); CD needs `Contributor`. Different identity, smaller blast radius.
- Re-deploying an existing artifact should not re-build it.

### 6.1 GitHub Actions: multi-environment CD

```yaml
name: cd

on:
  workflow_run:
    workflows: [ci]
    types: [completed]
    branches: [main]

permissions:
  id-token: write
  contents: read
  actions: read

jobs:
  deploy-dev:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    environment:
      name: dev
      url: https://taskflow-dev.azurewebsites.net
    steps:
      - name: Download artifact from CI
        uses: actions/download-artifact@v4
        with:
          name: taskflow-api
          path: ./publish
          run-id: ${{ github.event.workflow_run.id }}
          github-token: ${{ secrets.GITHUB_TOKEN }}

      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - uses: azure/webapps-deploy@v3
        with:
          app-name: app-taskflow-dev
          package: ./publish

  deploy-staging:
    needs: deploy-dev
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://taskflow-staging.azurewebsites.net
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: taskflow-api
          path: ./publish
          run-id: ${{ github.event.workflow_run.id }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - uses: azure/webapps-deploy@v3
        with:
          app-name: app-taskflow-staging
          package: ./publish
      - name: Smoke test
        run: |
          curl -fsSL --retry 5 https://taskflow-staging.azurewebsites.net/health \
            | tee /tmp/smoke.json
          grep -q '"status":"Healthy"' /tmp/smoke.json

  deploy-prod:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production              # has required reviewer
      url: https://taskflow.example.com
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: taskflow-api
          path: ./publish
          run-id: ${{ github.event.workflow_run.id }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - name: Deploy to staging slot
        uses: azure/webapps-deploy@v3
        with:
          app-name: app-taskflow-prod
          slot-name: staging-slot
          package: ./publish
      - name: Slot swap
        run: |
          az webapp deployment slot swap \
            -g rg-taskflow-prod \
            -n app-taskflow-prod \
            --slot staging-slot \
            --target-slot production
```

### 6.2 Azure Pipelines: multi-stage CD

```yaml
trigger: none                 # CD pipeline; triggered by CI publishing artifact
resources:
  pipelines:
    - pipeline: ci
      source: TaskFlow-CI
      trigger:
        branches: [main]

stages:
  - stage: dev
    jobs:
      - deployment: deploy_dev
        environment: dev
        strategy:
          runOnce:
            deploy:
              steps:
                - download: ci
                  artifact: taskflow-api
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'sc-taskflow-dev'
                    appType: webApp
                    appName: app-taskflow-dev
                    package: $(Pipeline.Workspace)/ci/taskflow-api

  - stage: staging
    dependsOn: dev
    jobs:
      - deployment: deploy_staging
        environment: staging
        strategy:
          runOnce:
            deploy:
              steps:
                - download: ci
                  artifact: taskflow-api
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'sc-taskflow-staging'
                    appType: webApp
                    appName: app-taskflow-staging
                    package: $(Pipeline.Workspace)/ci/taskflow-api
                - script: |
                    curl -fsSL --retry 5 \
                      https://taskflow-staging.azurewebsites.net/health

  - stage: prod
    dependsOn: staging
    jobs:
      - deployment: deploy_prod
        environment: production       # human approval gate here
        strategy:
          runOnce:
            deploy:
              steps:
                - download: ci
                  artifact: taskflow-api
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'sc-taskflow-prod'
                    appType: webApp
                    appName: app-taskflow-prod
                    deployToSlotOrASE: true
                    resourceGroupName: rg-taskflow-prod
                    slotName: staging-slot
                    package: $(Pipeline.Workspace)/ci/taskflow-api
                - script: |
                    az webapp deployment slot swap \
                      -g rg-taskflow-prod \
                      -n app-taskflow-prod \
                      --slot staging-slot \
                      --target-slot production
```

`environment: production` in Azure DevOps carries the **Approvals & Checks** (humans, business hours, REST checks).

---

## 7. Artifact Storage

| Where | What for |
|---|---|
| **GH Actions artifacts** | Short-lived (≤90 days) intra-pipeline handoff |
| **Azure Pipelines artifacts** | Same idea on ADO |
| **Container registry (ACR / GHCR)** | OCI images; long-lived, versioned, tag-immutable |
| **NuGet / npm feed** (ADO Artifacts, GitHub Packages) | Internal libraries |
| **Azure Storage** | Pinned long-term archives (compliance) |
| **GitHub Releases** | Public binaries with changelog |

### Artifact promotion model
Instead of rebuilding, promote by **re-tagging** in the registry:
```bash
az acr import \
  --name acrtaskflowprod \
  --source acrtaskflowdev.azurecr.io/taskflow-api:1.2.3 \
  --image taskflow-api:1.2.3
```
The blob is copied once; tags are cheap. Promotion = "trust this image in this registry".

---

## 8. Versioning Strategy

Three common approaches:

### 8.1 Build number versioning
`Version = $(github.run_number).0.0`. Simple, monotonic, no semver meaning. OK for internal apps.

### 8.2 GitVersion (semantic from branches)
```yaml
- uses: gittools/actions/gitversion/setup@v3
  with: { versionSpec: '6.x' }
- id: gitversion
  uses: gittools/actions/gitversion/execute@v3
```
GitVersion calculates `1.4.0-feature.3` from branch + tags. Pairs well with Git Flow.

### 8.3 Tag-driven release pipeline
- Push commits to `main` with conventional commits.
- A release workflow runs on `git tag v1.2.0`, builds, publishes with that exact version.
- Use [semantic-release](https://semantic-release.gitbook.io/) or [release-please](https://github.com/googleapis/release-please) to automate tag creation.

Pick #3 for TaskFlow — the release notes write themselves from commits.

---

## 9. Reusable Workflows / Templates

**Don't copy-paste pipelines across repos.** That's how 12 different security scans drift apart.

### 9.1 GitHub Actions — Reusable workflow
`taskflow/.github/workflows/build-dotnet.yml`:
```yaml
on:
  workflow_call:
    inputs:
      project: { required: true, type: string }
      dotnet-version: { default: '8.0.x', type: string }
    outputs:
      artifact-name:
        value: ${{ jobs.build.outputs.artifact-name }}
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact-name: ${{ steps.set.outputs.name }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: ${{ inputs.dotnet-version }} }
      - run: dotnet build ${{ inputs.project }} -c Release
      - id: set
        run: echo "name=build-output" >> "$GITHUB_OUTPUT"
```

Consumer:
```yaml
jobs:
  build:
    uses: taskflow/.github/workflows/build-dotnet.yml@v1
    with:
      project: src/TaskFlow.Api/TaskFlow.Api.csproj
```

### 9.2 Azure DevOps — Template
`templates/build-dotnet.yml`:
```yaml
parameters:
  - name: project
    type: string
  - name: dotnetVersion
    type: string
    default: '8.0.x'

steps:
  - task: UseDotNet@2
    inputs: { version: ${{ parameters.dotnetVersion }} }
  - script: dotnet build ${{ parameters.project }} -c Release
```

Consumer:
```yaml
steps:
  - template: templates/build-dotnet.yml
    parameters:
      project: src/TaskFlow.Api/TaskFlow.Api.csproj
```

---

## 10. Composite Actions vs Reusable Workflows (GitHub)

Both reduce duplication, but they serve different needs:

| | Composite action | Reusable workflow |
|---|---|---|
| Granularity | Few steps | Whole jobs |
| Inputs | `inputs:` | `inputs:` + `secrets:` + `outputs:` |
| Concurrency | Inherits caller | Has its own |
| Where it lives | Action in a repo | `.github/workflows/` |
| Use for | "Setup .NET + restore + cache" combo | "Standard build pipeline" |

Pick composite for **step sequences**, reusable workflow for **full pipelines**.

---

## 11. Matrix Builds

Use when you genuinely need to test against multiple targets:

```yaml
strategy:
  fail-fast: false
  matrix:
    os: [ubuntu-latest, windows-latest]
    dotnet: ['7.0.x', '8.0.x']
    exclude:
      - { os: windows-latest, dotnet: '7.0.x' }
```

### Pitfalls
- `fail-fast: true` cancels siblings on first failure — fine for fast-feedback, bad for collecting all failures.
- Matrix bloats minutes. Question whether you really need every combination.
- For containers, prefer multi-arch Docker builds (`docker buildx --platform linux/amd64,linux/arm64`) over OS matrix.

---

## 12. Quality Gates (block bad code)

These should *fail the pipeline*, not just warn:

| Gate | Tool |
|---|---|
| Unit test pass rate | `dotnet test` exit code |
| Coverage threshold | ReportGenerator + threshold check |
| Static analysis | CodeQL, SonarCloud, .NET analyzers |
| Secret scanning | GitHub secret scanning, gitleaks |
| Dependency CVEs | Dependabot, `dotnet list package --vulnerable`, Snyk |
| Container image CVEs | Trivy, Defender for Cloud |
| Style / lint | `dotnet format --verify-no-changes` |
| Open API drift | Spectral, `swagger-cli validate` |

### Coverage threshold example
```yaml
- name: Coverage threshold
  run: |
    pct=$(coverage-tool compute --target coverage.xml)
    awk -v v="$pct" 'BEGIN { if (v < 80) { print "FAIL "v"%"; exit 1 } else { print "OK "v"%" } }'
```

Don't add gates you'll later disable. Start at a low threshold and raise it.

---

## 13. Database Migrations in Pipelines

Two camps:

### 13.1 Apply at deploy time
- Pipeline runs `dotnet ef database update` before swapping slots.
- Risk: forward-only; rolling back the app does NOT roll back the schema.
- Mitigate with **expand/contract**: deploy schema change → deploy code that handles both shapes → cleanup later.

### 13.2 Apply at app startup
- App auto-migrates on boot.
- Multiple instances → race. Use a lock table or a leader-only step.
- Avoid in production. Acceptable for dev/local.

For TaskFlow, do **#1 with expand/contract**, gated by an approval if migration is destructive.

---

## 14. Pipeline Security (own the supply chain)

Six rules:

1. **Pin actions / tasks by SHA**, not by floating tag.
   ```yaml
   uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
   ```
   A tag can be moved by a compromised maintainer. A SHA cannot.

2. **Set `permissions:` to least-privilege** at the workflow root.
   ```yaml
   permissions:
     contents: read
     id-token: write
   ```

3. **Pull-request workflows from forks** run with restricted token. Don't `pull_request_target` unless you really know what you're doing.

4. **No `if: success()` skipped security jobs.** Make them required checks.

5. **No secrets in environment variables of `if` expressions** — they don't get masked.

6. **Sign artifacts** with [sigstore/cosign](https://docs.sigstore.dev/) so consumers can verify they came from your pipeline.

---

## 15. TaskFlow CI/CD Reference Topology

```
GitHub Repo
   │
   ├── .github/workflows/
   │     ├── ci.yml             (build, test, scan, publish artifact)
   │     ├── cd.yml             (dev → staging → prod, gated by env)
   │     ├── infra-plan.yml     (Terraform plan on PR — Topic 4)
   │     └── infra-apply.yml    (Terraform apply on merge to main — Topic 5)
   │
   └── infra/        (Terraform — Topics 4–5)

Azure
   ├── id-taskflow-ci             (Reader on all RGs — for tests)
   ├── id-taskflow-cd-dev         (Contributor on rg-taskflow-dev)
   ├── id-taskflow-cd-staging     (Contributor on rg-taskflow-staging)
   ├── id-taskflow-cd-prod        (Contributor on rg-taskflow-prod)
   └── acrtaskflow                (single ACR; tags promoted across envs)
```

Each identity has **only** the env it needs. Prod identity is federated only to the `production` GitHub environment, which requires human approval.

---

## 16. Anti-Patterns

| Anti-pattern | Why it bites | Fix |
|---|---|---|
| Build per environment | Prod isn't what you tested | Build once, deploy many |
| `latest` tag in deploys | Non-deterministic | Pin to SHA or version |
| Floating action tags (`@v4`) | Supply-chain risk | Pin to SHA |
| Tests skip on `main` only | "Just merge it, fix later" | Required check on `main` too |
| Single mega-workflow | Slow, hard to read | Split CI / CD / infra |
| Pipeline-stored connection string | Secret leak | OIDC + Key Vault references |
| No timeout | Hung job burns minutes | `timeout-minutes` on every job |
| No artifact retention policy | Storage cost explodes | Set `retention-days` |
| Manual portal changes after deploy | IaC drift | Lock with Azure Policy + alerts |

---

## Further Reading

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [Azure Pipelines YAML schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema)
- [Reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [DORA — Continuous Delivery](https://dora.dev/research/2014/2014-continuous-delivery/)
- [SLSA — Supply-chain Levels for Software Artifacts](https://slsa.dev/)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
