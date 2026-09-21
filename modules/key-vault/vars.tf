variable "key_vaults" {
  description = "Map of Azure Key Vault instances."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    tenant_id           = string

    sku_name = optional(string, "standard")

    purge_protection_enabled = optional(bool, true)

    soft_delete_retention_days = optional(number, 90)

    enable_rbac_authorization = optional(bool, true)

    public_network_access_enabled = optional(bool, true)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      length(trimspace(kv.name)) > 0 &&
      length(trimspace(kv.resource_group_name)) > 0 &&
      length(trimspace(kv.location)) > 0 &&
      length(trimspace(kv.tenant_id)) > 0
    ])

    error_message = "Each Key Vault must define a non-empty name, resource group name, location, and tenant ID."
  }

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      contains(
        ["standard", "premium"],
        lower(kv.sku_name)
      )
    ])

    error_message = "Key Vault sku_name must be either standard or premium."
  }

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      kv.soft_delete_retention_days >= 7 &&
      kv.soft_delete_retention_days <= 90
    ])

    error_message = "Key Vault soft delete retention must be between 7 and 90 days."
  }

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      kv.purge_protection_enabled == true ||
      kv.soft_delete_retention_days >= 7
    ])

    error_message = "Key Vault configuration must use a valid soft-delete retention period."
  }
}

variable "tags" {
  description = "Default tags applied to all Key Vault resources."

  type = map(string)

  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be a non-empty string."
  }
}