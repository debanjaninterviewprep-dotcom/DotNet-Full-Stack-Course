using Hangfire;

namespace TaskFlow.Topic09.Jobs;

[Queue("scans")]
public sealed class ScanFileJob
{
    private readonly ILogger<ScanFileJob> _logger;
    public ScanFileJob(ILogger<ScanFileJob> logger) => _logger = logger;

    // P3: replace with nClam / ClamAV / Defender. For the scaffold: log + simulate latency.
    public async Task ExecuteAsync(string storageKey, CancellationToken ct)
    {
        _logger.LogInformation("Scanning {Key}", storageKey);
        await Task.Delay(1_000, ct);
        _logger.LogInformation("Scan clean: {Key}", storageKey);
    }
}

[Queue("default")]
public sealed class MakeThumbnailJob
{
    private readonly ILogger<MakeThumbnailJob> _logger;
    public MakeThumbnailJob(ILogger<MakeThumbnailJob> logger) => _logger = logger;

    // P3: replace with SixLabors.ImageSharp resize.
    public async Task ExecuteAsync(string storageKey, CancellationToken ct)
    {
        _logger.LogInformation("Thumbnail for {Key}", storageKey);
        await Task.Delay(500, ct);
    }
}
