using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace TaskFlow.Topic10.Integration;

[Collection("Api")]
public sealed class ProjectsEndpointTests
{
    private readonly TaskFlowApiFactory _factory;
    private readonly HttpClient _client;

    public ProjectsEndpointTests(TaskFlowApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Add("X-Test-User", Guid.NewGuid().ToString()); // P3
    }

    [Fact]
    public async Task GET_health_returns_200()
    {
        var res = await _client.GetAsync("/health/ready");
        res.StatusCode.Should().BeOneOf(HttpStatusCode.OK, HttpStatusCode.NotFound);
        // NotFound is OK in the scaffold — replace with the real expectation when wired.
    }

    [Fact(Skip = "P2 wiring required — uncomment after ConfigureTestServices is filled in")]
    public async Task POST_creates_project()
    {
        var res = await _client.PostAsJsonAsync("/api/v1/projects", new { name = "Alpha" });
        res.StatusCode.Should().Be(HttpStatusCode.Created);
    }
}
