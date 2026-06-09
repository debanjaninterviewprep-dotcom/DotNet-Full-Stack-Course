#!/usr/bin/env bash
# P4-deploy.sh — Provision a Consumption Function App and deploy TaskFlow.Functions.
# Idempotent: safe to re-run.
set -euo pipefail

: "${AZ_REGION:=eastus}"
: "${AZ_REGION_SHORT:=eus}"
: "${RG:=taskflow-dev-${AZ_REGION_SHORT}-rg}"
: "${SHARED_RG:=taskflow-shared-${AZ_REGION_SHORT}-rg}"
: "${KV_NAME:?Set KV_NAME=<your-key-vault-name>}"
: "${MI_NAME:=mi-taskflow-app-dev}"

SUFFIX="${SUFFIX:-$(echo $RANDOM | md5sum | cut -c1-6)}"
STORAGE="sttaskflowfundev${SUFFIX}"
FUNCAPP="func-taskflow-dev-${SUFFIX}"
APPINSIGHTS="appi-taskflow-dev"

echo "==> Storage account ${STORAGE}"
az storage account create \
    -g "$RG" -n "$STORAGE" -l "$AZ_REGION" \
    --sku Standard_LRS --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false

echo "==> Application Insights ${APPINSIGHTS}"
az monitor app-insights component create \
    --app "$APPINSIGHTS" -g "$RG" -l "$AZ_REGION" \
    --kind web --application-type web 1>/dev/null

AI_KEY=$(az monitor app-insights component show \
    --app "$APPINSIGHTS" -g "$RG" --query instrumentationKey -o tsv)

echo "==> Function App ${FUNCAPP}"
az functionapp create \
    -g "$RG" -n "$FUNCAPP" \
    --storage-account "$STORAGE" \
    --consumption-plan-location "$AZ_REGION" \
    --runtime dotnet-isolated --runtime-version 8 \
    --functions-version 4 \
    --os-type Linux \
    --app-insights "$APPINSIGHTS" \
    --app-insights-key "$AI_KEY"

echo "==> Attach User-Assigned MI"
MI_ID=$(az identity show -g "$SHARED_RG" -n "$MI_NAME" --query id -o tsv)
MI_CLIENT_ID=$(az identity show -g "$SHARED_RG" -n "$MI_NAME" --query clientId -o tsv)

az functionapp identity assign \
    -g "$RG" -n "$FUNCAPP" \
    --identities "$MI_ID" 1>/dev/null

echo "==> Key Vault reference + identity hint"
KV_URI="https://${KV_NAME}.vault.azure.net/secrets/Sample--ConnectionString"
az functionapp config appsettings set \
    -g "$RG" -n "$FUNCAPP" \
    --settings \
        "Sample__ConnectionString=@Microsoft.KeyVault(SecretUri=${KV_URI})" \
        "AzureWebJobsStorage__credential=managedidentity" \
        "AzureWebJobsStorage__clientId=${MI_CLIENT_ID}" \
    1>/dev/null

echo "==> Publish"
pushd "$(dirname "$0")/TaskFlow.Functions" >/dev/null
dotnet publish -c Release -o ./publish
pushd ./publish >/dev/null
zip -qr ../app.zip .
popd >/dev/null

az functionapp deployment source config-zip \
    -g "$RG" -n "$FUNCAPP" --src ./app.zip 1>/dev/null
popd >/dev/null

echo "==> Done. Function App: https://${FUNCAPP}.azurewebsites.net"
