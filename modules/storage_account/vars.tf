# ============================================================
# MODULE: STORAGE ACCOUNT
# FILE: modules/storage_account/vars.tf
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

    shared_access_key_enabled = optional(bool, false)

    sas_expiration_period = optional(
      string,
      "7.00:00:00"
    )

    blob_delete_retention_days = optional(
      number,
      7
    )

    tags = optional(map(string), {})
  }))

  validation {
    condition = length(var.storage_accounts) > 0

    error_message = "At least one storage account must be defined."
  }

  validation {
    condition = alltrue([
      for storage_account_key in keys(var.storage_accounts) :
      length(trimspace(storage_account_key)) > 0
    ])

    error_message = "Each storage account map key must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      length(trimspace(storage_account.name)) > 0
    ])

    error_message = "Each storage account must define a non-empty name."
  }

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

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      length(trimspace(storage_account.resource_group_key)) > 0
    ])

    error_message = "Each storage account must reference a non-empty resource_group_key."
  }

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

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      contains(
        ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"],
        storage_account.account_replication_type
      )
    ])

    error_message = "Storage account replication type must be one of LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      contains(
        ["TLS1_2"],
        storage_account.min_tls_version
      )
    ])

    error_message = "Storage account min_tls_version must be TLS1_2."
  }

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      storage_account.blob_delete_retention_days >= 1 &&
      storage_account.blob_delete_retention_days <= 365
    ])

    error_message = "Storage Account blob delete retention must be between 1 and 365 days."
  }

  validation {
    condition = alltrue([
      for storage_account_key, storage_account in var.storage_accounts :
      can(regex(
        "^[0-9]+\\.[0-9]{2}:[0-9]{2}:[0-9]{2}$",
        storage_account.sas_expiration_period
      ))
    ])

    error_message = "Storage Account SAS expiration period must use D.HH:MM:SS or DD.HH:MM:SS format."
  }

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
# STORAGE CONTAINERS
# ============================================================

variable "storage_containers" {
  description = "Map of Blob Storage containers to provision."

  type = map(object({
    name                  = string
    storage_account_key   = string
    container_access_type = optional(string, "private")
  }))

  default = {}

  validation {
    condition = alltrue([
      for key, container in var.storage_containers :
      length(trimspace(container.name)) > 0
    ])

    error_message = "Each storage container must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for key, container in var.storage_containers :
      length(trimspace(container.storage_account_key)) > 0
    ])

    error_message = "Each storage container must reference a non-empty storage_account_key."
  }

  validation {
    condition = alltrue([
      for key, container in var.storage_containers :
      contains(
        ["private", "blob", "container"],
        container.container_access_type
      )
    ])

    error_message = "Storage container access type must be private, blob, or container."
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
# TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to all Storage Accounts."

  type    = map(string)
  default = {}

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      length(trimspace(tag_key)) > 0 &&
      length(trimspace(tag_value)) > 0
    ])

    error_message = "Each common tag key and value must be non-empty."
  }

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