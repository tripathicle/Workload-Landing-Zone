# Resource: azurerm_lb
# Description: Creates an internal Azure Load Balancer for the backend tier.
# ## Arguments Reference
# - name: (Required) Load balancer name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Resource group name.
# - sku: (Optional) Load balancer SKU, typically Standard.
# - frontend_ip_configuration: (Required) Frontend IP configuration for the LB.
# - tags: (Optional) Resource tags.
resource "azurerm_lb" "this" {
  for_each = var.load_balancers

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku

  frontend_ip_configuration {
    name                 = each.value.frontend_ip_configuration.name
    subnet_id            = each.value.frontend_ip_configuration.subnet_id
    private_ip_address   = each.value.frontend_ip_configuration.private_ip_address
    private_ip_address_allocation = "Static"
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = var.load_balancers

  loadbalancer_id = azurerm_lb.this[each.key].id
  name            = each.value.backend_address_pool.name
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each = merge([
    for lb_key, lb in var.load_balancers : {
      for ip_index, ip in lookup(lb.backend_address_pool, "ip_addresses", []) :
      "${lb_key}-${ip_index}" => {
        lb_key     = lb_key
        ip_address = ip
      }
    }
  ]...)

  name                    = "${each.value.lb_key}-backend-${each.key}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[each.value.lb_key].id
  ip_address              = each.value.ip_address
}

resource "azurerm_lb_probe" "this" {
  for_each = var.load_balancers

  loadbalancer_id = azurerm_lb.this[each.key].id
  name            = each.value.health_probe.name
  protocol        = each.value.health_probe.protocol
  port            = each.value.health_probe.port
}

resource "azurerm_lb_rule" "this" {
  for_each = var.load_balancers

  loadbalancer_id                = azurerm_lb.this[each.key].id
  name                           = each.value.lb_rule.name
  protocol                       = each.value.lb_rule.protocol
  frontend_port                  = each.value.lb_rule.frontend_port
  backend_port                   = each.value.lb_rule.backend_port
  frontend_ip_configuration_name = each.value.lb_rule.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this[each.key].id]
  probe_id                       = azurerm_lb_probe.this[each.key].id
  load_distribution              = each.value.lb_rule.load_distribution
  disable_outbound_snat          = false
}
