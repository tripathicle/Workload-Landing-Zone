output "network_interfaces" {
  description = "Network Interface details."

  value = {
    for key, nic in azurerm_network_interface.this :
    key => {
      id                 = nic.id
      name               = nic.name
      private_ip_address = nic.ip_configuration[0].private_ip_address
    }
  }
}