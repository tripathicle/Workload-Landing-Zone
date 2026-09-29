resource "azurerm_virtual_network_peering" "this" {
  for_each = var.vnet_peerings

  name = each.value.name

  resource_group_name = var.vnets[each.value.source_vnet_key].resource_group_name
  virtual_network_name = var.vnets[
    each.value.source_vnet_key
  ].name

  remote_virtual_network_id = var.vnets[
    each.value.remote_vnet_key
  ].id

  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}