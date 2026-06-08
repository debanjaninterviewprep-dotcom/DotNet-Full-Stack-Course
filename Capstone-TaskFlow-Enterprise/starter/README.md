# TaskFlow — Starter Repo Layout

Fork or copy this folder to a new repo (e.g., `taskflow`). Each subfolder has a stub `README.md` describing what goes there and pointers to the relevant phase notes.

```
starter/
├── README.md                          (this file)
├── copilot-instructions.md            (root Copilot instructions stub)
├── .github/
│   ├── workflows/
│   │   ├── pr.yml                     (PR validation stub)
│   │   ├── preview.yml                (PR preview env stub)
│   │   ├── staging.yml                (main → staging stub)
│   │   └── prod.yml                   (tag → prod with approval stub)
│   ├── instructions/
│   │   └── terraform.instructions.md  (scoped Copilot instructions for infra/)
│   └── prompts/
│       └── bump-api-version.prompt.md
├── backend/
│   └── README.md                      (where the .sln goes; layering rules)
├── frontend/
│   └── README.md                      (Angular 18 quickstart hints)
├── infra/
│   ├── modules/README.md
│   ├── envs/README.md
│   └── bootstrap/README.md            (remote state once-only setup)
└── docs/
    ├── architecture.md                (template)
    ├── runbook.md                     (template)
    ├── cost.md                        (template)
    ├── demo-script.md                 (template)
    └── adr/
        ├── 0001-record-architecture-decisions.md
        └── template.md
```

## How to use this

1. Copy `starter/` to a new git repo: `taskflow/`.
2. `git init && git add -A && git commit -m "chore: scaffold"`.
3. Run through [Build Plan M1](../02-Build-Plan.md#m1--backend-skeleton).
4. Tick boxes in the rubric as you go.
