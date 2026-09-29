resource "azurerm_lb" "this" {
  for_each = var.load_balancers

  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name

  sku = each.value.sku

  frontend_ip_configuration {
    name                          = each.value.frontend_ip_configuration_name
    subnet_id                     = var.subnets[each.value.subnet_key].id
    private_ip_address            = each.value.private_ip_address
    private_ip_address_allocation = "Static"
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = var.load_balancers

  name            = each.value.backend_pool_name
  loadbalancer_id = azurerm_lb.this[each.key].id
}

resource "azurerm_lb_probe" "this" {
  for_each = var.load_balancers

  name            = each.value.health_probe.name
  loadbalancer_id = azurerm_lb.this[each.key].id

  protocol            = each.value.health_probe.protocol
  port                = each.value.health_probe.port
  request_path        = each.value.health_probe.request_path
  interval_in_seconds = each.value.health_probe.interval_in_seconds
  number_of_probes    = each.value.health_probe.number_of_probes
}

resource "azurerm_lb_rule" "this" {
  for_each = var.load_balancers

  name            = each.value.load_balancing_rule.name
  loadbalancer_id = azurerm_lb.this[each.key].id

  protocol                       = each.value.load_balancing_rule.protocol
  frontend_port                  = each.value.load_balancing_rule.frontend_port
  backend_port                   = each.value.load_balancing_rule.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.this[each.key].id
  ]
  probe_id = azurerm_lb_probe.this[each.key].id

  idle_timeout_in_minutes = each.value.load_balancing_rule.idle_timeout_in_minutes
}