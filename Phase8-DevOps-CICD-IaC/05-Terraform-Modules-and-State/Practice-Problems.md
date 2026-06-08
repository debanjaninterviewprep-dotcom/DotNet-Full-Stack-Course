# Topic 5 — Practice Problems

> Solutions in [PracticeProblemsSolutions/](./PracticeProblemsSolutions/). Build on Topic 4's stack.

---

## P1 — Extract Your First Module

**Goal:** Refactor Topic 4's storage account into a reusable module without destroying it.

**Tasks**
1. Create `modules/storage-account/` with `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `README.md`.
2. Move the storage resource code into the module; expose `name`, `resource_group_name`, `location`, `replication_type`, `soft_delete_days`, `tags` as inputs.
3. In the root, replace the resource with a `module "storage" { source = "../modules/storage-account" ... }` call.
4. Add a `moved {}` block so the existing state is migrated (not recreated).
5. Run `terraform init && terraform plan` — must show **no changes**.

**Deliverables**
- `P1-modules/storage-account/` complete module.
- Updated root using the module.
- `P1-plan.txt` showing "no changes".

**Look-fors**
- [ ] `moved {}` block present.
- [ ] Plan shows no resource recreation.
- [ ] Module has its own README with usage example.

---

## P2 — Compose Three Modules

**Goal:** Build a real environment from leaf modules.

**Tasks**
1. Add modules: `network`, `web-app`, `key-vault`.
2. Root composes them:
   - `network` outputs subnet IDs.
   - `web-app` takes a subnet ID and the storage module's ID.
   - `key-vault` grants `Key Vault Secrets User` to the web app's principal ID.
3. All modules pinned by relative path; root passes `common_tags` everywhere.
4. Verify `terraform graph` shows the expected dependency chain.

**Deliverables**
- `P2-modules/` directory.
- `P2-graph.png` (`terraform graph | dot -Tpng > P2-graph.png`).

**Look-fors**
- [ ] No module calls another module (composition flat, not nested).
- [ ] Web App identity is system-assigned and granted KV access.
- [ ] Tags propagate to all resources.

---

## P3 — Remote State in Azure Storage

**Goal:** Move state out of local files.

**Tasks**
1. Bootstrap state storage (`rg-tfstate`, `sttfstate<rand>`, `tfstate` container) via a one-off `P3-bootstrap.sh`. The script must:
   - Disable shared key access.
   - Enable versioning + 30-day soft delete.
   - Assign `Storage Blob Data Contributor` to the current user.
2. Add `backend "azurerm" {}` block (partial config).
3. Create `backend-dev.hcl`, `backend-staging.hcl`, `backend-prod.hcl` with the right `key` paths.
4. Run `terraform init -backend-config=backend-dev.hcl` and migrate.
5. Document recovery steps if state is lost in `P3-recovery.md`.

**Deliverables**
- `P3-bootstrap.sh`
- `backend-*.hcl` files.
- `P3-recovery.md`.

**Look-fors**
- [ ] Bootstrap script is idempotent.
- [ ] Backend storage is locked down (no public access).
- [ ] Recovery doc covers blob-versioning restore.

---

## P4 — State Operations

**Goal:** Practice the dangerous commands in a safe place.

**Tasks**
1. **Rename a resource** with `moved {}`. Plan = no changes.
2. **Move a resource into a module** with `moved {}`. Plan = no changes.
3. **Adopt an existing resource** with `import {}` block (you can create a small KV manually first).
4. **Force-replace** a resource: `terraform apply -replace=...`. Capture the resulting plan.
5. **Disown** a resource: `terraform state rm`. Show that subsequent plan attempts to recreate it (then revert).

Write `P4-state-ops.md` with each command, the before/after state, and one gotcha you learned.

**Deliverables**
- `P4-state-ops.md`.

**Look-fors**
- [ ] All five operations completed.
- [ ] No accidental destroys.
- [ ] Gotchas are specific (e.g., "import requires writing config first").

---

## P5 — Multi-Environment Layout (Folder-per-env)

**Goal:** Switch from single-root to per-env folders.

**Tasks**
1. Reorganise as:
   ```
   infra/
   ├── modules/
   │   └── ...
   └── envs/
       ├── dev/   { main.tf, backend.hcl, terraform.tfvars }
       ├── staging/ { ... }
       └── prod/  { ... }
   ```
2. Each env composes the modules with env-specific sizing (B1 vs P1v3 etc).
3. Add `Makefile` or `tasks.ps1` with targets: `init <env>`, `plan <env>`, `apply <env>`.
4. Migrate the existing dev state to `envs/dev/`.

**Deliverables**
- New folder layout.
- `Makefile` / `tasks.ps1`.
- `P5-migration.md`.

**Look-fors**
- [ ] Env folders are thin — most logic in modules.
- [ ] No shared `tfvars` between envs.
- [ ] Migration didn't recreate resources.

---

## P6 — CI for Modules

**Goal:** Validate modules on every PR; release via tag.

**Tasks**
1. In the `modules/` repo (or subdir), add `.github/workflows/modules-ci.yml`:
   - On PR: `fmt -check`, `validate`, `tflint`, `tfsec`, `terraform test`.
   - On tag `v*`: publish module docs (auto-generate with `terraform-docs`).
2. Add `examples/minimal/` to every module and ensure it `terraform validate`s in CI.
3. Add a `release-please` config so merging a conventional-commit PR auto-tags modules.

**Deliverables**
- `P6-modules-ci.yml`
- `P6-release-please-config.json`
- `terraform-docs` config + a generated README in one module.

**Look-fors**
- [ ] All four checks run for every module.
- [ ] Tag triggers doc publish.
- [ ] Examples validate cleanly.

---

## P7 (Stretch) — Module Testing with `terraform test`

**Goal:** Author at least two `.tftest.hcl` files.

**Tasks**
1. One **happy-path** test: applies the minimal example, asserts on outputs.
2. One **failure** test: passes invalid input, asserts the validation triggers.
3. Run in CI as part of P6.

**Deliverables**
- `tests/*.tftest.hcl` for the storage-account module.

**Look-fors**
- [ ] Tests run with `terraform test`.
- [ ] Failure test uses `expect_failures`.
- [ ] Pipeline fails if a test breaks.

---

## Submission

Tell me **"check P3"** (or a range) for graded review.
