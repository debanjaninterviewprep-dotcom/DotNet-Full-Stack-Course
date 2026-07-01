class Feature : WorkItem
{
    public string StoryPoints { get; private set; }
    public string AcceptanceCriteria { get; private set; }

    public Feature(int id, string title, string storyPoints, string acceptanceCriteria) : base(id, title)
    {
        StoryPoints = storyPoints;
        AcceptanceCriteria = acceptanceCriteria;
    }

    public override void GetPriorityLevel()
    {
        Console.WriteLine($"Feature ID: {Id}, Title: {Title}, Story Points: {StoryPoints}");
    }
}