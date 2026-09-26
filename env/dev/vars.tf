variable "location" {
  description = "Azure region for all resources in the environment."

  type = string

  validation {
    condition = contains(
      [
        "japaneast",
        "eastus",
        "eastus2",
        "centralus",
        "westeurope",
        "uksouth"
      ],
      lower(var.location)
    )

    error_message = "location must be a supported Azure region."
  }
}

variable "environment" {
  description = "Deployment environment name."

  type = string

  validation {
    condition = contains(
      ["dev", "stage", "prod"],
      lower(var.environment)
    )

    error_message = "environment must be one of: dev, stage, or prod."
  }
}

variable "tags" {
  description = "Default tags applied to all resources."

  type    = map(string)
  default = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(trimspace(key)) > 0 &&
      length(trimspace(value)) > 0
    ])

    error_message = "Each tag key and value must be non-empty."
  }
}



# RESOURCE GROUPS
variable "resource_groups" {
  description = "Resource groups for the workload environment."

  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, rg in var.resource_groups :
      length(trimspace(rg.name)) > 0 &&
      length(trimspace(rg.location)) > 0
    ])

    error_message = "Each resource group must define a non-empty name and location."
  }
}


# STORAGE ACCOUNTS
variable "storage_accounts" {
  description = "Storage account definitions for the workload environment."

  type = map(object({
    name                            = string
    resource_group_name             = string
    account_tier                    = optional(string, "Standard")
    account_replication_type        = optional(string, "LRS")
    min_tls_version                 = optional(string, "TLS1_2")
    allow_nested_items_to_be_public = optional(bool, false)
    public_network_access_enabled   = optional(bool, true)
    tags                            = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      length(storage.name) >= 3 &&
      length(storage.name) <= 24 &&
      can(regex("^[a-z0-9]+$", storage.name))
    ])

    error_message = "Storage account names must be 3-24 characters and contain only lowercase letters and numbers."
  }

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      contains(
        ["Standard", "Premium"],
        storage.account_tier
      )
    ])

    error_message = "account_tier must be either Standard or Premium."
  }

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      contains(
        ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"],
        storage.account_replication_type
      )
    ])

    error_message = "account_replication_type must be a supported Azure replication type."
  }

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts :
      contains(
        ["TLS1_2", "TLS1_3"],
        storage.min_tls_version
      )
    ])

    error_message = "min_tls_version must be TLS1_2 or TLS1_3."
  }
}

variable "vnets" {
  description = "Map of VNets for the hub-spoke landing zone. Each VNet must use RFC1918 private address space and valid subnet ranges."

  type = map(object({
    name                = string
    resource_group_name = string
    address_space       = list(string)

    subnets = map(object({
      name                                          = string
      address_prefixes                              = list(string)
      service_endpoints                             = optional(list(string), [])
      private_endpoint_network_policies             = optional(string, "Disabled")
      private_link_service_network_policies_enabled = optional(bool, true)
    }))

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, vnet in var.vnets :
      length(vnet.address_space) > 0 &&
      alltrue([
        for cidr in vnet.address_space :
        can(cidrhost(cidr, 0))
      ]) &&
      length(vnet.subnets) > 0
    ])

    error_message = "Each VNet must define at least one valid private CIDR and at least one subnet."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      alltrue([
        for subnet_key, subnet in vnet.subnets :
        length(trimspace(subnet.name)) > 0 &&
        length(subnet.address_prefixes) > 0 &&
        alltrue([
          for cidr in subnet.address_prefixes :
          can(cidrhost(cidr, 0))
        ])
      ])
    ])

    error_message = "Each subnet must define a non-empty name and at least one valid CIDR address prefix."
  }

  validation {
    condition = alltrue([
      for vnet_key, vnet in var.vnets :
      alltrue([
        for subnet_key, subnet in vnet.subnets :
        contains(
          [
            "Disabled",
            "Enabled",
            "NetworkSecurityGroupEnabled",
            "RouteTableEnabled"
          ],
          subnet.private_endpoint_network_policies
        )
      ])
    ])

    error_message = "private_endpoint_network_policies must be Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
}

variable "public_ips" {
  description = "Public IPs used for ingress and administrative access."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Standard")
    allocation_method   = optional(string, "Static")
    zones               = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
}

# variable "firewalls" {
#   description = "Azure Firewall in the hub"
#   type = map(object({
#     name                = string
#     resource_group_name = string
#     location            = string
#     sku_name            = optional(string, "AZFW_VNet")
#     sku_tier            = optional(string, "Standard")
#     firewall_policy_id  = optional(string, null)
#     subnet_id           = string
#     public_ip_id        = string
#     tags                = optional(map(string), {})
#   }))
# }

variable "load_balancers" {
  description = "Internal Load Balancer configuration for the environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = string

    vnet_key   = string
    subnet_key = string

    frontend_ip_configuration = object({
      name               = string
      private_ip_address = string
    })

    backend_address_pool = object({
      name = string
    })

    health_probe = object({
      name                = string
      protocol            = string
      port                = number
      request_path        = string
      interval_in_seconds = number
      number_of_probes    = number
    })

    lb_rule = object({
      name                    = string
      protocol                = string
      frontend_port           = number
      backend_port            = number
      enable_floating_ip      = bool
      idle_timeout_in_minutes = number
      enable_tcp_reset        = bool
    })

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(["Basic", "Standard"], lb.sku)
    ])

    error_message = "Load Balancer SKU must be either Basic or Standard."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(["Tcp", "Udp"], lb.lb_rule.protocol)
    ])

    error_message = "Load Balancer rule protocol must be Tcp or Udp."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      contains(["Http", "Https", "Tcp"], lb.health_probe.protocol)
    ])

    error_message = "Health probe protocol must be Http, Https, or Tcp."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.frontend_ip_configuration.private_ip_address != ""
    ])

    error_message = "Every Load Balancer must have a private frontend IP address."
  }
}

variable "key_vaults" {
  description = "Key Vault definitions for the workload environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    tenant_id           = string

    sku_name = optional(string, "standard")

    purge_protection_enabled = optional(bool, true)

    soft_delete_retention_days = optional(number, 90)

    enable_rbac_authorization = optional(bool, true)

    public_network_access_enabled = optional(bool, false)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      length(trimspace(kv.name)) > 0 &&
      length(trimspace(kv.resource_group_name)) > 0 &&
      length(trimspace(kv.location)) > 0 &&
      length(trimspace(kv.tenant_id)) > 0
    ])

    error_message = "Each Key Vault must define a non-empty name, resource group name, location, and tenant ID."
  }

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      contains(
        ["standard", "premium"],
        lower(kv.sku_name)
      )
    ])

    error_message = "Key Vault sku_name must be either standard or premium."
  }

  validation {
    condition = alltrue([
      for key, kv in var.key_vaults :
      kv.soft_delete_retention_days >= 7 &&
      kv.soft_delete_retention_days <= 90
    ])

    error_message = "Key Vault soft delete retention must be between 7 and 90 days."
  }
}

variable "network_security_groups" {
  description = "Network Security Group definitions for the workload environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    security_rules = map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    }))

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, nsg in var.network_security_groups :
      length(trimspace(nsg.name)) > 0 &&
      length(trimspace(nsg.resource_group_name)) > 0 &&
      length(trimspace(nsg.location)) > 0
    ])

    error_message = "Each NSG must define a non-empty name, resource group name, and location."
  }

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      alltrue([
        for rule_key, rule in nsg.security_rules :
        rule.priority >= 100 &&
        rule.priority <= 4096 &&
        contains(["Inbound", "Outbound"], rule.direction) &&
        contains(["Allow", "Deny"], rule.access) &&
        contains(
          ["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"],
          rule.protocol
        )
      ])
    ])

    error_message = "Each NSG rule must have a priority between 100 and 4096, valid direction, access, and protocol."
  }

  validation {
    condition = alltrue([
      for nsg_key, nsg in var.network_security_groups :
      length([
        for rule_key, rule in nsg.security_rules :
        rule.priority
        ]) == length(distinct([
          for rule_key, rule in nsg.security_rules :
          rule.priority
      ]))
    ])

    error_message = "Security rule priorities must be unique within each NSG."
  }
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspace definitions for the workload environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku               = optional(string, "PerGB2018")
    retention_in_days = optional(number, 30)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, workspace in var.log_analytics_workspaces :
      length(trimspace(workspace.name)) > 0 &&
      length(trimspace(workspace.resource_group_name)) > 0 &&
      length(trimspace(workspace.location)) > 0
    ])

    error_message = "Each Log Analytics workspace must define a non-empty name, resource group name, and location."
  }

  validation {
    condition = alltrue([
      for key, workspace in var.log_analytics_workspaces :
      workspace.retention_in_days >= 30 &&
      workspace.retention_in_days <= 730
    ])

    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}

variable "application_insights" {
  description = "Application Insights definitions for the workload environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    workspace_key = string

    application_type = optional(string, "web")

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, appi in var.application_insights :
      length(trimspace(appi.name)) > 0 &&
      length(trimspace(appi.resource_group_name)) > 0 &&
      length(trimspace(appi.location)) > 0 &&
      length(trimspace(appi.workspace_key)) > 0
    ])

    error_message = "Each Application Insights resource must define a non-empty name, resource group name, location, and Log Analytics workspace key."
  }

  validation {
    condition = alltrue([
      for key, appi in var.application_insights :
      contains(
        ["web", "other"],
        lower(appi.application_type)
      )
    ])

    error_message = "Application Insights application_type must be either web or other."
  }
}


# APPLICATION GATEWAYS
# ============================================================
# APPLICATION GATEWAYS
# ============================================================

variable "application_gateways" {
  description = "Application Gateway definitions for workload ingress."

  type = map(object({

    name                = string
    resource_group_name = string
    location            = string

    # --------------------------------------------------------
    # SKU
    # --------------------------------------------------------

    sku = object({
      name     = string
      tier     = string
      capacity = number
    })

    # --------------------------------------------------------
    # WAF
    # --------------------------------------------------------

    waf_configuration = optional(object({
      enabled                  = optional(bool, true)
      firewall_mode            = optional(string, "Prevention")
      rule_set_type            = optional(string, "OWASP")
      rule_set_version         = optional(string, "3.2")
      file_upload_limit_mb     = optional(number, 100)
      request_body_check       = optional(bool, true)
      max_request_body_size_kb = optional(number, 128)
    }), null)

    # --------------------------------------------------------
    # NETWORK REFERENCES
    # --------------------------------------------------------

    vnet_key   = string
    subnet_key = string

    public_ip_key = string

    # --------------------------------------------------------
    # GATEWAY IP
    # --------------------------------------------------------

    gateway_ip_configuration = object({
      name = string
    })

    # --------------------------------------------------------
    # FRONTEND IP
    # --------------------------------------------------------

    frontend_ip_configuration = object({
      name = string
    })

    # --------------------------------------------------------
    # FRONTEND PORT
    # --------------------------------------------------------

    frontend_port = object({
      name = string
      port = number
    })

    # --------------------------------------------------------
    # HTTP LISTENER
    # --------------------------------------------------------

    http_listener = object({
      name                           = string
      frontend_ip_configuration_name = string
      frontend_port_name             = string
      protocol                       = string
    })

    # --------------------------------------------------------
    # BACKEND ADDRESS POOLS
    # --------------------------------------------------------

    backend_address_pools = map(object({
      ip_addresses = optional(list(string), [])
    }))

    # --------------------------------------------------------
    # HEALTH PROBES
    # --------------------------------------------------------

    health_probes = map(object({
      name                = string
      protocol            = string
      port                = number
      path                = string
      interval            = number
      timeout             = number
      unhealthy_threshold = number
    }))

    # --------------------------------------------------------
    # BACKEND HTTP SETTINGS
    # --------------------------------------------------------

    backend_http_settings = map(object({
      name                  = string
      cookie_based_affinity = string
      port                  = number
      protocol              = string
      request_timeout       = number
      probe_name            = string
    }))

    # --------------------------------------------------------
    # REQUEST ROUTING
    # --------------------------------------------------------

    request_routing_rule = object({
      name               = string
      priority           = number
      rule_type          = string
      http_listener_name = string

      url_path_map_name = string

      default_backend_address_pool_name  = string
      default_backend_http_settings_name = string

      path_rules = list(object({
        name                       = string
        paths                      = list(string)
        backend_address_pool_name  = string
        backend_http_settings_name = string
      }))
    })

    # --------------------------------------------------------
    # TAGS
    # --------------------------------------------------------

    tags = optional(map(string), {})
  }))

  # ==========================================================
  # BASIC VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      length(trimspace(gateway.name)) > 0 &&
      length(trimspace(gateway.resource_group_name)) > 0 &&
      length(trimspace(gateway.location)) > 0 &&
      length(trimspace(gateway.vnet_key)) > 0 &&
      length(trimspace(gateway.subnet_key)) > 0 &&
      length(trimspace(gateway.public_ip_key)) > 0
    ])

    error_message = "Each Application Gateway must define valid resource, VNet, subnet, and public IP references."
  }

  # ==========================================================
  # SKU VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      contains(
        ["Standard_v2", "WAF_v2"],
        gateway.sku.name
      ) &&
      contains(
        ["Standard_v2", "WAF_v2"],
        gateway.sku.tier
      ) &&
      gateway.sku.capacity >= 1 &&
      gateway.sku.capacity <= 125
    ])

    error_message = "Application Gateway must use Standard_v2 or WAF_v2 with capacity between 1 and 125."
  }

  # ==========================================================
  # WAF VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.waf_configuration == null ||
      (
        contains(
          ["Detection", "Prevention"],
          gateway.waf_configuration.firewall_mode
        ) &&
        gateway.waf_configuration.rule_set_type == "OWASP" &&
        gateway.waf_configuration.file_upload_limit_mb >= 1 &&
        gateway.waf_configuration.file_upload_limit_mb <= 750 &&
        gateway.waf_configuration.max_request_body_size_kb >= 8 &&
        gateway.waf_configuration.max_request_body_size_kb <= 128
      )
    ])

    error_message = "WAF configuration must use OWASP rules, Detection or Prevention mode, valid upload limits, and valid request body size."
  }

  # ==========================================================
  # FRONTEND PORT VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.frontend_port.port >= 1 &&
      gateway.frontend_port.port <= 65535
    ])

    error_message = "Application Gateway frontend port must be between 1 and 65535."
  }

  # ==========================================================
  # HEALTH PROBE VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      alltrue([
        for probe_key, probe in gateway.health_probes :
        probe.port >= 1 &&
        probe.port <= 65535 &&
        probe.interval >= 1 &&
        probe.timeout >= 1 &&
        probe.unhealthy_threshold >= 1
      ])
    ])

    error_message = "Application Gateway health probes must contain valid port, interval, timeout, and unhealthy threshold values."
  }

  # ==========================================================
  # BACKEND HTTP SETTINGS VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for gateway_key, gateway in var.application_gateways :
      alltrue([
        for settings_key, settings in gateway.backend_http_settings :
        settings.port >= 1 &&
        settings.port <= 65535 &&
        settings.request_timeout >= 1 &&
        settings.request_timeout <= 86400
      ])
    ])

    error_message = "Application Gateway backend settings must contain valid port and request timeout values."
  }

  # ==========================================================
  # ROUTING VALIDATION
  # ==========================================================

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.request_routing_rule.rule_type == "PathBasedRouting" &&
      gateway.request_routing_rule.priority >= 1 &&
      gateway.request_routing_rule.priority <= 20000
    ])

    error_message = "Application Gateway must use PathBasedRouting and routing priority must be between 1 and 20000."
  }
}

variable "network_interfaces" {
  description = "NIC definitions for VM attachments. Subnet relationships are resolved from the network module output by VNet/subnet key."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    vnet_key            = string
    subnet_key          = string
    ip_configuration = object({
      name                          = string
      private_ip_address_allocation = string
      private_ip_address            = optional(string, null)
    })
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, nic in var.network_interfaces : length(trimspace(nic.name)) > 0 && contains(["Dynamic", "Static"], nic.ip_configuration.private_ip_address_allocation) && length(trimspace(nic.vnet_key)) > 0 && length(trimspace(nic.subnet_key)) > 0
    ])
    error_message = "NIC names must be non-empty, private IP allocation must be Dynamic or Static, and both VNet and subnet keys must be provided."
  }
}

variable "linux_virtual_machines" {
  description = "Linux workload virtual machines for the environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    size                = string

    admin_username = string
    admin_password = optional(string, null)
    admin_ssh_key  = optional(string, null)

    nic_key = string

    custom_data = optional(string, null)

    identity_type = optional(string, "SystemAssigned")

    os_disk = object({
      caching              = string
      storage_account_type = string
    })

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    tags = optional(map(string), {})
  }))

  default = {}
}


variable "windows_virtual_machines" {
  description = "Windows workload virtual machines for the environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    size                = string

    admin_username = string
    admin_password = string

    nic_key = string

    custom_data = optional(string, null)

    identity_type = optional(string, "SystemAssigned")

    os_disk = object({
      caching              = string
      storage_account_type = string
    })

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    tags = optional(map(string), {})
  }))

  default = {}
}

# ============================================================
# SUBNET -> NSG ASSOCIATIONS
# ============================================================

variable "subnet_nsg_associations" {
  description = "Map of subnet-to-NSG associations. References use logical keys exposed by the network and NSG modules."

  type = map(object({
    subnet_name                 = string
    network_security_group_name = string
  }))

  validation {
    condition = alltrue([
      for key, association in var.subnet_nsg_associations :
      length(trimspace(association.subnet_name)) > 0 &&
      length(trimspace(association.network_security_group_name)) > 0
    ])

    error_message = "Each subnet-to-NSG association must define a non-empty subnet key and NSG key."
  }
}
variable "private_endpoints" {
  description = "Generic Azure Private Endpoints. Target resources are resolved from Terraform module outputs using a logical target key."

  type = map(object({
    name                = string
    location            = string
    resource_group_name = string

    vnet_key   = string
    subnet_key = string

    target_key = string

    private_service_connection = object({
      name                 = string
      is_manual_connection = optional(bool, false)
      subresource_names    = list(string)
      request_message      = optional(string, null)
    })

    private_dns_zone_key = optional(string, null)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, endpoint in var.private_endpoints :
      length(trimspace(endpoint.name)) > 0 &&
      length(trimspace(endpoint.location)) > 0 &&
      length(trimspace(endpoint.resource_group_name)) > 0 &&
      length(trimspace(endpoint.vnet_key)) > 0 &&
      length(trimspace(endpoint.subnet_key)) > 0 &&
      length(trimspace(endpoint.target_key)) > 0 &&
      length(trimspace(endpoint.private_service_connection.name)) > 0 &&
      length(endpoint.private_service_connection.subresource_names) > 0
    ])

    error_message = "Each private endpoint must define name, location, resource group, VNet key, subnet key, target key, service connection name, and at least one subresource."
  }
}

variable "private_dns_zones" {
  description = "Private DNS zones used by Azure Private Endpoints."

  type = map(object({
    name                = string
    resource_group_name = string
    vnet_key            = string
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, zone in var.private_dns_zones :
      length(trimspace(zone.name)) > 0 &&
      can(regex(
        "^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$",
        trimspace(zone.name)
      )) &&
      length(trimspace(zone.resource_group_name)) > 0 &&
      length(trimspace(zone.vnet_key)) > 0
    ])

    error_message = "Each Private DNS zone must define a valid DNS zone name, resource group name, and VNet key."
  }
}

variable "bastions" {
  description = "Azure Bastion hosts for secure administrative access. VNet/subnet and public IP relationships are resolved from outputs by key."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    vnet_key            = string
    subnet_key          = string
    public_ip_key       = string
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, bastion in var.bastions :
      length(trimspace(bastion.name)) > 0 &&
      length(trimspace(bastion.resource_group_name)) > 0 &&
      length(trimspace(bastion.location)) > 0 &&
      length(trimspace(bastion.vnet_key)) > 0 &&
      length(trimspace(bastion.subnet_key)) > 0 &&
      length(trimspace(bastion.public_ip_key)) > 0
    ])

    error_message = "Bastion name, resource group, location, VNet/subnet keys, and public IP key must be defined."
  }
}




variable "sql_servers" {
  description = "Azure SQL logical servers for the workload environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    version                       = optional(string, "12.0")
    administrator_login           = string
    administrator_login_password  = string
    minimum_tls_version           = optional(string, "1.2")
    public_network_access_enabled = optional(bool, false)

    tags = optional(map(string), {})
  }))

  # sensitive = true

  validation {
    condition = alltrue([
      for key, server in var.sql_servers :
      length(trimspace(server.name)) > 0 &&
      length(trimspace(server.resource_group_name)) > 0 &&
      length(trimspace(server.location)) > 0 &&
      length(trimspace(server.administrator_login)) > 0 &&
      length(server.administrator_login_password) >= 12
    ])

    error_message = "Each SQL Server must have a valid name, resource group, location, administrator login, and password of at least 12 characters."
  }
}

variable "sql_databases" {
  description = "Azure SQL databases for the workload environment."

  type = map(object({
    name                 = string
    sql_server_key       = string
    sku_name             = string
    max_size_gb          = optional(number, 32)
    zone_redundant       = optional(bool, false)
    storage_account_type = optional(string, "Geo")
    collation            = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    read_scale           = optional(bool, false)
    geo_backup_enabled   = optional(bool, true)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, database in var.sql_databases :
      length(trimspace(database.name)) > 0 &&
      length(trimspace(database.sql_server_key)) > 0 &&
      length(trimspace(database.sku_name)) > 0 &&
      database.max_size_gb > 0
    ])

    error_message = "Each SQL database must have a valid name, SQL Server key, SKU, and positive max_size_gb."
  }
}

variable "postgresql_servers" {
  description = "Azure Database for PostgreSQL Flexible Servers for the workload environment."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    version    = optional(string, "16")
    sku_name   = string
    storage_mb = optional(number, 32768)

    administrator_login    = string
    administrator_password = string

    backup_retention_days        = optional(number, 7)
    geo_redundant_backup_enabled = optional(bool, false)

    public_network_access_enabled = optional(bool, false)

    zone = optional(string, null)

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, server in var.postgresql_servers :
      length(trimspace(server.name)) > 0 &&
      length(trimspace(server.resource_group_name)) > 0 &&
      length(trimspace(server.location)) > 0 &&
      length(trimspace(server.administrator_login)) > 0 &&
      length(server.administrator_password) >= 12 &&
      length(trimspace(server.sku_name)) > 0
    ])

    error_message = "Each PostgreSQL server must define a valid name, resource group, location, administrator login, password of at least 12 characters, and SKU."
  }
}


variable "postgresql_databases" {
  description = "PostgreSQL databases for the workload environment."

  type = map(object({
    name                  = string
    postgresql_server_key = string

    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, database in var.postgresql_databases :
      length(trimspace(database.name)) > 0 &&
      length(trimspace(database.postgresql_server_key)) > 0
    ])

    error_message = "Each PostgreSQL database must define a valid name and PostgreSQL server key."
  }
}