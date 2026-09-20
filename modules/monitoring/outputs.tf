output "log_analytics_workspaces" {
  description = "Map of Log Analytics workspaces"
  value = {
    for key, workspace in azurerm_log_analytics_workspace.this : key => {
      id   = workspace.id
      name = workspace.name
    }
  }
}

output "application_insights" {
  description = "Map of Application Insights resources"
  value = {
    for key, appi in azurerm_application_insights.this : key => {
      id   = appi.id
      name = appi.name
    }
  }
}
