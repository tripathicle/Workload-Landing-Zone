# ============================================================
# Network Interface Input
# ============================================================
# CHANGE:
# - Added explicit validation for IP allocation mode.
# - Added validation for required string values.
# - Kept private_ip_address optional because Dynamic allocation
#   does not require a manually assigned IP.
# ============================================================

variable "network_interfaces" {
  description = "Map of Azure Network Interfaces to provision."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    ip_configuration = object({
      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = string
      private_ip_address            = optional(string, null)
    })

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, nic in var.network_interfaces :
      length(trimspace(nic.name)) > 0 &&
      length(trimspace(nic.resource_group_name)) > 0 &&
      length(trimspace(nic.location)) > 0 &&
      length(trimspace(nic.ip_configuration.name)) > 0 &&
      length(trimspace(nic.ip_configuration.subnet_id)) > 0 &&
      contains(
        ["Static", "Dynamic"],
        nic.ip_configuration.private_ip_address_allocation
      )
    ])

    error_message = "Each NIC must define a name, resource group, location, IP configuration name, subnet ID, and a private IP allocation mode of either Static or Dynamic."
  }

  validation {
    condition = alltrue([
      for key, nic in var.network_interfaces :
      nic.ip_configuration.private_ip_address_allocation == "Dynamic" ||
      (
        nic.ip_configuration.private_ip_address != null &&
        length(trimspace(nic.ip_configuration.private_ip_address)) > 0
      )
    ])

    error_message = "A private_ip_address must be provided when private_ip_address_allocation is Static."
  }
}


# ============================================================
# Common Tags
# ============================================================
# CHANGE:
# - Kept common tags as a module-level input.
# - Environment/root module controls common tagging.
# ============================================================

variable "tags" {
  description = "Default tags applied to all network interfaces."

  type = map(string)

  default = {}
}