# Solutions — AI in CI/CD & Infrastructure Automation

Drop your answers here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-ci/
│   ├── ci-draft.yml
│   ├── ci.yml
│   └── audit.md
├── P2-log-triage/
│   ├── action.yml
│   ├── triage.ps1     (or .sh / .ts)
│   ├── failing-workflow.yml
│   └── screenshot.png
├── P3-tf-reviewer/
│   ├── workflow.yml
│   ├── ai-tf-review/action.yml
│   └── screenshot.png
├── P4-incident-agent/
│   ├── TaskFlow.IncidentAgent/
│   │   ├── Program.cs
│   │   ├── Tools/
│   │   └── *.csproj
│   ├── sample-input.json
│   └── sample-output.md
├── P5-docs-pipeline/
│   ├── workflow.yml
│   └── pr-screenshot.png
├── P6-forecast/
│   ├── traffic-90d.csv
│   ├── ai-transcript.md
│   ├── crosscheck.xlsx (or .py + chart)
│   └── recommendation.md
└── P7-ai-in-ci-governance.md
```

Tell me **"check"** when done.

---

## P1 Starter — Hardened `ci.yml`

```yaml
name: ci

on:
  pull_request:
  push: { branches: [main] }

permissions:
  contents: read

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11   # v4.1.1
      - uses: actions/setup-dotnet@4d6c8fcf3c8f7a60068d26b594648e99df24cee3   # v4.0.0
        with: { dotnet-version: '8.0.x' }
      - name: NuGet cache
        uses: actions/cache@13aacd865c20de90d75de3b17ebe84f7a17d57d2   # v4.0.0
        with:
          path: ~/.nuget/packages
          key: nuget-${{ runner.os }}-${{ hashFiles('**/*.csproj','**/packages.lock.json') }}
          restore-keys: nuget-${{ runner.os }}-
      - run: dotnet restore --locked-mode
      - run: dotnet build -c Release --no-restore
      - run: dotnet test -c Release --no-build
          --logger "trx;LogFileName=test-results.trx"
          --collect:"XPlat Code Coverage"
          --results-directory ./TestResults
      - name: Publish TRX
        if: always()
        uses: actions/upload-artifact@5d5d22a31266ced268874388b861e4b58bb5c2f3   # v4.3.1
        with:
          name: test-results
          path: TestResults/**/*.trx
      - name: Publish coverage
        if: always()
        uses: actions/upload-artifact@5d5d22a31266ced268874388b861e4b58bb5c2f3
        with:
          name: coverage
          path: TestResults/**/coverage.cobertura.xml
```

## P2 Starter — `action.yml`

```yaml
name: AI Log Triage
description: Summarises failing step log and comments on the PR.
inputs:
  step-log-path: { required: true }
  model:         { required: false, default: gpt-4o-mini }
  max-tokens:    { required: false, default: '800' }
runs:
  using: composite
  steps:
    - shell: bash
      env:
        AOAI_ENDPOINT: ${{ env.AOAI_ENDPOINT }}
        AOAI_KEY:      ${{ env.AOAI_KEY }}
        GH_TOKEN:      ${{ env.GITHUB_TOKEN }}
        LOG_PATH:      ${{ inputs.step-log-path }}
        MODEL:         ${{ inputs.model }}
      run: |
        # 1. Trim log
        tail -n 200 "$LOG_PATH" > trimmed.log
        # 2. Call model with structured prompt (jq + curl)
        # 3. Parse JSON
        # 4. gh pr comment with the diagnosis
```

## P4 Starter — Incident agent skeleton

```csharp
using System.ComponentModel;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using Azure.AI.OpenAI;
using Azure.Identity;
using System.Text.Json;

var chat = new AzureOpenAIClient(
        new Uri(Environment.GetEnvironmentVariable("AOAI_ENDPOINT")!),
        new DefaultAzureCredential())
    .GetChatClient(Environment.GetEnvironmentVariable("AOAI_DEPLOYMENT")!)
    .AsIChatClient();

var agent = chat.CreateAIAgent(
    name: "IncidentTriage",
    instructions: """
        You triage Azure incidents.
        Use the tools to fetch telemetry, recent deploys, and the runbook.
        Return ONLY JSON matching this schema:
        {"summary":"...","likely_root_cause":"...","confidence":"low|medium|high",
         "suggested_actions":[{"action":"...","risk":"low|medium|high"}],
         "evidence_links":["..."]}
        If tools return empty/null, set confidence="low" and explain.
        Never invent links.
        """,
    tools:
    [
        AIFunctionFactory.Create(QueryAppInsights),
        AIFunctionFactory.Create(ListRecentDeploys),
        AIFunctionFactory.Create(ReadRunbook)
    ]);

var alertJson = await File.ReadAllTextAsync(args[0]);
var prompt = $"Triage this alert and produce JSON:\n{alertJson}";

var thread = agent.GetNewThread();
var response = await agent.RunAsync(prompt, thread);
Console.WriteLine(response.Text);

[Description("Run a KQL query against App Insights. Returns up to 50 rows as JSON.")]
static Task<string> QueryAppInsights([Description("KQL query")] string kql)
    => Task.FromResult("[]"); // wire to real client

[Description("List GitHub deploys in last N hours for a repo.")]
static Task<string> ListRecentDeploys(string repo, int hours = 24)
    => Task.FromResult("[]");

[Description("Read a runbook by name from docs/runbooks/.")]
static Task<string> ReadRunbook([Description("e.g. 'alert-5xx'")] string name)
    => File.Exists($"docs/runbooks/{name}.md")
        ? File.ReadAllTextAsync($"docs/runbooks/{name}.md")
        : Task.FromResult("");
```
