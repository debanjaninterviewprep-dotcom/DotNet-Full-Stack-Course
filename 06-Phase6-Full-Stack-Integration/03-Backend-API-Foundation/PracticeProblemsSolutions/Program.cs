// ===============================================================
//  Topic 3 - Backend API Foundation
//  PracticeProblemsSolutions starter
// ===============================================================
//
//  This file is the single-project starter. P1 asks you to split the
//  solution into Domain / Application / Infrastructure / Api projects.
//  Until you do that, treat this file as the stand-in "Api" project.
//
//  Run:  dotnet run
//  Then browse: https://localhost:7100/swagger
//
//  The TODO blocks below mirror the practice problems.

using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// === SERVICES ===========================================================
// TODO P3: extract these into AddTaskFlowApi / AddTaskFlowApplication /
//          AddTaskFlowInfrastructure extension methods (one per layer).

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// TODO P5: configure Swagger with JWT bearer + XML comments.
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TaskFlow API", Version = "v1" });
    // c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme { ... });
    // c.AddSecurityRequirement(new OpenApiSecurityRequirement { ... });
    // c.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, "PracticeProblems.xml"));
});

// TODO P2: bind JwtOptions with ValidateDataAnnotations + ValidateOnStart.
// builder.Services.AddOptions<JwtOptions>()
//     .Bind(builder.Configuration.GetSection(JwtOptions.SectionName))
//     .ValidateDataAnnotations()
//     .ValidateOnStart();

// TODO P4: configure Serilog from configuration + correlation-id middleware.
// builder.Host.UseSerilog((ctx, lc) => lc.ReadFrom.Configuration(ctx.Configuration));

// TODO P6: register DbContext + health checks (db, self, custom Redis).
// builder.Services.AddDbContext<TaskFlowDbContext>(o => o.UseSqlite("Data Source=topic03.db"));
// builder.Services.AddHealthChecks()
//     .AddDbContextCheck<TaskFlowDbContext>("db", tags: new[] { "ready" })
//     .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" });
//     // .AddCheck<RedisHealthCheck>("redis", tags: new[] { "ready" });

var app = builder.Build();

// === PIPELINE ===========================================================
// TODO P3: add UseExceptionHandler / ProblemDetails / Authentication /
//          Authorization once those topics arrive.

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// TODO P4: app.UseSerilogRequestLogging(...);
// TODO P4: app.Use(async (ctx, next) => { /* X-Correlation-Id */ await next(); });

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// TODO P6: map /health/live, /health/ready, /health endpoints.
// app.MapHealthChecks("/health/live",  new HealthCheckOptions { Predicate = c => c.Tags.Contains("live") });
// app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = c => c.Tags.Contains("ready") });
// app.MapHealthChecks("/health");

app.Run();

public partial class Program { } // for WebApplicationFactory in tests
