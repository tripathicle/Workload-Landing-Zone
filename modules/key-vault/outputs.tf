output "key_vaults" {
  description = "Map of created Key Vault metadata"
  value = {
    for key, kv in azurerm_key_vault.this : key => {
      id   = kv.id
      name = kv.name
      vault_uri = kv.vault_uri
    }
  }
}
