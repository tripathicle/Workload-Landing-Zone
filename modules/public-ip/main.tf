# Resource: azurerm_public_ip
# Description: Creates public IP addresses for ingress and admin access.
# ## Arguments Reference
# - name: (Required) Public IP name.
# - resource_group_name: (Required) Resource group for the public IP.
# - location: (Required) Azure region.
# - allocation_method: (Required) Static or Dynamic.
# - sku: (Optional) Public IP SKU.
# - zones: (Optional) Availability zones.
# - tags: (Optional) Resource tags.
resource "azurerm_public_ip" "this" {
  for_each = var.public_ips

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.allocation_method
  sku                 = each.value.sku
  zones               = lookup(each.value, "zones", [])
  tags                = merge(var.tags, lookup(each.value, "tags", {}))
}
