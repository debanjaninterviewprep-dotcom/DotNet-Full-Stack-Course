# Topic 8 — Practice Solutions

| File | Problem |
|---|---|
| `P1-mg-policy.sh` | MG hierarchy + naming/tagging initiative |
| `P1-results.md` | Compliance snapshot |
| `P2-storage-initiative.sh` | Storage hardening initiative |
| `P2-violation.md` | Captured deny message |
| `P3-dine.sh` | DINE auto-enable diagnostics |
| `P3-remediation.md` | Remediation run log |
| `P4-scps/deny-region.json` | AWS SCP — region restriction |
| `P4-scps/require-tags.json` | AWS SCP — tag enforcement |
| `P4-scps/deny-public-s3.json` | AWS SCP — block public S3 |
| `P4-scps/commentary.md` | Azure vs AWS notes |
| `P5-ca-pim.md` | Conditional Access + PIM design |

## Conventions

- Sub IDs / tenant IDs are placeholders.
- All policies assigned at MG, never per-resource.
- Test in a **non-production** tenant first; deny policies bite immediately.
