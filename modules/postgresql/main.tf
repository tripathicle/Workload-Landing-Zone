resource "azurerm_postgresql_flexible_server" "this" {
  for_each = var.postgresql_servers

  #checkov:skip=CKV_AZURE_136:Geo-redundant backup is intentionally disabled for the dev PostgreSQL server to avoid unnecessary cross-region backup cost.
  #checkov:skip=CKV2_AZURE_57:PostgreSQL Private Endpoint is provisioned by the dedicated private-access module using the PostgreSQL server resource ID; Checkov does not detect this cross-module relationship.

  name                = each.value.name
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  location            = var.resource_groups[each.value.resource_group_key].location

  version = each.value.version

  administrator_login    = each.value.administrator_login
  administrator_password = var.administrator_password

  sku_name   = each.value.sku_name
  storage_mb = each.value.storage_mb

  backup_retention_days         = each.value.backup_retention_days
  geo_redundant_backup_enabled  = each.value.geo_redundant_backup_enabled
  public_network_access_enabled = each.value.public_network_access_enabled

  dynamic "high_availability" {
    for_each = each.value.high_availability == null ? [] : [each.value.high_availability]

    content {
      mode = high_availability.value.mode
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = {
    for server_key, server in var.postgresql_servers :
    server_key => server
    if server.database != null
  }

  name      = each.value.database.name
  server_id = azurerm_postgresql_flexible_server.this[each.key].id

  charset   = each.value.database.charset
  collation = each.value.database.collation
}