variable "application_gateways" {
  description = "Map of Azure Application Gateways to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string
    public_ip_key      = string

    sku = object({
      name     = string
      tier     = string
      capacity = optional(number)
    })

    frontend_ip_configuration_name = string
    frontend_port_name             = string
    frontend_port                  = number

    gateway_ip_configuration_name = string

    http_listener_name = string

    waf_policy = optional(object({
      enabled          = optional(bool, true)
      firewall_mode    = optional(string, "Prevention")
      rule_set_type    = optional(string, "OWASP")
      rule_set_version = optional(string, "3.2")
    }), null)

    frontend_backend = object({
      name               = string
      ip_addresses       = list(string)
      http_settings_name = string
      http_settings_port = number
      probe_name         = string
      probe_path         = string
    })

    backend_backend = object({
      name               = string
      ip_addresses       = list(string)
      http_settings_name = string
      http_settings_port = number
      probe_name         = string
      probe_path         = string
    })

    path_map_name = string

    path_rules = list(object({
      name                       = string
      paths                      = list(string)
      backend_address_pool_name  = string
      backend_http_settings_name = string
    }))

    default_backend_address_pool_name  = string
    default_backend_http_settings_name = string

    request_routing_rule_name     = string
    request_routing_rule_priority = number
  }))

  validation {
    condition     = length(var.application_gateways) > 0
    error_message = "At least one Application Gateway must be defined."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      gateway.sku.name == "WAF_v2" &&
      gateway.sku.tier == "WAF_v2"
    ])

    error_message = "All Application Gateways must use the WAF_v2 SKU and tier."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      gateway.frontend_port >= 1 &&
      gateway.frontend_port <= 65535
    ])

    error_message = "Application Gateway frontend port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      gateway.waf_policy == null ||
      gateway.waf_policy.enabled
    ])

    error_message = "When a WAF policy is configured, it must be enabled."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      gateway.waf_policy == null ||
      gateway.waf_policy.firewall_mode == "Prevention"
    ])

    error_message = "Application Gateway WAF firewall mode must be Prevention."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      gateway.waf_policy == null ||
      gateway.waf_policy.rule_set_type == "OWASP"
    ])

    error_message = "Application Gateway WAF rule set type must be OWASP."
  }

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      gateway.waf_policy == null ||
      gateway.waf_policy.rule_set_version == "3.2"
    ])

    error_message = "Application Gateway WAF rule set version must be 3.2."
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
    condition     = length(var.resource_groups) > 0
    error_message = "At least one Resource Group must be available to the Gateway module."
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
    error_message = "At least one subnet must be available to the Gateway module."
  }
}

variable "public_ips" {
  description = "Public IPs created by the Public IP module."

  type = map(object({
    id                  = string
    name                = string
    ip_address          = string
    resource_group_name = string
    location            = string
    sku                 = string
    allocation_method   = string
  }))

  validation {
    condition     = length(var.public_ips) > 0
    error_message = "At least one Public IP must be available to the Gateway module."
  }
}

variable "tags" {
  description = "Common tags applied to Application Gateways and WAF policies."

  type    = map(string)
  default = {}
}