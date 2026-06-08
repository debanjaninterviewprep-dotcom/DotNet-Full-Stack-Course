using Azure.Identity;
using Azure.Messaging.ServiceBus;

namespace TaskFlow.ServiceBus.Console.Commands;

public static class Consume
{
    public static async Task<int> RunAsync(string ns, string topic, string[] args)
    {
        if (args.Length < 1) { System.Console.Error.WriteLine("consume <subscription>"); return 1; }
        var sub = args[0];

        await using var client = new ServiceBusClient(ns, new DefaultAzureCredential());
        var processor = client.CreateProcessor(topic, sub, new ServiceBusProcessorOptions
        {
            AutoCompleteMessages = false,
            MaxConcurrentCalls = 4,
            PrefetchCount = 8,
        });

        processor.ProcessMessageAsync += async args =>
        {
            var body = args.Message.Body.ToString();
            System.Console.WriteLine($"[{sub}] {args.Message.MessageId} type={args.Message.ApplicationProperties.GetValueOrDefault("type")} body={body}");
            try
            {
                if (body.Contains("fail", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("payload contains 'fail'");
                await args.CompleteMessageAsync(args.Message);
            }
            catch (InvalidOperationException ex)
            {
                await args.DeadLetterMessageAsync(args.Message, "InvalidPayload", ex.Message);
            }
        };

        processor.ProcessErrorAsync += a =>
        {
            System.Console.Error.WriteLine($"ERR: {a.Exception.Message}");
            return Task.CompletedTask;
        };

        await processor.StartProcessingAsync();
        System.Console.WriteLine("Consuming. Ctrl+C to stop.");
        var tcs = new TaskCompletionSource();
        System.Console.CancelKeyPress += (_, e) => { e.Cancel = true; tcs.SetResult(); };
        await tcs.Task;
        await processor.StopProcessingAsync();
        return 0;
    }
}
