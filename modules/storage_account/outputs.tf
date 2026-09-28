# ============================================================
# MODULE: STORAGE ACCOUNT
# FILE: Modules/storage_account/outputs.tf
# ============================================================
#
# Purpose:
#   Exposes stable Storage Account information to consuming
#   Terraform modules.
#
# ============================================================

output "storage_accounts" {
  description = "Map of provisioned Azure Storage Accounts keyed by the input storage account key."

  value = {
    for storage_account_key, storage_account in azurerm_storage_account.this :
    storage_account_key => {
      id                    = storage_account.id
      name                  = storage_account.name
      resource_group_name   = storage_account.resource_group_name
      location              = storage_account.location
      primary_blob_endpoint = storage_account.primary_blob_endpoint
    }
  }
}