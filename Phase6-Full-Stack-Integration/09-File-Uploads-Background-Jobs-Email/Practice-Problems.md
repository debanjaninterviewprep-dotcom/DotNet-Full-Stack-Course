# Topic 9 — Practice Problems

> Project: `PracticeProblemsSolutions/` — ASP.NET Core webapi with `MultipartReader` uploads, Hangfire, and MailKit. Run `docker compose up` (Mailpit) then `dotnet run`.

---

## P1 — Streaming upload endpoint with size + type guards

**Goal:** `POST /api/v1/tasks/{taskId}/attachments` accepts up to 50 MB via `multipart/form-data` without buffering.

**Tasks**
1. Decorate the action with `[DisableFormValueModelBinding]`, `[RequestSizeLimit(50_000_000)]`, `[RequestFormLimits(MultipartBodyLengthLimit = 50_000_000)]`.
2. Use `MultipartReader` to enumerate sections; reject when `Content-Disposition` lacks a filename.
3. Validate content type against an allow-list (`image/png`, `image/jpeg`, `application/pdf`, `text/plain`).
4. Sanitize filename (strip `..`, null bytes, control chars; keep only `Path.GetFileName(...)`).
5. Compute SHA-256 while streaming and return `{ id, key, size, sha256 }` from the action.

**Acceptance**
- Uploading 60 MB returns 413 (Request Entity Too Large) without buffering bytes into memory.
- Uploading `evil.exe` renamed to `evil.png` is detected via magic-byte check (bonus) and rejected with 422.
- Same content uploaded twice returns the same SHA-256.

---

## P2 — `IFileStorage` with local + Azure implementations

**Goal:** A storage abstraction with a `LocalDiskStorage` for dev and a `AzureBlobStorage` stub for prod.

**Tasks**
1. Define `IFileStorage` (`SaveAsync`, `OpenReadAsync`, `DeleteAsync`, `GetReadUrl`).
2. Implement `LocalDiskStorage` writing to `wwwroot/uploads/{folder}/{guid}_{name}` and returning a relative URL. Do **not** serve uploads from `wwwroot/` — write to `App_Data/uploads/` and expose via a controller action that sets `Content-Disposition: attachment`.
3. Implement `AzureBlobStorage` as a stub that throws `NotImplementedException` but compiles — wire `Azure.Storage.Blobs`.
4. Choose the implementation via `Storage:Provider` config value.
5. Write a unit test for `LocalDiskStorage` round-trip (save → open → assert SHA-256 matches input).

**Acceptance**
- Switching `Storage:Provider` between `Local` and `Azure` boots the app in either case (Azure stub will throw on first call — that's fine for P2).
- Files written by the local provider are not directly servable from `wwwroot/`.
- Round-trip test passes deterministically.

---

## P3 — Hangfire setup + virus-scan + thumbnail jobs

**Goal:** Wire Hangfire (SQL or in-memory storage), enqueue `ScanFileJob` and `MakeThumbnailJob` after upload, and protect the dashboard.

**Tasks**
1. Install `Hangfire.AspNetCore`. Use in-memory storage (`Hangfire.MemoryStorage`) for the practice scaffold; document SQL setup in README.
2. Configure server with named queues `default`, `scans`, `emails`.
3. Define `ScanFileJob` (placeholder that just sleeps 1 s and marks `Attachment.Status = Available`). Annotate with `[Queue("scans")]`.
4. Define `MakeThumbnailJob` for image content types only.
5. Map `/hangfire` dashboard guarded by `IDashboardAuthorizationFilter` requiring `Admin` role.

**Acceptance**
- After upload, both jobs appear in the dashboard and complete.
- Anonymous request to `/hangfire` returns 401/403.
- Killing the API mid-job and restarting causes the job to resume (verify with SQL storage; document for in-memory caveat).

---

## P4 — `IEmailSender` + Mailpit + SMTP/SendGrid implementations

**Goal:** Send templated emails via SMTP in dev; abstraction allows swapping to SendGrid in prod.

**Tasks**
1. Define `IEmailSender` and `EmailMessage` record.
2. Implement `SmtpEmailSender` using `MailKit.Net.Smtp.SmtpClient`. Read host/port/user/pass from config.
3. Implement `SendGridEmailSender` stub (compiles, throws until configured).
4. Add `docker-compose.yml` with Mailpit (`axllent/mailpit`).
5. Build a tiny `EmailTemplater` that loads `Application/Emails/Templates/{name}.html` and substitutes `{{variable}}` placeholders.

**Acceptance**
- Calling `_email.SendAsync(new("you@example.com","Hello","<p>Hi</p>"))` is visible in Mailpit at `http://localhost:8025`.
- Switching the provider via config does not require code changes.
- Templater throws a clear error when a placeholder is missing — never sends the raw `{{name}}` to the user.

---

## P5 — Welcome-email job + outbox pattern

**Goal:** Send a welcome email when a user registers, with at-least-once delivery via the outbox.

**Tasks**
1. Add `OutboxMessages` table (Id, OccurredAt, Type, Payload, ProcessedAt, Error).
2. In the registration handler, write the user **and** an `OutboxMessage(Type="UserRegistered", Payload={UserId})` in one `SaveChangesAsync` (single transaction).
3. Recurring `OutboxRelayJob` (every 5 s) selects `WHERE ProcessedAt IS NULL`, dispatches to a typed handler (`UserRegisteredHandler` enqueues `SendWelcomeEmailJob`), and marks processed.
4. `SendWelcomeEmailJob.ExecuteAsync(Guid userId)` is **idempotent** — checks `User.WelcomeEmailSentAt` before sending; sets it after.
5. Unit-test idempotency: invoke the job twice, assert `_email.SendAsync` was called once.

**Acceptance**
- Registering a user → email visible in Mailpit within 10 s.
- Killing the API after `SaveChangesAsync` but before `Enqueue` would normally drop the email — with the outbox, the relay catches it on next tick.
- Replaying the outbox row manually does not send a duplicate email.

---

## P6 — Recurring digest + cleanup jobs

**Goal:** Daily 08:00 UTC digest email per user; hourly cleanup of soft-deleted tasks older than 30 days.

**Tasks**
1. `DigestEmailJob.SendAllAsync(CancellationToken)` — finds users with notification preference enabled, enqueues a per-user `SendDigestEmail(Guid userId)` so each runs independently.
2. `RecurringJob.AddOrUpdate<DigestEmailJob>("daily-digest", j => j.SendAllAsync(CancellationToken.None), Cron.Daily(8))`.
3. `CleanupJob.PurgeAsync(CancellationToken)` — hard-deletes `Task` rows where `IsDeleted = true AND DeletedAt < UtcNow - 30d`.
4. `RecurringJob.AddOrUpdate<CleanupJob>("hourly-cleanup", j => j.PurgeAsync(CancellationToken.None), Cron.Hourly)`.
5. Add `[AutomaticRetry(Attempts = 3, OnAttemptsExceeded = AttemptsExceededAction.Delete)]` so failed runs don't pile up forever.

**Acceptance**
- Both jobs appear in the dashboard's "Recurring" tab with the correct schedule.
- Triggering "Run now" on `daily-digest` enqueues one per-user job per matching user.
- Cleanup is verifiably idempotent — running it twice doesn't double-delete anything (already gone).
