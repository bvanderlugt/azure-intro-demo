locals {
  my_name  = "${var.prefix}-${var.env}-${var.rg_name}"
  my_deployment   = "${var.prefix}-${var.env}"
}

resource "azurerm_resource_group" "resource-group" {
  name     = "${local.my_name}"
  location = "${var.location}"

  tags {
    Name        = "${local.my_name}"
    Deployment  = "${local.my_deployment}"
    Prefix      = "${var.prefix}"
    Environment = "${var.env}"
    Location    = "${var.location}"
    Terraform   = "true"
  }

}

