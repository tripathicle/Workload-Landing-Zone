# ============================================================
# NSG ASSOCIATION OUTPUTS
# ============================================================

output "subnet_nsg_associations" {
  description = "Map of provisioned subnet-to-NSG association resource IDs."

  value = {
    for key, association in azurerm_subnet_network_security_group_association.this :
    key => {
      id = association.id
    }
  }
}