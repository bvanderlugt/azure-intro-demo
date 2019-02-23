locals {
  my_name  = "${var.prefix}-${var.env}-vm"
  my_env   = "${var.prefix}-${var.env}"
  my_admin_user_name = "ubuntu"
  my_private_key = "vm_id_rsa"
}


resource "tls_private_key" "vm_ssh_key" {
  algorithm   = "RSA"
}

# NOTE: If you get 'No available provider "null" plugins'
# Try: terraform init, terraform get, terraform plan.
# I.e. resource occasionally fails the first time.
# When the resource is succesfull you should see the private key
# in ./terraform/modules/vm/.ssh folder.

# We have two versions since the private ssh key needs to be stored in the local
# workstation differently in Linux and Windows workstations.

# First the Linux version (my_workstation_is_linux = 1)
resource "null_resource" "vm_save_ssh_key_linux" {
  count = "${var.my_workstation_is_linux}"
  triggers {
    key = "${tls_private_key.vm_ssh_key.private_key_pem}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.vm_ssh_key.private_key_pem}" > ${path.module}/.ssh/${local.my_private_key}
      chmod 0600 ${path.module}/.ssh/${local.my_private_key}
EOF
  }
}



# Then the Windows version (my_workstation_is_linux = 0)
resource "null_resource" "vm_save_ssh_key_windows" {
  count = "${1 - var.my_workstation_is_linux}"
  triggers {
    key = "${tls_private_key.vm_ssh_key.private_key_pem}"
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell"]
    command = <<EOF
      md ${path.module}\\.ssh
      echo "${tls_private_key.vm_ssh_key.private_key_pem}" > ${path.module}\\.ssh\\${local.my_private_key}
EOF
  }
}


# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm

resource "azurerm_public_ip" "vm_pip" {
  name                 = "${local.my_name}-pip"
  location             = "${var.location}"
  resource_group_name  = "${var.rg_name}"
  // TODO: Complains about deprecation but the new field allocation_method does not exist?
  public_ip_address_allocation = "dynamic"

  tags {
    Name        = "${local.my_name}-pip"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Location    = "${var.location}"
    Terraform   = "true"
  }
}


resource "azurerm_network_interface" "vm_nic" {
  name                 = "${local.my_name}-nic"
  location             = "${var.location}"
  resource_group_name  = "${var.rg_name}"
  // Deprecated, see azurerm_subnet_network_security_group_association below.
  //network_security_group_id = "${var.public_mgmt_subnet_nw_sg_id}"

  ip_configuration {
    name                          = "${local.my_name}-nic-config"
    subnet_id                     = "${var.application_subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.vm_pip.id}"
  }

  tags {
    Name        = "${local.my_name}-nic"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Location    = "${var.location}"
    Terraform   = "true"
  }
}


resource "azurerm_virtual_machine" "posvm_vm" {
  name                         = "${local.my_name}"
  location                     = "${var.location}"
  resource_group_name          = "${var.rg_name}"
  network_interface_ids         = ["${azurerm_network_interface.vm_nic.id}"]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher      = "Canonical"
    offer          = "UbuntuServer"
    # https://azuremarketplace.microsoft.com/en/marketplace/apps/Canonical.UbuntuServer?tab=PlansAndPrice
    # => latest 18.04 not available.
    sku             = "16.04.0-LTS"
    version         = "latest"
  }

  storage_os_disk {
    name              = "${local.my_name}-os-disk"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}${var.env}"
    admin_username = "${local.my_admin_user_name}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${local.my_admin_user_name}/.ssh/authorized_keys"
      # You could also provide some existing key in some path like this:
      // key_data = "${file("${var.vm_ssh_public_key_file}")}"
      # Using some dummy domain.
      key_data = "${trimspace(tls_private_key.vm_ssh_key.public_key_openssh)} ${local.my_admin_user_name}@azure.com"
    }
  }

  tags {
    Name        = "${local.my_name}"
    Environment = "${local.my_env}"
    Prefix      = "${var.prefix}"
    Env         = "${var.env}"
    Location    = "${var.location}"
    Terraform   = "true"
  }

}
