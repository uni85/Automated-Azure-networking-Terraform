# 1. Connect to Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Reference your EXISTING Resource Group
data "azurerm_resource_group" "student_rg" {
  name = "azure-network-project" 
}

# 3. Create the HUB VNet
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = data.azurerm_resource_group.student_rg.location
  resource_group_name = data.azurerm_resource_group.student_rg.name
  address_space       = ["10.0.0.0/16"]
}

# 4. Create the SPOKE VNet
resource "azurerm_virtual_network" "spoke_prod" {
  name                = "vnet-spoke-prod"
  location            = data.azurerm_resource_group.student_rg.location
  resource_group_name = data.azurerm_resource_group.student_rg.name
  address_space       = ["10.1.0.0/16"]
}

# 5. Peering: HUB -> SPOKE
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-spoke"
  resource_group_name          = data.azurerm_resource_group.student_rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_prod.id
  allow_virtual_network_access = true
}

# 6. Peering: SPOKE -> HUB
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "spoke-to-hub"
  resource_group_name          = data.azurerm_resource_group.student_rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_prod.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
}