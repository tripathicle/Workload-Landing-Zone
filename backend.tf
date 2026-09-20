terraform {
  backend "azurerm" {
    # Replace these values with the real Azure state storage settings before first deployment.
    resource_group_name  = "<REPLACE_WITH_TFSTATE_RESOURCE_GROUP>"
    storage_account_name = "<REPLACE_WITH_TFSTATE_STORAGE_ACCOUNT>"
    container_name       = "<REPLACE_WITH_TFSTATE_CONTAINER>"
    key                  = "dev.terraform.tfstate"
  }
}
