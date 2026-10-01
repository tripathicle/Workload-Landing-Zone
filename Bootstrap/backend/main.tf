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
  #checkov:skip=CKV_AZURE_33:Azure Storage Queue service is not used by the Terraform state storage account; Queue logging is not applicable.
  #checkov:skip=CKV_AZURE_206:LRS replication is intentionally selected for this Terraform state storage account to avoid unnecessary redundancy and associated cost.
  #checkov:skip=CKV2_AZURE_1:Customer-managed encryption is not used for the bootstrap state storage account; Azure Storage platform-managed encryption is used.
  #checkov:skip=CKV2_AZURE_21:Terraform state uses the private tfstate container and does not require Storage Blob read logging for this bootstrap workload.
  #checkov:skip=CKV2_AZURE_33:Private Endpoint is intentionally not configured for the bootstrap state storage account because the bootstrap creates the remote-state storage itself; adding a Private Endpoint would require separate pre-existing private networking and runner connectivity.

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
  shared_access_key_enabled        = false

  sas_policy {
    expiration_period = "7.00:00:00"
    expiration_action = "Log"
  }

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