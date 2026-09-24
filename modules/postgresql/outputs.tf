output "postgresql_servers" {
  description = "Map of provisioned PostgreSQL Flexible Servers."

  value = {
    for key, server in azurerm_postgresql_flexible_server.this : key => {
      id   = server.id
      name = server.name
      fqdn = server.fqdn
    }
  }
}


output "postgresql_databases" {
  description = "Map of provisioned PostgreSQL databases."

  value = {
    for key, database in azurerm_postgresql_flexible_server_database.this : key => {
      id   = database.id
      name = database.name
    }
  }
}