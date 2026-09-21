# Resource: azurerm_network_interface
# Description: Creates NICs for attaching VM workloads to the proper subnets.
# ## Arguments Reference
# - name: (Required) NIC name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Target resource group.
# - ip_configuration: (Required) NIC IP configuration block.
# - tags: (Optional) Resource tags.

# ============================================================
# Azure Network Interface
# ============================================================
# CHANGE:
# - Kept the module generic and reusable.
# - NIC receives an already-resolved subnet_id from the root module.
# - Supports both Static and Dynamic private IP allocation.
# - Tags are merged so module-level tags and NIC-specific tags
#   can coexist.
#
# DESIGN:
# env/dev -> resolves vnet/subnet -> passes subnet_id -> NIC module
#
# The child module does NOT know about dev/prod, VNet names,
# subscription IDs, or environment-specific naming.
# ============================================================

resource "azurerm_network_interface" "this" {
  for_each = var.network_interfaces

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name = each.value.ip_configuration.name

    # CHANGE:
    # subnet_id is passed into the reusable module.
    # No subnet/resource lookup is hardcoded here.
    subnet_id = each.value.ip_configuration.subnet_id

    # CHANGE:
    # Supports both Static and Dynamic allocation.
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation

    # CHANGE:
    # Static IP is supplied only when configured.
    # Dynamic IP can safely use null.
    private_ip_address = each.value.ip_configuration.private_ip_address
  }

  # CHANGE:
  # Common module tags + resource-specific tags.
  # Resource-specific tags override duplicate common keys.
  tags = merge(
    var.tags,
    each.value.tags
  )
}