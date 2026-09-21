variable "location" {
  description = "Azure region for all resources in the dev environment. Must match the target region, compliance requirements, and service availability."
  type        = string

  validation {
    condition     = contains(["japaneast", "eastus", "eastus2", "centralus", "westeurope", "uksouth"], lower(var.location))
    error_message = "location must be a supported Azure region, for example: japaneast, eastus, eastus2, centralus, westeurope, or uksouth."
  }
}

variable "environment" {
  description = "Deployment environment name. Used for naming, tags, and policy enforcement."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], lower(var.environment))
    error_message = "environment must be one of: dev, stage, or prod."
  }
}

variable "tags" {
  description = "Default tags applied to all resources. Keep values consistent across the landing zone to support governance, ownership, and cost tracking."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings to preserve consistent governance and billing metadata."
  }
}

# RESOURCE GROUPS
variable "resource_groups" {
  description = "Map of resource groups to create for the dev environment. Names should be lowercase, globally unique within the subscription, and consistent with the naming convention."
  type = map(object({
    name = string
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for name, rg in var.resource_groups : length(trimspace(rg.name)) > 0 && can(regex("^[A-Za-z0-9-_.]+$", rg.name))
    ])
    error_message = "Each resource group name must be non-empty and contain only letters, numbers, hyphens, underscores, or periods."
  }
}

# STORAGE ACCOUNTS
variable "storage_accounts" {
  description = "Map of storage accounts to create for the dev environment. Values should follow Azure naming rules and enterprise storage standards."
  type = map(object({
    name                     = string
    resource_group_name      = string
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    tags                     = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, storage in var.storage_accounts : length(storage.name) >= 3 && length(storage.name) <= 24 && can(regex("^[a-z0-9]+$", storage.name)) && contains(["Standard", "Premium"], storage.account_tier) && contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RA-GRS"], storage.account_replication_type)
    ])
    error_message = "Storage account names must be 3-24 lowercase letters and numbers; account_tier must be Standard or Premium; replication type must be a valid Azure storage redundancy option."
  }
}

variable "vnets" {
  description = "Map of VNets for the hub-spoke landing zone. Each VNet must use RFC1918 private address space and valid subnet ranges."
  type = map(object({
    name                = string
    resource_group_name = string
    address_space       = list(string)
    subnets = map(object({
      name              = string
      address_prefixes  = list(string)
      service_endpoints = optional(list(string), [])
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, vnet in var.vnets : length(vnet.address_space) > 0 && alltrue([for cidr in vnet.address_space : can(cidrhost(cidr, 0))]) && length(vnet.subnets) > 0
    ])
    error_message = "Each VNet must define at least one valid private CIDR and at least one subnet."
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
  description = "Internal load balancers for backend workload tiers."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku = optional(string, "Standard")

    vnet_key    = string
    subnet_key  = string

    frontend_ip_configuration = object({
      name                 = string
      private_ip_address   = string
      private_ip_addresses = optional(list(string), [])
    })

    backend_address_pool = object({
      name         = string
      ip_addresses = optional(list(string), [])
    })

    health_probe = object({
      name                = string
      protocol            = optional(string, "Http")
      port                = number
      request_path        = optional(string, "/health")
      interval_in_seconds = optional(number, 30)
      number_of_probes    = optional(number, 2)
    })

    lb_rule = object({
      name                           = string
      frontend_ip_configuration_name = string
      backend_address_pool_name      = string
      frontend_port                  = number
      backend_port                   = number
      protocol                       = optional(string, "Tcp")
      load_distribution              = optional(string, "Default")
    })

    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      length(trimspace(lb.name)) > 0 &&
      length(trimspace(lb.resource_group_name)) > 0 &&
      length(trimspace(lb.location)) > 0 &&
      length(trimspace(lb.vnet_key)) > 0 &&
      length(trimspace(lb.subnet_key)) > 0 &&
      length(trimspace(lb.frontend_ip_configuration.name)) > 0 &&
      length(trimspace(lb.frontend_ip_configuration.private_ip_address)) > 0 &&
      length(trimspace(lb.backend_address_pool.name)) > 0 &&
      length(trimspace(lb.health_probe.name)) > 0 &&
      length(trimspace(lb.lb_rule.name)) > 0
    ])

    error_message = "Each load balancer must define valid resource, network, frontend, backend, health probe, and rule configuration."
  }

  validation {
    condition = alltrue([
      for key, lb in var.load_balancers :
      lb.health_probe.port >= 1 &&
      lb.health_probe.port <= 65535 &&
      lb.lb_rule.frontend_port >= 1 &&
      lb.lb_rule.frontend_port <= 65535 &&
      lb.lb_rule.backend_port >= 1 &&
      lb.lb_rule.backend_port <= 65535
    ])

    error_message = "Load balancer ports must be between 1 and 65535."
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
  description = "NSGs for ingress and app traffic. Rules must be explicit, ordered, and least-privilege by design."
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
      for key, nsg in var.network_security_groups : length(trimspace(nsg.name)) > 0 && alltrue([
        for rule_key, rule in nsg.security_rules : rule.priority >= 100 && rule.priority <= 4096 && contains(["Inbound", "Outbound"], rule.direction) && contains(["Allow", "Deny"], rule.access)
      ])
    ])
    error_message = "Each NSG name must be non-empty; every security rule priority must be between 100 and 4096 and include valid direction and access values."
  }
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspace for centralized diagnostics and monitoring."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "PerGB2018")
    retention_in_days   = optional(number, 30)
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, workspace in var.log_analytics_workspaces : length(trimspace(workspace.name)) > 0 && workspace.retention_in_days >= 30 && workspace.retention_in_days <= 730
    ])
    error_message = "Log Analytics names must be non-empty and retention_in_days should be between 30 and 730 days."
  }
}

variable "application_insights" {
  description = "Application Insights resource for application telemetry and observability."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    workspace_id        = string
    application_type    = optional(string, "web")
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, appi in var.application_insights : length(trimspace(appi.name)) > 0 && contains(["web", "other"], lower(appi.application_type))
    ])
    error_message = "Application Insights names must be non-empty and application_type must be web or other."
  }
}

# APPLICATION GATEWAYS
variable "application_gateways" {
  description = "Application Gateway definitions for workload ingress."

  type = map(object({
    name                = string
    resource_group_name = string
    location            = string

    sku = object({
      name     = string
      tier     = string
      capacity = number
    })

    waf_configuration = optional(object({
      enabled                  = optional(bool, true)
      firewall_mode            = optional(string, "Prevention")
      rule_set_type            = optional(string, "OWASP")
      rule_set_version         = optional(string, "3.2")
      file_upload_limit_mb     = optional(number, 100)
      request_body_check       = optional(bool, true)
      max_request_body_size_kb = optional(number, 128)
    }), null)

    vnet_key   = string
    subnet_key = string

    public_ip_key = string

    gateway_ip_configuration = object({
      name = string
    })

    frontend_ip_configuration = object({
      name = string
    })

    frontend_port = object({
      name = string
      port = number
    })

    http_listener = object({
      name                           = string
      frontend_ip_configuration_name = string
      frontend_port_name             = string
      protocol                       = string
    })

    request_routing_rule = object({
      name                       = string
      rule_type                  = string
      http_listener_name         = string
      backend_address_pool_name  = string
      backend_http_settings_name = string
    })

    backend_address_pool = object({
      name         = string
      ip_addresses = optional(list(string), [])
    })

    health_probe = object({
      name                = string
      protocol            = optional(string, "Http")
      port                = number
      path                = optional(string, "/")
      interval            = optional(number, 30)
      timeout             = optional(number, 30)
      unhealthy_threshold = optional(number, 3)
    })

    backend_http_settings = object({
      name                  = string
      cookie_based_affinity = string
      port                  = number
      protocol              = string
      request_timeout       = number
    })

    tags = optional(map(string), {})
  }))

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

    error_message = "Each Application Gateway must define valid resource, network, subnet, and public IP references."
  }

  validation {
    condition = alltrue([
      for key, gateway in var.application_gateways :
      gateway.frontend_port.port >= 1 &&
      gateway.frontend_port.port <= 65535 &&
      gateway.health_probe.port >= 1 &&
      gateway.health_probe.port <= 65535 &&
      gateway.backend_http_settings.port >= 1 &&
      gateway.backend_http_settings.port <= 65535
    ])

    error_message = "Application Gateway ports must be between 1 and 65535."
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
  description = "Linux VM definitions for the workload tier. NIC relationships are resolved from the network interface module by key."

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

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      length(trimspace(vm.name)) > 0 &&
      length(trimspace(vm.resource_group_name)) > 0 &&
      length(trimspace(vm.location)) > 0 &&
      length(trimspace(vm.size)) > 0 &&
      length(trimspace(vm.admin_username)) > 0 &&
      length(trimspace(vm.nic_key)) > 0
    ])

    error_message = "Each Linux VM must define a non-empty name, resource group, location, size, admin username, and NIC key."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      vm.admin_ssh_key != null ||
      (
        vm.admin_password != null &&
        length(trimspace(vm.admin_password)) >= 12
      )
    ])

    error_message = "Each Linux VM must provide either an SSH public key or an admin password of at least 12 characters."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      vm.identity_type == null ||
      contains(
        [
          "SystemAssigned",
          "UserAssigned",
          "SystemAssigned, UserAssigned"
        ],
        vm.identity_type
      )
    ])

    error_message = "identity_type must be SystemAssigned, UserAssigned, SystemAssigned, UserAssigned, or null."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      length(trimspace(vm.os_disk.caching)) > 0 &&
      length(trimspace(vm.os_disk.storage_account_type)) > 0
    ])

    error_message = "Each Linux VM must define valid OS disk caching and storage account type values."
  }

  validation {
    condition = alltrue([
      for key, vm in var.linux_virtual_machines :
      length(trimspace(vm.source_image_reference.publisher)) > 0 &&
      length(trimspace(vm.source_image_reference.offer)) > 0 &&
      length(trimspace(vm.source_image_reference.sku)) > 0 &&
      length(trimspace(vm.source_image_reference.version)) > 0
    ])

    error_message = "Each Linux VM must define publisher, offer, SKU, and version for the source image."
  }
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
variable "private_dns_zones" {
  description = "Private DNS zones used for Azure PaaS private access. VNet link relationships are resolved from the network module output by key."
  type = map(object({
    name                = string
    resource_group_name = string
    vnet_key            = string
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, zone in var.private_dns_zones : length(trimspace(zone.name)) > 0 && can(regex("\\.$", zone.name)) && length(trimspace(zone.vnet_key)) > 0
    ])
    error_message = "Private DNS zone names must be non-empty and fully qualified domain names; a valid VNet key is required for the VNet link."
  }
}

variable "private_endpoints" {
  description = "Private endpoints for Azure SQL and other PaaS services. VNet/subnet relationships are resolved from the network module output by key."
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    vnet_key            = string
    subnet_key          = string
    private_service_connection = object({
      name                           = string
      private_connection_resource_id = string
      is_manual_connection           = optional(bool, false)
      subresource_names              = list(string)
      request_message                = optional(string, null)
    })
    private_dns_zone_group = optional(object({
      name                 = string
      private_dns_zone_ids = list(string)
    }), null)
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for key, endpoint in var.private_endpoints : length(trimspace(endpoint.name)) > 0 && length(trimspace(endpoint.vnet_key)) > 0 && length(trimspace(endpoint.subnet_key)) > 0 && length(endpoint.private_service_connection.subresource_names) > 0
    ])
    error_message = "Private endpoint names, VNet/subnet keys, and service connection subresource names must be defined."
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
      for key, bastion in var.bastions : length(trimspace(bastion.name)) > 0 && length(trimspace(bastion.vnet_key)) > 0 && length(trimspace(bastion.subnet_key)) > 0 && length(trimspace(bastion.public_ip_key)) > 0
    ])
    error_message = "Bastion names, VNet/subnet keys, and public IP keys must be defined for secure access."
  }
}
