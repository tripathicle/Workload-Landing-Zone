# ============================================================
# MODULE: RESOURCE GROUP
# FILE: Modules/resource_group/outputs.tf
# ============================================================
#
# Purpose:
#   Exposes stable Resource Group information to consuming
#   Terraform modules.
#
# ============================================================

output "resource_groups" {
  description = "Map of provisioned Azure Resource Groups keyed by the input resource group key."

  value = {
    for resource_group_key, resource_group in azurerm_resource_group.this : resource_group_key => {
      id       = resource_group.id
      name     = resource_group.name
      location = resource_group.location
    }
  }
}