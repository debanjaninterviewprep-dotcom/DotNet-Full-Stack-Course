using Azure.Identity;
using Azure.Messaging.ServiceBus;

namespace TaskFlow.ServiceBus.Console.Commands;

public static class Sessions
{
    public static async Task<int> PublishAsync(string ns, string queue, string[] args)
    {
        if (args.Length < 2) { System.Console.Error.WriteLine("publish-user <userId> <action>"); return 1; }
        var (userId, action) = (args[0], args[1]);

        await using var c = new ServiceBusClient(ns, new DefaultAzureCredential());
        var sender = c.CreateSender(queue);

        await sender.SendMessageAsync(new ServiceBusMessage(action)
        {
            SessionId = userId,
            MessageId = Guid.NewGuid().ToString("N"),
        });
        System.Console.WriteLine($"Sent {action} for session {userId}");
        return 0;
    }

    public static async Task<int> ConsumeAsync(string ns, string queue)
    {
        await using var c = new ServiceBusClient(ns, new DefaultAzureCredential());
        var processor = c.CreateSessionProcessor(queue, new ServiceBusSessionProcessorOptions
        {
            MaxConcurrentSessions = 4,
            AutoCompleteMessages = false,
        });

        processor.ProcessMessageAsync += async args =>
        {
            System.Console.WriteLine($"[session={args.SessionId}] {args.Message.Body}");
            await args.CompleteMessageAsync(args.Message);
        };
        processor.ProcessErrorAsync += a => { System.Console.Error.WriteLine(a.Exception.Message); return Task.CompletedTask; };

        await processor.StartProcessingAsync();
        var tcs = new TaskCompletionSource();
        System.Console.CancelKeyPress += (_, e) => { e.Cancel = true; tcs.SetResult(); };
        await tcs.Task;
        await processor.StopProcessingAsync();
        return 0;
    }
}
