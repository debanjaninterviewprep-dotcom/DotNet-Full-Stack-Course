using Azure.Identity;
using Azure.Storage.Blobs;

namespace TaskFlow.Storage.Console.Commands;

public static class UploadCommand
{
    public static async Task<int> RunAsync(string account, string[] args)
    {
        if (args.Length < 2) { System.Console.Error.WriteLine("upload <localFile> <taskId>"); return 1; }
        var path = args[0];
        var taskId = args[1];

        if (!File.Exists(path)) { System.Console.Error.WriteLine($"File not found: {path}"); return 1; }

        var uri = new Uri($"https://{account}.blob.core.windows.net");
        var svc = new BlobServiceClient(uri, new DefaultAzureCredential());
        var container = svc.GetBlobContainerClient("attachments");
        await container.CreateIfNotExistsAsync();

        var name = $"{taskId}/{Guid.NewGuid():N}-{Path.GetFileName(path)}";
        var blob = container.GetBlobClient(name);

        await using var stream = File.OpenRead(path);
        await blob.UploadAsync(stream, overwrite: false);

        System.Console.WriteLine(blob.Uri);
        return 0;
    }
}
