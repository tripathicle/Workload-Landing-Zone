# ============================================================
# MODULE: VNET
# FILE: Modules/vnet/main.tf
# ============================================================

resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  address_space = each.value.address_space

  dns_servers = each.value.dns_servers

  tags = merge(
    var.tags,
    each.value.tags
  )
}