namespace TaskFlow.Topic09.Email;

// P4: stub — implement with the SendGrid SDK (SendGridClient.SendEmailAsync).
public sealed class SendGridEmailSender : IEmailSender
{
    public SendGridEmailSender(IConfiguration cfg)
    {
        // TODO P4: read cfg["Email:SendGrid:ApiKey"], construct SendGridClient.
    }

    public Task SendAsync(EmailMessage message, CancellationToken ct) =>
        throw new NotImplementedException("P4: implement SendGrid sender.");
}
