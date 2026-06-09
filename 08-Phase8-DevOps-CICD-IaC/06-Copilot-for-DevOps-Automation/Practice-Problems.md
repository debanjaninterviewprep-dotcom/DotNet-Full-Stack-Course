# Topic 6 — Practice Problems

> Solutions in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). Each problem produces a paired artifact: **the prompt(s) you used** + **the final reviewed output**.

---

## P1 — Repo-Level Copilot Instructions

**Goal:** Make Copilot generate code that matches your conventions.

**Tasks**
1. Write `.github/copilot-instructions.md` for `taskflow-infra` covering:
   - Tooling (Terraform 1.8+, AzureRM 4.x).
   - Naming convention.
   - Module layout.
   - Security defaults (no shared keys, TLS 1.2, MI over secrets).
   - GitHub Actions style (SHA-pinning, least privilege).
2. Add `.vscode/settings.json` enabling `github.copilot.chat.codeGeneration.useInstructionFiles = true` (or equivalent setting).
3. Write `P1-test-prompts.md` listing five prompts you tested **before and after** adding the instructions, with the diff in output.

**Deliverables**
- `.github/copilot-instructions.md`
- `P1-test-prompts.md`

**Look-fors**
- [ ] Instructions are specific and enforceable.
- [ ] Before/after comparison clearly shows the instructions influencing output.
- [ ] No vague rules like "use best practices".

---

## P2 — Generate a CI Workflow from a Spec

**Goal:** Prompt → reviewed → applied.

**Tasks**
1. Write a precise spec (15+ bullet points) for a .NET 8 CI workflow (see Topic 2 §4 for inspiration).
2. Generate the workflow via Copilot Chat. Save the **raw output** as `P2-raw.yml`.
3. Manually review and fix. Save the corrected version as `P2-final.yml`.
4. In `P2-review.md` list:
   - Each change you made.
   - Why (bug? security? convention?).
   - Whether updating the prompt would have prevented it.

**Deliverables**
- `P2-spec.md`
- `P2-raw.yml`, `P2-final.yml`
- `P2-review.md`

**Look-fors**
- [ ] At least three real fixes (not cosmetic).
- [ ] At least one update to your spec for next time.
- [ ] `P2-final.yml` runs cleanly.

---

## P3 — Translate ADO Pipeline → GitHub Actions

**Goal:** Use Copilot for tool translation.

**Tasks**
1. Take a non-trivial Azure Pipelines YAML (use Topic 2's `P4-azure-pipelines.yml` if needed).
2. Prompt Copilot to translate to GitHub Actions, preserving stages, caching, and approval gates.
3. Compare side-by-side; fix any mistranslations.
4. Document gotchas in `P3-translation-notes.md`:
   - Concepts that don't map 1:1 (deployment jobs, environments, etc.).
   - Idioms where Copilot was wrong.

**Deliverables**
- `P3-source.yml`, `P3-translated.yml`
- `P3-translation-notes.md`

**Look-fors**
- [ ] Both pipelines lint cleanly.
- [ ] Notes cite at least three real gotchas.
- [ ] Final translation actually preserves semantics (approvals, dependencies).

---

## P4 — Copilot-Assisted Triage

**Goal:** Use AI to speed up failure diagnosis without taking your eye off the ball.

**Tasks**
1. Take a failed CI run (real, or build one — failing test + flaky restore).
2. Use Copilot Chat with `@terminal /fix` and `@workspace /explain` to analyse.
3. Capture the conversation as `P4-conversation.md`.
4. In `P4-postmortem.md` answer:
   - What did Copilot get right?
   - What did it get wrong or miss?
   - How long did triage take versus your previous baseline?

**Deliverables**
- `P4-failure-log.txt`
- `P4-conversation.md`
- `P4-postmortem.md`

**Look-fors**
- [ ] Honest postmortem (no AI cheerleading).
- [ ] At least one identified weakness in Copilot's reasoning.

---

## P5 — Coding Agent for a Real Chore

**Goal:** Delegate a well-scoped DevOps ticket.

**Tasks**
1. Pick an actual chore: e.g., "Pin every GitHub Action in this repo by SHA" or "Add `permissions: contents: read` to every workflow missing it".
2. Open a GitHub issue describing the task precisely (acceptance criteria, scope, non-goals).
3. Assign to Copilot (Coding Agent).
4. Review the PR it produces.
5. Write `P5-agent-evaluation.md`:
   - Did it complete in scope?
   - How many lines did you change before merging?
   - Would you assign it a similar task again? Why / why not?

**Deliverables**
- Link/screenshot of issue + PR (or full text in `P5-issue-and-pr.md`).
- `P5-agent-evaluation.md`.

**Look-fors**
- [ ] Issue specifies acceptance criteria.
- [ ] PR was reviewed line-by-line.
- [ ] Honest evaluation (good and bad).

---

## P6 — Build a Prompt Library for the Team

**Goal:** Make AI assistance a team capability, not a personal skill.

**Tasks**
1. Create `P6-prompts/` with files for:
   - `generate-tf-module.md`
   - `add-coverage-gate.md`
   - `translate-bicep-to-tf.md`
   - `write-runbook-from-postmortem.md`
   - `review-iac-pr.md`
2. Each prompt file follows a template: **Goal**, **Inputs you must provide**, **Prompt text**, **Common pitfalls to fix in output**, **Example**.
3. Add a top-level `P6-README.md` indexing them.

**Deliverables**
- `P6-prompts/` directory.

**Look-fors**
- [ ] Prompts are reusable (no project-specific names hard-coded).
- [ ] Each lists at least two pitfalls.

---

## P7 (Stretch) — Measure It

**Goal:** Quantify Copilot's impact.

**Tasks**
For two weeks, log every Copilot-assisted task in a simple spreadsheet/csv:
- Task type (YAML, TF, script, doc, review).
- Time spent prompting.
- Time spent reviewing output.
- Whether you used the result (accepted / heavily edited / discarded).
- Defects later found.

Write `P7-measurement.md` summarising results + a recommendation: keep, change workflow, or shrink usage.

**Deliverables**
- `P7-log.csv`
- `P7-measurement.md`

**Look-fors**
- [ ] Real data, even if small N.
- [ ] Recommendation is supported by the data.

---

## Submission

Tell me **"check P2"** (or a range) for graded review.
