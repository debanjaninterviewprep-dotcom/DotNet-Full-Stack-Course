#!/usr/bin/env bash
# P1-redis.sh — Provision Azure Cache for Redis Standard C0 with Entra auth.
set -euo pipefail

: "${AZ_REGION:=eastus}"
: "${AZ_REGION_SHORT:=eus}"
: "${RG:=taskflow-dev-${AZ_REGION_SHORT}-rg}"
SUFFIX="${SUFFIX:-$(echo $RANDOM | md5sum | cut -c1-4)}"
NAME="redis-taskflow-dev-${SUFFIX}"

echo "==> Redis ${NAME} (Standard C0) — takes ~15-20 min"
az redis create -g "$RG" -n "$NAME" -l "$AZ_REGION" \
    --sku Standard --vm-size c0 \
    --enable-non-ssl-port false \
    --minimum-tls-version 1.2 1>/dev/null

echo "==> Enabling Entra auth"
az redis update -g "$RG" -n "$NAME" \
    --set "redisConfiguration.aad-enabled=true" 1>/dev/null

ME=$(az ad signed-in-user show --query id -o tsv)
echo "==> Granting Data Contributor to ${ME}"
az redis access-policy-assignment create \
    -g "$RG" -n "$NAME" \
    --object-id "$ME" --object-id-alias "$ME" \
    --policy-name "Data Contributor" 2>/dev/null \
    || echo "  (Entra access policy CLI may need preview extension; alternatively use Portal -> Authentication.)"

echo "==> Done. Endpoint: ${NAME}.redis.cache.windows.net:6380"
