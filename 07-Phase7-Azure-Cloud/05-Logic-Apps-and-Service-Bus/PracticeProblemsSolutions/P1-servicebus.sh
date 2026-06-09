#!/usr/bin/env bash
# P1-servicebus.sh — SB namespace, topic, subscriptions with filters.
set -euo pipefail

: "${AZ_REGION:=eastus}"
: "${AZ_REGION_SHORT:=eus}"
: "${RG:=taskflow-dev-${AZ_REGION_SHORT}-rg}"
SUFFIX="${SUFFIX:-$(echo $RANDOM | md5sum | cut -c1-4)}"
NS="sb-taskflow-dev-${SUFFIX}"
TOPIC="tasks-events"
QUEUE_SESSION="user-actions-queue"

echo "==> Namespace ${NS} (Standard)"
az servicebus namespace create -g "$RG" -n "$NS" -l "$AZ_REGION" --sku Standard 1>/dev/null

echo "==> Topic ${TOPIC} with duplicate detection"
az servicebus topic create -g "$RG" --namespace-name "$NS" -n "$TOPIC" \
    --enable-duplicate-detection true \
    --duplicate-detection-history-time-window PT10M 1>/dev/null

echo "==> Session-enabled queue ${QUEUE_SESSION}"
az servicebus queue create -g "$RG" --namespace-name "$NS" -n "$QUEUE_SESSION" \
    --enable-session true --max-delivery-count 5 1>/dev/null

echo "==> Subscriptions"
for SUB in audit-log email-notify metrics; do
  az servicebus topic subscription create -g "$RG" --namespace-name "$NS" \
    --topic-name "$TOPIC" -n "$SUB" --max-delivery-count 5 1>/dev/null
done

echo "==> Filters"
# Default rule: gets everything. Replace for filtered subs.
az servicebus topic subscription rule delete -g "$RG" --namespace-name "$NS" \
  --topic-name "$TOPIC" --subscription-name email-notify --name "\$Default" 2>/dev/null || true
az servicebus topic subscription rule create -g "$RG" --namespace-name "$NS" \
  --topic-name "$TOPIC" --subscription-name email-notify --name "OnlyAssigned" \
  --filter-type CorrelationFilter --correlation-filter properties.type=task.assigned 1>/dev/null

az servicebus topic subscription rule delete -g "$RG" --namespace-name "$NS" \
  --topic-name "$TOPIC" --subscription-name metrics --name "\$Default" 2>/dev/null || true
az servicebus topic subscription rule create -g "$RG" --namespace-name "$NS" \
  --topic-name "$TOPIC" --subscription-name metrics --name "ApiHigh" \
  --filter-type SqlFilter --filter-sql-expression "source='api' AND priority > 0" 1>/dev/null

echo "==> Granting Data Owner on namespace"
NS_ID=$(az servicebus namespace show -g "$RG" -n "$NS" --query id -o tsv)
ME=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --assignee "$ME" \
  --role "Azure Service Bus Data Owner" --scope "$NS_ID" 2>/dev/null || true

echo "==> Done. Namespace: ${NS}.servicebus.windows.net"
