namespace TaskFlow.Topic08.Hubs;

public sealed record TaskDetailDto(Guid Id, Guid ProjectId, string Title, string Status);
public sealed record CommentDto(Guid Id, Guid TaskId, string Body, string AuthorEmail, DateTimeOffset CreatedAt);
public sealed record NotificationDto(string Title, string? Body, string? Url);
public sealed record UserPresence(string UserId, string DisplayName, DateTimeOffset SeenAt);

// P1: strongly-typed server-to-client contract.
public interface ITaskFlowClient
{
    Task TaskCreated(TaskDetailDto task);
    Task TaskUpdated(TaskDetailDto task);
    Task TaskDeleted(Guid taskId);
    Task CommentAdded(Guid taskId, CommentDto comment);
    Task PresenceChanged(Guid projectId, IReadOnlyList<UserPresence> members);
    Task Notify(NotificationDto notification);
}
