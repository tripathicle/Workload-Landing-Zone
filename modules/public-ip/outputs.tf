output "public_ips" {
  description = "Map of public IP resource metadata"
  value = {
    for key, ip in azurerm_public_ip.this : key => {
      id   = ip.id
      name = ip.name
      ip   = ip.ip_address
    }
  }
}
