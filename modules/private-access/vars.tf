variable "private_dns_zones" {
  description = "Private DNS zones for future private endpoint integrations"
  type = map(object({
    name                = string
    resource_group_name = string
    virtual_network_id  = optional(string, null)
    tags                = optional(map(string), {})
  }))
}

variable "private_endpoints" {
  description = "Private endpoints for future Azure SQL and PaaS access"
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
    private_dns_zone_group = optional(object({
      name                 = string
      private_dns_zone_ids = list(string)
    }), null)
    tags = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to private access resources"
  type        = map(string)
  default     = {}
}
