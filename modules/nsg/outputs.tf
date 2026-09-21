# ============================================================
# Network Security Group Outputs
# ============================================================
# CHANGE:
# - Keeps the output keyed by the same logical key supplied
#   by the caller.
# - Exposes only the values downstream modules currently need:
#   NSG ID and name.
#
# Example:
# module.nsg.network_security_groups["frontend"].id
# ============================================================

output "network_security_groups" {
  description = "Map of provisioned Network Security Groups."

  value = {
    for key, nsg in azurerm_network_security_group.this : key => {
      id   = nsg.id
      name = nsg.name
    }
  }
}