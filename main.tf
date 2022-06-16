resource "random_pet" "rg-name" {
  prefix    = var.resource_group_name_prefix
}
resource "azurerm_resource_group" "rg" {
  name      = random_pet.rg-name.id
  location  = var.resource_group_location
}
 resource "azurerm_availability_set" "avset" {
   name                         = "avset"
   location                     = azurerm_resource_group.rg.location
   resource_group_name          = azurerm_resource_group.rg.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
 }

 resource "azurerm_linux_virtual_machine" "myvms" {
   count                 = "${var.vmcount}"
   name                  = "acctvm${count.index}"
   location              = azurerm_resource_group.rg.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.rg.name
   network_interface_ids = [element(azurerm_network_interface.week5NIC.*.id, count.index)]
   size                  = "Standard_B1s"

   # Uncomment this line to delete the OS disk automatically when deleting the VM
   # delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
   # delete_data_disks_on_termination = true
source_image_reference {
     publisher = "Canonical"
     offer     = "0001-com-ubuntu-server-focal"
     sku       = "20_04-lts-gen2"
     version   = "latest"
   }

   os_disk {
     name              = "myosdisk${count.index}"
     caching           = "ReadWrite"
     storage_account_type = "Premium_LRS"
   }
      admin_username = "azureadmin"
    admin_password = random_password.password.result
    disable_password_authentication = false
}

 resource "azurerm_linux_virtual_machine" "myDB" {
   name                  = "DBvm"
   location              = azurerm_resource_group.rg.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.rg.name
   network_interface_ids  = [azurerm_network_interface.week5DBNIC.id]
   size                  = "Standard_B1s"

   # Uncomment this line to delete the OS disk automatically when deleting the VM
   # delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
   # delete_data_disks_on_termination = true
source_image_reference {
     publisher = "Canonical"
     offer     = "0001-com-ubuntu-server-focal"
     sku       = "20_04-lts-gen2"
     version   = "latest"
   }

   os_disk {
     name              = "myosdisk"
     caching           = "ReadWrite"
     storage_account_type = "Premium_LRS"
   }
    admin_username = "azureadmin"
    admin_password = random_password.password.result
    disable_password_authentication = false
}
#Generate random password
resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}