using Azure.Data.Tables;
using Azure.Identity;

namespace TaskFlow.Storage.Console.Commands;

public static class ActivityCommands
{
    private const string TableName = "Activity";

    private static TableClient Client(string account) =>
        new(new Uri($"https://{account}.table.core.windows.net"),
            TableName, new DefaultAzureCredential());

    public static async Task<int> LogAsync(string account, string[] args)
    {
        if (args.Length < 4) { System.Console.Error.WriteLine("log-activity <userId> <type> <taskId> <jsonPayload>"); return 1; }
        var (userId, type, taskId, payload) = (args[0], args[1], args[2], args[3]);

        var c = Client(account);
        await c.CreateIfNotExistsAsync();

        var inv = (DateTime.MaxValue.Ticks - DateTime.UtcNow.Ticks).ToString("D19");
        var entity = new TableEntity(userId, $"inv-{inv}-{Guid.NewGuid():N}")
        {
            ["Type"] = type,
            ["TaskId"] = taskId,
            ["Payload"] = payload,
            ["At"] = DateTimeOffset.UtcNow,
        };
        await c.AddEntityAsync(entity);
        System.Console.WriteLine($"Logged: {entity.PartitionKey}/{entity.RowKey}");
        return 0;
    }

    public static async Task<int> ListAsync(string account, string[] args)
    {
        if (args.Length < 2) { System.Console.Error.WriteLine("list-activity <userId> <take>"); return 1; }
        var userId = args[0];
        var take = int.Parse(args[1]);

        var c = Client(account);
        var query = c.QueryAsync<TableEntity>(e => e.PartitionKey == userId, maxPerPage: take);

        int n = 0;
        await foreach (var e in query)
        {
            System.Console.WriteLine($"{e["At"]}  {e["Type"]}  task={e["TaskId"]}  rk={e.RowKey}");
            if (++n >= take) break;
        }
        return 0;
    }
}
