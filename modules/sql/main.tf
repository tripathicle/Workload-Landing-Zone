# ============================================================
# AZURE SQL SERVER
# ============================================================

resource "azurerm_mssql_server" "this" {
  #checkov:skip=CKV2_AZURE_45:SQL Private Endpoint is provisioned by the private-access module using this SQL Server resource ID; Checkov does not detect this cross-module graph relationship.

  for_each = var.sql_servers

  name = each.value.name

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  location = var.resource_groups[
    each.value.resource_group_key
  ].location

  version = each.value.version

  administrator_login = each.value.administrator_login

  administrator_login_password = var.administrator_password

  dynamic "azuread_administrator" {
    for_each = (
      each.value.azuread_administrator != null
      ? [each.value.azuread_administrator]
      : []
    )

    content {
      login_username = azuread_administrator.value.login_username
      object_id      = azuread_administrator.value.object_id
    }
  }

  minimum_tls_version = each.value.minimum_tls_version

  public_network_access_enabled = (
    each.value.public_network_access_enabled
  )

  tags = var.tags
}


# ============================================================
# AZURE SQL DATABASE
# ============================================================

resource "azurerm_mssql_database" "this" {
  #checkov:skip=CKV_AZURE_224:Ledger is not required for this dev workload and enabling it would introduce an unnecessary database feature requirement.
  #checkov:skip=CKV_AZURE_229:Zone redundancy is intentionally disabled for the Basic dev database SKU to avoid an unsupported or unnecessary availability configuration.

  for_each = {
    for key, server in var.sql_servers :
    key => server
    if server.database != null
  }

  name = each.value.database.name

  server_id = azurerm_mssql_server.this[
    each.key
  ].id

  sku_name = each.value.database.sku_name

  max_size_gb = each.value.database.max_size_gb

  zone_redundant = each.value.database.zone_redundant

  storage_account_type = (
    each.value.database.storage_account_type
  )

  tags = var.tags
}


# ============================================================
# SQL SERVER SECURITY ALERT POLICY
# ============================================================

resource "azurerm_mssql_server_security_alert_policy" "this" {
  #checkov:skip=CKV_AZURE_26:AzureRM provider 5.4.0 does not expose the email_account_admins attribute in the SQL Server security alert policy resource schema.
  #checkov:skip=CKV_AZURE_27:AzureRM provider 5.4.0 does not expose the email_addresses attribute in the SQL Server security alert policy resource schema.

  for_each = var.sql_servers

  resource_group_name = var.resource_groups[
    each.value.resource_group_key
  ].name

  server_name = azurerm_mssql_server.this[
    each.key
  ].name

  state = "Enabled"
}


# ============================================================
# SQL SERVER VULNERABILITY ASSESSMENT
# ============================================================


#checkov:skip=CKV2_AZURE_4:VA scan report email recipients are configured through the vulnerability_assessment input; Checkov 3.3.21 does not resolve the module-driven emails attribute.
#checkov:skip=CKV2_AZURE_5:VA admin and subscription owner notifications are enabled through the vulnerability_assessment input; Checkov 3.3.21 does not resolve the module-driven email_subscription_admins attribute.
resource "azurerm_mssql_server_vulnerability_assessment" "this" {
  #checkov:skip=CKV2_AZURE_4:VA scan report email recipients are configured through the vulnerability_assessment input; Checkov 3.3.21 does not resolve the module-driven emails attribute.
  #checkov:skip=CKV2_AZURE_5:VA admin and subscription owner notifications are enabled through the vulnerability_assessment input; Checkov 3.3.21 does not resolve the module-driven email_subscription_admins attribute.

  for_each = var.sql_servers

  server_security_alert_policy_id = (
    azurerm_mssql_server_security_alert_policy.this[
      each.key
    ].id
  )

  storage_container_path = format(
    "%s%s/",
    var.vulnerability_assessment_storage.storage_account.primary_blob_endpoint,
    var.vulnerability_assessment_storage.container.name
  )

  storage_account_access_key = (
    var.vulnerability_assessment_storage.storage_account.primary_access_key
  )

  recurring_scans {
    enabled = true

    email_subscription_admins = each.value.vulnerability_assessment.email_subscription_admins

    emails = each.value.vulnerability_assessment.emails
  }
}


# ============================================================
# SQL SERVER EXTENDED AUDITING POLICY
# ============================================================

resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  for_each = var.sql_servers

  server_id = azurerm_mssql_server.this[
    each.key
  ].id

  enabled = true

  log_monitoring_enabled = true

  retention_in_days = var.auditing_retention_days
}