# ============================================================
# KEY VAULT OUTPUTS
# ============================================================

output "key_vaults" {
  description = "Map of provisioned Azure Key Vaults."

  value = {
    for key, vault in azurerm_key_vault.this :
    key => {
      id                  = vault.id
      name                = vault.name
      resource_group_name = vault.resource_group_name
      location            = vault.location
    }
  }
}