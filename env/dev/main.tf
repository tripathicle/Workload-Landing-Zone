module "resource_groups" {
  source = "../../modules/rg"

  location        = var.location
  tags            = var.tags
  resource_groups = var.resource_groups
}

module "storage_accounts" {
  source = "../../modules/sa"

  location         = var.location
  tags             = var.tags
  storage_accounts = var.storage_accounts
}

module "network" {
  source = "../../modules/network"

  location = var.location
  tags     = var.tags
  vnets    = var.vnets
}

# module "app" {
#   source = "../../modules/app"
#
#   app_service_plan = var.app_service_plan
#   linux_web_apps   = var.linux_web_apps
#   sql_servers      = var.sql_servers
#   sql_databases    = var.sql_databases
#   tags             = var.tags
# }

module "key_vault" {
  source = "../../modules/key-vault"

  key_vaults = var.key_vaults
  tags       = var.tags
}

module "internal_load_balancer" {
  source = "../../modules/lb"

  load_balancers = {
    for name, lb in var.load_balancers : name => {
      name                = lb.name
      resource_group_name = lb.resource_group_name
      location            = lb.location
      sku                 = lb.sku
      frontend_ip_configuration = {
        name                 = lb.frontend_ip_configuration.name
        subnet_id            = module.network.subnets["${lb.vnet_key}-${lb.subnet_key}"].id
        private_ip_address   = lb.frontend_ip_configuration.private_ip_address
        private_ip_addresses = lb.frontend_ip_configuration.private_ip_addresses
      }
      backend_address_pool = {
        name         = lb.backend_address_pool.name
        ip_addresses = local.backend_vm_private_ips
      }
      health_probe = merge(lb.health_probe, {
        port = try(lb.health_probe.port, 8080)
        path = try(lb.health_probe.path, "/health")
      })
      lb_rule = merge(lb.lb_rule, {
        frontend_port = try(lb.lb_rule.frontend_port, 8080)
        backend_port  = try(lb.lb_rule.backend_port, 8080)
      })
      tags = lb.tags
    }
  }
  tags = var.tags
}

module "nsg" {
  source = "../../modules/nsg"

  network_security_groups = var.network_security_groups
  tags                    = var.tags
}

module "nic" {
  source = "../../modules/nic"

  network_interfaces = {
    for key, nic in var.network_interfaces : key => {
      name                = nic.name
      resource_group_name = nic.resource_group_name
      location            = nic.location
      ip_configuration = {
        name                          = nic.ip_configuration.name
        subnet_id                     = module.network.subnets["${nic.vnet_key}-${nic.subnet_key}"].id
        private_ip_address_allocation = nic.ip_configuration.private_ip_address_allocation
        private_ip_address            = try(nic.ip_configuration.private_ip_address, null)
      }
      tags = nic.tags
    }
  }
  tags = var.tags
}

module "vm" {
  source = "../../modules/vm"

  linux_virtual_machines = {
    for key, vm in var.linux_virtual_machines : key => {
      name                   = vm.name
      resource_group_name    = vm.resource_group_name
      location               = vm.location
      size                   = vm.size
      admin_username         = vm.admin_username
      admin_password         = vm.admin_password
      admin_ssh_key          = vm.admin_ssh_key
      network_interface_id   = module.nic.network_interfaces[vm.nic_key].id
      custom_data            = vm.custom_data
      os_disk                = vm.os_disk
      source_image_reference = vm.source_image_reference
      tags                   = vm.tags
    }
  }
  tags = var.tags
}

module "subnet_nsg_association" {
  source = "../../modules/nsg-association"

  subnet_nsg_associations = {
    frontend = {
      subnet_name                 = "spoke-frontend"
      network_security_group_name = "frontend"
    }
    backend = {
      subnet_name                 = "spoke-backend"
      network_security_group_name = "backend"
    }
    private_endpoint = {
      subnet_name                 = "spoke-private_endpoint"
      network_security_group_name = "private_endpoint"
    }
  }

  subnets = module.network.subnets
  nsgs    = module.nsg.network_security_groups
}

module "public_ip" {
  source = "../../modules/public-ip"

  public_ips = var.public_ips
  tags       = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  log_analytics_workspaces = var.log_analytics_workspaces
  application_insights     = var.application_insights
  tags                     = var.tags
}

locals {
  frontend_vm_private_ips = [
    for key, nic in var.network_interfaces : nic.ip_configuration.private_ip_address
    if startswith(key, "frontend_") && nic.ip_configuration.private_ip_address != null
  ]
  backend_vm_private_ips = [
    for key, nic in var.network_interfaces : nic.ip_configuration.private_ip_address
    if startswith(key, "backend_") && nic.ip_configuration.private_ip_address != null
  ]
}

module "gateway" {
  source = "../../modules/gateway"

  application_gateways = {
    for name, gateway in var.application_gateways : name => {
      name                = gateway.name
      resource_group_name = gateway.resource_group_name
      location            = gateway.location

      sku = gateway.sku

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

      health_probe = {
        name                = gateway.health_probe.name
        protocol            = gateway.health_probe.protocol
        port                = gateway.health_probe.port
        path                = gateway.health_probe.path
        interval            = gateway.health_probe.interval
        timeout             = gateway.health_probe.timeout
        unhealthy_threshold = gateway.health_probe.unhealthy_threshold
      }

      backend_http_settings = gateway.backend_http_settings

      tags = gateway.tags
    }
  }

  tags = var.tags
}
module "private_access" {
  source = "../../modules/private-access"

  private_dns_zones = {
    for key, zone in var.private_dns_zones : key => {
      name                = zone.name
      resource_group_name = zone.resource_group_name
      virtual_network_id  = module.network.vnets[zone.vnet_key].id
      tags                = zone.tags
    }
  }

  private_endpoints = {
    for key, endpoint in var.private_endpoints : key => {
      name                       = endpoint.name
      location                   = endpoint.location
      resource_group_name        = endpoint.resource_group_name
      subnet_id                  = module.network.subnets["${endpoint.vnet_key}-${endpoint.subnet_key}"].id
      private_service_connection = endpoint.private_service_connection
      private_dns_zone_group     = endpoint.private_dns_zone_group
      tags                       = endpoint.tags
    }
  }
  tags = var.tags
}

module "bastion" {
  source = "../../modules/bastion"

  bastions = {
    for key, bastion in var.bastions : key => {
      name                 = bastion.name
      resource_group_name  = bastion.resource_group_name
      location             = bastion.location
      subnet_id            = module.network.subnets["${bastion.vnet_key}-${bastion.subnet_key}"].id
      public_ip_address_id = module.public_ip.public_ips[bastion.public_ip_key].id
      tags                 = bastion.tags
    }
  }
  tags = var.tags
}

