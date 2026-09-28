# ============================================================
# PRIVATE ACCESS
# ============================================================

locals {
  workload_name = "hubandspokewl"

  # ----------------------------------------------------------
  # Private Endpoint Names
  # ----------------------------------------------------------

  private_endpoint_names = {
    sql = "pe-sql-${local.workload_name}-${var.environment}"

    postgresql = "pe-postgresql-${local.workload_name}-${var.environment}"

    key_vault = "pe-keyvault-${local.workload_name}-${var.environment}"
  }

  # ----------------------------------------------------------
  # Private Service Connection Names
  # ----------------------------------------------------------

  private_service_connection_names = {
    sql = "psc-sql-${local.workload_name}-${var.environment}"

    postgresql = "psc-postgresql-${local.workload_name}-${var.environment}"

    key_vault = "psc-keyvault-${local.workload_name}-${var.environment}"
  }

  # ----------------------------------------------------------
  # Private DNS Zone Group Names
  # ----------------------------------------------------------

  private_dns_zone_group_names = {
    sql        = "sql-dns-zone-group"
    postgresql = "postgresql-dns-zone-group"
    key_vault  = "keyvault-dns-zone-group"
  }

  # ----------------------------------------------------------
  # Private Endpoints
  #
  # Resource IDs are taken directly from module outputs.
  # No hardcoded Azure resource IDs.
  # ----------------------------------------------------------

  private_endpoints = {

    # ========================================================
    # AZURE SQL PRIVATE ENDPOINT
    # ========================================================

    sql = {
      name = local.private_endpoint_names.sql

      resource_group_key = "data"
      subnet_key         = "private_endpoint"

      private_service_connection = {
        name = local.private_service_connection_names.sql

        private_connection_resource_id = (
          module.sql.sql_servers["primary"].id
        )

        subresource_names = [
          "sqlServer"
        ]

        is_manual_connection = false
      }

      private_dns_zone_group = {
        name         = local.private_dns_zone_group_names.sql
        dns_zone_key = "sql"
      }
    }

    # ========================================================
    # POSTGRESQL PRIVATE ENDPOINT
    # ========================================================

    postgresql = {
      name = local.private_endpoint_names.postgresql

      resource_group_key = "data"
      subnet_key         = "private_endpoint"

      private_service_connection = {
        name = local.private_service_connection_names.postgresql

        private_connection_resource_id = (
          module.postgresql.postgresql_servers["primary"].id
        )

        subresource_names = [
          "postgresqlServer"
        ]

        is_manual_connection = false
      }

      private_dns_zone_group = {
        name         = local.private_dns_zone_group_names.postgresql
        dns_zone_key = "postgresql"
      }
    }

    # ========================================================
    # AZURE KEY VAULT PRIVATE ENDPOINT
    # ========================================================

    key_vault = {
      name = local.private_endpoint_names.key_vault

      resource_group_key = "app"
      subnet_key         = "private_endpoint"

      private_service_connection = {
        name = local.private_service_connection_names.key_vault

        private_connection_resource_id = (
          module.key_vault.key_vaults["workload"].id
        )

        subresource_names = [
          "vault"
        ]

        is_manual_connection = false
      }

      private_dns_zone_group = {
        name         = local.private_dns_zone_group_names.key_vault
        dns_zone_key = "keyvault"
      }
    }
  }
}