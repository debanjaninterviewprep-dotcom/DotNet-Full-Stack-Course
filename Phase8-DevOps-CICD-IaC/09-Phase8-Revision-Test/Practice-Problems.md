# Phase 8 Revision Test — Practice Problems Workspace

> The actual test is in [Notes.md](./Notes.md). This file is the rubric + folder layout for your answers.

## Scoring (100 points)

| Section | Pts | Full marks |
|---|---|---|
| A — Quick-fire concepts | 24 (2 each) | Correct, concise; no waffle |
| B — Architecture & diagrams | 18 (6 each) | Mermaid renders; identities and gates explicit |
| C — Code reading | 16 (4 each) | Every bug found; fix idiomatic |
| D — Hands-on build | 20 (10 each, pick 2 of 3) | Runs; uses OIDC; documented |
| E — Cost / perf / risk | 12 (4 each) | Numbers shown; assumptions stated |
| F — Security audit | 10 | All judged; remediations specific |

Pass: 70+. Below 70 = revisit weakest area before Phase 9.

## Folder Layout for Your Answers

```
PracticeProblemsSolutions/
├── README.md
├── Section-A.md
├── Section-B.md
├── Section-C.md
├── Section-D/
│   ├── D1-cicd/
│   ├── D2-terraform/
│   └── D3-observability/
├── Section-E.md
├── Section-F.md
└── reflection.md
```

## Self-Check Before "check"

- [ ] Section A: 12 answers, each ≤ 3 sentences.
- [ ] Section B: All three diagrams render in markdown preview.
- [ ] Section C: Each fix actually compiles / validates.
- [ ] Section D: Both builds you picked run end-to-end. Logs captured.
- [ ] Section E: Every calculation cites assumptions.
- [ ] Section F: F1 fully filled; F2 remediations have commands.

## Reflection Prompts (not graded, but useful)

In `reflection.md`:
1. Which topic felt weakest?
2. Did you reach for a doc you couldn't find by memory?
3. Where would your design fail under 10× scale or a 3 AM incident?
4. If you had to onboard a new engineer tomorrow, which **single diagram** would you hand them?
