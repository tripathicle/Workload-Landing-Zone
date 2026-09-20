variable "location" {
  description = "Azure region for the storage accounts. Must match the target deployment region and compliance scope."
  type        = string

  validation {
    condition     = contains(["japaneast", "eastus", "eastus2", "centralus", "westeurope", "uksouth"], lower(var.location))
    error_message = "location must be a supported Azure region for this environment."
  }
}

variable "tags" {
  description = "Default tags applied to all storage accounts. Use a consistent tagging strategy for governance and cost control."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings."
  }
}

variable "storage_accounts" {
  description = "Map of storage accounts to create. Names must follow Azure storage rules and replication settings must be valid."
  type = map(object({
    name                     = string
    resource_group_name      = string
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    tags                     = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts : length(storage.name) >= 3 && length(storage.name) <= 24 && can(regex("^[a-z0-9]+$", storage.name)) && contains(["Standard", "Premium"], storage.account_tier) && contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RA-GRS"], storage.account_replication_type)
    ])
    error_message = "Storage account names must be 3-24 lowercase letters and numbers; account_tier and account_replication_type must be valid Azure values."
  }
}
