output "bastions" {
  description = "Map of provisioned Azure Bastion hosts."

  value = {
    for bastion_key, bastion in azurerm_bastion_host.this :
    bastion_key => {
      id                  = bastion.id
      name                = bastion.name
      location            = bastion.location
      resource_group_name = bastion.resource_group_name
    }
  }
}