variable "subnets" {
  description = "Map of Azure Subnets to provision."

  type = map(object({
    name             = string
    vnet_key         = string
    address_prefixes = list(string)

    private_endpoint_network_policies = optional(
      string,
      "Disabled"
    )

    private_link_service_network_policies_enabled = optional(
      bool,
      true
    )
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }

  validation {
    condition = alltrue([
      for subnet_key in keys(var.subnets) :
      length(trimspace(subnet_key)) > 0
    ])

    error_message = "Each subnet map key must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      length(trimspace(subnet.name)) > 0
    ])

    error_message = "Each subnet must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      length(trimspace(subnet.vnet_key)) > 0
    ])

    error_message = "Each subnet must define a non-empty vnet_key."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      length(subnet.address_prefixes) > 0
    ])

    error_message = "Each subnet must define at least one address prefix."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      alltrue([
        for cidr in subnet.address_prefixes :
        can(cidrhost(cidr, 0))
      ])
    ])

    error_message = "Each subnet address prefix must be a valid CIDR."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      contains(
        [
          "Disabled",
          "Enabled",
          "NetworkSecurityGroupEnabled",
          "RouteTableEnabled"
        ],
        subnet.private_endpoint_network_policies
      )
    ])

    error_message = "private_endpoint_network_policies must be a supported Azure value."
  }
}

variable "vnets" {
  description = "Virtual Networks created by the VNet module."

  type = map(object({
    id                  = string
    name                = string
    resource_group_name = string
    location            = string
    address_space       = list(string)
  }))

  validation {
    condition     = length(var.vnets) > 0
    error_message = "At least one VNet must be available to the subnet module."
  }
}