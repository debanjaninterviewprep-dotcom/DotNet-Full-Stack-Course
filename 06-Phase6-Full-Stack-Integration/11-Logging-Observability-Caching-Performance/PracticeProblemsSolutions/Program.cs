using System.Diagnostics;
using System.Diagnostics.Metrics;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;
using Serilog.Context;
using Serilog.Events;
using Serilog.Formatting.Compact;
using TaskFlow.Topic11.Telemetry;

// P1: bootstrap logger so startup errors are captured.
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console(new RenderedCompactJsonFormatter())
    .CreateBootstrapLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Host.UseSerilog((ctx, services, cfg) => cfg
        .ReadFrom.Configuration(ctx.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithProperty("App", "TaskFlow.Api.Topic11")
        .Enrich.WithProperty("Env", ctx.HostingEnvironment.EnvironmentName)
        .Destructure.ByTransforming<LoginRequest>(r => new { r.Email })   // strip Password
        .WriteTo.Console(new RenderedCompactJsonFormatter())
        .WriteTo.Seq(ctx.Configuration["Seq:Url"] ?? "http://localhost:5341"));

    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();

    // P4: HybridCache (memory + Redis) — Redis fallback to in-memory if not configured.
    var redis = builder.Configuration.GetConnectionString("Redis");
    if (!string.IsNullOrWhiteSpace(redis))
        builder.Services.AddStackExchangeRedisCache(o => o.Configuration = redis);
    builder.Services.AddHybridCache(o =>
    {
        o.DefaultEntryOptions = new()
        {
            LocalCacheExpiration = TimeSpan.FromMinutes(2),
            Expiration = TimeSpan.FromMinutes(15),
        };
    });

    // P5: response compression + output caching.
    builder.Services.AddResponseCompression(o =>
    {
        o.EnableForHttps = true;
        o.Providers.Add<Microsoft.AspNetCore.ResponseCompression.BrotliCompressionProvider>();
        o.Providers.Add<Microsoft.AspNetCore.ResponseCompression.GzipCompressionProvider>();
    });
    builder.Services.AddOutputCache(o =>
    {
        o.AddBasePolicy(b => b.Expire(TimeSpan.FromSeconds(30)));
        o.AddPolicy("Stats", b => b.Expire(TimeSpan.FromMinutes(5))
                                    .SetVaryByQuery("from", "to")
                                    .Tag("stats"));
    });

    // P2 + P3: OpenTelemetry traces + metrics.
    builder.Services.AddOpenTelemetry()
        .ConfigureResource(r => r.AddService("taskflow-api-topic11", serviceVersion: "1.0.0"))
        .WithTracing(t => t
            .AddAspNetCoreInstrumentation(o => o.Filter = ctx => !ctx.Request.Path.StartsWithSegments("/health"))
            .AddHttpClientInstrumentation()
            .AddSource(AppDiagnostics.ActivitySourceName)
            .SetSampler(new TraceIdRatioBasedSampler(0.1))
            .AddOtlpExporter())
        .WithMetrics(m => m
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddRuntimeInstrumentation()
            .AddMeter(AppDiagnostics.MeterName)
            .AddPrometheusExporter()
            .AddOtlpExporter());

    builder.Services.AddSingleton<AppDiagnostics>();

    // P5: Polly via standard resilience handler on outbound clients.
    builder.Services.AddHttpClient("billing")
        .AddStandardResilienceHandler();

    builder.Services.AddHealthChecks()
        .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(),
                  tags: ["live"]);

    var app = builder.Build();

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

    app.UseResponseCompression();

    // P1: correlation id middleware.
    app.Use(async (ctx, next) =>
    {
        var correlationId = ctx.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Activity.Current?.TraceId.ToString()
            ?? Guid.NewGuid().ToString("N");
        ctx.Response.Headers["X-Correlation-Id"] = correlationId;
        using (LogContext.PushProperty("CorrelationId", correlationId))
            await next();
    });

    app.UseSerilogRequestLogging(opts =>
    {
        opts.GetLevel = (http, elapsed, ex) =>
            ex is not null ? LogEventLevel.Error :
            http.Response.StatusCode > 499 ? LogEventLevel.Error :
            elapsed > 1500 ? LogEventLevel.Warning :
            LogEventLevel.Information;
        opts.EnrichDiagnosticContext = (diag, http) =>
        {
            diag.Set("ClientIp", http.Connection.RemoteIpAddress?.ToString());
        };
    });

    app.UseOutputCache();
    app.UseAuthorization();

    app.MapHealthChecks("/health/live", new() { Predicate = c => c.Tags.Contains("live") });
    app.MapPrometheusScrapingEndpoint();   // /metrics
    app.MapControllers();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Host terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

public sealed record LoginRequest(string Email, string Password);

public partial class Program { }
