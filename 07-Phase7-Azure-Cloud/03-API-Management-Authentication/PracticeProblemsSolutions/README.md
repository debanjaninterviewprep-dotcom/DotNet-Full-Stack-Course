# Topic 3 — Practice Solutions

| File | Problem |
|---|---|
| `P1-apim-bootstrap.sh` | Provision APIM Consumption + import Function App |
| `P1-import.md` | Steps & verification |
| `P2-policies/product-taskflow-free.xml` | Subscription key + rate limit |
| `P2-test.md` | 401/429 test commands |
| `P3-policies/jwt-validation.xml` | Entra JWT validation policy |
| `P3-entra-setup.md` | App Registration walkthrough |
| `P4-policies/api-policies.xml` | CORS, headers, MI backend auth |
| `P4-mi-backend.md` | MI integration write-up |
| `P5-lockdown.sh` | Function App access restrictions |
| `P5-network-and-portal.md` | Developer portal + versioning notes |

## Conventions

- Replace `{{tenantId}}`, `{{apiAudience}}`, `{{spaOrigin}}` with **Named Values** in APIM, not literals.
- All XML policies include `<base />` at every section to chain inherited rules.
- IDs and emails in committed `.md` are placeholders.

## Verification quick-reference

```bash
# Subscription key required:
curl -i https://apim-taskflow-dev-xxx.azure-api.net/taskflow/ping
# expect 401

# With key (no JWT — depends on policy scope):
curl -i -H "Ocp-Apim-Subscription-Key: <key>" \
  https://apim-taskflow-dev-xxx.azure-api.net/taskflow/ping
# expect 401 from JWT policy

# With key + JWT:
curl -i \
  -H "Ocp-Apim-Subscription-Key: <key>" \
  -H "Authorization: Bearer <jwt>" \
  https://apim-taskflow-dev-xxx.azure-api.net/taskflow/ping
# expect 200
```

## Cleanup

```bash
az apim delete -g taskflow-dev-eus-rg -n apim-taskflow-dev-xxx --yes --no-wait
```
