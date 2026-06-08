#!/usr/bin/env bash
# P1-apim-bootstrap.sh — Provision APIM Consumption tier and import the Function App.
set -euo pipefail

: "${AZ_REGION:=eastus}"
: "${AZ_REGION_SHORT:=eus}"
: "${RG:=taskflow-dev-${AZ_REGION_SHORT}-rg}"
: "${PUBLISHER_EMAIL:?Set PUBLISHER_EMAIL=you@example.com}"
: "${PUBLISHER_NAME:?Set PUBLISHER_NAME='Your Name'}"
: "${FUNCAPP:?Set FUNCAPP=<your-function-app-name>}"

SUFFIX="${SUFFIX:-$(echo $RANDOM | md5sum | cut -c1-4)}"
APIM="apim-taskflow-dev-${SUFFIX}"

echo "==> Provisioning APIM ${APIM} (Consumption) — takes ~5 min"
az apim create \
    -g "$RG" -n "$APIM" -l "$AZ_REGION" \
    --sku-name Consumption \
    --publisher-email "$PUBLISHER_EMAIL" \
    --publisher-name "$PUBLISHER_NAME" \
    --enable-managed-identity true

FUNC_HOST=$(az functionapp show -g "$RG" -n "$FUNCAPP" --query defaultHostName -o tsv)
FUNC_KEY=$(az functionapp keys list -g "$RG" -n "$FUNCAPP" --query functionKeys.default -o tsv)

echo "==> Importing Function App as API 'taskflow'"
az apim api import \
    -g "$RG" --service-name "$APIM" \
    --api-id taskflow --path taskflow \
    --display-name "TaskFlow API" \
    --service-url "https://${FUNC_HOST}/api" \
    --specification-format OpenApi \
    --specification-url "https://${FUNC_HOST}/api/swagger.json?code=${FUNC_KEY}" || \
echo "  (If your Function App doesn't expose OpenAPI, import manually via Portal -> Function App import.)"

echo "==> APIM gateway: https://${APIM}.azure-api.net"
echo "==> Dev portal:   https://${APIM}.developer.azure-api.net"
