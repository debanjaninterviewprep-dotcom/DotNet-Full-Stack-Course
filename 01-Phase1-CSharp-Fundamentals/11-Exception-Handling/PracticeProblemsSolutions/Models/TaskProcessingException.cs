class TaskProcessingException : Exception
{
	public int TaskId { get; }

	public TaskProcessingException(int taskId, string message, Exception inner)
		: base(message, inner)
	{
		TaskId = taskId;
	}
}
