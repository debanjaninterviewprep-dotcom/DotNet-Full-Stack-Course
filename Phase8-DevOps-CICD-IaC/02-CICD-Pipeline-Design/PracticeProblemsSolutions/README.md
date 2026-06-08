# Topic 2 — Solutions Workspace

Drop your answers per [Practice-Problems.md](../Practice-Problems.md). Reference skeletons below — extend before submitting.

## Layout

```
PracticeProblemsSolutions/
├── README.md
├── P1-ci.yml
├── P2-cd.yml
├── P3-build-dotnet.yml
├── P3-consumer.yml
├── P4-azure-pipelines.yml
├── P4-templates/
│   └── dotnet-build.yml
├── P5-promote.sh
├── P5-deploy-pinned.yml
├── P6-ci.yml
├── P6-required-checks.md
├── P7-release.yml
├── P7-release-please-config.json
└── P7-demo-commits.md
```

---

## Starter: `P1-ci.yml`

```yaml
name: ci

on:
  push:
    branches: [main]
    paths: ['src/**', '.github/workflows/ci.yml']
  pull_request:
    branches: [main]
    paths: ['src/**', '.github/workflows/ci.yml']

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

env:
  DOTNET_VERSION: '8.0.x'

jobs:
  build-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
        with: { fetch-depth: 0 }
      - uses: actions/setup-dotnet@4d6c8fcf3c8f7a60068d26b594648e99df24cee3   # v4.0.0
        with: { dotnet-version: ${{ env.DOTNET_VERSION }} }
      - uses: actions/cache@13aacd865c20de90d75de3b17ebe84f7a17d57d2   # v4.0.0
        with:
          path: ~/.nuget/packages
          key: nuget-${{ runner.os }}-${{ hashFiles('**/*.csproj','**/packages.lock.json') }}
          restore-keys: nuget-${{ runner.os }}-
      - run: dotnet restore --locked-mode
      - run: dotnet build -c Release --no-restore
      - run: |
          dotnet test --no-build -c Release \
            --logger "trx;LogFileName=test-results.trx" \
            --collect:"XPlat Code Coverage" \
            --results-directory ./TestResults
      - if: always()
        uses: dorny/test-reporter@v1
        with:
          name: dotnet-tests
          path: TestResults/**/*.trx
          reporter: dotnet-trx
      - if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: TestResults/**/coverage.cobertura.xml

  package:
    needs: build-test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '8.0.x' }
      - run: |
          dotnet publish src/TaskFlow.Api/TaskFlow.Api.csproj \
            -c Release -o ./publish \
            /p:Version=${{ github.run_number }}.0.0
      - uses: actions/upload-artifact@v4
        with:
          name: taskflow-api
          path: ./publish
          retention-days: 30
```

---

## Starter: `P3-build-dotnet.yml`

```yaml
on:
  workflow_call:
    inputs:
      project: { required: true, type: string }
      dotnet-version: { default: '8.0.x', type: string }
      configuration: { default: 'Release', type: string }
    outputs:
      artifact-name:
        value: ${{ jobs.build.outputs.artifact-name }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact-name: ${{ steps.naming.outputs.name }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: ${{ inputs.dotnet-version }} }
      - run: dotnet build ${{ inputs.project }} -c ${{ inputs.configuration }}
      - id: naming
        run: |
          name="$(basename ${{ inputs.project }} .csproj)"
          echo "name=$name" >> "$GITHUB_OUTPUT"
```

---

## Starter: `P4-azure-pipelines.yml`

```yaml
trigger:
  branches: { include: [main] }
pr:
  branches: { include: [main] }

variables:
  dotnetVersion: '8.0.x'
  buildConfiguration: 'Release'

pool: { vmImage: 'ubuntu-latest' }

stages:
  - stage: build_test
    jobs:
      - job: build_test
        timeoutInMinutes: 15
        steps:
          - template: P4-templates/dotnet-build.yml
            parameters:
              project: 'src/TaskFlow.Api/TaskFlow.Api.csproj'
              configuration: $(buildConfiguration)
          - script: |
              dotnet test --no-build -c $(buildConfiguration) \
                --logger trx \
                --collect:"XPlat Code Coverage" \
                --results-directory $(Agent.TempDirectory)/TR
            displayName: Test
          - task: PublishTestResults@2
            condition: always()
            inputs:
              testResultsFormat: VSTest
              testResultsFiles: '**/*.trx'
              searchFolder: $(Agent.TempDirectory)/TR
              failTaskOnFailedTests: true
          - task: PublishCodeCoverageResults@2
            condition: always()
            inputs:
              summaryFileLocation: '$(Agent.TempDirectory)/TR/**/coverage.cobertura.xml'
  - stage: package
    dependsOn: build_test
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: pack
        steps:
          - task: UseDotNet@2
            inputs: { version: $(dotnetVersion) }
          - script: |
              dotnet publish src/TaskFlow.Api/TaskFlow.Api.csproj \
                -c Release -o $(Build.ArtifactStagingDirectory)/publish \
                /p:Version=$(Build.BuildNumber)
          - publish: $(Build.ArtifactStagingDirectory)/publish
            artifact: taskflow-api
```

---

## Starter: `P5-promote.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SOURCE_REG="acrtaskflowdev"
DEST_REG="acrtaskflowprod"
IMAGE="taskflow-api"
TAG="${1:?usage: $0 <tag>}"

az acr import \
  --name "$DEST_REG" \
  --source "${SOURCE_REG}.azurecr.io/${IMAGE}:${TAG}" \
  --image "${IMAGE}:${TAG}" \
  --force

src_digest=$(az acr repository show \
  --name "$SOURCE_REG" --image "${IMAGE}:${TAG}" --query digest -o tsv)
dst_digest=$(az acr repository show \
  --name "$DEST_REG"   --image "${IMAGE}:${TAG}" --query digest -o tsv)

if [[ "$src_digest" != "$dst_digest" ]]; then
  echo "Digest mismatch: $src_digest != $dst_digest" >&2
  exit 1
fi
echo "Promoted ${IMAGE}:${TAG} (digest $dst_digest)"
```

---

## Submission

When you finish a problem, tell me e.g. **"check P2"**.
