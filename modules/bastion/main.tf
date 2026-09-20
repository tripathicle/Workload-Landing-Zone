# Resource: azurerm_bastion_host
# Description: Creates an Azure Bastion host for secure administrative access to the hub network.
# ## Arguments Reference
# - name: (Required) Bastion host name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Resource group name.
# - ip_configuration: (Required) Bastion IP configuration block.
# - tags: (Optional) Resource tags.
resource "azurerm_bastion_host" "this" {
  for_each = var.bastions

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = each.value.subnet_id
    public_ip_address_id = each.value.public_ip_address_id
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}
