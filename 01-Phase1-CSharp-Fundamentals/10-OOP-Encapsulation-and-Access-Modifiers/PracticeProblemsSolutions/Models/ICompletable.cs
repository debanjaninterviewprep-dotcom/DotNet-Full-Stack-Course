interface ICompletable
{
    void Complete();
    bool IsCompleted { get; }
}