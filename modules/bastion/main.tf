resource "azurerm_bastion_host" "this" {
  for_each = var.bastions

  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  sku = each.value.sku

  copy_paste_enabled     = each.value.copy_paste_enabled
  file_copy_enabled      = each.value.file_copy_enabled
  ip_connect_enabled     = each.value.ip_connect_enabled
  shareable_link_enabled = each.value.shareable_link_enabled
  tunneling_enabled      = each.value.tunneling_enabled

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = var.subnets[each.value.subnet_key].id
    public_ip_address_id = var.public_ips[each.value.public_ip_key].id
  }

  tags = var.tags
}