#using msi for access to azure
provider "azure" {
  subscription_id = var.subscription_id
  use_msi = true
  features {}
}