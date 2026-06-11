class FileLogger : ILogger
{
    private readonly string _filePath;

    public FileLogger(string filePath)
    {
        _filePath = filePath;
    }

    public void Log(string message)
    {
        WriteToFile($"[INFO] {message}");
    }

    public void LogError(string message)
    {
        WriteToFile($"[ERROR] {message}");
    }

    public void LogWarning(string message)
    {
        WriteToFile($"[WARNING] {message}");
    }

    private void WriteToFile(string message)
    {
        try
        {
            using (StreamWriter sw = new StreamWriter(_filePath, true))
            {
                sw.WriteLine($"{DateTime.Now}: {message}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to write to log file: {ex.Message}");
        }
    }
}