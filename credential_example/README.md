# Credential Example Guide

This folder contains example values for the Terraform environment files.

## Purpose

Use this as a reference when creating real values for an environment before running `terraform apply`.

Do not commit actual credentials or live Azure IDs to the repository.

## How to use

1. Copy the values from this file into a real environment file such as:
   - `env/dev/terraform.tfvars`
   - `env/stage/terraform.tfvars`
   - `env/prod/terraform.tfvars`
2. Replace all placeholder values with the actual Azure values for your subscription.
3. Keep secrets in Azure DevOps variable groups or Azure Key Vault.

## Placeholder pattern

Use this pattern for values that must be replaced:

- `<REPLACE_WITH_SUBSCRIPTION_ID>`
- `<REPLACE_WITH_TENANT_ID>`
- `<REPLACE_WITH_RESOURCE_GROUP>`
- `<REPLACE_WITH_VNET_NAME>`
- `<REPLACE_WITH_VM_PASSWORD>`
- `<REPLACE_WITH_STRONG_PASSWORD>`

## Example structure

```hcl
location    = "japaneast"
environment = "dev"

tags = {
  environment = "dev"
  managed_by  = "terraform"
  owner       = "platform-team"
}

resource_groups = {
  platform = {
    name = "rg-platform-jpe-dev"
  }
}
```

## Important rule

A `.tfvars` file must contain literal values only.
Do not write any of the following inside a real tfvars file:

```hcl
var.some_value
module.some_output
```

Use real strings, numbers, lists, and maps only.

## Example credentials checklist

Before deployment, replace:

- subscription ID
- tenant ID
- resource group names
- storage account names
- VNet names
- subnet IDs
- NIC IDs
- public IP IDs
- VM password
- SQL admin password

## Recommended secret handling

- store passwords and tenant values in Azure Key Vault
- inject them through Azure DevOps variables
- keep the repo free of live secrets
