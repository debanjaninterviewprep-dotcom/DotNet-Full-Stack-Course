interface IRepository<T>
{
    void Add(T item);
    T GetById(int id);
    List<T> GetAll();
    void Update(T item);
    void Delete(int id);
    int Count { get; }
}

public interface INotificationService
{
    void Send(string to, string subject, string body);
    void SendBulk(string[] recipients, string subject, string body);
}

public interface IExportService<T>
{
    string ExportToCsv(IEnumerable<T> items);
    string ExportToJson(IEnumerable<T> items);
}