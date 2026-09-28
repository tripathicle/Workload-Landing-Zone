# ============================================================
# LINUX VIRTUAL MACHINES
# ============================================================

resource "azurerm_linux_virtual_machine" "this" {
  for_each = {
    for vm_key, vm in var.virtual_machines :
    vm_key => vm
    if vm.os_type == "Linux"
  }

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  size = each.value.size

  admin_username = each.value.admin_username

  disable_password_authentication = true

  admin_ssh_key {
    username = each.value.admin_username

    public_key = each.value.admin_ssh_key
  }

  network_interface_ids = [
    var.network_interfaces[
      each.value.nic_key
    ].id
  ]

  # ----------------------------------------------------------
  # SOURCE IMAGE
  # ----------------------------------------------------------

  source_image_reference {
    publisher = each.value.source_image_reference.publisher

    offer = each.value.source_image_reference.offer

    sku = each.value.source_image_reference.sku

    version = each.value.source_image_reference.version
  }

  # ----------------------------------------------------------
  # OS DISK
  #
  # security_encryption_type intentionally omitted.
  #
  # This prevents Terraform from forcing:
  # DiskWithVMGuestState / Confidential VM settings
  # on images that do not support them.
  # ----------------------------------------------------------

  os_disk {
    caching = each.value.os_disk.caching

    storage_account_type = (
      each.value.os_disk.storage_account_type
    )

    disk_size_gb = each.value.os_disk.disk_size_gb
  }

  # ----------------------------------------------------------
  # TRUSTED LAUNCH
  # ----------------------------------------------------------

  secure_boot_enabled = each.value.secure_boot_enabled

  vtpm_enabled = each.value.vtpm_enabled

  # ----------------------------------------------------------
  # CUSTOM DATA
  # ----------------------------------------------------------

  custom_data = (
    each.value.custom_data != null
    ? base64encode(each.value.custom_data)
    : null
  )

  # ----------------------------------------------------------
  # BOOT DIAGNOSTICS
  # ----------------------------------------------------------

  dynamic "boot_diagnostics" {
    for_each = (
      each.value.boot_diagnostics.enabled
      ? [1]
      : []
    )

    content {}
  }

  # ----------------------------------------------------------
  # SYSTEM-ASSIGNED MANAGED IDENTITY
  # ----------------------------------------------------------

  dynamic "identity" {
    for_each = (
      each.value.enable_system_assigned_identity
      ? [1]
      : []
    )

    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags
}


# ============================================================
# WINDOWS VIRTUAL MACHINES
# ============================================================

resource "azurerm_windows_virtual_machine" "this" {
  for_each = {
    for vm_key, vm in var.virtual_machines :
    vm_key => vm
    if vm.os_type == "Windows"
  }

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  size = each.value.size

  admin_username = each.value.admin_username

  admin_password = each.value.admin_password

  network_interface_ids = [
    var.network_interfaces[
      each.value.nic_key
    ].id
  ]

  # ----------------------------------------------------------
  # SOURCE IMAGE
  # ----------------------------------------------------------

  source_image_reference {
    publisher = each.value.source_image_reference.publisher

    offer = each.value.source_image_reference.offer

    sku = each.value.source_image_reference.sku

    version = each.value.source_image_reference.version
  }

  # ----------------------------------------------------------
  # OS DISK
  #
  # security_encryption_type intentionally omitted.
  # ----------------------------------------------------------

  os_disk {
    caching = each.value.os_disk.caching

    storage_account_type = (
      each.value.os_disk.storage_account_type
    )

    disk_size_gb = each.value.os_disk.disk_size_gb
  }

  # ----------------------------------------------------------
  # TRUSTED LAUNCH
  # ----------------------------------------------------------

  secure_boot_enabled = each.value.secure_boot_enabled

  vtpm_enabled = each.value.vtpm_enabled

  # ----------------------------------------------------------
  # CUSTOM DATA
  # ----------------------------------------------------------

  custom_data = (
    each.value.custom_data != null
    ? base64encode(each.value.custom_data)
    : null
  )

  # ----------------------------------------------------------
  # BOOT DIAGNOSTICS
  # ----------------------------------------------------------

  dynamic "boot_diagnostics" {
    for_each = (
      each.value.boot_diagnostics.enabled
      ? [1]
      : []
    )

    content {}
  }

  # ----------------------------------------------------------
  # SYSTEM-ASSIGNED MANAGED IDENTITY
  # ----------------------------------------------------------

  dynamic "identity" {
    for_each = (
      each.value.enable_system_assigned_identity
      ? [1]
      : []
    )

    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags
}