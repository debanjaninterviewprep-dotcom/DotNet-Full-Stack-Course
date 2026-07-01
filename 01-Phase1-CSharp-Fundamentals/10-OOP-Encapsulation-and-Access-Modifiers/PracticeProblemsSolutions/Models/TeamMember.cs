class TeamMember
{
    private List<WorkItem> _assignedWorkItems;
    public string Name { get; private set; }
    public string Role { get; private set; }

    public TeamMember(string name, string role)
    {
        Name = name;
        Role = role;
        _assignedWorkItems = new List<WorkItem>();
    }

    public void AssignWorkItem(WorkItem workItem)
    {
        _assignedWorkItems.Add(workItem);
    }

    public IReadOnlyList<WorkItem> GetWorkload()
    {
        Console.WriteLine($"Team Member: {Name}, Role: {Role}");
        Console.WriteLine("Assigned Work Items:");
        foreach (var workItem in _assignedWorkItems)
        {
            workItem.Display();
        }
        return _assignedWorkItems.AsReadOnly();
    }
}