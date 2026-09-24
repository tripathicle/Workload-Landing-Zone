resource "azurerm_postgresql_flexible_server" "this" {
  for_each = var.postgresql_servers

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  version    = each.value.version
  sku_name   = each.value.sku_name
  storage_mb = each.value.storage_mb

  administrator_login    = each.value.administrator_login
  administrator_password = each.value.administrator_password

  backup_retention_days        = each.value.backup_retention_days
  geo_redundant_backup_enabled = each.value.geo_redundant_backup_enabled

  public_network_access_enabled = each.value.public_network_access_enabled

  zone = each.value.zone

  tags = merge(
    var.tags,
    each.value.tags
  )
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = var.postgresql_databases

  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this[each.value.postgresql_server_key].id

  charset   = each.value.charset
  collation = each.value.collation
}