namespace TaskFlow.Topic09.Storage;

// P2: stub — implement with Azure.Storage.Blobs BlobContainerClient.
//   - SaveAsync: UploadAsync with overwrite false; compute SHA via CryptoStream wrapper.
//   - GetReadUrl: BlobSasBuilder with Read permission, expiry = UtcNow + ttl.
public sealed class AzureBlobStorage : IFileStorage
{
    public AzureBlobStorage(IConfiguration cfg)
    {
        // TODO P2: build BlobContainerClient from cfg["Storage:Azure:ConnectionString"]
        //                                       + cfg["Storage:Azure:Container"]
    }

    public Task<StoredFile> SaveAsync(string folder, string filename, string contentType,
        Stream content, CancellationToken ct) =>
        throw new NotImplementedException("P2: implement Azure Blob upload with SHA-256 hashing.");

    public Task<Stream> OpenReadAsync(string key, CancellationToken ct) =>
        throw new NotImplementedException("P2: implement Azure Blob download.");

    public Task DeleteAsync(string key, CancellationToken ct) =>
        throw new NotImplementedException("P2: implement Azure Blob delete.");

    public Uri GetReadUrl(string key, TimeSpan ttl) =>
        throw new NotImplementedException("P2: implement SAS URL generation.");
}
