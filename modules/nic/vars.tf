variable "network_interfaces" {
  description = "Map of Azure Network Interfaces to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string

    ip_configuration = object({
      name                          = string
      private_ip_address_allocation = optional(string, "Static")
      private_ip_address            = optional(string)
    })

    enable_accelerated_networking = optional(bool, false)

    load_balancer_backend_pool_key = optional(string)
  }))

  validation {
    condition     = length(var.network_interfaces) > 0
    error_message = "At least one Network Interface must be defined."
  }

  validation {
    condition = alltrue([
      for nic_key, nic in var.network_interfaces :
      length(trimspace(nic.name)) > 0
    ])

    error_message = "Each Network Interface must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for nic_key, nic in var.network_interfaces :
      length(trimspace(nic.resource_group_key)) > 0
    ])

    error_message = "Each Network Interface must define a resource_group_key."
  }

  validation {
    condition = alltrue([
      for nic_key, nic in var.network_interfaces :
      length(trimspace(nic.subnet_key)) > 0
    ])

    error_message = "Each Network Interface must define a subnet_key."
  }

  validation {
    condition = alltrue([
      for nic_key, nic in var.network_interfaces :
      nic.ip_configuration.private_ip_address_allocation == "Static"
    ])

    error_message = "All workload NICs must use Static private IP allocation."
  }

  validation {
    condition = alltrue([
      for nic_key, nic in var.network_interfaces :
      nic.ip_configuration.private_ip_address != null &&
      length(trimspace(nic.ip_configuration.private_ip_address)) > 0
    ])

    error_message = "Each workload NIC must define a private IP address."
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
    error_message = "At least one Resource Group must be available to the NIC module."
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
    error_message = "At least one subnet must be available to the NIC module."
  }
}

variable "backend_address_pools" {
  description = "Load Balancer backend address pools available for NIC association."

  type = map(object({
    id   = string
    name = string
  }))

  default = {}
}

variable "tags" {
  description = "Common tags applied to Network Interfaces."

  type    = map(string)
  default = {}
}