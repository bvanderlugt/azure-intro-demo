# Dev environment.
# NOTE: If environment copied, change environment related values (e.g. "dev" -> "perf").

##### Terraform configuration #####
# NOTE: You need to source the Azure Blog storage access key first, e.g.:
# source  ~/.azure/azure-intro-demo.sh
# See scripts/create-azure-storage-account.sh and README.md how to create the Terraform backend
# and how to create the environment variable source file.



provider "azurerm" {
    version               = "~> 1.20"
}

# NOTE: Change here the values you supplied to the create-azure-storage-account.sh script!
terraform {
  backend "azurerm" {
    storage_account_name  = "pcterrastorage"
    container_name        = "pc-terraform-backend-states-container"
    key                   = "dev-azure-intro-demo-terraform.tfstate"
  }
}

# These values are per environment.
locals {
  my_prefix              = "intro-demo"
  my_env                 = "dev"
  my_location            = "westeurope"
  # Choose the address space.
  vnet_address_prefix                       = "10.50.0.0/16"
  private_application_subnet_address_prefix = "10.50.1.0/24"
}


# Here we inject our values to the environment definition module which creates all actual resources.
module "env-def" {
  source   = "../../modules/env-def"
  prefix   = "${local.my_prefix}"
  env      = "${local.my_env}"
  location = "${local.my_location}"

  vnet_address_prefix                       = "${local.vnet_address_prefix}"
  private_application_subnet_address_prefix = "${local.private_application_subnet_address_prefix}"
}

