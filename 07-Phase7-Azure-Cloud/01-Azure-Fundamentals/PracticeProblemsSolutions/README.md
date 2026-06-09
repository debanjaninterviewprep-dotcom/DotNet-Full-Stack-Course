# Topic 1 — Practice Solutions

This folder is your scratchpad for the six exercises in [Practice-Problems.md](../Practice-Problems.md).

| File | Problem | Type |
|---|---|---|
| `P1-subscription-overview.md` | P1 — Subscription Tour & Budget | Markdown report |
| `P2-naming-and-tags.md` | P2 — Naming + Tagging spec | Markdown spec |
| `P2-create-rgs.sh` / `.ps1` | P2 — RG creation script | Shell script |
| `P3-rbac.md` | P3 — RBAC strategy & rationale | Markdown |
| `P3-assign-rbac.sh` | P3 — RBAC assignment script | Shell script |
| `P4-managed-identity.md` | P4 — Managed Identity write-up | Markdown |
| `P4-create-mi.sh` | P4 — MI provisioning script | Shell script |
| `P5-bootstrap.sh` / `.ps1` | P5 — Combined idempotent bootstrap | Shell script |
| `P5-runlog.md` | P5 — Two-run idempotency log | Markdown |
| `P6-policy.md` | P6 — Policy strategy & violation log | Markdown |
| `P6-assign-policies.sh` | P6 — Policy assignment script | Shell script |

## Conventions

- All scripts are **idempotent**: safe to re-run.
- Region: pick once, use everywhere. (Suggestion: `eastus` or `westeurope`.)
- Subscription ID, tenant ID, and emails: **placeholders** in committed files.
- Real values go in a local `.env` file that is `.gitignore`d.

## Cleanup

```bash
# Removes everything you created in this topic.
az group delete -n taskflow-dev-eus-rg --yes --no-wait
az group delete -n taskflow-shared-eus-rg --yes --no-wait
```
