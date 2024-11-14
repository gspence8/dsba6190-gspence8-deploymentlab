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
  name                = "vnet-dsba6190-cford38-dev-eastus-${random_integer.deployment_id_suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
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

  tags = local.tags

  network_rules {
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  }  
}

resource "azurerm_sql_server" "sql" {
  name                         = "sql-dsba6190-cford38-dev-001"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"   # Update with your admin username
  administrator_login_password = "P@ssword1234"  # Update with a secure password
}

resource "azurerm_sql_database" "database" {
  name                = "db-dsba6190-cford38-dev-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  server_name         = azurerm_sql_server.sql.name
  sku_name            = "Basic"
}

resource "azurerm_sql_virtual_network_rule" "vnet_rule" {
  name             = "sql-vnet-rule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name      = azurerm_sql_server.sql.name
  subnet_id        = azurerm_subnet.subnet.id
}
