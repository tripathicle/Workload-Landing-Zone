# ============================================================
# APPLICATION GATEWAY WAF POLICY
# ============================================================

resource "azurerm_web_application_firewall_policy" "this" {
  for_each = {
    for gateway_key, gateway in var.application_gateways :
    gateway_key => gateway
    if gateway.waf_policy != null
  }

  #checkov:skip=CKV_AZURE_135:Checkov does not recognize the current OWASP 3.2 WAF managed-rule configuration; no Log4j protection rule is explicitly disabled.

  name = "wafpol-${each.value.name}"

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  policy_settings {
    enabled = each.value.waf_policy.enabled
    mode    = each.value.waf_policy.firewall_mode
  }

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
  #checkov:skip=CKV_AZURE_120:WAF is enabled through the dedicated azurerm_web_application_firewall_policy resource and attached through firewall_policy_id; Checkov does not detect this cross-resource association reliably.
  #checkov:skip=CKV_AZURE_217:Development environment intentionally exposes an HTTP listener on port 80; HTTPS termination requires a certificate source that is not part of the current dev architecture.
  #checkov:skip=CKV_AZURE_218:Development environment intentionally uses HTTP between Application Gateway and the workload backends; backend TLS is not configured in the current dev architecture.

  for_each = var.application_gateways

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    capacity = each.value.sku.capacity
  }

  # ----------------------------------------------------------
  # Gateway IP Configuration
  # ----------------------------------------------------------

  gateway_ip_configuration {
    name = each.value.gateway_ip_configuration_name

    subnet_id = var.subnets[
      each.value.subnet_key
    ].id
  }

  # ----------------------------------------------------------
  # Frontend Port
  # ----------------------------------------------------------

  frontend_port {
    name = each.value.frontend_port_name
    port = each.value.frontend_port
  }

  # ----------------------------------------------------------
  # Frontend Public IP
  # ----------------------------------------------------------

  frontend_ip_configuration {
    name = each.value.frontend_ip_configuration_name

    public_ip_address_id = var.public_ips[
      each.value.public_ip_key
    ].id
  }

  # ----------------------------------------------------------
  # Frontend Backend Pool
  # ----------------------------------------------------------

  backend_address_pool {
    name         = each.value.frontend_backend.name
    ip_addresses = each.value.frontend_backend.ip_addresses
  }

  # ----------------------------------------------------------
  # Backend ILB Pool
  # ----------------------------------------------------------

  backend_address_pool {
    name         = each.value.backend_backend.name
    ip_addresses = each.value.backend_backend.ip_addresses
  }

  # ----------------------------------------------------------
  # Frontend Health Probe
  # ----------------------------------------------------------

  probe {
    name                                      = each.value.frontend_backend.probe_name
    protocol                                  = "Http"
    host                                      = "127.0.0.1"
    path                                      = each.value.frontend_backend.probe_path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
  }

  # ----------------------------------------------------------
  # Backend Health Probe
  # ----------------------------------------------------------

  probe {
    name                                      = each.value.backend_backend.probe_name
    protocol                                  = "Http"
    host                                      = "127.0.0.1"
    path                                      = each.value.backend_backend.probe_path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
  }

  # ----------------------------------------------------------
  # Frontend HTTP Settings
  # ----------------------------------------------------------

  backend_http_settings {
    name                  = each.value.frontend_backend.http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = each.value.frontend_backend.http_settings_port
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = each.value.frontend_backend.probe_name
  }

  # ----------------------------------------------------------
  # Backend HTTP Settings
  # ----------------------------------------------------------

  backend_http_settings {
    name                  = each.value.backend_backend.http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = each.value.backend_backend.http_settings_port
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = each.value.backend_backend.probe_name
  }

  # ----------------------------------------------------------
  # HTTP Listener
  # ----------------------------------------------------------

  http_listener {
    name                           = each.value.http_listener_name
    frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
    frontend_port_name             = each.value.frontend_port_name
    protocol                       = "Http"
  }

  # ----------------------------------------------------------
  # URL Path Map
  #
  # Default:
  #   /       -> Frontend VMs
  #
  # Path:
  #   /api/*  -> Backend ILB
  # ----------------------------------------------------------

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

  # ----------------------------------------------------------
  # Request Routing Rule
  # ----------------------------------------------------------

  request_routing_rule {
    name               = each.value.request_routing_rule_name
    priority           = each.value.request_routing_rule_priority
    rule_type          = "PathBasedRouting"
    http_listener_name = each.value.http_listener_name
    url_path_map_name  = each.value.path_map_name
  }

  # ----------------------------------------------------------
  # WAF Policy Association
  # ----------------------------------------------------------

  firewall_policy_id = try(
    azurerm_web_application_firewall_policy.this[each.key].id,
    null
  )

  tags = var.tags
}