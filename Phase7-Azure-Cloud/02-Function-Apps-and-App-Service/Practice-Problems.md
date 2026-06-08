# Topic 2: Function Apps & App Service — Practice Problems

> Five hands-on exercises. The first four use the C# project scaffolded in `PracticeProblemsSolutions/TaskFlow.Functions/`; the last targets App Service.

**Concept tags:** `azure-functions` `isolated-worker` `app-service` `managed-identity` `key-vault` `app-insights` `deployment-slots`

**Setup:**

```bash
# Tools
dotnet --version                       # 8.0 or later
func --version                         # Azure Functions Core Tools v4
az --version

# Resource group from Topic 1
az group show -n taskflow-dev-eus-rg
```

If the RG isn't there, re-run your Topic 1 P5 bootstrap first.

---

## P1 — HTTP-Triggered Function: `/ping` and `/echo`  *(Easy)*

**Tags:** `http-trigger` `isolated-worker`

### Requirements

In `TaskFlow.Functions`, implement two HTTP-triggered functions:

1. **GET `/api/ping`** — returns `200 OK` with body `pong` and a `X-Hostname` response header set to `Environment.MachineName`.
2. **POST `/api/echo`** — accepts JSON `{ "message": "..." }` and returns the same payload plus a server timestamp.

Both must:

- Use **Authorization Level = Function** (key-protected).
- Log entry/exit at `Information` and exceptions at `Error`.
- Return `400 Bad Request` for bad JSON.

Run locally with `func start`. Verify both endpoints with curl/Postman.

### Deliverable

Commit `HttpTriggers/PingFunction.cs` and `HttpTriggers/EchoFunction.cs`.

### Look-fors (rubric)

- [ ] Both endpoints work via `func start` on `http://localhost:7071`.
- [ ] `400` returned for invalid JSON (test with `{`).
- [ ] Log lines visible: `Information: Executing 'Functions.Ping'`.
- [ ] No secrets / connection strings hardcoded.

---

## P2 — Timer-Triggered Function: Daily Cleanup  *(Easy)*

**Tags:** `timer-trigger` `cron`

### Requirements

Add `TimerTriggers/StaleTokenSweeper.cs` that runs **every minute during local dev** and **every day at 03:00 UTC in Azure**. Use a setting (`StaleTokenSchedule`) for the CRON, with `local.settings.json` overriding to `"0 */1 * * * *"`.

The function body:
- Logs a fake "scanned N tokens, removed M" message.
- Reads N (range) from another setting `StaleTokenScanRange` (default 1–100).

### Deliverable

`TimerTriggers/StaleTokenSweeper.cs` plus updated `local.settings.json` (excluded from commit; commit `local.settings.example.json`).

### Look-fors

- [ ] CRON pulled from configuration, not hard-coded.
- [ ] Frequencies differ between local and the (planned) Azure setting — document in your README.
- [ ] No real database call yet — placeholder is fine; the focus is wiring.

---

## P3 — Queue-Triggered Function: Email Dispatcher  *(Medium)*

**Tags:** `queue-trigger` `bindings` `dlq`

### Requirements

Implement `QueueTriggers/EmailDispatcher.cs` that:

- Triggers on messages in a Storage Queue named `email-queue`.
- Deserializes `{ "to": "...", "subject": "...", "body": "..." }`.
- Logs the send and pretends to send (no SendGrid in this exercise).
- On exception, lets the function rethrow so Functions runtime puts the message on `email-queue-poison` after 5 dequeues.

You also need a small **HTTP function** `QueueTriggers/EnqueueEmail.cs` that lets you POST to `/api/enqueue-email` to drop a message on the queue (so you can test end-to-end without the Storage Explorer).

Use the **Azure SDK** to send (no output binding) so you can apply Managed Identity later.

### Deliverable

`QueueTriggers/EmailDispatcher.cs` + `QueueTriggers/EnqueueEmail.cs`. Document the storage account / connection setting names.

### Look-fors

- [ ] Local: posting to `/api/enqueue-email` causes the dispatcher to log within seconds.
- [ ] Bad JSON in the queue → goes to `email-queue-poison` after retries.
- [ ] No connection string in code; it's read from `Storage` setting.

---

## P4 — Deploy the Function App + Wire Up Managed Identity  *(Medium)*

**Tags:** `deployment` `managed-identity` `key-vault`

### Requirements

1. **Provision** a Function App in `taskflow-dev-eus-rg`:
   - Plan: Consumption (Linux).
   - Runtime: `dotnet-isolated 8.0`.
   - Backed by a new Storage Account `sttaskflowfuncdev<suffix>`.
   - Application Insights enabled.
2. **Assign** the User-Assigned MI from Topic 1 (`mi-taskflow-app-dev`) to the Function App.
3. **Add** an App Setting `Sample__ConnectionString` as a **Key Vault reference** to the secret you created in Topic 1.
4. **Deploy** your `TaskFlow.Functions` project via `func azure functionapp publish` or `az functionapp deployment source config-zip`.
5. **Verify**: hit the `/api/ping` URL with the function key.

### Deliverable

`P4-deploy.sh` script + `P4-deploy.md` write-up (what you ran, what worked, what didn't).

### Look-fors

- [ ] Function App appears in the RG with the right runtime stack.
- [ ] System-or-User MI shows up under Identity blade.
- [ ] App Setting shows ✓ "Key Vault reference" status.
- [ ] `/api/ping` returns `pong` from the Azure URL.

---

## P5 — App Service: Deploy a Minimal API with a Staging Slot  *(Medium)*

**Tags:** `app-service` `slots` `swap`

### Requirements

1. Scaffold a tiny ASP.NET Core minimal API (`TaskFlow.Api.Stub` — provided in `PracticeProblemsSolutions/`).
2. Provision an **App Service plan** (Standard S1) and a **Web App** in `taskflow-dev-eus-rg`.
3. Create a **staging slot** named `staging`.
4. Deploy the API to **staging**, smoke test it, then **swap** to production.
5. Roll back the swap as a drill.

### Deliverable

`P5-appservice.sh` (provisioning) + `P5-deploy.md` (steps + observations).

### Look-fors

- [ ] Both prod and staging URLs serve the same `/health` endpoint.
- [ ] Swap completes < 30 s, no 5xx during the swap (verify in App Insights).
- [ ] `WEBSITE_SLOT_NAME` env var differs in each slot — your code logs it, proving config separation.
- [ ] Roll-back swap works.

---

## Submission Checklist

- [ ] All 5 deliverables committed.
- [ ] `TaskFlow.Functions` builds with `dotnet build`.
- [ ] No secrets in commits (`local.settings.json` is gitignored).
- [ ] `README.md` lists each problem and how to verify it.

---

## Stretch Goals

- Add **Bicep** for the entire stack and replace the shell scripts.
- Add **OpenTelemetry** explicitly and ship traces alongside App Insights.
- Replace Storage Queue with **Service Bus** queue (preview Topic 5).
