using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace TaskFlow.Functions.HttpTriggers;

public class PingFunction
{
    private readonly ILogger<PingFunction> _log;

    public PingFunction(ILogger<PingFunction> log) => _log = log;

    [Function("Ping")]
    public HttpResponseData Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "ping")] HttpRequestData req)
    {
        _log.LogInformation("Ping invoked");

        var res = req.CreateResponse(HttpStatusCode.OK);
        res.Headers.Add("X-Hostname", Environment.MachineName);
        res.WriteString("pong");
        return res;
    }
}
