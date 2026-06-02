using System.Text.RegularExpressions;

namespace TaskFlow.Topic09.Email;

public sealed class EmailTemplater
{
    private readonly string _root;
    private static readonly Regex _placeholder = new(@"\{\{\s*(\w+)\s*\}\}", RegexOptions.Compiled);

    public EmailTemplater(IWebHostEnvironment env)
    {
        _root = Path.Combine(env.ContentRootPath, "Emails", "Templates");
    }

    public async Task<string> RenderAsync(string templateName, IDictionary<string, string> values,
        CancellationToken ct)
    {
        var path = Path.Combine(_root, templateName + ".html");
        var raw = await File.ReadAllTextAsync(path, ct);
        return _placeholder.Replace(raw, m =>
        {
            var key = m.Groups[1].Value;
            if (!values.TryGetValue(key, out var v))
                throw new InvalidOperationException($"Missing template value '{key}'");
            return System.Net.WebUtility.HtmlEncode(v);
        });
    }
}
