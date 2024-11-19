terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.9.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "xxxx"
  client_id       = "ssssssssss"
  client_secret   = "ddddddddd"
  tenant_id       = "xxxxxsssssssssss"
}