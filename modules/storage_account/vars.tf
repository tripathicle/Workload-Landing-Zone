# ============================================================
# MODULE: STORAGE ACCOUNT
# FILE: Modules/storage_account/variables.tf
# ============================================================
#
# Purpose:
#   Defines reusable Storage Account input contract and
#   validations.
#
# ============================================================


# ============================================================
# STORAGE ACCOUNTS
# ============================================================

variable "storage_accounts" {
  description = "Map of Azure Storage Accounts to provision."

  type = map(object({
    name                             = string
    resource_group_key               = string
    account_tier                     = optional(string, "Standard")
    account_replication_type         = optional(string, "LRS")
    min_tls_version                  = optional(string, "TLS1_2")
    allow_nested_items_to_be_public  = optional(bool, false)
    public_network_access_enabled    = optional(bool, false)
    cross_tenant_replication_enabled = optional(bool, false)
    tags                             = optional(map(string), {})
  }))

  # ----------------------------------------------------------
  # Validation 01:
  # At least one Storage Account must be defined.
  # ----------------------------------------------------------

  validation {
    condition = length(var.storage_accounts) > 0

    error_message = "At least one storage account must be defined."
  }

  # ----------------------------------------------------------
  # Validation 02:
  # Storage Account map keys must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key in keys(var.storage_accounts) :
      length(trimspace(storage_account_key)) > 0
    ])

    error_message = "Each storage account map key must be a non-empty string."
  }

  # ----------------------------------------------------------
  # Validation 03:
  # Storage Account name must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      length(trimspace(storage_account.name)) > 0
    ])

    error_message = "Each storage account must define a non-empty name."
  }

  # ----------------------------------------------------------
  # Validation 04:
  # Azure Storage Account name:
  #   - 3 to 24 characters
  #   - lowercase letters
  #   - numbers
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      can(regex(
        "^[a-z0-9]{3,24}$",
        storage_account.name
      ))
    ])

    error_message = "Each storage account name must be 3-24 characters and contain only lowercase letters and numbers."
  }

  # ----------------------------------------------------------
  # Validation 05:
  # Resource Group key must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      length(trimspace(storage_account.resource_group_key)) > 0
    ])

    error_message = "Each storage account must reference a non-empty resource_group_key."
  }

  # ----------------------------------------------------------
  # Validation 06:
  # Account tier.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      contains(
        ["Standard", "Premium"],
        storage_account.account_tier
      )
    ])

    error_message = "Storage account account_tier must be either Standard or Premium."
  }

  # ----------------------------------------------------------
  # Validation 07:
  # Replication type.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      contains(
        [
          "LRS",
          "GRS",
          "RAGRS",
          "ZRS",
          "GZRS",
          "RAGZRS"
        ],
        storage_account.account_replication_type
      )
    ])

    error_message = "Storage account replication type must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }

  # ----------------------------------------------------------
  # Validation 08:
  # Minimum TLS version.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      contains(
        ["TLS1_2", "TLS1_3"],
        storage_account.min_tls_version
      )
    ])

    error_message = "Storage account min_tls_version must be TLS1_2 or TLS1_3."
  }

  # ----------------------------------------------------------
  # Validation 09:
  # Resource-specific tag keys and values must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      alltrue([
        for tag_key, tag_value in storage_account.tags :
        length(trimspace(tag_key)) > 0 &&
        length(trimspace(tag_value)) > 0
      ])
    ])

    error_message = "Each storage account tag key and value must be non-empty."
  }

  # ----------------------------------------------------------
  # Validation 10:
  # Resource-specific tag keys must contain supported
  # characters.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      alltrue([
        for tag_key, tag_value in storage_account.tags :
        can(regex(
          "^[A-Za-z0-9_.:/+=@\\- ]+$",
          tag_key
        ))
      ])
    ])

    error_message = "Storage account tag keys contain unsupported characters."
  }
}


# ============================================================
# RESOURCE GROUPS
# ============================================================

variable "resource_groups" {
  description = "Map of Resource Groups created by the Resource Group module."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))

  validation {
    condition = length(var.resource_groups) > 0

    error_message = "At least one resource group must be available to the storage account module."
  }
}


# ============================================================
# COMMON TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to all Storage Accounts."

  type    = map(string)
  default = {}

  # ----------------------------------------------------------
  # Validation 01:
  # Common tag keys and values must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      length(trimspace(tag_key)) > 0 &&
      length(trimspace(tag_value)) > 0
    ])

    error_message = "Each common tag key and value must be non-empty."
  }

  # ----------------------------------------------------------
  # Validation 02:
  # Common tag keys must use supported characters.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      can(regex(
        "^[A-Za-z0-9_.:/+=@\\- ]+$",
        tag_key
      ))
    ])

    error_message = "Common tag keys contain unsupported characters."
  }
}