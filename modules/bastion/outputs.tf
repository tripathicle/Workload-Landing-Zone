output "bastions" {
  description = "Map of Azure Bastion hosts"
  value = {
    for key, bastion in azurerm_bastion_host.this : key => {
      id   = bastion.id
      name = bastion.name
    }
  }
}
