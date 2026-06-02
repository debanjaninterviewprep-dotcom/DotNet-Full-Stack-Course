using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace TaskFlow.Topic09.Email;

public sealed class SmtpEmailSender : IEmailSender
{
    private readonly IConfiguration _cfg;
    public SmtpEmailSender(IConfiguration cfg) => _cfg = cfg;

    public async Task SendAsync(EmailMessage message, CancellationToken ct)
    {
        var msg = new MimeMessage();
        msg.From.Add(MailboxAddress.Parse(_cfg["Email:From"] ?? "noreply@taskflow.local"));
        msg.To.Add(MailboxAddress.Parse(message.To));
        msg.Subject = message.Subject;

        var builder = new BodyBuilder { HtmlBody = message.Html, TextBody = message.Text };
        if (message.Attachments is not null)
        {
            foreach (var a in message.Attachments)
                builder.Attachments.Add(a.Filename, a.Content, ContentType.Parse(a.ContentType));
        }
        msg.Body = builder.ToMessageBody();

        using var client = new SmtpClient();
        var host = _cfg["Email:Smtp:Host"] ?? "localhost";
        var port = int.Parse(_cfg["Email:Smtp:Port"] ?? "1025");
        var user = _cfg["Email:Smtp:User"];
        var pass = _cfg["Email:Smtp:Pass"];

        await client.ConnectAsync(host, port, SecureSocketOptions.Auto, ct);
        if (!string.IsNullOrEmpty(user))
            await client.AuthenticateAsync(user, pass, ct);
        await client.SendAsync(msg, ct);
        await client.DisconnectAsync(true, ct);
    }
}
