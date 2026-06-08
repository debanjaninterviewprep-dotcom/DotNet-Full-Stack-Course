# Topic 5: Logic Apps & Service Bus

> The previous topic introduced **Storage Queues** — simple FIFO with one feature each. This topic levels up to two enterprise integration tools: **Azure Service Bus** (the industry-strength messaging broker) and **Azure Logic Apps** (low-code orchestration). They overlap but solve different problems: Service Bus is *plumbing*, Logic Apps is *workflow*.

---

## 1. When You Outgrow Storage Queues

You're ready for Service Bus when any of these hits:

| Symptom | Service Bus feature |
|---|---|
| "Multiple subscribers need the same message" | **Topics & Subscriptions** (pub/sub) |
| "I need ≥ 256 KB messages" | Up to **100 MB** (Premium) |
| "Duplicate messages are causing double-charging" | **Duplicate detection** window |
| "I need messages processed strictly in order across producers" | **Sessions** |
| "Failed messages must go to a hold-zone for inspection" | **Dead-Letter Queue** built-in |
| "I need transactions across multiple sends/receives" | **Transactions** |
| "Cross-region geo-DR for the broker itself" | **Geo-disaster recovery** |
| "Schedule a message for 3 hours later" | **Scheduled enqueue** |

---

## 2. Service Bus Building Blocks

```
Namespace ──► Queue (point-to-point)
          ──► Topic ──► Subscription (with filter)
                    ──► Subscription (with filter)
```

| Concept | What it is |
|---|---|
| **Namespace** | The Service Bus resource (one URL endpoint). Tier (Basic/Standard/Premium) is fixed here. |
| **Queue** | One sender, one logical receiver pool. |
| **Topic** | Publisher-side. Messages fan out via subscriptions. |
| **Subscription** | Receiver-side. Holds messages matching filter rules. |
| **Filter rule** | SQL or correlation filter on system + user properties. |
| **Dead-letter queue (DLQ)** | A built-in subqueue that holds undelivered messages. |
| **Session** | A logical group of related messages, processed FIFO by one receiver. |

### Tiers

| Tier | Topics? | Sessions? | DLQ? | Pricing | Use for |
|---|---|---|---|---|---|
| Basic | ❌ | ❌ | ❌ | Per-op (cheap) | Dev / queues only |
| Standard | ✅ | ✅ | ✅ | Per-op | Most prod |
| Premium | ✅ | ✅ | ✅ | Hourly + isolated | High throughput, VNet, geo-DR |

**TaskFlow** uses **Standard** in dev/prod.

---

## 3. The Receiver Patterns

### Peek-Lock (default, recommended)

1. Receiver gets the message + a **lock token**.
2. Receiver processes.
3. Receiver calls `CompleteAsync` to delete it.
4. If the receiver crashes, lock expires (default 30s) and the message is re-deliverable.

```csharp
var client = new ServiceBusClient(
    "<namespace>.servicebus.windows.net",
    new DefaultAzureCredential());

var processor = client.CreateProcessor("tasks-queue", new ServiceBusProcessorOptions
{
    AutoCompleteMessages = false,
    MaxConcurrentCalls = 8,
    PrefetchCount = 16,
});

processor.ProcessMessageAsync += async args =>
{
    var body = args.Message.Body.ToString();
    try
    {
        await DoWork(body);
        await args.CompleteMessageAsync(args.Message);
    }
    catch (Exception ex) when (IsPoisonable(ex))
    {
        await args.DeadLetterMessageAsync(args.Message,
            "InvalidPayload", ex.Message);
    }
    // any other exception: lock expires, message redelivered up to MaxDeliveryCount
};

processor.ProcessErrorAsync += args => { /* log */ return Task.CompletedTask; };
await processor.StartProcessingAsync();
```

### Receive-and-Delete

Faster, at-most-once. The broker deletes on read. Lose the message if your receiver crashes. Use only for telemetry where loss is acceptable.

---

## 4. Idempotency, Duplicates & DLQ

Service Bus guarantees *at-least-once* delivery. Code defensively:

- Use a **business idempotency key** (e.g. `OrderId`) and a small DB/Redis check on the receiver.
- Enable **duplicate detection** at the queue level (10-minute default window) for short-window dedup.
- Configure **MaxDeliveryCount** (default 10): after N failures the message goes to the DLQ.
- Build a **DLQ inspector** — a small CLI/UI to peek and replay or purge.

### Replay from DLQ

```csharp
var deadLetter = client.CreateReceiver("tasks-queue", new ServiceBusReceiverOptions
{
    SubReceiver = ServiceBusSubReceiver.DeadLetter
});

await foreach (var msg in deadLetter.ReceiveMessagesAsync().ConfigureAwait(false))
{
    // Inspect, fix, then resend or complete
    await sender.SendMessageAsync(new ServiceBusMessage(msg.Body));
    await deadLetter.CompleteMessageAsync(msg);
}
```

---

## 5. Topics & Subscriptions (Pub/Sub)

```
Producer ──► Topic "tasks-events"
                ├─► Subscription "audit-log"     (no filter — gets everything)
                ├─► Subscription "email-notify"  (filter: type='task.assigned')
                └─► Subscription "metrics"       (filter: source='api')
```

Filters:

- **Correlation filter** — match exact system/user properties (cheap, fast).
- **SQL filter** — `type LIKE 'task.%' AND priority > 3` (expressive, slightly slower).

### Why pub/sub matters

Adding a new consumer (e.g., a new "send-to-Slack" function) becomes:

1. Create a new subscription with a filter.
2. Wire a Function App / Logic App to it.
3. Done — no producer changes.

This is the loose-coupling promise.

---

## 6. Sessions (FIFO per Group)

Without sessions, Service Bus ordering is best-effort across consumers. With sessions:

- Producer sets `SessionId` (e.g., `userId`, `orderId`).
- Each session is processed by **one receiver at a time**, in order.
- Gives you per-key ordering with parallel scaling across keys.

Use case: process events for a single TaskFlow user strictly in order while still scaling horizontally across thousands of users.

---

## 7. Logic Apps: Low-Code Workflow

A **Logic App** is a JSON workflow with triggers and actions. Drag-and-drop in the portal, generate code via Bicep/ARM, version in Git.

| When trigger fires | Logic App responds |
|---|---|
| HTTP POST / webhook | Run flow |
| Service Bus message | Run flow per message |
| Recurrence (CRON) | Periodic |
| Blob created | React to upload |
| Azure Event Grid event | Resource lifecycle reaction |

Built-in **connectors** (400+): SendGrid, Outlook, Teams, Slack, SharePoint, Salesforce, SAP, ServiceNow, GitHub, …

### Logic App Standard vs Consumption

| | Consumption (Multi-tenant) | Standard (Single-tenant) |
|---|---|---|
| Pricing | Per-action | Hourly (App Service plan) |
| VNet | No | Yes |
| Stateful + Stateless | Stateful only | Both |
| Dev experience | Portal-only | Local VS Code dev, Bicep |
| Performance | Variable | Predictable |
| TaskFlow choice | Consumption (cheap) | Standard (when you need VNet) |

### When Logic App over a Function App

- **Logic App**: a sequence of integrations with little code (read SB → call API → email a user). Visual is faster.
- **Function App**: real logic, transformations, custom code, performance-critical paths.

A common pattern: Logic App orchestrates → calls a Function for the messy 5% of code.

---

## 8. Putting It Together: TaskFlow Event Flow

```
[ TaskFlow API ]
       │
       │  enqueue task.assigned
       ▼
[ SB Topic: tasks-events ]
       ├─► Sub "email-notify"  ── filter type='task.assigned' ─► Logic App: send email
       ├─► Sub "audit-log"     ── no filter ─► Function App: write Table audit row
       └─► Sub "metrics"       ── filter source='api' ─► Function App: bump counter
```

When something fails in any subscription, that subscription's **DLQ** holds it for a human (or replay job). Other subscribers continue processing.

---

## 9. Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Use Standard tier when Premium throughput is needed | Bench, then size |
| Process Service Bus messages in `ReceiveAndDelete` mode for important work | PeekLock + Complete |
| Forget MaxDeliveryCount | Set it explicitly; configure DLQ alerts |
| Encode huge blobs in messages | Pass a **Blob URL**; broker shouldn't hold MBs |
| Implement complex business logic in Logic Apps | Use Functions for logic, Logic Apps for glue |
| Trust message ordering without sessions | Use sessions or write order-tolerant handlers |
| Use connection strings in Logic App actions | Use **Managed Connections** + Managed Identity where supported |

---

## 10. Cost Control

- Standard SB: ~$10/mo flat + per-million ops; cheap.
- Logic Apps Consumption: free for first 4000 actions; pennies per 1000 after.
- DLQ messages **count against quota**; clean them up after triage.

---

## Further Reading

- [Service Bus messaging overview](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-messaging-overview)
- [Service Bus dead-letter queues](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-dead-letter-queues)
- [Choose between messaging services](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services)
- [Logic Apps Standard vs Consumption](https://learn.microsoft.com/azure/logic-apps/logic-apps-overview)
- [SQL filters in subscriptions](https://learn.microsoft.com/azure/service-bus-messaging/topic-filters)
