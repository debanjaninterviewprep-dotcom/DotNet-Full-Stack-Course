# Topic 4: Azure Storage — Blob, Table & Queue

> An Azure **Storage Account** is the most useful 13-character name in Azure. It bundles four data services (Blob, Table, Queue, File) plus disks behind a single global namespace and a unified RBAC model. This topic teaches you when to use each, how to access them with **Managed Identity** instead of connection strings, and the patterns TaskFlow uses for file uploads, denormalized lookups, and async work.

---

## 1. The Storage Account: One Container, Four Services

| Service | Stores | API style | TaskFlow use |
|---|---|---|---|
| **Blob** | Unstructured files (images, PDFs, logs) | REST + SDKs | Task attachments, exported reports |
| **Table** | Schema-less key/value rows (NoSQL) | Partition+Row keys | Hot lookups (per-user activity, audit) |
| **Queue** | Simple FIFO messages | Send / receive / delete | Background work decoupling |
| **File** | SMB/NFS shares | Mountable file system | Lift-and-shift legacy apps |

Plus: managed disks, `azcopy` for bulk transfer, lifecycle management, soft delete, immutability, change feed, etc.

> Single storage account = single billing line, single SLA, RBAC scope. Many apps share one. Some isolate per-app. Common compromise: one **shared** account for queue/table, one **per-workload** account for blobs.

---

## 2. Storage Account Settings That Matter

| Setting | Common choice | Why |
|---|---|---|
| **Performance** | Standard | Premium = higher IOPS for blobs/files; rare in TaskFlow. |
| **Replication** | LRS (3 copies in 1 DC) | Cheap. ZRS for higher resilience, GRS for geo. |
| **Access tier** (blob) | Hot | Frequent access. *Cool*/*Cold*/*Archive* for older data. |
| **Account kind** | StorageV2 | Always. (V1 is legacy.) |
| **Min TLS version** | 1.2 | Mandatory for prod. |
| **Allow blob public access** | **false** | Default deny; opt in per-container if needed. |
| **Hierarchical namespace** | off (Blob), on (Data Lake Gen2) | Big-data workloads only. |
| **Network access** | Selected networks (VNet) or public + firewall | Lock down for prod. |
| **Authorization** | RBAC (Entra) | Disable Shared Key in prod. |

---

## 3. Authentication & Authorization

### Three ways to authenticate (worst → best)

1. **Account key** — full-power admin password. Easy to leak. Use only for emergencies.
2. **SAS token** — time-bound URL with limited rights. Better for client-side scenarios.
3. **Microsoft Entra (RBAC)** — identity-based, audited, no secret to rotate. **Use this.**

### Data-plane RBAC roles

| Role | Grants on |
|---|---|
| `Storage Blob Data Reader` | Read blobs |
| `Storage Blob Data Contributor` | Read/write/delete blobs |
| `Storage Blob Data Owner` | Plus POSIX ACLs (Data Lake) |
| `Storage Queue Data Contributor` | Send / receive / delete queue messages |
| `Storage Queue Data Reader` | Peek messages |
| `Storage Table Data Contributor` | Read/write entities |

> Critical distinction: `Contributor` (without `Data`) is a **management-plane** role — manages the account, *cannot* read your data. Always grant **Data** roles to apps.

### Disabling shared key (recommended)

```bash
az storage account update -g $RG -n $ACCOUNT \
  --allow-shared-key-access false
```

After this, only Entra-authenticated callers work — your app must use Managed Identity.

---

## 4. Blob Storage Deep Dive

### Hierarchy

```
Storage Account ──► Container ──► Blob
       (resource)     (folder)     (file)
```

- Container names: lowercase, 3–63 chars, dash-separated.
- Blob name can include `/` and look like a path; the structure is virtual.

### Blob types

| Type | Optimized for | Use |
|---|---|---|
| **Block** | Most files | Upload, download, replace |
| **Append** | Append-only logs | Audit logs |
| **Page** | Random read/write 512-byte pages | VHD disks (rare in apps) |

### TaskFlow patterns

- **Task attachments**: `attachments` container, blob name `{taskId}/{guid}-{fileName}`.
- **User avatars**: `avatars` container, blob name `{userId}.{ext}`.
- **Generated reports**: `reports` container, blob name `{userId}/{yyyy}/{mm}/{guid}.pdf`.

### Uploading with the SDK + Managed Identity

```csharp
var endpoint = new Uri($"https://{accountName}.blob.core.windows.net");
var blobService = new BlobServiceClient(endpoint, new DefaultAzureCredential());

var container = blobService.GetBlobContainerClient("attachments");
await container.CreateIfNotExistsAsync(PublicAccessType.None);

var blob = container.GetBlobClient($"{taskId}/{Guid.NewGuid()}-{fileName}");
await using var stream = file.OpenReadStream();
await blob.UploadAsync(stream, overwrite: false);
```

### Generating a User-Delegation SAS (for downloads)

When the client must download a blob without going through your API every time, hand out a **time-limited** SAS *signed by Entra* (not by the account key):

```csharp
var userDelegationKey = await blobService.GetUserDelegationKeyAsync(
    DateTimeOffset.UtcNow, DateTimeOffset.UtcNow.AddHours(1));

var sasBuilder = new BlobSasBuilder
{
    BlobContainerName = "attachments",
    BlobName = blobName,
    Resource = "b",
    StartsOn = DateTimeOffset.UtcNow,
    ExpiresOn = DateTimeOffset.UtcNow.AddMinutes(10),
};
sasBuilder.SetPermissions(BlobSasPermissions.Read);

var sas = sasBuilder.ToSasQueryParameters(userDelegationKey, accountName).ToString();
var url = $"{blob.Uri}?{sas}";
```

> **Why user-delegation SAS over account-key SAS:** revocable (rotate the user-delegation key), audited per identity, no shared secret in app config.

### Lifecycle Management (auto-tiering)

Save money by aging blobs:

```json
{
  "rules": [
    {
      "name": "MoveOldAttachments",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool":     { "daysAfterModificationGreaterThan":  30 },
            "tierToArchive":  { "daysAfterModificationGreaterThan": 180 },
            "delete":         { "daysAfterModificationGreaterThan": 365 }
          }
        },
        "filters": { "blobTypes": ["blockBlob"], "prefixMatch": ["attachments/"] }
      }
    }
  ]
}
```

---

## 5. Table Storage (and its bigger sibling, Cosmos Table)

A NoSQL key/value store. Each entity has:

- `PartitionKey` — collocates entities; the lookup unit.
- `RowKey` — uniqueness within a partition.
- Up to 252 custom properties.

### When to choose Table over SQL

- Massive **per-user, per-tenant** lookups where SQL joins aren't needed.
- High write throughput, schema-flexible.
- Audit trails, telemetry, denormalized read models.

### TaskFlow examples

| Use | PartitionKey | RowKey | Properties |
|---|---|---|---|
| User activity feed | `userId` | `inv-{ticks}-{guid}` (descending) | type, taskId, createdAt |
| Per-task audit | `taskId` | `inv-{ticks}-{guid}` | actorId, action, before, after |
| Hot lookup: tasks by tag | `tag-{tagName}` | `taskId` | title, status |

### CRUD with the SDK

```csharp
var tableClient = new TableClient(
    new Uri($"https://{accountName}.table.core.windows.net"),
    "Activity",
    new DefaultAzureCredential());

await tableClient.CreateIfNotExistsAsync();

var entity = new TableEntity("user-42", $"inv-{InvertedTicks(now)}-{Guid.NewGuid():N}")
{
    ["Type"] = "task.created",
    ["TaskId"] = taskId,
    ["At"] = DateTimeOffset.UtcNow,
};
await tableClient.AddEntityAsync(entity);

// Latest 50 events for a user
var query = tableClient.QueryAsync<TableEntity>(
    e => e.PartitionKey == "user-42",
    maxPerPage: 50);
```

> **Inverted ticks trick:** `string.Format("{0:D19}", DateTime.MaxValue.Ticks - DateTime.UtcNow.Ticks)` makes lex order match newest-first. Table stores RowKey ascending only.

---

## 6. Queue Storage

The simplest async messaging in Azure:

- 64 KB max message.
- 7-day default TTL.
- Visibility timeout: invisible to other consumers while one is processing.
- At-least-once delivery (write your handlers idempotently).

### When to choose Storage Queue over Service Bus

| Need | Pick |
|---|---|
| Cheap, simple, < 80 GB total | **Storage Queue** |
| Topics / subscriptions, dead-letter, sessions, transactions | **Service Bus** |
| > 64 KB messages | **Service Bus** |
| FIFO across producers | **Service Bus** (sessions) |

### Producer / Consumer with MI

```csharp
var queue = new QueueClient(
    new Uri($"https://{accountName}.queue.core.windows.net/{queueName}"),
    new DefaultAzureCredential(),
    new QueueClientOptions { MessageEncoding = QueueMessageEncoding.Base64 });

await queue.CreateIfNotExistsAsync();
await queue.SendMessageAsync(JsonSerializer.Serialize(payload));

// Consumer
QueueMessage[] msgs = await queue.ReceiveMessagesAsync(maxMessages: 16, visibilityTimeout: TimeSpan.FromMinutes(1));
foreach (var msg in msgs)
{
    try
    {
        await Process(msg.Body.ToString());
        await queue.DeleteMessageAsync(msg.MessageId, msg.PopReceipt);
    }
    catch
    {
        // Don't delete; visibility timeout will return it. After maxDequeueCount, host moves to <queue>-poison.
    }
}
```

> **Idempotency rule:** assume each message will be delivered ≥ 2 times. Use a deduplication key (message ID, or a unique business key) and an *upsert* on the receiver side.

---

## 7. Networking & Private Endpoints

For production:

1. Disable **public network access**, OR set firewall to *Selected Networks* with your VNet.
2. Add a **Private Endpoint** in the VNet — gives the storage account a private IP.
3. Apps in the VNet (App Service VNet integration, Function Premium) reach storage privately.

This eliminates the public path for data, satisfies most compliance regimes, and prevents data exfiltration even if a key leaks.

---

## 8. Soft Delete, Versioning, Immutability

| Feature | Protects against |
|---|---|
| **Blob soft delete** (default 7 days) | Accidental deletion |
| **Container soft delete** | "Why is the container gone?" panic |
| **Blob versioning** | Overwrites; lets you roll back |
| **Point-in-time restore** | Catastrophic failures |
| **Immutability policy (WORM)** | Tampering — compliance requirement |
| **Change feed** | Audit-grade record of what changed when |

Always enable blob + container soft delete. Cost is negligible; recovery from oopsies is priceless.

---

## 9. Cost Controls

- Pick the right **tier**: Hot vs Cool vs Cold vs Archive (rehydrate latency!).
- Use **Lifecycle Management** to auto-age data.
- Watch **transactions** (each PutBlob is billed; consider batching small writes).
- Compress archive blobs.
- LRS is the cheapest replication; GRS doubles the cost.

---

## 10. Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Use account keys in app code | Use Managed Identity + RBAC |
| Generate SAS with account key | Generate **user-delegation SAS** |
| Make a public-read container "for convenience" | Hand out short-lived SAS URLs |
| One giant container with 100 M blobs flat | Subfolder-name (`{userId}/{date}/...`) by access pattern |
| Use Table for transactional joins | Use SQL/Cosmos for that; Table for high-write key/value |
| Count on FIFO from Storage Queue | Use Service Bus sessions |
| Skip soft delete to save 0.001 cents | Enable it — production sanity |

---

## 11. Choosing the Right Service (TaskFlow Cheat Sheet)

| Scenario | Service |
|---|---|
| Task attachment file | **Blob** |
| User avatar (≤ 1 MB) | **Blob** |
| Per-user activity feed (last 30 days, fast read) | **Table** |
| Heavy relational data (Tasks, Projects) | **SQL DB** (Topic 4 of Phase 5) |
| Background email send | **Storage Queue** (or Service Bus in Topic 5) |
| Reliable cross-service event (with retries, DLQ, sessions) | **Service Bus** (Topic 5) |
| Cache hot lookups | **Redis** (Topic 6) |

---

## Further Reading

- [Choose a data store](https://learn.microsoft.com/azure/architecture/guide/technology-choices/data-store-decision-tree)
- [Storage RBAC built-in roles](https://learn.microsoft.com/azure/storage/blobs/assign-azure-role-data-access)
- [Lifecycle management](https://learn.microsoft.com/azure/storage/blobs/lifecycle-management-overview)
- [User delegation SAS](https://learn.microsoft.com/azure/storage/blobs/storage-blob-user-delegation-sas-create-dotnet)
- [Table design patterns](https://learn.microsoft.com/azure/cosmos-db/table/design-patterns)
