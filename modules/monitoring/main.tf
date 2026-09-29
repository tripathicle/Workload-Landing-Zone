# ============================================================
# LOG ANALYTICS WORKSPACE
# ============================================================

resource "azurerm_log_analytics_workspace" "this" {
  for_each = {
    workload = var.monitoring.log_analytics_workspace
  }

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  sku = each.value.sku

  retention_in_days = each.value.retention_in_days

  tags = var.tags
}


# ============================================================
# APPLICATION INSIGHTS
# ============================================================

resource "azurerm_application_insights" "this" {
  for_each = {
    workload = var.monitoring.application_insights
  }

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  application_type = each.value.application_type

  workspace_id = azurerm_log_analytics_workspace.this["workload"].id

  retention_in_days = each.value.retention_in_days

  tags = var.tags
}