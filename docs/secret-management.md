# Secret Management Pattern

This repository uses a secure Azure DevOps pattern for real deployment values.

## Required approach

1. Keep all secret values out of version control.
2. Store real secrets in Azure Key Vault.
3. Reference them from Azure DevOps Library variables.
4. Inject variables into pipeline jobs as environment variables.
5. Keep only example values in `.tfvars.example` files.

## Azure DevOps variable groups

Create a variable group named `terraform-secrets` and add these variables:

- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`
- `AZURE_SERVICE_CONNECTION`

## Azure Key Vault integration

Use Key Vault to store production secrets such as:

- SQL admin password
- VM admin password
- storage account keys if needed
- service principal secrets when applicable

Then link the Azure DevOps variable group to Key Vault by using Azure Key Vault library linkage.

## Example

The secure pipeline file uses these environment variables:

```yaml
- bash: |
    terraform apply -auto-approve -input=false -var-file=terraform.tfvars
  env:
    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
    ARM_TENANT_ID: $(ARM_TENANT_ID)
    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
```

## Important rule

Never commit files containing real credentials, passwords, or subscription-specific identifiers.
Only commit `.tfvars.example` or sanitized templates.
