# ============================================================
# ENVIRONMENT
# ============================================================

variable "environment" {
  description = "Deployment environment."

  type = string

  validation {
    condition = contains(
      [
        "dev",
        "stage",
        "prod"
      ],
      var.environment
    )

    error_message = "Environment must be one of: dev, stage, prod."
  }
}


# ============================================================
# COMMON TAGS
# ============================================================

variable "tags" {
  description = "Common tags applied to all resources."

  type    = map(string)
  default = {}
}


# ============================================================
# RESOURCE GROUPS
# ============================================================

variable "resource_groups" {
  description = "Resource Groups to create."

  type = map(object({
    name     = string
    location = string
  }))

  validation {
    condition = length(var.resource_groups) > 0

    error_message = "At least one Resource Group must be defined."
  }

  validation {
    condition = alltrue([
      for key, resource_group in var.resource_groups :
      length(trimspace(resource_group.name)) > 0
    ])

    error_message = "Each Resource Group must define a non-empty name."
  }
}


# ============================================================
# STORAGE ACCOUNTS
# ============================================================

variable "storage_accounts" {
  description = "Storage Account configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")

    min_tls_version = optional(
      string,
      "TLS1_2"
    )

    allow_nested_items_to_be_public = optional(
      bool,
      false
    )

    public_network_access_enabled = optional(
      bool,
      false
    )

    cross_tenant_replication_enabled = optional(
      bool,
      false
    )
  }))

  validation {
    condition = length(var.storage_accounts) > 0

    error_message = "At least one Storage Account must be defined."
  }
}

# ============================================================
# STORAGE CONTAINERS
# ============================================================

variable "storage_containers" {
  description = "Storage container configuration."

  type = map(object({
    name                  = string
    storage_account_key   = string
    container_access_type = optional(string, "private")
  }))

  default = {}

  validation {
    condition = alltrue([
      for key, container in var.storage_containers :
      length(trimspace(container.name)) > 0
    ])

    error_message = "Each storage container must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for key, container in var.storage_containers :
      length(trimspace(container.storage_account_key)) > 0
    ])

    error_message = "Each storage container must reference a non-empty storage_account_key."
  }

  validation {
    condition = alltrue([
      for key, container in var.storage_containers :
      contains(
        ["private", "blob", "container"],
        container.container_access_type
      )
    ])

    error_message = "Storage container access type must be private, blob, or container."
  }
}


# ============================================================
# VIRTUAL NETWORKS
# ============================================================

variable "vnets" {
  description = "Virtual Network configuration."

  type = map(object({
    name               = string
    resource_group_key = string
    address_space      = list(string)
  }))

  validation {
    condition = length(var.vnets) > 0

    error_message = "At least one Virtual Network must be defined."
  }

  validation {
    condition = alltrue([
      for key, vnet in var.vnets :
      length(vnet.address_space) > 0
    ])

    error_message = "Each VNet must define at least one address space."
  }
}


# ============================================================
# SUBNETS
# ============================================================

variable "subnets" {
  description = "Subnet configuration."

  type = map(object({
    name     = string
    vnet_key = string

    address_prefixes = list(string)

    private_endpoint_network_policies = optional(
      string,
      "Disabled"
    )

    private_link_service_network_policies_enabled = optional(
      bool,
      true
    )
  }))

  validation {
    condition = length(var.subnets) > 0

    error_message = "At least one subnet must be defined."
  }

  validation {
    condition = alltrue([
      for key, subnet in var.subnets :
      length(subnet.address_prefixes) > 0
    ])

    error_message = "Each subnet must define at least one address prefix."
  }
}


# ============================================================
# VNET PEERING
# ============================================================

variable "vnet_peerings" {
  description = "Azure Virtual Network Peering configuration."

  type = map(object({
    name            = string
    source_vnet_key = string
    remote_vnet_key = string

    allow_virtual_network_access = optional(
      bool,
      true
    )

    allow_forwarded_traffic = optional(
      bool,
      true
    )

    allow_gateway_transit = optional(
      bool,
      false
    )

    use_remote_gateways = optional(
      bool,
      false
    )
  }))

  validation {
    condition = length(var.vnet_peerings) > 0

    error_message = "At least one VNet peering must be defined."
  }
}


# ============================================================
# PUBLIC IP ADDRESSES
# ============================================================

variable "public_ips" {
  description = "Public IP configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    allocation_method = optional(
      string,
      "Static"
    )

    sku = optional(
      string,
      "Standard"
    )
  }))

  validation {
    condition = length(var.public_ips) > 0

    error_message = "At least one Public IP must be defined."
  }
}


# ============================================================
# NETWORK SECURITY GROUPS
# ============================================================

variable "network_security_groups" {
  description = "Network Security Group configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    security_rules = map(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string, "*")
      destination_port_range       = optional(string, "*")
      source_address_prefix        = optional(string)
      destination_address_prefix   = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    }))
  }))

  validation {
    condition = length(var.network_security_groups) > 0

    error_message = "At least one Network Security Group must be defined."
  }
}


# ============================================================
# NSG ASSOCIATIONS
# ============================================================

variable "nsg_associations" {
  description = "Subnet to NSG associations."

  type = map(object({
    subnet_key = string
    nsg_key    = string
  }))

  validation {
    condition = length(var.nsg_associations) > 0

    error_message = "At least one NSG association must be defined."
  }
}


# ============================================================
# ROUTE TABLES
# ============================================================

variable "route_tables" {
  description = "Route table configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    routes = optional(map(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))

  default = {}
}


# ============================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================

variable "route_table_associations" {
  description = "Subnet to route table associations."

  type = map(object({
    subnet_key      = string
    route_table_key = string
  }))

  default = {}
}


# ============================================================
# NETWORK INTERFACES
# ============================================================

variable "network_interfaces" {
  description = "Network Interface configuration."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string

    ip_configuration = object({
      name                          = string
      private_ip_address_allocation = string
      private_ip_address            = optional(string)
      public_ip_key                 = optional(string)
    })

    backend_pool_key = optional(string)
  }))

  validation {
    condition = length(var.network_interfaces) > 0

    error_message = "At least one Network Interface must be defined."
  }
}


# ============================================================
# VIRTUAL MACHINES
# ============================================================
# ============================================================
# SSH PUBLIC KEY
# ============================================================

variable "admin_ssh_public_key" {
  description = "SSH public key used for Linux Virtual Machine administration."

  type      = string
  sensitive = true

  validation {
    condition = (
      length(trimspace(var.admin_ssh_public_key)) > 0 &&
      (
        startswith(trimspace(var.admin_ssh_public_key), "ssh-rsa") ||
        startswith(trimspace(var.admin_ssh_public_key), "ssh-ed25519") ||
        startswith(trimspace(var.admin_ssh_public_key), "ecdsa-sha2-")
      )
    )

    error_message = "admin_ssh_public_key must be a valid SSH public key."
  }
}


# ============================================================
# VIRTUAL MACHINES
# ============================================================

variable "virtual_machines" {
  description = "Map of Linux and Windows Virtual Machines to provision."

  type = map(object({
    name               = string
    resource_group_key = string
    nic_key            = string

    os_type = string
    size    = string

    admin_username = string

    admin_ssh_key  = optional(string)
    admin_password = optional(string)

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    os_disk = optional(object({
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
      disk_size_gb         = optional(number, 30)
    }), {})

    custom_data = optional(string)

    enable_system_assigned_identity = optional(bool, true)

    secure_boot_enabled = optional(bool, true)

    vtpm_enabled = optional(bool, true)

    boot_diagnostics = optional(object({
      enabled = optional(bool, true)
    }), {})
  }))

  validation {
    condition = length(var.virtual_machines) > 0

    error_message = "At least one Virtual Machine must be defined."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      contains(["Linux", "Windows"], vm.os_type)
    ])

    error_message = "Virtual Machine os_type must be either Linux or Windows."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      length(trimspace(vm.name)) > 0
    ])

    error_message = "Each Virtual Machine must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      length(trimspace(vm.admin_username)) > 0
    ])

    error_message = "Each Virtual Machine must define a non-empty admin username."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      contains(
        [
          "ReadOnly",
          "ReadWrite",
          "None"
        ],
        vm.os_disk.caching
      )
    ])

    error_message = "OS disk caching must be ReadOnly, ReadWrite, or None."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      contains(
        [
          "Standard_LRS",
          "StandardSSD_LRS",
          "Premium_LRS",
          "StandardSSD_ZRS",
          "Premium_ZRS"
        ],
        vm.os_disk.storage_account_type
      )
    ])

    error_message = "Unsupported OS disk storage account type."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_disk.disk_size_gb >= 30
    ])

    error_message = "OS disk size must be at least 30 GB."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Windows" || vm.admin_password != null
    ])

    error_message = "Windows Virtual Machines must define an administrator password."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Linux" || vm.admin_password == null
    ])

    error_message = "Linux Virtual Machines must use SSH authentication and must not define an admin password."
  }

  validation {
    condition = alltrue([
      for vm_key, vm in var.virtual_machines :
      vm.os_type != "Windows" || vm.admin_ssh_key == null
    ])

    error_message = "Windows Virtual Machines should not define an SSH public key."
  }
}







# ============================================================
# INTERNAL LOAD BALANCERS
# ============================================================

variable "load_balancers" {
  description = "Internal Load Balancer configuration."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string

    frontend_ip_configuration_name = string
    private_ip_address             = string

    sku = optional(
      string,
      "Standard"
    )

    backend_pool_name = string

    health_probe = object({
      name                = string
      protocol            = string
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
    })

    load_balancing_rule = object({
      name                    = string
      protocol                = string
      frontend_port           = number
      backend_port            = number
      idle_timeout_in_minutes = optional(number, 4)
    })
  }))

  validation {
    condition = length(var.load_balancers) > 0

    error_message = "At least one Load Balancer must be defined."
  }
}


# ============================================================
# APPLICATION GATEWAYS
# ============================================================

variable "application_gateways" {
  description = "Application Gateway WAF configuration."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string
    public_ip_key      = string

    sku = object({
      name     = string
      tier     = string
      capacity = optional(number)
    })

    frontend_ip_configuration_name = string
    frontend_port_name             = string
    frontend_port                  = number

    gateway_ip_configuration_name = string

    http_listener_name = string

    waf_policy = optional(object({
      enabled          = optional(bool, true)
      firewall_mode    = optional(string, "Prevention")
      rule_set_type    = optional(string, "OWASP")
      rule_set_version = optional(string, "3.2")
    }), null)

    frontend_backend = object({
      name               = string
      ip_addresses       = list(string)
      http_settings_name = string
      http_settings_port = number
      probe_name         = string
      probe_path         = string
    })

    backend_backend = object({
      name               = string
      ip_addresses       = list(string)
      http_settings_name = string
      http_settings_port = number
      probe_name         = string
      probe_path         = string
    })

    path_map_name = string

    path_rules = list(object({
      name                       = string
      paths                      = list(string)
      backend_address_pool_name  = string
      backend_http_settings_name = string
    }))

    default_backend_address_pool_name  = string
    default_backend_http_settings_name = string

    request_routing_rule_name     = string
    request_routing_rule_priority = number
  }))

  validation {
    condition = length(var.application_gateways) > 0

    error_message = "At least one Application Gateway must be defined."
  }
}


# ============================================================
# BASTION
# ============================================================

variable "bastions" {
  description = "Azure Bastion configuration."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string
    public_ip_key      = string

    sku = optional(
      string,
      "Standard"
    )

    copy_paste_enabled = optional(
      bool,
      true
    )

    file_copy_enabled = optional(
      bool,
      true
    )

    ip_connect_enabled = optional(
      bool,
      true
    )

    shareable_link_enabled = optional(
      bool,
      false
    )

    tunneling_enabled = optional(
      bool,
      true
    )
  }))

  validation {
    condition = length(var.bastions) > 0

    error_message = "At least one Bastion must be defined."
  }
}




# ============================================================
# AZURE SQL SERVERS
# ============================================================

variable "sql_servers" {
  description = "Azure SQL Server configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    administrator_login = string

    version = optional(
      string,
      "12.0"
    )

    minimum_tls_version = optional(
      string,
      "1.2"
    )

    public_network_access_enabled = optional(
      bool,
      false
    )

    azuread_administrator = optional(object({
      login_username = string
      object_id      = string
    }))

    database = optional(object({
      name                 = string
      sku_name             = string
      max_size_gb          = optional(number)
      zone_redundant       = optional(bool, false)
      storage_account_type = optional(string, "Local")
    }))

    vulnerability_assessment = object({
      email_subscription_admins = bool
      emails                    = list(string)
    })
  }))

  validation {
    condition = length(var.sql_servers) > 0

    error_message = "At least one Azure SQL Server must be defined."
  }
}


# ============================================================
# AZURE SQL ADMIN PASSWORD
# ============================================================

variable "sql_admin_password" {
  description = "Azure SQL administrator password."

  type      = string
  sensitive = true

  validation {
    condition = length(var.sql_admin_password) >= 8

    error_message = "Azure SQL administrator password must be at least 8 characters."
  }
}


# ============================================================
# POSTGRESQL FLEXIBLE SERVER
# ============================================================

variable "postgresql_servers" {
  description = "Azure PostgreSQL Flexible Server configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    administrator_login = string

    version = optional(
      string,
      "16"
    )

    sku_name = optional(
      string,
      "B_Standard_B1ms"
    )

    storage_mb = optional(
      number,
      32768
    )

    backup_retention_days = optional(
      number,
      7
    )

    geo_redundant_backup_enabled = optional(
      bool,
      false
    )

    public_network_access_enabled = optional(
      bool,
      false
    )

    database = optional(object({
      name = string

      charset = optional(
        string,
        "UTF8"
      )

      collation = optional(
        string,
        "en_US.utf8"
      )
    }))

    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string)
    }))
  }))

  validation {
    condition = length(var.postgresql_servers) > 0

    error_message = "At least one PostgreSQL server must be defined."
  }
}


# ============================================================
# POSTGRESQL ADMIN PASSWORD
# ============================================================

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password."

  type      = string
  sensitive = true

  validation {
    condition = length(var.postgresql_admin_password) >= 8

    error_message = "PostgreSQL administrator password must be at least 8 characters."
  }
}


# ============================================================
# PRIVATE ENDPOINTS
# ============================================================

variable "private_endpoints" {
  description = "Azure Private Endpoint configuration."

  type = map(object({
    name               = string
    resource_group_key = string
    subnet_key         = string

    private_service_connection = object({
      name                           = string
      private_connection_resource_id = string
      subresource_names              = list(string)
      is_manual_connection           = bool
    })

    private_dns_zone_group = optional(object({
      name         = string
      dns_zone_key = string
    }))
  }))

  default = {}

  validation {
    condition = alltrue([
      for key, pe in var.private_endpoints :
      length(trimspace(pe.name)) > 0
    ])

    error_message = "Each Private Endpoint must define a non-empty name."
  }

  validation {
    condition = alltrue([
      for key, pe in var.private_endpoints :
      length(pe.private_service_connection.subresource_names) > 0
    ])

    error_message = "Each Private Endpoint must define at least one subresource name."
  }
}


# ============================================================
# PRIVATE DNS ZONES
# ============================================================

variable "private_dns_zones" {
  description = "Private DNS Zones required for private Azure services."

  type = map(object({
    name               = string
    resource_group_key = string
  }))

  validation {
    condition = length(var.private_dns_zones) > 0

    error_message = "At least one Private DNS Zone must be defined."
  }

  validation {
    condition = alltrue([
      for key, zone in var.private_dns_zones :
      length(trimspace(zone.name)) > 0
    ])

    error_message = "Each Private DNS Zone must define a non-empty name."
  }
}


# ============================================================
# PRIVATE DNS ZONE - VNET LINKS
# ============================================================

variable "private_dns_zone_vnet_links" {
  description = "Private DNS Zone to Virtual Network links."

  type = map(object({
    dns_zone_key = string
    vnet_key     = string

    registration = optional(
      bool,
      false
    )
  }))

  validation {
    condition = length(var.private_dns_zone_vnet_links) > 0

    error_message = "At least one Private DNS Zone VNet link must be defined."
  }
}

# ============================================================
# KEY VAULT
# ============================================================

variable "key_vaults" {
  description = "Azure Key Vault configuration."

  type = map(object({
    name               = string
    resource_group_key = string

    sku_name = optional(string, "standard")

    tenant_id = optional(string)

    soft_delete_retention_days = optional(number, 90)
    purge_protection_enabled   = optional(bool, true)

    public_network_access_enabled = optional(bool, false)

    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)

    enable_rbac_authorization = optional(bool, true)
  }))

  default = {}
}

# ============================================================
# MONITORING
# ============================================================

variable "monitoring" {
  description = "Azure Monitor, Log Analytics and Application Insights configuration."

  type = object({
    log_analytics_workspace = object({
      name               = string
      resource_group_key = string
      sku                = optional(string, "PerGB2018")
      retention_in_days  = optional(number, 30)
    })

    application_insights = object({
      name               = string
      resource_group_key = string
      application_type   = optional(string, "web")
      retention_in_days  = optional(number, 90)
    })
  })
}