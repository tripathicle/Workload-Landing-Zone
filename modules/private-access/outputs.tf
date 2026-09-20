output "private_dns_zones" {
  description = "Map of created private DNS zones"
  value = {
    for key, zone in azurerm_private_dns_zone.this : key => {
      id   = zone.id
      name = zone.name
    }
  }
}

output "private_endpoints" {
  description = "Map of created private endpoints"
  value = {
    for key, endpoint in azurerm_private_endpoint.this : key => {
      id   = endpoint.id
      name = endpoint.name
    }
  }
}
