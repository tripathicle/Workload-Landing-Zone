output "service_plans" {
  description = "Map of app service plans"
  value = {
    for key, sp in azurerm_service_plan.this : key => {
      id   = sp.id
      name = sp.name
    }
  }
}

output "web_apps" {
  description = "Map of web apps"
  value = {
    for key, app in azurerm_linux_web_app.this : key => {
      id   = app.id
      name = app.name
      url  = "https://${app.default_hostname}"
    }
  }
}

output "sql_servers" {
  description = "Map of SQL servers"
  value = {
    for key, server in azurerm_mssql_server.this : key => {
      id   = server.id
      name = server.name
    }
  }
}

output "sql_databases" {
  description = "Map of SQL databases"
  value = {
    for key, db in azurerm_mssql_database.this : key => {
      id   = db.id
      name = db.name
    }
  }
}
