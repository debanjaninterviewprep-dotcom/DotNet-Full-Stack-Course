# Topic 9: Phase 7 Revision Test

## About This Test

A **comprehensive revision test** covering all 8 topics of Phase 7: Azure Cloud Development & Services. Designed to verify you can architect, deploy, secure, and govern an Azure-hosted system before moving to Phase 8 (DevOps & IaC).

**Rules:**
- Solve every problem without referring to your earlier notes.
- Target time: 4–5 hours for the full test.
- Write production-quality code; use Managed Identity, no static secrets.
- Use proper tagging, naming, error handling.
- After finishing, tell me "check" for a detailed review.

---

## Section A: Quick-Fire Concepts (12 Questions)

Answer each in **1–3 sentences**. Write your answers in `Section-A.md`.

1. What's the difference between a **Management Group**, a **Subscription**, and a **Resource Group**?
2. Compare **System-Assigned** and **User-Assigned** Managed Identity. When would you pick each?
3. Why is `Storage Blob Data Reader` a *better* choice than `Reader` for an app that reads blobs?
4. Difference between **Functions Consumption** and **Premium** plans.
5. In the .NET Functions Isolated worker model, what do you write to deserialize an HTTP body? (Show one line.)
6. What is the **policy pipeline** in APIM? Name the four stages.
7. Why prefer a **user-delegation SAS** over an **account-key SAS**?
8. When would you choose **Service Bus** over **Storage Queue**?
9. What is **cache stampede** and one way to mitigate it?
10. What's the difference between **Azure Policy `Deny`** and **AWS SCPs**?
11. Define **OIDC Workload Identity Federation** in one sentence.
12. What does **`AbortOnConnectFail = false`** do for `IConnectionMultiplexer` and why does it matter in production?

---

## Section B: Architecture & Diagram (3 Questions)

Use **Mermaid** for diagrams.

### B1 — End-to-End Flow

Draw a request flow from a SPA user clicking *"Upload Attachment"* to:
- APIM →
- Function App (HTTP trigger) →
- Blob Storage (private) →
- Queue (Service Bus) →
- Background Function →
- Table Storage (audit).

Annotate every arrow with **protocol** and **identity used**.

### B2 — Governance Hierarchy

Draw the MG/sub/RG hierarchy you'd use for TaskFlow with three environments (`dev`, `staging`, `prod`) and a shared platform sub. Indicate where each policy initiative is assigned.

### B3 — Cross-Cloud Plan (200 words)

A new requirement lands: TaskFlow must call AWS Textract for OCR, with no static AWS access keys. Describe how you'd wire it (federation, role, trust policy, runtime token exchange).

---

## Section C: Code Reading (4 Questions)

For each snippet, **identify the bug** and write a corrected version.

### C1.
```csharp
var blob = new BlobServiceClient(
    "DefaultEndpointsProtocol=https;AccountName=stx;AccountKey=BASE64==;EndpointSuffix=core.windows.net");
```

### C2.
```csharp
public async Task<TaskDto?> GetAsync(string id)
{
    var v = await _redis.StringGetAsync($"task:{id}");
    if (v.HasValue) return JsonSerializer.Deserialize<TaskDto>(v!);
    var t = await _repo.FindAsync(id);
    await _redis.StringSetAsync($"task:{id}", JsonSerializer.Serialize(t));
    return t;
}
```

### C3.
```csharp
processor.ProcessMessageAsync += async args =>
{
    var body = args.Message.Body.ToString();
    await DoWork(body);   // can throw
    await args.CompleteMessageAsync(args.Message);
};
```

### C4. (APIM XML)
```xml
<inbound>
  <validate-jwt header-name="Authorization">
    <openid-config url="https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration" />
  </validate-jwt>
</inbound>
```

---

## Section D: Hands-On Build (Pick 2 of 3)

Choose two and produce working code + scripts in `Section-D/`.

### D1 — Secure Blob Upload Pipeline

Build:
- A Function App with HTTP trigger `POST /api/upload`.
- Accepts `multipart/form-data` (file).
- Stores in a private container with key `{userId}/{guid}-{filename}`.
- Returns a **10-minute user-delegation SAS** for download.
- Authenticates client via APIM JWT (just include the policy XML).
- Function uses Managed Identity to talk to Storage.

### D2 — Pub/Sub Outbox

Build:
- A small ASP.NET Core API with one POST `/orders` that:
  - Inserts a row in an in-memory store.
  - Inserts an outbox row in the same transaction (use a real DB if you have one set up; in-memory acceptable for the test).
- A worker that drains the outbox, publishes to Service Bus topic `orders-events` with `Type=order.created`.
- A second consumer subscription that prints messages.

Demonstrate: kill the worker mid-flight, restart — no duplicate publishes (idempotency by `outboxId` as `MessageId`).

### D3 — Governance Drift Detection

Build a Function App (timer-trigger) that:
- Lists all storage accounts in your subscription.
- For each, checks: `allowSharedKeyAccess == false`, `minimumTlsVersion == TLS1_2`, `allowBlobPublicAccess == false`.
- Writes non-compliant accounts to a Service Bus topic `compliance-violations`.

Bonus: send a Teams/Slack webhook for each violation.

---

## Section E: Cost & Performance (3 Questions)

### E1.
You have 1 M Function executions per day, average duration 200 ms, 256 MB RAM. Estimate the **monthly bill** at Consumption pricing. Show your math.

### E2.
APIM Consumption tier costs per million requests vs Basic v2's hourly cost — when does Basic v2 become cheaper? Show a break-even calculation.

### E3.
Your Redis hit rate is 40%. Each miss costs 200 ms (DB). With 100 RPS, what's the average latency? Suggest two ways to push hit rate above 80%.

---

## Section F: Security Audit (2 Questions)

### F1.
Review this checklist for a TaskFlow production stack and **mark each item Pass / Fail / Needs work**, with a 1-sentence reason:

- [ ] All app secrets in Key Vault, referenced by App Settings.
- [ ] Storage account: shared key access disabled.
- [ ] Function App uses user-assigned MI.
- [ ] APIM JWT policy validates `aud` and `scp`.
- [ ] Service Bus uses connection string in App Settings.
- [ ] Redis access via primary key in `appsettings.json`.
- [ ] No `Owner` role assignments at subscription except 2 humans.
- [ ] Defender for Cloud Free tier on.
- [ ] Diag logs flow to Log Analytics for every resource (DINE).
- [ ] Public network access enabled on storage accounts.

### F2.
Pick the **two most dangerous** failures from F1 and write a remediation plan (steps + commands).

---

## Submission

When you finish, tell me **"check"** and I will:
- Score each section 0–10 with detailed feedback.
- Identify weakest areas to revisit.
- Recommend whether you're ready for Phase 8.

Total maximum score: **100**. Passing: **70**.
