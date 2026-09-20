variable "network_interfaces" {
  description = "Map of NICs for virtual machines"
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
}

variable "tags" {
  description = "Default tags to apply to all NICs"
  type        = map(string)
  default     = {}
}
