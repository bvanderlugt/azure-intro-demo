
output "vnet_id" {
  value = "${azurerm_virtual_network.vm-vnet.id}"
}

output "vnet_name" {
  value = "${azurerm_virtual_network.vm-vnet.name}"
}

output "private_application_subnet_id" {
  value = "${azurerm_subnet.private_application_subnet.id}"
}

