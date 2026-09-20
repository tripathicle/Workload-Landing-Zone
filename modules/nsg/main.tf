# Resource: azurerm_network_security_group
# Description: Creates a security group for filtering inbound and outbound traffic.
# ## Arguments Reference
# - name: (Required) NSG name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Target resource group.
# - security_rule: (Required) Inbound or outbound network rules.
# - tags: (Optional) Resource tags.
resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = merge(var.tags, lookup(each.value, "tags", {}))

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
