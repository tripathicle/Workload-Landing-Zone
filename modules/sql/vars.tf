# ============================================================
# AZURE SQL SERVERS
# ============================================================

variable "sql_servers" {
  description = "Azure SQL Server and optional database configuration."

  type = map(object({
    name                          = string
    resource_group_key            = string
    administrator_login           = string
    version                       = optional(string, "12.0")
    minimum_tls_version           = optional(string, "1.2")
    public_network_access_enabled = optional(bool, false)

    azuread_administrator = optional(object({
      login_username = string
      object_id      = string
    }))

    database = optional(object({
      name                 = string
      sku_name             = string
      max_size_gb          = optional(number)
      zone_redundant       = optional(bool, false)
      storage_account_type = optional(string, "Local")
    }))

    vulnerability_assessment = object({
      email_subscription_admins = bool
      emails                    = list(string)
    })
  }))

  validation {
    condition = length(var.sql_servers) > 0

    error_message = "At least one Azure SQL Server must be defined."
  }

  validation {
    condition = alltrue([
      for key, server in var.sql_servers :
      length(trimspace(server.name)) > 0
    ])

    error_message = "Each Azure SQL Server must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for key, server in var.sql_servers :
      length(trimspace(server.administrator_login)) > 0
    ])

    error_message = "Each Azure SQL Server must define a non-empty administrator login."
  }

  validation {
    condition = alltrue([
      for key, server in var.sql_servers :
      server.azuread_administrator == null ||
      (
        length(trimspace(server.azuread_administrator.login_username)) > 0 &&
        length(trimspace(server.azuread_administrator.object_id)) > 0
      )
    ])

    error_message = "Azure AD administrator must define a non-empty login username and object ID."
  }
}


# ============================================================
# SQL ADMINISTRATOR PASSWORD
# ============================================================

variable "administrator_password" {
  description = "Administrator password for Azure SQL Server."

  type      = string
  sensitive = true

  validation {
    condition = length(var.administrator_password) >= 8

    error_message = "Azure SQL administrator password must be at least 8 characters."
  }
}


# ============================================================
# SQL VULNERABILITY ASSESSMENT STORAGE
# ============================================================

variable "vulnerability_assessment_storage" {
  description = "Storage Account and container information used by SQL Vulnerability Assessment."

  type = object({
    storage_account = object({
      id                    = string
      primary_blob_endpoint = string
      primary_access_key    = string
    })

    container = object({
      id   = string
      name = string
    })
  })

  sensitive = true
}


# ============================================================
# SQL AUDITING
# ============================================================

variable "auditing_retention_days" {
  description = "SQL Server audit retention period in days."

  type    = number
  default = 180

  validation {
    condition = (
      var.auditing_retention_days > 90 &&
      var.auditing_retention_days <= 730
    )

    error_message = "SQL auditing retention must be greater than 90 days and no more than 730 days."
  }
}


# ============================================================
# RESOURCE GROUPS
# ============================================================

variable "resource_groups" {
  description = "Resource Groups created by the Resource Group module."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))

  validation {
    condition = length(var.resource_groups) > 0

    error_message = "At least one Resource Group must be available."
  }
}


# ============================================================
# COMMON TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to Azure SQL resources."

  type    = map(string)
  default = {}
}