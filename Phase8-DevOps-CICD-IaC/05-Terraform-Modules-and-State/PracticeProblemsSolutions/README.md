# Topic 5 — Solutions Workspace

```
PracticeProblemsSolutions/
├── README.md
├── P1-modules/storage-account/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── README.md
├── P1-plan.txt
├── P2-modules/
│   ├── network/
│   ├── web-app/
│   └── key-vault/
├── P2-graph.png
├── P3-bootstrap.sh
├── backend-dev.hcl
├── backend-staging.hcl
├── backend-prod.hcl
├── P3-recovery.md
├── P4-state-ops.md
├── envs/{dev,staging,prod}/
├── tasks.ps1
├── P5-migration.md
├── P6-modules-ci.yml
├── P6-release-please-config.json
└── tests/storage_account.tftest.hcl
```

---

## Starter: `P3-bootstrap.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

LOC="${LOC:-eastus}"
RG="${RG:-rg-tfstate}"
SA_SUFFIX="${SA_SUFFIX:-$RANDOM$RANDOM}"
SA="${SA:-sttfstate${SA_SUFFIX}}"
CONTAINER="${CONTAINER:-tfstate}"

az group create -n "$RG" -l "$LOC" >/dev/null

az storage account create \
  -g "$RG" -n "$SA" -l "$LOC" \
  --sku Standard_GRS --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --enable-versioning >/dev/null

az storage account blob-service-properties update \
  --account-name "$SA" \
  --enable-delete-retention true --delete-retention-days 30 \
  --enable-container-delete-retention true --container-delete-retention-days 30 \
  --enable-versioning true >/dev/null

USER_OID=$(az ad signed-in-user show --query id -o tsv)
SA_ID=$(az storage account show -g "$RG" -n "$SA" --query id -o tsv)
az role assignment create \
  --assignee-object-id "$USER_OID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID" >/dev/null

# Container creation needs the RBAC above + a moment for propagation
sleep 30
az storage container create \
  --account-name "$SA" --name "$CONTAINER" --auth-mode login >/dev/null

cat <<EOF
Bootstrap complete.

Use this for terraform init:

  resource_group_name  = "$RG"
  storage_account_name = "$SA"
  container_name       = "$CONTAINER"
  key                  = "<project>/<env>.tfstate"
EOF
```

## Starter: `backend-dev.hcl`

```hcl
resource_group_name  = "rg-tfstate"
storage_account_name = "sttfstate12345"
container_name       = "tfstate"
key                  = "taskflow/dev.tfstate"
use_oidc             = true
use_azuread_auth     = true
```

## Starter: `tests/storage_account.tftest.hcl`

```hcl
run "minimal_apply" {
  command = apply
  module { source = "./examples/minimal" }

  assert {
    condition     = output.id != ""
    error_message = "storage account id should be set"
  }
}

run "invalid_name_rejected" {
  command = plan
  variables { name = "BAD_NAME!" }
  expect_failures = [var.name]
}
```

## Starter: `tasks.ps1`

```powershell
param(
  [Parameter(Mandatory)][ValidateSet('init','plan','apply','destroy','test','fmt')] [string]$Action,
  [Parameter(Mandatory)][ValidateSet('dev','staging','prod')] [string]$Env
)

$envDir = "envs/$Env"
$backend = "../../backend-$Env.hcl"
$tfvars  = "terraform.tfvars"

Push-Location $envDir
try {
  switch ($Action) {
    'init'    { terraform init -reconfigure -backend-config="$backend" }
    'fmt'     { terraform fmt -recursive }
    'plan'    { terraform plan -var-file=$tfvars -out tfplan }
    'apply'   { terraform apply tfplan }
    'destroy' { terraform destroy -var-file=$tfvars -auto-approve:$false }
    'test'    { terraform test }
  }
} finally { Pop-Location }
```

---

## Submission

Tell me **"check P3"** (or a range) for graded review.
