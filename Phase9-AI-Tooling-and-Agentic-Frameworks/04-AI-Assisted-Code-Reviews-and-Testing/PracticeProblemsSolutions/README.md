# Solutions — AI-Assisted Code Reviews & Testing

Put your work here:

```
PracticeProblemsSolutions/
├── README.md
├── P1-github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── copilot-instructions.md
│   └── instructions/
│       ├── controllers.instructions.md
│       └── migrations.instructions.md
├── P2-progress-calculator/
│   ├── ProgressCalculator.cs
│   ├── ProgressCalculatorTests.cs
│   ├── stryker-config.json
│   ├── journey.md
│   └── stryker-report-after.html
├── P3-properties/
│   ├── ScheduleMergeTests.cs
│   └── counterexample-note.md
├── P4-e2e/
│   ├── tests/e2e/project-progress.spec.ts
│   └── ci-runs.md
├── P5-review/
│   ├── ai-review.md
│   ├── human-review.md
│   └── fixed.cs
├── P6-faker/
│   ├── ProjectFaker.cs
│   └── faker-run-report.md
└── P7-measurement-plan.md
```

Tell me **"check"** when done.

---

## P1 Starter — `controllers.instructions.md`

```markdown
---
applyTo: "**/*Controller.cs"
---
# Controller review rules
- Every public action has an HTTP verb attribute.
- Every action has `[Authorize]` or an explicit `[AllowAnonymous]` with a comment justifying it.
- No business logic in controllers — delegate to a service.
- Use ProblemDetails for errors via the existing exception filter.
- Validate inputs via FluentValidation; no inline null/range checks.
```

## P1 Starter — `migrations.instructions.md`

```markdown
---
applyTo: "**/*Migration*.cs"
---
# Migration review rules
- Additive only: new columns nullable in v1, backfilled by a separate job.
- No DROP COLUMN in the same release as code that wrote to it.
- Index changes annotated with rationale.
- Down migration provided and tested.
- Reject schema changes without an attached perf-impact note (size of table, RU/DTU expected impact).
```

## P2 Starter — `ProgressCalculator.cs` (subtle bug version)

```csharp
public static class ProgressCalculator
{
    public static int Compute(IEnumerable<TaskItem> tasks)
    {
        var list = tasks?.ToList() ?? throw new ArgumentNullException(nameof(tasks));
        if (list.Count == 0) return 0;
        var done = list.Count(t => t.Status == "done");
        return done * 100 / list.Count;        // integer division — round-trip loss
    }
}

public record TaskItem(string Id, string Status);
```

## P2 Starter — `stryker-config.json`

```json
{
  "stryker-config": {
    "test-projects": ["TaskFlow.Tests/TaskFlow.Tests.csproj"],
    "project": "TaskFlow/TaskFlow.csproj",
    "mutate": ["src/ProgressCalculator.cs"],
    "thresholds": { "high": 90, "low": 80, "break": 80 }
  }
}
```

## P5 Starter — `fixed.cs` skeleton

```csharp
[Authorize]
[HttpPost("transfer")]
public async Task<IActionResult> Transfer(TransferDto dto, CancellationToken ct)
{
    var validation = await _validator.ValidateAsync(dto, ct);
    if (!validation.IsValid) return ValidationProblem(validation.ToDictionary());

    if (dto.FromId == dto.ToId)
        return Problem("Source and destination must differ.", statusCode: 400);

    var userId = User.GetUserId();
    if (!await _authz.CanTransferFromAsync(userId, dto.FromId, ct))
        return Forbid();

    await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);

    var from = await _db.Accounts.FindAsync(new object[] { dto.FromId }, ct)
               ?? throw new EntityNotFoundException(nameof(Account), dto.FromId);
    var to   = await _db.Accounts.FindAsync(new object[] { dto.ToId }, ct)
               ?? throw new EntityNotFoundException(nameof(Account), dto.ToId);

    if (from.Currency != to.Currency)
        return Problem("Currency mismatch.", statusCode: 400);

    if (from.Balance < dto.Amount)
        return Problem("Insufficient funds.", statusCode: 400);

    from.Balance = decimal.Subtract(from.Balance, dto.Amount);
    to.Balance   = decimal.Add(to.Balance, dto.Amount);

    await _db.SaveChangesAsync(ct);
    await tx.CommitAsync(ct);

    _logger.LogInformation("Transfer completed {From} -> {To} {Amount} {Currency} by {User}",
        dto.FromId, dto.ToId, dto.Amount, from.Currency, userId);

    return NoContent();
}
```

## P6 Starter — `ProjectFaker.cs`

```csharp
using Bogus;

public static class ProjectFaker
{
    public static Faker<Project> Build()
    {
        var taskFaker = new Faker<TaskItem>()
            .RuleFor(t => t.Id,       f => f.Random.Guid().ToString())
            .RuleFor(t => t.Title,    f => f.Hacker.Phrase())
            .RuleFor(t => t.Status,   f => f.PickRandomWithout("done", "todo", "in_progress", "blocked"))
            .RuleFor(t => t.DueDate,  f => f.Date.Future(1));

        return new Faker<Project>()
            .RuleFor(p => p.Id,        f => $"TF-{f.Random.Number(1000, 9999)}")
            .RuleFor(p => p.Name,      f => f.Commerce.ProductName())
            .RuleFor(p => p.Owner,     f => f.Person.FullName)
            .RuleFor(p => p.StartDate, f => f.Date.Past(1))
            .RuleFor(p => p.Status,    f => f.PickRandom(new[] { "green", "yellow", "red" }))
            .RuleFor(p => p.Tasks, (f, p) => Enumerable.Range(0, f.Random.Int(0, 12))
                                                       .Select(_ => taskFaker.Generate())
                                                       .Select(t => t with { DueDate = f.Date.Between(p.StartDate.AddDays(1), p.StartDate.AddYears(1)) })
                                                       .ToList());
    }
}
```
