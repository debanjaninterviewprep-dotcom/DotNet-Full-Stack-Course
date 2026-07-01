abstract class WorkItem : IDisplayable, ICompletable
{
    public int Id { get; private set; }
    public string Title { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public bool IsCompleted { get; private set; }

    public WorkItem(int id, string title)
    {
        Id = id;
        Title = title;
        CreatedAt = DateTime.Now;
        IsCompleted = false;
    }

    public void Display()
    {
        Console.WriteLine($"WorkItem ID: {Id}, Title: {Title}, Created At: {CreatedAt}, Completed: {IsCompleted}");
    }
    public string ToShortString()
    {
        return $"ID: {Id}, Title: {Title}";
    }
    public void Complete()
    {
        IsCompleted = true;
    }
    public abstract void GetPriorityLevel();
}