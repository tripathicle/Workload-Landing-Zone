output "network_security_groups" {
  description = "Map of provisioned Azure Network Security Groups keyed by the input NSG key."

  value = {
    for nsg_key, nsg in azurerm_network_security_group.this :
    nsg_key => {
      id                  = nsg.id
      name                = nsg.name
      resource_group_name = nsg.resource_group_name
      location            = nsg.location
    }
  }
}