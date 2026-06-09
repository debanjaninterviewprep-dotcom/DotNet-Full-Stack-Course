using Amazon;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.SecurityToken;
using Amazon.SecurityToken.Model;
using Azure.Core;
using Azure.Identity;

if (args.Length < 3)
{
    Console.WriteLine("Usage: OidcFederation.Sample <awsAudience> <awsRoleArn> <s3Bucket>");
    return 1;
}
var (awsAudience, roleArn, bucket) = (args[0], args[1], args[2]);

// 1. Acquire an Entra token for the AWS audience.
var azureCred = new DefaultAzureCredential();
AccessToken token = await azureCred.GetTokenAsync(
    new TokenRequestContext(new[] { awsAudience }), default);

// 2. Exchange for short-lived AWS credentials via STS.
var sts = new AmazonSecurityTokenServiceClient(new AnonymousAWSCredentials(), RegionEndpoint.USEast1);
var assume = await sts.AssumeRoleWithWebIdentityAsync(new AssumeRoleWithWebIdentityRequest
{
    RoleArn = roleArn,
    RoleSessionName = $"azure-{Environment.MachineName}",
    WebIdentityToken = token.Token,
    DurationSeconds = 3600,
});

Console.WriteLine($"Got AWS creds, expire {assume.Credentials.Expiration:o}");

// 3. Use them.
var s3 = new AmazonS3Client(assume.Credentials, RegionEndpoint.USEast1);
var listing = await s3.ListObjectsV2Async(new() { BucketName = bucket, MaxKeys = 5 });
foreach (var obj in listing.S3Objects) Console.WriteLine($"  {obj.Key}  {obj.Size}B");
return 0;
