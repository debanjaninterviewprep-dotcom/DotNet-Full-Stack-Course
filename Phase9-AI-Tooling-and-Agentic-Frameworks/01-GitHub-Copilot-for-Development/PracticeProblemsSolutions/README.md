# Solutions — GitHub Copilot for Development

Drop your answers here using this structure:

```
PracticeProblemsSolutions/
├── README.md            (this file)
├── P1-copilot-instructions.md
├── P2-SPEC.md
├── P2-diff.patch
├── P3-test-plan.md
├── P3-tests/
├── P4-security-comparison.md
├── P5-issue.md
├── P5-pr-review.md
├── P6-prompts.md
└── P7-copilot-roi-plan.md
```

When done, tell me **"check"** and I will grade and give feedback.

---

## P1 Starter — `copilot-instructions.md` skeleton

```markdown
# Project: TaskFlow

## Stack
- .NET 8, C# 12, nullable enabled, file-scoped namespaces.
- Angular 18 standalone components, strict TS.
- EF Core 8 + SQL Server 2022.
- xUnit + FluentAssertions + Moq for unit tests.
- Jasmine + Karma for Angular unit tests.
- Serilog + OpenTelemetry exporting to Azure Monitor.

## C# conventions
- `record` for DTOs, `class` for entities, `readonly record struct` for value types.
- Async suffix on every async method.
- `IServiceCollection.AddTaskFlow*()` extension methods for DI.
- No `var` for built-in primitives (int, string, bool, etc.).
- Public APIs require `<summary>` XML docs.

## TypeScript / Angular conventions
- Standalone components only. No NgModules in new code.
- Reactive forms only. No template-driven forms.
- One component per file. Files in kebab-case.
- Strict null checks; no `any`.

## Testing
- Mirror folder structure: `Domain/Foo.cs` → `Domain.Tests/FooTests.cs`.
- xUnit `[Fact]` for single cases, `[Theory]` with `[InlineData]` for parameterised.
- Assert with FluentAssertions: `result.Should().Be(...)`.
- Mock only the boundary (IRepository, HttpClient via IHttpClientFactory).

## Logging & errors
- Structured logging with templates: `_logger.LogError(ex, "Charge failed for {CustomerId}", id);`.
- Never swallow exceptions. Re-throw with `throw;`, never `throw ex;`.
- No `Console.WriteLine` in production code.

## DO NOT
- Do not add Newtonsoft.Json — System.Text.Json only.
- Do not introduce MediatR — service layer pattern.
- Do not auto-generate controllers with `[AllowAnonymous]`.
- Do not build raw SQL strings — EF Core LINQ or parameterised queries only.
- Do not catch `Exception` without rethrow or logging.
- Do not add `// TODO` comments — open a tracked issue instead.

## When generating code
- Always add at least one xUnit test in the matching `*.Tests` project.
- Always wire new services through DI; never `new` a service.
- Always include `[Authorize]` on new controllers unless explicitly told otherwise.
```

## P2 Starter — `SPEC.md` skeleton

```markdown
GOAL
  Convert ProjectsService.GetAllAsync() from sync materialised list to async streaming.

PUBLIC API (UNCHANGED)
  Task<IReadOnlyList<Project>> GetAllAsync(CancellationToken ct)
    becomes
  IAsyncEnumerable<Project> GetAllAsync(CancellationToken ct)

CALLER UPDATES
  - ProjectsController.GetAll: stream response with `await foreach`.
  - ProjectsBackgroundJob: replace ToList() with foreach + batched processing.

CONSTRAINTS
  - No new dependencies.
  - Allocation must be flat regardless of row count (verify via dotnet-counters).
  - Cancellation must be honoured per row.

TEST IMPACT
  - Existing `Returns_All_Projects_Test` rewritten to consume IAsyncEnumerable.
  - Add `Honours_Cancellation_Test` using a CancellationTokenSource.

OUT OF SCOPE
  - Do not touch other repository methods.
  - Do not change persistence layer.
```

## P6 Starter — `prompts.md`

```markdown
# TaskFlow Prompt Library

## 1. Spec sandwich (refactor)
CONTEXT: {file or selection}
TASK: {single change axis}
CONSTRAINTS:
  - Public API unchanged
  - Test files updated
  - {project-specific constraint}
DELIVERABLE: {diff | full file | snippet}

## 2. Explain then modify
First, explain {selection} in 3 bullets.
Then, propose a refactor that {goal}.
Wait for me to confirm before writing code.

(... continue for the other 4 patterns)
```
