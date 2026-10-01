# ============================================================
# MODULE: VIRTUAL NETWORK
# FILE: modules/virtual_network/variables.tf
# ============================================================

variable "vnets" {
  description = "Map of Azure Virtual Networks to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    address_space      = list(string)
    dns_servers        = optional(list(string), [])
    tags               = optional(map(string), {})
  }))

  validation {
    condition = length(var.vnets) > 0

    error_message = "At least one virtual network must be defined."
  }

  validation {
    condition = alltrue([
      for vnet_key in keys(var.vnets) :
      length(trimspace(vnet_key)) > 0
    ])

    error_message = "Each VNet map key must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      length(trimspace(vnet.name)) > 0
    ])

    error_message = "Each VNet must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      can(regex(
        "^[A-Za-z0-9._()\\-]+$",
        vnet.name
      ))
    ])

    error_message = "Each VNet name contains unsupported characters."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      length(trimspace(vnet.resource_group_key)) > 0
    ])

    error_message = "Each VNet must define a non-empty resource_group_key."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      length(vnet.address_space) > 0
    ])

    error_message = "Each VNet must define at least one address space."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      alltrue([
        for cidr in vnet.address_space :
        can(cidrhost(cidr, 0))
      ])
    ])

    error_message = "Each VNet address_space entry must be a valid CIDR."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      alltrue([
        for dns_server in vnet.dns_servers :
        can(cidrhost(dns_server, 0))
      ])
    ])

    error_message = "Each VNet DNS server must be a valid IP address."
  }
}

variable "resource_groups" {
  description = "Resource Groups created by the Resource Group module."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))

  validation {
    condition = length(var.resource_groups) > 0

    error_message = "At least one resource group must be available to the VNet module."
  }
}

variable "tags" {
  description = "Common tags applied to all Virtual Networks."

  type    = map(string)
  default = {}

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      length(trimspace(tag_key)) > 0 &&
      length(trimspace(tag_value)) > 0
    ])

    error_message = "Each common tag key and value must be non-empty."
  }

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      can(regex(
        "^[A-Za-z0-9_.:/+=@\\- ]+$",
        tag_key
      ))
    ])

    error_message = "Common tag keys contain unsupported characters."
  }
}