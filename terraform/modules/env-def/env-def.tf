# NOTE: This is the environment definition that will be used by all environments.
# The actual environments (like dev) just inject their environment dependent values to env-def which defines the actual environment and creates that environment using given values.


# Main resource group for the demonstration.
module "main-resource-group" {
  source                    = "../resource-group"
  prefix                    = "${var.prefix}"
  env                       = "${var.env}"
  location                  = "${var.location}"
  rg_name                   = "main-rg"
}


module "vnet" {
  source          = "../vnet"
  prefix          = "${var.prefix}"
  env             = "${var.env}"
  location        = "${var.location}"
  rg_name         = "${module.main-resource-group.resource_group_name}"

  vnet_address_prefix                       = "${var.vnet_address_prefix}"
  private_application_subnet_address_prefix = "${var.private_application_subnet_address_prefix}"
}


module "vm" {
  source                        = "../vm"
  prefix                        = "${var.prefix}"
  env                           = "${var.env}"
  location                      = "${var.location}"
  rg_name                       = "${module.main-resource-group.resource_group_name}"
  private_application_subnet_id = "${module.vnet.private_application_subnet_id}"
}

