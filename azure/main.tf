provider "azurerm" {
  features {}
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}  

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.46.0"
    }
  }
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-resource-group"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-cluster"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "acr" {
  name                     = "myacr123"
  resource_group_name      = azurerm_resource_group.aks_rg.name
  location                 = azurerm_resource_group.aks_rg.location
  sku                      = "Basic"
  admin_enabled            = false
}

resource "azurerm_kubernetes_cluster_node_pool" "aks_node_pool" {
  name                = "nodepool1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  node_count          = 1
  vm_size             = "Standard_DS2_v2"
  availability_zones  = [1, 2, 3]
}

resource "azurerm_kubernetes_cluster_node_pool" "acr_integration_node_pool" {
  name                = "nodepool2"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  node_count          = 1
  vm_size             = "Standard_DS2_v2"
  availability_zones  = [1, 2, 3]
  node_labels = {
    "acr-integration" = "enabled"
  }
  tags = {
    environment = "dev"
  }
}

resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id        = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope               = azurerm_container_registry.acr.id
}