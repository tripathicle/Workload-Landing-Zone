variable "sql_servers" {
  description = "Azure SQL Server and optional database configuration."

  type = map(object({
    name                = string
    resource_group_key  = string
    administrator_login = string

    version             = optional(string, "12.0")
    minimum_tls_version = optional(string, "1.2")

    public_network_access_enabled = optional(bool, false)

    database = optional(object({
      name                 = string
      sku_name             = string
      max_size_gb          = optional(number)
      zone_redundant       = optional(bool, false)
      storage_account_type = optional(string, "Local")
    }))
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
}


variable "administrator_password" {
  description = "Administrator password for Azure SQL Server."

  type      = string
  sensitive = true

  validation {
    condition     = length(var.administrator_password) >= 8
    error_message = "Azure SQL administrator password must be at least 8 characters."
  }
}


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


variable "tags" {
  description = "Common tags applied to Azure SQL resources."

  type    = map(string)
  default = {}
}