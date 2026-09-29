variable "vnet_peerings" {
  description = "Map of Azure Virtual Network Peerings to provision."

  type = map(object({
    name            = string
    source_vnet_key = string
    remote_vnet_key = string

    allow_virtual_network_access = optional(bool, true)
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  }))

  validation {
    condition     = length(var.vnet_peerings) > 0
    error_message = "At least one VNet peering must be defined."
  }

  validation {
    condition = alltrue([
      for peering_key in keys(var.vnet_peerings) :
      length(trimspace(peering_key)) > 0
    ])

    error_message = "Each VNet peering map key must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for peering_key, peering in var.vnet_peerings :
      length(trimspace(peering.name)) > 0
    ])

    error_message = "Each VNet peering must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for peering_key, peering in var.vnet_peerings :
      length(trimspace(peering.source_vnet_key)) > 0 &&
      length(trimspace(peering.remote_vnet_key)) > 0
    ])

    error_message = "Each VNet peering must define source_vnet_key and remote_vnet_key."
  }

  validation {
    condition = alltrue([
      for peering_key, peering in var.vnet_peerings :
      peering.source_vnet_key != peering.remote_vnet_key
    ])

    error_message = "A VNet cannot be peered with itself."
  }
}

variable "vnets" {
  description = "Virtual Networks created by the Virtual Network module."

  type = map(object({
    id                  = string
    name                = string
    resource_group_name = string
    location            = string
    address_space       = list(string)
  }))

  validation {
    condition     = length(var.vnets) > 0
    error_message = "At least one VNet must be available to the VNet peering module."
  }
}