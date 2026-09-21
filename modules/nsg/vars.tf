# ============================================================
# Network Security Group Input
# ============================================================
# CHANGE:
# - Added validation for required NSG attributes.
# - Added validation for rule priority.
# - Added validation for direction and access.
# - Added validation for protocol.
# - Kept ports/address prefixes flexible because Azure NSG
#   supports values such as "*", individual ports, ranges,
#   CIDRs, and service tags.
# ============================================================

variable "network_security_groups" {
  description = "Map of Azure Network Security Groups and their security rules."

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
      for key, nsg in var.network_security_groups :
      length(trimspace(nsg.name)) > 0 &&
      length(trimspace(nsg.resource_group_name)) > 0 &&
      length(trimspace(nsg.location)) > 0
    ])

    error_message = "Each NSG must have a non-empty name, resource group name, and location."
  }

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      alltrue([
        for rule_key, rule in nsg.security_rules :
        length(trimspace(rule.name)) > 0 &&
        rule.priority >= 100 &&
        rule.priority <= 4096 &&
        contains(
          ["Inbound", "Outbound"],
          rule.direction
        ) &&
        contains(
          ["Allow", "Deny"],
          rule.access
        ) &&
        contains(
          ["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"],
          rule.protocol
        )
      ])
    ])

    error_message = "Each NSG rule must have a non-empty name, priority between 100 and 4096, valid direction (Inbound/Outbound), valid access (Allow/Deny), and a supported protocol (Tcp/Udp/Icmp/Esp/Ah/*)."
  }
}


# ============================================================
# Common Tags
# ============================================================
# CHANGE:
# - Common tags remain controlled by the environment/root module.
# - Individual NSGs can override/add resource-specific tags.
# ============================================================

variable "tags" {
  description = "Default tags applied to all network security groups."

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