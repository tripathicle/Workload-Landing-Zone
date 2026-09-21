# ============================================================
# SUBNET -> NSG ASSOCIATION CONFIGURATION
# ============================================================

variable "subnet_nsg_associations" {
  description = "Map of subnet-to-NSG associations. Values reference logical subnet and NSG keys exposed by upstream modules."

  type = map(object({
    subnet_name                 = string
    network_security_group_name = string
  }))

  default = {}

  validation {
    condition = alltrue([
      for key, association in var.subnet_nsg_associations :
      length(trimspace(association.subnet_name)) > 0 &&
      length(trimspace(association.network_security_group_name)) > 0
    ])

    error_message = "Each subnet-to-NSG association must define a non-empty subnet key and NSG key."
  }
}


# ============================================================
# SUBNET OUTPUTS FROM NETWORK MODULE
# ============================================================

variable "subnets" {
  description = "Map of subnet output objects produced by the network module."

  type = map(object({
    id   = string
    name = string
  }))

  default = {}
}


# ============================================================
# NSG OUTPUTS FROM NSG MODULE
# ============================================================

variable "nsgs" {
  description = "Map of NSG output objects produced by the NSG module."

  type = map(object({
    id   = string
    name = string
  }))

  default = {}
}