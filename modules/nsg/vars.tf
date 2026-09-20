variable "network_security_groups" {
  description = "Map of NSGs for the landing zone. Rules must be explicit, ordered, and least-privilege by design."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    security_rules = map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, nsg in var.network_security_groups : length(trimspace(nsg.name)) > 0 && alltrue([
        for rule_key, rule in nsg.security_rules : rule.priority >= 100 && rule.priority <= 4096 && contains(["Inbound", "Outbound"], rule.direction) && contains(["Allow", "Deny"], rule.access)
      ])
    ])
    error_message = "Each NSG name must be non-empty, and every rule must have a valid priority, direction, and access value."
  }
}

variable "tags" {
  description = "Default tags to apply to all NSGs. Keep naming and ownership metadata consistent."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings."
  }
}
