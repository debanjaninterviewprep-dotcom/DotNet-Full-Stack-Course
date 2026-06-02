using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace TaskFlow.Topic08.Hubs;

[Authorize]
public sealed class TaskFlowHub : Hub<ITaskFlowClient>
{
    private readonly ILogger<TaskFlowHub> _logger;

    public TaskFlowHub(ILogger<TaskFlowHub> logger) => _logger = logger;

    public override async Task OnConnectedAsync()
    {
        var sub = Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        _logger.LogInformation("Hub connected {ConnId} as {Sub}", Context.ConnectionId, sub);
        if (!string.IsNullOrEmpty(sub))
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user:{sub}");
        await base.OnConnectedAsync();
    }

    public override Task OnDisconnectedAsync(Exception? exception)
    {
        if (exception is not null)
            _logger.LogWarning(exception, "Hub disconnect with error {ConnId}", Context.ConnectionId);
        return base.OnDisconnectedAsync(exception);
    }

    // P3: resource-based check before joining the project group.
    public async Task JoinProject(Guid projectId)
    {
        // TODO P3: load Project from DbContext and call IAuthorizationService.AuthorizeAsync(user, project, "CanViewProject")
        // For the practice scaffold we accept any authenticated caller — replace with real check.
        await Groups.AddToGroupAsync(Context.ConnectionId, $"project:{projectId}");
    }

    public Task LeaveProject(Guid projectId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, $"project:{projectId}");

    // Demo: "typing…" — echoes to others in the group only.
    public Task Typing(Guid projectId, Guid taskId) =>
        Clients.OthersInGroup($"project:{projectId}").Notify(
            new NotificationDto("Typing", $"Someone is typing on task {taskId}", null));
}
