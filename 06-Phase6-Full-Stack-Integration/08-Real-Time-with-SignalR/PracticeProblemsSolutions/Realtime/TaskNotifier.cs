using Microsoft.AspNetCore.SignalR;
using TaskFlow.Topic08.Hubs;

namespace TaskFlow.Topic08.Realtime;

// P4: command handlers depend on this — keeps IHubContext out of business logic.
public sealed class TaskNotifier
{
    private readonly IHubContext<TaskFlowHub, ITaskFlowClient> _hub;

    public TaskNotifier(IHubContext<TaskFlowHub, ITaskFlowClient> hub) => _hub = hub;

    public Task TaskCreated(Guid projectId, TaskDetailDto task) =>
        _hub.Clients.Group($"project:{projectId}").TaskCreated(task);

    public Task TaskUpdated(Guid projectId, TaskDetailDto task) =>
        _hub.Clients.Group($"project:{projectId}").TaskUpdated(task);

    public Task TaskDeleted(Guid projectId, Guid taskId) =>
        _hub.Clients.Group($"project:{projectId}").TaskDeleted(taskId);

    public Task CommentAdded(Guid projectId, Guid taskId, CommentDto comment) =>
        _hub.Clients.Group($"project:{projectId}").CommentAdded(taskId, comment);

    public Task NotifyUser(string userId, NotificationDto notification) =>
        _hub.Clients.User(userId).Notify(notification);
}
