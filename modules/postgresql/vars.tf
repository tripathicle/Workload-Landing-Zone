variable "postgresql_servers" {
  description = "Map of Azure Database for PostgreSQL Flexible Servers."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    version    = optional(string, "16")
    sku_name   = string
    storage_mb = optional(number, 32768)

    administrator_login          = string
    administrator_password       = string
    backup_retention_days        = optional(number, 7)
    geo_redundant_backup_enabled = optional(bool, false)

    public_network_access_enabled = optional(bool, false)

    zone = optional(string, null)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      length(trimspace(server.name)) > 0 &&
      length(trimspace(server.resource_group_name)) > 0 &&
      length(trimspace(server.location)) > 0 &&
      length(trimspace(server.administrator_login)) > 0 &&
      length(server.administrator_password) >= 12 &&
      length(trimspace(server.sku_name)) > 0
    ])

    error_message = "Each PostgreSQL server must define valid name, resource group, location, administrator login, password of at least 12 characters, and SKU."
  }

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      contains(
        ["13", "14", "15", "16", "17"],
        server.version
      )
    ])

    error_message = "PostgreSQL version must be one of the supported versions configured by this module."
  }

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      server.storage_mb >= 32768
    ])

    error_message = "PostgreSQL storage_mb must be at least 32768 MB."
  }

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      server.backup_retention_days >= 7 &&
      server.backup_retention_days <= 35
    ])

    error_message = "PostgreSQL backup retention must be between 7 and 35 days."
  }
}


variable "postgresql_databases" {
  description = "Map of PostgreSQL databases."

  type = map(object({
    name                  = string
    postgresql_server_key = string

    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
  }))

  validation {
    condition = alltrue([
      for key, database in var.postgresql_databases :
      length(trimspace(database.name)) > 0 &&
      length(trimspace(database.postgresql_server_key)) > 0
    ])

    error_message = "Each PostgreSQL database must define a name and PostgreSQL server key."
  }
}


variable "tags" {
  description = "Default tags applied to PostgreSQL resources."

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