# ============================================================
# Network Interface Outputs
# ============================================================
# CHANGE:
# - Output remains a map keyed by the same logical key supplied
#   by the caller.
# - Exposes ID and name for downstream modules.
#
# Example:
# module.nic.network_interfaces["frontend_01"].id
#
# This is what the VM module consumes.
# ============================================================

output "network_interfaces" {
  description = "Map of provisioned network interfaces."

  value = {
    for key, nic in azurerm_network_interface.this : key => {
      id   = nic.id
      name = nic.name
    }
  }
}