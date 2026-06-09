namespace TaskFlow.Topic09.Storage;

public sealed record StoredFile(string Key, long Size, string ContentType, string Sha256);

public interface IFileStorage
{
    Task<StoredFile> SaveAsync(string folder, string filename, string contentType,
        Stream content, CancellationToken ct);
    Task<Stream> OpenReadAsync(string key, CancellationToken ct);
    Task DeleteAsync(string key, CancellationToken ct);
    Uri GetReadUrl(string key, TimeSpan ttl);
}
