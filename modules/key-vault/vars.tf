# ============================================================
# KEY VAULT VARIABLES
# ============================================================

variable "key_vaults" {
  description = "Azure Key Vault configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    sku_name = optional(string, "standard")

    tenant_id = optional(string)

    soft_delete_retention_days = optional(number, 90)
    purge_protection_enabled   = optional(bool, true)

    public_network_access_enabled = optional(bool, false)

    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)

    enable_rbac_authorization = optional(bool, true)
  }))

  validation {
    condition = alltrue([
      for key, vault in var.key_vaults :
      length(trimspace(vault.name)) > 0
    ])

    error_message = "Each Key Vault must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for key, vault in var.key_vaults :
      vault.soft_delete_retention_days >= 7 &&
      vault.soft_delete_retention_days <= 90
    ])

    error_message = "Key Vault soft delete retention must be between 7 and 90 days."
  }
}

variable "resource_groups" {
  description = "Resource group information."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))
}

variable "tags" {
  description = "Common resource tags."

  type    = map(string)
  default = {}
}