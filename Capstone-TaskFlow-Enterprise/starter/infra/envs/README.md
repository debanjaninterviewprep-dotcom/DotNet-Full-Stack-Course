# infra/envs/

One folder per environment. Each composes modules from `../modules/` and pins a remote backend.

```
envs/
├── dev/
│   ├── backend.tf       (azurerm backend pointing to state container)
│   ├── providers.tf
│   ├── main.tf          (module calls)
│   ├── variables.tf
│   ├── locals.tf        (standard tags)
│   └── outputs.tf
├── staging/
│   └── ... (same shape)
└── prod/
    └── ... (same shape)
```

## Backend example

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate<unique>"
    container_name       = "tfstate"
    key                  = "taskflow/dev.tfstate"
    use_oidc             = true
  }
}
```

## Locals — standard tags

```hcl
locals {
  standard_tags = {
    owner              = "platform-team@taskflow.example"
    costCenter         = "CC-1042"
    application        = "taskflow"
    environment        = var.env
    dataClassification = "confidential"
  }
}
```

Run via the GitHub Actions workflows; **never** apply prod from your laptop.
