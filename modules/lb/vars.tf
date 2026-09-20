variable "load_balancers" {
  description = "Map of internal load balancers for the backend tier. All health checks and ports must be explicitly defined for operational reliability."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Standard")
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
      name     = string
      protocol = optional(string, "Tcp")
      port     = number
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
      for key, lb in var.load_balancers : length(trimspace(lb.name)) > 0 && length(trimspace(lb.frontend_ip_configuration.subnet_id)) > 0 && lb.health_probe.port >= 1 && lb.health_probe.port <= 65535 && lb.lb_rule.frontend_port >= 1 && lb.lb_rule.frontend_port <= 65535 && lb.lb_rule.backend_port >= 1 && lb.lb_rule.backend_port <= 65535
    ])
    error_message = "Each load balancer must have a valid name, subnet ID, and valid TCP port values for health probes and load balancing rules."
  }
}

variable "tags" {
  description = "Default tags applied to load balancer resources. Use a standard ownership and environment tag set."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings."
  }
}
