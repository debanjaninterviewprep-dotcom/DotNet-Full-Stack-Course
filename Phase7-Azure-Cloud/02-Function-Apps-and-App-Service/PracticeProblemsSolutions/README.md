# Topic 2 — Practice Solutions

This folder contains two .NET projects:

| Project | Purpose | Problem |
|---|---|---|
| `TaskFlow.Functions/` | Isolated-worker Azure Functions app | P1 – P4 |
| `TaskFlow.Api.Stub/` | Minimal ASP.NET Core API for App Service | P5 |

Plus deployment scripts:

| File | Problem |
|---|---|
| `P4-deploy.sh` | Provisions & deploys the Function App |
| `P4-deploy.md` | Write-up |
| `P5-appservice.sh` | Provisions App Service + slot |
| `P5-deploy.md` | Write-up + swap drill notes |

## Local development

```bash
# Functions
cd TaskFlow.Functions
dotnet build
func start

# Web API
cd ../TaskFlow.Api.Stub
dotnet run
```

## Cleanup

```bash
az functionapp delete -g taskflow-dev-eus-rg -n func-taskflow-dev
az webapp delete -g taskflow-dev-eus-rg -n taskflow-api-dev
az appservice plan delete -g taskflow-dev-eus-rg -n asp-taskflow-dev --yes
```
