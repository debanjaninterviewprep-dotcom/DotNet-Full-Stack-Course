# Topic 09: File Uploads, Background Jobs & Email — Interview Questions

---

## Q1. What are the strategies for file uploads in ASP.NET Core?
**Answer:**
```csharp
// Small files: buffer in memory
[HttpPost("upload")]
public async Task<IActionResult> Upload(IFormFile file)
{
    if (file.Length > 10 * 1024 * 1024) return BadRequest("File too large (max 10MB)");
    if (!IsAllowedType(file.ContentType)) return BadRequest("File type not allowed");

    using var stream = file.OpenReadStream();
    var url = await _blobStorage.UploadAsync(file.FileName, stream, file.ContentType);
    return Ok(new { url });
}

// Large files: streaming (avoids buffering entire file in memory)
[HttpPost("upload-large"), DisableRequestSizeLimit]
public async Task<IActionResult> UploadLarge()
{
    if (!Request.HasFormContentType) return BadRequest("Expected form data");
    var form = await Request.ReadFormAsync();
    var file = form.Files[0];
    using var stream = file.OpenReadStream();
    await _blobStorage.UploadAsync(file.FileName, stream, file.ContentType);
    return Ok();
}

// Multiple files
[HttpPost("upload-multiple")]
public async Task<IActionResult> UploadMultiple(IFormFileCollection files) { }
```

---

## Q2. What are security considerations for file uploads?
**Answer:**
```csharp
// 1. Validate file type (content-based, not extension)
private static bool IsAllowedMimeType(string contentType)
    => new[] { "image/jpeg", "image/png", "image/gif", "application/pdf" }.Contains(contentType);

// 2. Validate magic bytes (don't trust Content-Type header)
private static bool IsValidImage(byte[] bytes)
{
    // PNG: 89 50 4E 47
    if (bytes.Length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50) return true;
    // JPEG: FF D8 FF
    if (bytes.Length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    return false;
}

// 3. Sanitize filename
var safeFileName = Path.GetFileNameWithoutExtension(file.FileName)
    .Replace("..", "")
    .Replace("/", "")
    .Replace("\\", "");
var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

// 4. Use random name to prevent path traversal
var storedName = $"{Guid.NewGuid()}{extension}";

// 5. Store OUTSIDE web root or use blob storage
// Never store in wwwroot/uploads — attacker could upload .aspx and execute it!

// 6. Limit size
builder.Services.Configure<FormOptions>(o => {
    o.MultipartBodyLengthLimit = 10 * 1024 * 1024; // 10MB
});

// 7. Virus scan (for sensitive environments)
var scanResult = await _virusScanner.ScanAsync(stream);
if (!scanResult.Clean) return BadRequest("File failed security scan");
```

---

## Q3. How do you integrate Azure Blob Storage for file storage?
**Answer:**
```csharp
// Install: Azure.Storage.Blobs
public class AzureBlobStorageService(BlobServiceClient blobClient, IOptions<BlobSettings> opts)
{
    private readonly string _container = opts.Value.Container;

    public async Task<string> UploadAsync(string fileName, Stream content, string contentType)
    {
        var container = blobClient.GetBlobContainerClient(_container);
        await container.CreateIfNotExistsAsync(PublicAccessType.None);

        var blobName = $"{DateTime.UtcNow:yyyy/MM/dd}/{Guid.NewGuid()}{Path.GetExtension(fileName)}";
        var blob = container.GetBlobClient(blobName);

        await blob.UploadAsync(content, new BlobHttpHeaders { ContentType = contentType });
        return blob.Uri.AbsoluteUri;
    }

    public async Task DeleteAsync(string blobUrl)
    {
        var uri = new Uri(blobUrl);
        var blobName = uri.AbsolutePath.TrimStart('/').Replace($"{_container}/", "");
        await blobClient.GetBlobContainerClient(_container).GetBlobClient(blobName).DeleteIfExistsAsync();
    }

    // Temporary SAS URL for secure access
    public Uri GetSasUrl(string blobName, TimeSpan expiry)
    {
        var blob = blobClient.GetBlobContainerClient(_container).GetBlobClient(blobName);
        return blob.GenerateSasUri(BlobSasPermissions.Read, DateTimeOffset.UtcNow.Add(expiry));
    }
}
```

---

## Q4. What are background jobs and what tools are available in .NET?
**Answer:**
Background jobs execute tasks outside the HTTP request-response cycle:

| Tool | Type | Persistence | Scale-out | Use case |
|---|---|---|---|---|
| `IHostedService` / `BackgroundService` | In-process | None | No | Simple periodic tasks |
| **Hangfire** | In-process + persistence | SQL/Redis/MongoDB | ✓ | General purpose, retry, schedules |
| **Quartz.NET** | In-process | SQL | ✓ | Complex cron-based scheduling |
| **Azure Service Bus** | Distributed messaging | Cloud | ✓ | Cross-service communication |
| **Mass Transit** | Message bus abstraction | Multiple | ✓ | Microservices |

```csharp
// Hangfire setup
builder.Services.AddHangfire(config =>
    config.UsePostgreSqlStorage(connectionString));
builder.Services.AddHangfireServer(opts => {
    opts.WorkerCount = 5;
    opts.Queues = new[] { "critical", "default", "low" };
});

app.UseHangfireDashboard("/hangfire"); // UI at /hangfire

// Enqueue a fire-and-forget job
BackgroundJob.Enqueue(() => emailService.SendWelcomeEmailAsync(userId));

// Schedule a delayed job
BackgroundJob.Schedule(() => emailService.SendReminderAsync(userId),
    TimeSpan.FromDays(3));

// Recurring job (cron)
RecurringJob.AddOrUpdate("daily-report", () => reportService.GenerateDailyAsync(),
    Cron.Daily(9, 0)); // 9:00 AM daily

// Continuation job (run B after A)
var jobId = BackgroundJob.Enqueue(() => processOrder(orderId));
BackgroundJob.ContinueJobWith(jobId, () => sendConfirmationEmail(orderId));
```

---

## Q5. How do you implement email sending in ASP.NET Core?
**Answer:**
```csharp
// Option 1: SMTP with MailKit (recommended over System.Net.Mail)
public class SmtpEmailService(IOptions<SmtpSettings> settings) : IEmailService
{
    public async Task SendAsync(EmailMessage message)
    {
        var mime = new MimeMessage();
        mime.From.Add(new MailboxAddress("TaskFlow", settings.Value.FromEmail));
        message.To.ForEach(to => mime.To.Add(MailboxAddress.Parse(to)));
        mime.Subject = message.Subject;
        mime.Body = new TextPart(message.IsHtml ? "html" : "plain") { Text = message.Body };

        using var client = new MailKit.Net.Smtp.SmtpClient();
        await client.ConnectAsync(settings.Value.Host, settings.Value.Port, settings.Value.UseSsl);
        await client.AuthenticateAsync(settings.Value.Username, settings.Value.Password);
        await client.SendAsync(mime);
        await client.DisconnectAsync(true);
    }
}

// Option 2: SendGrid (cloud email service)
public class SendGridEmailService(ISendGridClient client) : IEmailService
{
    public async Task SendAsync(EmailMessage msg)
    {
        var email = MailHelper.CreateSingleEmail(
            from: new EmailAddress("noreply@myapp.com", "MyApp"),
            to:   new EmailAddress(msg.To.First()),
            subject: msg.Subject,
            plainTextContent: msg.TextBody,
            htmlContent: msg.HtmlBody);
        var response = await client.SendEmailAsync(email);
    }
}
```

---

## Q6. How do you use Razor/HTML templates for emails?
**Answer:**
```csharp
// Using RazorLight or FluentEmail.Razor
// Install: FluentEmail.Core FluentEmail.Razor FluentEmail.SendGrid

builder.Services.AddFluentEmail("noreply@myapp.com", "MyApp")
    .AddRazorRenderer()
    .AddSendGridSender(apiKey);

// Email template: /EmailTemplates/WelcomeEmail.cshtml
@model WelcomeEmailModel
<!DOCTYPE html>
<html>
<body>
  <h1>Welcome, @Model.UserName!</h1>
  <p>Your account has been created successfully.</p>
  <a href="@Model.ConfirmUrl">Confirm Your Email</a>
</body>
</html>

// Send templated email
public async Task SendWelcomeAsync(string email, string userName, string confirmUrl)
{
    await _emailSender
        .To(email)
        .Subject("Welcome to MyApp!")
        .UsingTemplateFromFile(
            Path.Combine("EmailTemplates", "WelcomeEmail.cshtml"),
            new WelcomeEmailModel { UserName = userName, ConfirmUrl = confirmUrl })
        .SendAsync();
}
```

---

## Q7. How do you queue emails as background jobs?
**Answer:**
```csharp
// Always send emails asynchronously — never block HTTP request
// Pattern: enqueue email in request, background job sends it

// Service enqueues instead of sending directly
public class UserService(IBackgroundJobClient jobClient)
{
    public async Task RegisterAsync(RegisterDto dto)
    {
        var user = await CreateUserAsync(dto);

        // Don't await email here — enqueue as background job
        jobClient.Enqueue<IEmailService>(svc =>
            svc.SendWelcomeAsync(user.Email, user.Name, BuildConfirmUrl(user)));

        // HTTP request completes immediately
        return mapper.Map<UserDto>(user);
    }
}

// Email service job — retried automatically on failure
[AutomaticRetry(Attempts = 3, DelaysInSeconds = new[] { 60, 300, 3600 })]
public async Task SendWelcomeAsync(string email, string name, string confirmUrl)
{
    // Actual email sending here
}
```

---

## Q8. What is chunked upload and when is it needed?
**Answer:**
```csharp
// For large files (> 100MB), split into chunks on client and reassemble on server

// Client (Angular) — split and send chunks
async uploadLargeFile(file: File): Promise<void> {
    const chunkSize = 5 * 1024 * 1024; // 5MB chunks
    const totalChunks = Math.ceil(file.size / chunkSize);
    const uploadId = crypto.randomUUID();

    for (let i = 0; i < totalChunks; i++) {
        const chunk = file.slice(i * chunkSize, (i + 1) * chunkSize);
        const formData = new FormData();
        formData.append('chunk', chunk);
        formData.append('uploadId', uploadId);
        formData.append('chunkIndex', i.toString());
        formData.append('totalChunks', totalChunks.toString());
        await this.http.post('/api/upload/chunk', formData).toPromise();
        this.progress.set(((i + 1) / totalChunks) * 100);
    }
    await this.http.post('/api/upload/complete', { uploadId }).toPromise();
}

// Server — store chunks and reassemble
[HttpPost("chunk")]
public async Task<IActionResult> UploadChunk(UploadChunkDto dto)
{
    var chunkPath = Path.Combine(_tempDir, dto.UploadId, $"{dto.ChunkIndex}.part");
    Directory.CreateDirectory(Path.GetDirectoryName(chunkPath)!);
    using var stream = dto.Chunk.OpenReadStream();
    await using var file = System.IO.File.Create(chunkPath);
    await stream.CopyToAsync(file);
    return Ok();
}

[HttpPost("complete")]
public async Task<IActionResult> CompleteUpload([FromBody] CompleteUploadDto dto)
{
    // Combine all chunks into final file
    var parts = Directory.GetFiles(Path.Combine(_tempDir, dto.UploadId)).OrderBy(f => f);
    using var final = System.IO.File.Create(Path.Combine(_uploadDir, dto.FileName));
    foreach (var part in parts)
    {
        await using var chunk = System.IO.File.OpenRead(part);
        await chunk.CopyToAsync(final);
    }
    Directory.Delete(Path.Combine(_tempDir, dto.UploadId), true); // cleanup
    return Ok();
}
```

---

## Q9. What is Hangfire and what are its job types?
**Answer:**
```csharp
// 1. Fire-and-forget — execute once, immediately (or after delay)
var id = BackgroundJob.Enqueue(() => Console.WriteLine("Fire and forget"));

// 2. Delayed — execute once after a delay
BackgroundJob.Schedule(() => SendReminder(userId), TimeSpan.FromDays(1));
BackgroundJob.Schedule(() => SendReminder(userId), DateTime.UtcNow.AddHours(24));

// 3. Recurring — execute on a schedule (cron)
RecurringJob.AddOrUpdate("cleanup", () => CleanupOldFiles(), "0 2 * * *"); // 2AM daily
RecurringJob.AddOrUpdate("report",  () => GenerateReport(),  Cron.Weekly(DayOfWeek.Monday, 8));

// 4. Continuation — run after another job completes
var aId = BackgroundJob.Enqueue(() => ProcessOrder(orderId));
BackgroundJob.ContinueJobWith(aId, () => SendConfirmation(orderId));

// 5. Batch (Hangfire Pro) — group of jobs, trigger callback on completion
var batchId = BatchJob.StartNew(batch => {
    batch.Enqueue(() => ProcessChunk(1));
    batch.Enqueue(() => ProcessChunk(2));
    batch.Enqueue(() => ProcessChunk(3));
});
BatchJob.ContinueBatchWith(batchId, batch => {
    batch.Enqueue(() => SendCompletionEmail());
});
```

---

## Q10. What is the outbox pattern for reliable email delivery?
**Answer:**
```csharp
// Store emails in database with the same transaction as domain changes
// Background worker reads outbox and sends emails

public class EmailOutboxEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string To { get; set; } = "";
    public string Subject { get; set; } = "";
    public string HtmlBody { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int RetryCount { get; set; }
    public DateTime? SentAt { get; set; }
    public string? Error { get; set; }
}

// Service stores email in same transaction as business change
public async Task RegisterAsync(RegisterDto dto)
{
    var user = new User { Email = dto.Email };
    _db.Users.Add(user);
    _db.EmailOutbox.Add(new EmailOutboxEntry {
        To = dto.Email,
        Subject = "Welcome!",
        HtmlBody = BuildWelcomeEmail(user)
    });
    await _db.SaveChangesAsync(); // both in one transaction

    // Background worker sends the email
}

// Background worker processes outbox
public class EmailOutboxWorker(AppDbContext db, IEmailService email) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            var pending = await db.EmailOutbox
                .Where(e => e.SentAt == null && e.RetryCount < 3)
                .OrderBy(e => e.CreatedAt).Take(10).ToListAsync(ct);

            foreach (var entry in pending)
            {
                try {
                    await email.SendAsync(entry.To, entry.Subject, entry.HtmlBody);
                    entry.SentAt = DateTime.UtcNow;
                } catch (Exception ex) {
                    entry.RetryCount++;
                    entry.Error = ex.Message;
                }
            }
            await db.SaveChangesAsync(ct);
            await Task.Delay(TimeSpan.FromSeconds(30), ct);
        }
    }
}
```
