variable "key_vaults" {
  description = "Map of Azure Key Vault instances"
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    tenant_id                     = string
    sku_name                      = optional(string, "standard")
    purge_protection_enabled      = optional(bool, true)
    soft_delete_retention_days    = optional(number, 90)
    enable_rbac_authorization     = optional(bool, true)
    public_network_access_enabled = optional(bool, true)
    tags                          = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags to apply to all key vault resources"
  type        = map(string)
  default     = {}
}
