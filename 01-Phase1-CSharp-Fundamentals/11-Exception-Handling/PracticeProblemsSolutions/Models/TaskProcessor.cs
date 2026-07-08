class TaskProcessor : IDisposable
{
	private const int MaxTasks = 5;
	private List<TaskItem> _tasks = new List<TaskItem>();
	private bool _disposed = false;
	private Random _random = new Random();

	public void AddTask(int id, string title, int priority, DateTime dueDate)
	{
		if (_tasks.Count >= MaxTasks)
			throw new TaskQuotaExceededException(_tasks.Count, MaxTasks);

		if (id <= 0)
			throw new TaskValidationException("ID", id.ToString(), "ID must be positive.");

		if (title == null || title.Length < 3 || title.Length > 50)
			throw new TaskValidationException("Title", title ?? "null", "Title must be 3-50 characters.");

		if (priority < 1 || priority > 3)
			throw new TaskValidationException("Priority", priority.ToString(), "Priority must be 1 (Low), 2 (Medium), or 3 (High).");

		if (dueDate <= DateTime.Now)
			throw new TaskValidationException("DueDate", dueDate.ToString("yyyy-MM-dd"), "Due date must be in the future.");

		_tasks.Add(new TaskItem { Id = id, Title = title, Priority = priority, DueDate = dueDate });
	}

	public void ProcessTask(int id)
	{
		TaskItem? task = _tasks.Find(t => t.Id == id);
		if (task == null)
			throw new TaskProcessingException(id, $"Task {id} not found.", new Exception("Task not found"));

		if (_random.NextDouble() < 0.3)
			throw new TaskProcessingException(id, "Random system error.", new Exception("Simulated random failure"));

		task.IsProcessed = true;
	}

	public void ProcessAllTasks()
	{
		int succeeded = 0;
		List<int> failedIds = new List<int>();

		foreach (TaskItem task in _tasks)
		{
			try
			{
				ProcessTask(task.Id);
				Console.WriteLine($"✓ Task {task.Id} \"{task.Title}\" — Processed successfully.");
				succeeded++;
			}
			catch (TaskProcessingException ex) when (ex.TaskId > 0)
			{
				Console.WriteLine($"✗ Task {ex.TaskId} \"{task.Title}\" — Processing failed: {ex.Message}");
				failedIds.Add(ex.TaskId);
			}
		}

		Console.WriteLine($"\n=== Processing Summary ===");
		Console.WriteLine($"Total: {_tasks.Count} | Succeeded: {succeeded} | Failed: {failedIds.Count}");
		if (failedIds.Count > 0)
			Console.WriteLine($"Failed Tasks: #{string.Join(", #", failedIds)}");
	}

	public void Dispose()
	{
		if (!_disposed)
		{
			_tasks.Clear();
			_disposed = true;
			Console.WriteLine("\nTaskProcessor disposed. Resources cleaned up.");
		}
	}
}
