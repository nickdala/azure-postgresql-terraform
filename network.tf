resource "azurecaf_name" "vnet_name" {
  name          = local.application_name
  resource_type = "azurerm_virtual_network"
}

resource "azurerm_virtual_network" "network" {
  name                = azurecaf_name.vnet_name.result
  location            = local.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = local.network_cidr
}

# Create the data subnet
resource "azurecaf_name" "postgresql_subnet_name" {
  name          = local.application_name
  resource_type = "azurerm_subnet"
  suffixes      = ["postgresql"]
}

resource "azurerm_subnet" "postgresql_subnet" {
  name                 = azurecaf_name.postgresql_subnet_name.result
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = local.postgresql_subnet_cidr
  
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "Microsoft.DBforPostgreSQL/flexibleServers"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

