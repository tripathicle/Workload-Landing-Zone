variable "log_analytics_workspaces" {
  description = "Map of Log Analytics workspaces."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku               = optional(string, "PerGB2018")
    retention_in_days = optional(number, 30)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, workspace in var.log_analytics_workspaces :
      length(trimspace(workspace.name)) > 0 &&
      length(trimspace(workspace.resource_group_name)) > 0 &&
      length(trimspace(workspace.location)) > 0
    ])

    error_message = "Each Log Analytics workspace must define a non-empty name, resource group name, and location."
  }

  validation {
    condition = alltrue([
      for key, workspace in var.log_analytics_workspaces :
      workspace.retention_in_days >= 30 &&
      workspace.retention_in_days <= 730
    ])

    error_message = "Log Analytics retention must be between 30 and 730 days."
  }

  validation {
    condition = alltrue([
      for key, workspace in var.log_analytics_workspaces :
      contains(
        ["PerGB2018", "CapacityReservation", "Free", "Standalone"],
        workspace.sku
      )
    ])

    error_message = "Log Analytics workspace SKU must be a supported Azure SKU."
  }
}

variable "application_insights" {
  description = "Map of Application Insights resources."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    workspace_key = string

    application_type = optional(string, "web")

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, appi in var.application_insights :
      length(trimspace(appi.name)) > 0 &&
      length(trimspace(appi.resource_group_name)) > 0 &&
      length(trimspace(appi.location)) > 0 &&
      length(trimspace(appi.workspace_key)) > 0
    ])

    error_message = "Each Application Insights resource must define a non-empty name, resource group name, location, and Log Analytics workspace key."
  }

  validation {
    condition = alltrue([
      for key, appi in var.application_insights :
      contains(
        ["web", "other"],
        lower(appi.application_type)
      )
    ])

    error_message = "Application Insights application_type must be either web or other."
  }
}

variable "tags" {
  description = "Default tags applied to monitoring resources."

  type = map(string)

  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be a non-empty string."
  }
}