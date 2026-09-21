variable "location" {
  description = "Azure region for all resources in the prod environment"
  type        = string

  validation {
    condition     = contains(["japaneast", "eastus", "eastus2", "centralus", "westeurope", "uksouth"], lower(var.location))
    error_message = "location must be a supported Azure region."
  }
}

variable "environment" {
  description = "Deployment environment name"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], lower(var.environment))
    error_message = "environment must be one of: dev, stage, or prod."
  }
}

variable "tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for key, value in var.tags : length(trimspace(key)) > 0 && length(trimspace(value)) > 0
    ])
    error_message = "Each tag key and value must be non-empty strings."
  }
}

variable "resource_groups" {
  description = "Map of resource groups to create for the prod environment"
  type = map(object({
    name = string
    tags = optional(map(string), {})
  }))
}

variable "storage_accounts" {
  description = "Map of storage accounts to create for the prod environment"
  type = map(object({
    name                     = string
    resource_group_name      = string
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    tags                     = optional(map(string), {})
  }))
}

variable "vnets" {
  description = "Map of VNets for the hub-spoke landing zone"
  type = map(object({
    name                = string
    resource_group_name = string
    address_space       = list(string)
    subnets = map(object({
      name             = string
      address_prefixes = list(string)
    }))
    tags = optional(map(string), {})
  }))
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

variable "load_balancers" {
  description = "Map of Azure load balancers for the backend tier. Subnet relationships are resolved from the network module output by key."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    vnet_key            = string
    subnet_key          = string
    sku                 = optional(string, "Standard")
    frontend_ip_configuration = object({
      name                 = string
      private_ip_address   = string
      private_ip_addresses = optional(list(string), [])
    })
    backend_address_pool = object({
      name = string
    })
    health_probe = object({
      name     = string
      protocol = optional(string, "Tcp")
      port     = number
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
}

variable "network_security_groups" {
  description = "NSGs for ingress and app traffic"
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
}

variable "network_interfaces" {
  description = "NIC definitions for VM attachments. Subnet relationships are resolved from the network module output by key."
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
}

variable "linux_virtual_machines" {
  description = "Linux VM definitions for the app tier"
  type = map(object({
    name                 = string
    resource_group_name  = string
    location             = string
    size                 = string
    admin_username       = string
    admin_password       = string
    network_interface_id = string
    custom_data          = optional(string, null)
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
  sensitive = true
}

variable "subnet_nsg_associations" {
  description = "Map of subnet names to NSG names. The child association module resolves the Azure IDs from upstream module outputs."
  type = map(object({
    subnet_name                 = string
    network_security_group_name = string
  }))
  default = {}
}

variable "log_analytics_workspaces" {
  description = "Log Analytics workspace"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = optional(string, "PerGB2018")
    retention_in_days   = optional(number, 30)
    tags                = optional(map(string), {})
  }))
}

variable "application_insights" {
  description = "Application Insights"
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    workspace_id        = string
    application_type    = optional(string, "web")
    tags                = optional(map(string), {})
  }))
}

variable "application_gateways" {
  description = "Application Gateway for public ingress. VNet and public IP relationships are resolved from module outputs by key."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    vnet_key            = string
    subnet_key          = string
    public_ip_key       = string
    sku = object({
      name     = string
      tier     = string
      capacity = number
    })
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
      name = string
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
}

variable "private_dns_zones" {
  description = "Private DNS zones used for Azure PaaS private access. VNet link relationships are resolved from the network module output by key."
  type = map(object({
    name                = string
    resource_group_name = string
    vnet_key            = string
    tags                = optional(map(string), {})
  }))
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
}

variable "bastions" {
  description = "Azure Bastion hosts for secure SSH/RDP access. VNet/subnet and public IP relationships are resolved from outputs by key."
  type = map(object({
    name                = string
    resource_group_name = string
    location            = string
    vnet_key            = string
    subnet_key          = string
    public_ip_key       = string
    tags                = optional(map(string), {})
  }))
}
