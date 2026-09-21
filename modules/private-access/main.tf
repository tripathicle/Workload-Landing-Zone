# Resource: azurerm_private_dns_zone
# Description: Creates a private DNS zone for Azure private access scenarios.
# ## Arguments Reference
# - name: (Required) Private DNS zone name.
# - resource_group_name: (Required) Resource group for the DNS zone.
# - tags: (Optional) Resource tags.
# Resource: azurerm_private_endpoint
# Description: Creates a private endpoint for private connectivity to Azure Platform services.
# ## Arguments Reference
# - name: (Required) Private endpoint name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Resource group name.
# - subnet_id: (Required) Subnet used by the private endpoint.
# - private_service_connection: (Required) Private link connection configuration.
# - private_dns_zone_group: (Optional) DNS zone group for private resolution.
# - tags: (Optional) Resource tags.



resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns_zones

  name                = each.value.name
  resource_group_name = each.value.resource_group_name

  tags = merge(
    var.tags,
    each.value.tags
  )
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = each.value.private_service_connection.name
    private_connection_resource_id = each.value.private_service_connection.private_connection_resource_id
    is_manual_connection           = each.value.private_service_connection.is_manual_connection
    subresource_names              = each.value.private_service_connection.subresource_names
    request_message                = each.value.private_service_connection.request_message
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_key != null ? [each.value.private_dns_zone_key] : []

    content {
      name = "${each.key}-private-dns"

      private_dns_zone_ids = [
        azurerm_private_dns_zone.this[
          private_dns_zone_group.value
        ].id
      ]
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.private_dns_zones

  name                  = "${each.key}-vnet-link"
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = false

  tags = merge(
    var.tags,
    each.value.tags
  )
}