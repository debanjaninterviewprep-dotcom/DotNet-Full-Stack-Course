# Topic 3 — Solutions Workspace

```
PracticeProblemsSolutions/
├── README.md
├── P1-failure-log.txt
├── P1-triage.md
├── P2-ci.yml
├── P2-debug-policy.md
├── P3-before.yml
├── P3-after.yml
├── P3-baseline.md
├── P3-results.md
├── P4-ci.yml
├── P4-flake-report.md
├── P5-cache-strategy.md
├── P5-cache-example.yml
├── P6-Dockerfile
├── P6-ci.yml
├── P6-results.md
└── P7-act-notes.md
```

---

## Starter: `P2-ci.yml`

```yaml
name: ci

on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
  workflow_dispatch:
    inputs:
      debug:
        description: 'Attach tmate on failure (allow shell into runner)'
        required: false
        default: 'false'

permissions:
  contents: read

jobs:
  build-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '8.0.x' }
      - run: dotnet test -c Release

      - name: Tmate session (on failure, debug-only)
        if: ${{ failure() && github.event_name == 'workflow_dispatch' && github.event.inputs.debug == 'true' }}
        uses: mxschmitt/action-tmate@v3
        timeout-minutes: 15
```

---

## Starter: `P5-cache-example.yml`

```yaml
- name: Restore NuGet cache
  uses: actions/cache@v4
  with:
    path: |
      ~/.nuget/packages
      ~/.dotnet/tools
    key: nuget-v3-${{ runner.os }}-${{ hashFiles('**/*.csproj', '**/packages.lock.json') }}
    restore-keys: |
      nuget-v3-${{ runner.os }}-

- name: Restore pnpm cache
  uses: actions/cache@v4
  with:
    path: ~/.local/share/pnpm/store
    key: pnpm-v1-${{ runner.os }}-${{ hashFiles('pnpm-lock.yaml') }}
    restore-keys: pnpm-v1-${{ runner.os }}-
```

---

## Starter: `P6-Dockerfile`

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release jq unzip git \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# .NET global tools commonly used in CI
RUN dotnet tool install -g dotnet-coverage \
    && dotnet tool install -g dotnet-reportgenerator-globaltool

ENV PATH="${PATH}:/root/.dotnet/tools"

LABEL org.opencontainers.image.source="https://github.com/<you>/ci-dotnet"
```

---

## Submission

Tell me **"check P3"** for graded review.
