class TaskItem
{
	public int Id { get; set; }
	public string Title { get; set; } = string.Empty;
	public int Priority { get; set; }
	public DateTime DueDate { get; set; }
	public bool IsProcessed { get; set; }
}
