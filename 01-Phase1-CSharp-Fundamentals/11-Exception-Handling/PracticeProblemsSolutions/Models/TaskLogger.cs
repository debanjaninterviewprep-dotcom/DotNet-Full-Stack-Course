class TaskLogger : IDisposable
{
	private StreamWriter? _writer;
	private bool _disposed = false;
	private int _taskCount = 0;
	private int _errorCount = 0;
	private static readonly string[] ValidPriorities = { "Low", "Medium", "High" };

	public TaskLogger(string filePath)
	{
		_writer = new StreamWriter(filePath, append: false);
	}

	public void LogTask(string task, string priority)
	{
		if (_disposed) throw new ObjectDisposedException(nameof(TaskLogger));
		if (string.IsNullOrWhiteSpace(task))
			throw new ArgumentException("Task description cannot be empty.");
		if (!Array.Exists(ValidPriorities, p => p == priority))
			throw new ArgumentException($"Priority '{priority}' is invalid. Use Low, Medium, or High.");

		_writer!.WriteLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [{priority}] {task}");
		_writer.Flush();
		_taskCount++;
	}

	public void LogError(string errorMessage)
	{
		if (_disposed) throw new ObjectDisposedException(nameof(TaskLogger));
		_writer!.WriteLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [ERROR] {errorMessage}");
		_writer.Flush();
		_errorCount++;
	}

	public (int tasks, int errors) GetLogSummary()
	{
		if (_disposed) throw new ObjectDisposedException(nameof(TaskLogger));
		return (_taskCount, _errorCount);
	}

	public void Dispose()
	{
		if (!_disposed)
		{
			_writer?.Flush();
			_writer?.Close();
			_writer = null;
			_disposed = true;
			Console.WriteLine("Logger disposed.");
		}
	}
}
