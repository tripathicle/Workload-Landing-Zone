output "postgresql_servers" {
  description = "Map of PostgreSQL Flexible Servers."

  value = {
    for key, server in azurerm_postgresql_flexible_server.this :
    key => {
      id                  = server.id
      name                = server.name
      location            = server.location
      resource_group_name = server.resource_group_name

      fully_qualified_domain_name = server.fqdn
    }
  }
}


output "postgresql_databases" {
  description = "Map of PostgreSQL databases."

  value = {
    for key, database in azurerm_postgresql_flexible_server_database.this :
    key => {
      id        = database.id
      name      = database.name
      server_id = database.server_id
    }
  }
}