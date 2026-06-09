using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace TaskFlow.Functions.QueueTriggers;

public record EmailMessage(string To, string Subject, string Body);

public class EmailDispatcher
{
    private readonly ILogger<EmailDispatcher> _log;

    public EmailDispatcher(ILogger<EmailDispatcher> log) => _log = log;

    [Function("EmailDispatcher")]
    public Task Run(
        [QueueTrigger("email-queue", Connection = "Storage")] string raw)
    {
        EmailMessage msg = JsonSerializer.Deserialize<EmailMessage>(raw,
            new JsonSerializerOptions(JsonSerializerDefaults.Web))
            ?? throw new InvalidOperationException("Empty message");

        if (string.IsNullOrWhiteSpace(msg.To))
            throw new InvalidOperationException("Missing 'to' address");

        _log.LogInformation("Pretending to send email to {to} subject '{subject}'", msg.To, msg.Subject);
        return Task.CompletedTask;
    }
}
