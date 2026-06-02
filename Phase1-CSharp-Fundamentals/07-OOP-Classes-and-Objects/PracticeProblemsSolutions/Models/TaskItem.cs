class TaskItem
{
    private static int _idCounter = 1; // Static counter for unique IDs

    public int Id { get; set; } // Unique identifier for each task
    public string Title { get; set; } // Title of the task
    public string Description { get; set; } // Description of the task
    public string Priority { get; set; } // Priority level (e.g., Low, Medium, High)
    public bool IsCompleted { get; set; } // Status of the task
    public DateTime CreatedAt { get; set; } // Timestamp when the task was created
    public DateTime CompletedAt { get; set; } // Timestamp when the task was completed
    public User? AssignedTo { get; set; } // User assigned to the task (nullable)

    public TaskItem(string title, string description, string priority)
    {
        Id = _idCounter++;
        Title = title;
        Description = description;
        Priority = priority;
        CreatedAt = DateTime.Now;
        IsCompleted = false;
        CreatedAt = DateTime.Now;
        CompletedAt = DateTime.MinValue; // Default value indicating not completed
        AssignedTo = null; // No user assigned initially
    }

    public void MarkAsCompleted()
    {
        IsCompleted = true;
        CompletedAt = DateTime.Now; // Set completion timestamp
    }

    public void AssignToUser(User user)
    {
        AssignedTo = user; // Assign the task to a user
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"ID: {Id}");
        Console.WriteLine($"Title: {Title}");
        Console.WriteLine($"Description: {Description}");
        Console.WriteLine($"Priority: {Priority}");
        Console.WriteLine($"Status: {(IsCompleted ? "Completed" : "Pending")}");
        Console.WriteLine($"Created At: {CreatedAt}");
        if (IsCompleted)
            Console.WriteLine($"Completed At: {CompletedAt}");
        if (AssignedTo != null)
            Console.WriteLine($"Assigned To: {AssignedTo.Name} ({AssignedTo.Email})");
    }

    public static void DisplayAllTasks(List<TaskItem> tasks)
    {
        if (tasks.Count == 0)
        {
            Console.WriteLine("No tasks found.");
            return;
        }
        Console.WriteLine("All Tasks:");
        foreach (var task in tasks)
        {
            Console.WriteLine("---------------");
            task.DisplayInfo();
        }
    }

    public static void DisplayCompletedTasks(List<TaskItem> tasks)
    {
        var completedTasks = tasks.Where(t => t.IsCompleted).ToList();
        if (completedTasks.Count == 0)
        {
            Console.WriteLine("No completed tasks found.");
            return;
        }
        Console.WriteLine("Completed Tasks:");
        foreach (var task in completedTasks)
        {
            Console.WriteLine("---------------");
            task.DisplayInfo();
        }
    }
}