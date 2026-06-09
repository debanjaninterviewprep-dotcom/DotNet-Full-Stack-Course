var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var slot = Environment.GetEnvironmentVariable("WEBSITE_SLOT_NAME") ?? "local";
var version = typeof(Program).Assembly.GetName().Version?.ToString() ?? "dev";

app.MapGet("/", () => $"TaskFlow API stub — slot={slot}, version={version}");
app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    slot,
    version,
    machine = Environment.MachineName,
    timestamp = DateTimeOffset.UtcNow
}));

app.Run();
