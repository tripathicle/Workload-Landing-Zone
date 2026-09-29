variable "private_endpoints" {
  description = "Map of Azure Private Endpoints to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string

    private_service_connection = object({
      name                           = string
      private_connection_resource_id = string
      subresource_names              = list(string)
      is_manual_connection           = bool
    })

    private_dns_zone_group = optional(object({
      name         = string
      dns_zone_key = string
    }))
  }))

  validation {
    condition = length(var.private_endpoints) > 0

    error_message = "At least one Private Endpoint must be defined."
  }

  validation {
    condition = alltrue([
      for pe_key, pe in var.private_endpoints :
      length(trimspace(pe.name)) > 0
    ])

    error_message = "Each Private Endpoint must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for pe_key, pe in var.private_endpoints :
      length(trimspace(pe.resource_group_key)) > 0 &&
      length(trimspace(pe.subnet_key)) > 0
    ])

    error_message = "Each Private Endpoint must define valid resource group and subnet keys."
  }

  validation {
    condition = alltrue([
      for pe_key, pe in var.private_endpoints :
      length(pe.private_service_connection.subresource_names) > 0
    ])

    error_message = "Each Private Endpoint must define at least one subresource name."
  }
}


variable "private_dns_zones" {
  description = "Private DNS Zones required for private Azure services."

  type = map(object({
    name               = string
    resource_group_key = string
  }))

  validation {
    condition = length(var.private_dns_zones) > 0

    error_message = "At least one Private DNS Zone must be defined."
  }

  validation {
    condition = alltrue([
      for zone_key, zone in var.private_dns_zones :
      length(trimspace(zone.name)) > 0
    ])

    error_message = "Each Private DNS Zone must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for zone_key, zone in var.private_dns_zones :
      length(trimspace(zone.resource_group_key)) > 0
    ])

    error_message = "Each Private DNS Zone must define a Resource Group key."
  }
}


variable "private_dns_zone_vnet_links" {
  description = "Private DNS Zone to Virtual Network links."

  type = map(object({
    dns_zone_key = string
    vnet_key     = string
    registration = optional(bool, false)
  }))

  validation {
    condition = length(var.private_dns_zone_vnet_links) > 0

    error_message = "At least one Private DNS Zone VNet link must be defined."
  }

  validation {
    condition = alltrue([
      for link_key, link in var.private_dns_zone_vnet_links :
      length(trimspace(link.dns_zone_key)) > 0 &&
      length(trimspace(link.vnet_key)) > 0
    ])

    error_message = "Each Private DNS Zone VNet link must define valid DNS Zone and VNet keys."
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

    error_message = "At least one Resource Group must be available."
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
    condition = length(var.subnets) > 0

    error_message = "At least one subnet must be available."
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
    condition = length(var.vnets) > 0

    error_message = "At least one VNet must be available."
  }
}


variable "tags" {
  description = "Common tags applied to Private Access resources."

  type = map(string)

  default = {}
}