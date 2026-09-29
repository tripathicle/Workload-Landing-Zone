resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = var.vnets[each.value.vnet_key].resource_group_name
  virtual_network_name = var.vnets[each.value.vnet_key].name
  address_prefixes     = each.value.address_prefixes

  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  private_link_service_network_policies_enabled = (
    each.value.private_link_service_network_policies_enabled
  )
}