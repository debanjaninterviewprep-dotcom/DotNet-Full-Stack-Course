# Topic 5: Logic Apps & Service Bus — Practice Problems

> Five exercises that turn TaskFlow's queue traffic into a real pub/sub event bus, with DLQ handling and a Logic App glueing in email.

**Concept tags:** `service-bus` `topics` `subscriptions` `dlq` `sessions` `logic-apps` `idempotency`

**Prereqs:** RG `taskflow-dev-eus-rg`. You'll provision a Service Bus namespace and a Logic App (Consumption).

---

## P1 — Provision Service Bus + Topic + Three Subscriptions  *(Easy)*

**Tags:** `service-bus` `topics` `filters`

### Requirements

`P1-servicebus.sh` provisions:
- Namespace `sb-taskflow-dev-<suffix>` (Standard tier).
- Topic `tasks-events` with duplicate detection (10-min window).
- Subscriptions:
  - `audit-log` (no filter)
  - `email-notify` (correlation filter `type='task.assigned'`)
  - `metrics` (SQL filter `source='api' AND priority > 0`)
- All subscriptions: `MaxDeliveryCount=5`, dead-letter on filter eval errors.
- Grant your user `Azure Service Bus Data Owner` at namespace scope (for local dev).

### Deliverable

`P1-servicebus.sh` + `P1-verify.md` (`az servicebus topic subscription show ...` outputs).

### Look-fors

- [ ] Three subscriptions with correct filters.
- [ ] Duplicate detection enabled.
- [ ] Role assignment in place.

---

## P2 — Producer + PeekLock Consumer + DLQ  *(Medium)*

**Tags:** `peek-lock` `dlq` `idempotency`

### Requirements

In `TaskFlow.ServiceBus.Console`:
- `publish <type> <priority> <payload>` — sends a message to the topic with `Type`, `Priority`, `Source=api` user properties and a unique `MessageId` (idempotency).
- `consume <subscription>` — opens a `ServiceBusProcessor`, peek-lock, complete on success, dead-letter on `payload contains 'fail'` exception.

Demonstrate end-to-end: publish 3 task.assigned, 1 task.done, 1 with payload `fail`. Consume `email-notify` (gets only assigneds), `audit-log` (all 5 — minus the failed one which goes to DLQ).

### Deliverable

`Commands/Publish.cs`, `Commands/Consume.cs`. `P2-runlog.md`.

### Look-fors

- [ ] Filter routing visible: `email-notify` only sees `task.assigned`.
- [ ] Failed message ends up in `email-notify/$DeadLetterQueue`.
- [ ] Re-running consumer doesn't duplicate work.

---

## P3 — DLQ Inspector + Replay  *(Medium)*

**Tags:** `dlq` `replay`

### Requirements

Add commands:
- `dlq-peek <subscription> [n]` — show the next n DLQ messages with reason.
- `dlq-replay <subscription> <messageId>` — re-publish to the original topic, complete the DLQ message.
- `dlq-purge <subscription>` — drain & complete all DLQ messages (with a `--yes` confirmation).

### Deliverable

`Commands/Dlq.cs` + `P3-dlq.md`.

### Look-fors

- [ ] Replay preserves user properties, not just body.
- [ ] Purge requires explicit confirmation flag.
- [ ] DLQ peek shows the original DeadLetterReason / DeadLetterErrorDescription.

---

## P4 — Sessions for Per-User Ordering  *(Hard)*

**Tags:** `sessions` `fifo`

### Requirements

1. Add a **session-enabled queue** `user-actions-queue` to the namespace (`enable-session true`).
2. `publish-user <userId> <action>` — sends with `SessionId=userId`.
3. `consume-sessions` — uses `ServiceBusSessionProcessor` with `MaxConcurrentSessions=4`.
4. Demonstrate: publish 100 messages for 5 users in random order; consumer logs interleaved across users but **strictly ordered per user**.

### Deliverable

`Commands/Sessions.cs` + `P4-sessions.md` showing run output.

### Look-fors

- [ ] Output proves per-user FIFO.
- [ ] Multiple sessions process in parallel.
- [ ] Lost-lock scenario discussed (long handler, session lock duration).

---

## P5 — Logic App Consumer for Email Notifications  *(Medium)*

**Tags:** `logic-apps` `connectors`

### Requirements

Create a **Logic App (Consumption)** triggered by the `email-notify` subscription that:
- Parses the message JSON.
- Sends an email via the Outlook 365 connector (or, if you don't have one, the Office 365 *Outlook* connector with a personal account, or fallback to logging via HTTP request to webhook.site).
- Posts to a Teams/Slack webhook (optional).

Capture the workflow JSON in `P5-logic-app.json`.

### Deliverable

`P5-logic-app.json` (exportable from Portal) + `P5-walkthrough.md` with screenshots.

### Look-fors

- [ ] Trigger uses **Azure-hosted connection** authenticated by Entra (managed identity preferred).
- [ ] Workflow handles bad input gracefully (Condition + Terminate with error).
- [ ] You documented at least one **failed run** and how Logic Apps shows the diagnostics.

---

## Submission Checklist

- [ ] All scripts and code committed.
- [ ] No connection strings or secrets in commits.
- [ ] `README.md` lists every CLI verb and Logic App import steps.

---

## Stretch Goals

- Replace Storage Queue in Topic 4 with a Service Bus queue and re-test the queue exercises.
- Add **Premium** namespace setup steps (private endpoint, geo-DR) in a separate notes file.
- Implement an **outbox pattern** in your API: write the row + an outbox event in one DB transaction; a tiny worker drains the outbox to Service Bus.
