output "nsg_associations" {
  description = "Map of Network Security Group to Subnet associations."

  value = {
    for association_key, association in azurerm_subnet_network_security_group_association.this :
    association_key => {
      id                        = association.id
      subnet_id                 = association.subnet_id
      network_security_group_id = association.network_security_group_id
    }
  }
}