# ============================================================
# LOCALS
# ============================================================
# CHANGE:
# - Added/kept derived frontend and backend private IP lists.
# - These values are calculated once and reused by App Gateway
#   and Internal Load Balancer.
# - Keeps complex for-expressions out of module blocks.
# - Enterprise Terraform pattern: locals are used for derived data.
# ============================================================

locals {
  # CHANGE:
  # Collect only frontend VM private IPs.
  # App Gateway uses these IPs as its backend pool.
  frontend_vm_private_ips = [
    for key, nic in var.network_interfaces :
    nic.ip_configuration.private_ip_address
    if startswith(key, "frontend_") &&
    nic.ip_configuration.private_ip_address != null
  ]

  # CHANGE:
  # Collect only backend VM private IPs.
  # Internal Load Balancer uses these IPs as its backend pool.
  backend_vm_private_ips = [
    for key, nic in var.network_interfaces :
    nic.ip_configuration.private_ip_address
    if startswith(key, "backend_") &&
    nic.ip_configuration.private_ip_address != null
  ]
}


# ============================================================
# RESOURCE GROUPS
# ============================================================
# CHANGE:
# - Root module only passes environment-specific values.
# - Resource-group creation remains inside reusable child module.
# - No resource implementation is placed in env/dev/main.tf.
# ============================================================

module "resource_groups" {
  source = "../../modules/rg"

  resource_groups = var.resource_groups
  tags            = var.tags
}


# ============================================================
# STORAGE ACCOUNTS
# ============================================================
# CHANGE:
# - Storage account module receives common location and tags.
# - Actual resource implementation remains inside child module.
# ============================================================

module "sa" {
  source = "../../modules/sa"

  storage_accounts = var.storage_accounts
  location         = var.location
  tags             = var.tags
}


# ============================================================
# NETWORK
# ============================================================
# CHANGE:
# - Central network module creates/returns VNets and subnets.
# - Other modules consume network outputs instead of creating
#   their own networking resources.
# ============================================================

module "network" {
  source = "../../modules/network"

  location = var.location
  tags     = var.tags
  vnets    = var.vnets
}


# ============================================================
# NETWORK SECURITY GROUPS
# ============================================================
# CHANGE:
# - NSGs are created independently through reusable NSG module.
# - Subnet association is handled separately below.
# - This keeps NSG creation and association concerns separated.
# ============================================================

module "nsg" {
  source = "../../modules/nsg"

  network_security_groups = var.network_security_groups
  tags                    = var.tags
}


# ============================================================
# PUBLIC IP ADDRESSES
# ============================================================
# CHANGE:
# - Public IPs are centralized through the reusable public-ip module.
# - App Gateway and Bastion consume these outputs.
# - No public IP is directly created by those modules.
# ============================================================

module "public_ip" {
  source = "../../modules/public-ip"

  public_ips = var.public_ips
  tags       = var.tags
}


# ============================================================
# NETWORK INTERFACES
# ============================================================
# CHANGE:
# - NIC subnet relationship is resolved from module.network outputs.
# - Environment config only specifies vnet_key/subnet_key.
# - Actual Azure subnet ID is obtained dynamically.
# - NIC module remains reusable and does not know about dev/prod.
# ============================================================

module "nic" {
  source = "../../modules/nic"

  network_interfaces = {
    for key, nic in var.network_interfaces : key => {
      name                = nic.name
      resource_group_name = nic.resource_group_name
      location            = nic.location

      ip_configuration = {
        name = nic.ip_configuration.name

        # CHANGE:
        # Resolve the actual Azure subnet ID from the network module
        # instead of hardcoding subnet resource IDs.
        subnet_id = module.network.subnets[
          "${nic.vnet_key}-${nic.subnet_key}"
        ].id

        private_ip_address_allocation = nic.ip_configuration.private_ip_address_allocation
        private_ip_address            = try(nic.ip_configuration.private_ip_address, null)
      }

      tags = nic.tags
    }
  }

  tags = var.tags
}


# ============================================================
# LINUX VIRTUAL MACHINES
# ============================================================
# CHANGE:
# - VM module now receives an actual NIC resource ID.
# - var.linux_virtual_machines keeps only nic_key.
# - nic_key is resolved here against module.nic output.
#
# IMPORTANT FIX:
# Old:
#   module.network_interface.network_interfaces[vm.nic_key].id
#
# Correct:
#   module.nic.network_interfaces[vm.nic_key].id
#
# The actual module declared in this root module is:
#   module "nic"
# ============================================================

module "vm" {
  source = "../../modules/vm"

  linux_virtual_machines = {
    for key, vm in var.linux_virtual_machines : key => {
      name                = vm.name
      resource_group_name = vm.resource_group_name
      location            = vm.location
      size                = vm.size

      admin_username = vm.admin_username
      admin_password = vm.admin_password
      admin_ssh_key  = vm.admin_ssh_key

      network_interface_id = module.nic.network_interfaces[vm.nic_key].id

      custom_data = vm.custom_data

      identity_type = vm.identity_type

      os_disk = vm.os_disk

      source_image_reference = vm.source_image_reference

      tags = vm.tags
    }
  }

  tags = var.tags
}

# ============================================================
# SUBNET -> NSG ASSOCIATIONS
# ============================================================
module "subnet_nsg_association" {
  source = "../../modules/nsg-association"

  # Read the environment-specific association mapping.
  subnet_nsg_associations = var.subnet_nsg_associations

  # Consume subnet objects from the network module.
  subnets = module.network.subnets

  # Consume NSG objects from the NSG module.
  nsgs = module.nsg.network_security_groups
}

# ============================================================
# INTERNAL LOAD BALANCER
# ============================================================
# CHANGE:
# - ILB subnet ID is resolved from module.network.
# - Backend VM private IPs come from locals.
# - Health probe defaults to backend port 8080 and /health.
# - Load-balancing rule defaults to frontend/backend port 8080.
#
# Traffic:
# Frontend VMs -> ILB:8080 -> Backend VMs:8080
# ============================================================

module "internal_load_balancer" {
  source = "../../modules/lb"

  load_balancers = {
    for name, lb in var.load_balancers : name => {
      name                = lb.name
      resource_group_name = lb.resource_group_name
      location            = lb.location
      sku                 = lb.sku

      frontend_ip_configuration = {
        name = lb.frontend_ip_configuration.name

        subnet_id = module.network.subnets[
          "${lb.vnet_key}-${lb.subnet_key}"
        ].id

        private_ip_address   = lb.frontend_ip_configuration.private_ip_address
        private_ip_addresses = lb.frontend_ip_configuration.private_ip_addresses
      }

      backend_address_pool = {
        name         = lb.backend_address_pool.name
        ip_addresses = local.backend_vm_private_ips
      }

      health_probe = {
        name                = lb.health_probe.name
        protocol            = lb.health_probe.protocol
        port                = lb.health_probe.port
        request_path        = lb.health_probe.request_path
        interval_in_seconds = lb.health_probe.interval_in_seconds
        number_of_probes    = lb.health_probe.number_of_probes
      }

      lb_rule = lb.lb_rule

      tags = lb.tags
    }
  }

  tags = var.tags
}


# ============================================================
# KEY VAULT
# ============================================================
# CHANGE:
# - Key Vault remains a reusable child module.
# - Environment-specific Key Vault configuration stays in tfvars.
# ============================================================

module "key_vault" {
  source = "../../modules/key-vault"

  key_vaults = var.key_vaults

  tags = var.tags
}


# ============================================================
# MONITORING
# ============================================================
# CHANGE:
# - Log Analytics and Application Insights are managed through
#   one reusable monitoring module.
# - Common tags are applied from the environment root.
# ============================================================

module "monitoring" {
  source = "../../modules/monitoring"

  log_analytics_workspaces = var.log_analytics_workspaces
  application_insights     = var.application_insights

  tags = var.tags
}


# ============================================================
# APPLICATION GATEWAY
# ============================================================
# CHANGE:
# - App Gateway subnet ID is resolved from network module.
# - Public IP ID is resolved from public_ip module.
# - Frontend VM private IPs come from locals.
# - Health probe is explicitly passed through.
#
# Traffic:
# Internet
#    |
#    v
# App Gateway :80
#    |
#    v
# Frontend VM :80
# ============================================================

module "gateway" {
  source = "../../modules/gateway"

  application_gateways = {
    for name, gateway in var.application_gateways : name => {
      name                = gateway.name
      resource_group_name = gateway.resource_group_name
      location            = gateway.location

      sku = gateway.sku

      waf_configuration = gateway.waf_configuration

      gateway_ip_configuration = {
        name = gateway.gateway_ip_configuration.name

        subnet_id = module.network.subnets[
          "${gateway.vnet_key}-${gateway.subnet_key}"
        ].id
      }

      frontend_ip_configuration = {
        name = gateway.frontend_ip_configuration.name

        public_ip_address_id = module.public_ip.public_ips[
          gateway.public_ip_key
        ].id
      }

      frontend_port = gateway.frontend_port

      http_listener = gateway.http_listener

      request_routing_rule = gateway.request_routing_rule

      backend_address_pool = {
        name         = gateway.backend_address_pool.name
        ip_addresses = local.frontend_vm_private_ips
      }

      health_probe = gateway.health_probe

      backend_http_settings = gateway.backend_http_settings

      tags = gateway.tags
    }
  }

  tags = var.tags
}


# ============================================================
# PRIVATE DNS + PRIVATE ENDPOINT
# ============================================================
# CHANGE:
# - Private DNS zone VNet association uses network module output.
# - Private endpoint subnet uses network module output.
# - Environment config only specifies logical vnet/subnet keys.
# ============================================================

module "private_access" {
  source = "../../modules/private-access"

  private_dns_zones = {
    for key, zone in var.private_dns_zones : key => {
      name                = zone.name
      resource_group_name = zone.resource_group_name

      virtual_network_id = module.network.vnets[
        zone.vnet_key
      ].id

      tags = zone.tags
    }
  }

  private_endpoints = {
    for key, endpoint in var.private_endpoints : key => {
      name                = endpoint.name
      location            = endpoint.location
      resource_group_name = endpoint.resource_group_name

      subnet_id = module.network.subnets[
        "${endpoint.vnet_key}-${endpoint.subnet_key}"
      ].id

      private_service_connection = {
        name = endpoint.private_service_connection.name

        private_connection_resource_id = local.private_endpoint_targets[
          endpoint.target_key
        ]

        is_manual_connection = endpoint.private_service_connection.is_manual_connection
        subresource_names    = endpoint.private_service_connection.subresource_names
        request_message      = endpoint.private_service_connection.request_message
      }

      private_dns_zone_key = endpoint.private_dns_zone_key

      tags = endpoint.tags
    }
  }

  tags = var.tags
}


# ============================================================
# AZURE BASTION
# ============================================================
# CHANGE:
# - Bastion subnet ID comes from network module.
# - Bastion public IP comes from public-ip module.
# - No public IP is attached directly to workload VMs.
#
# Traffic:
# Administrator
#     |
#     v
# Azure Bastion
#     |
#     v
# VM private IP
# ============================================================

module "bastion" {
  source = "../../modules/bastion"

  bastions = {
    for key, bastion in var.bastions : key => {
      name                = bastion.name
      resource_group_name = bastion.resource_group_name
      location            = bastion.location

      ip_configuration = {
        name = "bastion-ip-config"

        subnet_id = module.network.subnets[
          "${bastion.vnet_key}-${bastion.subnet_key}"
        ].id

        public_ip_address_id = module.public_ip.public_ips[
          bastion.public_ip_key
        ].id
      }

      tags = bastion.tags
    }
  }

  tags = var.tags
}

module "sql" {
  source = "../../modules/sql"

  sql_servers   = var.sql_servers
  sql_databases = var.sql_databases
  tags          = var.tags
}

# postgresql module
module "postgresql" {
  source = "../../modules/postgresql"

  postgresql_servers   = var.postgresql_servers
  postgresql_databases = var.postgresql_databases

  tags = var.tags
}