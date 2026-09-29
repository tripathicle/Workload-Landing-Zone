output "load_balancers" {
  description = "Map of provisioned Azure Load Balancers."

  value = {
    for lb_key, lb in azurerm_lb.this :
    lb_key => {
      id                  = lb.id
      name                = lb.name
      location            = lb.location
      resource_group_name = lb.resource_group_name

      frontend_ip_address = [
        for frontend in lb.frontend_ip_configuration :
        frontend.private_ip_address
      ][0]
    }
  }
}

output "backend_address_pools" {
  description = "Map of Load Balancer backend address pools."

  value = {
    for lb_key, pool in azurerm_lb_backend_address_pool.this :
    lb_key => {
      id   = pool.id
      name = pool.name
    }
  }
}

output "health_probes" {
  description = "Map of Load Balancer health probes."

  value = {
    for lb_key, probe in azurerm_lb_probe.this :
    lb_key => {
      id   = probe.id
      name = probe.name
    }
  }
}