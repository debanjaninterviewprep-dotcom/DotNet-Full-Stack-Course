class InMemoryTaskRepository : IRepository<TaskBase_Five>
{
    private List<TaskBase_Five> _tasks = new List<TaskBase_Five>();

    public int Count => _tasks.Count;

    public void Add(TaskBase_Five item) => _tasks.Add(item);

    public void Delete(int id)
    {
        var task = GetById(id);
        if (task != null) _tasks.Remove(task);
    }

    public List<TaskBase_Five> GetAll() => _tasks;

    public TaskBase_Five GetById(int id)
        => _tasks.FirstOrDefault(x => x.Id == id);

    public void Update(TaskBase_Five item)
    {
        var existing = GetById(item.Id);
        if (existing != null)
        {
            existing.Title = item.Title;
            existing.Description = item.Description;
            existing.IsCompleted = item.IsCompleted;
        }
    }
}