terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_postgresql_server" "psql-server" {
  name                = "psql-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  administrator_login          = data.azurerm_key_vault_secret.db-login.value
  administrator_login_password = data.azurerm_key_vault_secret.db-pwd.value

  sku_name   = "GP_Gen5_4"
  version    = "11"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

# resource "azurerm_postgresql_firewall_rule" "psql-fw" {
#   name                = "AllowAzureServices"
#   resource_group_name = data.azurerm_resource_group.rg.name
#   server_name         = azurerm_postgresql_server.psql-server.name
#   start_ip_address    = "0.0.0.0"
#   end_ip_address      = "0.0.0.0"
# }

resource "azurerm_service_plan" "service-plan" {
  name                = "plan-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_container_group" "pgadmin" {
   name                = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "aci-pgadmin-${var.project_name}${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 5432
      protocol = "TCP"
    }

    ports {
      port     = 15432
      protocol = "TCP"
    }

    environment_variables = {
      "PGADMIN_DEFAULT_EMAIL": data.azurerm_key_vault_secret.pgadmin-login.value,
      "PGADMIN_DEFAULT_PASSWORD": data.azurerm_key_vault_secret.pgadmin-pwd.value,
    }
  }
}

resource "azurerm_linux_web_app" "api" {
  name                = "web-${var.project_name}${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.service-plan.id

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

  connection_string {
    name = "DefaultConnection"
    value = "dbname='postgres' user='${data.azurerm_key_vault_secret.db-login.value}@${azurerm_postgresql_server.psql-server.name}' host='${azurerm_postgresql_server.psql-server.name}.postgres.database.azure.com' password='${data.azurerm_key_vault_secret.db-pwd.value}' port='5432' sslmode='true'"
    type = "PostgreSQL"
  }

  app_settings = {
    "POSTGRES_USERNAME": data.azurerm_key_vault_secret.db-login.value,
    "POSTGRES_PASSWORD": data.azurerm_key_vault_secret.db-pwd.value,
  }
}