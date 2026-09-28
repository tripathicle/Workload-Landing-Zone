# ============================================================
# MODULE: RESOURCE GROUP
# FILE: Modules/resource_group/main.tf
# ============================================================
#
# Purpose:
#   Provisions one or more Azure Resource Groups using a
#   reusable map-based input.
#
# Design:
#   - for_each based
#   - reusable across dev/stage/prod
#   - common tags + resource-specific tags
#   - resource-specific tags override common tags
#
# ============================================================

resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups

  name     = each.value.name
  location = each.value.location

  tags = merge(
    var.tags,
    each.value.tags
  )
}