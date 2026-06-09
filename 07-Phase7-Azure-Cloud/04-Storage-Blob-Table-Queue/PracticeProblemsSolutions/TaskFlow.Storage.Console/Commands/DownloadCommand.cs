using Azure.Identity;
using Azure.Storage.Blobs;

namespace TaskFlow.Storage.Console.Commands;

public static class DownloadCommand
{
    public static async Task<int> RunAsync(string account, string[] args)
    {
        if (args.Length < 2) { System.Console.Error.WriteLine("download <localOut> <containerOrPath>/<blob>"); return 1; }
        var outPath = args[0];
        var blobPath = args[1];

        var slash = blobPath.IndexOf('/');
        if (slash < 0) { System.Console.Error.WriteLine("Path must include container/blob"); return 1; }
        var container = blobPath[..slash];
        var blobName = blobPath[(slash + 1)..];

        var uri = new Uri($"https://{account}.blob.core.windows.net");
        var svc = new BlobServiceClient(uri, new DefaultAzureCredential());
        var blob = svc.GetBlobContainerClient(container).GetBlobClient(blobName);

        await blob.DownloadToAsync(outPath);
        System.Console.WriteLine($"Wrote {outPath}");
        return 0;
    }
}
