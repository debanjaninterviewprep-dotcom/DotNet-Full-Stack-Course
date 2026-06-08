namespace TaskFlow.RedisApi.Services;

public record TaskDto(string Id, string Title, string Status);

public class TaskRepository
{
    private readonly Dictionary<string, TaskDto> _store = new()
    {
        ["abc"] = new("abc", "Wire OAuth", "in_progress"),
        ["def"] = new("def", "Write tests", "todo"),
    };

    public async Task<TaskDto?> FindAsync(string id, CancellationToken ct)
    {
        await Task.Delay(200, ct); // simulate slow DB
        return _store.TryGetValue(id, out var t) ? t : null;
    }

    public async Task UpdateAsync(string id, TaskDto t, CancellationToken ct)
    {
        await Task.Delay(50, ct);
        _store[id] = t with { Id = id };
    }
}
