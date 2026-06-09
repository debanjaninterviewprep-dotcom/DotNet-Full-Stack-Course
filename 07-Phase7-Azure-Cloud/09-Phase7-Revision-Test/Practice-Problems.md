# Phase 7 Revision Test — Practice Problems Workspace

> The actual test is in [Notes.md](./Notes.md). This file is a checklist + scoring rubric so you (and the grader) know what "good" looks like for each section.

## Scoring Rubric (100 points)

| Section | Points | What earns full marks |
|---|---|---|
| A — Quick-fire concepts | 24 (2 each) | Correct, concise; no hand-waving |
| B — Architecture & diagrams | 18 (6 each) | Mermaid renders; arrows annotated; identity model explicit |
| C — Code reading | 16 (4 each) | Bug identified AND fix is idiomatic |
| D — Hands-on build | 20 (10 each, pick 2 of 3) | Code runs; uses MI; documented |
| E — Cost & performance | 12 (4 each) | Numbers shown; assumptions stated |
| F — Security audit | 10 | All items judged; remediations are specific |

Pass: 70+. Below 70: revisit weak topic areas before Phase 8.

---

## Folder Layout for Your Answers

```
PracticeProblemsSolutions/
├── Section-A.md         # 12 quick-fire answers
├── Section-B.md         # Mermaid diagrams & cross-cloud plan
├── Section-C.md         # Bug analysis + fixed code
├── Section-D/           # Hands-on builds (your 2 of 3)
│   ├── D1-secure-upload/
│   ├── D2-outbox/
│   └── D3-drift-detect/
├── Section-E.md         # Cost & perf math
└── Section-F.md         # Audit + remediation plan
```

---

## Self-Check Before "check"

- [ ] Section A: 12 answers, no answer longer than 3 sentences.
- [ ] Section B: All three diagrams render in your local markdown preview.
- [ ] Section C: Each fix actually compiles (paste to a scratch project).
- [ ] Section D: Both chosen builds run end-to-end at least once. Logs / outputs captured.
- [ ] Section E: Each calculation cites the price source and shows the formula.
- [ ] Section F: F1 fully filled; F2 remediations have CLI commands.

---

## Honest Self-Assessment Prompts

Before submitting, write a short paragraph (`reflection.md`) answering:

1. Which topic felt weakest while taking this test?
2. Did you reach for any external doc you couldn't find by memory?
3. Where would your design fail under 10× scale?
4. If you had to onboard a junior developer to TaskFlow's Azure stack tomorrow, what's the **one diagram** you'd hand them?

These are not graded but they make the next phase more useful.
