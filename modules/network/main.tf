# Resource: azurerm_virtual_network
# Description: Creates the hub and spoke VNets used in the Azure landing zone.
# ## Arguments Reference
# - name: (Required) Name of the virtual network.
# - resource_group_name: (Required) Resource group where the VNet is deployed.
# - location: (Required) Azure region for the VNet.
# - address_space: (Required) CIDR range for the VNet.
# - tags: (Optional) Tags applied to the VNet.
locals {
  subnets = merge([
    for vnet_key, vnet in var.vnets : {
      for subnet_key, subnet in vnet.subnets : "${vnet_key}-${subnet_key}" => {
        vnet_name           = vnet.name
        resource_group_name = vnet.resource_group_name
        subnet_name         = subnet.name
        address_prefixes    = subnet.address_prefixes
      }
    }
  ]...)
}

resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  name                = each.value.name
  location            = var.location
  resource_group_name = each.value.resource_group_name
  address_space       = each.value.address_space
  tags                = merge(var.tags, lookup(each.value, "tags", {}))
}

resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                 = each.value.subnet_name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = lookup(var.vnets[split("-", each.key)[0]], "subnets", {})[split("-", each.key)[1]].service_endpoints
}

resource "azurerm_virtual_network_peering" "this" {
  for_each = {
    for pair in flatten([
      for source_key, source_vnet in var.vnets : [
        for target_key, target_vnet in var.vnets : {
          source_key           = source_key
          target_key           = target_key
          source_vnet_name     = source_vnet.name
          source_rg_name       = source_vnet.resource_group_name
          target_vnet_name     = target_vnet.name
          target_rg_name       = target_vnet.resource_group_name
        }
        if source_key != target_key
      ]
    ]) : "${pair.source_key}-to-${pair.target_key}" => pair
  }

  name                         = "${each.value.source_key}-to-${each.value.target_key}"
  resource_group_name          = each.value.source_rg_name
  virtual_network_name         = azurerm_virtual_network.this[each.value.source_key].name
  remote_virtual_network_id    = azurerm_virtual_network.this[each.value.target_key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
