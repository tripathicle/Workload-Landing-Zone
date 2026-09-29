variable "postgresql_servers" {
  description = "Azure PostgreSQL Flexible Server configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    administrator_login = string

    version = optional(string, "16")

    sku_name = optional(
      string,
      "B_Standard_B1ms"
    )

    storage_mb = optional(
      number,
      32768
    )

    backup_retention_days = optional(
      number,
      7
    )

    geo_redundant_backup_enabled = optional(
      bool,
      false
    )

    public_network_access_enabled = optional(
      bool,
      false
    )

    database = optional(object({
      name = string

      charset = optional(
        string,
        "UTF8"
      )

      collation = optional(
        string,
        "en_US.utf8"
      )
    }))

    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string)
    }))
  }))

  validation {
    condition = length(var.postgresql_servers) > 0

    error_message = "At least one PostgreSQL server must be defined."
  }

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      length(trimspace(server.name)) > 0
    ])

    error_message = "Each PostgreSQL server must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      length(trimspace(server.administrator_login)) > 0
    ])

    error_message = "Each PostgreSQL server must define a non-empty administrator login."
  }
}


variable "administrator_password" {
  description = "Administrator password for PostgreSQL Flexible Server."

  type      = string
  sensitive = true

  validation {
    condition = length(var.administrator_password) >= 8

    error_message = "PostgreSQL administrator password must be at least 8 characters."
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
  description = "Common tags applied to PostgreSQL resources."

  type    = map(string)
  default = {}
}