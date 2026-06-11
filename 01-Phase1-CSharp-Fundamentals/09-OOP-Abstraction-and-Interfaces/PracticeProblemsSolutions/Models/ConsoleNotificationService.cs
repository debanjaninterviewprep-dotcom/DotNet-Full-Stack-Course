class ConsoleNotificationService : INotificationService
{
    public void Send(string to, string subject, string body)
    {
        Console.WriteLine($"[Notification to: {to}] {subject} - {body}");
    }

    public void SendBulk(string[] recipients, string subject, string body)
    {
        foreach (var r in recipients)
            Send(r, subject, body);
    }
}
