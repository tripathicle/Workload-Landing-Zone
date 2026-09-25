# Resource: azurerm_lb
# Description: Creates an internal Azure Load Balancer for the backend tier.
# ## Arguments Reference
# - name: (Required) Load balancer name.
# - location: (Required) Azure region.
# - resource_group_name: (Required) Resource group name.
# - sku: (Optional) Load balancer SKU, typically Standard.
# - frontend_ip_configuration: (Required) Frontend IP configuration for the LB.
# - tags: (Optional) Resource tags.



# Creates a reusable Azure Internal Load Balancer.
# The module supports:
# - Private frontend IP
# - Backend VM private IP registration
# - HTTP health probe
# - TCP load-balancing rule
#
# This module does NOT create:
# - Public IP
# - NSG
# - VM/NIC
# - Subnet
#
# Those resources remain owned by their respective modules.

resource "azurerm_lb" "this" {
  for_each = var.load_balancers

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku

  frontend_ip_configuration {
    name = each.value.frontend_ip_configuration.name

    # The subnet is resolved by the parent environment.
    # This keeps the child module reusable and prevents
    # hardcoding VNet/subnet names inside the module.
    subnet_id = each.value.frontend_ip_configuration.subnet_id

    # The ILB uses a fixed private IP.
    private_ip_address = each.value.frontend_ip_configuration.private_ip_address

    private_ip_address_allocation = "Static"
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}

resource "azurerm_lb_backend_address_pool" "this" {
  for_each = var.load_balancers

  name            = each.value.backend_address_pool.name
  loadbalancer_id = azurerm_lb.this[each.key].id
}

# Registers backend VM private IP addresses in the backend pool.
#
# We intentionally register IP addresses instead of NIC references.
# This makes the LB module independent from the NIC module implementation.
resource "azurerm_lb_backend_address_pool_address" "this" {
  for_each = {
    for item in flatten([
      for lb_key, lb in var.load_balancers : [
        for ip in lb.backend_address_pool.ip_addresses : {
          key                 = "${lb_key}-${replace(ip, ".", "-")}"
          load_balancer_key   = lb_key
          ip_address          = ip
          virtual_network_id  = lb.frontend_ip_configuration.vnet_id
        }
      ]
    ]) : item.key => item
  }

  name                    = each.key
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[
    each.value.load_balancer_key
  ].id

  ip_address         = each.value.ip_address
  virtual_network_id = each.value.virtual_network_id
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

  enable_floating_ip       = each.value.lb_rule.enable_floating_ip
  idle_timeout_in_minutes  = each.value.lb_rule.idle_timeout_in_minutes
  enable_tcp_reset         = each.value.lb_rule.enable_tcp_reset
}