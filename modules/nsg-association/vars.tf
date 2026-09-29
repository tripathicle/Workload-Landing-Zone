variable "nsg_associations" {
  description = "Map of Network Security Group to Subnet associations."

  type = map(object({
    nsg_key    = string
    subnet_key = string
  }))

  validation {
    condition     = length(var.nsg_associations) > 0
    error_message = "At least one NSG association must be defined."
  }

  validation {
    condition = alltrue([
      for association_key, association in var.nsg_associations :
      length(trimspace(association_key)) > 0
    ])
    error_message = "Each NSG association map key must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for association_key, association in var.nsg_associations :
      length(trimspace(association.nsg_key)) > 0 &&
      length(trimspace(association.subnet_key)) > 0
    ])
    error_message = "Each NSG association must define non-empty nsg_key and subnet_key values."
  }
}

variable "network_security_groups" {
  description = "Network Security Groups created by the NSG module."

  type = map(object({
    id                  = string
    name                = string
    resource_group_name = string
    location            = string
  }))

  validation {
    condition     = length(var.network_security_groups) > 0
    error_message = "At least one Network Security Group must be available."
  }
}

variable "subnets" {
  description = "Subnets created by the Subnet module."

  type = map(object({
    id               = string
    name             = string
    address_prefixes = list(string)
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be available."
  }
}