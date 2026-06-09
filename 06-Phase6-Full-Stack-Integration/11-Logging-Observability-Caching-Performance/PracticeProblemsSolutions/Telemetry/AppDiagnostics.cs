using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace TaskFlow.Topic11.Telemetry;

// P2 + P3: a single home for ActivitySource + Meter + the custom instruments.
public sealed class AppDiagnostics
{
    public const string ActivitySourceName = "TaskFlow.Application";
    public const string MeterName = "TaskFlow.Application";

    public ActivitySource ActivitySource { get; } = new(ActivitySourceName, "1.0.0");
    public Meter Meter { get; } = new(MeterName, "1.0.0");

    public Counter<long> ProjectsCreated { get; }
    public Histogram<double> HandlerDurationMs { get; }

    public AppDiagnostics()
    {
        ProjectsCreated = Meter.CreateCounter<long>(
            name: "taskflow.projects.created.total",
            unit: "{projects}",
            description: "Number of projects created.");

        HandlerDurationMs = Meter.CreateHistogram<double>(
            name: "taskflow.handler.duration_ms",
            unit: "ms",
            description: "Application handler duration.");
    }
}
