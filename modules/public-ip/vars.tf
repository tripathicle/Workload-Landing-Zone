variable "public_ips" {
  description = "Map of public IP addresses used by ingress and admin components"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    allocation_method   = optional(string, "Static")
    sku                 = optional(string, "Standard")
    zones               = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to public IP resources"
  type        = map(string)
  default     = {}
}
