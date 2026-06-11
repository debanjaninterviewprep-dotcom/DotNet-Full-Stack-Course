class BugTask : TaskBase
{
    public string Severity { get; set; }
    public int StepsToReproduce { get; set; }
    public int EstimatedHours { get; set; }
    public string Priority { get; set; }
    public BugTask(int id, string title, string assignee, string severity, int stepsToReproduce)
        : base(id, title, assignee)
    {
        Severity = severity;
        StepsToReproduce = stepsToReproduce;
        EstimatedHours = Severity switch
        {
            "Critical" => 8,
            "High" => 5,
            "Medium" => 3,
            "Low" => 1,
            _ => 2
        };
    
        Priority = Severity switch
        {
            "Critical" => "High",
            "High" => "Medium",
            "Medium" => "Low",
            "Low" => "Low",
            _ => "Medium"
        };
    }

    public override void DisplayInfo()
    {
        base.DisplayInfo();
        Console.WriteLine($"Severity: {Severity}");
        Console.WriteLine($"Steps to Reproduce: {StepsToReproduce}");
        Console.WriteLine($"Estimated Hours: {EstimatedHours}");
        Console.WriteLine($"Priority: {Priority}");
    }
}