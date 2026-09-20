# Resource: azurerm_key_vault
# Description: Creates Azure Key Vault instances for secure secret storage and application configuration values.
# ## Arguments Reference
# - name: (Required) Key Vault name.
# - resource_group_name: (Required) Resource group where the vault is created.
# - location: (Required) Azure region.
# - tenant_id: (Required) Microsoft Entra tenant ID used by the vault.
# - sku_name: (Required) Pricing tier for the Key Vault.
# - purge_protection_enabled: (Optional) Enables purge protection.
# - soft_delete_retention_days: (Optional) Number of days to retain soft-deleted vaults.
# - public_network_access_enabled: (Optional) Allows public network access.
# - tags: (Optional) Resource tags.
resource "azurerm_key_vault" "this" {
  for_each = var.key_vaults

  name                          = each.value.name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  tenant_id                     = each.value.tenant_id
  sku_name                      = each.value.sku_name
  purge_protection_enabled      = each.value.purge_protection_enabled
  soft_delete_retention_days    = each.value.soft_delete_retention_days
  public_network_access_enabled = each.value.public_network_access_enabled
  tags                          = merge(var.tags, lookup(each.value, "tags", {}))
}
