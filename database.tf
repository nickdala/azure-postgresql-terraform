resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Azure Private DNS provides a reliable, secure DNS service to manage and
# resolve domain names in a virtual network without the need to add a custom DNS solution
# https://docs.microsoft.com/azure/dns/private-dns-privatednszone
resource "azurerm_private_dns_zone" "postgresql_database" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.resource_group.name
}

# After you create a private DNS zone in Azure, you'll need to link a virtual network to it.
# https://docs.microsoft.com/azure/dns/private-dns-virtual-network-links
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_database" {
  name                  = azurerm_private_dns_zone.postgresql_database.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_database.name
  virtual_network_id    = azurerm_virtual_network.network.id
  resource_group_name   = azurerm_resource_group.resource_group.name

  depends_on = [ azurerm_subnet.postgresql_subnet ]
}

resource "azurecaf_name" "postgresql_server" {
  name          = local.application_name
  resource_type = "azurerm_postgresql_flexible_server"
}

resource "azurerm_postgresql_flexible_server" "postgresql_database" {
  name                = azurecaf_name.postgresql_server.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = local.location

  administrator_login    = "pgadmin"
  administrator_password = random_password.password.result

  sku_name                     = local.postgresql_sku_name
  version                      = "16"

  delegated_subnet_id          = azurerm_subnet.postgresql_subnet.id
  private_dns_zone_id          = azurerm_private_dns_zone.postgresql_database.id

  geo_redundant_backup_enabled = false
  
  high_availability {
    mode = "ZoneRedundant"
    standby_availability_zone = 2
  }
  zone = 1

  storage_mb = 32768

  authentication {
    password_auth_enabled          = true    
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql_database]
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  name                = "${local.application_name}db"
  server_id           = azurerm_postgresql_flexible_server.postgresql_database.id
}

############################################################################################################
# 2nd database
############################################################################################################

resource "azurecaf_name" "postgresql_server2" {
  name          = "${local.application_name}2"
  resource_type = "azurerm_postgresql_flexible_server"
}

resource "azurerm_postgresql_flexible_server" "postgresql_database2" {
  name                = azurecaf_name.postgresql_server2.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = local.location

  administrator_login    = "pgadmin"
  administrator_password = random_password.password.result

  sku_name                     = local.postgresql_sku_name
  version                      = "16"

  delegated_subnet_id          = azurerm_subnet.postgresql_subnet.id
  private_dns_zone_id          = azurerm_private_dns_zone.postgresql_database.id

  geo_redundant_backup_enabled = false

  high_availability {
    mode = "ZoneRedundant"
    standby_availability_zone = 2
  }
  
  zone = 1

  storage_mb = 32768

  create_mode = "Replica"
  source_server_id = azurerm_postgresql_flexible_server.postgresql_database.id

  authentication {
    password_auth_enabled          = true    
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql_database]
}