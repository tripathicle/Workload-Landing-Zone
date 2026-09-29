resource "azurerm_network_interface" "this" {
  for_each = var.network_interfaces

  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  ip_configuration {
    name                          = each.value.ip_configuration.name
    subnet_id                     = var.subnets[each.value.subnet_key].id
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation
    private_ip_address            = each.value.ip_configuration.private_ip_address
  }

  tags = var.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each = {
    for nic_key, nic in var.network_interfaces :
    nic_key => nic
    if try(nic.backend_pool_key, null) != null
  }

  network_interface_id = azurerm_network_interface.this[each.key].id

  ip_configuration_name = each.value.ip_configuration.name

  backend_address_pool_id = var.backend_address_pools[
    each.value.backend_pool_key
  ].id
}