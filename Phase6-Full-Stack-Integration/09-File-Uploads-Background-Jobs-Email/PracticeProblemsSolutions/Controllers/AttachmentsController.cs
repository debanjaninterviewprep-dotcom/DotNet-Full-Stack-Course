using System.Net.Http.Headers;
using Hangfire;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Net.Http.Headers;
using TaskFlow.Topic09.Jobs;
using TaskFlow.Topic09.Storage;

namespace TaskFlow.Topic09.Controllers;

[ApiController]
[Route("api/v1/tasks/{taskId:guid}/attachments")]
public sealed class AttachmentsController : ControllerBase
{
    private static readonly HashSet<string> _allowedTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/png", "image/jpeg", "application/pdf", "text/plain",
    };

    private readonly IFileStorage _storage;
    private readonly IBackgroundJobClient _jobs;

    public AttachmentsController(IFileStorage storage, IBackgroundJobClient jobs)
    {
        _storage = storage;
        _jobs = jobs;
    }

    // P1: streaming multipart upload.
    [HttpPost]
    [DisableFormValueModelBinding]
    [RequestSizeLimit(50_000_000)]
    [RequestFormLimits(MultipartBodyLengthLimit = 50_000_000)]
    public async Task<IActionResult> Upload(Guid taskId, CancellationToken ct)
    {
        if (!MediaTypeHeaderValue.TryParse(Request.ContentType, out var mt) ||
            !mt.MediaType.HasValue ||
            !mt.MediaType.Value!.StartsWith("multipart/", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new ProblemDetails { Title = "Expected multipart/form-data" });
        }

        var boundary = HeaderUtilities.RemoveQuotes(mt.Boundary).Value;
        if (string.IsNullOrEmpty(boundary))
            return BadRequest(new ProblemDetails { Title = "Missing boundary" });

        var reader = new MultipartReader(boundary, Request.Body);
        while (await reader.ReadNextSectionAsync(ct) is { } section)
        {
            if (!ContentDispositionHeaderValue.TryParse(section.ContentDisposition, out var cd) ||
                !cd.FileName.HasValue)
            {
                continue;
            }

            var contentType = section.ContentType ?? "application/octet-stream";
            if (!_allowedTypes.Contains(contentType))
                return UnprocessableEntity(new ProblemDetails { Title = "Disallowed file type" });

            var stored = await _storage.SaveAsync(
                folder: $"tasks/{taskId:N}",
                filename: cd.FileName.Value!,
                contentType: contentType,
                content: section.Body,
                ct: ct);

            // P3: enqueue scan + thumbnail jobs.
            _jobs.Enqueue<ScanFileJob>(j => j.ExecuteAsync(stored.Key, CancellationToken.None));
            if (contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
                _jobs.Enqueue<MakeThumbnailJob>(j => j.ExecuteAsync(stored.Key, CancellationToken.None));

            return Created($"/api/v1/files/{Uri.EscapeDataString(stored.Key)}", stored);
        }

        return BadRequest(new ProblemDetails { Title = "No file in request" });
    }
}

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false, Inherited = true)]
public sealed class DisableFormValueModelBindingAttribute : Attribute, Microsoft.AspNetCore.Mvc.Filters.IResourceFilter
{
    public void OnResourceExecuting(Microsoft.AspNetCore.Mvc.Filters.ResourceExecutingContext ctx)
    {
        var factories = ctx.ValueProviderFactories;
        factories.RemoveType<Microsoft.AspNetCore.Mvc.ModelBinding.FormValueProviderFactory>();
        factories.RemoveType<Microsoft.AspNetCore.Mvc.ModelBinding.JQueryFormValueProviderFactory>();
    }
    public void OnResourceExecuted(Microsoft.AspNetCore.Mvc.Filters.ResourceExecutedContext ctx) { }
}
