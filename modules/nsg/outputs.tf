output "network_security_groups" {
  description = "Map of NSGs"
  value = {
    for key, nsg in azurerm_network_security_group.this : key => {
      id   = nsg.id
      name = nsg.name
    }
  }
}
