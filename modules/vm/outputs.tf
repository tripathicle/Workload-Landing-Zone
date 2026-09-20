output "linux_virtual_machines" {
  description = "Map of Linux VMs"
  value = {
    for key, vm in azurerm_linux_virtual_machine.this : key => {
      id   = vm.id
      name = vm.name
    }
  }
}
