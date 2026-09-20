output "network_interfaces" {
  description = "Map of NICs"
  value = {
    for key, nic in azurerm_network_interface.this : key => {
      id   = nic.id
      name = nic.name
    }
  }
}
