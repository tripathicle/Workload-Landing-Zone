# ============================================================
# MODULE: RESOURCE GROUP
# FILE: Modules/resource_group/variables.tf
# ============================================================
#
# Purpose:
#   Defines the reusable input contract and validations for
#   Azure Resource Groups.
#
# ============================================================


# ============================================================
# RESOURCE GROUPS
# ============================================================

variable "resource_groups" {
  description = "Map of Azure Resource Groups to provision."

  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))

  # ----------------------------------------------------------
  # Validation 01:
  # At least one Resource Group must be provided.
  # ----------------------------------------------------------

  validation {
    condition = length(var.resource_groups) > 0

    error_message = "At least one resource group must be defined."
  }

  # ----------------------------------------------------------
  # Validation 02:
  # Resource Group map keys must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key in keys(var.resource_groups) :
      length(trimspace(resource_group_key)) > 0
    ])

    error_message = "Each resource group map key must be a non-empty string."
  }

  # ----------------------------------------------------------
  # Validation 03:
  # Resource Group name must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      length(trimspace(resource_group.name)) > 0
    ])

    error_message = "Each resource group must define a non-empty name."
  }

  # ----------------------------------------------------------
  # Validation 04:
  # Resource Group name length.
  #
  # Azure Resource Group names have a maximum length of
  # 90 characters.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      length(resource_group.name) <= 90
    ])

    error_message = "Each resource group name must be 90 characters or fewer."
  }

  # ----------------------------------------------------------
  # Validation 05:
  # Resource Group name character validation.
  #
  # Allowed:
  #   A-Z
  #   a-z
  #   0-9
  #   .
  #   _
  #   -
  #   (
  #   )
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      can(regex(
        "^[A-Za-z0-9._()\\-]+$",
        resource_group.name
      ))
    ])

    error_message = "Each resource group name may contain only letters, numbers, periods, underscores, hyphens, and parentheses."
  }

  # ----------------------------------------------------------
  # Validation 06:
  # Resource Group location must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      length(trimspace(resource_group.location)) > 0
    ])

    error_message = "Each resource group must define a non-empty Azure location."
  }

  # ----------------------------------------------------------
  # Validation 07:
  # Resource Group location must not contain invalid
  # control characters.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      can(regex(
        "^[A-Za-z0-9 ._-]+$",
        trimspace(resource_group.location)
      ))
    ])

    error_message = "Each resource group location must contain a valid Azure region name."
  }

  # ----------------------------------------------------------
  # Validation 08:
  # Resource-specific tag keys and values must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      alltrue([
        for tag_key, tag_value in resource_group.tags :
        length(trimspace(tag_key)) > 0 &&
        length(trimspace(tag_value)) > 0
      ])
    ])

    error_message = "Each resource group tag key and value must be non-empty."
  }

  # ----------------------------------------------------------
  # Validation 09:
  # Resource-specific tag keys must not contain control
  # characters.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for resource_group_key, resource_group in var.resource_groups :
      alltrue([
        for tag_key, tag_value in resource_group.tags :
        can(regex(
          "^[A-Za-z0-9_.:/+=@\\- ]+$",
          tag_key
        ))
      ])
    ])

    error_message = "Resource group tag keys contain unsupported characters."
  }
}


# ============================================================
# COMMON TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to all Azure Resource Groups."

  type    = map(string)
  default = {}

  # ----------------------------------------------------------
  # Validation 01:
  # Common tag keys and values must be non-empty.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      length(trimspace(tag_key)) > 0 &&
      length(trimspace(tag_value)) > 0
    ])

    error_message = "Each common tag key and value must be non-empty."
  }

  # ----------------------------------------------------------
  # Validation 02:
  # Common tag keys must use supported characters.
  # ----------------------------------------------------------

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags :
      can(regex(
        "^[A-Za-z0-9_.:/+=@\\- ]+$",
        tag_key
      ))
    ])

    error_message = "Common tag keys contain unsupported characters."
  }
}