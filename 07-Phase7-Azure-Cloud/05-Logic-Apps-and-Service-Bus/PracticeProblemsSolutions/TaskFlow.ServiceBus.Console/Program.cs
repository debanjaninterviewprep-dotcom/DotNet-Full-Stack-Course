using Microsoft.Extensions.Configuration;
using TaskFlow.ServiceBus.Console.Commands;

var config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json")
    .AddEnvironmentVariables()
    .Build();

var ns = config["ServiceBus:Namespace"]!;
var topic = config["ServiceBus:Topic"]!;
var sessionQueue = config["ServiceBus:SessionQueue"]!;

if (args.Length == 0)
{
    System.Console.WriteLine(@"Usage:
  publish <type> <priority> <jsonPayload>
  consume <subscription>
  dlq-peek <subscription> [n]
  dlq-replay <subscription> <messageId>
  dlq-purge <subscription> --yes
  publish-user <userId> <action>
  consume-sessions
");
    return 1;
}

return args[0] switch
{
    "publish"           => await Publish.RunAsync(ns, topic, args[1..]),
    "consume"           => await Consume.RunAsync(ns, topic, args[1..]),
    "dlq-peek"          => await Dlq.PeekAsync(ns, topic, args[1..]),
    "dlq-replay"        => await Dlq.ReplayAsync(ns, topic, args[1..]),
    "dlq-purge"         => await Dlq.PurgeAsync(ns, topic, args[1..]),
    "publish-user"      => await Sessions.PublishAsync(ns, sessionQueue, args[1..]),
    "consume-sessions"  => await Sessions.ConsumeAsync(ns, sessionQueue),
    _                   => Fail("Unknown verb")
};

static int Fail(string m) { System.Console.Error.WriteLine(m); return 1; }
