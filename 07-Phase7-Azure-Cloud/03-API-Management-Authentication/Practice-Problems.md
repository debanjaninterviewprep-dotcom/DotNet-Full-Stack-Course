# Topic 3: API Management — Practice Problems

> Five exercises that take your TaskFlow Function App from public to **gateway-protected**, with subscription keys, JWT validation, rate limits, and a developer portal.

**Concept tags:** `apim` `policies` `jwt` `entra-id` `rate-limit` `cors` `developer-portal` `openapi`

**Prereqs:**
- Topic 2 deployed Function App reachable at `https://func-taskflow-dev-*.azurewebsites.net`.
- Resource group `taskflow-dev-eus-rg` exists.
- An Entra App Registration for the API audience (you'll create one in P3).

---

## P1 — Provision APIM (Consumption) and Import the Function App  *(Easy)*

**Tags:** `apim` `consumption` `openapi-import`

### Requirements

1. Provision an APIM **Consumption** tier instance:
   - Name: `apim-taskflow-dev-<suffix>`
   - Region: same as your RG
   - Publisher email/name: yours
2. Import the Function App as an API:
   - Either via *Portal → Import → Function App* (use the existing keys),
   - Or via `az apim api import --specification-format OpenApi` if you have an OpenAPI doc.
3. Smoke test: call `/api/ping` through the APIM hostname (`https://apim-taskflow-dev-*.azure-api.net/taskflow/ping`).

### Deliverable

`P1-apim-bootstrap.sh` + `P1-import.md` (steps + screenshot of the API in APIM).

### Look-fors

- [ ] APIM Consumption SKU visible: `az apim show --query sku.name`.
- [ ] The Function App appears as a **Backend** in APIM.
- [ ] The original direct-to-Function URL still works (you'll lock it down in P5).

---

## P2 — Subscription Key + Rate Limit  *(Easy)*

**Tags:** `subscription-key` `rate-limit`

### Requirements

1. Create a new **Product** "TaskFlow Free" containing the imported API.
2. Require a **subscription key** for the Product.
3. Add an **inbound policy** at the Product scope:
   - `rate-limit-by-key` of 30 calls / minute, keyed by subscription ID.
   - `quota-by-key` of 1000 calls / day.
4. Subscribe yourself, then verify:
   - Calls without `Ocp-Apim-Subscription-Key` → 401.
   - 31st call within a minute → 429.

### Deliverable

`P2-policies/product-taskflow-free.xml` + `P2-test.md` with the curl commands proving 401 and 429.

### Look-fors

- [ ] Policy includes `<base />` at every section.
- [ ] You document **how to reset the counter** (delete subscription / wait).
- [ ] 401 message is friendly (custom `<return-response>` in `on-error`).

---

## P3 — Validate Microsoft Entra JWT  *(Medium)*

**Tags:** `jwt` `entra-id` `app-registration`

### Requirements

1. Create two **App Registrations** in your Entra tenant:
   - `taskflow-api` (the API): expose a scope `Tasks.Access`. Application ID URI: `api://taskflow-dev`.
   - `taskflow-spa` (the client): grant the API permission, redirect URI for local SPA.
2. Get a delegated token for `api://taskflow-dev/Tasks.Access` (Postman OAuth 2.0 helper or `az login` with a SPA flow).
3. Add a policy at the **API scope** that:
   - Validates the JWT against your tenant's OIDC config.
   - Requires `aud == api://taskflow-dev`.
   - Requires `scp` claim contains `Tasks.Access`.
4. Confirm:
   - No token → 401.
   - Wrong audience → 401 with explanatory error.
   - Valid token → 200 from `/api/ping`.

### Deliverable

`P3-policies/jwt-validation.xml` + `P3-entra-setup.md` (App Reg IDs redacted, scopes, token acquisition steps).

### Look-fors

- [ ] `openid-config` URL points to your tenant ID.
- [ ] Failure message includes a **correlation ID** so you can match logs.
- [ ] Required claims include `aud` AND `scp`.

---

## P4 — CORS, Headers, and Backend Auth via Managed Identity  *(Medium)*

**Tags:** `cors` `header-rewrite` `managed-identity`

### Requirements

1. Add a **CORS** policy at the API scope allowing your local SPA origin and the prod hostname.
2. Inject a **correlation ID** header (`x-correlation-id`) inbound; echo it in the response (`outbound`).
3. Strip `x-powered-by` and `server` from outbound responses.
4. Switch APIM → Function App auth from "function key" to **APIM Managed Identity** calling the Function App's Easy Auth (Entra). Document the steps.

### Deliverable

`P4-policies/api-policies.xml` + `P4-mi-backend.md` (sequence diagram + steps).

### Look-fors

- [ ] Browser preflight succeeds (test from your SPA host).
- [ ] Outbound responses no longer leak server identity.
- [ ] APIM no longer needs `x-functions-key`; backend rejects un-MI requests.

---

## P5 — Lock Down the Backend & Publish the Dev Portal  *(Hard)*

**Tags:** `network-restrictions` `developer-portal` `versioning`

### Requirements

1. Add **access restrictions** on the Function App so that only APIM can reach it:
   - For Consumption APIM: whitelist the **outbound APIM IP** (`az apim show --query publicIpAddresses`).
   - Reject all other inbound traffic (deny-all rule at lowest priority).
2. Verify direct Function URL → 403 from your laptop, but APIM URL still works.
3. Customize the **Developer Portal**:
   - Set a friendly title and description.
   - Publish.
   - Subscribe a test "consumer" user and document the self-service flow.
4. Create an **API Version** `v2` from the current API as a copy, so you understand the version-vs-revision distinction.

### Deliverable

`P5-network-and-portal.md` (steps, screenshots) + `P5-lockdown.sh` (idempotent script applying the access restrictions).

### Look-fors

- [ ] `curl https://<func>.azurewebsites.net/api/ping` from your laptop returns 403.
- [ ] APIM still reaches the function (proves the IP whitelist).
- [ ] Developer portal shows your APIs with documentation generated from OpenAPI.
- [ ] `v2` exists alongside `v1` with separate URL.

---

## Submission Checklist

- [ ] All policy XML files committed in `P*-policies/`.
- [ ] Token captures and IDs **redacted** before commit.
- [ ] `README.md` in solutions folder lists each artifact.
- [ ] You can repeat the entire flow from a clean RG using the shell scripts.

---

## Stretch Goals

- Replace shell scripts with **Bicep** for the entire APIM + policy stack.
- Add a `<cache-lookup>` policy on `GET /tasks/{id}` (requires Standard tier — note the SKU jump).
- Wire APIM logs into Log Analytics and write a KQL query for `4xx-by-subscription`.
