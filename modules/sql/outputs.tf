output "sql_servers" {
  description = "Map of provisioned Azure SQL logical servers."

  value = {
    for key, server in azurerm_mssql_server.this : key => {
      id   = server.id
      name = server.name
      fqdn = server.fully_qualified_domain_name
    }
  }
}

output "sql_databases" {
  description = "Map of provisioned Azure SQL databases."

  value = {
    for key, database in azurerm_mssql_database.this : key => {
      id   = database.id
      name = database.name
    }
  }
}