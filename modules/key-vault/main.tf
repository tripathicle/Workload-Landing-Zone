# ============================================================
# KEY VAULT
# ============================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  #checkov:skip=CKV2_AZURE_32:Private Endpoint is provisioned by the private-access module using this Key Vault resource ID; Checkov does not detect this cross-module graph relationship.

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

  network_acls {
    bypass                     = each.value.network_acls.bypass
    default_action             = each.value.network_acls.default_action
    ip_rules                   = each.value.network_acls.ip_rules
    virtual_network_subnet_ids = each.value.network_acls.virtual_network_subnet_ids
  }

  tags = var.tags
}