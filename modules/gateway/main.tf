# ============================================================
# AZURE APPLICATION GATEWAY
# ============================================================

resource "azurerm_application_gateway" "this" {
  for_each = var.application_gateways

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  # ----------------------------------------------------------
  # SKU
  # ----------------------------------------------------------

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    capacity = each.value.sku.capacity
  }

  # ----------------------------------------------------------
  # WAF
  # ----------------------------------------------------------

  dynamic "waf_configuration" {
    for_each = each.value.waf_configuration != null ? [each.value.waf_configuration] : []

    content {
      enabled                  = waf_configuration.value.enabled
      firewall_mode            = waf_configuration.value.firewall_mode
      rule_set_type            = waf_configuration.value.rule_set_type
      rule_set_version         = waf_configuration.value.rule_set_version
      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      request_body_check       = waf_configuration.value.request_body_check
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb
    }
  }

  # ----------------------------------------------------------
  # GATEWAY IP CONFIGURATION
  # ----------------------------------------------------------

  gateway_ip_configuration {
    name      = each.value.gateway_ip_configuration.name
    subnet_id = each.value.gateway_ip_configuration.subnet_id
  }

  # ----------------------------------------------------------
  # FRONTEND IP
  # ----------------------------------------------------------

  frontend_ip_configuration {
    name                 = each.value.frontend_ip_configuration.name
    public_ip_address_id = each.value.frontend_ip_configuration.public_ip_address_id
  }

  # ----------------------------------------------------------
  # FRONTEND PORT
  # ----------------------------------------------------------

  frontend_port {
    name = each.value.frontend_port.name
    port = each.value.frontend_port.port
  }

  # ----------------------------------------------------------
  # HTTP LISTENER
  # ----------------------------------------------------------

  http_listener {
    name                           = each.value.http_listener.name
    frontend_ip_configuration_name = each.value.http_listener.frontend_ip_configuration_name
    frontend_port_name             = each.value.http_listener.frontend_port_name
    protocol                       = each.value.http_listener.protocol
  }

  # ==========================================================
  # BACKEND ADDRESS POOLS
  # ==========================================================

  dynamic "backend_address_pool" {
    for_each = each.value.backend_address_pools

    content {
      name         = backend_address_pool.key
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  # ==========================================================
  # HEALTH PROBES
  # ==========================================================

  dynamic "probe" {
    for_each = each.value.health_probes

    content {
      name                = probe.value.name
      protocol            = probe.value.protocol
      port                = probe.value.port
      path                = probe.value.path
      interval            = probe.value.interval
      timeout             = probe.value.timeout
      unhealthy_threshold = probe.value.unhealthy_threshold
    }
  }

  # ==========================================================
  # BACKEND HTTP SETTINGS
  # ==========================================================

  dynamic "backend_http_settings" {
    for_each = each.value.backend_http_settings

    content {
      name                  = backend_http_settings.value.name
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity
      port                  = backend_http_settings.value.port
      protocol              = backend_http_settings.value.protocol
      request_timeout       = backend_http_settings.value.request_timeout
      probe_name            = backend_http_settings.value.probe_name
    }
  }

  # ==========================================================
  # URL PATH MAP
  # ==========================================================
  #
  # Default:
  #   / -> frontend
  #
  # Path:
  #   /api/* -> backend
  #
  # ==========================================================

  dynamic "url_path_map" {
    for_each = [
      each.value.request_routing_rule
    ]

    content {
      name = url_path_map.value.url_path_map_name

      default_backend_address_pool_name = (
        url_path_map.value.default_backend_address_pool_name
      )

      default_backend_http_settings_name = (
        url_path_map.value.default_backend_http_settings_name
      )

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules

        content {
          name  = path_rule.value.name
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
  }

  # ==========================================================
  # REQUEST ROUTING RULE
  # ==========================================================

  request_routing_rule {
    name               = each.value.request_routing_rule.name
    priority           = each.value.request_routing_rule.priority
    rule_type          = each.value.request_routing_rule.rule_type
    http_listener_name = each.value.request_routing_rule.http_listener_name

    url_path_map_name = each.value.request_routing_rule.url_path_map_name
  }

  # ----------------------------------------------------------
  # TAGS
  # ----------------------------------------------------------

  tags = merge(
    var.tags,
    each.value.tags
  )
}