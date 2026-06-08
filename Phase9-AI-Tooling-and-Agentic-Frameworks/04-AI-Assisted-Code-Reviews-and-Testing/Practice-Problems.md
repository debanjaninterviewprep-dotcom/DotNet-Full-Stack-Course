# Practice Problems — AI-Assisted Code Reviews & Testing

> Tell me **"check"** after finishing.

---

## P1 — PR Template + Path-Scoped Review Instructions

**Goal:** Make every TaskFlow PR forced into a review-friendly shape.

**Tasks:**
1. Author `.github/PULL_REQUEST_TEMPLATE.md` with sections: Change, Why, Risk checkboxes, Tests, Reviewer focus.
2. Author `.github/copilot-instructions.md` (or extend the one from Topic 1) with global review rules.
3. Author **two** path-scoped instruction files in `.github/instructions/`:
   - `controllers.instructions.md` (`applyTo: "**/*Controller.cs"`).
   - `migrations.instructions.md` (`applyTo: "**/*Migration*.cs"`).

**Deliverable:** the three files committed under `.github/`.

**Look-fors:** Rules are concrete and testable; `applyTo` globs correct; no overlap conflicts.

---

## P2 — Generate, Mutate, Iterate

**Goal:** Show that AI-generated tests actually catch bugs.

**Tasks:**
1. Pick a real-ish service: `ProgressCalculator.Compute(IEnumerable<TaskItem>)` (returns int 0–100).
2. Implement the SUT with at least one subtle bug pattern (off-by-one or division boundary).
3. Use Copilot to plan test cases (no code yet) — save the plan.
4. Generate tests one bullet at a time.
5. Run Stryker (`dotnet stryker`); record initial mutation score.
6. Add one test per surviving mutant until score ≥ 80%.
7. Capture the journey.

**Deliverable:** SUT + tests + `journey.md` (planned cases, stryker before/after, what mutants required hand-written tests).

**Look-fors:** Mutation score rose meaningfully; you can show at least one bug found post-generation.

---

## P3 — Property-Based Test Set

**Goal:** Express domain invariants as properties.

**Tasks:**
1. Pick a pure function (e.g., `Schedule.Merge(existing, incoming)` returning a merged schedule).
2. With Copilot, enumerate 6+ invariants ("merging the same item twice is idempotent", "result preserves order", etc.).
3. Implement each as an FsCheck `[Property]` test.
4. Find at least one counter-example, fix the SUT, re-run.

**Deliverable:** Test file + a short note describing the counter-example and the fix.

**Look-fors:** Invariants are non-trivial; counter-example is real, not contrived.

---

## P4 — E2E with Playwright + AI

**Goal:** Write a stable e2e test with AI assistance.

**Tasks:**
1. With `npx playwright codegen`, record: "user logs in, creates project, drags task to Done, sees progress = 100%".
2. Hand the recording to Copilot Chat: "Refactor this for stability. Use only `data-testid` selectors. Add explicit waits. Use the existing PageObject pattern in `tests/e2e/pages`."
3. Verify it runs locally and on CI 5 times in a row without flake.

**Deliverable:** the polished spec + 5 green CI runs.

**Look-fors:** Selectors stable; explicit waits; PageObjects respected; no CSS-class selectors.

---

## P5 — Reviewing a Bad PR

**Goal:** Show you can spot what AI review will miss.

**Tasks:**
1. Open the bad PR snippet below.
2. Use Copilot Code Review (or chat) to review it — paste its comments into `ai-review.md`.
3. Then do a **human** review: list the issues AI missed in `human-review.md`. Aim for at least 4.

```csharp
[HttpPost("transfer")]
public async Task<IActionResult> Transfer(TransferDto dto)
{
    var from = await _db.Accounts.FindAsync(dto.FromId);
    var to   = await _db.Accounts.FindAsync(dto.ToId);
    from.Balance -= dto.Amount;
    to.Balance   += dto.Amount;
    await _db.SaveChangesAsync();
    return Ok();
}
```

**Deliverable:** `ai-review.md`, `human-review.md`, a `fixed.cs` showing the corrected controller.

**Look-fors:** You spotted: missing auth, missing validation, missing transaction, race conditions, missing logging, missing currency/precision considerations.

---

## P6 — Test-Data Generator with Domain Rules

**Goal:** Build a Bogus-based generator AI helped tune.

**Tasks:**
1. Build a `ProjectFaker` that generates valid `Project` entities (tasks have `DueDate > Project.StartDate`, status distribution roughly matches your real data).
2. Use AI to suggest 3 additional invariants and bake them in.
3. Generate 10,000 rows; pass them all through your real validators; assert 100% accept.

**Deliverable:** Generator code + a small report on pass rate and any failures discovered.

**Look-fors:** Generator is *correct by construction* — failing rows aren't post-filtered.

---

## P7 — Measurement Plan

**Goal:** Define how the team will tell if AI review/testing is paying off in 90 days.

**Tasks:** In `measurement-plan.md` cover:
- Metrics chosen (≤ 5): reviewer median time, defect escape rate, mutation score, test count, PR cycle time.
- Baselines (with date).
- How each is captured (script / dashboard / GH Insights).
- Decision criteria for keep / change / drop.

**Deliverable:** `measurement-plan.md`.

**Look-fors:** Honest, measurable, names the confounders.

---

## Scoring Rubric

| # | Pts | Full marks |
|---|---|---|
| P1 | 10 | Rules concrete; path globs correct |
| P2 | 20 | Mutation score rose; bug found via process |
| P3 | 15 | Real counter-example; non-trivial properties |
| P4 | 15 | 5 green runs; selectors stable |
| P5 | 15 | Missing-issue list is substantial |
| P6 | 10 | Correct-by-construction; 100% accept |
| P7 | 15 | Measurable; confounders named |

Total: 100. Pass: 70.
