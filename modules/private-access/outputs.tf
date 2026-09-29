# ============================================================
# PRIVATE ENDPOINT OUTPUTS
# ============================================================

output "private_endpoints" {
  description = "Map of provisioned Private Endpoints."

  value = {
    for pe_key, pe in azurerm_private_endpoint.this :
    pe_key => {
      id                  = pe.id
      name                = pe.name
      location            = pe.location
      resource_group_name = pe.resource_group_name
      subnet_id           = pe.subnet_id

      private_ip_address = (
        pe.private_service_connection[0].private_ip_address
      )

      network_interface_id = pe.network_interface[0].id
    }
  }
}


# ============================================================
# PRIVATE DNS ZONE OUTPUTS
# ============================================================

output "private_dns_zones" {
  description = "Map of provisioned Private DNS Zones."

  value = {
    for zone_key, zone in azurerm_private_dns_zone.this :
    zone_key => {
      id   = zone.id
      name = zone.name
    }
  }
}


# ============================================================
# PRIVATE DNS VNET LINK OUTPUTS
# ============================================================

output "private_dns_zone_vnet_links" {
  description = "Map of Private DNS Zone to VNet links."

  value = {
    for link_key, link in azurerm_private_dns_zone_virtual_network_link.this :
    link_key => {
      id                  = link.id
      name                = link.name
      private_dns_zone_id = link.private_dns_zone_id
      virtual_network_id  = link.virtual_network_id
    }
  }
}