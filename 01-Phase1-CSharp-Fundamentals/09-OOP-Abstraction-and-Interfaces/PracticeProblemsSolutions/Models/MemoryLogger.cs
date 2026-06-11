class MemoryLogger : ILogger
{
    private List<string> logs = new List<string>();

    public void Log(string message)
    {
        logs.Add($"INFO: {message}");
    }

    public void LogError(string message)
    {
        logs.Add($"ERROR: {message}");
    }

    public void LogWarning(string message)
    {
        logs.Add($"WARNING: {message}");
    }

    public void PrintLogs()
    {
        foreach (var log in logs)
        {
            Console.WriteLine(log);
        }
    }
}