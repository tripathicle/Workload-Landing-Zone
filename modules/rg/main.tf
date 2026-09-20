# Resource: azurerm_resource_group
# Description: Creates a resource group for the landing zone.
# ## Arguments Reference
# - name: (Required) The name of the resource group.
# - location: (Required) Azure region for the resource group.
# - tags: (Optional) Tags applied to the resource group.
resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups

  name     = each.value.name
  location = var.location
  tags     = merge(var.tags, each.value.tags)
}
