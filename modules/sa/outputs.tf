
output "storage_accounts" {
  description = "Map of provisioned Azure Storage Accounts."

  value = {
    for key, storage_account in azurerm_storage_account.this : key => {
      id                    = storage_account.id
      name                  = storage_account.name
      primary_blob_endpoint = storage_account.primary_blob_endpoint
    }
  }
}