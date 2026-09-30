output "virtual_machines" {
  description = "All provisioned Virtual Machines."

  value = merge(
    {
      for key, vm in azurerm_linux_virtual_machine.this :
      key => {
        id            = vm.id
        name          = vm.name
        computer_name = vm.computer_name
        private_ip_address = var.network_interfaces[
          var.virtual_machines[key].nic_key
        ].private_ip_address
        resource_group_key = var.virtual_machines[key].resource_group_key
        nic_key            = var.virtual_machines[key].nic_key
        os_type            = "Linux"
      }
    },
    {
      for key, vm in azurerm_windows_virtual_machine.this :
      key => {
        id            = vm.id
        name          = vm.name
        computer_name = vm.computer_name
        private_ip_address = var.network_interfaces[
          var.virtual_machines[key].nic_key
        ].private_ip_address
        resource_group_key = var.virtual_machines[key].resource_group_key
        nic_key            = var.virtual_machines[key].nic_key
        os_type            = "Windows"
      }
    }
  )
}


output "linux_virtual_machines" {
  description = "Provisioned Linux Virtual Machines."

  value = {
    for key, vm in azurerm_linux_virtual_machine.this :
    key => {
      id            = vm.id
      name          = vm.name
      computer_name = vm.computer_name
      private_ip_address = var.network_interfaces[
        var.virtual_machines[key].nic_key
      ].private_ip_address
      resource_group_key = var.virtual_machines[key].resource_group_key
      nic_key            = var.virtual_machines[key].nic_key
      os_type            = "Linux"
    }
  }
}


output "windows_virtual_machines" {
  description = "Provisioned Windows Virtual Machines."

  value = {
    for key, vm in azurerm_windows_virtual_machine.this :
    key => {
      id            = vm.id
      name          = vm.name
      computer_name = vm.computer_name
      private_ip_address = var.network_interfaces[
        var.virtual_machines[key].nic_key
      ].private_ip_address
      resource_group_key = var.virtual_machines[key].resource_group_key
      nic_key            = var.virtual_machines[key].nic_key
      os_type            = "Windows"
    }
  }
}