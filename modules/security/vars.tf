# variable "public_ips" {
#   description = "Map of public IPs used by shared platform services"
#   type = map(object({
#     name                = string
#     resource_group_name = string
#     location            = string
#     sku                 = optional(string, "Standard")
#     allocation_method   = optional(string, "Static")
#     zones               = optional(list(string), [])
#     tags                = optional(map(string), {})
#   }))
# }
#
# variable "firewalls" {
#   description = "Map of Azure Firewalls"
#   type = map(object({
#     name                = string
#     resource_group_name = string
#     location            = string
#     sku_name            = optional(string, "AZFW_VNet")
#     sku_tier            = optional(string, "Standard")
#     firewall_policy_id  = optional(string, null)
#     subnet_id           = string
#     public_ip_id        = string
#     tags                = optional(map(string), {})
#   }))
# }

variable "key_vaults" {
  description = "Map of Azure Key Vault instances"
  type = map(object({
    name                            = string
    resource_group_name             = string
    location                        = string
    tenant_id                       = string
    sku_name                        = optional(string, "standard")
    purge_protection_enabled        = optional(bool, true)
    soft_delete_retention_days      = optional(number, 90)
    enable_rbac_authorization       = optional(bool, true)
    public_network_access_enabled   = optional(bool, true)
    tags                            = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags to apply to all security resources"
  type        = map(string)
  default     = {}
}
