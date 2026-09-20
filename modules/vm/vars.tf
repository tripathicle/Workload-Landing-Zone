variable "linux_virtual_machines" {
  description = "Map of Linux VMs for the app tier"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    size                = string
    admin_username      = string
    admin_password      = optional(string, null)
    admin_ssh_key       = optional(string, null)
    network_interface_id = string
    custom_data         = optional(string, null)
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
}

variable "tags" {
  description = "Default tags to apply to all virtual machines"
  type        = map(string)
  default     = {}
}
