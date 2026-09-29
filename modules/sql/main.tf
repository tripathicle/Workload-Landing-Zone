# ============================================================
# AZURE SQL SERVER
# ============================================================

resource "azurerm_mssql_server" "this" {
  for_each = var.sql_servers

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  version = each.value.version

  administrator_login = each.value.administrator_login

  administrator_login_password = var.administrator_password

  minimum_tls_version = each.value.minimum_tls_version

  public_network_access_enabled = (
    each.value.public_network_access_enabled
  )

  tags = var.tags
}


# ============================================================
# AZURE SQL DATABASE
# ============================================================

resource "azurerm_mssql_database" "this" {
  for_each = {
    for key, server in var.sql_servers :
    key => server
    if server.database != null
  }

  name = each.value.database.name

  server_id = azurerm_mssql_server.this[
    each.key
  ].id

  sku_name = each.value.database.sku_name

  max_size_gb = each.value.database.max_size_gb

  zone_redundant = each.value.database.zone_redundant

  storage_account_type = (
    each.value.database.storage_account_type
  )

  tags = var.tags
}