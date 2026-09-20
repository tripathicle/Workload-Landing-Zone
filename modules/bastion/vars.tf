variable "bastions" {
  description = "Map of Azure Bastion resources"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    subnet_id           = string
    public_ip_address_id = string
    tags                = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to Bastion resources"
  type        = map(string)
  default     = {}
}
