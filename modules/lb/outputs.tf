# ============================================================
# LOAD BALANCER OUTPUTS
# ============================================================

output "load_balancers" {
  description = "Map of provisioned internal load balancers."

  value = {
    for key, lb in azurerm_lb.this : key => {
      id   = lb.id
      name = lb.name

      frontend_ip_configuration = {
        id                 = lb.frontend_ip_configuration[0].id
        name               = lb.frontend_ip_configuration[0].name
        private_ip_address = lb.frontend_ip_configuration[0].private_ip_address
      }
    }
  }
}