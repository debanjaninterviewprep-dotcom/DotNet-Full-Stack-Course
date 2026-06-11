class TaskBase
{
    public int id;
    public string title;
    public string assignee;
    public DateTime createdAt;
    public bool isCompleted;

    public TaskBase(int id, string title, string assignee)
    {
        this.id = id;
        this.title = title;
        this.assignee = assignee;
        this.createdAt = DateTime.Now;
        this.isCompleted = false;
    }

    public virtual int GetEstimatedHours()
    {
        return 1; // Default estimate, can be overridden by subclasses
    }

    public virtual string GetPriority()
    {
        return "Medium"; // Default priority, can be overridden by subclasses
    }

    public virtual void DisplayInfo()
    {
        Console.WriteLine($"Task ID: {id}, Title: {title}, Assignee: {assignee}, Created At: {createdAt}, Completed: {isCompleted}");
    }

    public void CompleteTask()
    {
        isCompleted = true;
        Console.WriteLine($"Task '{title}' marked as completed.");
    }

    public override string ToString()
    {
        return $"[Task] ID: {id}, Title: {title}, Assignee: {assignee}, Created At: {createdAt}, Completed: {isCompleted}";
    }
}