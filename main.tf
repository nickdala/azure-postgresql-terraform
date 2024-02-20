terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.92.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    } 
  }
}

locals {
  application_name = "example"
  location = "eastus"

  network_cidr = ["10.0.0.0/16"]
  postgresql_subnet_cidr = ["10.0.2.0/27"]

  postgresql_sku_name = "GP_Standard_D4s_v3"
}

resource "azurecaf_name" "resource_group" {
  name          = local.application_name
  resource_type = "azurerm_resource_group"
}

resource "azurerm_resource_group" "resource_group" {
  name     = azurecaf_name.resource_group.result
  location = local.location
}
