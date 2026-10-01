# ============================================================
# MODULE: STORAGE ACCOUNT
# FILE: modules/storage_account/outputs.tf
# ============================================================

output "storage_accounts" {
  description = "Map of provisioned Azure Storage Accounts keyed by the input storage account key."

  sensitive = true

  value = {
    for storage_account_key, storage_account in azurerm_storage_account.this :
    storage_account_key => {
      id                    = storage_account.id
      name                  = storage_account.name
      resource_group_name   = storage_account.resource_group_name
      location              = storage_account.location
      primary_blob_endpoint = storage_account.primary_blob_endpoint
      primary_access_key    = storage_account.primary_access_key
    }
  }
}


output "storage_containers" {
  description = "Map of provisioned Azure Storage Containers keyed by the input container key."

  value = {
    for container_key, container in azurerm_storage_container.this :
    container_key => {
      id                 = container.id
      name               = container.name
      storage_account_id = container.storage_account_id
    }
  }
}