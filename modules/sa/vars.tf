variable "location" {
  description = "Azure region for the storage accounts."

  type = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must be a non-empty Azure region."
  }
}

variable "storage_accounts" {
  description = "Map of Azure Storage Accounts to provision."

  type = map(object({
    name                       = string
    resource_group_name        = string
    account_tier               = optional(string, "Standard")
    account_replication_type   = optional(string, "LRS")
    min_tls_version            = optional(string, "TLS1_2")
    allow_nested_items_to_be_public = optional(bool, false)
    public_network_access_enabled   = optional(bool, true)
    tags                       = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      length(storage.name) >= 3 &&
      length(storage.name) <= 24 &&
      can(regex("^[a-z0-9]+$", storage.name))
    ])

    error_message = "Storage account names must be 3-24 characters and contain only lowercase letters and numbers."
  }

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      contains(
        ["Standard", "Premium"],
        storage.account_tier
      )
    ])

    error_message = "account_tier must be either Standard or Premium."
  }

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      contains(
        ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"],
        storage.account_replication_type
      )
    ])

    error_message = "account_replication_type must be a supported Azure replication type."
  }

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      contains(
        ["TLS1_2", "TLS1_3"],
        storage.min_tls_version
      )
    ])

    error_message = "min_tls_version must be TLS1_2 or TLS1_3."
  }
}

variable "tags" {
  description = "Default tags applied to all storage accounts."

  type    = map(string)
  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be non-empty."
  }
}