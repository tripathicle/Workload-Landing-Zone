# ============================================================
# APPLICATION GATEWAY VARIABLES
# ============================================================

variable "application_gateways" {
  description = "Map of Azure Application Gateway resources."

  type = map(object({

    name                = string
    resource_group_name = string
    location            = string

    # --------------------------------------------------------
    # SKU
    # --------------------------------------------------------

    sku = object({
      name     = string
      tier     = string
      capacity = number
    })

    # --------------------------------------------------------
    # WAF
    # --------------------------------------------------------

    waf_configuration = optional(object({
      enabled                  = optional(bool, true)
      firewall_mode            = optional(string, "Prevention")
      rule_set_type            = optional(string, "OWASP")
      rule_set_version         = optional(string, "3.2")
      file_upload_limit_mb     = optional(number, 100)
      request_body_check       = optional(bool, true)
      max_request_body_size_kb = optional(number, 128)
    }), null)

    # --------------------------------------------------------
    # GATEWAY IP
    # --------------------------------------------------------

    gateway_ip_configuration = object({
      name      = string
      subnet_id = string
    })

    # --------------------------------------------------------
    # FRONTEND IP
    # --------------------------------------------------------

    frontend_ip_configuration = object({
      name                 = string
      public_ip_address_id = string
    })

    # --------------------------------------------------------
    # FRONTEND PORT
    # --------------------------------------------------------

    frontend_port = object({
      name = string
      port = number
    })

    # --------------------------------------------------------
    # HTTP LISTENER
    # --------------------------------------------------------

    http_listener = object({
      name                           = string
      frontend_ip_configuration_name = string
      frontend_port_name             = string
      protocol                       = string
    })

    # --------------------------------------------------------
    # BACKEND ADDRESS POOLS
    # --------------------------------------------------------

    backend_address_pools = map(object({
      ip_addresses = optional(list(string), [])
    }))

    # --------------------------------------------------------
    # HEALTH PROBES
    # --------------------------------------------------------

    health_probes = map(object({
      name                = string
      protocol            = string
      port                = number
      path                = string
      interval            = number
      timeout             = number
      unhealthy_threshold = number
    }))

    # --------------------------------------------------------
    # BACKEND HTTP SETTINGS
    # --------------------------------------------------------

    backend_http_settings = map(object({
      name                  = string
      cookie_based_affinity = string
      port                  = number
      protocol              = string
      request_timeout       = number
      probe_name            = string
    }))

    # --------------------------------------------------------
    # REQUEST ROUTING
    # --------------------------------------------------------

    request_routing_rule = object({
      name               = string
      priority           = number
      rule_type          = string
      http_listener_name = string

      url_path_map_name = string

      default_backend_address_pool_name  = string
      default_backend_http_settings_name = string

      path_rules = list(object({
        name                       = string
        paths                      = list(string)
        backend_address_pool_name  = string
        backend_http_settings_name = string
      }))
    })

    # --------------------------------------------------------
    # TAGS
    # --------------------------------------------------------

    tags = optional(map(string), {})
  }))

  # ==========================================================
  # RESOURCE VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      length(trimspace(gateway.name)) > 0 &&
      length(trimspace(gateway.resource_group_name)) > 0 &&
      length(trimspace(gateway.location)) > 0 &&
      length(trimspace(gateway.gateway_ip_configuration.name)) > 0 &&
      length(trimspace(gateway.gateway_ip_configuration.subnet_id)) > 0 &&
      length(trimspace(gateway.frontend_ip_configuration.name)) > 0 &&
      length(trimspace(gateway.frontend_ip_configuration.public_ip_address_id)) > 0
    ])

    error_message = "Each Application Gateway must define valid name, resource group, location, gateway subnet, frontend IP configuration, and public IP ID."
  }

  # ==========================================================
  # SKU VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      contains(
        ["Standard_v2", "WAF_v2"],
        gateway.sku.name
      ) &&
      contains(
        ["Standard_v2", "WAF_v2"],
        gateway.sku.tier
      ) &&
      gateway.sku.capacity >= 1 &&
      gateway.sku.capacity <= 125
    ])

    error_message = "Application Gateway must use Standard_v2 or WAF_v2 with capacity between 1 and 125."
  }

  # ==========================================================
  # WAF VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.waf_configuration == null ||
      (
        contains(
          ["Detection", "Prevention"],
          gateway.waf_configuration.firewall_mode
        ) &&
        gateway.waf_configuration.rule_set_type == "OWASP" &&
        gateway.waf_configuration.file_upload_limit_mb >= 1 &&
        gateway.waf_configuration.file_upload_limit_mb <= 750 &&
        gateway.waf_configuration.max_request_body_size_kb >= 8 &&
        gateway.waf_configuration.max_request_body_size_kb <= 128
      )
    ])

    error_message = "WAF configuration must use OWASP rules, Detection or Prevention mode, valid upload limits, and valid request body size."
  }

  # ==========================================================
  # FRONTEND PORT VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.frontend_port.port >= 1 &&
      gateway.frontend_port.port <= 65535
    ])

    error_message = "Application Gateway frontend port must be between 1 and 65535."
  }

  # ==========================================================
  # HEALTH PROBE VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      alltrue([
        for probe_key, probe in gateway.health_probes :
        probe.port >= 1 &&
        probe.port <= 65535 &&
        probe.interval >= 1 &&
        probe.timeout >= 1 &&
        probe.unhealthy_threshold >= 1
      ])
    ])

    error_message = "Application Gateway health probes must contain valid port, interval, timeout, and unhealthy threshold values."
  }

  # ==========================================================
  # BACKEND HTTP SETTINGS VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      alltrue([
        for settings_key, settings in gateway.backend_http_settings :
        settings.port >= 1 &&
        settings.port <= 65535 &&
        settings.request_timeout >= 1 &&
        settings.request_timeout <= 86400
      ])
    ])

    error_message = "Application Gateway backend HTTP settings must contain valid port and request timeout values."
  }

  # ==========================================================
  # ROUTING RULE VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.request_routing_rule.priority >= 1 &&
      gateway.request_routing_rule.priority <= 20000 &&
      gateway.request_routing_rule.rule_type == "PathBasedRouting"
    ])

    error_message = "Application Gateway routing rule must use PathBasedRouting and priority must be between 1 and 20000."
  }
}

# ============================================================
# DEFAULT TAGS
# ============================================================

variable "tags" {
  description = "Default tags applied to Application Gateway resources."

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