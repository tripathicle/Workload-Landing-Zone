output "terraform_state_resource_group" {
  description = "Resource group containing Terraform state storage."
  value       = azurerm_resource_group.tfstate.name
}

output "terraform_state_storage_account" {
  description = "Storage account used for Terraform remote state."
  value       = azurerm_storage_account.tfstate.name
}

output "terraform_state_container" {
  description = "Blob container used for Terraform remote state."
  value       = azurerm_storage_container.tfstate.name
}