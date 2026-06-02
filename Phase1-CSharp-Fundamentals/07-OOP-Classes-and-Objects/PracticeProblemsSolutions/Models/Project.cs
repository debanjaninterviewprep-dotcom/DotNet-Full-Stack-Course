class Project
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public List<TaskItem> Tasks { get; set; } = new(20);
    public int TaskCount => Tasks.Count;

    public Project(string name)
    {
        Id = Guid.NewGuid();
        Name = name;
    }

    public void AddTask(TaskItem task)
    {
        Tasks.Add(task);
    }

    public void RemoveTask(Guid taskId)
    {
        Tasks.RemoveAll(t => t.Id.Equals(taskId));
    }

    public TaskItem? GetTaskByPriority()
    {
        return Tasks.OrderByDescending(t => t.Priority).FirstOrDefault();
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"Project: {Name} (ID: {Id})");
        Console.WriteLine($"Total Tasks: {TaskCount}");
        foreach (var task in Tasks)
        {
            string status = task.IsCompleted ? "Completed" : "Pending";
            string assignee = task.AssignedTo?.Name ?? "Unassigned";
            Console.WriteLine($"- Task: {task.Title}, Status: {status}, Priority: {task.Priority}, Assigned To: {assignee}");
        }
    }

    public void GetCompletionPercentage()
    {
        if (TaskCount == 0)
        {
            Console.WriteLine("No tasks in the project.");
            return;
        }

        int completedTasks = Tasks.Count(t => t.IsCompleted);
        double percentage = (double)completedTasks / TaskCount * 100;

        const int barWidth = 20;
        int filled = (int)Math.Round(percentage / 100 * barWidth);
        string bar = new string('█', filled) + new string('░', barWidth - filled);

        Console.WriteLine($"📊 PROGRESS: {completedTasks}/{TaskCount} tasks ({percentage:F1}%)");
        Console.WriteLine($"[{bar}] {percentage:F0}%");
    }

}