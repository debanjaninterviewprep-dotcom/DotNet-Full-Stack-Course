using Azure.Identity;
using Azure.Messaging.ServiceBus;

namespace TaskFlow.ServiceBus.Console.Commands;

public static class Dlq
{
    private static ServiceBusClient Client(string ns) => new(ns, new DefaultAzureCredential());

    public static async Task<int> PeekAsync(string ns, string topic, string[] args)
    {
        if (args.Length < 1) { System.Console.Error.WriteLine("dlq-peek <subscription> [n]"); return 1; }
        var sub = args[0];
        var n = args.Length > 1 ? int.Parse(args[1]) : 10;

        await using var c = Client(ns);
        var receiver = c.CreateReceiver(topic, sub, new ServiceBusReceiverOptions
        {
            SubQueue = SubQueue.DeadLetter,
        });

        var msgs = await receiver.PeekMessagesAsync(n);
        foreach (var m in msgs)
        {
            System.Console.WriteLine($"  {m.MessageId} reason={m.DeadLetterReason} desc={m.DeadLetterErrorDescription}");
        }
        return 0;
    }

    public static async Task<int> ReplayAsync(string ns, string topic, string[] args)
    {
        if (args.Length < 2) { System.Console.Error.WriteLine("dlq-replay <subscription> <messageId>"); return 1; }
        var sub = args[0]; var id = args[1];

        await using var c = Client(ns);
        var receiver = c.CreateReceiver(topic, sub, new ServiceBusReceiverOptions { SubQueue = SubQueue.DeadLetter });
        var sender = c.CreateSender(topic);

        ServiceBusReceivedMessage? hit = null;
        while ((hit = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(2))) is not null)
        {
            if (hit.MessageId == id)
            {
                var copy = new ServiceBusMessage(hit.Body) { MessageId = hit.MessageId, ContentType = hit.ContentType };
                foreach (var kv in hit.ApplicationProperties) copy.ApplicationProperties[kv.Key] = kv.Value;
                await sender.SendMessageAsync(copy);
                await receiver.CompleteMessageAsync(hit);
                System.Console.WriteLine($"Replayed {id}");
                return 0;
            }
            await receiver.AbandonMessageAsync(hit);
        }
        System.Console.WriteLine($"Not found in DLQ: {id}");
        return 1;
    }

    public static async Task<int> PurgeAsync(string ns, string topic, string[] args)
    {
        if (args.Length < 1 || !args.Contains("--yes")) { System.Console.Error.WriteLine("dlq-purge <subscription> --yes"); return 1; }
        var sub = args[0];

        await using var c = Client(ns);
        var receiver = c.CreateReceiver(topic, sub, new ServiceBusReceiverOptions { SubQueue = SubQueue.DeadLetter });
        int n = 0;
        ServiceBusReceivedMessage? m;
        while ((m = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(2))) is not null)
        {
            await receiver.CompleteMessageAsync(m);
            n++;
        }
        System.Console.WriteLine($"Purged {n} message(s)");
        return 0;
    }
}
