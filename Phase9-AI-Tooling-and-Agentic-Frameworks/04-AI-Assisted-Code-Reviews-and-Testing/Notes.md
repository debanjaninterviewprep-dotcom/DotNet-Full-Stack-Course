# Topic 4: AI-Assisted Code Reviews & Testing

## What You'll Learn

How to use AI tooling to make code reviews **faster and tighter** and tests **deeper and less brittle** — without surrendering judgement to the model. Concrete workflows for GitHub Copilot for PRs, Copilot Code Review, AI-generated unit/integration/property/mutation tests, and AI-assisted test data generation.

---

## 1. The Problem AI is Solving in Reviews & Tests

Code review and testing both suffer from the same tax:

- Reviews skim; subtle bugs slip past tired humans.
- Tests assert the easy cases; the hard branches go untested.
- Both compete with feature work for time.

AI doesn't replace either. It changes the **shape of the work**:
- Reviews: AI surfaces the boring stuff (style, obvious bugs, missing docs) so humans spend time on architecture and intent.
- Tests: AI proposes the test cases you'd forget; you keep the judgement about which matter.

> Rule: *AI assists the reviewer; the reviewer is still accountable.* The PR author and reviewer's names are on the merge — not the model's.

---

## 2. Surface Map — Where AI Plugs In

| Layer | Tool | What it does |
|---|---|---|
| PR description | Copilot for PRs | Drafts a summary from the diff |
| First-pass review | Copilot Code Review | Inline comments on style, bugs, security |
| Custom rules | `copilot-instructions.md` + custom review rules | Tailor what Copilot flags |
| Test generation | Copilot Chat `/tests`, Edits mode | Unit, integration, e2e scaffolds |
| Test refactor | Copilot Edits | Migrate test framework / convert sync to async |
| Mutation testing | Stryker.NET + AI assists | Finds tests that don't actually catch bugs |
| Property-based testing | FsCheck / CsCheck with AI-suggested properties | Find unexpected counter-examples |
| Test data | AI-generated fakers | Realistic synthetic data |
| Reviewer assignment | CODEOWNERS + Copilot suggestions | Right human gets the PR |
| Static analysis | CodeQL + Copilot Autofix | Suggested patches for security findings |

---

## 3. Copilot for PRs — Description, Review, and Suggested Changes

### 3.1 PR Description Generation

On any PR, click "Generate by Copilot". Output: a description that summarises file groups and key changes.

This is a **starting point**, not a finished PR description. Always add:
- **Why** the change is needed (Copilot can only see *what* changed).
- Links to issue / spec.
- Risks and rollout notes.
- Screenshots for UI changes.
- Database migration callouts.

### 3.2 Copilot Code Review

Two modes:
- **Single review**: trigger on a PR; Copilot leaves inline comments.
- **Automatic review**: configure repo / org to have Copilot auto-review every PR.

It catches:
- Off-by-one, null-deref, obvious logic bugs.
- Style drift from `copilot-instructions.md`.
- Missing tests for new public methods.
- Hardcoded secrets, weak crypto, SQL building.
- Outdated API usage.

It misses:
- Architectural problems.
- Intent mismatch (the change does X but the issue asked for Y).
- Subtle concurrency bugs.
- Security issues that require business context (e.g., this endpoint should require role X).

**Therefore** Copilot's review is one signal, not the gate. Human reviewer still required.

### 3.3 Custom Review Rules

Repo-scoped guidance via `.github/copilot-instructions.md` (covered in Topic 1) AND **path-scoped instructions** via `.github/instructions/*.instructions.md` with `applyTo:`:

```markdown
---
applyTo: "**/*Controller.cs"
---
# Controller review rules
- Every public action must have an HTTP verb attribute.
- Every action must have `[Authorize]` or an explicit `[AllowAnonymous]` comment justifying why.
- No business logic in controllers — delegate to a service.
- Return ProblemDetails for errors via the existing exception filter, not bespoke responses.
```

```markdown
---
applyTo: "**/*Migration*.cs"
---
# Migration review rules
- All ALTER TABLE additions must be additive in v1 (NULL-able) and backfilled separately.
- No data loss without explicit `IsDestructive = true` annotation.
- Down migration must exist.
```

These layer per file — a controller migration file would inherit both.

### 3.4 Acting on Suggested Changes

When Copilot proposes an edit:
1. Read the comment in full (not just the diff).
2. Check if it understood your **intent**, not just your code.
3. Apply with one click if obviously right; otherwise reply, "We do X because Y" — that becomes context for future reviews if you also fold the rule into `copilot-instructions.md`.

---

## 4. AI-Assisted Reviewer Workflow

A realistic, sustainable workflow:

```
Author                                Reviewer
------                                --------
1. Open PR (Copilot drafts desc.)     
2. Add why / risks / rollout
3. Push                              4. Copilot auto-reviews
                                     5. Author addresses Copilot's points (or replies)
                                     6. Human reviewer takes a *second* pass:
                                          - intent vs. diff
                                          - architecture / design
                                          - security / authz
                                          - performance hot paths
                                     7. Request changes / approve
8. Squash + merge
```

The win is in step 6: the human review is **shorter** because the noise is already filtered. Reviewer focus shifts from "is the indentation right?" to "is this the right design?"

Anti-pattern: humans rubber-stamping after Copilot review. Cure: PR template forces reviewer to answer one question explicitly ("design decision X / Y / Z — is this the right one?").

---

## 5. Generating Unit Tests with AI — Done Right

The "before AI" workflow:
- Write a test for the happy path.
- Skim for obvious edge cases.
- Commit.

The "with AI" workflow:
- Open the SUT.
- Ask Copilot for a **list** of test cases. No code.
- Trim / approve the list.
- Generate tests **one at a time**, each pinned to one bullet.
- Run; **mutate** the SUT; verify tests fail.

### Example prompt

```
For the selected method ScheduleService.CreateRecurring(...), list test cases I should have, grouped by:
  - happy path
  - input validation (each parameter)
  - business-rule edge cases (overlap, DST, leap-day, end-before-start)
  - dependency failures (repository throws, calendar service unreachable)
Don't write code yet.
```

Pick the ones that matter (often: 6–10 of 20 suggested). Then per bullet:

```
Write an xUnit test for the bullet: "DST transition during recurrence keeps wall-clock time stable".
- Use existing test style in ScheduleServiceTests.cs.
- Use FluentAssertions for assertions.
- Mock IRepository<ScheduleEntry> using Moq; verify SaveAsync was called once with the expected entry.
```

### The mutation rule

A test that doesn't catch a bug is overhead. After generating tests, **change one constant** in the SUT and re-run. If everything still passes, the new tests are decorative.

`Stryker.NET` automates this:

```bash
dotnet tool install -g dotnet-stryker
cd TaskFlow.Tests
dotnet stryker
```

Stryker mutates your production code (changes `>` to `>=`, replaces returns, removes statements) and reports which mutations your tests **failed to catch**. AI is great at proposing tests for the surviving mutants.

### What AI is bad at

- Picking up domain invariants you never told it about. ("A loan can never be in two states at once.")
- Catching subtle async bugs (race conditions, deadlocks).
- Writing meaningful integration tests against a real Postgres/Cosmos — it tends to mock too much.

Mitigation: write the **hard** tests yourself; let AI write the parameter-by-parameter validation tests and edge-case sweeps.

---

## 6. Integration & End-to-End Tests with AI

Generation patterns:

### Integration tests (service + real-ish dependency)

```
Generate an xUnit integration test using TestContainers for SQL Server.
- Spin up a fresh DB per test class.
- Apply EF migrations.
- Seed a project with two tasks.
- Call ProjectsService.GetProgressAsync; assert progress = 50.
- Use the existing TestcontainerFixture pattern in TaskFlow.Tests/Integration.
```

### Playwright e2e

```
Generate a Playwright test for: "User logs in, creates a project, drags a task to Done, sees progress = 100%".
- Selectors: data-testid attributes only.
- One assertion per action.
- Use the existing PageObjects in tests/e2e/pages.
```

Playwright pairs especially well with AI:
- `npx playwright codegen` records actions → AI cleans + parameterises.
- Selector suggestions tend to use stable test IDs when your codebase already uses them (Copilot mirrors).

E2E pitfalls:
- Tests slow → AI piles on more → suite times out. Cap e2e count; rely on integration for breadth.
- Brittle selectors. Enforce `data-testid` and reject CSS-class selectors in review.

---

## 7. Property-Based Testing with AI

For pure functions or domain rules, **property-based testing** finds bugs example-based tests can't.

The framework picks random inputs and tries to falsify a property you state.

```csharp
// FsCheck-style property
[Property]
public void Round_trip_serialization_preserves_object(Project project)
{
    var json = Serializer.Serialize(project);
    var back = Serializer.Deserialize<Project>(json);
    back.Should().BeEquivalentTo(project);
}
```

Where AI shines:
- Proposing *properties* you didn't think of. ("Adding a task increases progress by ≤ 100/totalTasks.")
- Generating realistic `Arbitrary<T>` shapes (custom generators).

Prompt:
```
For ProgressCalculator, list 8 invariants (laws) that should hold for any input. Then turn each into an FsCheck property test. Use existing arbitraries in TaskFlow.Tests/Arbitraries.
```

When the runner finds a counter-example, it shrinks it to the smallest reproducer — and AI is then useful for explaining *why* the example breaks the invariant.

---

## 8. Test Data Generation

Two flavours:

### Static / faker data
Use Bogus + AI-suggested rules:
```csharp
var projectFaker = new Faker<Project>()
    .RuleFor(p => p.Id,       f => f.Random.Guid().ToString())
    .RuleFor(p => p.Name,     f => f.Commerce.ProductName())
    .RuleFor(p => p.Owner,    f => f.Person.FullName)
    .RuleFor(p => p.Status,   f => f.PickRandom("green", "yellow", "red"))
    .RuleFor(p => p.Tasks,    f => Enumerable.Range(0, f.Random.Int(0, 12))
                                   .Select(_ => taskFaker.Generate()).ToList());
```

Ask AI for an additional rule that captures a tricky invariant (e.g., "Tasks DueDate > Project StartDate").

### Synthetic data for ML / scenario testing
Use a model to generate batches of realistic records, then sanity-check distributions. Beware:
- Bias amplification (model's notion of "name" skews to certain demographics).
- Schema drift (model invents fields).

Always **post-validate** synthetic data through your real validators.

---

## 9. Code Review Checklists Augmented by AI

A working pattern:

`.github/PULL_REQUEST_TEMPLATE.md`
```markdown
## Change
<!-- one-line summary -->

## Why
<!-- link issue / spec -->

## Risk
- [ ] Schema change?       [ ] No   [ ] Yes (migration attached)
- [ ] New external call?   [ ] No   [ ] Yes (retry/timeout configured)
- [ ] Auth / authz touch?  [ ] No   [ ] Yes (security review requested)
- [ ] Feature flag used?   [ ] No   [ ] Yes (flag name: ___)

## Tests
- [ ] Unit tests for new logic
- [ ] Integration tests if dependencies change
- [ ] Mutation testing run on new files (`dotnet stryker --since=main`)

## Reviewer focus
<!-- author signals what to look at hardest -->
```

Then `.github/instructions/pr-review.instructions.md`:
```markdown
---
applyTo: "**/*"
---
When reviewing a PR:
1. Compare diff against PR description "Change" + "Why". Flag if intent and diff don't match.
2. Verify all "Risk" boxes have a corresponding pattern in the code.
3. Verify Tests box claims match the actual test changes.
4. Don't bikeshed nullable; the codebase already enables nullable warnings.
```

This wires the human review template *and* the AI reviewer to focus on the same checklist.

---

## 10. CodeQL + Copilot Autofix

GitHub Advanced Security users get **Copilot Autofix** on CodeQL findings: the scan flags a vulnerability and Copilot proposes a one-click patch in the PR.

Workflow:
- CI runs CodeQL on every PR.
- Findings appear inline with severity.
- Each finding gets a Copilot Autofix suggestion.
- Author applies, edits, or dismisses with justification.

Caveats:
- Autofix is best at well-understood bug classes (path traversal, XSS, SQL injection patterns, weak crypto). Worse at logic bugs CodeQL flags through custom queries.
- Apply, then **re-run tests** — autofix can subtly change behaviour.
- Dismissals require justification text — that text becomes audit evidence.

---

## 11. Anti-Patterns

| Anti-pattern | Why it's bad | Better |
|---|---|---|
| Treating Copilot review as approval | Misses architecture / intent issues | Human reviewer still required |
| Generating tests for the *current* (buggy) behaviour | Locks in the bug | Plan tests against the spec, not the code |
| One huge prompt: "test everything" | Output shallow + redundant | Plan list → one test per prompt |
| No mutation testing | Tests look complete but catch nothing | Run Stryker on new files |
| Brittle e2e selectors from `codegen` | Tests break on every CSS change | Enforce data-testid; lint for it |
| Skipping the "why" in PR descriptions | Reviewers can't judge intent | PR template forces it |
| Hand-waving "AI reviewed it" | Accountability vacuum | Reviewer and author still named |
| Letting AI write tests during the PR that's adding the feature | Confirmation bias | Write tests at least partly first / TDD |
| Synthetic data without distribution check | Skewed training/results | Plot distributions; compare to real |

---

## 12. Measuring Whether This is Working

| Metric | Target | Watch out for |
|---|---|---|
| Reviewer median time | down 20–40% | Quality regression |
| Defect escape rate (bugs found post-merge) | flat or down | Easy bugs are not the only bugs |
| Test count growth | up | Mutation score should rise with it |
| Stryker mutation score | rising toward 70%+ | Coverage % is not enough |
| % PRs with AI suggestions applied | tracked, not optimised | Vanity if you optimise it |
| Time from PR open → first human comment | down | Author satisfaction |

---

## 13. Mental Model

> AI compresses the boring parts of review and testing. The judgement parts — intent, architecture, domain invariants, security trade-offs — still need humans. Use AI to widen *coverage*; use humans to deepen *insight*.

Move to [Practice Problems](./Practice-Problems.md).
