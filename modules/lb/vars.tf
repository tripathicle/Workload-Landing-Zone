# ============================================================
# LOAD BALANCER VARIABLES
# ============================================================

variable "load_balancers" {
  description = "Internal Load Balancer configuration."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = string

    frontend_ip_configuration = object({
      name               = string
      subnet_id          = string
      vnet_id            = string
      private_ip_address = string
    })

    backend_address_pool = object({
      name         = string
      ip_addresses = list(string)
    })

    health_probe = object({
      name                = string
      protocol            = string
      port                = number
      request_path        = string
      interval_in_seconds = number
      number_of_probes    = number
    })

    lb_rule = object({
      name                    = string
      protocol                = string
      frontend_port           = number
      backend_port            = number
      floating_ip_enabled     = bool
      idle_timeout_in_minutes = number
      tcp_reset_enabled       = bool
    })

    tags = map(string)
  }))

  # ----------------------------------------------------------
  # SKU
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Basic", "Standard"],
        lb.sku
      )
    ])

    error_message = "Load Balancer SKU must be either Basic or Standard."
  }

  # ----------------------------------------------------------
  # RULE PROTOCOL
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Tcp", "Udp"],
        lb.lb_rule.protocol
      )
    ])

    error_message = "Load Balancer rule protocol must be Tcp or Udp."
  }

  # ----------------------------------------------------------
  # PROBE PROTOCOL
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(
        ["Http", "Https", "Tcp"],
        lb.health_probe.protocol
      )
    ])

    error_message = "Health probe protocol must be Http, Https, or Tcp."
  }

  # ----------------------------------------------------------
  # PRIVATE IP
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.frontend_ip_configuration.private_ip_address != ""
    ])

    error_message = "Every Load Balancer must have a private frontend IP address."
  }
}

# ============================================================
# DEFAULT TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to all Load Balancers."

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