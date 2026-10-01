# ============================================================
# MODULE: STORAGE ACCOUNT
# FILE: modules/storage_account/main.tf
# ============================================================

resource "azurerm_storage_account" "this" {
  #checkov:skip=CKV2_AZURE_33:Storage Private Endpoint is provisioned by the private-access module using this Storage Account resource ID; Checkov does not detect this cross-module graph relationship.
  #checkov:skip=CKV_AZURE_33:Storage Queue service is not used by this workload; Queue logging is therefore not applicable.
  #checkov:skip=CKV_AZURE_206:LRS replication is intentionally selected for this dev workload to avoid unnecessary cross-region or zone redundancy and associated cost.
  #checkov:skip=CKV2_AZURE_1:Customer-managed encryption key is not required for this dev workload; Azure Storage platform-managed encryption is used.

  for_each = var.storage_accounts

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type

  min_tls_version                  = each.value.min_tls_version
  allow_nested_items_to_be_public  = each.value.allow_nested_items_to_be_public
  public_network_access_enabled    = each.value.public_network_access_enabled
  cross_tenant_replication_enabled = each.value.cross_tenant_replication_enabled

  shared_access_key_enabled = each.value.shared_access_key_enabled

  sas_policy {
    expiration_period = each.value.sas_expiration_period
    expiration_action = "Block"
  }

  blob_properties {
    delete_retention_policy {
      days = each.value.blob_delete_retention_days
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}


# ============================================================
# STORAGE CONTAINERS
# ============================================================

resource "azurerm_storage_container" "this" {
  #checkov:skip=CKV_AZURE_34:This SQL Vulnerability Assessment results container is intentionally private; Checkov does not correctly resolve the effective private container access configuration.
  #checkov:skip=CKV2_AZURE_8:This container is used only for SQL Vulnerability Assessment scan results and is not an Azure Activity Log destination.
  #checkov:skip=CKV2_AZURE_21:This container is used only for SQL Vulnerability Assessment scan results; Storage Blob read logging is not applicable to this security scan-results container.

  for_each = var.storage_containers

  name = each.value.name

  storage_account_id = azurerm_storage_account.this[
    each.value.storage_account_key
  ].id

  container_access_type = each.value.container_access_type
}