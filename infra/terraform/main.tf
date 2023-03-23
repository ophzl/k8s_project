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

  sku_name   = "B_Gen5_2"
  version    = "9.5"
  storage_mb = 5120

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

#   public_network_access_enabled    = true
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_postgresql_database" "pg-db" {
  name                = "pg-db"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.psql-server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_postgresql_firewall_rule" "psql-fw" {
  name                = "psql-fw"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.psql-server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

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
      port     = 80
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
      node_version = "16-lts"
    }
  }

  app_settings = {
    PORT                      = var.api_port
    DB_HOST                   = azurerm_postgresql_server.psql-server.fqdn
    DB_USERNAME               = "${data.azurerm_key_vault_secret.db-login.value}@${azurerm_postgresql_server.psql-server.name}"
    DB_PASSWORD               = data.azurerm_key_vault_secret.db-pwd.value
    DB_DATABASE               = azurerm_postgresql_database.pg-db.name
    DB_DAILECT                = "postgres"
    DB_PORT                   = 5432
    ACCESS_TOKEN_SECRET       = data.azurerm_key_vault_secret.access-token-secret.value
    REFRESH_TOKEN_SECRET      = data.azurerm_key_vault_secret.refresh-token-secret.value
    ACCESS_TOKEN_EXPIRY       = var.access_token_expiry
    REFRESH_TOKEN_EXPIRY      = var.refresh_token_expiry
    REFRESH_TOKEN_COOKIE_NAME = var.refresh_token_cookie_name
  }
}