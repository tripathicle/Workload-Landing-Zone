variable "log_analytics_workspaces" {
  description = "Map of Log Analytics workspaces"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "PerGB2018")
    retention_in_days   = optional(number, 30)
    tags                = optional(map(string), {})
  }))
}

variable "application_insights" {
  description = "Map of Application Insights resources"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    workspace_id        = string
    application_type    = optional(string, "web")
    tags                = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to monitoring resources"
  type        = map(string)
  default     = {}
}
