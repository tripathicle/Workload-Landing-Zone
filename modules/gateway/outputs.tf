output "application_gateways" {
  description = "Map of Application Gateways"
  value = {
    for key, gateway in azurerm_application_gateway.this : key => {
      id   = gateway.id
      name = gateway.name
    }
  }
}
