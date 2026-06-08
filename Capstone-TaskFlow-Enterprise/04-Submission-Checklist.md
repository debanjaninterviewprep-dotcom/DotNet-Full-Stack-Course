# 04 — Submission Checklist

When you're ready to be graded, the repo (or repos) must contain everything below. Tick boxes here; commit this file with your submission.

---

## Repository Layout (canonical)

```
taskflow/                              # root (single repo OK, or split below)
├── README.md
├── copilot-instructions.md
├── .github/
│   ├── workflows/
│   │   ├── pr.yml
│   │   ├── preview.yml
│   │   ├── staging.yml
│   │   └── prod.yml
│   ├── instructions/
│   │   └── terraform.instructions.md
│   ├── prompts/
│   │   └── bump-api-version.prompt.md
│   └── chatmodes/                     # optional
│       └── refactor-aggregate.chatmode.md
├── backend/
│   ├── TaskFlow.sln
│   ├── src/
│   │   ├── TaskFlow.Api/
│   │   ├── TaskFlow.Application/
│   │   ├── TaskFlow.Domain/
│   │   └── TaskFlow.Infrastructure/
│   ├── tests/
│   │   ├── TaskFlow.Tests.Unit/
│   │   └── TaskFlow.Tests.Integration/
│   └── Directory.Build.props
├── frontend/
│   ├── angular.json
│   ├── package.json
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/
│   │   │   ├── features/board/
│   │   │   ├── features/project/
│   │   │   └── shared/
│   │   └── styles/
│   └── e2e/                           # Playwright
├── infra/
│   ├── modules/
│   │   ├── network/
│   │   ├── data/
│   │   ├── app/
│   │   ├── observability/
│   │   └── security/
│   ├── envs/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── bootstrap/                     # remote state setup, run once
└── docs/
    ├── architecture.md
    ├── runbook.md
    ├── cost.md
    ├── known-gaps.md
    ├── demo-script.md
    ├── adr/
    │   ├── 0001-record-architecture-decisions.md
    │   └── ... (≥ 8 total)
    ├── diagrams/                      # exported PNG/SVG
    └── demo/                          # recording
```

> Splitting into `taskflow-app` + `taskflow-infra` is fine — link them from each README.

---

## Mandatory Deliverables

### Code
- [ ] Backend builds + tests pass on a clean clone (`dotnet build && dotnet test`).
- [ ] Frontend builds + tests pass on a clean clone (`npm ci && npm test && npm run e2e`).
- [ ] Terraform plans clean for dev / staging / prod (`terraform plan` no diff after `apply`).
- [ ] All Actions SHA-pinned; no `@v4`-style tags.
- [ ] No secrets in source; CI uses OIDC only.

### Running Environments
- [ ] **Dev** alive and reachable (give me the URL or a screenshot if torn down for cost).
- [ ] **Staging** deployed on last `main` commit.
- [ ] **Prod** at tag `v1.0.0` with the demo data seeded.

### Documentation
- [ ] `README.md` — quickstart in < 10 commands; architecture diagram inline.
- [ ] `docs/architecture.md` — C4 (Context + Container + Component + Deployment).
- [ ] `docs/adr/` — ≥ 8 ADRs.
- [ ] `docs/runbook.md` — deploy / rollback / 3 common alerts + response.
- [ ] `docs/cost.md` — current monthly figure + 3 optimisation ideas.
- [ ] `docs/known-gaps.md` — anything you cut and why.

### Demo
- [ ] `docs/demo-script.md` — 8-minute walk-through script with timings.
- [ ] Recording (Loom / OBS) linked from the root README.
- [ ] Slide(s) optional but encouraged for the architecture overview.

### Security & Compliance Evidence
- [ ] Secure Score screenshot from Defender (≥ 70%).
- [ ] Policy compliance screenshot (≥ 95%).
- [ ] Output of a tenant-isolation integration test proving cross-tenant 404.
- [ ] Incident dry-run write-up in `docs/incidents/`.

### Cost Evidence
- [ ] Cost Analysis screenshot for last 30 days.
- [ ] Budget alert configuration screenshot or Terraform.

---

## "Definition of Done" Final Sweep

Before saying "**grade me**":

1. Clone the repo to a new folder, follow the README quickstart, watch it work.
2. Open the demo video on a friend's laptop — does it land in 8 minutes?
3. Open any Azure Portal blade for prod — does it look clean (tags, locks, MI everywhere, no warnings)?
4. Run the rubric in [03-Rubric.md](./03-Rubric.md) on yourself; record your self-score in `docs/self-score.md`.
5. Ping me: "**capstone ready, please grade**".

---

## What Happens Next

I grade against [03-Rubric.md](./03-Rubric.md), section by section. You get:
- A score.
- A pass / fail / distinction marker.
- A list of "must-fix" items if pass-line is missed.
- Three "would elevate" items regardless of score.

Good luck. Build the platform you'd want to inherit.
