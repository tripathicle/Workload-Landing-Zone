# ============================================================
# LOG ANALYTICS WORKSPACE OUTPUT
# ============================================================

output "log_analytics_workspace" {
  description = "Log Analytics Workspace information."

  value = {
    id = azurerm_log_analytics_workspace.this["workload"].id

    name = (
      azurerm_log_analytics_workspace.this["workload"].name
    )

    workspace_id = (
      azurerm_log_analytics_workspace.this["workload"].workspace_id
    )

    resource_group_name = (
      azurerm_log_analytics_workspace.this["workload"].resource_group_name
    )

    location = (
      azurerm_log_analytics_workspace.this["workload"].location
    )
  }
}


# ============================================================
# APPLICATION INSIGHTS OUTPUT
# ============================================================

output "application_insights" {
  description = "Application Insights information."

  value = {
    id = (
      azurerm_application_insights.this["workload"].id
    )

    name = (
      azurerm_application_insights.this["workload"].name
    )

    app_id = (
      azurerm_application_insights.this["workload"].app_id
    )

    instrumentation_key = (
      azurerm_application_insights.this["workload"].instrumentation_key
    )

    connection_string = (
      azurerm_application_insights.this["workload"].connection_string
    )

    resource_group_name = (
      azurerm_application_insights.this["workload"].resource_group_name
    )

    location = (
      azurerm_application_insights.this["workload"].location
    )
  }

  sensitive = true
}