# ============================================================
# POSTGRESQL FLEXIBLE SERVER
# ============================================================

resource "azurerm_postgresql_flexible_server" "this" {
  for_each = var.postgresql_servers

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  version = each.value.version

  administrator_login = each.value.administrator_login

  administrator_password = var.administrator_password

  sku_name = each.value.sku_name

  storage_mb = each.value.storage_mb

  backup_retention_days = each.value.backup_retention_days

  geo_redundant_backup_enabled = (
    each.value.geo_redundant_backup_enabled
  )

  public_network_access_enabled = (
    each.value.public_network_access_enabled
  )

  dynamic "high_availability" {
    for_each = (
      each.value.high_availability != null
      ? [each.value.high_availability]
      : []
    )

    content {
      mode = high_availability.value.mode

      standby_availability_zone = try(
        high_availability.value.standby_availability_zone,
        null
      )
    }
  }

  tags = var.tags

  # ----------------------------------------------------------
  # Azure-managed PostgreSQL zone / HA drift
  #
  # Azure can change the primary availability zone during
  # failover or platform operations. Terraform should not try
  # to move the server back automatically.
  # ----------------------------------------------------------

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# ============================================================
# POSTGRESQL DATABASE
# ============================================================

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = {
    for key, server in var.postgresql_servers :
    key => server
    if server.database != null
  }

  name = each.value.database.name

  server_id = azurerm_postgresql_flexible_server.this[
    each.key
  ].id

  charset = each.value.database.charset

  collation = each.value.database.collation

  # lifecycle {
  #   prevent_destroy = true
  # }

}