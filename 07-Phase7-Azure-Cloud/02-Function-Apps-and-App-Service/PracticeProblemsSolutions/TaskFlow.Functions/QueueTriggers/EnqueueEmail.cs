using System.Net;
using System.Text.Json;
using Azure.Storage.Queues;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace TaskFlow.Functions.QueueTriggers;

public class EnqueueEmail
{
    private readonly ILogger<EnqueueEmail> _log;

    public EnqueueEmail(ILogger<EnqueueEmail> log) => _log = log;

    [Function("EnqueueEmail")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "enqueue-email")] HttpRequestData req)
    {
        var conn = Environment.GetEnvironmentVariable("Storage")
            ?? throw new InvalidOperationException("Missing 'Storage' setting");

        var payload = await new StreamReader(req.Body).ReadToEndAsync();
        if (string.IsNullOrWhiteSpace(payload))
        {
            var bad = req.CreateResponse(HttpStatusCode.BadRequest);
            await bad.WriteStringAsync("Body required");
            return bad;
        }

        var queue = new QueueClient(conn, "email-queue",
            new QueueClientOptions { MessageEncoding = QueueMessageEncoding.Base64 });
        await queue.CreateIfNotExistsAsync();
        await queue.SendMessageAsync(payload);

        _log.LogInformation("Enqueued message size {bytes}B", payload.Length);

        var res = req.CreateResponse(HttpStatusCode.Accepted);
        await res.WriteAsJsonAsync(new { queued = true });
        return res;
    }
}
