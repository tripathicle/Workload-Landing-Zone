output "vnet_peerings" {
  description = "Map of provisioned Azure VNet Peerings keyed by the input peering key."

  value = {
    for peering_key, peering in azurerm_virtual_network_peering.this :
    peering_key => {
      id                        = peering.id
      name                      = peering.name
      resource_group_name       = peering.resource_group_name
      virtual_network_name      = peering.virtual_network_name
      remote_virtual_network_id = peering.remote_virtual_network_id
    }
  }
}