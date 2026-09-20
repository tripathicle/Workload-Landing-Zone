# Resource: azurerm_storage_account
# Description: Creates a storage account with enterprise defaults for secure access and supported Azure storage configuration.
# ## Arguments Reference
# - name: (Required) Storage account name used in the Azure subscription.
# - resource_group_name: (Required) Resource group where the storage account is created.
# - location: (Required) Azure region for the storage account.
# - account_tier: (Required) Storage performance tier such as Standard or Premium.
# - account_replication_type: (Required) Redundancy policy such as LRS, GRS, or ZRS.
# - min_tls_version: (Optional) Minimum TLS version enforced for secure access.
# - allow_nested_items_to_be_public: (Optional) Controls public access to nested items.
# - public_network_access_enabled: (Optional) Enables or disables public network access.
# - tags: (Optional) Tag set applied to the storage account.
resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                     = each.value.name
  resource_group_name      = each.value.resource_group_name
  location                 = var.location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags = merge(var.tags, each.value.tags)
}
