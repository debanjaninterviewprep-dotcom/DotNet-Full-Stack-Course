using System.Text.Json;
using Azure.Identity;
using Azure.Storage.Queues;
using Azure.Storage.Queues.Models;

namespace TaskFlow.Storage.Console.Commands;

public static class QueueCommands
{
    private const string QueueName = "work-queue";

    private static QueueClient Client(string account) =>
        new(new Uri($"https://{account}.queue.core.windows.net/{QueueName}"),
            new DefaultAzureCredential(),
            new QueueClientOptions { MessageEncoding = QueueMessageEncoding.Base64 });

    public static async Task<int> EnqueueAsync(string account, string[] args)
    {
        if (args.Length < 2) { System.Console.Error.WriteLine("enqueue <type> <payload>"); return 1; }
        var msg = JsonSerializer.Serialize(new { Type = args[0], Payload = args[1], At = DateTimeOffset.UtcNow });

        var q = Client(account);
        await q.CreateIfNotExistsAsync();
        await q.SendMessageAsync(msg);
        System.Console.WriteLine("Queued.");
        return 0;
    }

    public static async Task<int> ConsumeAsync(string account, string[] _)
    {
        var q = Client(account);
        await q.CreateIfNotExistsAsync();

        var seen = new HashSet<string>();
        QueueMessage[] msgs = await q.ReceiveMessagesAsync(maxMessages: 16, visibilityTimeout: TimeSpan.FromMinutes(1));

        if (msgs.Length == 0) { System.Console.WriteLine("No messages."); return 0; }

        foreach (var m in msgs)
        {
            if (!seen.Add(m.MessageId))
            {
                System.Console.WriteLine($"Skipping duplicate {m.MessageId}");
                continue;
            }
            try
            {
                var json = JsonSerializer.Deserialize<JsonElement>(m.Body.ToString());
                var type = json.GetProperty("Type").GetString();
                System.Console.WriteLine($"Processing {m.MessageId} type={type}");
                if (type == "fail") throw new InvalidOperationException("intentional");
                await q.DeleteMessageAsync(m.MessageId, m.PopReceipt);
            }
            catch (Exception ex)
            {
                System.Console.WriteLine($"  failed: {ex.Message}; will reappear (or move to poison after retries)");
            }
        }
        return 0;
    }
}
