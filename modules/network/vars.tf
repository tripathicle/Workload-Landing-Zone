variable "location" {
  description = "Azure region for the virtual networks. Region must align with the landing zone deployment."
  type        = string

  validation {
    condition     = contains(["japaneast", "eastus", "eastus2", "centralus", "westeurope", "uksouth"], lower(var.location))
    error_message = "location must be a supported Azure region for this landing zone."
  }
}

variable "vnets" {
  description = "Map of virtual networks to create in the Azure landing zone. CIDR blocks must be valid private RFC1918 ranges."
  type = map(object({
    name                = string
    resource_group_name = string
    address_space       = list(string)
    subnets = map(object({
      name             = string
      address_prefixes = list(string)
      service_endpoints = optional(list(string), [])
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, vnet in var.vnets : length(vnet.address_space) > 0 && alltrue([for cidr in vnet.address_space : can(cidrhost(cidr, 0))]) && length(vnet.subnets) > 0
    ])
    error_message = "Each VNet must define at least one valid CIDR and at least one subnet."
  }
}

variable "tags" {
  description = "Default tags to apply to all virtual networks. Keep environments and ownership metadata consistent."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings."
  }
}
