variable "public_ips" {
  description = "Map of Azure Public IP addresses to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    allocation_method  = optional(string, "Static")
    sku                = optional(string, "Standard")
    tags               = optional(map(string), {})
  }))

  validation {
    condition     = length(var.public_ips) > 0
    error_message = "At least one public IP must be defined."
  }

  validation {
    condition = alltrue([
      for public_ip_key in keys(var.public_ips) :
      length(trimspace(public_ip_key)) > 0
    ])

    error_message = "Each public IP map key must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for public_ip_key, public_ip in var.public_ips :
      length(trimspace(public_ip.name)) > 0
    ])

    error_message = "Each public IP must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for public_ip_key, public_ip in var.public_ips :
      length(trimspace(public_ip.resource_group_key)) > 0
    ])

    error_message = "Each public IP must define a non-empty resource_group_key."
  }

  validation {
    condition = alltrue([
      for public_ip_key, public_ip in var.public_ips :
      public_ip.allocation_method == "Static"
    ])

    error_message = "All public IP addresses must use Static allocation."
  }

  validation {
    condition = alltrue([
      for public_ip_key, public_ip in var.public_ips :
      public_ip.sku == "Standard"
    ])

    error_message = "All public IP addresses must use the Standard SKU."
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
    error_message = "At least one resource group must be available to the public IP module."
  }
}

variable "tags" {
  description = "Common tags applied to all Public IP addresses."

  type    = map(string)
  default = {}
}