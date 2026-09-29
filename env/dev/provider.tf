terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-hubandspokewl"
    storage_account_name = "sttfstatehubandspokewl"
    container_name       = "tfstate"
    key                  = "workload/dev.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = "95c42c0d-f71d-4420-8a12-f3157ba3471d"
}