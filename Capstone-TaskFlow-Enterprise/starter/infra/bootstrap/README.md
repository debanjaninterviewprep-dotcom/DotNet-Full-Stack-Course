# infra/bootstrap/

One-time setup that creates the **Terraform remote state** backend itself (chicken-and-egg).

## What goes here

- A small Terraform / Bicep / PowerShell script that creates:
  - Resource group `rg-tfstate`
  - Storage account `sttfstate<unique>` (private endpoint optional)
  - Blob container `tfstate`
  - State container blob lease handling (Azure Storage handles locking via lease blobs natively)
  - Optional: Azure Key Vault for state encryption keys (CMK)

## How to run

Run once, by a human, with a privileged identity (`Owner` at sub scope). After this:

1. Note the storage account name.
2. Update `infra/envs/<env>/backend.tf` to point here.
3. From now on, all Terraform runs go through CI with OIDC.

## Why a separate folder

This state container itself is **not** managed by Terraform after creation — it's the root of trust. Deleting it would orphan all your state.

## Suggested CLI (one-off)

```pwsh
$rg = "rg-tfstate"
$sa = "sttfstate$([guid]::NewGuid().ToString('N').Substring(0,8))"
$loc = "northeurope"
az group create -n $rg -l $loc --tags purpose=tfstate owner=platform
az storage account create -n $sa -g $rg -l $loc --sku Standard_GRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --account-name $sa -n tfstate --auth-mode login
Write-Host "Backend storage account: $sa"
```
