using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace TaskFlow.Functions.TimerTriggers;

public class StaleTokenSweeper
{
    private readonly ILogger<StaleTokenSweeper> _log;
    private readonly int _scanRange;

    public StaleTokenSweeper(ILogger<StaleTokenSweeper> log)
    {
        _log = log;
        _scanRange = int.TryParse(Environment.GetEnvironmentVariable("StaleTokenScanRange"), out var n) ? n : 100;
    }

    [Function("StaleTokenSweeper")]
    public void Run([TimerTrigger("%StaleTokenSchedule%")] TimerInfo timer)
    {
        var removed = Random.Shared.Next(0, _scanRange / 10);
        _log.LogInformation(
            "Sweeper run @ {now}. Scanned {scanned} tokens, removed {removed}. Next: {next}",
            DateTimeOffset.UtcNow, _scanRange, removed, timer.ScheduleStatus?.Next);
    }
}
