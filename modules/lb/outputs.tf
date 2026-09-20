output "load_balancers" {
  description = "Map of internal load balancers"
  value = {
    for key, lb in azurerm_lb.this : key => {
      id   = lb.id
      name = lb.name
      frontend_ip_configuration = lb.frontend_ip_configuration
    }
  }
}
