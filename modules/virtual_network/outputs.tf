# ============================================================
# MODULE: VIRTUAL NETWORK
# FILE: modules/virtual_network/outputs.tf
# ============================================================

output "vnets" {
  description = "Map of provisioned Virtual Networks keyed by the input VNet key."

  value = {
    for vnet_key, vnet in azurerm_virtual_network.this :
    vnet_key => {
      id                  = vnet.id
      name                = vnet.name
      resource_group_name = vnet.resource_group_name
      location            = vnet.location
      address_space       = vnet.address_space
    }
  }
}