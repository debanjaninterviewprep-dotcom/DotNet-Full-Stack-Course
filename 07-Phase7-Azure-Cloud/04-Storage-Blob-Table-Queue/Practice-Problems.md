# Topic 4: Azure Storage — Practice Problems

> Five exercises across Blob, Table, and Queue. All code uses **Managed Identity** (locally via `az login`), no account keys.

**Concept tags:** `blob` `table` `queue` `managed-identity` `sas` `lifecycle` `idempotency`

**Prereqs:**
- A storage account named `sttaskflowdev<suffix>` in `taskflow-dev-eus-rg`.
- You hold `Storage Blob Data Contributor`, `Storage Table Data Contributor`, `Storage Queue Data Contributor` on it (or its parent RG) for local dev.
- Run `az login`. The C# project uses `DefaultAzureCredential`.

---

## P1 — Provision the Storage Account (Locked Down)  *(Easy)*

**Tags:** `provisioning` `rbac` `min-tls`

### Requirements

Create `P1-storage.sh` that provisions a storage account with:
- StorageV2, Standard LRS.
- TLS 1.2 minimum.
- Public blob access **disabled**.
- Shared key access **disabled** (`--allow-shared-key-access false`).
- Three blob containers: `attachments`, `avatars`, `reports` (private).
- Blob soft delete: 7 days. Container soft delete: 7 days.
- Assign yourself **`Storage Blob Data Contributor`**, **`Storage Table Data Contributor`**, **`Storage Queue Data Contributor`** at the account scope.

### Deliverable

`P1-storage.sh` + `P1-verify.md` showing `az storage account show` output (key fields highlighted).

### Look-fors

- [ ] `allowSharedKeyAccess: false`
- [ ] `minimumTlsVersion: TLS1_2`
- [ ] Soft delete enabled on both blob and container.
- [ ] All three RBAC role assignments visible: `az role assignment list --assignee <you>`.

---

## P2 — Blob Upload + User-Delegation SAS  *(Medium)*

**Tags:** `blob` `sas` `entra-id`

### Requirements

In `TaskFlow.Storage.Console`, add commands:
- `upload <localFile> <taskId>` — uploads to `attachments/{taskId}/{guid}-{fileName}`.
- `download-link <blobPath>` — returns a 10-minute **user-delegation SAS** URL.
- `download <localOut> <blobPath>` — downloads via the SDK (sanity check).

Constraints:
- No account key, anywhere.
- Don't overwrite existing blobs (`overwrite: false`).
- Print blob URL + content type.

### Deliverable

`Commands/UploadCommand.cs`, `Commands/SasCommand.cs`, `Commands/DownloadCommand.cs`. `P2-demo.md` with sample runs.

### Look-fors

- [ ] Re-upload of the same path returns a 409 — proves `overwrite=false`.
- [ ] SAS URL works in a browser, expires after 10 minutes.
- [ ] All clients use `DefaultAzureCredential`.

---

## P3 — Table Storage: Per-User Activity Feed  *(Medium)*

**Tags:** `table` `partition-key` `inverted-ticks`

### Requirements

Implement an `IActivityLog` service over Table Storage:
- `Append(userId, type, taskId, payload)` — inserts an entity to table `Activity`, partition `userId`, RowKey `inv-{invertedTicks}-{guid}`.
- `RecentForUser(userId, take)` — returns the `take` most recent entries.
- `ByTask(taskId, fromUtc, toUtc)` — secondary view; document why this is **expensive** in Table Storage.

CLI commands: `log-activity`, `list-activity`, `task-activity`.

### Deliverable

`Services/ActivityLog.cs` + `Commands/ActivityCommands.cs`.

### Look-fors

- [ ] RowKey uses inverted ticks so `RecentForUser` can use `Take(n)` without sorting.
- [ ] Code paginates if `take > 1000` (Table page size).
- [ ] You explain in `P3-notes.md` why `ByTask` requires either a secondary table or a scan, and pick one.

---

## P4 — Queue Producer + Idempotent Consumer  *(Medium)*

**Tags:** `queue` `idempotency` `dlq`

### Requirements

Two CLI commands:
- `enqueue <type> <payload>` — adds a JSON message to `work-queue`.
- `consume` — pulls messages, processes, deletes. Idempotency: keep an in-memory `HashSet<string>` of processed `messageId`s. After 5 dequeues, the runtime moves to `work-queue-poison`; demonstrate this by intentionally throwing for `type==fail`.

### Deliverable

`Commands/QueueCommands.cs` + `P4-runlog.md` showing a successful round-trip and a poisoned message.

### Look-fors

- [ ] Consumer uses `ReceiveMessagesAsync` with explicit visibility timeout.
- [ ] Failed messages re-appear after the timeout, until eventually moved to poison.
- [ ] Consumer re-runs without double-processing the same message ID.

---

## P5 — Lifecycle, Soft Delete & Recovery Drill  *(Hard)*

**Tags:** `lifecycle` `soft-delete` `versioning`

### Requirements

1. Add a **Lifecycle Management** policy to:
   - Tier `attachments/` blobs to *Cool* after 30 days, *Cold* after 90, *Archive* after 180.
   - Delete blobs in `reports/` after 365 days.
2. Enable **blob versioning** on the account.
3. Drill: upload a blob, overwrite it, delete it, then **restore** the previous version using soft delete + versioning.
4. Document the recovery commands.

### Deliverable

`P5-lifecycle.json` (the policy) + `P5-drill.md` (commands + outputs).

### Look-fors

- [ ] Policy is set: `az storage account management-policy show`.
- [ ] After delete, blob is recoverable: `az storage blob undelete`.
- [ ] After overwrite, you can promote a previous version.

---

## Submission Checklist

- [ ] All commands compile and run via `dotnet run -- <command>`.
- [ ] No account keys committed (run `git secrets --scan` if you have it).
- [ ] `README.md` lists every CLI verb and what it does.

---

## Stretch Goals

- Add a **Private Endpoint** for the storage account; reach it from a Function App with VNet integration.
- Replace the consumer's in-memory dedup with a Table-Storage-backed idempotency cache.
- Implement retry-with-backoff on transient `Azure.RequestFailedException`s.
