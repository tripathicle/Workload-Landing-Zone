# Resource: azurerm_log_analytics_workspace
# Description: Creates a centralized Log Analytics workspace for diagnostics and security monitoring.
# ## Arguments Reference
# - name: (Required) Workspace name.
# - resource_group_name: (Required) Target resource group.
# - location: (Required) Azure region.
# - sku: (Optional) Log Analytics SKU.
# - retention_in_days: (Optional) Data retention period.
# - tags: (Optional) Resource tags.
resource "azurerm_log_analytics_workspace" "this" {
  for_each = var.log_analytics_workspaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.sku
  retention_in_days   = each.value.retention_in_days
  tags                = merge(var.tags, lookup(each.value, "tags", {}))
}

# Resource: azurerm_application_insights
# Description: Creates Application Insights for application telemetry and health monitoring.
# ## Arguments Reference
# - name: (Required) Application Insights resource name.
# - resource_group_name: (Required) Target resource group.
# - location: (Required) Azure region.
# - workspace_id: (Required) Log Analytics workspace ID.
# - application_type: (Optional) Application type for telemetry.
# - tags: (Optional) Resource tags.
resource "azurerm_application_insights" "this" {
  for_each = var.application_insights

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  workspace_id        = each.value.workspace_id
  application_type    = each.value.application_type
  tags                = merge(var.tags, lookup(each.value, "tags", {}))
}
