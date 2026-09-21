variable "linux_virtual_machines" {
  description = "Map of Linux virtual machines to provision."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    size                = string

    admin_username = string
    admin_password = optional(string, null)
    admin_ssh_key  = optional(string, null)

    network_interface_id = string

    custom_data = optional(string, null)

    identity_type = optional(string, "SystemAssigned")

    os_disk = object({
      caching              = string
      storage_account_type = string
    })

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      length(trimspace(vm.name)) > 0 &&
      length(trimspace(vm.resource_group_name)) > 0 &&
      length(trimspace(vm.location)) > 0 &&
      length(trimspace(vm.size)) > 0 &&
      length(trimspace(vm.admin_username)) > 0 &&
      length(trimspace(vm.network_interface_id)) > 0
    ])

    error_message = "Each Linux VM must define a non-empty name, resource group, location, size, admin username, and network interface ID."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      vm.admin_ssh_key != null ||
      (
        vm.admin_password != null &&
        length(trimspace(vm.admin_password)) >= 12
      )
    ])

    error_message = "Each Linux VM must provide either an SSH public key or an admin password of at least 12 characters."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      vm.identity_type == null ||
      contains(
        [
          "SystemAssigned",
          "UserAssigned",
          "SystemAssigned, UserAssigned"
        ],
        vm.identity_type
      )
    ])

    error_message = "identity_type must be SystemAssigned, UserAssigned, SystemAssigned, UserAssigned, or null."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      length(trimspace(vm.os_disk.caching)) > 0 &&
      length(trimspace(vm.os_disk.storage_account_type)) > 0
    ])

    error_message = "Each Linux VM must define valid OS disk caching and storage account type values."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      length(trimspace(vm.source_image_reference.publisher)) > 0 &&
      length(trimspace(vm.source_image_reference.offer)) > 0 &&
      length(trimspace(vm.source_image_reference.sku)) > 0 &&
      length(trimspace(vm.source_image_reference.version)) > 0
    ])

    error_message = "Each Linux VM must define publisher, offer, SKU, and version for the source image."
  }
}

variable "tags" {
  description = "Default tags applied to all Linux virtual machines."

  type = map(string)

  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be a non-empty string."
  }
}