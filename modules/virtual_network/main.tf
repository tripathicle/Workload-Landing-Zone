resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  #checkov:skip=CKV_AZURE_183:Azure-provided platform DNS is intentionally used for this workload; no custom DNS server infrastructure is deployed.

  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  address_space = each.value.address_space
  dns_servers   = each.value.dns_servers

  tags = merge(
    var.tags,
    each.value.tags
  )
}