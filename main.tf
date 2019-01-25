provider "azurerm" {
  version = "1.21"
}

resource "azurerm_resource_group" "rg" {
  name     = "Kubernetes"
  location = "West Europe"
}

