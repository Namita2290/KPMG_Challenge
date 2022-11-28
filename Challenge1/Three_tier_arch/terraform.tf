terraform {
  required_version = ">= 0.14"
    required_providers {
        azure = {
            source = "hashicorp/azurerm"
            version = "2.89.0"
        }
  }
}