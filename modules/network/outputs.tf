output "vnets" {
  description = "Map of created virtual networks"
  value = {
    for key, vnet in azurerm_virtual_network.this : key => {
      id   = vnet.id
      name = vnet.name
    }
  }
}

output "subnets" {
  description = "Map of created subnets"
  value = {
    for key, subnet in azurerm_subnet.this : key => {
      id   = subnet.id
      name = subnet.name
    }
  }
}
