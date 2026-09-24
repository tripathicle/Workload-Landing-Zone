locals {
  private_endpoint_targets = merge(
    {
      for key, server in module.sql.sql_servers :
      "sql:${key}" => server.id
    },

    {
      for key, server in module.postgresql.postgresql_servers :
      "postgresql:${key}" => server.id
    }
  )
}