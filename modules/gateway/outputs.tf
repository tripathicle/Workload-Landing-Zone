output "application_gateways" {
  description = "Map of provisioned Application Gateways."

  value = {
    for gateway_key, gateway in azurerm_application_gateway.this :
    gateway_key => {
      id                  = gateway.id
      name                = gateway.name
      location            = gateway.location
      resource_group_name = gateway.resource_group_name
    }
  }
}