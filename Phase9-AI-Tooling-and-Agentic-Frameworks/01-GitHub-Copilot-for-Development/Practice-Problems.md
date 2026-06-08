# Practice Problems — GitHub Copilot for Development

> Tell me **"check"** after finishing for grading and feedback.

---

## P1 — Author a `copilot-instructions.md` for TaskFlow

**Goal:** Produce the file Copilot will load on every chat session for the repo.

**Tasks:**
1. Stack & version pinning.
2. Naming + style conventions (C# and TypeScript both).
3. Test conventions (xUnit + Jasmine).
4. Logging / error handling rules.
5. "Do not do" list (forbidden libraries, patterns).
6. PR / commit guidance.

**Deliverable:** `.github/copilot-instructions.md` of ≥ 60 lines, organised into sections.

**Look-fors:** Concrete (not "write clean code"); says "what NOT to do"; mentions security.

---

## P2 — Spec-first refactor

**Goal:** Convert `ProjectsService.GetAllAsync()` (sync, eager `.ToList()`) to `IAsyncEnumerable<Project>` using Copilot Edits mode.

**Tasks:**
1. Write a `SPEC.md` describing the goal, public-signature constraint, allocation constraint, and test impact.
2. Run Edits mode against the spec.
3. Reject any unrelated file changes.
4. Update + run unit tests.

**Deliverable:** `SPEC.md` + diff + test run output.

**Look-fors:** Spec ≤ 40 lines; agent stayed in scope; tests pass; allocation actually flat.

---

## P3 — Test plan, then tests

**Goal:** Use Copilot to *plan* tests for `InvoiceCalculator.ComputeTotal(...)` before generating any.

**Tasks:**
1. Chat prompt to enumerate test cases grouped: happy / validation / boundary / dependency failure.
2. Review the list; delete duplicates / low-value cases.
3. Generate one test at a time from the approved list.
4. Mutation-check: change one constant in the production code; ensure at least one test fails.

**Deliverable:** Approved test-case list, generated tests, mutation result.

**Look-fors:** At least one Copilot-generated test caught the mutation; tests use FluentAssertions consistently.

---

## P4 — Security-aware generation

**Goal:** Force Copilot to generate a **secure** version of three commonly insecure patterns.

For each, paste the insecure version and prompt Copilot to fix:
1. Ad-hoc string-concatenated SQL.
2. File download endpoint with user-supplied path.
3. JWT validation with `ValidateLifetime = false`.

**Tasks:**
- Initial prompt; capture the suggestion.
- Re-prompt with explicit security requirement; capture the new suggestion.
- Note the **difference**.

**Deliverable:** `security-comparison.md` with three before/after diffs and a 2–3 sentence reflection per case.

**Look-fors:** Demonstrates that prompting matters; correctly identifies remaining weaknesses.

---

## P5 — Coding Agent issue

**Goal:** Write an issue good enough for the Coding Agent to deliver a PR you'd merge.

**Tasks:**
1. Pick a real low-risk change: e.g., "Add XML doc comments to all public members in `Domain/Entities/`."
2. Write the issue: context, scope (paths affected), acceptance criteria as a checklist, out-of-scope notes.
3. Assign to Copilot. (Or simulate locally with Edits mode if no Enterprise license.)
4. Review the PR like you would a human's.

**Deliverable:** Issue body + PR diff + review comments.

**Look-fors:** Scope respected; acceptance criteria all met; no creep.

---

## P6 — Prompt-pattern catalogue

**Goal:** Build a small reusable prompt library for your team.

**Tasks:** Document 6 reusable prompts (one per pattern from §5 of the notes) with:
- When to use it.
- The exact template (with `{{placeholders}}`).
- An example invocation.
- The failure mode it avoids.

**Deliverable:** `prompts.md` in the repo's `/docs`.

**Look-fors:** Templates are reusable as-is; examples are domain-specific (TaskFlow).

---

## P7 — Measurement plan

**Goal:** Design how your team will know whether Copilot is paying off after 90 days.

**Tasks:** A one-page plan covering:
- Metrics chosen (≤ 5) and how each is captured.
- Baseline (current values, with date).
- Targets and acceptable noise.
- Survey question.
- Decision criteria for "renew", "extend trial", "drop".

**Deliverable:** `copilot-roi-plan.md`.

**Look-fors:** Measurable; not vanity metrics; honest about confounders.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 10 | Concrete, repo-specific, includes negatives |
| P2 | 15 | Spec tight; agent stayed in scope; perf actually flat |
| P3 | 15 | Mutation caught; tests readable |
| P4 | 15 | Demonstrates prompt-shaping power; flags residual risk |
| P5 | 15 | Scope respected; PR review-grade |
| P6 | 15 | Reusable templates; failure modes named |
| P7 | 15 | Measurable; honest about confounders |

Total: 100. Pass: 70.
