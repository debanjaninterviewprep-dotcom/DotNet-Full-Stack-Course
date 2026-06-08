#!/usr/bin/env bash
# P1-storage.sh — Provision a locked-down storage account for TaskFlow.
set -euo pipefail

: "${AZ_REGION:=eastus}"
: "${AZ_REGION_SHORT:=eus}"
: "${RG:=taskflow-dev-${AZ_REGION_SHORT}-rg}"
SUFFIX="${SUFFIX:-$(echo $RANDOM | md5sum | cut -c1-4)}"
ACCT="sttaskflowdev${SUFFIX}"

echo "==> Storage account ${ACCT}"
az storage account create \
    -g "$RG" -n "$ACCT" -l "$AZ_REGION" \
    --sku Standard_LRS --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --default-action Allow 1>/dev/null

ACCT_ID=$(az storage account show -g "$RG" -n "$ACCT" --query id -o tsv)

echo "==> Soft delete (blob + container, 7 days)"
az storage account blob-service-properties update \
    --account-name "$ACCT" -g "$RG" \
    --enable-delete-retention true --delete-retention-days 7 \
    --enable-container-delete-retention true --container-delete-retention-days 7 \
    --enable-versioning true 1>/dev/null

ME=$(az ad signed-in-user show --query id -o tsv)
for ROLE in "Storage Blob Data Contributor" "Storage Table Data Contributor" "Storage Queue Data Contributor"; do
  echo "==> Assigning '${ROLE}' to me on ${ACCT}"
  az role assignment create --assignee "$ME" --role "$ROLE" --scope "$ACCT_ID" 2>/dev/null || true
done

echo "==> Creating containers"
for C in attachments avatars reports; do
  az storage container create --name "$C" \
    --account-name "$ACCT" --auth-mode login 1>/dev/null
done

echo "==> Done. Storage: ${ACCT}"
