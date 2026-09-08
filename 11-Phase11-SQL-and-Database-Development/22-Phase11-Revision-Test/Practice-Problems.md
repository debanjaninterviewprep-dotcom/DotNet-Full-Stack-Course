# Phase 11 Revision Test — Practice Problems

The test itself lives in [Notes.md](./Notes.md). This file restates the **rubric** and **submission layout** so you can plan your time.

---

## Time Budget

| Section | Suggested time |
|---|---|
| A — Quick-fire | 45 min |
| B — Diagrams | 30 min |
| C — Bug hunts | 40 min |
| D — Hands-on (2 of 3) | 90 min |
| E — Design & trade-offs | 40 min |
| F — Audit | 30 min |
| **Total** | **~4–6 hr** |

---

## Rubric

| Section | Pts |
|---|---|
| A — 15 quick-fire (2 pts each) | 30 |
| B — 2 diagrams (5 pts each) | 10 |
| C — 5 bug hunts (4 pts each) | 20 |
| D — 2 of 3 hands-on (12 pts each) | 24 |
| E — 2 design/trade-off answers (5 pts each) | 10 |
| F — Security & integrity audit checklist | 6 |
| **Total** | **100** |
| **Pass** | **70** |

### Section-by-section scoring notes

- **A:** Full marks = sharp, correct, no padding. Half marks for a partially correct or overly generic answer (e.g. "NULLs are weird" instead of naming three-valued logic specifically).
- **B:** Full marks = correct cardinality/relationships, clearly labelled, weak entities identified in B1; decision points correctly shown as diamonds in B2.
- **C:** 2 pts identification (naming the actual defect, not just "this looks wrong") + 2 pts a working fix.
- **D:** Query/procedure runs against a freshly seeded `TaskFlowDb` with no errors; deterministic; correctly schema-qualified; the specific rubric bullets in Notes.md §D are all satisfied.
- **E:** Reasoning is concrete and ordered (E2 specifically must show *process*, not just a guessed final answer) — vague "check the indexes" answers lose marks even if eventually correct.
- **F:** Eight checks, each naming a specific query/DMV/code pattern and a stated "good" criterion — generic checks ("review the code") do not count.

---

## Submission

Place answers under `PracticeProblemsSolutions/` (see Notes.md for the exact tree). Tell me **"check"** when ready.
