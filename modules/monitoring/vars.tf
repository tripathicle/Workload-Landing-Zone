# ============================================================
# MONITORING VARIABLES
# ============================================================

variable "monitoring" {
  description = "Azure Monitor, Log Analytics and Application Insights configuration."

  type = object({
    log_analytics_workspace = object({
      name               = string
      resource_group_key = string
      sku                = optional(string, "PerGB2018")
      retention_in_days  = optional(number, 30)
    })

    application_insights = object({
      name               = string
      resource_group_key = string
      application_type   = optional(string, "web")
      retention_in_days  = optional(number, 90)
    })
  })

  validation {
    condition = (
      var.monitoring.log_analytics_workspace.retention_in_days >= 30 &&
      var.monitoring.log_analytics_workspace.retention_in_days <= 730
    )

    error_message = "Log Analytics retention must be between 30 and 730 days."
  }

  validation {
    condition = (
      var.monitoring.application_insights.retention_in_days >= 30 &&
      var.monitoring.application_insights.retention_in_days <= 730
    )

    error_message = "Application Insights retention must be between 30 and 730 days."
  }
}


# ============================================================
# RESOURCE GROUPS
# ============================================================

variable "resource_groups" {
  description = "Resource group information."

  type = map(object({
    id       = string
    name     = string
    location = string
  }))
}


# ============================================================
# TAGS
# ============================================================

variable "tags" {
  description = "Common resource tags."

  type    = map(string)
  default = {}
}