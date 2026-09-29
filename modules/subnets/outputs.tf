output "subnets" {
  description = "Map of provisioned Azure Subnets keyed by the input subnet key."

  value = {
    for subnet_key, subnet in azurerm_subnet.this :
    subnet_key => {
      id               = subnet.id
      name             = subnet.name
      address_prefixes = subnet.address_prefixes
    }
  }
}