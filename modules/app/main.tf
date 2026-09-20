locals {
  default_app_tags = merge(var.tags, {})
}

# Resource: azurerm_service_plan
# Description: Creates the App Service plan used by the web application tier.
# ## Arguments Reference
# - name: (Required) App Service plan name.
# - resource_group_name: (Required) Target resource group.
# - location: (Required) Azure region.
# - os_type: (Required) OS family, such as Linux.
# - sku_name: (Required) App Service pricing tier.
# - tags: (Optional) Resource tags.
resource "azurerm_service_plan" "this" {
  for_each = var.app_service_plan

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name
  tags                = merge(local.default_app_tags, lookup(each.value, "tags", {}))
}

# Resource: azurerm_linux_web_app
# Description: Creates the Linux web app for the presentation tier.
# ## Arguments Reference
# - name: (Required) Web app name.
# - resource_group_name: (Required) Target resource group.
# - location: (Required) Azure region.
# - service_plan_id: (Required) App Service plan ID.
# - https_only: (Optional) Enables HTTPS-only access.
# - site_config: (Optional) Website configuration block.
# - tags: (Optional) Resource tags.
resource "azurerm_linux_web_app" "this" {
  for_each = var.linux_web_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  service_plan_id     = each.value.service_plan_id
  https_only          = lookup(each.value, "https_only", true)

  dynamic "site_config" {
    for_each = each.value.site_config != null ? [each.value.site_config] : []
    content {
      always_on = lookup(site_config.value, "always_on", true)
      ftps_state = lookup(site_config.value, "ftps_state", "FtpsOnly")
      http2_enabled = lookup(site_config.value, "http2_enabled", true)
    }
  }

  tags = merge(local.default_app_tags, lookup(each.value, "tags", {}))
}

# Resource: azurerm_mssql_server
# Description: Creates the SQL logical server used by the data tier.
# ## Arguments Reference
# - name: (Required) SQL server name.
# - resource_group_name: (Required) Target resource group.
# - location: (Required) Azure region.
# - version: (Required) SQL Server version.
# - administrator_login: (Required) SQL administrator login.
# - administrator_login_password: (Required) SQL administrator password.
# - minimum_tls_version: (Optional) TLS minimum version.
# - tags: (Optional) Resource tags.
resource "azurerm_mssql_server" "this" {
  for_each = var.sql_servers

  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  version                      = each.value.version
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  minimum_tls_version          = lookup(each.value, "minimum_tls_version", "1.2")
  tags                         = merge(local.default_app_tags, lookup(each.value, "tags", {}))
}

# Resource: azurerm_mssql_database
# Description: Creates the SQL database in the logical server.
# ## Arguments Reference
# - name: (Required) Database name.
# - server_id: (Required) SQL server ID.
# - sku_name: (Required) Database pricing tier.
# - collation: (Optional) Database collation.
# - tags: (Optional) Resource tags.
resource "azurerm_mssql_database" "this" {
  for_each = var.sql_databases

  name      = each.value.name
  server_id = each.value.server_id
  sku_name  = each.value.sku_name
  collation = lookup(each.value, "collation", "SQL_Latin1_General_CP1_CI_AS")
  tags      = merge(local.default_app_tags, lookup(each.value, "tags", {}))
}
