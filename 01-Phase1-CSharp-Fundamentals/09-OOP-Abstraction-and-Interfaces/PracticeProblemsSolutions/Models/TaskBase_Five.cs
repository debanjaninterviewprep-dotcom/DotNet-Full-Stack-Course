abstract class TaskBase_Five : IComparable<TaskBase_Five>
{
    public int Id { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public bool IsCompleted { get; set; }

    public abstract string GetCategory();
    public abstract int GetPriorityScore();

    public int CompareTo(TaskBase_Five other)
    {
        return other.GetPriorityScore().CompareTo(this.GetPriorityScore()); // descending
    }
}