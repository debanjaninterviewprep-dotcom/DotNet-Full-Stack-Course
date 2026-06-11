class ConsoleLogger : ILogger
{
    public void Log(string message)
    {
        Console.WriteLine($"\u001b[32m[INFO] {message}\u001b[0m");
    }

    public void LogError(string message)
    {
        Console.WriteLine($"\u001b[31m[ERROR] {message}\u001b[0m");
    }

    public void LogWarning(string message)
    {
        Console.WriteLine($"\u001b[33m[WARNING] {message}\u001b[0m");
    }
}