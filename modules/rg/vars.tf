variable "resource_groups" {
  description = "Map of Azure resource groups to provision."

  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, rg in var.resource_groups :
      length(trimspace(rg.name)) > 0 &&
      length(trimspace(rg.location)) > 0
    ])

    error_message = "Each resource group must define a non-empty name and location."
  }

  validation {
    condition = alltrue([
      for key, rg in var.resource_groups :
      can(regex("^[A-Za-z0-9._()-]+$", rg.name))
    ])

    error_message = "Each resource group name contains invalid characters."
  }
}

variable "tags" {
  description = "Default tags applied to all resource groups."

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