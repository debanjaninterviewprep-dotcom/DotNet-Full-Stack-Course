// ===============================================================
//  Topic 4 - CRUD, DTOs, Validation, Filtering & Pagination
// ===============================================================
//  Each TODO maps to a Practice-Problems.md problem.
//  Browse Swagger at https://localhost:7104/swagger after dotnet run.

using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers().AddNewtonsoftJson(); // for JSON Patch (Topic 4 stretch)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TaskFlow Topic 4", Version = "v1" });
});

// ---------------------------------------------------------------
// TODO P1: Project entity + ProjectDto + AutoMapper profile +
//          ProjectsController (POST/GET-by-id/DELETE).
// builder.Services.AddDbContext<TaskFlowDbContext>(o =>
//     o.UseSqlite("Data Source=topic04.db"));
// builder.Services.AddAutoMapper(cfg => cfg.AddMaps(typeof(Program).Assembly));

// ---------------------------------------------------------------
// TODO P2: List /tasks with offset pagination + sort whitelist.

// ---------------------------------------------------------------
// TODO P3: CreateTaskValidator (FluentValidation) +
//          ValidationBehavior<,> registered as MediatR pipeline behavior.
// builder.Services.AddMediatR(c => c.RegisterServicesFromAssembly(typeof(Program).Assembly));
// builder.Services.AddValidatorsFromAssembly(typeof(Program).Assembly);
// builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));

// ---------------------------------------------------------------
// TODO P4: Global IExceptionHandler -> RFC 7807 ProblemDetails with traceId.
// builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
// builder.Services.AddProblemDetails(o =>
// {
//     o.CustomizeProblemDetails = ctx =>
//     {
//         ctx.ProblemDetails.Extensions["traceId"] =
//             System.Diagnostics.Activity.Current?.TraceId.ToString() ?? ctx.HttpContext.TraceIdentifier;
//     };
// });

// ---------------------------------------------------------------
// TODO P5: ETag/If-Match concurrency on PUT /api/v1/tasks/{id}.

// ---------------------------------------------------------------
// TODO P6: Keyset pagination for /api/v1/projects/{id}/activity.

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseExceptionHandler();   // requires P4
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();
app.Run();

public partial class Program { }
