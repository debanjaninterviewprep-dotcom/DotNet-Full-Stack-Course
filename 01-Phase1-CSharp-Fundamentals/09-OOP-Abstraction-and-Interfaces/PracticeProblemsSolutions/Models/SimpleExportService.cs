using System.Text.Json;
using System.Text;

public class SimpleExportService<T> : IExportService<T>
{
    public string ExportToCsv(IEnumerable<T> items)
    {
        var sb = new StringBuilder();
        foreach (var item in items)
        {
            sb.AppendLine(item.ToString());
        }
        return sb.ToString();
    }

    public string ExportToJson(IEnumerable<T> items)
    {
        return JsonSerializer.Serialize(items, new JsonSerializerOptions { WriteIndented = true });
    }
}