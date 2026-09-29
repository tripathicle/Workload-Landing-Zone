variable "load_balancers" {
  description = "Map of Azure Load Balancers to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string

    frontend_ip_configuration_name = string
    private_ip_address             = string

    sku = optional(string, "Standard")

    backend_pool_name = string

    health_probe = object({
      name                = string
      protocol            = string
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
    })

    load_balancing_rule = object({
      name                    = string
      protocol                = string
      frontend_port           = number
      backend_port            = number
      idle_timeout_in_minutes = optional(number, 4)
    })
  }))

  validation {
    condition     = length(var.load_balancers) > 0
    error_message = "At least one Load Balancer must be defined."
  }

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      length(trimspace(lb.name)) > 0
    ])
    error_message = "Each Load Balancer must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      length(trimspace(lb.resource_group_key)) > 0
    ])
    error_message = "Each Load Balancer must define a resource_group_key."
  }

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      length(trimspace(lb.subnet_key)) > 0
    ])
    error_message = "Each Load Balancer must define a subnet_key."
  }

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      lb.sku == "Standard"
    ])
    error_message = "All Load Balancers must use the Standard SKU."
  }

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      can(
        regex(
          "^([0-9]{1,3}\\.){3}[0-9]{1,3}$",
          lb.private_ip_address
        )
      )
    ])
    error_message = "Each Load Balancer must define a valid IPv4 private IP address."
  }

  validation {
    condition = alltrue([
      for lb_key, lb in var.load_balancers :
      lb.load_balancing_rule.frontend_port >= 1 &&
      lb.load_balancing_rule.frontend_port <= 65535 &&
      lb.load_balancing_rule.backend_port >= 1 &&
      lb.load_balancing_rule.backend_port <= 65535
    ])
    error_message = "Load Balancer frontend and backend ports must be between 1 and 65535."
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
    error_message = "At least one Resource Group must be available to the Load Balancer module."
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
    error_message = "At least one subnet must be available to the Load Balancer module."
  }
}

variable "tags" {
  description = "Common tags applied to Load Balancers."

  type    = map(string)
  default = {}
}