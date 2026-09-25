output "linux_virtual_machines" {
  description = "Map of provisioned Linux virtual machines."

  value = {
    for key, vm in azurerm_linux_virtual_machine.this : key => {
      id   = vm.id
      name = vm.name
    }
  }
}


output "windows_virtual_machines" {
  description = "Map of provisioned Windows virtual machines."

  value = {
    for key, vm in azurerm_windows_virtual_machine.this : key => {
      id   = vm.id
      name = vm.name
    }
  }
}