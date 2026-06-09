# Topic 6 — Solutions Workspace

```
PracticeProblemsSolutions/
├── README.md
├── copilot-instructions.md         (P1 — put in .github/ of target repo)
├── P1-test-prompts.md
├── P2-spec.md
├── P2-raw.yml
├── P2-final.yml
├── P2-review.md
├── P3-source.yml
├── P3-translated.yml
├── P3-translation-notes.md
├── P4-failure-log.txt
├── P4-conversation.md
├── P4-postmortem.md
├── P5-issue-and-pr.md
├── P5-agent-evaluation.md
├── P6-prompts/
│   ├── generate-tf-module.md
│   ├── add-coverage-gate.md
│   ├── translate-bicep-to-tf.md
│   ├── write-runbook-from-postmortem.md
│   └── review-iac-pr.md
├── P7-log.csv
└── P7-measurement.md
```

---

## Starter: `copilot-instructions.md`

```markdown
# Copilot Instructions — taskflow-infra

## Tooling
- Terraform >= 1.8.0
- Provider: hashicorp/azurerm ~> 4.0
- All providers pinned with `~>` operator
- Lockfile committed (`.terraform.lock.hcl`)

## Conventions
- Resource naming: `<type-prefix>-<project>-<environment>-<region>`
  e.g. `rg-taskflow-dev-eus`, `app-taskflow-dev-eus`
- Modules live under `modules/<name>/` with files: `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `README.md`
- Per-environment configs under `envs/<env>/`

## Security defaults (non-negotiable)
- Storage: `shared_access_key_enabled = false`, `min_tls_version = "TLS1_2"`, `allow_nested_items_to_be_public = false`
- App Services: `https_only = true`, `minimum_tls_version = "1.2"`
- Identity: prefer system-assigned managed identity; never client secrets
- Role assignments: scope to the smallest resource (RG or below); never `Owner`

## GitHub Actions
- All actions pinned by SHA, not by tag
- Workflow-level `permissions:` set to least-privilege
- `concurrency` with `cancel-in-progress` keyed on `ref`
- Every job has `timeout-minutes`
- Use OIDC (`ARM_USE_OIDC=true`); no `client-secret` parameters

## Outputs
- Mark anything credential-shaped as `sensitive = true`
- Document outputs in module READMEs

## Don't
- Hard-code subscription IDs
- Use `terraform workspace` for prod/staging/dev separation
- Generate code that bypasses branch protection
```

---

## Starter: `P6-prompts/generate-tf-module.md`

```markdown
# Prompt: Generate a Terraform Module

## Goal
Scaffold a new Terraform module following taskflow-infra conventions.

## Inputs you must provide
- Module name (single coherent capability)
- Required resources (list)
- Required inputs (with type and defaults)
- Required outputs

## Prompt
Generate a Terraform module under `modules/<NAME>/` with:
- `versions.tf` (Terraform >=1.8, hashicorp/azurerm ~> 4.0)
- `variables.tf` with description + validation for every input
- `main.tf` creating: <RESOURCES>
- `outputs.tf` exposing: <OUTPUTS>
- `README.md` with usage example

All resources must follow taskflow-infra security defaults (no shared keys, TLS 1.2, system-assigned MI). Tag every resource via a `var.tags` merged with `{ managed_by = "terraform" }`.

## Common pitfalls to fix in output
- Module declares `provider` block (it must not — root owns providers)
- Validation rules missing or trivial
- Missing `description` on inputs / outputs
- Outputs that leak secrets not marked `sensitive = true`

## Example
[paste an example call after refining]
```

---

## Submission

Tell me **"check P2"** (or a range) for graded review.
