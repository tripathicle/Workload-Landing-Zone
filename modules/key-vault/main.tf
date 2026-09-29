# ============================================================
# CURRENT AZURE CLIENT CONFIGURATION
# ============================================================

data "azurerm_client_config" "current" {}


# ============================================================
# AZURE KEY VAULT
# ============================================================

resource "azurerm_key_vault" "this" {
  for_each = var.key_vaults

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  tenant_id = coalesce(
    each.value.tenant_id,
    data.azurerm_client_config.current.tenant_id
  )

  sku_name = each.value.sku_name

  soft_delete_retention_days = each.value.soft_delete_retention_days
  purge_protection_enabled   = each.value.purge_protection_enabled

  public_network_access_enabled = each.value.public_network_access_enabled

  enabled_for_disk_encryption = each.value.enabled_for_disk_encryption
  enabled_for_deployment      = each.value.enabled_for_deployment
  enabled_for_template_deployment = (
    each.value.enabled_for_template_deployment
  )

  rbac_authorization_enabled = each.value.enable_rbac_authorization

  tags = var.tags
}