using Microsoft.Extensions.Configuration;
using TaskFlow.Storage.Console.Commands;

var config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: false)
    .AddEnvironmentVariables()
    .Build();

var account = config["Storage:AccountName"]
    ?? throw new InvalidOperationException("Storage:AccountName is required");

if (args.Length == 0)
{
    Console.WriteLine(@"Usage:
  upload <localFile> <taskId>
  download-link <blobPath>
  download <localOut> <blobPath>
  log-activity <userId> <type> <taskId> <jsonPayload>
  list-activity <userId> <take>
  enqueue <type> <payload>
  consume
");
    return 1;
}

var verb = args[0];
var rest = args.Skip(1).ToArray();
try
{
    return verb switch
    {
        "upload"          => await UploadCommand.RunAsync(account, rest),
        "download-link"   => await SasCommand.RunAsync(account, rest),
        "download"        => await DownloadCommand.RunAsync(account, rest),
        "log-activity"    => await ActivityCommands.LogAsync(account, rest),
        "list-activity"   => await ActivityCommands.ListAsync(account, rest),
        "enqueue"         => await QueueCommands.EnqueueAsync(account, rest),
        "consume"         => await QueueCommands.ConsumeAsync(account, rest),
        _                 => Fail($"Unknown verb: {verb}")
    };
}
catch (Exception ex)
{
    Console.Error.WriteLine($"ERROR: {ex.GetType().Name}: {ex.Message}");
    return 2;
}

static int Fail(string m) { Console.Error.WriteLine(m); return 1; }
