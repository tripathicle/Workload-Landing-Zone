variable "location" {
  description = "Azure region for all virtual networks and subnets."

  type = string

  validation {
    condition = contains(
      [
        "japaneast",
        "eastus",
        "eastus2",
        "centralus",
        "westeurope",
        "uksouth"
      ],
      lower(trimspace(var.location))
    )

    error_message = "location must be one of the supported Azure regions."
  }
}

variable "vnets" {
  description = "Map of virtual networks and their subnet configurations."

  type = map(object({
    name                = string
    resource_group_name = string
    address_space       = list(string)

    subnets = map(object({
      name                                          = string
      address_prefixes                              = list(string)
      service_endpoints                             = optional(list(string), [])
      private_endpoint_network_policies             = optional(string, "Disabled")
      private_link_service_network_policies_enabled = optional(bool, true)
    }))

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      length(trimspace(vnet.name)) > 0 &&
      length(trimspace(vnet.resource_group_name)) > 0 &&
      length(vnet.address_space) > 0 &&
      alltrue([
        for cidr in vnet.address_space :
        can(cidrhost(cidr, 0))
      ]) &&
      length(vnet.subnets) > 0
    ])

    error_message = "Each VNet must define a non-empty name, resource group, at least one valid CIDR address space, and at least one subnet."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      alltrue([
        for subnet_key, subnet in vnet.subnets :
        length(trimspace(subnet.name)) > 0 &&
        length(subnet.address_prefixes) > 0 &&
        alltrue([
          for cidr in subnet.address_prefixes :
          can(cidrhost(cidr, 0))
        ])
      ])
    ])

    error_message = "Each subnet must define a non-empty name and at least one valid CIDR address prefix."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      alltrue([
        for subnet_key, subnet in vnet.subnets :
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
    ])

    error_message = "private_endpoint_network_policies must be Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
}

variable "tags" {
  description = "Default tags applied to all virtual networks and subnets."

  type    = map(string)
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