# Topic 1: GitHub Copilot for Development

## What You'll Learn

How to use GitHub Copilot as a **leverage tool** — not a code generator. Practical patterns, prompting, governance, security, and measurement. By the end, you can use Copilot in your daily .NET + Angular workflow without producing brittle, insecure, or hallucinated code.

---

## 1. The Copilot Product Family — Get the Names Right

| Surface | What it is | Where it runs | When to use |
|---|---|---|---|
| **Copilot Code Completion** (formerly "Copilot") | Inline ghost-text suggestions as you type | IDE (VS, VS Code, Rider, Neovim, JetBrains) | Tight loops: line-by-line writing |
| **Copilot Chat** | Conversational AI inside IDE/web | IDE sidebar, GitHub.com | Asking, explaining, refactoring chunks |
| **Copilot Edits / Agent Mode** (VS Code) | Multi-file edits driven by a goal | VS Code | Cross-file refactors, scaffolding |
| **Copilot Workspace** | Plan → spec → implementation, browser-based | github.com/copilot | Starting from an issue |
| **Copilot Coding Agent** | Asynchronous agent that opens PRs | GitHub Actions runner | Well-scoped, low-risk issues |
| **Copilot CLI** | `gh copilot suggest`, `gh copilot explain` | Terminal | Shell one-liners |
| **Copilot for Pull Requests** | PR summaries, review suggestions | github.com PR page | Reviewing or authoring PRs |
| **Copilot in Windows Terminal** | Terminal command help | Windows Terminal | OS commands |

> Important separation: **GitHub Copilot** ≠ **Microsoft 365 Copilot**. M365 Copilot lives in Word/Excel/Teams over your Graph data — covered in Topic 2. Don't conflate them on resumes or in design docs.

### Licensing Tiers (mid-2026)

- **Copilot Free** — limited completions/chats per month, no enterprise controls.
- **Copilot Pro** — individual paid; access to multiple models (GPT, Claude, Gemini).
- **Copilot Business** — org-level controls, IP indemnification, no training on your code.
- **Copilot Enterprise** — adds custom knowledge bases, fine-tuned models, custom instructions org-wide, Copilot Workspace, Coding Agent included.

A Business+ license disables training on your code by default. That's the only tier acceptable for any commercial codebase you don't own.

---

## 2. How the Suggestion Engine Actually Works

A simplified mental model — useful for predicting when Copilot will be **wrong**.

```
                 ┌────────────────────────────┐
file context →   │ Prompt assembler           │
selection →      │  (~thousands of tokens)    │
chat history →   │                            │
neighboring →    │                            │
  open files     └──────────┬─────────────────┘
                            ▼
                   ┌────────────────┐
                   │ Foundation     │  GPT-4o / Claude / o-series, etc.
                   │ model          │
                   └──────────┬─────┘
                              ▼
                   ┌─────────────────────┐
                   │ Post-processing     │  policy filter, public-code detection,
                   │ + diff merge        │  IP filter (Business+)
                   └──────────┬──────────┘
                              ▼
                       suggestion shown
```

Implications:

1. **It only sees what's in the prompt.** Variables defined in a non-open file? The model is guessing. Open the file or quote the relevant snippet in chat.
2. **Larger code context wins.** Keep relevant files open. Close noisy ones.
3. **The model is stateless across requests.** Chat history is re-sent each turn; long sessions silently drop the start.
4. **Different models behave differently.** Switch models when one consistently gives bad results — Claude is often stronger for refactors, GPT-class for new code.
5. **Public-code filter** (Business+) blocks suggestions matching public code verbatim ≥ ~150 chars. It does **not** stop the model from regurgitating algorithmic patterns or near-duplicates.

---

## 3. The Four Modes of Use

Each has a different "shape" of prompt and a different failure mode.

### Mode 1 — Inline Completion (ghost text)

Best for: filling in obvious next lines, boilerplate, test cases that mirror an existing one.

**Pattern: prime with a comment.**
```csharp
// Returns the project's progress percentage (0-100) as int.
// Throws ArgumentNullException if project is null.
// Returns 0 if project has no tasks.
public int CalculateProgress(Project project)
{
    // ghost text fills in
}
```

The comment is doing 80% of the work. Without it you get a guess; with it you get an implementation aligned to your contract.

**Failure mode:** Copilot autocompletes confidently into the **wrong API** when you have multiple similarly named methods. Always read the suggestion before pressing Tab.

### Mode 2 — Chat (sidebar)

Best for: refactoring a selection, explaining unfamiliar code, generating a focused chunk.

**Pattern: "Role + Task + Constraints + Style"**
```
You are a senior .NET developer.
Refactor the selected method to:
  - Use IAsyncEnumerable<Project>.
  - Cancel via CancellationToken.
  - Avoid allocating intermediate List<>.
Match the existing code style (file-scoped namespaces, no `var` for primitives).
Return only the new method body.
```

**Slash commands** (VS Code):
- `/explain` — what does this do?
- `/fix` — fix the diagnostic
- `/tests` — generate tests
- `/doc` — add XML doc
- `/new` — scaffold a new file/project

**Failure mode:** asking for "the best way to X" — model invents an answer to match the question. Anchor it: "Given **this file** and **these constraints**, what's the best approach?"

### Mode 3 — Edits / Agent Mode

Best for: changes spanning 2–10 files where you can describe the goal cleanly.

**Pattern: spec-first.** Write a `CHANGE.md` (or a chat message) like:
```
GOAL: Add soft-delete to Projects.

CHANGES:
  - Project entity: add IsDeleted (bool, default false), DeletedAt (DateTime?, nullable).
  - DbContext: add HasQueryFilter excluding soft-deleted.
  - ProjectsService.DeleteAsync: set flags instead of removing.
  - ProjectsController: keep contract (204 on delete).
  - EF migration named "AddProjectSoftDelete".
  - Update existing unit tests that assert hard-delete.

CONSTRAINTS:
  - No breaking API changes.
  - Existing repository pattern preserved.
  - Use ApplicationDbContext convention; do not introduce a new context.
```

Submit. Review each proposed file diff. **Reject** the ones you didn't ask for (it will often "improve" unrelated code). Accept the rest. Run tests.

**Failure mode:** scope creep — the agent edits 14 files when you asked about 4. Use small, atomic specs and reject extras.

### Mode 4 — Coding Agent (asynchronous PR)

Best for: issues that are well-described, low-risk, isolated.

**Good fits:**
- Dependency bumps with test runs.
- Doc-string completions across a module.
- Adding a missing test file for an existing class.
- Migrating one file from `var` to explicit types per a style change.

**Bad fits:**
- Architectural changes.
- Anything touching security, auth, billing, schema migrations.
- Issues with vague acceptance criteria.

Pattern: write the issue like you'd write a PR description. Include "Done when" checklist. Assign to Copilot. Review the PR like any human PR — extra scrutiny because the author can't push back.

---

## 4. Custom Instructions — The Single Biggest Win

`.github/copilot-instructions.md` is loaded into every Copilot Chat session for that repo. This is the **lever** that turns Copilot from a generic generator into a project-aware collaborator.

A solid `copilot-instructions.md`:

```markdown
# Project: TaskFlow

## Stack
- .NET 8, C# 12, nullable enabled.
- Angular 18 standalone components, reactive forms.
- EF Core 8 with SQL Server. Repository pattern + Unit of Work.
- xUnit + FluentAssertions + Moq.
- Serilog → App Insights via OpenTelemetry.

## Conventions
- File-scoped namespaces.
- `record` for DTOs, `class` for entities.
- Async suffix on all async methods.
- `IServiceCollection.AddTaskFlow*()` extension methods for DI registration.
- All public APIs documented with `<summary>`.
- No `var` for built-in primitives.

## What NOT to do
- Do not add NewtonsoftJson — System.Text.Json only.
- Do not introduce MediatR; we use a service layer.
- Do not silently catch exceptions.
- Do not add `// TODO` comments — open an issue instead.

## When generating code
- Always add at least one xUnit test in the matching Tests project.
- Always wire new services through DI; never `new`.
- Always use structured logging with templates, never string interpolation.
```

Copilot Enterprise adds **knowledge bases** — point Copilot at a curated set of repos / docs and chat answers reference them. Use for architecture docs, ADRs, runbooks.

There are also **path-specific** instructions in newer VS Code via `.github/instructions/*.instructions.md` with `applyTo:` globs — e.g., apply Angular conventions only to `**/*.ts`.

---

## 5. Prompt Patterns That Work for Code

### 5.1 The Spec Sandwich
```
CONTEXT:
  - Selected code is a CSV importer used in the nightly job.
TASK:
  - Convert it to async streaming.
CONSTRAINTS:
  - Public signature must stay the same.
  - Memory must stay flat regardless of file size.
DELIVERABLE:
  - The new method + a one-line summary of the perf change.
```

### 5.2 Explain → Modify
```
First, explain the selected method in 3 bullet points.
Then, propose a refactor that removes the nested for-loop.
Wait for me to confirm before writing code.
```
Forces a checkpoint so you don't get a 200-line patch you didn't sign off on.

### 5.3 Translate
```
Convert this xUnit test to use FluentAssertions.
Keep the test name and the arrange phase identical.
```
Translation prompts have the lowest hallucination rate — useful for migrations.

### 5.4 Checklist Generation
```
For the selected service, list the unit test cases I should have, grouped by:
  - happy path
  - validation failures
  - dependency failures
Don't write code yet.
```
Use Copilot to **plan**, then write the tests yourself or with a follow-up prompt.

### 5.5 Anchor to Docs
```
Using this doc: https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis
write a minimal API for /projects with GET / GET{id} / POST / PUT / DELETE.
```
The model fetches/uses recent docs and is less likely to invent old APIs.

### 5.6 Counter-Example Prompt
```
What edge cases will break the selected function?
Pick the three most likely failures and write a failing test for each.
```
Forces it into adversarial mode.

---

## 6. Testing with Copilot

A test-generation workflow that actually works:

1. **Plan first.** Ask Copilot for a *list* of test cases (no code).
2. **Approve / trim the list.** Delete the ones that don't add value.
3. **Generate one test at a time.** Use `/tests` on the SUT with a single bullet from the approved list.
4. **Run.** Don't trust the result if it passes — read the assertion. Copilot loves asserting that `result != null` and calling it done.
5. **Mutate.** Change the production code to break the test. If the test still passes, it's worthless.

For .NET projects, give Copilot context:
- Open the SUT.
- Open one existing test file as a style reference.
- In chat: "Follow the existing test style in `ProjectsServiceTests`."

---

## 7. Refactoring with Copilot

Three refactor archetypes:

### Archetype A — Local refactor (one method)
- Select method → `/fix` or chat: "Extract the validation block into a private method."
- Diff is small, review takes seconds.

### Archetype B — File-scoped refactor
- Edits mode. Goal: "Convert this controller from sync to async. Keep route signatures."
- Review diff, run tests.

### Archetype C — Cross-cutting refactor
- Spec-first markdown (see Mode 3).
- Edits mode or Coding Agent.
- Expect 2–3 review iterations.

**Anti-pattern:** asking Copilot to "improve this class". Vague = invented improvements = bug surface. Always state the *change axis*: performance, readability, testability, allocation, async, nullability.

---

## 8. Security Considerations

### What Copilot can leak (or expose)

- **Prompt content goes to the model provider.** Don't paste production secrets into chat. Even Business+ tier transmits prompts.
- **Auto-completed secrets.** Copilot won't suggest random secrets — but it will happily complete `var apiKey = "sk-...";` if you start typing one.
- **License contamination.** Public-code filter reduces but doesn't eliminate copy-from-OSS risk. For licensed/dual-licensed code, audit suggestions.

### What Copilot can generate (badly)

Empirically common vulnerabilities in Copilot output:
- **SQL injection** when generating ad-hoc queries — always insist on parameterised queries or EF Core LINQ.
- **Path traversal** in file-handling code.
- **Hard-coded crypto parameters** (IVs of zero, ECB mode).
- **Authn/authz holes** — generated controllers often skip `[Authorize]`.
- **Outdated APIs** — old SDK versions with known CVEs.

### Guardrails

1. SAST + secret scanning in CI on every PR, including Copilot-authored ones.
2. Mandatory human review of all PRs (Copilot or human).
3. `copilot-instructions.md` lists "what NOT to do" for security.
4. Block specific suggestions org-wide via content exclusions (Business+).
5. Pin model where stability matters; experiment with newer models in a sandbox.

---

## 9. Measuring Value

If you're justifying Copilot to leadership, use a small set of measurable signals — not vibes.

| Signal | How to measure | Trap |
|---|---|---|
| Acceptance rate | % suggestions accepted (Copilot dashboard) | High acceptance ≠ quality |
| Cycle time | PR open → merge time before/after rollout | Confounded by load |
| PR size | Lines per PR before/after | Bigger PRs may signal slop |
| Defect rate | Bugs / KLOC over 90 days | Lagging indicator |
| Developer survey | Quarterly DX survey, single question | Sentiment, not productivity |

A reasonable framing: "Copilot is plumbing; it should make small tasks faster and bigger tasks slightly safer. We expect a 10–25% cycle-time improvement and no quality regression."

---

## 10. Anti-Patterns (Learned the Hard Way)

| Anti-pattern | Why it's bad | Better |
|---|---|---|
| "Write me a full microservice." | Output is plausible but unmoored; nothing fits. | Generate file-by-file with anchoring. |
| Accepting suggestions without reading | Bug factory. | Read every Tab press. |
| Long chat sessions | Context window saturates; old detail drops silently. | New chat per task. |
| Generating tests after the code | Tests confirm the code, not the spec. | Plan tests first or use TDD-style prompts. |
| Using free model in commercial repos | Training opt-out unclear; IP indemnification doesn't apply. | Business+ tier. |
| Pasting customer data into chat | Privacy/regulatory issue. | Synthetic samples. |
| Letting Copilot name things | Inconsistent naming across the codebase. | Provide naming conventions in instructions. |
| "Make this better" prompts | Invented improvements. | State the change axis. |
| Disabling tests "because Copilot said they're flaky" | Hides real bugs. | Investigate flakiness for real. |

---

## 11. Daily Workflow (Suggested)

Morning:
- Open the issue / ticket. Read the acceptance criteria.
- Open the relevant files. Close noise.
- `copilot-instructions.md` is up to date? If not, fix it first.

During the work:
- Inline completion for typing speed.
- Chat for refactors and explanations.
- Edits mode for multi-file changes.
- Run tests every few suggestions, not after a big batch.

PR time:
- Use Copilot to draft the PR description from the diff.
- Review every line before pushing. Reviewer is you, not the model.

End of day:
- If a chat session produced a useful pattern, add it to `copilot-instructions.md` so the team gets it tomorrow.

---

## Mental Model

> Copilot is a confident junior engineer with infinite memory of public code, no memory of your codebase, no judgement, and a strong urge to please. Treat its output the way you'd treat a junior's PR: read every line, ask "why this approach?", and never merge without tests.

Move to [Practice Problems](./Practice-Problems.md).
