variable "location" {
  description = "Azure region for the resource groups. Must be an approved enterprise region and match the deployment landing zone."
  type        = string

  validation {
    condition     = contains(["japaneast", "eastus", "eastus2", "centralus", "westeurope", "uksouth"], lower(var.location))
    error_message = "location must be a supported Azure region for this landing zone configuration."
  }
}

variable "tags" {
  description = "Default tags applied to all resource groups. Use a consistent tagging strategy for ownership, environment, and cost allocation."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings."
  }
}

variable "resource_groups" {
  description = "Map of resource groups to create. Names should align with the Enterprise naming convention and be valid Azure resource group names."
  type = map(object({
    name = string
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, rg in var.resource_groups : length(trimspace(rg.name)) > 0 && can(regex("^[A-Za-z0-9-_.]+$", rg.name))
    ])
    error_message = "Each resource group name must be non-empty and valid for Azure resource naming."
  }
}
