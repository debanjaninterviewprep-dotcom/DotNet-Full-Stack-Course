# Topic 3: Troubleshooting & Optimizing Pipelines

> **Goal:** Diagnose pipeline failures fast, understand why they're slow, and apply concrete optimisations (caching, parallelism, runner choice, image hygiene). When this topic is done you should be able to look at a 12-minute CI and turn it into a 3-minute CI without losing any guarantees.

---

## 1. A Diagnostic Mindset

Pipelines fail for one of five reasons. Identify the bucket first; the fix follows.

| Bucket | Tell-tale signs |
|---|---|
| **Source / config** | Same error on every machine; deterministic; new failure right after a YAML edit |
| **Environment / runner** | Works on machine A, fails on machine B; intermittent OS-specific issues |
| **Dependency / network** | NuGet/npm restore failed; 503 from registry; only happens at certain times |
| **Flaky test / race** | Same test fails ~5% of the time; passes on rerun |
| **Resource / quota** | Job killed with OOM; "no agent available"; throttled by Azure/GitHub |

If your team doesn't know which bucket a red build falls into within 60 seconds, your logs aren't good enough.

---

## 2. Reading a Failed Run (the right way)

### 2.1 Scan from the top, not the bottom
The first red step usually causes the cascade. The last red step is often noise. Scroll up to the **first non-zero exit** and start there.

### 2.2 Look for the literal error
- C# build: search for `error CS`.
- Tests: search for `Failed!`, then for the specific assertion.
- Azure CLI: search for `ERROR:`.
- Docker: `failed to compute cache key` or `exit code: <n>`.

### 2.3 Compare against the last green run
GitHub: click "Compare" between two runs. Difference is usually:
- A new commit (look at diff).
- A new runner image version.
- A floating action moved (this is why we pin SHAs).

### 2.4 Re-run with debug logging
- **GitHub Actions:** Re-run job → tick **"Enable debug logging"**. Adds `ACTIONS_RUNNER_DEBUG=true` and `ACTIONS_STEP_DEBUG=true`. Shows runner internals, masked-value matches, expression evaluation.
- **Azure Pipelines:** Run new build with variable `System.Debug=true`.

Treat these like x-rays — useful, but produces noise. Don't leave them on for green builds.

### 2.5 SSH / tmate into the runner
For maddening reproduction problems:

```yaml
- name: Setup tmate session (debug only)
  if: failure() && runner.debug == '1'
  uses: mxschmitt/action-tmate@v3
  timeout-minutes: 15
```

You SSH into the actual runner, poke around, then quit. **Never** leave this on a default workflow — gives anyone with run access a shell.

---

## 3. Common Failure Patterns & Fixes

### 3.1 "It works on my machine"

| Symptom | Likely cause | Fix |
|---|---|---|
| Build OK locally, fails in CI on a missing tool | Tool installed globally on dev box, not declared | Add explicit `dotnet tool restore` / `setup-*` step |
| Different test results | Time-zone, culture, locale | Set `TZ=UTC` and `DOTNET_CLI_UI_LANGUAGE=en-US` in env |
| File-path case | Windows is case-insensitive, Linux runner is case-sensitive | Fix the case in code or rename |
| Line-ending diffs | CRLF vs LF | `.gitattributes` + `dotnet format` |

### 3.2 NuGet / npm restore flakiness

```
warning NU1605: Detected package downgrade
error NU3037: Package signature validation failed
```

Causes:
- Transient `nuget.org` 503.
- Stale lockfile vs csproj.
- Mirror missing the version.

Fixes:
- Retry restore (`dotnet restore` once is fine, twice with `--force` if needed).
- Pin to a stable Azure Artifacts feed for upstream proxying.
- Use **lock files** (`<RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>`) so CI uses `--locked-mode`.

### 3.3 Flaky tests

> If a test fails 1% of the time, it fails 100% of the time on a long enough timeline.

Patterns:
- Time-based (`DateTime.Now`) — inject a clock.
- Order-dependent — find with `xunit` random order, fix shared state.
- Network call in unit test — mock it.
- Parallel state collision — use `Collection` to serialize.

Triage in CI without unblocking PRs:
```yaml
- name: Test (with retry)
  uses: nick-fields/retry@v3
  with:
    timeout_minutes: 10
    max_attempts: 2
    command: dotnet test --no-build -c Release
```

Then tag the test as `[Trait("Flaky","true")]`, file a ticket, fix this sprint.

### 3.4 "No agent available" / queue starvation

Causes:
- Self-hosted runner offline.
- Org concurrency limit hit.
- Sudden parallel job spike (matrix bomb).

Fixes:
- Cap matrix.
- Use `concurrency: cancel-in-progress` to drop superseded runs.
- Add scaling for self-hosted runners (e.g., `actions-runner-controller` on AKS with autoscaling on `wait-time`).

### 3.5 Image / SDK breakage on runner refresh

Microsoft refreshes hosted images weekly. A passing build can break Monday morning because:
- A preinstalled tool version changed.
- The SDK got a security patch that surfaces a deprecation.

Mitigations:
- **Pin** SDK with `setup-dotnet@v4 + dotnet-version` (don't rely on preinstalled).
- Subscribe to the [runner-images repo](https://github.com/actions/runner-images) — they post upcoming changes.
- Self-host critical builds where you control the image cadence.

### 3.6 OOM / timeout
- Add `timeout-minutes:` to every job (forces visibility).
- For .NET, `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1` can shave memory.
- For containers, set explicit `--memory` to surface OOMs early.
- Profile what's allocating — heap dump on failure via `dotnet-dump`.

---

## 4. Performance: Where the Time Actually Goes

Instrument first. Optimise second. Run the same pipeline 3× and measure:

| Phase | Typical share | If yours is bigger… |
|---|---|---|
| Setup (checkout, SDK, tools) | 10–20% | Cache more; smaller base image |
| Restore | 10–30% | Cache NuGet/npm; use lock files |
| Build | 20–40% | Incremental build; remove unused projects from solution |
| Test | 30–60% | Parallelize; split fast/slow |
| Package & publish | 5–15% | Docker layer caching |
| Other (artifacts, scans) | 5–20% | Run in parallel, not sequential |

You only get fast pipelines by attacking the **biggest** bucket. Optimising a 30-second step won't matter if test takes 4 minutes.

---

## 5. Caching (the biggest single lever)

### 5.1 NuGet (GitHub Actions)

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.nuget/packages
      ~/.dotnet/tools          # also cache global tools
    key: nuget-${{ runner.os }}-${{ hashFiles('**/*.csproj','**/packages.lock.json') }}
    restore-keys: |
      nuget-${{ runner.os }}-
```

Or the simpler `setup-dotnet` built-in cache:
```yaml
- uses: actions/setup-dotnet@v4
  with:
    dotnet-version: '8.0.x'
    cache: true
    cache-dependency-path: '**/packages.lock.json'
```

### 5.2 npm / pnpm / yarn
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'
    cache-dependency-path: pnpm-lock.yaml
```

### 5.3 Cache hygiene
- **Key on lockfile**, not on package manifest alone (else cache hits incorrectly).
- **Include OS** in the key (different OS = different binaries).
- **Use restore-keys** as fallback — partial hit is faster than no hit.
- **Don't cache huge / mutable folders** (e.g., `node_modules` is OK if reproducible, dangerous if dev-only).
- Cache is **scoped to branch**; PRs from forks won't get your cache (security feature).

### 5.4 Azure Pipelines `Cache@2`
```yaml
- task: Cache@2
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/packages.lock.json'
    restoreKeys: 'nuget | "$(Agent.OS)"'
    path: $(NUGET_PACKAGES)
```

Set `NUGET_PACKAGES` as a variable pointing to `$(Pipeline.Workspace)/.nuget/packages` so it persists in the workspace.

### 5.5 Docker layer caching

Two approaches:

**Buildx + registry cache (most flexible):**
```yaml
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: acrtaskflow.azurecr.io/api:${{ github.sha }}
    cache-from: type=registry,ref=acrtaskflow.azurecr.io/api:buildcache
    cache-to:   type=registry,ref=acrtaskflow.azurecr.io/api:buildcache,mode=max
```

**GitHub Actions cache:**
```yaml
cache-from: type=gha
cache-to:   type=gha,mode=max
```
GH cache has a 10 GB limit; the registry approach is uncapped (you pay storage).

### 5.6 Cache invalidation
The two hardest problems in CS are naming, cache invalidation, and off-by-one errors. Use these rules:

- Always include a **lockfile hash** in the key.
- When you change SDK version, change a prefix in the key (`nuget-v2-…`).
- Periodically rotate the prefix to flush stale caches (~quarterly).

---

## 6. Parallelism

### 6.1 Job-level parallelism
GitHub: each job runs on its own runner. Don't put steps in one job if they can be separate jobs (test + lint + security can all run in parallel).

```yaml
jobs:
  test:    ...
  lint:    ...
  scan:    ...
  build:   ...   # independent of the three above
  package:
    needs: [test, lint, scan, build]
```

### 6.2 Test sharding
For a long test suite, split with `xUnit.runner.json` filters or `dotnet test --filter`:

```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: |
      dotnet test --filter "FullyQualifiedName!~SlowSuite" \
        --logger "trx" \
        -- RunConfiguration.TestSessionTimeout=600000 \
        /p:ShardIndex=${{ matrix.shard }} /p:TotalShards=4
```

xUnit doesn't ship native sharding — use a deterministic-hash filter or `dotnet test --filter "Category=Shard${shard}"` with categorised tests.

### 6.3 Parallel test execution within a process
- xUnit: `[assembly: CollectionBehavior(DisableTestParallelization = false)]`. Threads = `Environment.ProcessorCount` by default.
- NUnit: `[Parallelizable(ParallelScope.All)]`.
- Watch for shared state (`static`, files, DB connections).

### 6.4 Diminishing returns
8 jobs in parallel ≠ 8× speed. Bottleneck shifts to:
- Artifact upload bandwidth.
- Total minute cost.
- Wait time for the slowest shard.

Profile after each change.

---

## 7. Runner Choice & Sizing

| Runner | When to use | Cost note |
|---|---|---|
| `ubuntu-latest` | Default for .NET, Node, Python | Cheapest |
| `windows-latest` | .NET Framework, WPF, MSIX | 2× minutes |
| `macos-latest` | iOS, Mac signing | 10× minutes |
| `ubuntu-latest-4-cores` (larger GH runners) | CPU-bound builds (Rust, C++, big test suite) | 2–4× minutes but often net cheaper from wall time |
| `self-hosted` (ephemeral, on AKS) | Private network, sustained load | Pay your own infra; faster cold start with warm pool |

Rule of thumb: if you save 5 min of wall time using a 2× runner, you pay 2× minutes — even. Anything beyond that is a win.

---

## 8. Trimming the Critical Path

### 8.1 Don't restore twice
```yaml
- run: dotnet restore --locked-mode
- run: dotnet build  --no-restore
- run: dotnet test   --no-build --no-restore
```
`--no-restore --no-build` are essential. Otherwise each step does a full restore/build.

### 8.2 Don't rebuild what you can publish from build output
`dotnet publish` re-builds by default. Use:
```bash
dotnet publish --no-build -c Release -o ./publish
```
…after a separate `dotnet build`.

### 8.3 Avoid full clone when you don't need history
```yaml
- uses: actions/checkout@v4
  with: { fetch-depth: 1 }
```
…unless you need GitVersion, blame, or release notes that need full history.

### 8.4 Skip work when nothing changed (path filters + concurrency)
- `paths:` filter: don't run a docs typo through the whole build.
- `paths-ignore:` for the opposite.
- `concurrency` + `cancel-in-progress`: drop superseded runs.

### 8.5 Pre-built container images
If every CI run does `apt-get install` of 5 tools, bake them into a custom container:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/taskflow/ci-dotnet:8.0-2026.06
```
The image is pulled once per runner; subsequent steps are fast.

---

## 9. Profiling Real Pipelines

### 9.1 GitHub Actions metrics
- `Actions → Run → Job → Summary` shows per-step duration.
- `Insights → Actions` (org-level) shows minute usage trends.
- For a slow run, copy the timing JSON: `gh run view <id> --log | wc` then eyeball.

### 9.2 Azure Pipelines analytics
- `Pipelines → Analytics → Pipeline pass rate / Duration trend / Test pass rate`.
- Stage-level timings in the run view.

### 9.3 Bring your own metrics
Emit each step's duration to App Insights:
```yaml
- run: |
    end=$(date +%s)
    duration=$((end-START))
    curl -X POST https://dc.services.visualstudio.com/v2/track \
      -H "Content-Type: application/json" \
      -d "{ \"name\":\"Microsoft.ApplicationInsights.Metric\", \"iKey\":\"$AI_KEY\", \"data\":{...} }"
```
Now you can dashboard CI duration over time and alert on regressions.

---

## 10. Debugging Specific Tooling Failures

### 10.1 Azure CLI in pipelines
```yaml
- uses: azure/cli@v2
  with:
    inlineScript: |
      set -x                          # echo commands
      az account show
      az group list -o table
```
- `--verbose` and `--debug` show HTTP requests.
- `AZURE_CORE_OUTPUT=json` ensures parseable output for `jq`.

### 10.2 Bicep / ARM deploys
```bash
az deployment group what-if --resource-group rg-x --template-file main.bicep --parameters @params.json
```
What-if shows the diff *before* you apply. Always run it in PR pipeline; fail if unwanted changes appear.

### 10.3 Terraform (preview — full coverage in Topic 4)
- `TF_LOG=DEBUG` for verbose.
- `terraform plan -detailed-exitcode` returns 2 if there's a diff (useful in CI).

### 10.4 Docker
- `--progress=plain` gets full layer logs in CI.
- `docker buildx build --no-cache` if you suspect a stale layer.
- Push a debug image then `docker run --rm -it <img> sh` to inspect.

### 10.5 Kubernetes
- `kubectl describe pod <p>` for events.
- `kubectl logs -p <p>` for previous instance.
- `kubectl debug` (1.25+) to add an ephemeral container with curl/dig.

---

## 11. Reproducing Failures Locally

The fastest fix is one you reproduce on your laptop.

### 11.1 GitHub Actions: `act`
```bash
act push -j build-test \
  --container-architecture linux/amd64 \
  --secret-file .env.secrets
```
[nektos/act](https://github.com/nektos/act) runs workflows in Docker. Caveats:
- Some Actions don't work (GitHub-hosted only features).
- Use `--platform ubuntu-latest=catthehacker/ubuntu:full-22.04` for closer parity to GitHub's image.

### 11.2 Azure DevOps: agent locally
Install the agent on your machine in a separate folder, point it to your project. Disable when done. Slower to set up than `act`.

### 11.3 The container approach
Build a Dockerfile that *is* your CI environment:
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0
RUN apt-get update && apt-get install -y jq curl unzip
```
Run your build inside it locally. Works for both GH Actions and ADO since both can be configured to use container jobs.

---

## 12. Pipeline Anti-Patterns That Cost Time

| Anti-pattern | Time cost | Fix |
|---|---|---|
| `actions/checkout` with `fetch-depth: 0` everywhere | 10–60 s | `fetch-depth: 1` unless needed |
| Two separate `restore` and `build` calls without `--no-restore` | Doubles restore time | Add `--no-restore` |
| Caching `node_modules` instead of pnpm/npm store | Slower & flaky | Cache the store, not modules |
| Running tests sequentially when parallel-safe | N× wall time | Enable test parallelism |
| Same workflow runs lint twice (push + PR same SHA) | 2× minutes | Use `if: github.event_name == 'pull_request' || github.ref == 'refs/heads/main'` |
| Self-hosted runner without ephemeral mode | Stale workspace, leaks secrets | Ephemeral + clean workspace step |
| No `timeout-minutes:` | Hung job burns minutes silently | Set tight timeouts everywhere |
| Huge artifacts (entire repo) | Network + storage | Upload only what's needed |
| Caching everything | Cache becomes bigger than fresh download | Be selective |
| Verbose default logging | Hard to read | Verbose only when failing |

---

## 13. SLAs for Pipelines

Set internal targets and track them:

| Metric | Target |
|---|---|
| PR CI time | < 8 min (P95) |
| Main CI time | < 12 min (P95) |
| Deploy to dev | < 5 min after CI succeeds |
| Failed-rerun-then-green ratio | < 5% (else flake problem) |
| Pipeline availability | > 99% (else infra problem) |

If you don't measure these, you can't tell whether changes help.

---

## 14. The Slowest-Path Checklist (when nothing seems to help)

When you've tried the obvious things and CI is still slow:

1. **Profile each step** — print start/end timestamps; find the actual hotspot.
2. **Cold vs warm timing** — second run on the same SHA reveals cache effectiveness.
3. **Parallelizable but serial** — restructure to fan out.
4. **Repeated SDK install** — bake into custom container image.
5. **Test suite too monolithic** — shard or split into smoke/full.
6. **Pulling docker base every time** — cache base layer (`docker save`/`load` or registry cache).
7. **Artifact upload as critical path** — compress, split, or skip altogether.
8. **Network to a slow region** — runner in EU, ACR in US East. Co-locate.
9. **Self-host with warm pool** — if you have sustained throughput.

---

## 15. Worked Example: 14 min → 3 min

Real(-ish) refactor of a .NET 8 API CI:

| Step | Before | After | Change |
|---|---|---|---|
| Checkout | 30 s | 5 s | `fetch-depth: 1` |
| Setup SDK | 25 s | 1 s (cached) | `setup-dotnet` cache:true |
| Restore | 90 s | 8 s | NuGet cache + lock file |
| Build | 110 s | 65 s | `--no-restore`, removed 3 unused projects |
| Test | 7 min | 1m 50s | 4-way matrix shard |
| Coverage report | 25 s | 25 s | n/a |
| Security scan | 3 min | 3 min (parallel) | Moved to parallel job |
| Publish artifact | 35 s | 10 s | `dotnet publish --no-build`, only needed files |
| **Wall clock** | **14 min** | **~3 min** | |

Lessons: caching > shrinking, parallel > sequential, smaller checkout matters more than you'd think.

---

## Further Reading

- [GitHub Actions — caching dependencies](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Azure Pipelines — caching](https://learn.microsoft.com/azure/devops/pipelines/release/caching)
- [GitHub Actions debug logging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
- [Docker Buildx caching](https://docs.docker.com/build/cache/backends/)
- [nektos/act](https://github.com/nektos/act)
- [actions-runner-controller (AKS-hosted runners)](https://github.com/actions/actions-runner-controller)
