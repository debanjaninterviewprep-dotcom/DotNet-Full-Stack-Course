# Topic 4 — Practice Solutions

The C# project `TaskFlow.Storage.Console` is a small CLI exercising Blob, Table, and Queue with **Managed Identity**.

| File | Problem |
|---|---|
| `P1-storage.sh` | Provisioning |
| `P1-verify.md` | Verification |
| `TaskFlow.Storage.Console/` | C# CLI for P2 – P4 |
| `P3-notes.md` | Table design discussion |
| `P4-runlog.md` | Queue/poison drill log |
| `P5-lifecycle.json` | Lifecycle policy |
| `P5-drill.md` | Recovery drill |

## Build & run

```bash
cd TaskFlow.Storage.Console
dotnet build
dotnet run -- upload ./README.md task-001
dotnet run -- download-link attachments/task-001/<guid>-README.md
dotnet run -- log-activity user-1 task.created task-001 '{"foo":1}'
dotnet run -- list-activity user-1 10
dotnet run -- enqueue work '{"foo":"bar"}'
dotnet run -- consume
```

`appsettings.json` holds the storage account name only; all auth is via `DefaultAzureCredential` (which picks up `az login` locally and Managed Identity in Azure).

## Cleanup

```bash
az storage account delete -g taskflow-dev-eus-rg -n sttaskflowdev<suffix> --yes
```
