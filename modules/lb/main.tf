# ============================================================
# AZURE INTERNAL LOAD BALANCER
# ============================================================

resource "azurerm_lb" "this" {
  for_each = var.load_balancers

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku

  # ----------------------------------------------------------
  # PRIVATE FRONTEND
  # ----------------------------------------------------------

  frontend_ip_configuration {
    name = each.value.frontend_ip_configuration.name

    subnet_id = each.value.frontend_ip_configuration.subnet_id

    private_ip_address = each.value.frontend_ip_configuration.private_ip_address

    private_ip_address_allocation = "Static"
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}

# ============================================================
# BACKEND ADDRESS POOL
# ============================================================

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = var.load_balancers

  name            = each.value.backend_address_pool.name
  loadbalancer_id = azurerm_lb.this[each.key].id
}

# ============================================================
# BACKEND ADDRESS POOL MEMBERS
# ============================================================

resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for ip in lb.backend_address_pool.ip_addresses : {
          key                = "${lb_key}-${replace(ip, ".", "-")}"
          load_balancer_key  = lb_key
          ip_address         = ip
          virtual_network_id = lb.frontend_ip_configuration.vnet_id
        }
      ]
    ]) : item.key => item
  }

  name = each.key

  backend_address_pool_id = azurerm_lb_backend_address_pool.this[
    each.value.load_balancer_key
  ].id

  ip_address         = each.value.ip_address
  virtual_network_id = each.value.virtual_network_id
}

# ============================================================
# HEALTH PROBE
# ============================================================

resource "azurerm_lb_probe" "this" {
  for_each = var.load_balancers

  name            = each.value.health_probe.name
  loadbalancer_id = azurerm_lb.this[each.key].id

  protocol = each.value.health_probe.protocol
  port     = each.value.health_probe.port

  request_path = (
    each.value.health_probe.protocol == "Http" ||
    each.value.health_probe.protocol == "Https"
  ) ? each.value.health_probe.request_path : null

  interval_in_seconds = each.value.health_probe.interval_in_seconds
  number_of_probes    = each.value.health_probe.number_of_probes
}

# ============================================================
# LOAD BALANCER RULE
# ============================================================

resource "azurerm_lb_rule" "this" {
  for_each = var.load_balancers

  name            = each.value.lb_rule.name
  loadbalancer_id = azurerm_lb.this[each.key].id

  protocol                       = each.value.lb_rule.protocol
  frontend_port                  = each.value.lb_rule.frontend_port
  backend_port                   = each.value.lb_rule.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration.name

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.this[each.key].id
  ]

  probe_id = azurerm_lb_probe.this[each.key].id

  # AzureRM 5.x
  floating_ip_enabled     = each.value.lb_rule.floating_ip_enabled
  idle_timeout_in_minutes = each.value.lb_rule.idle_timeout_in_minutes
  tcp_reset_enabled       = each.value.lb_rule.tcp_reset_enabled
}