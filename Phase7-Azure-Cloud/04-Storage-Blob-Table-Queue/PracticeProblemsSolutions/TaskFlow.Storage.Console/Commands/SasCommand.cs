using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Sas;

namespace TaskFlow.Storage.Console.Commands;

public static class SasCommand
{
    public static async Task<int> RunAsync(string account, string[] args)
    {
        if (args.Length < 1) { System.Console.Error.WriteLine("download-link <containerOrPath>/<blob>"); return 1; }
        var blobPath = args[0]; // e.g. attachments/task-001/abc-file.pdf

        var slash = blobPath.IndexOf('/');
        if (slash < 0) { System.Console.Error.WriteLine("Path must include container/blob"); return 1; }
        var container = blobPath[..slash];
        var blobName = blobPath[(slash + 1)..];

        var uri = new Uri($"https://{account}.blob.core.windows.net");
        var svc = new BlobServiceClient(uri, new DefaultAzureCredential());

        var udk = await svc.GetUserDelegationKeyAsync(
            DateTimeOffset.UtcNow.AddMinutes(-1),
            DateTimeOffset.UtcNow.AddHours(1));

        var sas = new BlobSasBuilder
        {
            BlobContainerName = container,
            BlobName = blobName,
            Resource = "b",
            StartsOn = DateTimeOffset.UtcNow,
            ExpiresOn = DateTimeOffset.UtcNow.AddMinutes(10),
            Protocol = SasProtocol.Https,
        };
        sas.SetPermissions(BlobSasPermissions.Read);

        var token = sas.ToSasQueryParameters(udk.Value, account);
        var blob = svc.GetBlobContainerClient(container).GetBlobClient(blobName);

        System.Console.WriteLine($"{blob.Uri}?{token}");
        return 0;
    }
}
