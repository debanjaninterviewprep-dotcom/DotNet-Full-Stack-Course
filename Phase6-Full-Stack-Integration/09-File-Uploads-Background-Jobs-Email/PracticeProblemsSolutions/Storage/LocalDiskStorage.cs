using System.Security.Cryptography;

namespace TaskFlow.Topic09.Storage;

public sealed class LocalDiskStorage : IFileStorage
{
    private readonly string _root;

    public LocalDiskStorage(IConfiguration cfg, IWebHostEnvironment env)
    {
        _root = cfg["Storage:LocalRoot"] ?? Path.Combine(env.ContentRootPath, "App_Data", "uploads");
        Directory.CreateDirectory(_root);
    }

    public async Task<StoredFile> SaveAsync(string folder, string filename, string contentType,
        Stream content, CancellationToken ct)
    {
        var safe = SanitizeFilename(filename);
        var key = $"{folder}/{Guid.NewGuid():N}_{safe}";
        var path = Path.Combine(_root, key.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);

        using var sha = SHA256.Create();
        await using var fs = File.Create(path);
        await using var crypto = new CryptoStream(fs, sha, CryptoStreamMode.Write);
        await content.CopyToAsync(crypto, ct);
        crypto.FlushFinalBlock();

        var hash = Convert.ToHexString(sha.Hash!);
        return new StoredFile(key, fs.Length, contentType, hash);
    }

    public Task<Stream> OpenReadAsync(string key, CancellationToken ct)
    {
        var path = Path.Combine(_root, key.Replace('/', Path.DirectorySeparatorChar));
        Stream s = File.OpenRead(path);
        return Task.FromResult(s);
    }

    public Task DeleteAsync(string key, CancellationToken ct)
    {
        var path = Path.Combine(_root, key.Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(path)) File.Delete(path);
        return Task.CompletedTask;
    }

    public Uri GetReadUrl(string key, TimeSpan ttl)
    {
        // Local provider: return the controller-served URL. Real signing not applicable.
        return new Uri($"/api/v1/files/{Uri.EscapeDataString(key)}", UriKind.Relative);
    }

    private static string SanitizeFilename(string raw)
    {
        var name = Path.GetFileName(raw);
        foreach (var c in Path.GetInvalidFileNameChars())
            name = name.Replace(c, '_');
        return string.IsNullOrWhiteSpace(name) ? "file" : name;
    }
}
