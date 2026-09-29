# ============================================================
# SQL SERVER OUTPUTS
# ============================================================

output "sql_servers" {
  description = "Azure SQL Server information."

  value = {
    for key, server in azurerm_mssql_server.this :
    key => {
      id                          = server.id
      name                        = server.name
      location                    = server.location
      resource_group_name         = server.resource_group_name
      fully_qualified_domain_name = server.fully_qualified_domain_name
    }
  }
}


# ============================================================
# SQL DATABASE OUTPUTS
# ============================================================

output "sql_databases" {
  description = "Azure SQL Database information."

  value = {
    for key, database in azurerm_mssql_database.this :
    key => {
      id        = database.id
      name      = database.name
      server_id = database.server_id
      sku_name  = database.sku_name
    }
  }
}