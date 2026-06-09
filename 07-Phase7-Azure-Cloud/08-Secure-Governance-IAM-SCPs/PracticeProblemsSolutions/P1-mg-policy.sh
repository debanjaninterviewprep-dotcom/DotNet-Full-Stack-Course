#!/usr/bin/env bash
# P1-mg-policy.sh — Build a small MG hierarchy and assign a naming/tagging initiative.
set -euo pipefail

: "${TENANT_ROOT_MG:?Set TENANT_ROOT_MG to your tenant root MG id}"
: "${SUB_ID:?Set SUB_ID=<subscription-id-to-place-under-workloads>}"

echo "==> MGs"
for MG in taskflow-root taskflow-platform taskflow-workloads taskflow-sandbox; do
  az account management-group create \
      --name "$MG" --display-name "$MG" \
      --parent "$TENANT_ROOT_MG" 1>/dev/null || true
done

# Re-parent platform/workloads/sandbox under taskflow-root
for MG in taskflow-platform taskflow-workloads taskflow-sandbox; do
  az account management-group update --name "$MG" --parent-id "/providers/Microsoft.Management/managementGroups/taskflow-root" 1>/dev/null || true
done

echo "==> Move subscription under taskflow-workloads"
az account management-group subscription add \
    --name taskflow-workloads --subscription "$SUB_ID" 1>/dev/null || true

echo "==> Define & assign initiative — use Portal for the friendliest UX, or CLI:"
cat <<'EOF'
# 1) Author initiative JSON locally (definition + parameters), or use built-in policies referenced in the topic notes.
# 2) Create at MG scope:
az policy set-definition create \
    --management-group taskflow-root \
    --name "taskflow-naming-tagging" \
    --display-name "TaskFlow Naming & Tagging" \
    --definitions @initiative-definitions.json \
    --params @initiative-parameters.json
# 3) Assign:
az policy assignment create \
    --name "taskflow-naming-tagging-assign" \
    --policy-set-definition "/providers/Microsoft.Management/managementGroups/taskflow-root/providers/Microsoft.Authorization/policySetDefinitions/taskflow-naming-tagging" \
    --scope "/providers/Microsoft.Management/managementGroups/taskflow-workloads"
EOF

echo "==> Done"
