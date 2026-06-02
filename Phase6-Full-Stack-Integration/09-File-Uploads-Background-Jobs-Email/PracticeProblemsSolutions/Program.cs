using Hangfire;
using Hangfire.MemoryStorage;
using TaskFlow.Topic09.Email;
using TaskFlow.Topic09.Jobs;
using TaskFlow.Topic09.Storage;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// P2: storage abstraction — picks implementation by config.
var storageProvider = builder.Configuration["Storage:Provider"] ?? "Local";
if (string.Equals(storageProvider, "Azure", StringComparison.OrdinalIgnoreCase))
    builder.Services.AddSingleton<IFileStorage, AzureBlobStorage>();
else
    builder.Services.AddSingleton<IFileStorage, LocalDiskStorage>();

// P4: email — SMTP for dev (Mailpit), SendGrid for prod.
var emailProvider = builder.Configuration["Email:Provider"] ?? "Smtp";
if (string.Equals(emailProvider, "SendGrid", StringComparison.OrdinalIgnoreCase))
    builder.Services.AddSingleton<IEmailSender, SendGridEmailSender>();
else
    builder.Services.AddSingleton<IEmailSender, SmtpEmailSender>();

builder.Services.AddSingleton<EmailTemplater>();

// P3: Hangfire with in-memory storage for the scaffold.
// For production: AddSqlServerStorage(connectionString, ...) — see README.
builder.Services.AddHangfire(c => c
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseMemoryStorage());

builder.Services.AddHangfireServer(o =>
{
    o.WorkerCount = Math.Min(Environment.ProcessorCount * 2, 20);
    o.Queues = ["default", "scans", "emails"];
});

builder.Services.AddScoped<ScanFileJob>();
builder.Services.AddScoped<MakeThumbnailJob>();
builder.Services.AddScoped<SendWelcomeEmailJob>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// P3: dashboard with auth filter (replace AllowAllConnectionsFilter with admin check in prod).
app.UseHangfireDashboard("/hangfire", new Hangfire.DashboardOptions
{
    Authorization = [new AdminOnlyDashboardAuthorizationFilter()],
});

app.MapControllers();

// P6: register recurring jobs.
RecurringJob.AddOrUpdate<DigestEmailJob>(
    "daily-digest",
    j => j.SendAllAsync(CancellationToken.None),
    Cron.Daily(8));

RecurringJob.AddOrUpdate<CleanupJob>(
    "hourly-cleanup",
    j => j.PurgeAsync(CancellationToken.None),
    Cron.Hourly);

app.Run();

public partial class Program { }
