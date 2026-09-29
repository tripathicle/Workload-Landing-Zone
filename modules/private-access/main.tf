# ============================================================
# PRIVATE DNS ZONES
# ============================================================

resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns_zones

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  tags = var.tags
}


# ============================================================
# PRIVATE DNS ZONE -> VNET LINKS
# ============================================================

# ============================================================
# PRIVATE DNS ZONE -> VNET LINKS
# ============================================================

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.private_dns_zone_vnet_links

  name = each.key

  private_dns_zone_id = azurerm_private_dns_zone.this[
    each.value.dns_zone_key
  ].id

  virtual_network_id = var.vnets[
    each.value.vnet_key
  ].id

  registration_enabled = each.value.registration

  tags = var.tags
}

# ============================================================
# PRIVATE ENDPOINTS
# ============================================================

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name = each.value.name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  subnet_id = var.subnets[
    each.value.subnet_key
  ].id

  private_service_connection {
    name = each.value.private_service_connection.name

    private_connection_resource_id = (
      each.value.private_service_connection
      .private_connection_resource_id
    )

    subresource_names = (
      each.value.private_service_connection
      .subresource_names
    )

    is_manual_connection = (
      each.value.private_service_connection
      .is_manual_connection
    )
  }

  dynamic "private_dns_zone_group" {
    for_each = (
      each.value.private_dns_zone_group != null
      ? [each.value.private_dns_zone_group]
      : []
    )

    content {
      name = private_dns_zone_group.value.name

      private_dns_zone_ids = [
        azurerm_private_dns_zone.this[
          private_dns_zone_group.value.dns_zone_key
        ].id
      ]
    }
  }

  tags = var.tags
}