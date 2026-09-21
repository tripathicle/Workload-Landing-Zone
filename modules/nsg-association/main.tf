# ============================================================
# NSG ASSOCIATION
# ============================================================
# Associates each subnet with its corresponding Network
# Security Group.
#
# The module does not create subnets or NSGs.
# It consumes their IDs from the parent module outputs.
# ============================================================

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnet_nsg_associations

  subnet_id = var.subnets[
    each.value.subnet_name
  ].id

  network_security_group_id = var.nsgs[
    each.value.network_security_group_name
  ].id
}

# ============================================================
# SUBNET -> NSG ASSOCIATIONS
# ============================================================
# CHANGE:
# - NSGs are created by module.nsg.
# - Subnets are created by module.network.
# - This module connects the two using their outputs.
#
# IMPORTANT:
# The logical keys here must match the keys expected by the
# nsg-association child module.
# ============================================================
# SUBNET -> NSG ASSOCIATIONS
# ============================================================
# PURPOSE:
# - Associates workload subnets with their corresponding NSGs.
# - Subnets are created by the network module.
# - NSGs are created by the NSG module.
# - Environment-specific association mapping is maintained
#   in terraform.tfvars.
#
# FLOW:
#
# terraform.tfvars
#       |
#       v
# var.subnet_nsg_associations
#       |
#       v
# nsg-association module
#       |
#       +---- module.network.subnets
#       |
#       +---- module.nsg.network_security_groups
#       |
#       v
# Azure Subnet <-> Azure NSG
# ============================================================
