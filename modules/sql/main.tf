resource "azurerm_mssql_server" "this" {
  for_each = var.sql_servers

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  version                      = each.value.version
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password

  minimum_tls_version           = each.value.minimum_tls_version
  public_network_access_enabled = each.value.public_network_access_enabled

  tags = merge(
    var.tags,
    each.value.tags
  )
}

resource "azurerm_mssql_database" "this" {
  for_each = var.sql_databases

  name      = each.value.name
  server_id = azurerm_mssql_server.this[each.value.sql_server_key].id

  sku_name = each.value.sku_name

  max_size_gb          = each.value.max_size_gb
  zone_redundant       = each.value.zone_redundant
  storage_account_type = each.value.storage_account_type
  collation            = each.value.collation
  read_scale           = each.value.read_scale
  geo_backup_enabled   = each.value.geo_backup_enabled

  tags = merge(
    var.tags,
    each.value.tags
  )
}