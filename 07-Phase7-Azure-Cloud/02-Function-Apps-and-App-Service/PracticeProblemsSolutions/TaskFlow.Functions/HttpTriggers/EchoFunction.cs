using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace TaskFlow.Functions.HttpTriggers;

public record EchoRequest(string Message);
public record EchoResponse(string Message, DateTimeOffset ReceivedAt);

public class EchoFunction
{
    private readonly ILogger<EchoFunction> _log;
    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public EchoFunction(ILogger<EchoFunction> log) => _log = log;

    [Function("Echo")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "echo")] HttpRequestData req)
    {
        _log.LogInformation("Echo invoked");

        EchoRequest? body;
        try
        {
            body = await JsonSerializer.DeserializeAsync<EchoRequest>(req.Body, JsonOpts);
        }
        catch (JsonException ex)
        {
            _log.LogError(ex, "Invalid JSON in echo request");
            var bad = req.CreateResponse(HttpStatusCode.BadRequest);
            await bad.WriteStringAsync("Invalid JSON");
            return bad;
        }

        if (body is null || string.IsNullOrWhiteSpace(body.Message))
        {
            var bad = req.CreateResponse(HttpStatusCode.BadRequest);
            await bad.WriteStringAsync("'message' is required");
            return bad;
        }

        var res = req.CreateResponse(HttpStatusCode.OK);
        await res.WriteAsJsonAsync(new EchoResponse(body.Message, DateTimeOffset.UtcNow));
        return res;
    }
}
