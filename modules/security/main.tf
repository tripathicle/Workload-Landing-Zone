# resource "azurerm_public_ip" "this" {
#   for_each = var.public_ips
#
#   name                = each.value.name
#   resource_group_name = each.value.resource_group_name
#   location            = each.value.location
#   sku                 = each.value.sku
#   allocation_method   = each.value.allocation_method
#   zones               = length(each.value.zones) > 0 ? each.value.zones : null
#   tags                = merge(var.tags, lookup(each.value, "tags", {}))
# }
#
# resource "azurerm_firewall" "this" {
#   for_each = var.firewalls
#
#   name                = each.value.name
#   resource_group_name = each.value.resource_group_name
#   location            = each.value.location
#   sku_name            = each.value.sku_name
#   sku_tier            = each.value.sku_tier
#   firewall_policy_id  = each.value.firewall_policy_id
#   tags                = merge(var.tags, lookup(each.value, "tags", {}))
#
#   ip_configuration {
#     name                 = "firewall-ip-config"
#     subnet_id            = each.value.subnet_id
#     public_ip_address_id = each.value.public_ip_id
#   }
# }

resource "azurerm_key_vault" "this" {
  for_each = var.key_vaults

  name                          = each.value.name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  tenant_id                     = each.value.tenant_id
  sku_name                      = each.value.sku_name
  purge_protection_enabled      = each.value.purge_protection_enabled
  soft_delete_retention_days    = each.value.soft_delete_retention_days
  public_network_access_enabled = each.value.public_network_access_enabled
  tags                          = merge(var.tags, lookup(each.value, "tags", {}))
}

