# Resource: azurerm_linux_virtual_machine
# Description: Creates the Linux virtual machines used in the frontend or backend tier.
# ## Arguments Reference
# - name: (Required) VM name.
# - resource_group_name: (Required) The resource group of the VM.
# - location: (Required) Azure region.
# - size: (Required) VM size, such as Standard_F1als_v7.
# - admin_username: (Required) Administrative username for the VM.
# - admin_password: (Required) Administrative password for the VM.
# - network_interface_ids: (Required) NICs attached to the VM.
# - os_disk: (Required) OS disk configuration.
# - source_image_reference: (Required) Marketplace image reference.
# - custom_data: (Optional) Cloud-init or bootstrap script.
# - tags: (Optional) Resource tags.
resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.linux_virtual_machines

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  size                = each.value.size
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_ssh_key != null ? null : each.value.admin_password
  disable_password_authentication = each.value.admin_ssh_key != null
  network_interface_ids = [each.value.network_interface_id]
  custom_data = each.value.custom_data != null ? base64encode(each.value.custom_data) : null

  dynamic "admin_ssh_key" {
    for_each = each.value.admin_ssh_key != null ? [each.value.admin_ssh_key] : []
    content {
      username   = each.value.admin_username
      public_key = admin_ssh_key.value
    }
  }

  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}
