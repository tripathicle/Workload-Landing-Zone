# ============================================================
# VIRTUAL MACHINES
# ============================================================

variable "virtual_machines" {
  description = "Map of Linux and Windows Virtual Machines to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    nic_key            = string

    os_type = string
    size    = string

    admin_username = string

    admin_ssh_key = optional(string)
    admin_password = optional(string)

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    os_disk = optional(object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
      disk_size_gb         = optional(number, 30)
    }), {})

    custom_data = optional(string)

    enable_system_assigned_identity = optional(bool, true)

    secure_boot_enabled = optional(bool, true)

    vtpm_enabled = optional(bool, true)

    boot_diagnostics = optional(object({
      enabled = optional(bool, true)
    }), {})
  }))

  validation {
    condition = length(var.virtual_machines) > 0

    error_message = "At least one Virtual Machine must be defined."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      contains(["Linux", "Windows"], vm.os_type)
    ])

    error_message = "Virtual Machine os_type must be either Linux or Windows."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      length(trimspace(vm.name)) > 0
    ])

    error_message = "Each Virtual Machine must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      length(trimspace(vm.admin_username)) > 0
    ])

    error_message = "Each Virtual Machine must define a non-empty admin username."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      contains(
        [
          "ReadOnly",
          "ReadWrite",
          "None"
        ],
        vm.os_disk.caching
      )
    ])

    error_message = "OS disk caching must be ReadOnly, ReadWrite, or None."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      contains(
        [
          "Standard_LRS",
          "StandardSSD_LRS",
          "Premium_LRS",
          "StandardSSD_ZRS",
          "Premium_ZRS"
        ],
        vm.os_disk.storage_account_type
      )
    ])

    error_message = "Unsupported OS disk storage account type."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_disk.disk_size_gb >= 30
    ])

    error_message = "OS disk size must be at least 30 GB."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Linux" || vm.admin_ssh_key != null
    ])

    error_message = "Linux Virtual Machines must define an SSH public key."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Windows" || vm.admin_password != null
    ])

    error_message = "Windows Virtual Machines must define an administrator password."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Linux" || vm.admin_password == null
    ])

    error_message = "Linux Virtual Machines must use SSH authentication and must not define an admin password."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Windows" || vm.admin_ssh_key == null
    ])

    error_message = "Windows Virtual Machines should not define an SSH public key."
  }
}


# ============================================================
# RESOURCE GROUPS
# ============================================================

variable "resource_groups" {
  description = "Resource Groups created by the Resource Group module."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))

  validation {
    condition = length(var.resource_groups) > 0

    error_message = "At least one Resource Group must be available."
  }
}


# ============================================================
# NETWORK INTERFACES
# ============================================================

variable "network_interfaces" {
  description = "Network Interfaces created by the NIC module."

  type = map(object({
    id                 = string
    name               = string
    private_ip_address = string
  }))

  validation {
    condition = length(var.network_interfaces) > 0

    error_message = "At least one Network Interface must be available."
  }
}



# ============================================================
# COMMON TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to Virtual Machines."

  type    = map(string)
  default = {}
}