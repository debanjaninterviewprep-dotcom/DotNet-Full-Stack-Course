#!/usr/bin/env bash
# P5-lockdown.sh — Restrict Function App so only APIM can reach it.
set -euo pipefail

: "${RG:=taskflow-dev-eus-rg}"
: "${FUNCAPP:?Set FUNCAPP=<your-function-app>}"
: "${APIM:?Set APIM=<your-apim-name>}"

APIM_IPS=$(az apim show -g "$RG" -n "$APIM" --query "publicIpAddresses" -o tsv | tr '\t' '\n')

echo "==> Whitelisting APIM IPs:"
PRIORITY=100
for ip in $APIM_IPS; do
  echo "    + ${ip}"
  az functionapp config access-restriction add \
      -g "$RG" -n "$FUNCAPP" \
      --rule-name "allow-apim-${PRIORITY}" \
      --priority "$PRIORITY" \
      --action Allow \
      --ip-address "${ip}/32" \
      1>/dev/null
  PRIORITY=$((PRIORITY+1))
done

echo "==> Adding deny-all (priority 999)"
az functionapp config access-restriction add \
    -g "$RG" -n "$FUNCAPP" \
    --rule-name "deny-all" \
    --priority 999 \
    --action Deny \
    --ip-address "0.0.0.0/0" 1>/dev/null || true

echo "==> Done. Verify by curl-ing the function URL directly: should be 403."
