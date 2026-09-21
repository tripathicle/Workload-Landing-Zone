variable "sql_servers" {
  description = "Map of Azure SQL logical servers to provision."

  # sensitive = true

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    version                      = optional(string, "12.0")
    administrator_login         = string
    administrator_login_password = string

    minimum_tls_version           = optional(string, "1.2")
    public_network_access_enabled = optional(bool, false)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, server in var.sql_servers :
      length(trimspace(server.name)) >= 1 &&
      length(trimspace(server.resource_group_name)) > 0 &&
      length(trimspace(server.location)) > 0 &&
      length(trimspace(server.administrator_login)) >= 1 &&
      length(server.administrator_login_password) >= 12
    ])

    error_message = "Each SQL Server must define a valid name, resource group, location, administrator login, and password of at least 12 characters."
  }

  validation {
    condition = alltrue([
      for key, server in var.sql_servers :
      contains(
        ["1.2"],
        server.minimum_tls_version
      )
    ])

    error_message = "minimum_tls_version must be 1.2."
  }
}

variable "sql_databases" {
  description = "Map of Azure SQL databases to provision."

  type = map(object({
    name              = string
    sql_server_key    = string
    sku_name          = string
    max_size_gb       = optional(number, 32)
    zone_redundant    = optional(bool, false)
    storage_account_type = optional(string, "Geo")
    collation         = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    read_scale        = optional(bool, false)
    geo_backup_enabled = optional(bool, true)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, database in var.sql_databases :
      length(trimspace(database.name)) > 0 &&
      length(trimspace(database.sql_server_key)) > 0 &&
      length(trimspace(database.sku_name)) > 0 &&
      database.max_size_gb > 0
    ])

    error_message = "Each SQL database must define a name, SQL Server key, SKU, and positive max_size_gb."
  }

  validation {
    condition = alltrue([
      for key, database in var.sql_databases :
      contains(
        ["Geo", "Local"],
        database.storage_account_type
      )
    ])

    error_message = "storage_account_type must be either Geo or Local."
  }
}

variable "tags" {
  description = "Default tags applied to SQL resources."

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