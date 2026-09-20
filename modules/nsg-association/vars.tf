variable "subnet_nsg_associations" {
  description = "Map of subnet names to NSG names. The module resolves the IDs from output objects passed by the parent module."
  type = map(object({
    subnet_name               = string
    network_security_group_name = string
  }))
  default = {}
}

variable "subnets" {
  description = "Map of subnet output objects produced by the network module."
  type = map(object({
    id   = string
    name = string
  }))
  default = {}
}

variable "nsgs" {
  description = "Map of NSG output objects produced by the NSG module."
  type = map(object({
    id   = string
    name = string
  }))
  default = {}
}
