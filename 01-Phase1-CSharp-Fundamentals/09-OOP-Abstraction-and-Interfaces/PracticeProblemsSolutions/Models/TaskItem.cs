class TaskItem : IComparable<TaskItem>, IEquatable<TaskItem>, IFormattable
{
    public int Id { get; set; }
    public string Title { get; set; }
    public string Priority { get; set; }

    public int CompareTo(TaskItem other)
    {
        if (other == null) return 1;

        // Assuming Priority is a string like "High", "Medium", "Low"
        int thisPriority = GetPriorityValue(this.Priority);
        int otherPriority = GetPriorityValue(other.Priority);

        if(thisPriority == otherPriority)
        {
            return this.Title.CompareTo(other.Title); // If priorities are equal, sort by Title
        }

        return thisPriority.CompareTo(otherPriority);
    }

    private int GetPriorityValue(string priority)
    {
        return priority switch
        {
            "High" => 3,
            "Medium" => 2,
            "Low" => 1,
            _ => 0
        };
    }

    public bool Equals(TaskItem other)
    {
        if (other == null) return false;
        return this.Id == other.Id && this.Title == other.Title && this.Priority == other.Priority;
    }

    public override bool Equals(object obj)
    {
        return Equals(obj as TaskItem);
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(Id, Title, Priority);
    }

    public string ToString(string format, IFormatProvider formatProvider)
    {
        return format switch
        {
            "G" => $"Task: {Title} (Priority: {Priority})",
            "D" => $"Task ID: {Id}",
            "P" => $"Priority: {Priority}",
            _ => $"Task: {Title} (Priority: {Priority})"
        };
    }

    public override string ToString()
    {
        return ToString("G", null);
    }
}