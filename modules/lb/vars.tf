# ============================================================
# INTERNAL LOAD BALANCER CONFIGURATION
# ============================================================

variable "load_balancers" {
  description = "Map of internal Azure Load Balancers."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku = optional(string, "Standard")

    frontend_ip_configuration = object({
      name                 = string
      subnet_id            = string
      private_ip_address   = string
      private_ip_addresses = optional(list(string), [])
    })

    backend_address_pool = object({
      name         = string
      ip_addresses = optional(list(string), [])
    })

    health_probe = object({
      name                = string
      protocol            = optional(string, "Http")
      port                = number
      request_path        = optional(string, "/health")
      interval_in_seconds = optional(number, 30)
      number_of_probes    = optional(number, 2)
    })

    lb_rule = object({
      name                           = string
      frontend_ip_configuration_name = string
      backend_address_pool_name      = string
      frontend_port                  = number
      backend_port                   = number
      protocol                       = optional(string, "Tcp")
      load_distribution              = optional(string, "Default")
    })

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      length(trimspace(lb.name)) > 0 &&
      length(trimspace(lb.resource_group_name)) > 0 &&
      length(trimspace(lb.location)) > 0 &&
      length(trimspace(lb.frontend_ip_configuration.name)) > 0 &&
      length(trimspace(lb.frontend_ip_configuration.subnet_id)) > 0 &&
      length(trimspace(lb.frontend_ip_configuration.private_ip_address)) > 0 &&
      length(trimspace(lb.backend_address_pool.name)) > 0 &&
      length(trimspace(lb.health_probe.name)) > 0 &&
      length(trimspace(lb.lb_rule.name)) > 0 &&
      length(trimspace(lb.lb_rule.frontend_ip_configuration_name)) > 0 &&
      length(trimspace(lb.lb_rule.backend_address_pool_name)) > 0
    ])

    error_message = "Each load balancer must define valid names, resource group, location, frontend IP configuration, backend pool, health probe, and load balancing rule configuration."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Basic", "Standard"],
        lb.sku
      )
    ])

    error_message = "Load balancer SKU must be either Basic or Standard."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Tcp", "Http", "Https"],
        lb.health_probe.protocol
      )
    ])

    error_message = "Load balancer health probe protocol must be Tcp, Http, or Https."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.health_probe.port >= 1 &&
      lb.health_probe.port <= 65535
    ])

    error_message = "Load balancer health probe port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.health_probe.interval_in_seconds >= 5 &&
      lb.health_probe.interval_in_seconds <= 120
    ])

    error_message = "Health probe interval must be between 5 and 120 seconds."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.health_probe.number_of_probes >= 1 &&
      lb.health_probe.number_of_probes <= 20
    ])

    error_message = "Health probe number_of_probes must be between 1 and 20."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.lb_rule.frontend_port >= 1 &&
      lb.lb_rule.frontend_port <= 65535 &&
      lb.lb_rule.backend_port >= 1 &&
      lb.lb_rule.backend_port <= 65535
    ])

    error_message = "Load balancing rule frontend and backend ports must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Tcp", "Udp", "All"],
        lb.lb_rule.protocol
      )
    ])

    error_message = "Load balancing rule protocol must be Tcp, Udp, or All."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Default", "SourceIP", "SourceIPProtocol"],
        lb.lb_rule.load_distribution
      )
    ])

    error_message = "Load distribution must be Default, SourceIP, or SourceIPProtocol."
  }
}


# ============================================================
# DEFAULT TAGS
# ============================================================

variable "tags" {
  description = "Default tags applied to load balancer resources."

  type = map(string)

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