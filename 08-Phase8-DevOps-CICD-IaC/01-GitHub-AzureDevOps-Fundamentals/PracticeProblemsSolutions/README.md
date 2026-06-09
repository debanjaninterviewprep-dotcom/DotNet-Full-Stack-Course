# Topic 1 — Practice Problem Solutions Workspace

Drop your answers here matching the structure in [Practice-Problems.md](../Practice-Problems.md):

```
PracticeProblemsSolutions/
├── README.md                       <- this file
├── P1-repo-skeleton/
│   ├── README.md
│   ├── LICENSE
│   ├── SECURITY.md
│   ├── CONTRIBUTING.md
│   ├── CHANGELOG.md
│   ├── .editorconfig
│   ├── .gitattributes
│   ├── .gitignore
│   └── .github/
│       ├── CODEOWNERS
│       ├── pull_request_template.md
│       └── ISSUE_TEMPLATE/
│           ├── bug_report.md
│           └── feature_request.md
├── P2-branching-decision.md
├── P3-branch-protection.json
├── P3-apply.sh
├── P4-create-federation.sh
├── P4-deploy.yml
├── P5-pr-walkthrough.md
├── P6-mono-vs-poly.md
└── P7-runner-setup.sh   (stretch)
```

## Reference snippets

Sample skeletons for the most-asked files are included below as **starting points**, not finished answers — extend them as the problems require.

### `.editorconfig`
```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.{json,yml,yaml,md}]
indent_size = 2

[*.cs]
csharp_new_line_before_open_brace = all
dotnet_sort_system_directives_first = true
```

### `.gitattributes`
```
* text=auto eol=lf
*.sln text eol=crlf
*.cmd text eol=crlf
*.png binary
*.jpg binary
*.pdf binary
*.zip binary
```

### `CODEOWNERS`
```
# Default
*               @taskflow/platform

# Pipelines & infra
/.github/       @taskflow/devops
/infra/         @taskflow/devops

# Security-sensitive code
/src/Auth/      @taskflow/security @taskflow/platform
```

### Sample branch-protection JSON (`P3-branch-protection.json`)
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["build", "test", "lint", "security-scan"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_signatures": true,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
```

Apply:
```bash
gh api -X PUT \
  repos/<org>/<repo>/branches/main/protection \
  --input P3-branch-protection.json
```

### OIDC federation (`P4-create-federation.sh`)
```bash
#!/usr/bin/env bash
set -euo pipefail

LOCATION="eastus"
RG="rg-taskflow-dev"
MI_NAME="id-taskflow-cicd-dev"
GH_ORG="your-org"
GH_REPO="taskflow-api"
GH_ENV="production"
ROLE="Contributor"

az group create -n "$RG" -l "$LOCATION"

MI_ID=$(az identity create -g "$RG" -n "$MI_NAME" --query id -o tsv)
MI_CLIENT_ID=$(az identity show -g "$RG" -n "$MI_NAME" --query clientId -o tsv)
MI_OBJECT_ID=$(az identity show -g "$RG" -n "$MI_NAME" --query principalId -o tsv)

# Federated credential scoped to the production GitHub environment
az identity federated-credential create \
  --name "fc-github-prod" \
  --identity-name "$MI_NAME" \
  --resource-group "$RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${GH_ORG}/${GH_REPO}:environment:${GH_ENV}" \
  --audiences "api://AzureADTokenExchange"

# Least-privilege role on the RG only
SUB_ID=$(az account show --query id -o tsv)
az role assignment create \
  --assignee-object-id "$MI_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "$ROLE" \
  --scope "/subscriptions/${SUB_ID}/resourceGroups/${RG}"

echo
echo "Set these in GitHub repo variables:"
echo "  AZURE_CLIENT_ID=${MI_CLIENT_ID}"
echo "  AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)"
echo "  AZURE_SUBSCRIPTION_ID=${SUB_ID}"
```

### Sample workflow (`P4-deploy.yml`)
```yaml
name: deploy-dev

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  smoke:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://taskflow.example.com
    steps:
      - uses: actions/checkout@v4

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Prove the connection works
        run: |
          az group show -n rg-taskflow-dev
          az account show
```

---

## Submission

When you finish a problem, tell me e.g. **"check P3"** and I'll review.
