# Topic 5 — Practice Solutions

| File | Problem |
|---|---|
| `P1-servicebus.sh` | SB namespace + topic + subscriptions |
| `P1-verify.md` | Verification |
| `TaskFlow.ServiceBus.Console/` | C# CLI for P2–P4 |
| `P2-runlog.md` | Pub/sub round-trip log |
| `P3-dlq.md` | DLQ inspector / replay log |
| `P4-sessions.md` | Sessions FIFO log |
| `P5-logic-app.json` | Exported Logic App workflow |
| `P5-walkthrough.md` | Logic App setup walkthrough |

## Run

```bash
cd TaskFlow.ServiceBus.Console
dotnet run -- publish task.assigned 5 '{"taskId":"t1","assignee":"u1"}'
dotnet run -- consume email-notify
dotnet run -- dlq-peek email-notify
```

## Cleanup

```bash
az servicebus namespace delete -g taskflow-dev-eus-rg -n sb-taskflow-dev-<suffix>
az logic workflow delete -g taskflow-dev-eus-rg -n logic-taskflow-email --yes
```
