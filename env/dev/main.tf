# ============================================================
# RESOURCE GROUP MODULE
# ============================================================

module "resource_group" {
  source = "../../modules/resource_group"

  resource_groups = var.resource_groups
  tags            = var.tags
}


# ============================================================
# STORAGE ACCOUNT MODULE
# ============================================================

module "storage_account" {
  source = "../../modules/storage_account"

  storage_accounts = var.storage_accounts
  resource_groups  = module.resource_group.resource_groups
  tags             = var.tags
}


# ============================================================
# VNET MODULE
# ============================================================

module "vnet" {
  source = "../../modules/virtual_network"

  vnets           = var.vnets
  resource_groups = module.resource_group.resource_groups
  tags            = var.tags
}


# ============================================================
# SUBNET MODULE
# ============================================================

module "subnet" {
  source = "../../modules/subnets"

  subnets = var.subnets
  vnets   = module.vnet.vnets
}


# ============================================================
# VNET PEERING MODULE
# ============================================================

module "vnet_peering" {
  source = "../../modules/vnet_peering"

  vnet_peerings = var.vnet_peerings
  vnets         = module.vnet.vnets
}


# ============================================================
# PUBLIC IP MODULE
# ============================================================

module "public_ip" {
  source = "../../modules/public-ip"

  public_ips      = var.public_ips
  resource_groups = module.resource_group.resource_groups
  tags            = var.tags
}


# ============================================================
# NSG MODULE
# ============================================================

module "nsg" {
  source = "../../modules/nsg"

  network_security_groups = var.network_security_groups
  resource_groups         = module.resource_group.resource_groups
  tags                    = var.tags
}


# ============================================================
# NSG ASSOCIATION MODULE
# ============================================================

module "nsg_association" {
  source = "../../modules/nsg-association"

  nsg_associations        = var.nsg_associations
  network_security_groups = module.nsg.network_security_groups
  subnets                 = module.subnet.subnets
}


# ============================================================
# INTERNAL LOAD BALANCER MODULE
# ============================================================

module "lb" {
  source = "../../modules/lb"

  load_balancers = var.load_balancers

  resource_groups = module.resource_group.resource_groups
  subnets         = module.subnet.subnets

  tags = var.tags
}


# ============================================================
# NETWORK INTERFACE MODULE
# ============================================================

module "nic" {
  source = "../../modules/nic"

  network_interfaces = var.network_interfaces

  resource_groups = module.resource_group.resource_groups
  subnets         = module.subnet.subnets

  backend_address_pools = module.lb.backend_address_pools

  tags = var.tags
}


# ============================================================
# VIRTUAL MACHINES
# ============================================================


module "vm" {
  source = "../../modules/vm"

  virtual_machines = {
    for key, vm in var.virtual_machines :
    key => merge(
      vm,
      {
        admin_ssh_key = (
          vm.os_type == "Linux"
          ? var.admin_ssh_public_key
          : try(vm.admin_ssh_key, null)
        )
      }
    )
  }

  resource_groups    = module.resource_group.resource_groups
  network_interfaces = module.nic.network_interfaces

  tags = var.tags
}





# ============================================================
# APPLICATION GATEWAY / WAF MODULE
# ============================================================

module "gateway" {
  source = "../../modules/gateway"

  application_gateways = var.application_gateways
  resource_groups      = module.resource_group.resource_groups
  subnets              = module.subnet.subnets
  public_ips           = module.public_ip.public_ips
  tags                 = var.tags
}


# ============================================================
# AZURE BASTION MODULE
# ============================================================

module "bastion" {
  source = "../../modules/bastion"

  bastions = var.bastions

  resource_groups = module.resource_group.resource_groups
  subnets         = module.subnet.subnets
  public_ips      = module.public_ip.public_ips

  tags = var.tags
}


# ============================================================
# AZURE SQL
# ============================================================

module "sql" {
  source = "../../modules/sql"

  sql_servers = var.sql_servers

  resource_groups = module.resource_group.resource_groups

  administrator_password = var.sql_admin_password

  tags = var.tags
}


# ============================================================
# POSTGRESQL FLEXIBLE SERVER
# ============================================================

module "postgresql" {
  source = "../../modules/postgresql"

  postgresql_servers = var.postgresql_servers

  resource_groups = module.resource_group.resource_groups

  administrator_password = var.postgresql_admin_password

  tags = var.tags
}


# ============================================================
# PRIVATE ACCESS
#
# Creates:
#   - Private DNS Zones
#   - Private DNS Zone -> VNet Links
#   - Private Endpoints
# ============================================================

module "private_access" {
  source = "../../modules/private-access"

  private_endpoints = local.private_endpoints

  private_dns_zones = var.private_dns_zones

  private_dns_zone_vnet_links = (
    var.private_dns_zone_vnet_links
  )

  resource_groups = module.resource_group.resource_groups

  subnets = module.subnet.subnets

  vnets = module.vnet.vnets

  tags = var.tags
}


# ============================================================
# KEY VAULT
#
# Creates:
#   - Azure Key Vault
#   - RBAC authorization
#   - Soft delete
#   - Purge protection
#
# No secrets are created at this stage.
# ============================================================

module "key_vault" {
  source = "../../modules/key-vault"

  key_vaults = var.key_vaults

  resource_groups = module.resource_group.resource_groups

  tags = var.tags
}


# ============================================================
# MONITORING
#
# Creates:
#   - Log Analytics Workspace
#   - Workspace-based Application Insights
#
# Diagnostic settings and alerts will be added separately.
# ============================================================

module "monitoring" {
  source = "../../modules/monitoring"

  monitoring = var.monitoring

  resource_groups = module.resource_group.resource_groups

  tags = var.tags
}