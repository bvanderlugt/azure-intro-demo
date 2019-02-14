locals {
  my_name = "${var.prefix}-${var.env}-vnet"
  my_env = "${var.prefix}-${var.env}"
}


resource "azurerm_virtual_network" "vm-vnet" {
  name = "${local.my_name}"
  location = "${var.location}"
  address_space = ["${var.vnet_address_prefix}"]
  resource_group_name = "${var.rg_name}"

  tags {
    Name        = "${local.my_name}"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Location    = "${var.location}"
    Terraform   = "true"
  }
}


resource "azurerm_subnet" "private_application_subnet" {
  name                 = "${local.my_name}-private-application-subnet"
  address_prefix       = "${var.private_application_subnet_address_prefix}"
  resource_group_name  = "${var.rg_name}"
  virtual_network_name = "${azurerm_virtual_network.vm-vnet.name}"
  # NOTE: This field will be depricated in terraform 2.0 but now required or nw-sg will be disassociated with every terraform apply.
  network_security_group_id  = "${azurerm_network_security_group.private_application_subnet_nw_sg.id}"
}


resource "azurerm_network_security_group" "private_application_subnet_nw_sg" {
  name                = "${local.my_name}-private-application-subnet-nw-sg"
  location            = "${var.location}"
  resource_group_name = "${var.rg_name}"

  tags {
    Name        = "${local.my_name}"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Location    = "${var.location}"
    Terraform   = "true"
  }
}


resource "azurerm_subnet_network_security_group_association" "private_application_subnet_assoc" {
  subnet_id                 = "${azurerm_subnet.private_application_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.private_application_subnet_nw_sg.id}"
}


resource "azurerm_network_security_rule" "private_application_subnet_ssh_22_rule" {
  name = "${local.my_name}-private-application-subnet-nw-sg-allow-ssh-22-rule"
  priority                    = 250
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "${var.private_application_subnet_address_prefix}"
  resource_group_name         = "${var.rg_name}"
  network_security_group_name = "${azurerm_network_security_group.private_application_subnet_nw_sg.name}"
}

