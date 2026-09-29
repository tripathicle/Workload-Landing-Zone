terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ============================================================
# TERRAFORM STATE RESOURCE GROUP
# ============================================================

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate-hubandspokewl"
  location = "Japan East"

  tags = {
    environment = "platform"
    managed_by  = "terraform"
    owner       = "platform-team"
    purpose     = "terraform-state"
  }
}

# ============================================================
# TERRAFORM STATE STORAGE ACCOUNT
# ============================================================

resource "azurerm_storage_account" "tfstate" {
  name                = "sttfstatehubandspokewl"
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  public_network_access_enabled = true

  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    environment = "platform"
    managed_by  = "terraform"
    owner       = "platform-team"
    purpose     = "terraform-state"
  }
}

# ============================================================
# TERRAFORM STATE CONTAINER
# ============================================================

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}