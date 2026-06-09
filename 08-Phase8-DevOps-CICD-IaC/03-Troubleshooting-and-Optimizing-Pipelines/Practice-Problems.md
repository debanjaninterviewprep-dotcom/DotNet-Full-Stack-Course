# Topic 3 — Practice Problems

> Solutions go in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). Each problem has **Goal**, **Tasks**, **Deliverables**, **Look-fors**.

---

## P1 — Triage a Failed Run

**Goal:** Practice the diagnostic mindset.

**Tasks**
Given the failure transcript in `P1-failure-log.txt` (write a realistic one if you don't have a real failure handy — include NuGet restore noise, a build error, a test failure, and an Azure CLI timeout), write `P1-triage.md` that:
1. Identifies the **first** real error.
2. Classifies it into one of the five buckets (Source / Env / Dep / Flake / Resource).
3. Lists three hypotheses ranked by likelihood.
4. Specifies the one experiment you'd run first to disambiguate, and what each outcome would tell you.

**Look-fors**
- [ ] Skips noise; identifies the *causing* error not the *cascading* one.
- [ ] Hypotheses are concrete (not "maybe the network").
- [ ] Experiment is cheap (< 5 min) and falsifiable.

---

## P2 — Add Debug Logging Safely

**Goal:** Make a workflow auto-attach a tmate session only when explicitly opted in.

**Tasks**
1. Add a `workflow_dispatch` input `debug` (boolean, default false).
2. In the build job, append a step that opens tmate **only** when the workflow was dispatched with `debug=true` AND the job failed.
3. Add a `timeout-minutes` of 15 on the tmate step.
4. Document in `P2-debug-policy.md`:
   - Who can dispatch with debug.
   - What never to do in a tmate (touch prod, exfiltrate secrets).

**Deliverables**
- `P2-ci.yml`
- `P2-debug-policy.md`

**Look-fors**
- [ ] Tmate step gated by both `failure()` and the input.
- [ ] Timeout present.
- [ ] Policy mentions secret exposure risk.

---

## P3 — Speed Up a Slow CI

**Goal:** Demonstrate a measurable speed improvement.

**Tasks**
1. Take `P3-before.yml` (an intentionally slow .NET CI — write one if needed: no cache, full clone, sequential test/lint/scan, no `--no-restore`).
2. Profile and produce `P3-baseline.md` showing per-step durations.
3. Apply at least **five** optimisations and write `P3-after.yml`.
4. Re-run and produce `P3-results.md` with before/after table and a one-sentence rationale per change.

Targets:
- ≥ 50% wall-clock reduction.
- No reduction in coverage or test count.
- All four security scans still required.

**Deliverables**
- `P3-before.yml`
- `P3-after.yml`
- `P3-baseline.md`
- `P3-results.md`

**Look-fors**
- [ ] Measured both runs, didn't eyeball.
- [ ] At least one cache, one parallelisation, one checkout improvement.
- [ ] Rationale ties each change to a specific bottleneck.

---

## P4 — Make a Flaky Test Fail Visibly

**Goal:** Surface flakiness instead of hiding it behind retry.

**Tasks**
1. Add three test attributes: `Flaky`, `Slow`, `Integration`.
2. In CI, run categories separately:
   - **Fast unit tests** — required check, no retry, must pass.
   - **Flaky** — runs with retry but writes to a "flake report" if any retry was needed.
   - **Integration** — runs only on `main` or nightly.
3. Wire the flake report to a job summary using `$GITHUB_STEP_SUMMARY`.
4. After 5 reports in a week, the test should be quarantined (manual ticket).

**Deliverables**
- `P4-ci.yml`
- `P4-flake-report.md` (sample output)

**Look-fors**
- [ ] Fast unit tests have **no** retry.
- [ ] Flake report is visible without clicking into logs.
- [ ] Quarantine policy is written down.

---

## P5 — Cache Strategy

**Goal:** Design and document a caching strategy you'd defend at design review.

**Tasks**
Write `P5-cache-strategy.md` answering:
1. Which package managers your repos use (NuGet, npm, pnpm, others).
2. The cache key for each: what's hashed, what's prefixed.
3. Restore-key fallback order.
4. How you invalidate (manual prefix bump? scheduled job?).
5. Estimated CI minute savings (with math).
6. Risks (cache poisoning, key collisions, fork PRs not getting cache).

Provide the matching `P5-cache-example.yml` snippet.

**Look-fors**
- [ ] Lockfile in the key.
- [ ] OS in the key.
- [ ] Documented invalidation procedure.
- [ ] Math, not vibes, for savings estimate.

---

## P6 — Build a CI Container Image

**Goal:** Eliminate repeated tool installs.

**Tasks**
1. Write `P6-Dockerfile`:
   - Base: `mcr.microsoft.com/dotnet/sdk:8.0`.
   - Adds: `jq`, `unzip`, `curl`, `azure-cli`, `gh` CLI, `pwsh`, `coverlet`.
2. Publish it to GHCR as `ghcr.io/<you>/ci-dotnet:8.0-test`.
3. Update `P6-ci.yml` so the build job uses `container:` with that image.
4. Measure cold and warm run times in `P6-results.md`.

**Look-fors**
- [ ] Image is multi-arch if reasonable.
- [ ] Build doesn't install tools again at runtime.
- [ ] Image is published with a stable tag (not `:latest`).

---

## P7 (Stretch) — Reproduce a Pipeline Locally

**Goal:** Use `act` (or equivalent) to run your CI workflow on your laptop.

**Tasks**
1. Install `act`.
2. Run `act push -j build-test --container-architecture linux/amd64`.
3. Fix any incompatibility (likely path / cache).
4. Document differences from real GitHub-hosted runs.

**Deliverables**
- `P7-act-notes.md` (what worked, what didn't, when to reach for it).

**Look-fors**
- [ ] Identifies specific Actions that fail under `act`.
- [ ] Lists realistic use cases for local repro.

---

## Submission

Tell me **"check P3"** (or a range) for graded review.
