variable "app_service_plan" {
  description = "Map of app service plans for the 3-tier monolithic app"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    os_type             = string
    sku_name            = string
    tags                = optional(map(string), {})
  }))
}

variable "linux_web_apps" {
  description = "Map of Linux web apps for the presentation layer"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    service_plan_id     = string
    https_only          = optional(bool, true)
    site_config = optional(object({
      always_on = optional(bool, true)
    }), {})
    tags = optional(map(string), {})
  }))
}

variable "sql_servers" {
  description = "Map of Azure SQL logical servers for the data layer"
  type = map(object({
    name                         = string
    resource_group_name          = string
    location                     = string
    version                      = string
    administrator_login          = string
    administrator_login_password = string
    minimum_tls_version          = optional(string, "1.2")
    tags                         = optional(map(string), {})
  }))
}

variable "sql_databases" {
  description = "Map of Azure SQL databases"
  type = map(object({
    name      = string
    server_id = string
    sku_name  = string
    collation = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    tags      = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to all app-layer resources"
  type        = map(string)
  default     = {}
}
