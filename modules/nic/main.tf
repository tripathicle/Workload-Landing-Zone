# Resource: azurerm_network_interface
# Description: Creates NICs for attaching VM workloads to the proper subnets.
# ## Arguments Reference
# - name: (Required) NIC name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Target resource group.
# - ip_configuration: (Required) NIC IP configuration block.
# - tags: (Optional) Resource tags.
resource "azurerm_network_interface" "this" {
  for_each = var.network_interfaces

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                          = each.value.ip_configuration.name
    subnet_id                     = each.value.ip_configuration.subnet_id
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation
    private_ip_address            = try(each.value.ip_configuration.private_ip_address, null)
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}
