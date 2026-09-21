# ============================================================
# APPLICATION GATEWAY OUTPUTS
# ============================================================

output "application_gateways" {
  description = "Map of provisioned Application Gateway resources."

  value = {
    for key, gateway in azurerm_application_gateway.this : key => {
      id   = gateway.id
      name = gateway.name
    }
  }
}