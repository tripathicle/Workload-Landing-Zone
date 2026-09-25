output "load_balancers" {
  description = "Created Load Balancers."

  value = {
    for key, lb in azurerm_lb.this : key => {
      id   = lb.id
      name = lb.name
    }
  }
}

output "frontend_ip_configurations" {
  description = "Load Balancer frontend IP configuration details."

  value = {
    for key, lb in azurerm_lb.this : key => {
      id = one([
        for frontend in lb.frontend_ip_configuration :
        frontend.id
        if frontend.name == var.load_balancers[key].frontend_ip_configuration.name
      ])

      private_ip_address = var.load_balancers[
        key
      ].frontend_ip_configuration.private_ip_address
    }
  }
}

output "backend_address_pools" {
  description = "Load Balancer backend address pools."

  value = {
    for key, pool in azurerm_lb_backend_address_pool.this : key => {
      id   = pool.id
      name = pool.name
    }
  }
}

output "health_probes" {
  description = "Load Balancer health probes."

  value = {
    for key, probe in azurerm_lb_probe.this : key => {
      id   = probe.id
      name = probe.name
    }
  }
}

output "rules" {
  description = "Load Balancer rules."

  value = {
    for key, rule in azurerm_lb_rule.this : key => {
      id   = rule.id
      name = rule.name
    }
  }
}