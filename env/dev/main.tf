
# ============================================================
# LOCALS
# ============================================================

locals {
  frontend_vm_private_ips = [
    for key, nic in var.network_interfaces :
    nic.ip_configuration.private_ip_address
    if startswith(key, "frontend_") &&
    nic.ip_configuration.private_ip_address != null
  ]

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

module "resource_groups" {
  source = "../../modules/rg"

  resource_groups = var.resource_groups
  tags            = var.tags
}


# ============================================================
# STORAGE ACCOUNTS
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

module "network" {
  source = "../../modules/network"

  location = var.location
  tags     = var.tags
  vnets    = var.vnets
}


# ============================================================
# NETWORK SECURITY GROUPS
# ============================================================

module "nsg" {
  source = "../../modules/nsg"

  network_security_groups = var.network_security_groups
  tags                    = var.tags
}


# ============================================================
# PUBLIC IP ADDRESSES
# ============================================================

module "public_ip" {
  source = "../../modules/public-ip"

  public_ips = var.public_ips
  tags       = var.tags
}


# ============================================================
# NETWORK INTERFACES
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
# LINUX + WINDOWS VIRTUAL MACHINES
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

      network_interface_id = module.nic.network_interfaces[
        vm.nic_key
      ].id

      custom_data = vm.custom_data

      identity_type = vm.identity_type

      os_disk = vm.os_disk

      source_image_reference = vm.source_image_reference

      tags = vm.tags
    }
  }

  windows_virtual_machines = {
    for key, vm in var.windows_virtual_machines : key => {
      name                = vm.name
      resource_group_name = vm.resource_group_name
      location            = vm.location
      size                = vm.size

      admin_username = vm.admin_username
      admin_password = vm.admin_password

      network_interface_id = module.nic.network_interfaces[
        vm.nic_key
      ].id

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

  subnet_nsg_associations = var.subnet_nsg_associations

  subnets = module.network.subnets

  nsgs = module.nsg.network_security_groups
}



# INTERNAL LOAD BALANCER


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

        vnet_id = module.network.vnets[
          lb.vnet_key
        ].id

        private_ip_address = lb.frontend_ip_configuration.private_ip_address
      }

      backend_address_pool = {
        name        = lb.backend_address_pool.name
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

module "key_vault" {
  source = "../../modules/key-vault"

  key_vaults = var.key_vaults

  tags = var.tags
}


# ============================================================
# MONITORING
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
#
# Traffic:
#
# Internet
#    |
#    | HTTP :80
#    v
# Application Gateway WAF_v2
#    |
#    +---- / -----------------> Frontend VM :80
#    |
#    +---- /api/* ------------> Internal LB :8080
#                                  |
#                                  +----> Backend VM 01 :8080
#                                  |
#                                  +----> Backend VM 02 :8080
#
# Frontend pool:
#   frontend_vm_private_ips
#
# Backend pool:
#   ILB private IP = 10.20.2.10
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

      # --------------------------------------------------------
      # BACKEND POOLS
      # --------------------------------------------------------
      #
      # frontend -> Frontend VM private IPs
      # backend  -> Internal Load Balancer private IP
      #
      # Do NOT put backend VM IPs directly here.
      # App Gateway must send /api/* traffic to the ILB.
      # --------------------------------------------------------

      backend_address_pools = {
        frontend = {
          ip_addresses = local.frontend_vm_private_ips
        }

        backend = {
          ip_addresses = [
            module.internal_load_balancer
            .frontend_ip_configurations["backend"]
            .private_ip_address
          ]
        }
      }

      # --------------------------------------------------------
      # HEALTH PROBES
      # --------------------------------------------------------

      health_probes = gateway.health_probes

      # --------------------------------------------------------
      # BACKEND HTTP SETTINGS
      # --------------------------------------------------------

      backend_http_settings = gateway.backend_http_settings

      # --------------------------------------------------------
      # PATH-BASED ROUTING
      # --------------------------------------------------------

      request_routing_rule = gateway.request_routing_rule

      tags = gateway.tags
    }
  }

  tags = var.tags
}


# ============================================================
# PRIVATE DNS + PRIVATE ENDPOINTS
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


# ============================================================
# AZURE SQL
# ============================================================

module "sql" {
  source = "../../modules/sql"

  sql_servers   = var.sql_servers
  sql_databases = var.sql_databases

  tags = var.tags
}


# ============================================================
# POSTGRESQL
# ============================================================

module "postgresql" {
  source = "../../modules/postgresql"

  postgresql_servers   = var.postgresql_servers
  postgresql_databases = var.postgresql_databases

  tags = var.tags
}

