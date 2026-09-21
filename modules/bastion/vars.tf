variable "bastions" {
  description = "Map of Azure Bastion hosts to provision."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    ip_configuration = object({
      name                 = string
      subnet_id            = string
      public_ip_address_id = string
    })

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, bastion in var.bastions :
      length(trimspace(bastion.name)) > 0 &&
      length(trimspace(bastion.resource_group_name)) > 0 &&
      length(trimspace(bastion.location)) > 0 &&
      length(trimspace(bastion.ip_configuration.name)) > 0 &&
      length(trimspace(bastion.ip_configuration.subnet_id)) > 0 &&
      length(trimspace(bastion.ip_configuration.public_ip_address_id)) > 0
    ])

    error_message = "Each Bastion host must define a non-empty name, resource group, location, IP configuration name, subnet ID, and public IP address ID."
  }
}

variable "tags" {
  description = "Default tags applied to Bastion resources."

  type    = map(string)
  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be non-empty."
  }
}