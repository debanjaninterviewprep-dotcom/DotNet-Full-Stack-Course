using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OutputCaching;
using Microsoft.Extensions.Caching.Hybrid;
using TaskFlow.Topic11.Telemetry;

namespace TaskFlow.Topic11.Controllers;

[ApiController]
[Route("api/v1/projects/{projectId:guid}")]
public sealed class ProjectStatsController : ControllerBase
{
    private readonly HybridCache _cache;
    private readonly AppDiagnostics _diag;

    public ProjectStatsController(HybridCache cache, AppDiagnostics diag)
    {
        _cache = cache;
        _diag = diag;
    }

    // P4: HybridCache wrapper with tag-based invalidation.
    [HttpGet("stats")]
    [OutputCache(PolicyName = "Stats")]
    public async Task<ActionResult<ProjectStats>> GetStats(Guid projectId, CancellationToken ct)
    {
        using var span = _diag.ActivitySource.StartActivity("LoadProjectStats");
        span?.SetTag("project.id", projectId);

        var stats = await _cache.GetOrCreateAsync(
            key: $"project:{projectId}:stats",
            factory: async _ =>
            {
                // TODO P4: replace with real EF Core aggregation:
                //   var counts = await _db.Tasks.Where(t => t.ProjectId == projectId)
                //                              .GroupBy(t => t.Status)
                //                              .Select(g => new { g.Key, Count = g.Count() })
                //                              .ToListAsync(ct);
                await Task.Delay(50, ct); // simulate DB latency
                return new ProjectStats(projectId, new Dictionary<string, int>
                {
                    ["Open"] = 5, ["InProgress"] = 3, ["Done"] = 12,
                });
            },
            tags: ["project-stats", $"project:{projectId}"],
            cancellationToken: ct);

        return Ok(stats);
    }

    // P4: write that invalidates the per-project tag.
    [HttpPost("invalidate-stats")]
    public async Task<IActionResult> InvalidateStats(Guid projectId, CancellationToken ct)
    {
        await _cache.RemoveByTagAsync($"project:{projectId}", ct);
        return NoContent();
    }
}

public sealed record ProjectStats(Guid ProjectId, IReadOnlyDictionary<string, int> CountsByStatus);
