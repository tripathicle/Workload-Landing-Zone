output "public_ips" {
  description = "Map of provisioned Azure Public IP addresses keyed by the input public IP key."

  value = {
    for public_ip_key, public_ip in azurerm_public_ip.this :
    public_ip_key => {
      id                  = public_ip.id
      name                = public_ip.name
      ip_address          = public_ip.ip_address
      resource_group_name = public_ip.resource_group_name
      location            = public_ip.location
      sku                 = public_ip.sku
      allocation_method   = public_ip.allocation_method
    }
  }
}