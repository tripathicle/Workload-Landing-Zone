output "vnets" {
  description = "Map of created virtual networks keyed by logical VNet key."

  value = {
    for key, vnet in azurerm_virtual_network.this : key => {
      id            = vnet.id
      name          = vnet.name
      address_space = vnet.address_space
    }
  }
}


output "subnets" {
  description = "Map of created subnets keyed by '<vnet_key>-<subnet_key>'."

  value = {
    for key, subnet in azurerm_subnet.this : key => {
      id               = subnet.id
      name             = subnet.name
      address_prefixes = subnet.address_prefixes
    }
  }
}