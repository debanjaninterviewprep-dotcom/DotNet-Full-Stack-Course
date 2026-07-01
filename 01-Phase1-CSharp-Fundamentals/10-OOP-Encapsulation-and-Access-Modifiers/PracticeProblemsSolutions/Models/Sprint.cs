class Sprint
{
    private List<WorkItem> _workItems;
    private int _maxcapacity;
    public readonly string Name;
    public readonly DateTime StartDate;
    public readonly DateTime EndDate;
    public string Velocity => $"{_workItems.Count(wi => wi.IsCompleted)} / {_workItems.Count}";
    public DateTime CompletionDate => _workItems.All(wi => wi.IsCompleted) ? DateTime.Now : DateTime.MinValue;
    public int RemainingCapacity => _maxcapacity - _workItems.Count;

    public Sprint(string name, DateTime startDate, DateTime endDate, int maxcapacity)
    {
        Name = name;
        StartDate = startDate;
        EndDate = endDate;
        _maxcapacity = maxcapacity;
        _workItems = new List<WorkItem>();
    }

    public void AddWorkItem(WorkItem workItem)
    {
        if (_workItems.Count < _maxcapacity)
        {
            _workItems.Add(workItem);
        }
        else
        {
            Console.WriteLine("Cannot add more work items. Sprint capacity reached.");
        }
    }

    public void CompleteWorkItem(int workItemId)
    {
        var workItem = _workItems.FirstOrDefault(wi => wi.Id == workItemId);
        if (workItem != null)
        {
            workItem.Complete();
        }
        else
        {
            Console.WriteLine($"Work item with ID {workItemId} not found in the sprint.");
        }
    }

    public void GetBoard()
    {
        Console.WriteLine($"Sprint: {Name}, Start Date: {StartDate}, End Date: {EndDate}, Velocity: {Velocity}");
        foreach (var workItem in _workItems)
        {
            workItem.Display();
        }
        Console.WriteLine($"To Do: {_workItems.Count(wi => !wi.IsCompleted)}, In Progress: {_workItems.Count(wi => wi.IsCompleted && wi.CreatedAt < DateTime.Now)}, Done: {_workItems.Count(wi => wi.IsCompleted)}");
    }

    public void GetBurndownData()
    {
        int completedCount = _workItems.Count(wi => wi.IsCompleted);
        int remainingCount = _workItems.Count - completedCount;
        Console.WriteLine($"Burndown Data - Completed: {completedCount}, Remaining: {remainingCount}");
    }
}