# ============================================================
# MODULE: STORAGE ACCOUNT
# FILE: Modules/storage_account/main.tf
# ============================================================
#
# Purpose:
#   Provisions one or more Azure Storage Accounts.
#
# Design:
#   - for_each based
#   - Resource Group resolved using resource_group_key
#   - Location resolved from Resource Group
#   - Common + resource-specific tags
#
# ============================================================

resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                = each.value.name
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  location            = var.resource_groups[each.value.resource_group_key].location

  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type

  min_tls_version                  = each.value.min_tls_version
  allow_nested_items_to_be_public  = each.value.allow_nested_items_to_be_public
  public_network_access_enabled    = each.value.public_network_access_enabled
  cross_tenant_replication_enabled = each.value.cross_tenant_replication_enabled

  tags = merge(
    var.tags,
    each.value.tags
  )
}