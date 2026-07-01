class Improvement : WorkItem
{
    public string CurrentBehavior { get; private set; }
    public string DesiredBehavior { get; private set; }

    public Improvement(int id, string title, string currentBehavior, string desiredBehavior) : base(id, title)
    {
        CurrentBehavior = currentBehavior;
        DesiredBehavior = desiredBehavior;
    }

    public override void GetPriorityLevel()
    {
        Console.WriteLine($"Improvement ID: {Id}, Title: {Title}, Current Behavior: {CurrentBehavior}, Desired Behavior: {DesiredBehavior}");
    }
}