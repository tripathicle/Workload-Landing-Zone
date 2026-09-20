variable "application_gateways" {
  description = "Map of Application Gateway objects"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku = object({
      name     = string
      tier     = string
      capacity = number
    })
    gateway_ip_configuration = object({
      name      = string
      subnet_id = string
    })
    frontend_ip_configuration = object({
      name                 = string
      public_ip_address_id = string
    })
    frontend_port = object({
      name = string
      port = number
    })
    http_listener = object({
      name                           = string
      frontend_ip_configuration_name = string
      frontend_port_name             = string
      protocol                       = string
    })
    request_routing_rule = object({
      name                       = string
      rule_type                 = string
      http_listener_name        = string
      backend_address_pool_name = string
      backend_http_settings_name = string
    })
    backend_address_pool = object({
      name         = string
      ip_addresses = optional(list(string), [])
    })
    health_probe = optional(object({
      name     = string
      protocol = optional(string, "Http")
      port     = number
      path     = optional(string, "/")
    }), null)
    backend_http_settings = object({
      name                  = string
      cookie_based_affinity = string
      port                  = number
      protocol              = string
      request_timeout       = number
    })
    tags = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to application gateway resources"
  type        = map(string)
  default     = {}
}
