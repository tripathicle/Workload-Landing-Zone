variable "public_ips" {
  description = "Map of Azure Public IP addresses used by ingress and administrative components."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    allocation_method = optional(string, "Static")
    sku               = optional(string, "Standard")
    zones             = optional(list(string), [])
    tags              = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, pip in var.public_ips :
      length(trimspace(pip.name)) > 0 &&
      length(trimspace(pip.resource_group_name)) > 0 &&
      length(trimspace(pip.location)) > 0
    ])

    error_message = "Each Public IP must have a non-empty name, resource group name, and location."
  }

  validation {
    condition = alltrue([
      for key, pip in var.public_ips :
      contains(
        ["Static", "Dynamic"],
        pip.allocation_method
      )
    ])

    error_message = "Public IP allocation_method must be either Static or Dynamic."
  }

  validation {
    condition = alltrue([
      for key, pip in var.public_ips :
      contains(
        ["Basic", "Standard"],
        pip.sku
      )
    ])

    error_message = "Public IP SKU must be either Basic or Standard."
  }

  validation {
    condition = alltrue([
      for key, pip in var.public_ips :
      pip.sku == "Standard" || length(pip.zones) == 0
    ])

    error_message = "Availability zones should only be configured for Standard Public IPs."
  }
}


variable "tags" {
  description = "Default tags applied to all Public IP resources."

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