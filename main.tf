// Tags
locals {
  tags = {
    class      = var.tag_class
    instructor = var.tag_instructor
    semester   = var.tag_semester
  }
}

// Existing Resources

/// Subscription ID

# data "azurerm_subscription" "current" {
# }

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "rg-dsba6190-gspence8-dev-eastus-${random_integer.deployment_id_suffix.result}"
  location = "East US"

  tags = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dsba6190-gspence8-dev-eastus-${random_integer.deployment_id_suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${random_integer.deployment_id_suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.rg.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}

// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "stodsba6190gspence8dev${random_integer.deployment_id_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Hierarchical namespace
  tags                     = local.tags

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  }
}

resource "azurerm_mssql_server" "sql" {
  name                         = "sql-dsba6190-gspence8-dev-${random_integer.deployment_id_suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"     # Update with your admin username
  administrator_login_password = "P@ssword1234" # Update with a secure password
  tags                         = local.tags
}

resource "azurerm_mssql_database" "database" {
  name         = "dbdsba6190gspence8dev${random_integer.deployment_id_suffix.result}"
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"
  tags         = local.tags
}

resource "azurerm_mssql_virtual_network_rule" "vnet_rule" {
  name      = "sql-vnet-rule"
  server_id = azurerm_sql_server.sql.id
  subnet_id = azurerm_subnet.subnet.id
}
