#!/usr/bin/env bash
# P5-appservice.sh — Provision App Service plan + Web App + staging slot, deploy stub, swap.
set -euo pipefail

: "${AZ_REGION:=eastus}"
: "${AZ_REGION_SHORT:=eus}"
: "${RG:=taskflow-dev-${AZ_REGION_SHORT}-rg}"
PLAN="asp-taskflow-dev"
APP="taskflow-api-dev-$(echo $RANDOM | md5sum | cut -c1-4)"

echo "==> Plan ${PLAN} (S1)"
az appservice plan create -g "$RG" -n "$PLAN" --sku S1 --is-linux

echo "==> Web App ${APP}"
az webapp create -g "$RG" -p "$PLAN" -n "$APP" --runtime "DOTNETCORE:8.0"

echo "==> Staging slot"
az webapp deployment slot create -g "$RG" -n "$APP" --slot staging

echo "==> Build & deploy to staging"
pushd "$(dirname "$0")/TaskFlow.Api.Stub" >/dev/null
dotnet publish -c Release -o ./publish
pushd ./publish >/dev/null
zip -qr ../app.zip .
popd >/dev/null

az webapp deploy -g "$RG" -n "$APP" --slot staging \
    --src-path ./app.zip --type zip 1>/dev/null
popd >/dev/null

echo "==> Smoke test staging"
curl -fsS "https://${APP}-staging.azurewebsites.net/health" | tee /dev/stderr

echo "==> Swap to production"
az webapp deployment slot swap -g "$RG" -n "$APP" --slot staging --target-slot production

echo "==> Verify production"
curl -fsS "https://${APP}.azurewebsites.net/health"

echo "==> Done. Roll back drill: rerun the swap to undo."
