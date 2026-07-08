class TaskQuotaExceededException : Exception
{
	public int CurrentCount { get; }
	public int MaxAllowed { get; }

	public TaskQuotaExceededException(int current, int max)
		: base($"Cannot add more tasks. Current: {current}, Maximum: {max}.")
	{
		CurrentCount = current;
		MaxAllowed = max;
	}
}
