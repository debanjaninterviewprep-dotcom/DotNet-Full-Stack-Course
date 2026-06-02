namespace TaskFlow.Topic09.Email;

public sealed record EmailAttachment(string Filename, string ContentType, byte[] Content);
public sealed record EmailMessage(
    string To,
    string Subject,
    string Html,
    string? Text = null,
    IReadOnlyList<EmailAttachment>? Attachments = null);

public interface IEmailSender
{
    Task SendAsync(EmailMessage message, CancellationToken ct);
}
