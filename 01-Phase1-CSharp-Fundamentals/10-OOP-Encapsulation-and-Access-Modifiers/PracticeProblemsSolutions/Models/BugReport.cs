class BugReport : WorkItem
{
    public string Severity { get; private set; }
    public string StepsToReproduce { get; private set; }

    public BugReport(int id, string title, string severity, string stepsToReproduce) : base(id, title)
    {
        Severity = severity;
        StepsToReproduce = stepsToReproduce;
    }

    public override void GetPriorityLevel()
    {
        Console.WriteLine($"BugReport ID: {Id}, Title: {Title}, Severity: {Severity}");
    }
}