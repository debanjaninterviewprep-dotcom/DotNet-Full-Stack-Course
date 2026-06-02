using Hangfire;
using TaskFlow.Topic09.Email;

namespace TaskFlow.Topic09.Jobs;

[Queue("emails")]
[AutomaticRetry(Attempts = 5)]
public sealed class SendWelcomeEmailJob
{
    private readonly IEmailSender _email;
    private readonly EmailTemplater _templates;
    // private readonly TaskFlowDbContext _db;  // P5: inject your DbContext

    public SendWelcomeEmailJob(IEmailSender email, EmailTemplater templates)
    {
        _email = email;
        _templates = templates;
    }

    // P5: must be idempotent — check User.WelcomeEmailSentAt, set after success.
    public async Task ExecuteAsync(Guid userId, CancellationToken ct)
    {
        // TODO P5: var user = await _db.Users.FindAsync(userId, ct);
        // if (user is null || user.WelcomeEmailSentAt is not null) return;

        var html = await _templates.RenderAsync("Welcome", new Dictionary<string, string>
        {
            ["name"] = "User",
            ["loginUrl"] = "https://localhost:5173/login",
        }, ct);

        await _email.SendAsync(new EmailMessage(
            To: "demo@taskflow.local",
            Subject: "Welcome to TaskFlow",
            Html: html), ct);

        // TODO P5: user.WelcomeEmailSentAt = DateTimeOffset.UtcNow; await _db.SaveChangesAsync(ct);
    }
}

[Queue("emails")]
[AutomaticRetry(Attempts = 3, OnAttemptsExceeded = AttemptsExceededAction.Delete)]
public sealed class DigestEmailJob
{
    private readonly ILogger<DigestEmailJob> _logger;
    public DigestEmailJob(ILogger<DigestEmailJob> logger) => _logger = logger;

    // P6: enumerate users with digest preference, enqueue per-user SendDigestEmail.
    public Task SendAllAsync(CancellationToken ct)
    {
        _logger.LogInformation("Daily digest tick @ {Now:O}", DateTimeOffset.UtcNow);
        return Task.CompletedTask;
    }
}

[Queue("default")]
[AutomaticRetry(Attempts = 3, OnAttemptsExceeded = AttemptsExceededAction.Delete)]
public sealed class CleanupJob
{
    private readonly ILogger<CleanupJob> _logger;
    public CleanupJob(ILogger<CleanupJob> logger) => _logger = logger;

    // P6: hard-delete soft-deleted tasks older than 30 days.
    public Task PurgeAsync(CancellationToken ct)
    {
        _logger.LogInformation("Cleanup tick @ {Now:O}", DateTimeOffset.UtcNow);
        return Task.CompletedTask;
    }
}
