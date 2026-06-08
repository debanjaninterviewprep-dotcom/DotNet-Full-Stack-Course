using Azure.Identity;
using Azure.Messaging.ServiceBus;

namespace TaskFlow.ServiceBus.Console.Commands;

public static class Publish
{
    public static async Task<int> RunAsync(string ns, string topic, string[] args)
    {
        if (args.Length < 3) { System.Console.Error.WriteLine("publish <type> <priority> <jsonPayload>"); return 1; }
        var (type, priority, body) = (args[0], int.Parse(args[1]), args[2]);

        await using var client = new ServiceBusClient(ns, new DefaultAzureCredential());
        var sender = client.CreateSender(topic);

        var msg = new ServiceBusMessage(body)
        {
            ContentType = "application/json",
            MessageId = Guid.NewGuid().ToString("N"),
            ApplicationProperties =
            {
                ["type"] = type,
                ["priority"] = priority,
                ["source"] = "api",
            },
        };
        await sender.SendMessageAsync(msg);
        System.Console.WriteLine($"Published {msg.MessageId} type={type} priority={priority}");
        return 0;
    }
}
