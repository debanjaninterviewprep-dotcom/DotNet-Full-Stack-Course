# Phase 6 Capstone — Reference Pack

This folder is **docs-only**. There is no `.csproj`. The "solution" to the capstone is the integrated TaskFlow you've built across Topics 1–12 plus the stretch challenges B1–B5.

## Contents

| File | Purpose |
|---|---|
| `capstone-checklist.md` | Acceptance + non-functional checks copied from Notes.md for fast self-review |
| `demo-script.md`        | The 5-minute demo with timestamps, expanded with talking points |
| `viva-questions.md`     | All 35 viva questions with concise model answers |
| `runbook-template.md`   | Skeleton `docs/runbook.md` you fill in for D2 |
| `adr-template.md`       | Skeleton ADR for any B-series challenge |

## How to use

1. Open `capstone-checklist.md` and tick boxes as you verify each item.
2. Practice the `demo-script.md` until you can do it cold.
3. Use `viva-questions.md` for spaced-repetition review.
4. Copy `runbook-template.md` to your repo's `docs/runbook.md` and complete it.
5. For each B-series challenge: copy `adr-template.md` to `docs/adrs/000X-<title>.md` and fill in the decision.

## Submission gate

Before declaring Phase 6 done, ALL of these must be true:

- [ ] D1 demo runs end-to-end in ≤ 5 min on a clean clone.
- [ ] D2 runbook validated via tabletop exercise.
- [ ] D3 threat model dated within 30 days.
- [ ] ≥ 2 of B1–B5 merged with ADR + tests + demo coverage.
- [ ] CI on `main` green; perf budget passing; coverage targets met.
- [ ] Tagged release `v1.0.0` with images in GHCR; deploy workflow ran successfully at least once.
