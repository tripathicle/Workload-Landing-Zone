variable "network_security_groups" {
  description = "Map of Azure Network Security Groups to provision."

  type = map(object({
    name               = string
    resource_group_key = string

    security_rules = optional(map(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      destination_port_range       = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      destination_address_prefix   = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    })), {})
  }))

  # ------------------------------------------------------------
  # NSG map must not be empty
  # ------------------------------------------------------------

  validation {
    condition = length(var.network_security_groups) > 0

    error_message = "At least one Network Security Group must be defined."
  }

  # ------------------------------------------------------------
  # NSG key validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue([
      for nsg_key in keys(var.network_security_groups) :
      length(trimspace(nsg_key)) > 0
    ])

    error_message = "Each NSG map key must be a non-empty string."
  }

  # ------------------------------------------------------------
  # NSG name validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      length(trimspace(nsg.name)) > 0 &&
      length(nsg.name) <= 80
    ])

    error_message = "Each NSG name must be between 1 and 80 characters."
  }

  # ------------------------------------------------------------
  # Resource group key validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      length(trimspace(nsg.resource_group_key)) > 0
    ])

    error_message = "Each NSG must define a non-empty resource_group_key."
  }

  # ------------------------------------------------------------
  # Rule priority validation
  # Azure NSG priorities: 100 - 4096
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        rule.priority >= 100 &&
        rule.priority <= 4096
      ]
    ]))

    error_message = "NSG rule priority must be between 100 and 4096."
  }

  # ------------------------------------------------------------
  # Rule priority uniqueness
  # Priority must be unique within each NSG
  # ------------------------------------------------------------

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      length([
        for rule_key, rule in nsg.security_rules :
        rule.priority
        ]) == length(distinct([
          for rule_key, rule in nsg.security_rules :
          rule.priority
      ]))
    ])

    error_message = "NSG rule priorities must be unique within each Network Security Group."
  }

  # ------------------------------------------------------------
  # Rule name validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        length(trimspace(rule.name)) > 0 &&
        length(rule.name) <= 80
      ]
    ]))

    error_message = "Each NSG security rule name must be between 1 and 80 characters."
  }

  # ------------------------------------------------------------
  # Direction validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        contains(
          ["Inbound", "Outbound"],
          rule.direction
        )
      ]
    ]))

    error_message = "NSG security rule direction must be Inbound or Outbound."
  }

  # ------------------------------------------------------------
  # Access validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        contains(
          ["Allow", "Deny"],
          rule.access
        )
      ]
    ]))

    error_message = "NSG security rule access must be Allow or Deny."
  }

  # ------------------------------------------------------------
  # Protocol validation
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        contains(
          ["Tcp", "Udp", "Icmp", "*"],
          rule.protocol
        )
      ]
    ]))

    error_message = "NSG security rule protocol must be Tcp, Udp, Icmp, or *."
  }

  # ------------------------------------------------------------
  # Source port validation
  #
  # Exactly one of:
  # - source_port_range
  # - source_port_ranges
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        (
          (rule.source_port_range != null ? 1 : 0) +
          (rule.source_port_ranges != null ? 1 : 0)
        ) == 1
      ]
    ]))

    error_message = "Each NSG rule must define exactly one of source_port_range or source_port_ranges."
  }

  # ------------------------------------------------------------
  # Destination port validation
  #
  # Exactly one of:
  # - destination_port_range
  # - destination_port_ranges
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        (
          (rule.destination_port_range != null ? 1 : 0) +
          (rule.destination_port_ranges != null ? 1 : 0)
        ) == 1
      ]
    ]))

    error_message = "Each NSG rule must define exactly one of destination_port_range or destination_port_ranges."
  }

  # ------------------------------------------------------------
  # Source address validation
  #
  # Exactly one of:
  # - source_address_prefix
  # - source_address_prefixes
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        (
          (rule.source_address_prefix != null ? 1 : 0) +
          (rule.source_address_prefixes != null ? 1 : 0)
        ) == 1
      ]
    ]))

    error_message = "Each NSG rule must define exactly one of source_address_prefix or source_address_prefixes."
  }

  # ------------------------------------------------------------
  # Destination address validation
  #
  # Exactly one of:
  # - destination_address_prefix
  # - destination_address_prefixes
  # ------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for nsg_key, nsg in var.network_security_groups : [
        for rule_key, rule in nsg.security_rules :
        (
          (rule.destination_address_prefix != null ? 1 : 0) +
          (rule.destination_address_prefixes != null ? 1 : 0)
        ) == 1
      ]
    ]))

    error_message = "Each NSG rule must define exactly one of destination_address_prefix or destination_address_prefixes."
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
    condition = length(var.resource_groups) > 0

    error_message = "At least one resource group must be available to the NSG module."
  }
}


variable "tags" {
  description = "Common tags applied to all Network Security Groups."

  type    = map(string)
  default = {}
}