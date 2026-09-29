# ============================================================
# WEB APPLICATION FIREWALL POLICY
# ============================================================

resource "azurerm_web_application_firewall_policy" "this" {
  for_each = {
    for gateway_key, gateway in var.application_gateways :
    gateway_key => gateway
    if gateway.waf_policy != null
  }

  name = "wafpol-${each.value.name}"

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  # ==========================================================
  # WAF POLICY SETTINGS
  # ==========================================================

  policy_settings {
    enabled = each.value.waf_policy.enabled
    mode    = each.value.waf_policy.firewall_mode
  }

  # ==========================================================
  # MANAGED RULES
  # OWASP 3.2
  # ==========================================================

  managed_rules {
    managed_rule_set {
      type    = each.value.waf_policy.rule_set_type
      version = each.value.waf_policy.rule_set_version
    }
  }

  tags = var.tags
}


# ============================================================
# APPLICATION GATEWAY
# ============================================================

resource "azurerm_application_gateway" "this" {
  for_each = var.application_gateways

  name                = each.value.name
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  location            = var.resource_groups[each.value.resource_group_key].location

  # ==========================================================
  # WAF POLICY ASSOCIATION
  # ==========================================================

  firewall_policy_id = (
    each.value.waf_policy != null
    ? azurerm_web_application_firewall_policy.this[each.key].id
    : null
  )

  # ==========================================================
  # SKU
  # ==========================================================

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    capacity = each.value.sku.capacity
  }

  # ==========================================================
  # GATEWAY IP CONFIGURATION
  # ==========================================================

  gateway_ip_configuration {
    name      = each.value.gateway_ip_configuration_name
    subnet_id = var.subnets[each.value.subnet_key].id
  }

  # ==========================================================
  # PUBLIC FRONTEND IP
  # ==========================================================

  frontend_ip_configuration {
    name                 = each.value.frontend_ip_configuration_name
    public_ip_address_id = var.public_ips[each.value.public_ip_key].id
  }

  # ==========================================================
  # FRONTEND PORT
  # ==========================================================

  frontend_port {
    name = each.value.frontend_port_name
    port = each.value.frontend_port
  }

  # ==========================================================
  # FRONTEND BACKEND POOL
  # FE-01 + FE-02
  # ==========================================================

  backend_address_pool {
    name = each.value.frontend_backend.name

    ip_addresses = each.value.frontend_backend.ip_addresses
  }

  # ==========================================================
  # BACKEND POOL
  # Internal Load Balancer 10.20.2.10
  # ==========================================================

  backend_address_pool {
    name = each.value.backend_backend.name

    ip_addresses = each.value.backend_backend.ip_addresses
  }

  # ==========================================================
  # FRONTEND HEALTH PROBE
  # FE VMs :80 /
  # ==========================================================

  probe {
    name     = each.value.frontend_backend.probe_name
    protocol = "Http"

    host = "localhost"

    path = each.value.frontend_backend.probe_path

    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = [
        "200-399"
      ]
    }
  }

  # ==========================================================
  # BACKEND HEALTH PROBE
  # Internal LB :8080 /health
  # ==========================================================

  probe {
    name     = each.value.backend_backend.probe_name
    protocol = "Http"

    host = "localhost"

    path = each.value.backend_backend.probe_path

    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = [
        "200-399"
      ]
    }
  }

  # ==========================================================
  # FRONTEND HTTP SETTINGS
  # App Gateway -> FE VMs :80
  # ==========================================================

  backend_http_settings {
    name                  = each.value.frontend_backend.http_settings_name
    cookie_based_affinity = "Disabled"

    port     = each.value.frontend_backend.http_settings_port
    protocol = "Http"

    request_timeout = 30
    probe_name      = each.value.frontend_backend.probe_name
  }

  # ==========================================================
  # BACKEND HTTP SETTINGS
  # App Gateway -> Internal LB :8080
  # ==========================================================

  backend_http_settings {
    name                  = each.value.backend_backend.http_settings_name
    cookie_based_affinity = "Disabled"

    port     = each.value.backend_backend.http_settings_port
    protocol = "Http"

    request_timeout = 30
    probe_name      = each.value.backend_backend.probe_name
  }

  # ==========================================================
  # HTTP LISTENER
  # Internet -> App Gateway :80
  # ==========================================================

  http_listener {
    name = each.value.http_listener_name

    frontend_ip_configuration_name = (
      each.value.frontend_ip_configuration_name
    )

    frontend_port_name = each.value.frontend_port_name

    protocol = "Http"
  }

  # ==========================================================
  # URL PATH MAP
  #
  # /api/* -> Backend LB
  # default -> Frontend VMs
  # ==========================================================

  url_path_map {
    name = each.value.path_map_name

    default_backend_address_pool_name = (
      each.value.default_backend_address_pool_name
    )

    default_backend_http_settings_name = (
      each.value.default_backend_http_settings_name
    )

    dynamic "path_rule" {
      for_each = each.value.path_rules

      content {
        name = path_rule.value.name

        paths = path_rule.value.paths

        backend_address_pool_name = (
          path_rule.value.backend_address_pool_name
        )

        backend_http_settings_name = (
          path_rule.value.backend_http_settings_name
        )
      }
    }
  }

  # ==========================================================
  # REQUEST ROUTING RULE
  # Path Based Routing
  # ==========================================================

  request_routing_rule {
    name     = each.value.request_routing_rule_name
    priority = each.value.request_routing_rule_priority

    rule_type = "PathBasedRouting"

    http_listener_name = each.value.http_listener_name
    url_path_map_name  = each.value.path_map_name
  }

  # ==========================================================
  # TAGS
  # ==========================================================

  tags = var.tags
}