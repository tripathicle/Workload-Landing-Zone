variable "private_dns_zones" {
  description = "Map of Private DNS zones and their target virtual network keys."

  type = map(object({
    name                = string
    resource_group_name = string
    virtual_network_id  = string
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, zone in var.private_dns_zones :
      length(trimspace(zone.name)) > 0 &&
      length(trimspace(zone.resource_group_name)) > 0 &&
      length(trimspace(zone.virtual_network_id)) > 0
    ])

    error_message = "Each Private DNS zone must define a non-empty name, resource group name, and virtual network ID."
  }
}

variable "private_endpoints" {
  description = "Map of Private Endpoints."

  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    subnet_id           = string

    private_service_connection = object({
      name                           = string
      private_connection_resource_id = string
      is_manual_connection           = optional(bool, false)
      subresource_names              = list(string)
      request_message                = optional(string, null)
    })

    private_dns_zone_key = optional(string, null)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, endpoint in var.private_endpoints :
      length(trimspace(endpoint.name)) > 0 &&
      length(trimspace(endpoint.location)) > 0 &&
      length(trimspace(endpoint.resource_group_name)) > 0 &&
      length(trimspace(endpoint.subnet_id)) > 0 &&
      length(trimspace(endpoint.private_service_connection.name)) > 0 &&
      length(trimspace(endpoint.private_service_connection.private_connection_resource_id)) > 0 &&
      length(endpoint.private_service_connection.subresource_names) > 0
    ])

    error_message = "Each Private Endpoint must define name, location, resource group, subnet, service connection, resource ID, and at least one subresource."
  }
}

variable "tags" {
  description = "Default tags applied to private access resources."

  type    = map(string)
  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be non-empty."
  }
}