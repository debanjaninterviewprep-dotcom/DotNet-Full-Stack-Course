# Topic 4 — Practice Problems

> Solutions go in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). All Terraform must successfully `plan` against a real Azure subscription (or be runnable with `terraform plan -refresh=false` against mocked providers).

---

## P1 — First Stack: RG + Storage

**Goal:** Provision an Azure RG and a hardened storage account.

**Tasks**
1. Write `P1-stack/` with: `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars`.
2. Variables: `project`, `environment`, `location`, `tags` (map).
3. Resources:
   - Resource Group.
   - Storage Account with **all** of:
     - `shared_access_key_enabled = false`
     - `min_tls_version = "TLS1_2"`
     - `allow_nested_items_to_be_public = false`
     - `blob_properties.versioning_enabled = true`
     - 30-day soft delete
4. Outputs: RG name, storage account name, primary blob endpoint.
5. Run `terraform fmt`, `validate`, `plan`, `apply`. Capture outputs.

**Deliverables**
- The full `P1-stack/` folder.
- `P1-run.md` with the `apply` summary.

**Look-fors**
- [ ] Provider version pinned with `~>`.
- [ ] `.terraform.lock.hcl` committed.
- [ ] No secrets in code.
- [ ] All resources tagged with project + environment + managed_by.

---

## P2 — Variables, Locals, Validation

**Goal:** Make the stack reusable and resistant to misuse.

**Tasks**
1. Add validation rules:
   - `project` matches `^[a-z]{4,12}$`.
   - `environment` ∈ {dev, staging, prod}.
   - `location` ∈ {eastus, westus2, westeurope}.
   - `instance_count` between 1 and 10.
2. Add a `local.is_prod` and use it to switch SKUs in P3.
3. Add a `local.common_tags` merging user tags with `managed_by = terraform`.
4. Provide one `dev.tfvars` and one `prod.tfvars` to demonstrate env switching.

**Deliverables**
- Updated `variables.tf`, `main.tf`, `dev.tfvars`, `prod.tfvars`.

**Look-fors**
- [ ] All validations fail with helpful messages.
- [ ] `dev.tfvars` and `prod.tfvars` differ in expected places only.
- [ ] No env-specific logic outside `locals`.

---

## P3 — App Service + System-Assigned Identity + RBAC

**Goal:** Add a Linux Web App that can read/write blobs with no secrets.

**Tasks**
1. Add `azurerm_service_plan` (SKU: `B1` dev / `P1v3` prod via `local.is_prod`).
2. Add `azurerm_linux_web_app` with:
   - System-assigned identity.
   - `https_only = true`.
   - .NET 8.
   - `health_check_path = "/health"`.
   - App Insights connection string app setting.
3. Add `azurerm_application_insights` (Workspace-based; create the workspace too).
4. Grant the web app identity **`Storage Blob Data Contributor`** on the storage account.

**Deliverables**
- Updated `main.tf`, `outputs.tf` (add app URL).
- `P3-plan.txt` (truncated `terraform plan` output).

**Look-fors**
- [ ] Identity block present.
- [ ] Role assignment scoped to the storage account, not RG.
- [ ] App Insights wired via connection string, not instrumentation key.

---

## P4 — Import an Existing Resource

**Goal:** Adopt a manually-created resource into Terraform without recreating it.

**Tasks**
1. In the Portal (or with az), create a Key Vault that Terraform did **not** create.
2. Write matching Terraform config (`azurerm_key_vault.kv`) with the **same** properties.
3. Run `terraform import azurerm_key_vault.kv /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/<name>`.
4. Run `terraform plan` — it should show **no changes**. If it shows changes, adjust your code until it doesn't.

**Deliverables**
- `P4-kv.tf` with the imported resource.
- `P4-import.md` describing the process and the gotchas you hit.

**Look-fors**
- [ ] Final plan is "no changes".
- [ ] Notes call out which fields are read-only / computed.

---

## P5 — Drift Detection

**Goal:** Catch out-of-band changes.

**Tasks**
1. Apply P3 to dev.
2. In the Portal, modify the App Service: change `health_check_path` to `/`.
3. Run `terraform plan -refresh-only`. Observe the drift.
4. Run `terraform apply -refresh-only`. Observe state update.
5. Run `terraform plan`. Now you should see Terraform wanting to restore `/health`.
6. Decide: accept the Portal change (update code) OR reject it (apply).
7. Write `P5-drift-policy.md`: when to accept, when to reject, and which fields are too noisy to enforce (suggest `ignore_changes`).

**Deliverables**
- `P5-drift-policy.md`.
- Screenshots / transcripts of each step.

**Look-fors**
- [ ] Correct distinction between `-refresh-only` and a normal plan.
- [ ] Policy lists at least one field worth `ignore_changes`.

---

## P6 — Wire It Into GitHub Actions (PR plan comments)

**Goal:** Plan on PR, apply on merge.

**Tasks**
1. Set up OIDC federation for `id-taskflow-tf-dev` (you may reuse from Topic 1 P4).
2. Write `.github/workflows/terraform.yml`:
   - `plan` job on PR — posts a `terraform show -no-color tfplan` excerpt as PR comment.
   - `apply` job on push to main, gated by `environment: production`.
   - Both jobs use `ARM_USE_OIDC=true`.
3. Configure branch protection so the `plan` check is required.

**Deliverables**
- `P6-terraform.yml`.
- A real (or simulated) PR transcript showing the plan comment in `P6-pr-walkthrough.md`.

**Look-fors**
- [ ] OIDC, not service-principal secret.
- [ ] Plan comment is the **actual** plan diff, not a placeholder.
- [ ] Apply is environment-gated.

---

## P7 (Stretch) — Policy-as-Code Gate

**Goal:** Block bad plans before apply.

**Tasks**
1. Install `tfsec` and `conftest` locally; both run in CI.
2. Add `P7-policy/` with at least three Rego policies:
   - Disallow public blob containers.
   - Require tags `project`, `environment`, `cost_center`.
   - Require `min_tls_version = TLS1_2` on storage / web app.
3. Add them to the CI workflow; the job must fail on violation.

**Deliverables**
- `P7-policy/*.rego`
- Updated workflow snippet.
- `P7-results.md`: which policies caught what (write a small intentional violation to demonstrate).

**Look-fors**
- [ ] Policies are testable (`conftest test`).
- [ ] CI fails loudly on violation; passes when fixed.

---

## Submission

Tell me **"check P3"** (or a range) for graded review.
